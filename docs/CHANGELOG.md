# CHANGELOG.md — Historical Record

What shipped, newest first, grouped by real commits on `main`. Hashes are real — look one up with `git show <hash>`.

**This is history, not current state.** For what's true now see `PROJECT_STATE.md`; for what's planned, `TODO.md`; for why a choice was made, `DECISIONS.md`.

---

## `cb1a964` — Documentation context architecture refactor (2026-08-20)

Documentation only; no application code, `project.yml`, or build configuration touched.

Restructured the documentation for **progressive context loading**: a Claude session now reads only `CLAUDE.md` + `PROJECT_STATE.md` at startup (~3.3K tokens, down from ~18.8K) and loads the rest on demand via a decision table in `CLAUDE.md`.

- **`CLAUDE.md`** gained a startup protocol, a per-task documentation-loading table, a source-of-truth hierarchy with conflict-handling rules, and a documentation update policy. It no longer instructs sessions to read the whole corpus.
- **`PROJECT_STATE.md`** converted from an accumulating session journal into a current-state snapshot, with an explicit policy against re-accumulating narrative.
- **`CLAUDE_CONTEXT.md`** reduced ~78%, keeping only what the repository can't tell you — product philosophy, distribution constraints, deliberately-rejected work, and judgment lessons. Repository file maps, file counts, and per-file descriptions removed as discoverable by grep.
- **`DECISIONS.md`** split: 14 active ADRs stay, each tagged with what it constrains; ADR-004, ADR-005, ADR-008, and ADR-014 moved to the new `docs/archive/DECISIONS_ARCHIVE.md` as historical or superseded. Numbering preserved, no meaning changed.
- **`PROJECT_SPEC.md`** stripped of duplicated architecture and data-model content, with shipped behavior separated more sharply from roadmap.
- **`TODO.md`** and **`KNOWN_ISSUES.md`** cleared of struck-through completed work; **`CHANGELOG.md`** entries relabeled from "Unreleased" to their real commit hashes.

A follow-up hygiene pass then consolidated the WidgetKit pause to a single authoritative statement in ADR-017 (four documents had restated it in full), removed the duplicated XcodeGen-signing lesson and Personal Team distribution limits, and dropped the hardcoded test count from `DEVELOPMENT_GUIDE.md` so the number lives in one fewer place.

**Accuracy fixes** found by validating docs against the repository: the test count (51 → **54**, verified by a live run), `Shield.habit` documented as a raw `habitID`, and a `ViewModels/` folder missing from both folder-structure lists while non-existent `Resources/` and `Tests/` folders were listed. Also removed a stale claim in ADR-009 that below-target quantifiable days still render as `.missed` — ADR-015 fixed that.

## `26bd240` — "By Day of Week" radial chart (2026-08-20)

Closes the backlog's "additional chart types" item.

- **`InsightsService.weekdayDistribution(for:referenceDate:)`** — completion rate per weekday across a habit's whole history, bucketed by weekday rather than date range, reusing the same `DueDateRule.isDue`/`CompletionService.isFullyCompleted` choke points `dailyRate` already uses. New `WeekdaySlice` (`dueCount`/`completedCount`/computed `rate`).
- **`WeekdayRadialChartView`** — the app's first genuinely radial chart (trend and time-of-day are both Cartesian). Swift Charts `SectorMark`, seven equal-angle wedges, radius from that weekday's rate. `outerRadius` has no `PlottableValue` overload in this SDK, caught by a build error and fixed by computing `.ratio(...)` per-mark. "Best on ___" headline mirroring `TimeOfDayChartView`.
- New "By Day of Week" section in `HabitInsightsView` between Time of Day and History, reusing the existing `hasAnyCompletions` gate and `ContentUnavailableView` empty state.
- `HabitInsightsViewModel.weekdaySlices(for:)` pass-through. Three new `InsightsServiceTests` cases.

**Verification:** zero warnings, 54/54 tests. No `project.yml` changes. Visual verification still outstanding — see `TODO.md`. See ADR-018.

## `7b2c5b1` — Documentation currency pass (2026-08-08)

Brought `CLAUDE_CONTEXT.md`, `TESTING.md`, and `DEVELOPMENT_GUIDE.md` current. Documentation only.

## `96d51d5` — Calendar History verification closed out (2026-07-31)

The user confirmed on their own device that Calendar History and the Today-screen polish all work correctly. Closed the open verification items in `KNOWN_ISSUES.md` and `TODO.md`. Documentation only; the underlying automation-tool gap was never diagnosed.

## `89f5507` — Simulator-tooling gap logged (2026-07-31)

Documented that `HabitsView`'s "+" toolbar button doesn't respond to synthetic taps in this environment — a more specific finding than earlier sessions' general "taps stop working," since every other control worked normally in the same session. Documentation only.

## `a1f6146` — Calendar History (v1.1) (2026-07-31)

Shipped from the roadmap. WidgetKit (v1.2), requested alongside it, was explicitly dropped — see ADR-017.

- **`StreakService.dailyHistory`'s per-day branch extracted** into a private `dayState` helper, reused by both the existing loop (behavior-preserving) and a new public `dayCompletionState(for:on:referenceDate:)`, which adds a `day > today` guard so an unlogged future day reports `.notDue` rather than `.missed`. See ADR-016.
- **`CalendarHistoryGridView`** — a month grid (weekday columns, day numbers, `firstWeekday`-aware), distinct from the dot-matrix heatmap. Purely presentational: every cell's color comes from a `stateProvider` closure.
- **`CalendarHistoryView`** — a dedicated screen (not a segmented toggle) with month navigation clamped between the habit's creation month and the current month, pushed from a "View Full Calendar" link in Habit Insights' History section.
- **`DayCompletionState.color(tint:)`** extracted into a shared extension so the calendar and the heatmap don't each define their own mapping.
- Four new `StreakServiceTests` cases, including a cross-check that `dayCompletionState` agrees with `dailyHistory` across a mixed-state range.

**Verification:** zero warnings, 51/51 tests. No `project.yml` changes. Simulator verification was blocked by a tooling gap; confirmed by the user directly instead (`KNOWN_ISSUES.md` R7).

## `40ca2d3` — Today screen interaction and motion polish (2026-07-31)

UI polish; no new features or model changes.

- **Completion celebration.** `CompletionCelebrationView` plays a brief checkmark burst plus success haptic when daily progress crosses into 100% — the 0→1 transition only, not on every render or reopen. Reduce Motion shows the checkmark without the motion.
- **Progress ring glow.** `ProgressRingView` gained an opt-in `pulseGlow`, enabled only for Today's header ring; static under Reduce Motion.
- **Full-card tap target.** `HabitCardView`'s body is now a `Button` mirroring the card's primary control. Inner controls still work when tapped directly; the card just no longer requires precision-tapping.
- **Swipe-to-delete on Today.** The habit list became a `List` (a `ScrollView`/`VStack` can't host `.swipeActions`), and `TodayViewModel` gained `delete(_:)` mirroring `HabitsViewModel`'s delete-then-reschedule shape.
- **Removed the Habits tab's `EditButton()`** — long-press-drag reordering has worked without edit mode since iOS 16, so it was pure redundancy.
- **Shields for Weekly Goal habits — considered, declined.** Surfaced a real conflict with ADR-009; the user chose to leave the scoping as-is. No code change.

**Verification:** zero warnings, 47/47 tests. Interaction verification blocked by the tooling gap; confirmed by the user directly (`KNOWN_ISSUES.md` R7).

## `5084e28` — Heatmap richness for below-target quantifiable days (2026-07-30)

`dailyHistory` now reports `.partial` instead of `.missed` for a quantifiable habit logged below target on a due, unshielded day — distinguishing "attempted but short" from "did nothing," reusing the existing state and color. Two new/updated `StreakServiceTests` cases. Verified visually. See ADR-015.

## `f0e80b4` — Unit label length cap (2026-07-30)

`AddEditHabitViewModel.unitLabel` clamps to 24 characters via a `didSet`. Emoji-blocking was considered and deliberately skipped — it would reject legitimate non-ASCII labels for no benefit, since length was the actual concern. No new tests (thin ViewModel glue).

## `940333f` — Physical-device verification (2026-07-30)

Installed on the developer's iPhone to close the last two verification items needing a real device. The user confirmed emoji habit-icon entry and the custom `ColorPicker` both work end-to-end with no crashes — proving both prior "bugs" were simulator-tooling limitations. Documented that `xctrace` and `devicectl` report different identifiers for the same device. See `KNOWN_ISSUES.md` R6.

## `7857311` — Simulator verification pass (2026-07-30)

Verified shield long-press end-to-end (`KNOWN_ISSUES.md` R4). Root-caused the previous session's "taps stopped registering app-wide" symptom: the tool's coordinate space is device **points**, not screenshot pixels. Documented the remaining keyboard/`ColorPicker` tooling limits.

## `d293b88` — Documentation audit against the actual codebase (2026-07-30)

A fresh session verified the just-generated docs against real code rather than trusting them, and found several inaccuracies: an inflated test-count claim repeated across three files; off-by-one file counts; `Completion`/`Occurrence` fields documented as raw IDs when they're SwiftData relationships; a missing `HabitService.duplicate`/`updateOccurrence` mention; and a `PROJECT_SPEC.md` self-contradiction listing export and charts as both shipped and out of scope. No application code touched.

## `d9d77e4` — Documentation knowledge base generated (2026-07-29)

Added `docs/`, moved `PROJECT_SPEC.md` and `ARCHITECTURE.md` into it, and created the knowledge-base files. Updated `CLAUDE.md` with a documentation map and the "Never Change Without Explicit Approval" and "Always Verify" sections. Refreshed `ARCHITECTURE.md`'s Data Model, Services, Navigation, and Persistence sections, which had gone stale. See ADR-014 (archived).

## `82e82bb` — Emoji icons, custom accent colors, quick shields (2026-07-29)

- **Emoji habit icons.** A habit's icon can be a single Apple emoji via a text field and the system keyboard. New `HabitIconView` and the `String.isSFSymbolCompatible` heuristic pick the right renderer at all six places an icon is drawn.
- **Custom accent colors.** Both per-habit and app-wide accents gained a 9th "Custom" swatch backed by a native `ColorPicker`, stored as an optional hex override that takes priority over the curated `AccentColor` — which is otherwise untouched.
- **Quick Shields.** Long-press "Shield Today" on a Today card, gated on the previously-unwired `Frequency.supportsShields`, plus a shield badge.
- **Fixed:** `AccentColorPickerView`'s decorative overlay was silently blocking taps to the `ColorPicker` beneath it (`KNOWN_ISSUES.md` R1).

**Testing:** 4 new cases, 46 total. Zero warnings.

## `bd2fa6f` — Quantifiable habit logging (2026-07-24)

Custom (single-occurrence) habits can track a numeric daily target instead of a binary checkmark. `Habit.targetValue`/`unit` and `Completion.value` added, all additive — nil/1 defaults leave every existing binary habit unaffected. `CompletionService.isCompleted` became threshold-aware, which propagated through `StreakService`, `InsightsService`, and the notification gate **for free**, since all three already routed through it. Today shows a fill ring; tapping opens the new `LogValueView` stepper. Export gained a Value column. See ADR-010.

Also in this window: `project.yml` pinned `CODE_SIGN_STYLE`/`DEVELOPMENT_TEAM` permanently during the physical-device deployment happening alongside — see ADR-003.

## `5153c15` — Streak shields (2026-07-24)

New `Shield` SwiftData model at habit-day granularity. `StreakService` gained shield-priority logic: a shielded day bridges a streak without incrementing or breaking it, and `dailyHistory` reports `.shielded`, ranked below full completion but above partial/missed. New `ManageShieldsView` sheet. `Frequency.supportsShields` added (Daily/Weekdays only). See ADR-009.

## `f762452` — Interaction and visual polish pass (2026-07-23)

Triggered by a user-shared third-party "master audit," every claim of which was fact-checked against real code first.

Migrated hand-rolled empty states to `ContentUnavailableView` across Today/Habits/Stats and added the two genuinely missing ones in Habit Insights. Added a `.partial` heatmap state, an accent-color top border on habit cards, a Duplicate swipe action, a gradient on the progress ring stroke, and fixed dim inactive tab-bar icons in dark mode.

**Rejected from the same audit:** a hallucinated "Quit Habit Logic" feature, a `Habit` → subtype architecture split, Widgets, and a cloud backend.

## `b67a83a` — App icon redesign (2026-07-23)

A bold single-weight anchor glyph nested in a thin progress ring, rendered at true 1024×1024 via Core Graphics with no alpha channel. Chosen from three candidates.

## `bf305cf` — Smart Reminders (2026-07-23)

Opt-in 8:00 PM catch-all notification for any habit still due and incomplete, independent of per-habit reminders. Resolves the "local notifications can't be live" problem via reschedule frequency rather than a Notification Service Extension — see ADR-007. No new tests; reuses already-tested primitives.

## `06f39f5` — Biometric app lock (2026-07-23)

New `AuthenticationService` wrapping `LocalAuthentication`, with `LAContext` never leaked outside that file. New `LockScreenView`; the root branch became 4-way. Re-locks on every background→foreground transition (ADR-006). The Settings toggle appears only when biometry is enrolled. `NSFaceIDUsageDescription` added to `project.yml`.

## `bc6a50a` — App-wide accent color (2026-07-23)

`SettingsService.accentColor`, reusing the per-habit `AccentColorPickerView` unmodified. Five hardcoded `AccentColor.indigo` call sites swapped over. Fixed a sheet-tint propagation gap where `.tint()` set at a parent didn't reactively update an already-open `.sheet()`. See ADR-008 (archived).

## `b27cd0e` — CSV/JSON data export (2026-07-23)

New `ExportService` (CSV flat, JSON nested), reached via two `ShareLink` rows in a new Settings "Data" section. Includes archived habits. `Frequency.displayName` relocated to the Model layer so `ExportService` didn't need a third copy of the logic — see ADR-004 (archived). New `ExportServiceTests`.

## `8aa9ba3` — Onboarding flow with permission priming (2026-07-23)

Welcome → choose starter habits → conditional notification priming → conditional location priming, gated by `hasCompletedOnboarding`. Replaced silent starter-habit auto-seeding and the unconditional location request on every cold launch (ADR-005, archived). Fixed a dormant bug as a side effect: the auto-seeded Prayer habit's reminder never actually scheduled, because the old seeding path bypassed the only code path that requests notification permission (`KNOWN_ISSUES.md` R3).

## `c8ecfb1` — Initial commit (2026-07-23)

The entire v1 scaffold in one commit (76 files, ~5,300 lines): the design system, all core SwiftData models, the full `ScheduleProvider` strategy pattern, all core services, the Today/Habits/Stats/Settings/Add-Edit/Habit-Insights screens, the early Swift Testing suite, and `ARCHITECTURE.md` itself.

**This commit is a snapshot, not a work session.** It represents substantial prior iterative work — scaffold, design system, models, persistence, services, each screen, an accessibility pass, an earlier polish pass, a full visual redesign, prayer-method configuration, and Habit Insights — that predates the git history's granularity.
