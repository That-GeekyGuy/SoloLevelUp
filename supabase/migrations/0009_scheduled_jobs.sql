-- SoloLevelUp — FR-3.7: a quest occurrence that's still 'pending' once its
-- day has passed is auto-marked 'skipped'. Run hourly via pg_cron.
--
-- Known simplification: this compares against the database server's
-- current_date rather than each user's own profiles.timezone, so the
-- cutoff can be off by up to ~1 day for users far from UTC. Acceptable for
-- a single-user personal deployment where the owner picks a challenge
-- timezone that matches the server; revisit (per-user cutoff evaluation)
-- if that stops being true. Recomputation of Rise Rating/achievements still
-- happens correctly either way, via the same AFTER trigger (0007).
create or replace function public.auto_skip_past_pending()
returns void
language sql
as $$
  update public.quest_log_entries
     set status = 'skipped'
   where status = 'pending'
     and occurrence_date < current_date;
$$;

select cron.schedule(
  'auto-skip-past-pending',
  '0 * * * *',
  $$select public.auto_skip_past_pending();$$
);
