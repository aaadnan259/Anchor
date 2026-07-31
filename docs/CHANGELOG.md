# CHANGELOG.md

Grouped by milestone (matching real commits on `main`), not by conversation. Newest first. Commit hashes are real and can be looked up with `git show <hash>`.

---

## Unreleased — Calendar History (v1.1)

**Type:** New feature, shipped from `PROJECT_SPEC.md`'s Future Roadmap. WidgetKit (v1.2), requested alongside it, was explicitly dropped for this session — see `DECISIONS.md` ADR-017.

- **`StreakService.dailyHistory`'s per-day branch extracted** into a private `dayState(for:on:today:habitStart:)` helper, reused by both the existing `dailyHistory` loop (behavior-preserving — all pre-existing `StreakServiceTests` cases pass unchanged) and a new public `dayCompletionState(for:on:referenceDate:)` single-day lookup, which adds a `day > today` guard so an unlogged future day reports `.notDue` instead of `.missed`. See `DECISIONS.md` ADR-016.
- **New `Anchor/Components/CalendarHistoryGridView.swift`** — a month-grid calendar (weekday columns, day numbers, `Calendar.current.firstWeekday`-aware) distinct from the existing dot-matrix `HabitHistoryGridView` heatmap. Purely presentational — every cell's color comes from a `stateProvider` closure, never computed locally. Reuses the same `DayCompletionState` → `Color` mapping as the heatmap, now factored out into a shared `DayCompletionState.color(tint:)` extension (`Anchor/Extensions/DayCompletionState+Color.swift`) instead of being duplicated.
- **New `Anchor/Views/CalendarHistoryView.swift`** — a dedicated screen (not a segmented-control toggle) with month navigation clamped between the habit's creation month and the current month, pushed via a new "View Full Calendar" `NavigationLink` in `HabitInsightsView`'s existing History section, alongside the heatmap and "Manage Shielded Days."
- `HabitInsightsViewModel` gained one thin pass-through: `dayCompletionState(for:on:)`.
- New `StreakServiceTests` cases: a cross-check that `dayCompletionState` agrees with `dailyHistory` for every day in a mixed-state range, the future-date `.notDue` fix, pre-creation-date `.notDue`, and confirmation that today-with-nothing-logged reports `.missed` (no inherited streak-continuity leniency).

**Verification:** `xcodebuild build` — zero warnings. `xcodebuild test` — 51/51 passing (47 existing + 4 new). No `project.yml` changes — new Swift files only, picked up via `xcodegen generate` (a no-op regeneration of the unchanged config, not a config edit). Simulator-automation verification was blocked by a tooling gap (`KNOWN_ISSUES.md` #5); confirmed working end-to-end by the user directly instead — see `KNOWN_ISSUES.md` R7.

---

## Unreleased — Today screen interaction and motion polish

**Type:** UI polish, no new features or model changes.

- **Completion celebration.** New `CompletionCelebrationView` plays a brief checkmark-seal burst + success haptic over the header's progress ring the moment daily progress crosses into 100% (0→1 transition only, not on every render or app reopen). Respects Reduce Motion (shows the checkmark without the motion).
- **Progress ring glow.** `ProgressRingView` gained an opt-in `pulseGlow` parameter — a soft, blurred duplicate of the filled arc that pulses via `repeatForever`. Enabled only for Today's header ring (the small per-habit/expand/log rings are unaffected). Falls back to a static (non-animated) glow under Reduce Motion.
- **Full-card tap target.** `HabitCardView`'s whole body is now a `Button` whose action mirrors the card's existing primary control (toggle for binary habits, log-value sheet for quantifiable habits, expand/collapse for multi-occurrence habits). The dedicated inner controls still work exactly as before when tapped directly; the card just no longer requires precision-tapping a small control.
- **Swipe-to-delete on Today.** `TodayView`'s habit list is now a `List` (previously a plain `ScrollView`/`VStack`, which can't host `.swipeActions`) so a trailing-edge swipe reveals Delete, matching `HabitsView`'s existing pattern. `TodayViewModel` gained a `delete(_:)` method (new `habitService`/`notificationService`/`smartRemindersEnabled` dependencies, mirroring `HabitsViewModel`'s existing delete-then-reschedule shape).
- **Removed the Habits tab's `EditButton()`.** Reordering already works via long-press-drag without entering edit mode (standard SwiftUI `List`/`onMove` behavior since iOS 16), so the toolbar button was pure redundancy.
- **Shields for Weekly Goal habits — considered, declined.** The request to make shields available for the Gym preset surfaced a real conflict with ADR-009 (shields are deliberately scoped to Daily/Weekdays habits only; a weekly-goal shield's semantics — free completion vs. reduced target — were never decided). Surfaced to the user via `AskUserQuestion`; they chose to leave the existing scoping as-is. No code change.

**Verification:** `xcodebuild build` — zero warnings, `** BUILD SUCCEEDED **`. `xcodebuild test` — 47/47 passing. Simulator-automation verification of the full-card tap, swipe-to-delete, and 100%-completion celebration was blocked across two sessions by a tooling gap (`KNOWN_ISSUES.md` #5); confirmed working end-to-end by the user directly instead — see `KNOWN_ISSUES.md` R7. The Edit-button removal and progress ring glow were already confirmed via simulator screenshots at the time.

---

## Unreleased — Heatmap richness for below-target quantifiable days

**Type:** Small polish fix, no new feature.

- `StreakService.dailyHistory` now reports `.partial` (reusing the existing state and heatmap color) instead of `.missed` for a quantifiable habit logged below target on a due, unshielded day — distinguishing "attempted but short" from "did nothing." See `DECISIONS.md` ADR-015.
- New `StreakServiceTests` cases: `dailyHistoryQuantifiablePartialToCompleted` (replaces the old `dailyHistoryQuantifiableMissedToCompleted`, updated to expect `.partial`), `dailyHistoryQuantifiableNothingLoggedIsMissed`.
- Verified visually in the simulator: logging 3 of 8 on a quantifiable habit now renders today's heatmap cell distinctly from an unlogged day.

---

## Unreleased — Unit label length cap

**Type:** Small polish fix, no new feature.

- `AddEditHabitViewModel.unitLabel` now clamps to 24 characters via a `didSet`, closing the "Unit label validation" `TODO.md` item. Emoji-blocking was considered and deliberately skipped (see `TODO.md`).
- No new tests — thin ViewModel glue, consistent with the established testing boundary (`TESTING.md`).

---

## Unreleased — Documentation generation

**Type:** Documentation only, no application code changed.

- Added `docs/` folder; moved `PROJECT_SPEC.md` and `ARCHITECTURE.md` into it.
- Added `CLAUDE_CONTEXT.md`, `PROJECT_STATE.md`, `DECISIONS.md`, `TODO.md`, `CHANGELOG.md` (this file), `KNOWN_ISSUES.md`, `TESTING.md`, `DEVELOPMENT_GUIDE.md`.
- Added root `README.md`.
- Updated `CLAUDE.md` with a documentation map, a "Never Change Without Explicit Approval" section, and an "Always Verify Before Modifying Code" section.
- Refreshed `ARCHITECTURE.md`'s Data Model, Services, Navigation, and Persistence sections to match the current codebase (they had gone stale relative to the initial-commit version).

---

## `82e82bb` — Add emoji habit icons, custom accent colors, and quick shields (2026-07-29)

**Features:**
- **Emoji habit icons.** A habit's icon can be a single Apple emoji (via a text field + the system emoji keyboard) as an alternative to the curated SF Symbol grid. New `HabitIconView` component and `String.isSFSymbolCompatible` heuristic pick the right renderer at all six places an icon is drawn.
- **Custom accent colors.** Both per-habit and app-wide accent colors gained a 9th "Custom" swatch backed by a native `ColorPicker`, stored as an optional hex override (`Habit.customColorHex` / `SettingsService.customAccentColorHex`) that takes priority over the existing curated `AccentColor` enum, which is otherwise untouched.
- **Quick Shields.** Habit cards on Today gained a long-press "Shield Today" quick action (gated on `Frequency.supportsShields`, previously unwired) plus a shield badge — a faster alternative to Habit Insights' existing Manage Shielded Days sheet.

**Fixed:**
- `AccentColorPickerView`'s decorative border/checkmark overlay on the new Custom swatch was silently blocking taps from reaching the native `ColorPicker` beneath it — a default SwiftUI `.overlay()` hit-testing behavior. Fixed with explicit `.allowsHitTesting(false)` on each decorative layer.

**Testing:** 4 new cases (`StringIconTests`, `ColorHexTests`) — 46 total, all passing. Zero build warnings.

---

## `bd2fa6f` — Add quantifiable habit logging (2026-07-24)

**Features:**
- Custom (single-occurrence) habits can track a numeric daily target ("8 glasses of water") instead of a binary checkmark.
- `Habit.targetValue`/`unit`, `Completion.value` added (both additive — nil/1 defaults keep every existing binary habit unaffected).
- `CompletionService.isCompleted` became threshold-aware, which propagated correctly through `StreakService`, `InsightsService`, and the notification gate for free, since all three already routed through it.
- Today shows a fill ring (reusing the existing gradient-animated `ProgressRingView`) for quantifiable habits; tapping opens a new `LogValueView` stepper sheet.
- Export gained a Value column/field.

**Fixed:**
- `project.yml` pinned `CODE_SIGN_STYLE`/`DEVELOPMENT_TEAM` permanently (see `DECISIONS.md` ADR-003) — fixed during the physical-device deployment that happened alongside this feature, not part of the feature itself, but landed in the same window.

**Testing:** New `StreakServiceTests`/`ExportServiceTests` cases for quantifiable-habit streak/export behavior.

---

## `5153c15` — Add streak shields (2026-07-24)

**Features:**
- New `Shield` SwiftData model (habit-day granularity).
- `StreakService` gained shield-priority logic: a shielded day bridges a streak without incrementing or breaking it; `dailyHistory` reports `.shielded`, ranked below full-completion but above partial/missed.
- New `ManageShieldsView` sheet (date picker + list of shielded days), reached from Habit Insights' new History section.
- `Frequency.supportsShields` added (Daily/Weekdays only — `.timesPerWeek` explicitly excluded).

**Testing:** New `StreakServiceTests` cases covering shield streak-continuity, non-increment, and `dailyHistory` priority ordering.

---

## `f762452` — Interaction and visual polish pass (2026-07-23)

**Context:** Triggered by a user-shared third-party "master audit." Every specific claim was fact-checked against the real codebase before acting on it — see `CLAUDE_CONTEXT.md`'s Lessons Learned for what turned out to be accurate, already-done, or hallucinated.

**Features/fixes:**
- Migrated hand-rolled empty states to native `ContentUnavailableView` across Today/Habits/Stats, and added the two genuinely missing ones to Habit Insights (zero-completion trend/time-of-day states).
- Added a `.partial` heatmap state (some-but-not-all occurrences done) — previously indistinguishable from `.missed`.
- Added a thin accent-color top border to `HabitCardView`.
- Added a Duplicate swipe action to `HabitsView` (`HabitService.duplicate`).
- Added a subtle gradient to `ProgressRingView`'s stroke.
- Fixed dim/hard-to-read inactive tab bar icons in dark mode.

**Rejected from the same audit** (not implemented): a hallucinated "Quit Habit Logic" feature, a Habit→subtype architecture split, Widgets, and a cloud backend — see `DECISIONS.md`/`CLAUDE_CONTEXT.md`.

**Testing:** New `StreakServiceTests` cases for the `.partial` heatmap state.

---

## `b67a83a` — Redesign app icon (2026-07-23)

Bold single-weight anchor glyph nested in a thin progress ring, rendered at true 1024×1024 via Core Graphics, no alpha channel. Chosen from three rendered candidates.

---

## `bf305cf` — Add Smart Reminders (2026-07-23)

**Features:**
- Opt-in evening (8:00 PM) catch-all notification for any habit still due and incomplete, independent of any per-habit reminder.
- Resolves the "local notifications can't be live" problem via reschedule frequency rather than a new Notification Service Extension target — see `DECISIONS.md` ADR-007.

**Testing:** None new — reuses already-tested primitives (`DueDateRule.isDue`, `CompletionService.isFullyCompleted`); consistent with `NotificationService`'s established untested-wrapper boundary (see `TESTING.md`).

---

## `06f39f5` — Add biometric app lock (2026-07-23)

**Features:**
- New `AuthenticationService` wrapping `LocalAuthentication` (`LAContext` never leaked outside this file).
- New `LockScreenView`; `AnchorApp`'s root branch became 4-way (test / onboarding / lock / main).
- Re-locks on every background→foreground transition (see `DECISIONS.md` ADR-006), not just cold launch.
- Settings toggle only shown when the device has usable biometry enrolled.
- `NSFaceIDUsageDescription` added to `project.yml`.

**Testing:** None new — established boundary for services wrapping live hardware frameworks (see `TESTING.md`). Manual verification only; actual biometric match/no-match couldn't be driven via the simulator's Face ID simulation from this tooling.

---

## `bc6a50a` — Add custom accent color picker (2026-07-23)

**Features:**
- App-wide accent color setting (`SettingsService.accentColor`), reusing the existing per-habit `AccentColorPickerView` unmodified.
- Five hardcoded `AccentColor.indigo` call sites swapped to `settingsService.accentColor.color`.
- Fixed a sheet-tint live-update propagation gap (`.tint()` set at a parent level didn't reactively update an already-open `.sheet()`).

**Testing:** None new — straightforward property addition following an already-tested persistence pattern.

---

## `b27cd0e` — Add CSV/JSON data export (2026-07-23)

**Features:**
- New `ExportService` (CSV flat / JSON nested), reached via two `ShareLink` rows in a new Settings "Data" section.
- Includes archived habits.
- `Frequency.displayName` relocated from `HabitsViewModel` to the Model layer (see `DECISIONS.md` ADR-004) so `ExportService` didn't need a third copy of the logic.

**Testing:** New `ExportServiceTests.swift` — CSV escaping/quoting, zero-completion edge case, JSON round-trip, archived-habit inclusion.

---

## `8aa9ba3` — Add onboarding flow with permission priming (2026-07-23)

**Features:**
- New Welcome → choose starter habits (multi-select presets) → conditional notification priming → conditional location priming flow, gated by `hasCompletedOnboarding`.
- Replaced silent starter-habit auto-seeding (`HabitService.seedStarterHabitsIfNeeded`, deleted) and the unconditional location-permission request on every cold launch — see `DECISIONS.md` ADR-005.
- Fixed a dormant bug as a side effect: the auto-seeded Prayer habit's `reminderEnabled: true` never resulted in an actually-scheduled notification, because the old seeding path bypassed `AddEditHabitViewModel.save()` (the only path that requests notification permission).
- New `HabitService.create(from preset:displayOrder:)`, consolidating preset→Habit construction that previously existed in two places.

**Testing:** None new — established ViewModel/UI-glue boundary; manually verified both the full-permission and skip-all-permissions paths.

---

## `c8ecfb1` — Initial commit: Anchor habit tracker (2026-07-23)

The entire v1 scaffold, landed as one commit (76 files, ~5300 lines): design system (`Theme/`), all core SwiftData models (`Habit`/`Occurrence`/`Completion`), the full scheduling strategy pattern (`ScheduleProvider` + `FixedTimeProvider`/`PrayerProvider`/`WeeklyProvider`), all core services, Today/Habits/Stats/Settings/Add-Edit/Habit-Insights screens, the early Swift Testing suite (`StreakServiceTests`, `InsightsServiceTests`, `ScheduleProviderTests`, the `DueDateRule` suite), and `ARCHITECTURE.md` (then at root) itself.

This single commit represents substantial prior iterative work — scaffold, design system, models, persistence, services, each screen, an accessibility pass, an earlier polish pass, a full visual redesign, prayer-method configuration (`SettingsService`, 13 calculation methods), and Habit Insights — that predates the git history's granularity. The commit boundary is a snapshot, not a single work session.
