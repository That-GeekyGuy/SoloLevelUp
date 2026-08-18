-- SoloLevelUp — Row Level Security (NFR-3.5). Every per-user table is
-- locked to auth.uid() = user_id; catalog tables are read-only for
-- authenticated clients (writes only via service_role — the owner or the
-- MCP server, per §5.9/§7.6); the two server-derived tables
-- (rise_rating_snapshots, user_achievements) are read-only for clients too —
-- they're written exclusively by the SECURITY DEFINER functions in 0007.

alter table public.profiles                enable row level security;
alter table public.challenges               enable row level security;
alter table public.metric_definitions       enable row level security;
alter table public.quests                   enable row level security;
alter table public.quest_log_entries        enable row level security;
alter table public.metric_entries           enable row level security;
alter table public.rise_rating_snapshots    enable row level security;
alter table public.devices                  enable row level security;
alter table public.achievements             enable row level security;
alter table public.user_achievements        enable row level security;
alter table public.learning_items           enable row level security;
alter table public.user_learning_progress   enable row level security;

-- profiles: self-select/update only; insert happens via the onboarding
-- trigger (0008), which is SECURITY DEFINER and so bypasses this policy set.
create policy profiles_select_own on public.profiles
  for select using (auth.uid() = id);
create policy profiles_update_own on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- challenges
create policy challenges_select_own on public.challenges
  for select using (auth.uid() = user_id);
create policy challenges_insert_own on public.challenges
  for insert with check (auth.uid() = user_id);
create policy challenges_update_own on public.challenges
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- metric_definitions
create policy metric_definitions_select_own on public.metric_definitions
  for select using (auth.uid() = user_id);
create policy metric_definitions_insert_own on public.metric_definitions
  for insert with check (auth.uid() = user_id);
create policy metric_definitions_update_own on public.metric_definitions
  for update using (auth.uid() = user_id and not is_system) with check (auth.uid() = user_id);
create policy metric_definitions_delete_own on public.metric_definitions
  for delete using (auth.uid() = user_id and not is_system);

-- quests
create policy quests_select_own on public.quests
  for select using (auth.uid() = user_id);
create policy quests_insert_own on public.quests
  for insert with check (auth.uid() = user_id);
create policy quests_update_own on public.quests
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy quests_delete_own on public.quests
  for delete using (auth.uid() = user_id);

-- quest_log_entries (also written via log_quest_action/ensure_today_entries,
-- which run as the caller and so are still subject to these same policies)
create policy quest_log_entries_select_own on public.quest_log_entries
  for select using (auth.uid() = user_id);
create policy quest_log_entries_insert_own on public.quest_log_entries
  for insert with check (auth.uid() = user_id);
create policy quest_log_entries_update_own on public.quest_log_entries
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- metric_entries (manual logging per FR-4.3, plus system rows inserted by
-- the SECURITY DEFINER trigger which bypasses these policies)
create policy metric_entries_select_own on public.metric_entries
  for select using (auth.uid() = user_id);
create policy metric_entries_insert_own on public.metric_entries
  for insert with check (auth.uid() = user_id and source_quest_log_entry_id is null);
create policy metric_entries_delete_own on public.metric_entries
  for delete using (auth.uid() = user_id and source_quest_log_entry_id is null);

-- rise_rating_snapshots: read-only for clients; all writes go through the
-- SECURITY DEFINER recompute_rise_rating()/onboarding trigger.
create policy rise_rating_snapshots_select_own on public.rise_rating_snapshots
  for select using (auth.uid() = user_id);

-- devices
create policy devices_select_own on public.devices
  for select using (auth.uid() = user_id);
create policy devices_insert_own on public.devices
  for insert with check (auth.uid() = user_id);
create policy devices_update_own on public.devices
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy devices_delete_own on public.devices
  for delete using (auth.uid() = user_id);

-- achievements catalog: readable by any authenticated user, writable only
-- by service_role (the owner/MCP server) — no policy needed for that since
-- service_role bypasses RLS entirely.
create policy achievements_select_active on public.achievements
  for select using (is_active);

-- user_achievements: read-only for clients; all writes go through the
-- SECURITY DEFINER evaluate_achievements() (FR-6.5: never client-revocable).
create policy user_achievements_select_own on public.user_achievements
  for select using (auth.uid() = user_id);

-- learning_items catalog: readable by any authenticated user.
create policy learning_items_select_active on public.learning_items
  for select using (is_active);

-- user_learning_progress
create policy user_learning_progress_select_own on public.user_learning_progress
  for select using (auth.uid() = user_id);
create policy user_learning_progress_insert_own on public.user_learning_progress
  for insert with check (auth.uid() = user_id);
create policy user_learning_progress_update_own on public.user_learning_progress
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
