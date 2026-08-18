# SoloLevelUp

A gamified, "Solo Leveling"-inspired habit and self-improvement app: a
66-day challenge of daily quests, an RPG-style Rise Rating (Wisdom /
Strength / Focus / Confidence / Discipline), streaks, achievements, and a
Daily Learning feed — for Web, Android, and Windows, all on one account.

Full spec: [`docs/SRS.md`](docs/SRS.md).

## Repo layout

- `app/` — the Flutter client (Web, Android, Windows targets from one
  codebase; see SRS §7.2 for why).
- `supabase/migrations/` — the Postgres schema, RLS policies, and
  server-side logic (streaks, Rise Rating, achievements) backing all three
  clients (SRS §4, §7.6).
- `docs/SRS.md` — the software requirements specification.

## Getting started

### 1. Backend

1. Create a free Supabase project.
2. Apply the migrations in order:
   ```
   supabase link --project-ref <your-project-ref>
   supabase db push
   ```
   (or run each file in `supabase/migrations/` against your project via the
   SQL editor, in filename order — they're plain, dependency-ordered SQL).
3. Copy your project's URL and anon/publishable key from
   **Settings → API**.

### 2. App

```
cd app
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://<your-project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```

Without those two `--dart-define` values the app boots to a "Supabase
isn't configured yet" screen instead of crashing — see
`app/lib/core/supabase/supabase_config.dart`.

Targets: `flutter run -d chrome` (Web), `flutter run -d windows`
(Windows), or an attached Android device/emulator.

## What's scaffolded vs. what's next

Implemented: auth gate, Today screen (swipe-to-complete/skip, To-dos/Done/
Skipped, metrics strip), Rise Rating (Current/Potential/Day 1), Achievements
grid, Daily Learning (feed + reader with synced progress), and the full
schema/RLS/derived-state logic behind all of it (validated end-to-end
against a local Postgres instance — onboarding, quest completion, streaks,
metric rollup, Rise Rating recompute, and achievement unlocking all work).

Not yet built: the MCP server (SRS §5.9/§7.6), the Daily Learning content
seed itself (§5.7.1 — the pipeline is designed, no items are seeded yet),
push notifications (§5.8), the quest create/edit UI, offline write-queue
(Drift is a dependency but not wired up yet), and day-by-day history
navigation (Today only shows *today* for now).
