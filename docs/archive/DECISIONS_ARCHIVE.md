# DECISIONS_ARCHIVE.md — Historical & Superseded Decisions

Decisions that were real at the time but **no longer constrain future work** — either the code they governed is gone, or a later ADR expanded on them. Preserved for the historical record; moved out of `../DECISIONS.md` so that file contains only what still binds.

ADR numbering is global and shared with `../DECISIONS.md`; numbers are never reused.

---

## ADR-014 — Documentation restructured into `docs/`, with `CLAUDE.md` at root
**2026-07-29 · Status: HISTORICAL** (the structure it created was later reorganized again — see `../../CLAUDE.md`'s Startup Protocol for the current arrangement)

**Problem:** A single, ever-growing conversation is a bad place to store project knowledge — it gets compacted or deleted, and nothing in it is discoverable by a fresh session without being told to look.

**Options:** (1) keep everything in one `CLAUDE.md`; (2) split into ten files, all at repo root; (3) split into ten files, everything except `CLAUDE.md` under `docs/`.

**Decision:** Option 3. `CLAUDE.md` and `README.md` stay at root — the two things a human or a fresh Claude session looks for first — and everything else lives in `docs/`, including `PROJECT_SPEC.md`, moved there for consistency even though it predated the restructure.

**Reasoning:** Keeps the repo root readable for a human browsing on GitHub while still giving a fresh session one obvious entry point that points into the rest.

**Tradeoffs:** `PROJECT_SPEC.md` moved out from under any tooling or muscle memory referencing it at root — mitigated by fixing every in-repo reference in the same change.

---

## ADR-008 — `AccentColor` is a curated, closed 8-case enum, not an open color picker (first pass)
**2026-07-23 · Status: SUPERSEDED in scope by ADR-012** (the curated-first *pattern* still holds; the closed-palette *scope* was later widened by an additive custom-color override)

**Problem:** Add an app-wide accent color setting, reusing or extending the existing per-habit color concept.

**Options:** (1) reuse the existing curated `AccentColorPickerView` as-is for the app-wide setting too; (2) add a native `ColorPicker` for an open, arbitrary app-wide color.

**Decision:** Option 1.

**Reasoning:** Keeps a single, cohesive, curated visual identity rather than letting the app-wide tint diverge arbitrarily from the per-habit palette.

**Tradeoffs:** None at the time — the simplest option, directly reusing an already-built, already-tested component. This decision is what later created the real tension resolved in ADR-012, when a genuine "exact custom color" request arrived.

**Still binding today:** the 8 curated cases and their raw values remain protected — see `../../CLAUDE.md`'s "Never Change Without Explicit Approval."

---

## ADR-005 — Onboarding replaces silent starter-habit auto-seeding
**2026-07-23 · Status: HISTORICAL** (the seeding code it replaced, `HabitService.seedStarterHabitsIfNeeded`, no longer exists)

**Problem:** Before onboarding existed, `TodayView` silently created Prayer/Gym/Work the first time it rendered with zero habits, and `RootTabView` requested location permission unconditionally on every cold launch — both with no context shown to the user first.

**Options:** (1) leave the silent behavior and add an onboarding flow on top of it; (2) replace the silent seeding entirely, making onboarding the only path that creates starter habits, with permission requests conditional on what the user actually chose.

**Decision:** Option 2.

**Reasoning:** The silent version also had a real bug — the auto-seeded Prayer habit's `reminderEnabled: true` never resulted in an actually-scheduled notification, because `HabitService.create()` was called directly rather than through `AddEditHabitViewModel.save()`, the one path that requests notification permission and schedules. Routing all first-run habit creation through the same explicit flow fixed this as a side effect rather than as a separate fix.

**Tradeoffs:** None significant — a straightforward improvement with no real downside identified.

**Durable lesson:** a code path that bypasses the "one real path" for creating something will silently skip whatever that path does. Worth checking for whenever a convenience/seeding shortcut exists.

---

## ADR-004 — `Frequency.displayName` lives on the Model, not a ViewModel
**2026-07-23 · Status: HISTORICAL** (a one-time relocation, long since done; the underlying rule — no duplicated business logic — lives in `../../CLAUDE.md`)

**Problem:** `ExportService` needed the same human-readable frequency string ("Every day", "5x per week") that `HabitsViewModel.frequencyDescription(for:)` already computed.

**Options:** (1) write a third copy of the logic inside `ExportService`; (2) have `ExportService` depend on `HabitsViewModel`; (3) move the logic to `Frequency.displayName` on the Model layer and have both callers delegate to it.

**Decision:** Option 3.

**Reasoning:** Option 2 is backwards in the dependency graph — Services must not depend on ViewModels. Option 1 duplicates business logic, which `CLAUDE.md` explicitly forbids. Option 3 matches the existing convention (every other enum in the codebase — `PrayerCalculationMethod`, `AppAppearance`, `TimeOfDayPeriod`, `InsightsRange` — already has its own `displayName`) and was a purely mechanical relocation with zero behavior change at the one existing call site.
