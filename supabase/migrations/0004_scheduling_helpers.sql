-- SoloLevelUp — scheduling helper: is a given quest due on a given date,
-- per its repeat_rule (SRS §4.1 Quest.repeat_rule, FR-3.1).
create or replace function public.quest_is_due(p_quest public.quests, p_date date)
returns boolean
language plpgsql
stable
as $$
declare
  v_type text := p_quest.repeat_rule ->> 'type';
  v_isodow int;
  v_week_start date;
  v_done_this_week int;
begin
  if v_type = 'everyday' then
    return true;

  elsif v_type = 'specific_weekdays' then
    -- weekdays stored as ISO day-of-week ints, 1=Monday .. 7=Sunday
    v_isodow := extract(isodow from p_date);
    return (p_quest.repeat_rule -> 'weekdays') @> to_jsonb(v_isodow);

  elsif v_type = 'n_times_per_week' then
    -- "any N days this week" — due as long as this week's done-count hasn't hit N yet
    v_week_start := date_trunc('week', p_date)::date;
    select count(*) into v_done_this_week
      from public.quest_log_entries
     where quest_id = p_quest.id
       and status = 'done'
       and occurrence_date >= v_week_start
       and occurrence_date <= p_date;
    return v_done_this_week < coalesce((p_quest.repeat_rule ->> 'n')::int, 999);

  else
    return false;
  end if;
end;
$$;
comment on function public.quest_is_due is 'SRS §4.1 repeat_rule interpreter, used by v_today_quests and ensure_today_entries.';
