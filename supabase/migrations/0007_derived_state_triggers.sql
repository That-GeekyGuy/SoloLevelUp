-- SoloLevelUp — server-side derivation of Rise Rating and Achievements
-- (NFR-5.1 / AR-7: computed once, server-side, never trusted from client
-- writes). These run SECURITY DEFINER so that, even though every user's own
-- action triggers them, only this code path can ever write into
-- rise_rating_snapshots or user_achievements — RLS in 0010 grants clients
-- read-only access to both tables.

create or replace function public.recompute_rise_rating(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_challenge public.challenges;
  v_day1 public.rise_rating_snapshots;
  v_wisdom numeric; v_strength numeric; v_focus numeric;
  v_confidence numeric; v_discipline numeric; v_overall numeric;
begin
  select * into v_challenge
    from public.challenges
   where user_id = p_user_id and status = 'active'
   order by created_at desc
   limit 1;
  if v_challenge is null then
    return;
  end if;

  select * into v_day1
    from public.rise_rating_snapshots
   where challenge_id = v_challenge.id and lens = 'day1';
  if v_day1 is null then
    return; -- seeded at challenge creation (0008); nothing to do if missing
  end if;

  -- SRS §5.5.1: each difficulty point of a completed quest contributes 2
  -- Rise Rating points to that quest's stat_category, capped at 100. This is
  -- a tunable first pass (see docs/SRS.md §9, open question 3), recomputed
  -- from the full history every time so it can never drift/double-count.
  select
    least(100, v_day1.wisdom     + coalesce(sum(q.difficulty) filter (where q.stat_category = 'wisdom'),     0) * 2),
    least(100, v_day1.strength   + coalesce(sum(q.difficulty) filter (where q.stat_category = 'strength'),   0) * 2),
    least(100, v_day1.focus      + coalesce(sum(q.difficulty) filter (where q.stat_category = 'focus'),      0) * 2),
    least(100, v_day1.confidence + coalesce(sum(q.difficulty) filter (where q.stat_category = 'confidence'), 0) * 2),
    least(100, v_day1.discipline + coalesce(sum(q.difficulty) filter (where q.stat_category = 'discipline'), 0) * 2)
    into v_wisdom, v_strength, v_focus, v_confidence, v_discipline
  from public.quest_log_entries l
  join public.quests q on q.id = l.quest_id
  where l.user_id = p_user_id
    and l.challenge_id = v_challenge.id
    and l.status = 'done';

  v_overall := round((coalesce(v_wisdom, v_day1.wisdom)
                     + coalesce(v_strength, v_day1.strength)
                     + coalesce(v_focus, v_day1.focus)
                     + coalesce(v_confidence, v_day1.confidence)
                     + coalesce(v_discipline, v_day1.discipline)) / 5.0);

  insert into public.rise_rating_snapshots
    (user_id, challenge_id, lens, taken_at, overall, wisdom, strength, focus, confidence, discipline)
  values
    (p_user_id, v_challenge.id, 'current', now(),
     v_overall, coalesce(v_wisdom, v_day1.wisdom), coalesce(v_strength, v_day1.strength),
     coalesce(v_focus, v_day1.focus), coalesce(v_confidence, v_day1.confidence), coalesce(v_discipline, v_day1.discipline))
  on conflict (challenge_id, lens) do update
    set taken_at = excluded.taken_at,
        overall = excluded.overall,
        wisdom = excluded.wisdom,
        strength = excluded.strength,
        focus = excluded.focus,
        confidence = excluded.confidence,
        discipline = excluded.discipline;
end;
$$;

create or replace function public.evaluate_achievements(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_achievement record;
  v_type text;
  v_unlocked boolean;
  v_total_completions int;
  v_max_streak int;
  v_learning_done int;
  v_current public.rise_rating_snapshots;
  v_challenge public.challenges;
begin
  select * into v_challenge
    from public.challenges
   where user_id = p_user_id
   order by created_at desc
   limit 1;
  if v_challenge is null then
    return;
  end if;

  select count(*) into v_total_completions
    from public.quest_log_entries
   where user_id = p_user_id and status = 'done';

  select coalesce(max(streak_len), 0) into v_max_streak
    from public.v_quest_streaks
   where user_id = p_user_id;

  select count(*) into v_learning_done
    from public.user_learning_progress
   where user_id = p_user_id and status = 'done';

  select * into v_current
    from public.rise_rating_snapshots
   where challenge_id = v_challenge.id and lens = 'current';

  for v_achievement in
    select a.* from public.achievements a
     where a.is_active
       and not exists (
         select 1 from public.user_achievements ua
          where ua.user_id = p_user_id and ua.achievement_id = a.id
       )
  loop
    v_type := v_achievement.unlock_rule ->> 'type';
    v_unlocked := false;

    if v_type = 'quest_completions_total' then
      v_unlocked := v_total_completions >= (v_achievement.unlock_rule ->> 'threshold')::int;

    elsif v_type = 'streak_reached' then
      v_unlocked := v_max_streak >= (v_achievement.unlock_rule ->> 'threshold')::int;

    elsif v_type = 'challenge_completed' then
      v_unlocked := v_challenge.status = 'completed';

    elsif v_type = 'learning_items_done' then
      v_unlocked := v_learning_done >= (v_achievement.unlock_rule ->> 'threshold')::int;

    elsif v_type = 'stat_reached' and v_current is not null then
      v_unlocked := (
        case v_achievement.unlock_rule ->> 'stat'
          when 'wisdom'     then v_current.wisdom
          when 'strength'   then v_current.strength
          when 'focus'      then v_current.focus
          when 'confidence' then v_current.confidence
          when 'discipline' then v_current.discipline
          else v_current.overall
        end
      ) >= (v_achievement.unlock_rule ->> 'threshold')::numeric;
    end if;

    if v_unlocked then
      insert into public.user_achievements (user_id, achievement_id)
      values (p_user_id, v_achievement.id)
      on conflict do nothing;
    end if;
  end loop;
end;
$$;

-- Fires on every quest_log_entries write, regardless of whether it came from
-- log_quest_action(), a direct client update, or an MCP call — this is what
-- keeps client and MCP writes indistinguishable (AR-9).
create or replace function public.on_quest_log_entry_change()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_quest public.quests;
begin
  select * into v_quest from public.quests where id = new.quest_id;

  -- FR-3.8: auto metric rollup on completion, retraction on undo.
  if new.status = 'done' and (tg_op = 'INSERT' or old.status is distinct from 'done') then
    if v_quest.linked_metric_id is not null then
      insert into public.metric_entries
        (user_id, challenge_id, metric_id, value, source_quest_log_entry_id, occurred_on)
      values
        (new.user_id, new.challenge_id, v_quest.linked_metric_id,
         coalesce(v_quest.metric_increment, 1), new.id, new.occurrence_date)
      on conflict (source_quest_log_entry_id) where source_quest_log_entry_id is not null do nothing;
    end if;
  elsif tg_op = 'UPDATE' and old.status = 'done' and new.status is distinct from 'done' then
    delete from public.metric_entries where source_quest_log_entry_id = new.id;
  end if;

  perform public.recompute_rise_rating(new.user_id);
  perform public.evaluate_achievements(new.user_id);

  return new;
end;
$$;

create unique index if not exists metric_entries_source_uidx
  on public.metric_entries (source_quest_log_entry_id)
  where source_quest_log_entry_id is not null;

drop trigger if exists quest_log_entries_after_change on public.quest_log_entries;
create trigger quest_log_entries_after_change
  after insert or update of status on public.quest_log_entries
  for each row execute function public.on_quest_log_entry_change();
