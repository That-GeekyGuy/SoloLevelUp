-- SoloLevelUp — read views backing the client screens directly (SRS §3.1).
-- Keeping these as views (rather than duplicating the logic in each Flutter
-- client) is what NFR-5.1 requires: derived values computed once, server-side.

-- Streak per quest (SRS §4.2): walk quest_log_entries backward from the most
-- recent occurrence; the streak is how many consecutive 'done' rows precede
-- the first non-'done' row (or the full row count if there is no break).
create or replace view public.v_quest_streaks as
with ordered as (
  select
    quest_id,
    user_id,
    status,
    row_number() over (partition by quest_id order by occurrence_date desc) as rn
  from public.quest_log_entries
),
breaks as (
  select quest_id, min(rn) as first_break_rn
  from ordered
  where status <> 'done'
  group by quest_id
),
totals as (
  select quest_id, user_id, count(*) as total_rows
  from ordered
  group by quest_id, user_id
)
select
  t.quest_id,
  t.user_id,
  coalesce(b.first_break_rn - 1, t.total_rows) as streak_len
from totals t
left join breaks b using (quest_id);

-- Today screen (FR-3.3, FR-3.4): every active quest due today, with its
-- status for today (defaulting to 'pending' if no row exists yet — the
-- client should call ensure_today_entries() first so a row always exists,
-- but the view is safe to read even if that hasn't happened yet) and streak.
create or replace view public.v_today_quests as
select
  q.id as quest_id,
  q.user_id,
  q.title,
  q.description,
  q.icon_ref,
  q.repeat_rule,
  q.difficulty,
  q.stat_category,
  coalesce(l.status, 'pending') as today_status,
  l.id as today_entry_id,
  coalesce(s.streak_len, 0) as streak_len
from public.quests q
left join public.quest_log_entries l
  on l.quest_id = q.id and l.occurrence_date = current_date
left join public.v_quest_streaks s
  on s.quest_id = q.id
where q.is_active
  and public.quest_is_due(q, current_date);

-- Metrics rollup strip (FR-4.1), scoped to each metric's owning challenge.
create or replace view public.v_metric_totals as
select
  me.user_id,
  me.challenge_id,
  md.key as metric_key,
  md.display_name,
  md.unit,
  md.icon_ref,
  sum(me.value) as total
from public.metric_entries me
join public.metric_definitions md on md.id = me.metric_id
group by me.user_id, me.challenge_id, md.key, md.display_name, md.unit, md.icon_ref;

-- Rise Rating screen (FR-5.1-5.5): all three lenses in one row per active
-- challenge. "potential" is computed here, at read time, and is never
-- persisted (AR-7) — it linearly projects the trailing rate of gain
-- (current - day1) / days_elapsed across the challenge's remaining days.
create or replace view public.v_rise_rating as
with c as (
  select
    ch.id as challenge_id,
    ch.user_id,
    greatest(1, current_date - ch.start_date + 1) as days_elapsed,
    greatest(0, ch.length_days - (current_date - ch.start_date + 1)) as days_remaining
  from public.challenges ch
  where ch.status = 'active'
),
d1 as (
  select * from public.rise_rating_snapshots where lens = 'day1'
),
cur as (
  select * from public.rise_rating_snapshots where lens = 'current'
)
select
  c.user_id,
  c.challenge_id,
  d1.overall as day1_overall, d1.wisdom as day1_wisdom, d1.strength as day1_strength,
  d1.focus as day1_focus, d1.confidence as day1_confidence, d1.discipline as day1_discipline,
  cur.overall as current_overall, cur.wisdom as current_wisdom, cur.strength as current_strength,
  cur.focus as current_focus, cur.confidence as current_confidence, cur.discipline as current_discipline,
  least(100, cur.overall    + ((cur.overall    - d1.overall)    / c.days_elapsed) * c.days_remaining) as potential_overall,
  least(100, cur.wisdom     + ((cur.wisdom     - d1.wisdom)     / c.days_elapsed) * c.days_remaining) as potential_wisdom,
  least(100, cur.strength   + ((cur.strength   - d1.strength)   / c.days_elapsed) * c.days_remaining) as potential_strength,
  least(100, cur.focus      + ((cur.focus      - d1.focus)      / c.days_elapsed) * c.days_remaining) as potential_focus,
  least(100, cur.confidence + ((cur.confidence - d1.confidence) / c.days_elapsed) * c.days_remaining) as potential_confidence,
  least(100, cur.discipline + ((cur.discipline - d1.discipline) / c.days_elapsed) * c.days_remaining) as potential_discipline
from c
join d1 on d1.challenge_id = c.challenge_id
join cur on cur.challenge_id = c.challenge_id;
