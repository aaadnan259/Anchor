# CLAUDE_CONTEXT.md

Complete project knowledge base for Anchor. Read this first in any new session — it's the narrative and reasoning that the other `docs/` files don't carry on their own.

This file documents **what happened and why**. For **what the app does**, see `PROJECT_SPEC.md`. For **how it's built**, see `ARCHITECTURE.md`. For **exactly where things stand right now**, see `PROJECT_STATE.md` (that one gets updated every session; this one doesn't).

---

## Project Overview

**Purpose.** Anchor is a focused, native iOS habit tracker. It is deliberately *not* a task manager, planner, calendar, or productivity suite — the whole app is built around one job: help the user complete today's habits with minimal friction.

**Vision.** Fast to open, fast to understand, fast to complete. Native iOS experience over cross-platform convenience. Privacy-first and local-first — no accounts, no backend, no analytics. Feature depth over feature breadth: a small set of things done exceptionally well (one of which — prayer-time scheduling — most habit trackers don't attempt at all) rather than a broad, generic feature set.

**Target audience.** Anyone who wants a simple, beautiful daily habit checklist. Prayer-time-aware scheduling (via the Adhan library) is a first-class preset, not a niche add-on — it's one of the app's real differentiators, not the whole point of the app.

**Current version.** `MARKETING_VERSION: 1.0` in `project.yml`. Pre-release: installed via direct USB/Xcode on two physical devices (the developer's own iPhone and a friend's iPhone, for one-off feedback) but never submitted to TestFlight or the App Store. Free "Personal Team" code signing only — see [Distribution constraints](#distribution-constraints-learned-the-hard-way) below.

**Current development stage.** Feature-complete for the v1 scope defined in `PROJECT_SPEC.md`. Every planned v1 feature has shipped; the only backlog items left are explicitly deferred (see [Features](#features) below) or belong to a later version (v1.1+).

**Tech stack.**
- Swift 6, strict concurrency checking on (`SWIFT_STRICT_CONCURRENCY: complete`)
- SwiftUI + SwiftData, iOS 17+ deployment target
- XcodeGen — the `.xcodeproj` is generated from `project.yml` and is gitignored; never hand-edit it, never commit it
- Adhan Swift (Swift Package Manager) — the only third-party dependency, used only because Apple provides no prayer-time calculation API

**Overall architecture.** MVVM with dependency injection. `View → ViewModel → Service → SwiftData`, strictly one direction. The single most important architectural fact in this codebase: `CompletionService.isCompleted` / `isFullyCompleted` is a choke point that *every* consumer of "is this habit done" — `StreakService`, `InsightsService`, `NotificationService`'s smart-reminder gate, the heatmap — calls through, rather than re-implementing its own check. Full detail in `ARCHITECTURE.md`.

---

## Repository Structure

```
Anchor/
  App/            AnchorApp.swift — entry point, ModelContainer, 4-way root branch
  Models/         SwiftData @Model classes + plain value types
  ViewModels/     @Observable classes, one per screen
  Views/          Full-screen SwiftUI views
  Components/     Small reusable views used across multiple screens
  Services/       Business logic; mostly stateless structs
  Theme/          Design tokens (spacing, color, typography, motion, corners)
  Utilities/      HabitPreset, Haptics, SampleData
  Extensions/     Color+Hex, String+Icon
AnchorTests/      Swift Testing suite
docs/             This file and its siblings
CLAUDE.md         Engineering rules (root, not in docs/)
README.md         Short project intro (root)
project.yml       XcodeGen spec — the source of truth for the Xcode project
```

**Models/** (10 files): `Habit`, `Occurrence`, `Completion`, `Shield` are `@Model` SwiftData classes. `Frequency`, `Weekday`, `AppAppearance`, `PrayerCalculationMethod`, `PrayerMadhab`, `PrayerName`, `ScheduleProviderKind` are plain `Codable` enums/structs, mostly stored as encoded `Data` on `Habit` (e.g. `frequency`) or as raw-value strings (e.g. `AccentColor`, defined in `Theme/`).

**ViewModels/** (6 files): `TodayViewModel`, `HabitsViewModel`, `AddEditHabitViewModel`, `StatsViewModel`, `HabitInsightsViewModel`, `OnboardingViewModel`. Each is `@Observable @MainActor`, constructed fresh per-screen in a `.task` block (not injected via `@Environment` — only *Services* and `SettingsService`/`LocationService` are environment-injected, since those are genuinely shared/long-lived).

**Views/** (11 files): `TodayView`, `HabitsView`, `StatsView`, `AddEditHabitView`, `HabitInsightsView`, `SettingsView`, `OnboardingView`, `RootTabView`, `LockScreenView`, `LogValueView`, `ManageShieldsView`.

**Components/** (14 files): the reusable building blocks — `HabitCardView` (the Today/Habits list row, with expandable/quantifiable/binary/shielded branches), `HabitIconView` (renders SF Symbol or emoji from the same `icon: String`), `IconPickerView`, `AccentColorPickerView`, `ProgressRingView`, `CompletionToggleView`, `HabitHistoryGridView` (the heatmap), `TrendChartView`, `TimeOfDayChartView`, `WeeklyBarsView`, `OccurrenceRowView`, `PresetCardView`, `PrimaryButtonView`, `SectionHeaderView`.

**Services/** (15 files): see `ARCHITECTURE.md`'s Services section for the full responsibility breakdown of each. Headline list: `HabitService`, `CompletionService`, `ScheduleService` (+ its `ScheduleProvider` strategies: `FixedTimeProvider`, `PrayerProvider`, `WeeklyProvider`, plus the shared `DueDateRule`), `PrayerService`, `LocationService`, `NotificationService`, `StreakService`, `InsightsService`, `ExportService`, `AuthenticationService`, `SettingsService`.

**Theme/** (6 files): `Spacing` (4/8/12/16/24/32/48 scale), `CornerRadius` (12 small, 20 cards — always `.continuous`), `Surface` (background/card/border semantic colors), `Typography` (named `Font` extensions), `Motion` (named `Animation` presets — snappy/bouncy, with Reduce Motion fallbacks baked in at call sites), `AccentColor` (the curated 8-case enum).

**AnchorTests/** (8 files): `StreakServiceTests.swift` is the largest and most important (40+ cases — streaks, shields, quantifiable thresholds, daily history). `InsightsServiceTests`, `ScheduleProviderTests`, `ExportServiceTests`, `ColorHexTests`, `StringIconTests` cover their respective services/extensions. `AnchorTests.swift` — despite the generic Xcode-scaffold name — actually contains the `DueDateRule` suite. `TestSupport.swift` holds shared fixtures (a fixed UTC `Calendar` for date-math determinism, an in-memory `ModelContext` factory).

---

## Features

### Completed

All of the following have shipped, are covered by `PROJECT_SPEC.md`'s Screens section, and (where they touch non-trivial logic) have Swift Testing coverage.

| Feature | Purpose | Key files |
|---|---|---|
| Core habit tracking | Create/edit/archive/delete/duplicate/reorder habits; Prayer/Gym/Work/Custom presets; Daily/Weekdays/Weekly-Goal frequency | `HabitService`, `AddEditHabitViewModel`, `HabitsView` |
| Today screen | Daily checklist, expandable multi-occurrence habits, one-tap completion, overall progress ring | `TodayViewModel`, `TodayView`, `HabitCardView` |
| Prayer-time scheduling | Adhan-backed, configurable calculation method + madhab, never special-cased outside the `ScheduleProvider` strategy pattern | `PrayerService`, `PrayerProvider`, `ScheduleService` |
| Local notifications | Per-habit fixed-time or prayer-time reminders, rescheduled on launch/foreground/midnight/habit-edit/location-change | `NotificationService` |
| Stats screen | Current/best streak, last-4-weeks bars, completion %, heatmap | `StatsViewModel`, `StatsView`, `HabitHistoryGridView` |
| Habit Insights | Trend chart (week/month/year), time-of-day distribution, completion history grid — pushed from a Stats card | `InsightsService`, `HabitInsightsViewModel`, `HabitInsightsView` |
| Onboarding | Welcome → choose starter habits (multi-select presets) → conditional notification priming → conditional location priming → creates habits | `OnboardingViewModel`, `OnboardingView` |
| Data export | CSV (flat) and JSON (nested) via `ShareLink`, includes archived habits | `ExportService` |
| App-wide accent color (curated) | 8-swatch palette, independent of per-habit colors, reuses `AccentColorPickerView` | `SettingsService.accentColor` |
| Biometric app lock | Face ID/Touch ID with device-passcode fallback, re-locks on every background→foreground | `AuthenticationService`, `LockScreenView` |
| Smart Reminders | Opt-in evening (8pm) catch-all notification for anything still undone, independent of per-habit reminders | `NotificationService.scheduleSmartReminders` |
| App icon redesign | Anchor glyph nested in a thin progress ring | `Assets.xcassets/AppIcon.appiconset` |
| Interaction/visual polish pass | `ContentUnavailableView` empty states, heatmap partial-completion color, card accent-color top border, Duplicate swipe action, progress-ring gradient stroke, dark-mode tab-bar tint fix | see `CHANGELOG.md` "Interaction and visual polish pass" |
| Streak Shields | Protect a streak for a vacation/illness day without losing it, habit-day granularity, Daily/Weekdays habits only | `Shield`, `StreakService`, `ManageShieldsView` |
| Quantifiable Logging | Numeric habit values ("8 glasses of water") instead of a binary checkmark, Custom/single-occurrence habits only | `Habit.targetValue/unit`, `Completion.value`, `LogValueView` |
| Emoji habit icons | A single Apple emoji as an alternative to the curated SF Symbol grid | `HabitIconView`, `String.isSFSymbolCompatible`, `IconPickerView` |
| Custom accent color | Exact color (native `ColorPicker`) as a 9th swatch, per-habit and app-wide, alongside the untouched curated 8 | `Habit.customColorHex`, `SettingsService.customAccentColorHex` |
| Quick Shields | Long-press a Today card for "Shield Today" — faster than Habit Insights' Manage Shielded Days sheet | `HabitCardView.contextMenu`, `TodayViewModel.toggleShield` |

### In Progress

None — every feature task reached completion. This documentation pass is the only open work as of this writing.

### Planned (v1.1+, not to be implemented in v1)

- **v1.1 — Calendar history.** A calendar-style view of past completions, distinct from the existing heatmap.
- **v1.2 — Widgets.** Explicitly deferred: needs a whole new WidgetKit extension target, a real scope jump.
- **v1.3 — iCloud Sync.** Explicitly out of scope for v1 (`PROJECT_SPEC.md`'s "Explicitly Out of Scope" list) — no accounts, no cloud, local-first is a deliberate v1 promise.
- **v1.4 — Apple Watch.**

### Deferred (backlog, not version-assigned)

- **Cross-habit correlation insights** (e.g. "does completing habit A predict completing habit B") — blocked on real usage data, not on engineering effort. Statistically meaningless with the sparse completion history any one user has early on; revisit once there's a real dataset to reason about.
- **Additional chart types** — radial completion charts. Line trend charts and the dot-matrix heatmap already shipped; a third chart type hasn't been prioritized.

### Cancelled / Rejected

- **"Quit Habit Logic"** — proposed by a third-party "master audit" (see [Lessons Learned](#lessons-learned)) mid-session. Describes a smoking-cessation-style quitting feature that doesn't exist anywhere in Anchor's actual scope; concluded to be hallucinated or copied from a different app's audit. Not implemented.
- **Habit→subtype splitting** — proposed by the same audit; would have been an architecture regression (the current single `Habit` model with an occurrence-mode split is simpler and already handles every real use case).
- **Widgets now / a cloud (Supabase/Firebase) backend** — both directly contradict `PROJECT_SPEC.md`'s explicit "Explicitly Out of Scope" list and the v1.2/v1.3 roadmap ordering. Not implemented ahead of schedule.
- **Fully replacing the curated `AccentColor` enum with an open color model everywhere** — considered when the user asked for "exact custom colors." Rejected in favor of adding a 9th "Custom" swatch alongside the untouched 8 curated cases, after the user chose that option explicitly (see `DECISIONS.md`).
- **True per-occurrence shielding** (e.g. shield just today's Dhuhr, not the whole Prayer habit-day) — considered for the Quick Shields feature. Rejected in favor of keeping shields at the existing habit-day granularity, after the user chose that option explicitly (see `DECISIONS.md`).

---

## Architecture

Full detail lives in `ARCHITECTURE.md` — this section is a summary, not a duplicate.

- **Pattern:** MVVM + DI. `View → ViewModel → Service → SwiftData`. Views render state only; Services own all business logic; Models are dumb data holders.
- **The single choke point:** `CompletionService.isCompleted(occurrence:on:)` / `isFullyCompleted(habit:on:)`. Everything that needs to know "is this done" — `StreakService`'s streak/history calculations, `InsightsService`'s trend data, `NotificationService`'s smart-reminder gate — calls through these two methods. This is *the* reason Quantifiable Logging (a feature that conceptually touches almost every layer of the app) was safe to build by changing `isCompleted` in one place instead of ~15 call sites individually.
- **State ownership:** `@State`/`@Binding`/`@Bindable`/`@Environment`/`@Query` — no `ObservableObject` unless truly necessary (none currently exist; everything is `@Observable`).
- **Persistence:** SwiftData only, four models (`Habit`, `Occurrence`, `Completion`, `Shield`). App-wide preferences are UserDefaults via `SettingsService`, a deliberately separate mechanism from SwiftData since they're scalar settings, not relational data.
- **Concurrency:** Swift 6 strict concurrency. Services and ViewModels are `@MainActor`. Apple-framework types that predate Sendable auditing (`UNUserNotificationCenter`, `LAContext`) are wrapped behind `@preconcurrency import` at the single file that touches them, never leaked outward.
- **XcodeGen:** `project.yml` is the source of truth; `Anchor.xcodeproj` is generated and gitignored. **Critical:** `project.yml`'s `settings.base` must declare `CODE_SIGN_STYLE: Automatic` and `DEVELOPMENT_TEAM: X264QUS42N` explicitly — without them, every `xcodegen generate` silently wipes any signing team set through Xcode's own GUI, breaking physical-device builds. This was discovered and fixed permanently mid-session; see `DECISIONS.md`.

---

## UI Design System

Tokens live in `Anchor/Theme/`; this section explains the *why* behind them.

- **Typography:** SF Pro via named `Font` extensions in `Typography.swift`, full Dynamic Type support throughout.
- **Spacing:** a fixed 4/8/12/16/24/32/48 scale (`Spacing.xs` through `Spacing.xxl`) — no ad-hoc padding values anywhere in the codebase.
- **Corners:** `CornerRadius.small` (12) for controls/fields, `CornerRadius.card` (20) for cards — always `.continuous` style, never the default (sharper) SwiftUI corner curve.
- **Colors:** semantic (`Surface.background`/`.card`/`.border`) plus a curated 8-color `AccentColor` palette (indigo, teal, coral, amber, emerald, rose, sky, violet — each a fixed hex, not adaptive per color-scheme). As of the Custom Accent Color feature, both per-habit and app-wide accents can also be an exact custom color, stored as a hex override that takes priority over the curated enum without touching it. Full light/dark support throughout via `Color(light:dark:)`.
- **Animation:** named `Motion` presets (`snappy`, `bouncy`), always with an explicit Reduce-Motion fallback (`reduceMotion ? .linear(duration: 0.1) : Motion.snappy`) at every call site that animates.
- **No shadows, anywhere.** Confirmed via a repo-wide grep during the polish pass — zero `.shadow()` usage. This is a deliberate, consistent design choice (depth comes from color/opacity/stroke, not elevation), preserved rather than "fixed" when a third-party audit suggested adding glow effects.
- **Haptics:** a thin `Haptics` utility wrapping `UIImpactFeedbackGenerator`/`UINotificationFeedbackGenerator`, fired on meaningful state changes (completion toggle, shield toggle, swatch selection) — never on passive navigation.
- **Touch targets:** 44×44pt minimum on every interactive control, including icon/color swatches that are visually smaller (padding/`contentShape` make up the difference).
- **Iconography:** SF Symbols by default; as of the Emoji Icons feature, a habit's icon can also be a single emoji, rendered by the same `HabitIconView` component regardless of which kind it is.

---

## Important Decisions

Full ADR-style entries with problem/options/reasoning/tradeoffs live in `DECISIONS.md`. Headlines:

1. **Curated `AccentColor` stays a closed enum; custom color is a separate optional override, not a replacement.** Preserves 13+ existing decorative call sites and both persistence layers untouched.
2. **Shields stay at habit-day granularity; no per-occurrence shielding.** Avoids a `StreakService`/`Shield`-model rewrite for a case that only matters for multi-occurrence (Prayer-style) habits.
3. **Quantifiable habits are `Int`, not `Double`, and scoped to single-occurrence (Custom) habits only.** Matches the existing `timesPerWeekTarget: Int` precedent; avoids floating-point threshold comparisons; a numeric target doesn't map cleanly onto multi-occurrence habits like Prayer.
4. **Smart Reminders don't try to be "live."** Local notifications can't recompute "is this still true" at fire time without a Notification Service Extension. Resolved by making reschedules frequent enough (launch/foreground/edit) that staleness is rare, rather than building the extension.
5. **Biometric lock re-locks on every background→foreground, not just cold launch.** Matches the standard pattern from banking/password-manager apps.
6. **Onboarding replaced silent auto-seeding of starter habits.** The old behavior (silently creating Prayer/Gym/Work the moment Today first rendered) fired location/notification permission prompts with zero context; onboarding makes every choice explicit and primes permissions before requesting them.
7. **`HabitService.update(...)`'s `targetValue`/`unit`/`customColorHex` parameters are non-optional, unlike `create(...)`'s.** Forces every call site to explicitly decide what happens to a habit's config on edit, preventing a forgotten parameter from silently erasing it.

---

## Bugs

Full tracker lives in `KNOWN_ISSUES.md`. Headlines:

- **Fixed this session:** `AccentColorPickerView`'s decorative border/checkmark overlay on the new "Custom" swatch was silently intercepting taps meant for the native `ColorPicker` beneath it (a default SwiftUI `.overlay()` hit-testing gotcha). Fixed by marking each decorative overlay `.allowsHitTesting(false)`.
- **Fixed this session:** `project.yml` missing an explicit signing team caused every `xcodegen generate` to wipe Xcode-GUI-set signing, breaking physical-device builds. Fixed by declaring `CODE_SIGN_STYLE`/`DEVELOPMENT_TEAM` in `project.yml` itself.
- **Fixed pre-session (per commit history):** the auto-seeded Prayer habit's `reminderEnabled: true` never actually resulted in a scheduled notification, because `HabitService.create()` was called directly rather than through `AddEditHabitViewModel.save()` (the only path that triggers a notification request). Fixed by the Onboarding feature, which routes all first-run habit creation through the same explicit-permission-request flow as manual habit creation.
- **Open / unverified:** see `KNOWN_ISSUES.md` for the current list — mostly interaction paths that couldn't be confirmed end-to-end via the simulator-automation tooling in this environment (not known code defects).

---

## Development History

Reconstructed from `git log` (11 commits, all dated 2026-07-23 through 2026-07-29) plus session narrative. Full changelog in `CHANGELOG.md`.

1. **Initial commit** (`c8ecfb1`, 2026-07-23) — the entire v1 scaffold landed as one commit: design system, all core models (`Habit`/`Occurrence`/`Completion`), all core services, Today/Habits/Stats/Settings/Add-Edit/Habit-Insights views, the full early Swift Testing suite, and `ARCHITECTURE.md` itself. This single commit represents a large amount of iterative work (scaffold → design system → models → persistence → services → each screen → accessibility → polish → a visual redesign → prayer-method configuration → Habit Insights) that predates the visible conversation window — the commit boundary doesn't reflect a single work session.
2. **Onboarding flow** (`8aa9ba3`) — replaced silent starter-habit auto-seeding with an explicit welcome → choose-habits → conditional-priming flow; fixed the dormant Prayer-reminder bug above as a side effect of routing habit creation through one path.
3. **CSV/JSON data export** (`b27cd0e`) — `ShareLink`-based; relocated `Frequency.displayName` from a ViewModel into the Model layer so `ExportService` didn't need a third copy of "human-readable frequency" logic.
4. **Custom accent color picker** (`bc6a50a`) — app-wide accent, reusing the existing per-habit `AccentColorPickerView` unmodified.
5. **Biometric app lock** (`06f39f5`) — `AuthenticationService` wrapping `LocalAuthentication`, the app's 3-way root branch became 4-way, `scenePhase`-driven re-lock.
6. **Smart Reminders** (`bf305cf`) — resolved the "local notifications can't be live" problem via reschedule frequency rather than a Notification Service Extension.
7. **App icon redesign** (`b67a83a`).
8. **Interaction and visual polish pass** (`f762452`) — triggered by a user-shared third-party "master audit"; fact-checked every claim against the real codebase before acting on any of it (see Lessons Learned).
9. **Streak Shields** (`5153c15`) — new `Shield` model, `StreakService` shield-priority logic, `ManageShieldsView`.
10. **Quantifiable habit logging** (`bd2fa6f`) — `targetValue`/`unit`/`value`, `CompletionService.isCompleted` became threshold-aware.
11. **Mid-session, no code commit: physical device deployment.** Installed on the developer's own iPhone (discovering and permanently fixing the `project.yml` signing bug above), then on a friend's iPhone via direct USB for one-off feedback — using `mcp__computer-use__*` tooling to drive Xcode's Signing & Capabilities GUI directly, since command-line `xcodebuild` can't access Xcode's GUI-authenticated Apple ID session.
12. **Mid-session, no code commit: iOS Simulator runtime went missing.** A genuine environment issue (confirmed unrelated to any code change) — `xcrun simctl list runtimes` returned empty despite SDKs being present. Diagnosed via a chain of `xcodebuild`/`simctl` commands, fixed via `xcodebuild -downloadPlatform iOS` at the user's explicit choice.
13. **Emoji icons, custom accent color, quick shields** (`82e82bb`) — delivered from a bundled, copy-pasted "master prompt" covering three features at once. Researched via three parallel Explore agents before planning; two real design forks (custom-color scope, shield granularity) were resolved directly with the user via `AskUserQuestion` rather than assumed; found and fixed the `AccentColorPickerView` hit-testing bug above during verification.
14. **This documentation pass** — generating the `docs/` knowledge base you're reading now.

---

## Current State

See `PROJECT_STATE.md` for the live version — it's updated every session and this section is not. As of this writing: every application-code feature task is complete and pushed to `origin/main` at `82e82bb`; the only open work is this documentation generation itself, being committed separately once finished.

---

## Lessons Learned

- **Grep every call site before changing a shared enum's shape**, not just the obvious ones. `AccentColor` had 13+ call sites hardcoding specific cases as decorative/preview tints, well outside the "per-habit color" usages that would come to mind first. Missing them would have been a silent visual regression, not a compile error.
- **XcodeGen regenerates the entire `.xcodeproj` from `project.yml` on every `xcodegen generate`.** Anything configured only through Xcode's GUI (a signing team, a capability) is wiped the next time the project regenerates unless it's also declared in `project.yml`. Discovered the hard way via a confusing "No Account for Team" error during physical-device deployment; fixed permanently by declaring `CODE_SIGN_STYLE`/`DEVELOPMENT_TEAM` in `project.yml` itself.
- **A single choke point makes cross-cutting features safe.** Quantifiable Logging conceptually touches streaks, insights, notifications, export, and the completion UI — but because every one of those already routed through `CompletionService.isCompleted`/`isFullyCompleted` instead of re-implementing its own check, the feature was safe to build by changing one method rather than ~15 call sites.
- **Simulator-automation tooling in this environment is unreliable for certain native/UIKit-bridged controls.** Plain taps often don't register on `Toggle` (`UISwitch`) or `ColorPicker` (`UIColorWell`); a `touch_path` drag gesture (press, move a few points, release) reliably worked around it for `Toggle` but was inconsistent for `ColorPicker`. Basic taps also periodically stopped registering across the *entire* app for stretches at a time — a connection/environment issue unrelated to any specific control or any code change. `xcrun simctl pbcopy` corrupts UTF-8 input, so emoji characters can't be reliably injected into the simulator's pasteboard from the host shell. None of this reflects code defects; see `KNOWN_ISSUES.md` for exactly what's unverified as a result.
- **Fact-check third-party "master audits" and copy-pasted prompts against the actual current code before implementing anything from them.** This session encountered two such external prompts. One contained an entire hallucinated feature ("Quit Habit Logic," smoking-cessation-style, describing something that has never existed in Anchor) alongside genuinely accurate observations (the original app icon glyph really was ambiguous). Treat every specific, checkable claim as needing verification, not as ground truth.
- **When a new request conflicts with an already-shipped, deliberate design decision, surface the conflict and let the user choose — don't silently override history.** "Make colors fully custom" conflicted with the already-shipped curated-palette decision; the conflict was named explicitly and the user chose a middle path (add a 9th swatch) rather than having it silently overridden or silently ignored.
- **Physical-device deployment pipeline:** `xcrun xctrace list devices` (find UDID) → `xcodebuild build -destination 'id=<UDID>' -allowProvisioningUpdates` → `xcrun devicectl device install app --device <UDID> <path>.app` → `xcrun devicectl device process launch --device <UDID> <bundle-id>`. First install on any device needs a one-time manual trust step: Settings → General → VPN & Device Management → trust the developer certificate.

### Distribution constraints (learned the hard way)

Free "Personal Team" signing (no paid Apple Developer account) means: apps expire after 7 days on-device, and can *only* be installed via direct USB + Xcode — no OTA/wireless distribution is possible at all. TestFlight and Ad Hoc distribution both require a paid $99/year Apple Developer Program membership. Enrolling requires entering payment information, which Claude must never do on the user's behalf (a hard safety constraint, not a preference) — if the user wants TestFlight, they need to enroll themselves.

---

## Future Roadmap

Full prioritized list in `TODO.md`. Headline: the v1 feature set (per `PROJECT_SPEC.md`) is complete. What's left is either explicitly version-gated (Calendar history v1.1, Widgets v1.2, iCloud Sync v1.3, Apple Watch v1.4 — "do not implement roadmap items in v1") or explicitly deferred pending more usage data (cross-habit correlation insights).

---

## Prompt For Future Claude

Paste this into a new Claude Code conversation to resume development with full context:

```
This is the Anchor iOS habit tracker (SwiftUI + SwiftData, MVVM+DI). Before doing anything else:

1. Read CLAUDE.md (engineering rules — timeless, rarely changes).
2. Read docs/CLAUDE_CONTEXT.md (this file — full project history and reasoning).
3. Read docs/PROJECT_STATE.md (exactly where the last session stopped — this is the
   most likely to have changed since CLAUDE_CONTEXT.md was last updated).
4. Skim docs/PROJECT_SPEC.md (what the app does) and docs/ARCHITECTURE.md (how it's
   built) for anything relevant to what I'm about to ask you to do.
5. Check docs/KNOWN_ISSUES.md and docs/TODO.md if what I'm asking relates to an
   open issue or backlog item.

Do not start writing code until you've done this — the project has enough
accumulated history that skipping it will cause you to rediscover already-settled
decisions (see docs/DECISIONS.md) or reintroduce already-fixed bugs.

After reading, confirm you understand the current state in 2-3 sentences, then wait
for my actual request.
```

---

## When To Regenerate This Knowledge Base

Re-run the documentation-generation prompt (or at minimum manually update `PROJECT_STATE.md` and `CHANGELOG.md`) whenever:

- a major feature is completed
- the architecture changes
- a significant refactor happens
- before starting a new Claude Code conversation on this project
- before this conversation reaches roughly 70% of its context budget

`PROJECT_STATE.md` is cheap to update and should happen every session. The other files only need a full pass after something big enough to actually change them.
