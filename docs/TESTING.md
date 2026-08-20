# TESTING.md — Testing Strategy

What gets automated tests, what doesn't, and why. Build and run commands live in `DEVELOPMENT_GUIDE.md` — this file doesn't repeat them.

Anchor uses **Swift Testing** (`import Testing`, `@Test`, `#expect`), not XCTest.

---

## The Boundary

| Gets a test suite | Doesn't |
|---|---|
| Services with non-trivial derived computation: `StreakService`, `InsightsService`, `ExportService`, the `ScheduleProvider` strategies, `DueDateRule` | Thin CRUD/pass-through glue: `HabitService`'s create/update/archive/delete |
| Pure extensions with real logic: `String.isSFSymbolCompatible`, `Color.toHexInt()` | Services wrapping live system/hardware frameworks: `LocationService`, `NotificationService`, `AuthenticationService` — not practical without mocking infrastructure this project doesn't have |
| | `CompletionService` — exercised indirectly through `StreakServiceTests`/`InsightsServiceTests` fixtures, since it's mostly thin dispatch over SwiftData relationships |
| | ViewModels, even ones with real logic — verified manually in the simulator |
| | Pure UI (empty states, gradient strokes, card borders, tab tinting) — verified manually |

This boundary has held across every feature added. Don't add a test file reflexively — ask whether the thing has non-trivial derived computation with edge cases, or is thin glue, a system wrapper, or pure UI.

## Current Suite

**54 tests, all passing, across 7 files** (verified 2026-08-20):

- **`StreakServiceTests.swift` — 25 cases, by far the most important file in the suite.** Streak continuity, best-vs-current streak, weekly-target streaks, `dailyHistory`'s multi-way state (`.completed`/`.partial`/`.missed`/`.notDue`/`.shielded`), shield continuity/non-increment/priority ordering, quantifiable-threshold breaking and completing, and `dayCompletionState`'s single-day lookups (cross-checked against `dailyHistory`, future-date and pre-creation `.notDue`, today-with-nothing-logged `.missed`). **Read this before changing `StreakService`, `Frequency`, or `DueDateRule`.**
- `InsightsServiceTests.swift` — 8 cases: trend bucketing (week/month/year with boundary cases), time-of-day distribution, weekday distribution.
- `ExportServiceTests.swift` — 7 cases: CSV header/escaping/quoting, zero-completion edge case, JSON round-trip, archived-habit inclusion, quantifiable value export.
- `ScheduleProviderTests.swift` — 7 cases: `FixedTimeProvider`, `WeeklyProvider`, `PrayerProvider` (with and without a coordinate).
- `AnchorTests.swift` — 3 cases. **Misleadingly named** (Xcode's default scaffold, never renamed): it holds the `DueDateRule` suite, not a catch-all.
- `StringIconTests.swift` — 3 cases: SF Symbol names, simple emoji, compound (ZWJ/keycap) emoji.
- `ColorHexTests.swift` — 1 case: `Color(hex:)` ↔ `toHexInt()` round-trip.

**Shared fixtures** live in `TestSupport.swift`: a fixed UTC `Calendar` for date-math determinism (used by exact-string/timestamp assertions) and an in-memory `ModelContext` factory (for tests needing a real `CompletionService`). `StreakServiceTests` deliberately uses `Calendar.current` instead — it tests real local-day-boundary behavior. **Match whatever the file you're extending already uses.**

## Edge Cases Worth Remembering

- **"Today in progress" leniency.** An incomplete *today* doesn't break a streak; an incomplete *past* due day does. This applies to quantifiable habits too — a below-target value logged today doesn't break the streak, the same shortfall on a past day does. Get this backwards and a test passes for the wrong reason: `quantifiableBelowTargetDoesNotComplete` was originally written against "today" and had to be corrected to a past day for exactly this reason.
- **Shield priority in `dailyHistory`.** Full completion always wins outright. A day that is both fully completed and shielded reports `.completed`, not `.shielded`.
- **Time-zone determinism.** Don't mix the fixed UTC calendar and `Calendar.current` — check what the file already uses.

## Manual Verification (Simulator)

Every shipped feature has followed this shape — use it as the template:

1. Build (zero warnings) → test (all passing). Run `xcodegen generate` first only if `project.yml` changed.
2. Install and launch on a booted simulator.
3. Walk the golden path for the new feature.
4. Walk its specific edge cases — e.g. for shields, a habit that doesn't support them; for quantifiable habits, crossing the target exactly.
5. **Regression check:** confirm the feature didn't change behavior it shouldn't touch — quantifiable logging shouldn't alter how binary habits behave at all.
6. Light mode *and* dark mode.
7. Screenshot as evidence before reporting the task complete.

## Regression Checklist

Re-run whenever touching `CompletionService`, `StreakService`, `Habit`, `Completion`, or `Frequency` — the shared core every feature depends on:

- [ ] A binary Daily habit toggles complete/incomplete correctly and builds a streak.
- [ ] A multi-occurrence (Prayer-style) habit shows partial progress and only counts as done when every occurrence is done.
- [ ] A `.timesPerWeek` habit builds a streak on its weekly target, not daily.
- [ ] A quantifiable habit requires reaching its target, not just any non-zero log.
- [ ] A shielded day bridges a streak without incrementing or breaking it, and doesn't show as `.missed` in the heatmap.
- [ ] Archived habits are excluded from Today/Habits but still appear in Stats history and export.
- [ ] CSV and JSON export both include every habit type correctly, including the Value column and archived habits.

## Needs Manual Verification — Structurally Untestable

- **Actual biometric Face ID/Touch ID match.** The simulator's biometric-match simulation isn't drivable from this session's tooling.
- **Actual notification firing** with correct, fresh content at its scheduled time. No tool available to fast-forward wall-clock time or trigger a specific pending notification.

## Simulator-Automation Tooling Quirks

**Environment notes, not app bugs.** Three separate "known issues" turned out to be tooling limitations, not defects — see `KNOWN_ISSUES.md` R6, R7, and R8. **Verify on a device or with a human before concluding a UI interaction is broken.**

- **Tap coordinates are in device points, not screenshot pixels.** Confirmed as a real, repeatable failure mode: treating a ~918×1996px screenshot as if it were the 402×874pt coordinate space makes taps silently miss or land out of bounds — which looks identical to "taps stopped registering app-wide." Always scale by the ratio between the screenshot and the `attach` call's reported point dimensions. Rule this out before concluding the environment is flaky.
- **UIKit-bridged controls are unreliable under synthetic taps.** `Toggle` (`UISwitch`) and `ColorPicker` (`UIColorWell`) often don't respond. A `touch_path` drag (press, move a few points, release) reliably worked around it for `Toggle`, inconsistently for `ColorPicker`.
- **No on-screen software keyboard renders** in this streamed simulator environment — emoji entry and any keyboard-dependent path can't be driven here.
- **A single `ToolbarItem` button can stop responding** while everything else works. Confirmed 2026-07-31 with `HabitsView`'s "+" (Add Habit): 10+ attempts, correct coordinates cross-checked against known-good tab-bar positions, full app restart, fresh simulator boot — all failed, while tab bar and in-view buttons worked normally in the same session. Never diagnosed. If it recurs, don't assume app-wide unresponsiveness; it may be isolated to one control.
- **`xcrun simctl pbcopy` corrupts UTF-8** piped from the host shell — don't use it to seed the pasteboard with non-ASCII text.

## Future Automated Tests

Nothing urgent queued. The one candidate: a `CompletionServiceTests.swift`, *if* that service ever grows logic beyond threshold comparison and dispatch. See `TODO.md`.
