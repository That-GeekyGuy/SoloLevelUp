-- SoloLevelUp — write RPCs the clients (and the MCP server, §5.9) call
-- instead of writing quest_log_entries directly, so idempotency (AR-5) and
-- day/challenge bookkeeping are handled in one place.

-- Materialize today's pending rows for every currently-due active quest.
-- Call on app open / Today screen load; safe to call repeatedly (idempotent
-- via the (quest_id, occurrence_date) unique constraint from 0002).
create or replace function public.ensure_today_entries()
returns void
language plpgsql
as $$
declare
  v_user uuid := auth.uid();
  v_challenge public.challenges;
  v_quest public.quests;
  v_day_number int;
begin
  select * into v_challenge
    from public.challenges
   where user_id = v_user and status = 'active'
   order by created_at desc
   limit 1;

  if v_challenge is null then
    return;
  end if;

  v_day_number := (current_date - v_challenge.start_date) + 1;

  for v_quest in
    select * from public.quests where user_id = v_user and is_active
  loop
    if public.quest_is_due(v_quest, current_date) then
      insert into public.quest_log_entries
        (quest_id, user_id, challenge_id, challenge_day_number, occurrence_date, status)
      values
        (v_quest.id, v_user, v_challenge.id, v_day_number, current_date, 'pending')
      on conflict (quest_id, occurrence_date) do nothing;
    end if;
  end loop;
end;
$$;

-- Complete / skip / undo a quest for *today*. This is the single write path
-- FR-3.3/FR-3.5 (swipe-to-complete/skip, same-day undo) and FR-9.2 (the MCP
-- complete_quest/skip_quest tools) both go through, so client and MCP writes
-- are indistinguishable once persisted (AR-9). p_client_write_id is the
-- offline-safe idempotency key from AR-5 — a retried call with the same key
-- returns the original result instead of double-applying.
create or replace function public.log_quest_action(
  p_quest_id uuid,
  p_action text,               -- 'done' | 'skipped' | 'undo'
  p_device_id uuid default null,
  p_client_write_id text default null
) returns public.quest_log_entries
language plpgsql
as $$
declare
  v_user uuid := auth.uid();
  v_challenge public.challenges;
  v_day_number int;
  v_status text;
  v_existing public.quest_log_entries;
  v_result public.quest_log_entries;
begin
  if p_action not in ('done', 'skipped', 'undo') then
    raise exception 'Invalid action %, expected done|skipped|undo', p_action;
  end if;

  if p_client_write_id is not null then
    select * into v_existing
      from public.quest_log_entries
     where client_write_id = p_client_write_id;
    if found then
      return v_existing;
    end if;
  end if;

  select * into v_challenge
    from public.challenges
   where user_id = v_user and status = 'active'
   order by created_at desc
   limit 1;

  if v_challenge is null then
    raise exception 'No active challenge for user %', v_user;
  end if;

  v_day_number := (current_date - v_challenge.start_date) + 1;
  v_status := case p_action when 'undo' then 'pending' else p_action end;

  insert into public.quest_log_entries
    (quest_id, user_id, challenge_id, challenge_day_number, occurrence_date,
     status, completed_at, device_id, client_write_id)
  values
    (p_quest_id, v_user, v_challenge.id, v_day_number, current_date,
     v_status, case when v_status = 'done' then now() else null end,
     p_device_id, p_client_write_id)
  on conflict (quest_id, occurrence_date) do update
    set status = excluded.status,
        completed_at = excluded.completed_at,
        device_id = coalesce(excluded.device_id, public.quest_log_entries.device_id),
        client_write_id = coalesce(excluded.client_write_id, public.quest_log_entries.client_write_id)
  returning * into v_result;

  return v_result;
end;
$$;
comment on function public.log_quest_action is 'Single write path for quest completion/skip/undo. Downstream effects (metric rollup, Rise Rating, achievements) fire from the AFTER trigger in 0007, not from here, so they apply no matter which caller uses this RPC.';
