# Software Requirements Specification

## SoloLevelUp — Gamified Self-Improvement & Habit System

**Document version:** 1.1
**Status:** Draft for review
**Author:** Claude (drafted from product reference video + repository context)
**Target platforms:** Web, Android, Windows (single shared account across all three)
**Deployment context:** personal/single-user project — no company, no public app-store listing required; this shapes several decisions below (§7.2, §7.6, §8) toward zero ongoing cost rather than multi-tenant scale.

**Changelog**
- 1.1 — Resolved the technology-stack open question (Flutter + Supabase, §7.2); added a Claude MCP integration module (§5.9, §7.6) so Claude can read progress and author challenges/quests on the user's behalf; replaced the placeholder content-sourcing assumption with a concrete, copyright-safe Daily Learning content pipeline (§5.7.1).

---

## 1. Introduction

### 1.1 Purpose

This document specifies the functional and non-functional requirements for **SoloLevelUp**, a gamified habit-building and self-improvement application inspired by the "Solo Leveling" progression fantasy: the user is the protagonist, daily discipline is the grind, and life stats visibly level up. The reference product motion (a short-form ad for a "Life Reset — 66 Day Habit" app) demonstrates the core loop this SRS formalizes: a fixed-length daily-quest challenge, RPG-style stat growth, streaks, achievements, and a bundled reading/learning module.

This SRS is the single source of truth for engineering, design, and QA to build one backend and three client applications (Web, Android, Windows) that share one account and one dataset in real time.

### 1.2 Scope

SoloLevelUp lets a user:

- Enroll in a fixed-duration challenge (default **66 days**, configurable) split into weeks.
- Complete a daily list of **quests** (habits/to-dos) by swiping to complete or skip, each quest carrying a streak counter, a repeat schedule, and a difficulty rating.
- Track cumulative lifestyle metrics (e.g., water intake, cold showers taken, pages read) that roll up automatically from quest completions.
- View an RPG-style **Rise Rating** dashboard with six stats (Overall, Wisdom, Strength, Focus, Confidence, Discipline), each shown as a 0–100 score with a delta and progress bar, across three lenses: **Current rating**, **Potential rating**, and **Day 1 rating**.
- Unlock **Achievements** from a fixed catalog (badges are shown as locked "?" tiles until earned).
- Consume a **Daily Learning** feed of curated non-fiction book summaries (recommended list + "done" list, filterable by category) and read full in-app summary text.
- Do all of the above from **Web, Android, and Windows**, signed into the **same account**, with data created on one device visible on the others within seconds.

Out of scope for v1 (explicitly deferred, listed in §8): iOS/macOS native clients, social/friends features, in-app purchases beyond a single premium tier, wearable integrations.

### 1.3 Intended Audience

Product/engineering team building this system: backend engineers, Web/Android/Windows client engineers, QA, and design. Assumes familiarity with REST/GraphQL APIs, OAuth2, and standard mobile/desktop/web app architecture; does not assume prior context on the product idea beyond this document.

### 1.4 Definitions, Acronyms, Abbreviations

| Term | Meaning |
|---|---|
| Quest | A single habit/to-do item scheduled for a given day (e.g., "Wake up at 7:30AM"). |
| Challenge | The overall 66-day (configurable) program a user is enrolled in. |
| Streak | Consecutive count of days a specific quest was completed without a miss, per that quest's own repeat schedule. |
| Rise Rating | The six-stat RPG scorecard (Overall, Wisdom, Strength, Focus, Confidence, Discipline). |
| Stat | One of the six Rise Rating dimensions. |
| Difficulty | 1–5 star rating authored per quest, used as a weighting factor in stat-point calculations. |
| Day 1 rating | Snapshot of the user's Rise Rating taken at enrollment, used as the growth baseline. |
| Potential rating | A projected Rise Rating if the user maintains their current completion pace to the end of the challenge. |
| SSO / Same account | One identity (email/password or OAuth) valid across Web, Android, and Windows, with one canonical data record. |
| BFF | Backend-for-frontend / the shared API layer all three clients call. |
| PWA | Progressive Web App. |
| MAUI | .NET Multi-platform App UI, a candidate framework for the Windows client. |

### 1.5 References

- Reference product motion: user-supplied screen recording of a "Life Reset: 66 Day Habit" style app (analyzed frame-by-frame to derive the screens and mechanics specified in §5).
- IEEE 830-1998 SRS structure (used as this document's skeleton).

### 1.6 Document Overview

§2 describes the product at a high level (personas, environment, constraints, assumptions). §3 defines external interfaces. §4 defines the data model shared by all clients. §5 is the detailed functional requirement set, organized by feature module, each requirement individually numbered and testable. §6 covers non-functional requirements. §7 covers the cross-platform account/sync architecture (the core technical challenge this project adds beyond a single-platform app). §8 lists out-of-scope items and open questions. §9 is acceptance criteria.

---

## 2. Overall Description

### 2.1 Product Perspective

SoloLevelUp is a new, self-contained product: one backend service (auth, data, sync, content) fronted by three independently-shipped clients that render the same domain model. There is no legacy system to integrate with; this is a greenfield build. The three clients are peers — none is a "master" — the backend is the single source of truth and all clients are thin(ish) views over it with local caching for offline use.

### 2.2 Product Functions (Summary)

1. **Account & Identity** — sign up, sign in, sign out, password reset, session management, shared across all three platforms.
2. **Challenge Management** — start/reset a challenge, configurable length, week/day navigation.
3. **Quest Management** — CRUD on quests, scheduling (everyday / N times per week / specific weekdays), difficulty, streaks, swipe-to-complete/skip, To-dos/Done/Skipped views.
4. **Metrics Rollup** — cumulative lifestyle counters derived from quest completions (water, showers, pages, custom metrics).
5. **Rise Rating Engine** — computes the six stats from completion history under three lenses (Current / Potential / Day 1) with deltas.
6. **Achievements** — catalog, unlock rules, locked/unlocked UI state, notification on unlock.
7. **Daily Learning** — curated book-summary content feed, recommendation logic, category filters, reading progress, "Done" tracking.
8. **Cross-Platform Sync** — real-time propagation of all state changes across a user's signed-in devices.
9. **Notifications** — reminders for pending quests, streak-at-risk alerts, achievement unlocks (push on Android/Windows, web push/browser notifications on Web).
10. **Claude MCP Integration** — an MCP server exposing the user's own progress, streaks, and Rise Rating to Claude as tools, and letting Claude create/adjust quests and generate new challenge weeks on the user's behalf (see §5.9).

### 2.3 User Classes and Characteristics

| Class | Description | Key needs |
|---|---|---|
| Primary user (self-improver) | Individual enrolled in their own challenge. | Fast daily check-in, motivating visuals, low friction to log a habit. |
| New/trial user | Has not yet completed onboarding/challenge setup. | Clear onboarding, sensible defaults, low-commitment entry point. |
| Returning multi-device user | Uses the app on, e.g., phone during the day and desktop/web at night. | Instant, reliable sync; no duplicate/lost completions. |
| Admin/content operator (internal) | Curates the Daily Learning catalog and Achievement catalog. | A CMS or admin API to publish content without a client release. |

### 2.4 Operating Environment

- **Web**: evergreen Chrome, Edge, Firefox, Safari (last 2 major versions); responsive from 360px mobile-web width up to desktop; installable as a PWA.
- **Android**: Android 9 (API 28) and above; phone and tablet layouts.
- **Windows**: Windows 10 21H2 and above, Windows 11; desktop windowed and maximized layouts, keyboard + mouse first-class.
- **Backend**: cloud-hosted (containerized), horizontally scalable, region configurable.

### 2.5 Design and Implementation Constraints

- One account model, one canonical dataset — no platform may hold data the others cannot eventually see.
- All quest-completion writes must be safe to perform offline and reconcile later (see §7.4 conflict resolution).
- Difficulty, streak, and Rise Rating calculations must be computed **server-side** (or in a shared library used identically by all clients) so the three platforms never disagree on a user's score.
- Content (Daily Learning catalog, Achievement catalog) is server-driven so it can be updated without app-store/store releases.

### 2.6 Assumptions and Dependencies

- Users have a valid email address or an OAuth-capable identity (Google/Apple/Microsoft) for account creation.
- Daily Learning content is generated, not licensed — see §5.7.1 for the concrete sourcing/generation pipeline (this replaces the earlier "assume content exists" placeholder).
- Push notification delivery depends on platform-native services (FCM for Android/Web push, WNS or a cross-platform push provider for Windows).
- Single-user deployment: the app is built for one account (the owner's). Multi-tenant concerns (per-user billing, admin moderation of other users' content, abuse handling) are out of scope; "admin" and "the user" are the same person, and the "admin API" in FR-6/FR-7 is simply an authenticated endpoint the owner (or Claude, via the MCP server in §5.9) calls directly.

---

## 3. External Interface Requirements

### 3.1 User Interfaces (per platform, common IA)

All three clients expose the same information architecture, adapted to platform conventions:

1. **Today / Quests** (home) — challenge day counter ("Day 15/66"), week progress dots, cumulative metric strip, To-dos / Done / Skipped tabs, swipeable quest cards.
2. **Rise Rating** — Current / Potential / Day 1 tabs, six stat tiles with score, delta, and progress bar.
3. **Achievements** — grid of badge tiles, locked state shows "?", unlocked shows artwork + name + unlock date; unlocked/total counter.
4. **Daily Learning** — Recommended / Done tabs, category filter, book cards (cover, title, author, rating, review count); tapping opens a full-screen reader.
5. **Quest Detail / Editor** — create/edit a quest: title, description, icon/image, repeat schedule, difficulty, linked metric (optional), reminder time.
6. **Settings/Account** — profile, linked sign-in methods, notification preferences, challenge configuration (length, start date, reset), data export, sign-out, delete account.
7. **Auth screens** — sign up, sign in, forgot password, OAuth provider buttons — visually consistent across platforms but implemented with each platform's native/appropriate auth UI pattern.

Interaction parity requirement: the **swipe-to-complete / swipe-to-skip** gesture on quest cards is a core brand interaction on touch platforms (Web mobile, Android); on Windows and desktop Web, an equivalent (click-drag or explicit Complete/Skip buttons plus keyboard shortcuts) must produce the identical resulting state change.

### 3.2 Hardware Interfaces

None required beyond standard platform APIs (touch input, notification services). No sensor integration in v1 (e.g., no automatic step/water tracking — all metric logging is manual, tied to quest completion).

### 3.3 Software Interfaces

- **Backend API**: Supabase's auto-generated REST/RPC layer plus Postgres Realtime (see §7.2), consumed identically by all three Flutter clients.
- **Auth provider**: Supabase Auth — OAuth 2.0 / OpenID Connect for Google/Apple/Microsoft sign-in, plus first-party email+password.
- **Push notification services**: FCM (Android, Web Push), and a Windows-compatible channel (WNS via FCM-to-WNS bridge, or a unified provider such as OneSignal/Firebase covering Windows via web-based notifications in the packaged app).
- **Content/admin API**: the same Supabase endpoints, called directly by the owner or by Claude via the MCP server (§5.9) for publishing Daily Learning items and Achievement definitions — no separate admin surface for a single-user deployment.
- **MCP server**: a stdio (local) or remote HTTP/SSE MCP server exposing the tools in §5.9, sitting alongside the three clients as a fourth consumer of the same backend.
- **Analytics/crash reporting**: a shared analytics SDK/event schema (see §6.6) instrumented identically on all three clients so funnels are comparable.

### 3.4 Communications Interfaces

- All client-server traffic over HTTPS/TLS 1.2+.
- Real-time updates over WebSocket (or long-lived SSE) for cross-device sync; REST/GraphQL fallback with polling if a persistent connection isn't available (e.g., background on mobile).

---

## 4. Data Model (shared across all clients)

This is the canonical domain model the backend owns; all three clients render views over it.

### 4.1 Entities

**User**
`id, email, display_name, auth_providers[], created_at, timezone, challenge_length_days (default 66), challenge_start_date, notification_prefs, premium_tier`

**Challenge**
`id, user_id, start_date, length_days, status (active/completed/reset), reset_count`
One user has one active Challenge at a time; history of past challenges retained for stats.

**Quest**
`id, user_id, title, description, icon_ref, repeat_rule (everyday | n_times_per_week:{n} | specific_weekdays:{[]}), difficulty (1-5), linked_metric_id (nullable), reminder_time (nullable), is_active, created_at, archived_at`

**QuestLogEntry**
`id, quest_id, user_id, challenge_day_number, date, status (done | skipped | pending), completed_at, device_id, client_write_id (idempotency key)`
One row per quest per scheduled occurrence. Streak is derived, not stored redundantly (or stored as a cached, server-recomputed value for read performance — see §5.3).

**MetricDefinition**
`id, key (e.g. "water_liters", "pages_read", "cold_showers"), display_name, unit, aggregation (sum | count), icon_ref` — system-defined defaults plus user-defined custom metrics.

**MetricEntry**
`id, user_id, metric_id, value, source_quest_log_entry_id (nullable, for auto-rollup), date`

**RiseRatingSnapshot**
`id, user_id, taken_at, lens (day1 | current — "potential" is computed on read, not stored), overall, wisdom, strength, focus, confidence, discipline`
Day-1 snapshot is written once at enrollment; "current" is recomputed continuously (see §5.4); "potential" is a pure function of current + remaining days + pace, never persisted.

**Achievement** (catalog, admin-managed)
`id, key, name, description, icon_ref, unlock_rule (machine-evaluable condition), sort_order, is_active`

**UserAchievement**
`id, user_id, achievement_id, unlocked_at`

**LearningItem** (catalog, admin-managed)
`id, title, author, cover_ref, category[], rating, rating_count, summary_text (chaptered), est_read_minutes, is_active`

**UserLearningProgress**
`id, user_id, learning_item_id, status (recommended | in_progress | done), progress_pct, last_read_at`

**Device**
`id, user_id, platform (web|android|windows), push_token, last_seen_at` — used for targeted push and for the "which device wrote this" audit trail used in conflict resolution.

### 4.2 Key Derived Values

- **Streak** for a quest = count of consecutive scheduled occurrences with `status = done`, walked backward from the most recent scheduled occurrence, per that quest's own `repeat_rule` calendar (a "3 times/week" quest's streak counts consecutive scheduled instances, not consecutive calendar days).
- **Cumulative metric totals** = `sum(MetricEntry.value)` grouped by `metric_id`, scoped to the active Challenge (and optionally lifetime).
- **Rise Rating deltas** = `current.stat − day1_snapshot.stat`.

---

## 5. Specific Functional Requirements

Each requirement is uniquely IDed for traceability into test cases. "Shall" denotes a mandatory requirement.

### 5.1 Account & Cross-Platform Identity

- **FR-1.1** The system shall allow account creation via email+password and via OAuth (Google, Apple, Microsoft), producing one unique `User` record regardless of method.
- **FR-1.2** A user shall be able to sign into Web, Android, and Windows clients with the same credentials and see the same account data on all three.
- **FR-1.3** The system shall support multiple concurrent authenticated sessions/devices per user without forcing sign-out of other devices.
- **FR-1.4** The system shall support password reset via emailed link, and account recovery for OAuth-only accounts via the provider.
- **FR-1.5** The system shall allow a signed-in user to view and revoke individual active sessions/devices from Settings.
- **FR-1.6** The system shall allow full account deletion, which cascades and deletes all Challenge, Quest, MetricEntry, RiseRatingSnapshot, Achievement, and Learning progress data for that user within 30 days, per applicable data-protection requirements.

### 5.2 Challenge Lifecycle

- **FR-2.1** On first sign-in, the system shall prompt the user to configure a Challenge: length in days (default 66), start date (default today).
- **FR-2.2** The Today screen shall display the current day as `Day {current}/{length}` and the current week-of-challenge (e.g., "First day of week 3"), computed from `challenge_start_date`.
- **FR-2.3** The Today screen shall provide previous/next day navigation, allowing the user to review (but not retroactively falsify completion state for) past days, and to preview upcoming scheduled quests.
- **FR-2.4** On reaching `length_days`, the system shall mark the Challenge `completed` and present a completion summary (final Rise Rating, achievements earned, metrics totals) before offering to start a new Challenge.
- **FR-2.5** A user shall be able to reset their current Challenge (restart day count at 1) at any time from Settings, with an explicit confirmation step warning that streaks reset.

### 5.3 Quest Management & Daily Execution

- **FR-3.1** A user shall be able to create a Quest with: title, optional description/motivational subtitle, optional icon/image, repeat schedule (Everyday / N times a week / specific weekdays), difficulty (1–5 stars), and optional linked metric with an increment value (e.g., "Drink 3L water" auto-adds 3.0 to `water_liters` on completion).
- **FR-3.2** A user shall be able to edit or archive (soft-delete) an existing Quest; archiving does not delete historical `QuestLogEntry` rows.
- **FR-3.3** The Today screen shall list all Quests scheduled for the current day as swipeable cards, each showing: title, subtitle, current streak in days, repeat rule, difficulty stars, and a swipe-to-complete (right) / swipe-to-skip (left) gesture, with an equivalent button/keyboard affordance on non-touch platforms.
- **FR-3.4** The Today screen shall provide three filtered views — **To-dos**, **Done**, **Skipped** — each labeled with a live count, reflecting the current day's quest statuses.
- **FR-3.5** Completing a quest shall be reversible on the same day (undo completion) without penalty to streak history.
- **FR-3.6** The system shall compute and persist streak count per Quest per FR-language in §4.2, recalculated on every status change and available for display within 1 second of the change on the originating device.
- **FR-3.7** If a scheduled quest occurrence is neither completed nor explicitly skipped by end of its scheduled day (in the user's timezone), the system shall mark it `skipped` automatically and this shall count against streak continuity.
- **FR-3.8** A quest with a `linked_metric_id` shall, on completion, write a corresponding `MetricEntry`; on undo, the system shall retract that entry.

### 5.4 Metrics Rollup Strip

- **FR-4.1** The Today screen shall display a horizontally-scrollable strip of cumulative metrics for the active Challenge (e.g., "39.0L water drank", "135 pages read", "N showers taken"), sourced from `MetricEntry` sums.
- **FR-4.2** Metric totals shall update within 1 second of a contributing quest completion/undo on the same device, and reflect on other devices per the sync latency target in §6.1.
- **FR-4.3** A user shall be able to define custom metrics (name + unit) and attach them to quests.

### 5.5 Rise Rating

- **FR-5.1** The system shall expose a "My Rise rating" screen with three tabs: **Current rating**, **Potential rating**, **Day 1 rating**.
- **FR-5.2** Each tab shall display six stat tiles — Overall, Wisdom, Strength, Focus, Confidence, Discipline — each with: a numeric score (0–100), a signed delta versus the Day 1 snapshot (e.g., "+41"), and a horizontal progress bar reflecting the score.
- **FR-5.3** "Day 1 rating" shall be an immutable snapshot captured at Challenge enrollment (or reset) and shall not change thereafter for that Challenge.
- **FR-5.4** "Current rating" shall be recomputed from the user's actual completion history (weighted by quest difficulty and category-to-stat mapping — see §5.5.1) and shall update after every quest status change.
- **FR-5.5** "Potential rating" shall be a computed projection assuming the user's trailing-N-day completion rate continues through the remaining Challenge days; it is never persisted and always derived at read time.
- **FR-5.6** Stat computation logic (the mapping of quest category/difficulty to stat point contributions) shall live in a single shared server-side module (or an identical shared library consumed by all clients) so Current/Potential/Day 1 values are never platform-dependent.

#### 5.5.1 Quest-to-Stat Mapping (initial rule set, admin-configurable)

Each Quest is tagged with one primary stat category at creation (default inferred from title, user-editable): e.g., "Wake up early" → Discipline; "Run 3km" → Strength; "Read" → Wisdom; "Cold shower" → Confidence; a planning/journaling quest → Focus. Completing a quest contributes `points = difficulty × category_weight` to that stat's running score, normalized into the 0–100 range; Overall is a weighted average of the other five.

### 5.6 Achievements

- **FR-6.1** The system shall maintain a global Achievement catalog (admin-managed, not per-user) with machine-evaluable unlock rules (e.g., "complete 30 quests total," "reach a 14-day streak on any quest," "finish a Challenge").
- **FR-6.2** The Achievements screen shall display all catalog achievements as a grid; locked achievements shall render as an obfuscated "?" tile without revealing name/description; unlocked achievements shall reveal artwork, name, and unlock date.
- **FR-6.3** The screen header shall show live progress as `You have unlocked {n}/{total} achievements.`
- **FR-6.4** The system shall evaluate unlock rules server-side on every relevant state change and, on unlock, shall (a) persist a `UserAchievement` row, (b) push a notification/toast to the originating device, and (c) reflect the unlock on all other signed-in devices within the sync latency target.
- **FR-6.5** Achievement unlock state shall never be revocable by client action (no "un-earning" an achievement via retroactive edits).

### 5.7 Daily Learning

- **FR-7.1** The Daily Learning screen shall present a **Recommended** tab (a ranked/curated feed of `LearningItem`s not yet started or completed) and a **Done** tab (items the user has finished), plus a category filter control.
- **FR-7.2** Each `LearningItem` card shall display cover art, title, author, star rating, and rating count.
- **FR-7.3** Selecting an item shall open a full-screen reader presenting the chaptered `summary_text`, with scroll-based progress tracking persisted to `UserLearningProgress.progress_pct`.
- **FR-7.4** Reaching the end of a summary shall mark the item `done`, move it out of Recommended and into the Done tab, and (if configured) contribute to the Wisdom stat per §5.5.1.
- **FR-7.5** Reading progress on a given item shall resume from the last-read position when reopened on any device.
- **FR-7.6** The system shall never surface the same `LearningItem` twice in the Recommended feed within one full cycle of the catalog (i.e., "unique every day" means *no repeats until every item has been shown*, not that content is regenerated from scratch daily).

#### 5.7.1 Content Sourcing Pipeline (copyright-safe, zero recurring cost)

There is no free, legal API for ready-made commercial book summaries (services like Blinkist license their summaries and don't expose a public API; reproducing their or a publisher's copyrighted condensation verbatim would also infringe copyright even if scraped). The pipeline below avoids both problems by never storing or displaying anyone else's copyrighted summary text — every `summary_text` in the catalog is **original text synthesized specifically for this app**, seeded from free public *metadata* only:

1. **Metadata source (free, no key required for light use):** the [Open Library Books API](https://openlibrary.org/dev/docs/api/books) and/or the [Google Books API](https://developers.google.com/books) supply title, author, publication year, subject/category tags, and a short public-domain-safe blurb for virtually any book — used only to identify *which* book and *what it's broadly about*, never copied into `summary_text`.
2. **Summary generation:** for each catalog entry, Claude is given the book's title/author/subject metadata and writes an original ~400–600 word insight-card summary in the app's own voice (key ideas, one or two actionable takeaways, tone matching the "Rise" framing) — this is original synthesis from public knowledge of the book's ideas, not a reproduction of the book's or any third party's copyrighted prose, which is the same legal posture as a human writing their own book-report notes.
3. **Batch pre-generation, not live daily calls:** because this is a personal single-user app, the cheapest and simplest approach is to generate a batch (e.g., 100–365 items) **once**, in an ordinary Claude conversation (using the subscription the user already has — $0 marginal cost, no API billing), and bulk-insert the results into `LearningItem` via the MCP `add_learning_item` tool (§5.9) or a one-off seed script. Refilling the catalog later (another 100 items every few months) is the same zero-cost action.
4. **Optional live automation:** if the user later wants the catalog to top itself up automatically without a manual chat session, an Edge Function can call the Claude API on a weekly cron to generate a handful of new items — this is the *one* place a small real operating cost can appear (a short summary is a fraction of a cent to a few cents per item on current Claude pricing), and is opt-in, not required for v1.
5. **Daily selection ("Recommended" ordering):** a deterministic function — `catalog[(challenge_day_number + user_cycle_offset) % catalog_size]`, skipping items already marked `done` — picks the day's featured item, guaranteeing no repeat until a full pass through the catalog, with zero server compute beyond a modulo.
6. **Attribution, not reproduction:** each item still credits the real book/author for discoverability (title, author, cover art placeholder or a licensed-for-use generic cover), but the summary body itself is the app's own generated content — this is what makes it legally distributable/displayable even though the underlying books are copyrighted.

### 5.8 Notifications

- **FR-8.1** The system shall send a daily reminder notification (time configurable per user) if any of the day's quests remain in `pending` status.
- **FR-8.2** The system shall send a "streak at risk" notification for quests with a streak ≥ 3 that remain pending within a configurable window before the automatic-skip cutoff (FR-3.7).
- **FR-8.3** The system shall send an achievement-unlocked notification at the moment of unlock.
- **FR-8.4** Notification delivery shall target only the user's currently-registered `Device` push tokens for the platform capable of receiving it (Android/Windows native push, Web Push where the browser permission is granted).
- **FR-8.5** A user shall be able to enable/disable each notification category independently in Settings, and this preference shall apply uniformly regardless of which platform they're currently on.

### 5.9 Claude MCP Integration

An MCP (Model Context Protocol) server exposes the same backend the three clients use, as a set of tools, so Claude (in Claude Desktop, Claude Code, or as a claude.ai custom connector) can act as a coach: reviewing progress and authoring/adjusting the user's quests and challenges directly, instead of the user hand-entering everything in the app.

- **FR-9.1** The MCP server shall expose read tools: `get_today` (current day's quests + statuses), `get_rise_rating` (all three lenses), `get_streaks`, `get_achievements`, `get_metrics_summary` — each returning the same data the clients render, sourced from the same backend (no separate data path, per AR-1).
- **FR-9.2** The MCP server shall expose write tools: `create_quest`, `update_quest`, `archive_quest`, `complete_quest`, `skip_quest` — subject to the identical server-side validation and stat/streak recomputation as a write from a client app (AR-7); an MCP-originated write is indistinguishable from a client write once persisted, and syncs to all open clients per NFR-1.2.
- **FR-9.3** The MCP server shall expose a `generate_challenge_week` tool that, given the user's current Rise Rating, recent completion rate, and (optionally) a natural-language goal from the user (e.g., "focus on Strength this week," "I'm traveling, make it lighter"), proposes a set of quests for the coming week; proposed quests shall be staged for the user's confirmation by default (not silently activated), with an explicit `auto_apply` flag the user can enable once they trust the suggestions.
- **FR-9.4** The MCP server shall expose `add_learning_item` (per §5.7.1) so Claude can top up the Daily Learning catalog directly from a chat session.
- **FR-9.5** The MCP server shall authenticate as the single app owner using a long-lived personal access token or the backend's service-role credential, scoped only to that one account — no multi-user auth flow is required (per §2.6, single-user deployment).
- **FR-9.6** The MCP server shall be runnable either locally over stdio (attached to Claude Desktop/Claude Code, zero hosting cost, recommended default for a personal project) or deployed as a small remote HTTP/SSE MCP endpoint (e.g., on a free-tier edge function host) and added as a claude.ai custom connector, for access from a phone or web-based Claude session without a local machine running.

---

## 6. Non-Functional Requirements

### 6.1 Performance & Sync Latency

- **NFR-1.1** A state-changing action (quest complete/skip/undo) shall be reflected in that client's own UI in **< 150 ms** (optimistic local update).
- **NFR-1.2** The same change shall be visible on the user's other actively-open, network-connected devices within **≤ 3 seconds (p95)** of the server accepting the write.
- **NFR-1.3** Cold app start to interactive Today screen shall be **< 2.5 s** on a mid-tier Android device and **< 1.5 s** on Web/Windows with warm cache.
- **NFR-1.4** The backend API shall sustain **p99 < 300 ms** for read endpoints and **p99 < 500 ms** for write endpoints at target launch scale (see NFR-3.1).

### 6.2 Reliability & Offline Behavior

- **NFR-2.1** All three clients shall support offline quest completion/skip/undo, queuing writes locally and syncing on reconnect (see §7.4 for conflict resolution rules).
- **NFR-2.2** No user-initiated write shall be silently lost; a write that ultimately fails to sync after retries shall surface a visible, actionable error to the user.
- **NFR-2.3** Backend service uptime target: **99.9%** monthly, excluding scheduled maintenance windows communicated in advance.

### 6.3 Security

- **NFR-3.1** All network traffic shall use TLS 1.2+; no plaintext credential or token transmission.
- **NFR-3.2** Passwords shall be hashed with a modern adaptive algorithm (Argon2id or bcrypt with an appropriate work factor); plaintext passwords shall never be logged or stored.
- **NFR-3.3** Session tokens shall be short-lived access tokens (e.g., JWT, ≤ 1 hour) plus long-lived refresh tokens, revocable per-device (supports FR-1.5).
- **NFR-3.4** All user data at rest shall be encrypted using provider-managed encryption at minimum.
- **NFR-3.5** The system shall enforce authorization such that a user can only read/write their own `User`-scoped data; catalog data (Achievements, LearningItems) is read-only to end users.
- **NFR-3.6** The system shall rate-limit authentication endpoints to mitigate credential-stuffing/brute-force attempts.

### 6.4 Usability & Accessibility

- **NFR-4.1** All three clients shall meet WCAG 2.1 AA for color contrast, focus indication, and screen-reader labeling of interactive elements (quest cards, stat tiles, achievement tiles).
- **NFR-4.2** The swipe-to-complete/skip gesture shall have a fully keyboard- and screen-reader-operable equivalent on every platform (not just Windows/desktop Web).
- **NFR-4.3** UI text, dates, and units (metric/imperial for metrics like liters) shall support localization infrastructure even if v1 ships English-only.

### 6.5 Portability & Consistency

- **NFR-5.1** Business logic that affects correctness across devices (streak calculation, Rise Rating computation, achievement unlock evaluation) shall be implemented once, server-side, and never duplicated with platform-specific logic that could drift.
- **NFR-5.2** Visual/interaction design shall follow one shared design system (spacing, color, typography, iconography) adapted per platform idiom (Material on Android, Fluent on Windows, responsive web patterns), so the product is recognizably "the same app" everywhere.

### 6.6 Observability

- **NFR-6.1** All three clients shall emit a common analytics event schema (e.g., `quest_completed`, `quest_skipped`, `achievement_unlocked`, `learning_item_finished`) with a shared property set, enabling cross-platform funnel analysis.
- **NFR-6.2** The backend shall expose structured logs and metrics (request latency, error rate, sync queue depth) to support the SLOs in §6.1–6.2.
- **NFR-6.3** Crash/error reporting shall be wired on all three clients with symbolication for release builds.

### 6.7 Maintainability

- **NFR-7.1** The Achievement catalog and Daily Learning catalog shall be editable via an internal admin interface/API without requiring a client app release.
- **NFR-7.2** The API shall be versioned; a breaking change requires a new version path and a documented client-compatibility window.

---

## 7. Cross-Platform Account & Architecture Requirements

This section exists because "same account, three platforms" is the central technical risk of this project and deserves explicit architectural requirements, not just a feature list.

### 7.1 Single Identity, Single Dataset

- **AR-1** There shall be exactly one backend service and one database of record. Web, Android, and Windows are clients of that service; none may maintain an independent authoritative copy of user data.
- **AR-2** Authentication shall be centralized (e.g., a dedicated auth provider or a self-hosted OAuth2/OIDC-compliant service) issuing tokens honored identically by all three clients against the same API.

### 7.2 Technology Stack (decision)

Given a personal, single-user deployment where aesthetic polish and animation quality matter (this is a visually-driven, game-like product) and ongoing cost must stay at $0, the stack is:

- **Client framework — Flutter.** One Dart codebase compiles to Android (native ARM), Windows (native Win32 desktop), and Web (CanvasKit/WASM), which directly satisfies AR-1's "no platform-specific drift" concern for free, since there is only one UI implementation to begin with. Flutter's own rendering engine (Impeller/Skia) draws every pixel itself rather than delegating to each OS's native widget set, which is what makes it the better choice here over React Native: this app leans heavily on custom, game-like visual language (gradient glows, particle-style "level up" effects, swipeable quest cards with physics, animated stat bars) that needs to look *identical* and feel equally smooth on all three platforms, not merely "close enough" per-platform. `react-native-windows` is also comparatively less mature/maintained than Flutter's Windows target. State management: **Riverpod**. Rich animation: Flutter's own animation APIs for most UI, **Rive** for the achievement-unlock/level-up set-pieces (free tier is enough for personal use). Local cache/offline queue: **Drift** (SQLite) implementing the write-queue behavior in NFR-2.1/AR-4.
- **Backend — Supabase.** Managed Postgres (maps directly onto §4's relational data model), built-in Auth (email+password and Google/Apple/Microsoft OAuth, satisfying FR-1.1–FR-1.2 out of the box with one SDK call per client), Realtime (Postgres change-data-capture over WebSocket, satisfying AR-3's cross-device push without hand-rolling a socket server), Storage (achievement art, book covers), and Edge Functions (Deno/TS) for the server-side-only logic AR-1/NFR-5.1/AR-7 require: streak computation, Rise Rating computation, achievement unlock evaluation, and the daily-learning selection function in §5.7.1. This replaces a hand-built Node/NestJS API with a managed equivalent that has a free tier generous enough for one user indefinitely (see the cost note in §7.7).
- **Shared client logic**: API client, cache layer, offline write queue, and auth/session handling live in one Dart package shared by all three Flutter targets — there is no second implementation to keep in sync.

### 7.3 Real-Time Sync

- **AR-3** The system shall support a real-time update channel so that a change made on Device A appears on Device B without the user manually refreshing, whenever Device B is foregrounded and network-connected (per NFR-1.2).
- **AR-4** When a client reconnects after being offline, it shall reconcile by pulling all server-side changes since its last known sync cursor (not a full re-download), and shall push any locally-queued writes.

### 7.4 Conflict Resolution

- **AR-5** Each write from a client shall carry a client-generated idempotency key (`client_write_id`) so retried/duplicate submissions (e.g., after a flaky offline reconnect) are not double-applied.
- **AR-6** For same-entity conflicting writes made offline on two devices before either synced (e.g., quest marked done on phone, then marked skipped on desktop before phone's write synced), the system shall apply **last-write-wins by server-received timestamp**, and surface a non-blocking notice to the losing device ("this was updated on another device") rather than silently overwriting without any trace.
- **AR-7** Derived values (streak, Rise Rating, metric totals, achievement unlock state) shall always be recomputed server-side from the reconciled event log after any conflict resolution — never trusted from client-cached derived values.

### 7.5 Device Management

- **AR-8** The system shall track a `Device` record per signed-in client install (per §4.1) to support targeted push notifications and the session list in FR-1.5.

### 7.6 MCP Server Architecture

- **AR-9** The MCP server (§5.9) shall be a thin wrapper over the same Supabase backend the clients use — it calls the same tables/RPCs/Edge Functions, never a parallel data path — so a quest Claude creates behaves identically to one created in the app (AR-1, AR-7).
- **AR-10** For a single-user deployment, the recommended default is a **local MCP server run over stdio** (Python `FastMCP` or the Node MCP SDK), holding the Supabase service-role key in a local `.env` file, launched by Claude Desktop/Claude Code's MCP config — this requires no hosting, no public endpoint, and no additional cost or attack surface beyond the user's own machine.
- **AR-11** If remote access (e.g., from claude.ai on a phone) is desired, the same server logic shall be deployable as a small remote MCP endpoint on a free-tier edge platform (e.g., Cloudflare Workers, which has first-class MCP hosting support) and registered as a claude.ai custom connector; this is additive, not a replacement for AR-10.

### 7.7 Cost Note (personal deployment)

- Supabase free tier (500MB DB, 50k MAU, 1GB storage, 5GB egress/mo) comfortably covers a single-user account indefinitely.
- Flutter builds for Android/Windows are sideloaded directly (no Google Play $25 fee or Microsoft Store account needed for personal use); Web build deploys free to Cloudflare Pages/Vercel.
- The MCP server run locally (AR-10) has zero hosting cost; the optional remote variant (AR-11) fits Cloudflare Workers' free tier.
- The only place a non-zero recurring cost can appear is the *optional* live Daily Learning automation in §5.7.1 step 4 (Claude API calls on a cron) — skip it and use the manual batch-generation approach (step 3) to stay at exactly $0.

---

## 8. Out of Scope / Deferred (v1)

- Native iOS/macOS clients.
- Social features: friends, leaderboards, sharing streaks publicly.
- Wearable/sensor auto-tracking of metrics (step count, water intake via smart bottle, etc.) — v1 logging is manual via quest completion.
- Multiple simultaneous active Challenges per user.
- In-app monetization beyond a single premium tier gate (premium feature set itself to be defined in a follow-up doc).
- Coach/human-guided programs; this is a self-directed tool in v1.
- Content authoring tooling polish — v1 assumes a minimal internal admin API/CLI for catalog management, not a full CMS UI.

## 9. Open Questions

1. ~~Final client technology stack~~ — **resolved**: Flutter + Supabase (§7.2).
2. ~~Daily Learning content source~~ — **resolved**: Claude-generated original summaries seeded from free book metadata, batch-generated at $0 marginal cost (§5.7.1).
3. Exact quest-category → stat weighting formula (§5.5.1) — needs the user's own sign-off on initial values and tuning process (no separate "product team" in a personal deployment — this is just a taste call).
4. Push provider for Windows (native WNS vs. unified provider) — depends on the Windows packaging decision (MSIX vs. unpackaged .exe); low priority for a single-user app since in-app "streak at risk" state is also visible on open.
5. Data retention window after account deletion (FR-1.6 proposes 30 days) — low-priority for single-user deployment (no compliance obligation to a third party), but a sane default to keep for hygiene.
6. Whether to enable the optional live Daily Learning automation (§5.7.1 step 4, the only component with a non-zero recurring cost) — default is **off** (manual batch generation) unless the user wants full hands-off automation.

## 10. Acceptance Criteria (Definition of Done for this SRS's implementation)

The v1 build satisfies this SRS when:

- A user can create one account and use it, with full data parity, on Web, Android, and Windows (AR-1, AR-2, FR-1.2).
- A quest completed on one device is visible, with correct streak/metric/Rise-Rating updates, on a second signed-in device within the latency target (NFR-1.2) without manual refresh (AR-3).
- The Today, Rise Rating, Achievements, and Daily Learning screens exist and behave per §5.3–5.7 on all three platforms, including a non-touch-equivalent for the swipe gesture (FR-3.3, NFR-4.2).
- Streak, Rise Rating, and achievement-unlock values are identical across platforms for the same account at the same point in time (NFR-5.1), verified by a cross-platform parity test suite.
- Offline quest completion syncs correctly on reconnect with no data loss and documented conflict-resolution behavior (NFR-2.1, AR-6).
