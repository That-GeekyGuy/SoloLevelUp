-- SoloLevelUp — global catalog tables (SRS §4.1 Achievement, UserAchievement,
-- LearningItem, UserLearningProgress). Catalogs are admin-managed; in this
-- single-user deployment "admin" means the owner or Claude via the MCP
-- server (§5.9), writing with the service-role key — not the app's anon key.

create table public.achievements (
  id            uuid primary key default gen_random_uuid(),
  key           text not null unique,
  name          text not null,
  description   text not null,
  icon_ref      text,
  unlock_rule   jsonb not null,
  -- unlock_rule shapes (evaluated by the 0004 trigger):
  --   {"type":"quest_completions_total","threshold":30}
  --   {"type":"streak_reached","threshold":14}
  --   {"type":"challenge_completed"}
  --   {"type":"learning_items_done","threshold":10}
  --   {"type":"stat_reached","stat":"discipline","threshold":90}
  sort_order    int not null default 0,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now()
);
comment on table public.achievements is 'SRS §4.1 Achievement (FR-6.1). Global catalog, not per-user. Seeded in 0006.';

create table public.user_achievements (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users (id) on delete cascade,
  achievement_id  uuid not null references public.achievements (id) on delete cascade,
  unlocked_at     timestamptz not null default now(),
  unique (user_id, achievement_id)
);
comment on table public.user_achievements is 'SRS §4.1 UserAchievement. Insert-only from the 0004 trigger — never updated/deleted by client code (FR-6.5).';

create table public.learning_items (
  id                uuid primary key default gen_random_uuid(),
  title             text not null,
  author            text not null,
  cover_ref         text,
  category          text[] not null default '{}',
  rating            numeric,
  rating_count      int default 0,
  summary_text      text not null,
  est_read_minutes  int,
  is_active         boolean not null default true,
  created_at        timestamptz not null default now()
);
comment on table public.learning_items is 'SRS §4.1 LearningItem / §5.7.1. summary_text is original synthesis generated from public book metadata — never a reproduction of a licensed summary service''s text. Seeded via the MCP add_learning_item tool (FR-9.4), not this migration.';

create table public.user_learning_progress (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references auth.users (id) on delete cascade,
  learning_item_id   uuid not null references public.learning_items (id) on delete cascade,
  status             text not null default 'recommended' check (status in ('recommended', 'in_progress', 'done')),
  progress_pct       numeric not null default 0 check (progress_pct between 0 and 100),
  last_read_at       timestamptz,
  unique (user_id, learning_item_id)
);
comment on table public.user_learning_progress is 'SRS §4.1 UserLearningProgress (FR-7.3, FR-7.5).';
