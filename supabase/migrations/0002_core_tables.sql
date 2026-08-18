-- SoloLevelUp — core per-user tables (SRS §4.1: User, Challenge, Quest,
-- QuestLogEntry, MetricDefinition, MetricEntry, RiseRatingSnapshot, Device).
--
-- `auth.users` (managed by Supabase Auth) is the identity table; `profiles`
-- extends it with app-specific fields (SRS User entity minus auth fields).

create table public.profiles (
  id                     uuid primary key references auth.users (id) on delete cascade,
  display_name           text,
  timezone               text not null default 'UTC',
  challenge_length_days  int not null default 66 check (challenge_length_days > 0),
  notification_prefs     jsonb not null default '{
    "daily_reminder": true,
    "streak_at_risk": true,
    "achievement_unlocked": true
  }'::jsonb,
  premium_tier           text not null default 'free' check (premium_tier in ('free', 'premium')),
  created_at             timestamptz not null default now()
);
comment on table public.profiles is 'One row per user; extends auth.users. SRS §4.1 User.';

create table public.challenges (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users (id) on delete cascade,
  start_date   date not null default current_date,
  length_days  int not null check (length_days > 0),
  status       text not null default 'active' check (status in ('active', 'completed', 'reset')),
  reset_count  int not null default 0,
  created_at   timestamptz not null default now()
);
comment on table public.challenges is 'SRS §4.1 Challenge. One active row per user at a time (enforced by 0004 trigger, not a DB constraint, so history is retained).';
create index challenges_user_active_idx on public.challenges (user_id) where status = 'active';

create table public.metric_definitions (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users (id) on delete cascade,
  key             text not null,
  display_name    text not null,
  unit            text not null,
  aggregation     text not null default 'sum' check (aggregation in ('sum', 'count')),
  icon_ref        text,
  is_system       boolean not null default false,
  created_at      timestamptz not null default now(),
  unique (user_id, key)
);
comment on table public.metric_definitions is 'SRS §4.1 MetricDefinition. System defaults (water_liters, pages_read, cold_showers) seeded per-user on signup; is_system rows are not user-deletable.';

create table public.quests (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references auth.users (id) on delete cascade,
  title              text not null,
  description        text,
  icon_ref           text,
  repeat_rule        jsonb not null,
  -- repeat_rule shapes: {"type":"everyday"}
  --                     {"type":"n_times_per_week","n":3}
  --                     {"type":"specific_weekdays","weekdays":[1,3,5]}  -- 1=Mon..7=Sun
  difficulty         int not null default 3 check (difficulty between 1 and 5),
  stat_category      text not null check (stat_category in ('wisdom', 'strength', 'focus', 'confidence', 'discipline')),
  linked_metric_id   uuid references public.metric_definitions (id) on delete set null,
  metric_increment   numeric,
  reminder_time      time,
  is_active          boolean not null default true,
  created_at         timestamptz not null default now(),
  archived_at        timestamptz
);
comment on table public.quests is 'SRS §4.1 Quest / FR-3.1. stat_category drives the Rise Rating formula in 0004 (§5.5.1).';
create index quests_user_active_idx on public.quests (user_id) where is_active;

create table public.quest_log_entries (
  id                   uuid primary key default gen_random_uuid(),
  quest_id             uuid not null references public.quests (id) on delete cascade,
  user_id              uuid not null references auth.users (id) on delete cascade,
  challenge_id         uuid not null references public.challenges (id) on delete cascade,
  challenge_day_number int not null,
  occurrence_date      date not null,
  status               text not null default 'pending' check (status in ('done', 'skipped', 'pending')),
  completed_at         timestamptz,
  device_id            uuid,
  client_write_id      text,
  created_at           timestamptz not null default now(),
  unique (quest_id, occurrence_date),
  unique (client_write_id)
);
comment on table public.quest_log_entries is 'SRS §4.1 QuestLogEntry. One row per quest per scheduled day. client_write_id is the idempotency key for AR-5 (safe retry of offline writes).';
create index quest_log_entries_user_date_idx on public.quest_log_entries (user_id, occurrence_date);
create index quest_log_entries_quest_idx on public.quest_log_entries (quest_id, occurrence_date desc);

create table public.metric_entries (
  id                          uuid primary key default gen_random_uuid(),
  user_id                     uuid not null references auth.users (id) on delete cascade,
  challenge_id                uuid not null references public.challenges (id) on delete cascade,
  metric_id                   uuid not null references public.metric_definitions (id) on delete cascade,
  value                       numeric not null,
  source_quest_log_entry_id   uuid references public.quest_log_entries (id) on delete cascade,
  occurred_on                 date not null default current_date,
  created_at                  timestamptz not null default now()
);
comment on table public.metric_entries is 'SRS §4.1 MetricEntry. Rows with source_quest_log_entry_id are auto-written/retracted by the 0004 trigger (FR-3.8); rows without it are manual logs.';
create index metric_entries_user_metric_idx on public.metric_entries (user_id, metric_id, challenge_id);
create index metric_entries_source_idx on public.metric_entries (source_quest_log_entry_id);

create table public.rise_rating_snapshots (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users (id) on delete cascade,
  challenge_id uuid not null references public.challenges (id) on delete cascade,
  lens         text not null check (lens in ('day1', 'current')),
  taken_at     timestamptz not null default now(),
  overall      numeric not null,
  wisdom       numeric not null,
  strength     numeric not null,
  focus        numeric not null,
  confidence   numeric not null,
  discipline   numeric not null,
  unique (challenge_id, lens)
);
comment on table public.rise_rating_snapshots is 'SRS §4.1 RiseRatingSnapshot. "day1" is written once at enrollment and never updated again (FR-5.3); "current" is upserted in place by the 0004 trigger (FR-5.4). "potential" (FR-5.5) is never persisted — computed at read time by a view in 0005.';

create table public.devices (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users (id) on delete cascade,
  platform      text not null check (platform in ('web', 'android', 'windows')),
  push_token    text,
  last_seen_at  timestamptz not null default now(),
  created_at    timestamptz not null default now()
);
comment on table public.devices is 'SRS §4.1 Device. Supports targeted push (FR-8.4) and the session list in FR-1.5.';
