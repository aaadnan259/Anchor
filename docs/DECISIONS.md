# DECISIONS.md

Architectural Decision Record. One entry per non-obvious choice — not every line of code, only the ones where a reasonable alternative existed and was consciously rejected. Newest first.

---

## ADR-015: Below-target quantifiable heatmap days reuse `.partial`, not a new `DayCompletionState` case

**Date:** 2026-07-30

**Problem:** `TODO.md`/`KNOWN_ISSUES.md` flagged that a quantifiable habit logged below target rendered identically to a day with nothing logged at all (both `.missed`), with no way to tell "attempted but short" from "did nothing" in the heatmap. The original backlog wording assumed closing this would need "a new `DayCompletionState` case or a richer value on the existing ones, plus a new heatmap color."

**Options considered:**
1. Reuse the existing `.partial` case — extend `dailyHistory`'s `completedCount == 0` branch to check `CompletionService.value`, and report `.partial` if it's greater than zero. No new enum case, no new heatmap color; `HabitHistoryGridView` needs zero changes.
2. Add a new `DayCompletionState` case (e.g. `.attemptedBelowTarget`) with its own heatmap color.

**Decision:** Option 1.

**Reasoning:** `.partial` already means "attempted but not fully done" for multi-occurrence habits — extending that same meaning to "attempted but below target" for quantifiable (single-occurrence) habits is a coherent, not overloaded, use of the existing state. It closes the actual gap (distinguishing attempted-but-short from did-nothing) with a one-line change to `StreakService`, versus a new case touching the enum, the heatmap color function, and every switch statement over `DayCompletionState`.

**Tradeoffs:** A multi-occurrence "some done" day and a quantifiable "some progress" day now render identically in the heatmap. Judged acceptable since both mean the same thing to a user glancing at the grid ("you did something, just not enough") and no habit is ever both multi-occurrence and quantifiable (ADR-010 scopes quantifiable to single-occurrence habits only), so the two meanings never collide on the same habit's history.

**Also clarified during this work:** a shielded quantifiable day was never actually part of this gap — `CompletionService.isShielded` is already checked before the `completedCount == 0` branch in `dailyHistory`, so a shielded day correctly reports `.shielded` regardless of any logged value. The original backlog wording bundled "shielded" and "below-target" together; only the latter was a real gap.

---

## ADR-014: Documentation restructured into `docs/`, with `CLAUDE.md` staying at root

**Date:** 2026-07-29

**Problem:** A single, ever-growing conversation is a bad place to store project knowledge — it gets deleted or compacted, and nothing in it is discoverable by a fresh session without being told to look.

**Options considered:**
1. Keep everything in one `CLAUDE.md`.
2. Split into the ten files requested, all at repo root.
3. Split into the ten files, move everything except `CLAUDE.md` into `docs/`.

**Decision:** Option 3. `CLAUDE.md` and `README.md` stay at root (the two things a human or a fresh Claude session would look for first); everything else — including `PROJECT_SPEC.md`, moved there from root for consistency even though it predates this restructure — lives in `docs/`.

**Reasoning:** Keeps the repo root readable for a human browsing on GitHub, while still giving a fresh Claude session one obvious entry point (`CLAUDE.md`) that points into the rest.

**Tradeoffs:** `PROJECT_SPEC.md` moved out from under any existing tooling or muscle memory that referenced it at root — mitigated by fixing every in-repo reference to the new path as part of the same change.

---

## ADR-013: Quick Shields stay at habit-day granularity; no per-occurrence shielding

**Date:** 2026-07-29

**Problem:** The Quick Shields feature request said "shield either the whole day or just the task for that day." For single-occurrence habits those are the same thing; for multi-occurrence habits (Prayer) they're not — the existing `Shield` model has no occurrence reference, so "just the task" isn't representable today.

**Options considered:**
1. Keep `Shield` at habit-day granularity (existing model, unchanged). The dashboard gets one "Shield Today" action per habit card.
2. Add true per-occurrence shielding — `Shield` gains an optional `occurrence` reference, and `StreakService`/`dailyHistory` need new logic for "day partially shielded."

**Decision:** Option 1, chosen by the user via `AskUserQuestion` after the tradeoff was surfaced directly.

**Reasoning:** Option 2 requires deciding how a per-occurrence shield interacts with the already-tested `isFullyCompleted`/streak-priority logic for a day where some occurrences are shielded and others aren't completed — genuine new streak semantics, not just new UI, and risk to code that's covered by 40+ existing tests. Option 1 needed zero changes to `Shield`, `StreakService`, or any tested logic — only new UI wiring (`TodayViewModel` pass-throughs, a `HabitCardView` context menu, wiring the previously-dead `Frequency.supportsShields`).

**Tradeoffs:** A user can't shield just one prayer within a Prayer habit's day from the dashboard — only the whole day. Judged acceptable since `Gym`/`Work`/`Custom` (single-occurrence) habits, the majority case, have no such gap at all.

---

## ADR-012: Custom accent color is an additive override, not a replacement of the curated enum

**Date:** 2026-07-29

**Problem:** A request for "exact custom colors" arrived that, taken literally, conflicts with an already-shipped decision (ADR-008 below) to keep `AccentColor` a curated, closed palette.

**Options considered:**
1. Add a "Custom…" swatch alongside the existing 8, backed by a native `ColorPicker`, stored as a new optional `customColorHex` field that overrides the curated color when set. `AccentColor` itself untouched.
2. Skip true custom colors; just add more curated swatches.
3. Replace `AccentColor` everywhere with an open hex/RGB value.

**Decision:** Option 1, chosen by the user via `AskUserQuestion` after research showed the real blast radius of option 3.

**Reasoning:** Research (via a parallel Explore pass) found `AccentColor` persisted via `rawValue` in *both* SwiftData (`Habit.accentColor`) and UserDefaults (`SettingsService.accentColor`), plus 13+ view call sites hardcoding specific named cases as decorative/preview tints unrelated to any real habit. Option 3 would touch every one of those, both persistence layers, and every test fixture using a named case — for a "give me an exact color" ask that option 1 satisfies just as well with a fraction of the blast radius.

**Tradeoffs:** Two color concepts now coexist (`accentColor: AccentColor`, always set, and `customColorHex: UInt?`, the override) rather than one unified type. Every "what color is this habit" call site must remember to read the computed `tintColor`/`effectiveAccentColor` accessor, not `accentColor.color` directly, or it'll ignore an active custom color. Mitigated by naming the accessor distinctly and grepping every live (non-decorative) call site to swap them during implementation.

---

## ADR-011: Emoji icon entry via a text field + system keyboard, not a curated grid

**Date:** 2026-07-29

**Problem:** Users should be able to set a habit's icon to an emoji. How do they pick one?

**Options considered:**
1. A constrained text field relying on iOS's own emoji keyboard (tap the globe key).
2. A curated grid of common emoji, like the existing SF Symbol grid.

**Decision:** Option 1, chosen by the user via `AskUserQuestion`.

**Reasoning:** Gives access to every Apple emoji with zero curation or upkeep burden as new emoji ship each year. Matches how Notes/Notion/Reminders handle the same "custom icon" problem. A curated grid would need to be chosen, maintained, and would always be a strict subset.

**Tradeoffs:** No visual browsing UI within the app — the user must already know roughly which emoji they want and reach for the system keyboard. Judged acceptable since this mirrors standard iOS conventions the target audience already knows.

---

## ADR-010: Quantifiable habits are `Int`, scoped to single-occurrence (Custom) habits only

**Date:** 2026-07-24

**Problem:** Add numeric habit tracking ("8 glasses of water") without a rewrite of the completion/streak model.

**Options considered:**
1. `Int` target/value, single-occurrence habits only, threshold logic added to `CompletionService.isCompleted`.
2. `Double` target/value, to support fractional targets (e.g. "2.5 miles").
3. Allow quantifiable targets on multi-occurrence habits too (e.g. "5 prayers, but also track total prayer minutes").

**Decision:** Option 1.

**Reasoning:** `Int` matches the existing `timesPerWeekTarget: Int` precedent in the same view model and avoids floating-point threshold-comparison edge cases; every realistic use case (glasses, minutes, pages, steps) is whole numbers anyway. Restricting to single-occurrence habits means "reached target" has one unambiguous meaning — a numeric target doesn't map cleanly onto "5 prayers," and none of the built-in presets asked for it.

**Tradeoffs:** No fractional targets (can't track "2.5 miles" exactly, would round). No numeric tracking on Prayer-style habits. Both judged out of scope for a feature explicitly aimed at things like water/pages/steps.

**Load-bearing implementation detail:** `CompletionService.isCompleted` becoming threshold-aware (`completion.value >= target` when `habit.targetValue` is set, existence-based otherwise) is the *only* change needed — every consumer (`StreakService`, `InsightsService`, the notification gate) already calls through this method rather than re-implementing "is this done," so the new semantics propagated automatically. See ADR-002.

---

## ADR-009: Streak Shields are habit-day granularity, not per-occurrence (first pass)

**Date:** 2026-07-24

**Problem:** Let a user protect a streak for a day they can't complete a habit (vacation, illness) without it resetting to zero.

**Options considered:**
1. A `Shield` model at habit+day granularity (no occurrence reference).
2. A `Shield` model with an optional occurrence reference from the start.

**Decision:** Option 1.

**Reasoning:** The backlog's own framing ("vacation/illness... don't reset a streak to zero") never called for occurrence-level granularity, and it's simpler to reason about in `StreakService`'s already-tested streak logic. This decision was later revisited and reconfirmed for the *dashboard* quick-action in ADR-013 above — the answer was the same both times, for the same reason.

**Reasoning for exclusion from `.timesPerWeek` habits:** a weekly-target streak is already forgiving (missing 1-2 days rarely breaks a "3x/week" streak), and shielding one would require inventing an ambiguous semantic (does a shield count as a free completion? reduce the effective target?) the backlog didn't call for.

**Tradeoffs:** `StreakService.dailyHistory`'s `.partial` state (for multi-occurrence "some but not all done") and a below-target quantifiable day both currently render identically to `.missed` in the heatmap — a minor display-richness gap, not a correctness bug, deliberately not fixed in the same pass.

**Reconfirmed 2026-07-31:** a request to make Shields available for the "Gym" preset (which defaults to `.timesPerWeek`) surfaced this exact exclusion again. Rather than silently extending shield semantics to weekly-goal habits, the conflict with this ADR was surfaced to the user via `AskUserQuestion` — options were "invent the missing semantics and extend shields," "make Gym itself shieldable by changing its default frequency instead," or "leave as-is." The user chose to leave the existing scoping untouched. No code changed.

---

## ADR-008: `AccentColor` is a curated, closed 8-case enum — not an open color picker (first pass)

**Date:** 2026-07-23

**Problem:** Add an app-wide accent color setting, reusing or extending the existing per-habit color concept.

**Options considered:**
1. Reuse the existing curated `AccentColorPickerView` as-is for the app-wide setting too.
2. Add a native `ColorPicker` for an open, arbitrary app-wide color.

**Decision:** Option 1.

**Reasoning:** Keeps a single, cohesive, curated visual identity across the app rather than letting the app-wide tint diverge arbitrarily from the per-habit palette. This decision is what later created the real tension resolved in ADR-012 above, when a genuine "exact custom color" request arrived — at that point the *pattern* (curated-first, open-color-as-an-addition) held, but the *scope* expanded to include an exact-color option.

**Tradeoffs:** None at the time — this was the simplest option and directly reused an already-built, already-tested component.

---

## ADR-007: Smart Reminders don't try to be "live"

**Date:** 2026-07-23

**Problem:** A local notification scheduled ahead of time can't know, at the moment it fires, whether the habit it's nudging about has since been completed — leading to stale "you haven't done X" notifications after X is actually done.

**Options considered:**
1. Build a Notification Service Extension (a new Xcode target) to compute content live at fire time.
2. Don't try to be live — make content "fresh as of the last reschedule," and make reschedules frequent enough that staleness is rare in practice.

**Decision:** Option 2.

**Reasoning:** `NotificationService.rescheduleAll` already runs on app launch, every foreground, and every habit edit. As long as the user opens the app at least once during the day — a safe assumption for a habit tracker they're actively using — the evening nudge gets recomputed against real completion state. A Notification Service Extension is the same category of scope jump as Widgets (a new Xcode target), deliberately avoided for a gap that's narrow (complete a habit, then background the app and never reopen it before 8pm) and low-stakes (worst case: one redundant "gentle nudge").

**Tradeoffs:** The narrow gap above is real and accepted, not silently ignored — documented explicitly rather than glossed over.

---

## ADR-006: Biometric lock re-locks on every background→foreground, not just cold launch

**Date:** 2026-07-23

**Problem:** When should the app require re-authentication?

**Options considered:**
1. Only on cold launch.
2. Every background→foreground transition.

**Decision:** Option 2.

**Reasoning:** Matches the standard pattern for exactly this feature in banking apps and password managers — the category of app where users already expect this behavior.

**Tradeoffs:** Slightly more friction (a quick app-switch away and back re-triggers Face ID) than option 1, judged correct for a privacy feature whose whole point is that friction.

---

## ADR-005: Onboarding replaces silent starter-habit auto-seeding

**Date:** 2026-07-23

**Problem:** Before onboarding existed, `TodayView` silently created Prayer/Gym/Work the first time it rendered with zero habits, and `RootTabView` requested location permission unconditionally on every cold launch — both with no context shown to the user first.

**Options considered:**
1. Leave the silent behavior; just add an onboarding flow on top of it.
2. Replace the silent seeding entirely — onboarding becomes the only path that creates starter habits, and permission requests move to be conditional on what the user actually chose.

**Decision:** Option 2.

**Reasoning:** The silent version also had a real bug — the auto-seeded Prayer habit's `reminderEnabled: true` never resulted in an actual scheduled notification, because `HabitService.create()` was called directly rather than through the one path (`AddEditHabitViewModel.save()`) that requests notification permission and schedules. Routing all first-run habit creation through the same explicit flow fixed this as a side effect, not a separate fix.

**Tradeoffs:** None significant — this was a straightforward improvement with no real downside identified.

---

## ADR-004: `Frequency.displayName` lives on the Model, not a ViewModel

**Date:** 2026-07-23

**Problem:** `ExportService` needs the same human-readable frequency string ("Every day", "5x per week") that `HabitsViewModel.frequencyDescription(for:)` already computes.

**Options considered:**
1. Write a third copy of the logic inside `ExportService`.
2. Have `ExportService` depend on `HabitsViewModel`.
3. Move the logic to `Frequency.displayName` (the Model layer) and have both `HabitsViewModel` and `ExportService` delegate to it.

**Decision:** Option 3.

**Reasoning:** Option 2 is backwards in the dependency graph — Services must not depend on ViewModels. Option 1 duplicates business logic, which `CLAUDE.md` explicitly forbids. Option 3 matches the existing convention (every other enum in the codebase — `PrayerCalculationMethod`, `AppAppearance`, `TimeOfDayPeriod`, `InsightsRange` — already has its own `displayName`) and required a purely mechanical relocation, zero behavior change at the one existing call site.

---

## ADR-003: XcodeGen signing config must live in `project.yml`, not just Xcode's GUI

**Date:** 2026-07-23 (discovered during physical-device deployment)

**Problem:** Deploying to a physical device via `xcodebuild -allowProvisioningUpdates` failed with "Signing for 'Anchor' requires a development team," even after setting the team through Xcode's own Signing & Capabilities GUI.

**Root cause:** `xcodegen generate` regenerates the entire `.xcodeproj` from `project.yml` on every run. Since `project.yml` never declared a signing team, every regeneration silently wiped whatever team had been set through Xcode's GUI.

**Decision:** Add `CODE_SIGN_STYLE: Automatic` and `DEVELOPMENT_TEAM: X264QUS42N` to `project.yml`'s `settings.base` permanently, so the correct team survives every future regeneration.

**Tradeoffs:** None — this is a strict improvement; the team ID is specific to the developer's own Apple ID and would need updating if the project ever changed hands.

---

## ADR-002: `CompletionService.isCompleted`/`isFullyCompleted` is the single choke point for completion state

**Date:** established at initial scaffold (2026-07-23), *load-bearing* for every feature added since

**Problem:** Many parts of the app need to know "is this occurrence/habit done" — streaks, insights, notifications, the heatmap. If each re-implements its own check, adding new completion semantics (like a numeric threshold) means finding and updating every one of them.

**Decision:** Every consumer calls through `CompletionService.isCompleted(occurrence:on:)` / `isFullyCompleted(habit:on:)` rather than querying `Completion` records directly.

**Reasoning:** Confirmed via repo-wide grep (multiple times, across multiple features) that zero call sites bypass this. This is what made Quantifiable Logging (ADR-010) safe to build by changing one method instead of ~15 call sites — a direct, demonstrated payoff of the pattern, not just a theoretical one.

**Enforcement:** `CLAUDE.md`'s "Never Change Without Explicit Approval" section calls this out explicitly — any new feature needing completion state must call through these methods, never duplicate the logic.

---

## ADR-001: MVVM + DI, `View → ViewModel → Service → SwiftData`, one direction only

**Date:** initial scaffold (2026-07-23)

**Decision:** The foundational architecture pattern for the whole app. Views render state only; ViewModels hold UI state and call Services; Services own all business logic and are the only layer that touches SwiftData; Models are dumb data holders with no logic.

**Reasoning:** Standard, well-understood pattern that scales cleanly as features are added — every feature added since (10+ major ones) has fit this pattern without requiring an architecture change, per `ARCHITECTURE.md`'s "Future Extensibility" section.

**See:** `ARCHITECTURE.md` for the full diagrammed dependency graph and layer responsibilities.
