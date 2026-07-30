# TESTING.md

## Testing Strategy

Anchor uses Swift Testing (`import Testing`, `@Test`, `#expect`), not XCTest. Run via `xcodebuild test` — see `DEVELOPMENT_GUIDE.md` for the exact command.

**The established boundary — what gets a dedicated automated test suite vs. what doesn't:**

| Gets tests | Doesn't get tests |
|---|---|
| Services with non-trivial derived computation: `StreakService`, `InsightsService`, `ExportService`, `ScheduleProvider` strategies, `DueDateRule` | Services that are thin CRUD/pass-through glue: `HabitService`'s create/update/archive/delete |
| Pure extensions with real logic: `String.isSFSymbolCompatible`, `Color.toHexInt()` | Services wrapping live system/hardware frameworks: `LocationService`, `NotificationService`, `AuthenticationService` — not practical to unit-test without mocking infrastructure this project doesn't have |
| | `CompletionService` — exercised only indirectly through `StreakServiceTests`/`InsightsServiceTests` fixture helpers, since it's mostly a thin dispatch layer over SwiftData relationships |
| | ViewModels — even ones with real logic (`TodayViewModel`, `HabitsViewModel`) — verified manually in the simulator instead |
| | Pure UI (empty-state swaps, gradient strokes, card borders, tab bar tinting) — verified manually |

This boundary has held consistently across every feature added. Don't add a test file reflexively; ask "does this have non-trivial derived computation with edge cases, or is it thin glue/a system wrapper/pure UI?" before creating one.

**Current suite: 46 tests, all passing, across 7 files:**

- `AnchorTests/StreakServiceTests.swift` — the largest by far (20 cases). Streak continuity, best-vs-current streak, weekly-target streaks, `dailyHistory`'s multi-way state (`.completed`/`.partial`/`.missed`/`.notDue`/`.shielded`), shield streak-continuity/non-increment/priority-ordering, quantifiable-habit threshold breaking/completing/history-transition.
- `AnchorTests/InsightsServiceTests.swift` — trend bucketing (week/month/year, including boundary cases), time-of-day distribution bucketing.
- `AnchorTests/ScheduleProviderTests.swift` — `FixedTimeProvider`, `WeeklyProvider`, `PrayerProvider` (with and without a coordinate).
- `AnchorTests/ExportServiceTests.swift` — CSV header/escaping/quoting, zero-completion edge case, JSON round-trip, archived-habit inclusion, quantifiable-habit value export.
- `AnchorTests/ColorHexTests.swift` — `Color(hex:)` ↔ `toHexInt()` round-trip.
- `AnchorTests/StringIconTests.swift` — `isSFSymbolCompatible` for SF Symbol names, simple emoji, compound (ZWJ/keycap) emoji.
- `AnchorTests.swift` (misleadingly named — Xcode's default scaffold name, never renamed) — the `DueDateRule` suite: daily/weekly/weekdays due-date logic.

**Shared fixtures:** `AnchorTests/TestSupport.swift` — a fixed UTC `Calendar` for date-math determinism (used by tests that do exact-string or exact-timestamp assertions), an in-memory `ModelContext` factory (used by tests that need a real `CompletionService`, e.g. shield/streak tests). `StreakServiceTests` specifically uses `Calendar.current` instead — see the comment at the top of that file explaining why (it's testing real local-day-boundary behavior, not deterministic UTC string output).

---

## Manual Tests (Simulator)

Every feature's shipped verification pass has followed roughly this shape — use it as a template for new features:

1. `xcodegen generate` (only if `project.yml` changed) → `xcodebuild build` (must show zero warnings, `** BUILD SUCCEEDED **`) → `xcodebuild test` (must show `Test run with N tests passed`).
2. Install/launch on a booted simulator (see `DEVELOPMENT_GUIDE.md`).
3. Walk the golden path for the new feature.
4. Walk the edge cases specific to that feature (e.g. for shields: a habit that doesn't support them; for quantifiable habits: crossing the target exactly).
5. **Regression check:** confirm the feature didn't change behavior for habits/screens it shouldn't touch — e.g. quantifiable logging shouldn't change how Prayer/Gym/Work (binary habits) behave at all.
6. Light mode and dark mode both.
7. Screenshot the result as evidence before reporting the task complete.

## Regression Checklist

Re-run this whenever touching `CompletionService`, `StreakService`, `Habit`, `Completion`, or `Frequency` — the shared core every feature depends on:

- [ ] A plain binary Daily habit still toggles complete/incomplete correctly and builds a streak.
- [ ] A multi-occurrence habit (Prayer-style) still shows partial progress correctly and only counts as done when every occurrence is done.
- [ ] A `.timesPerWeek` habit still builds a streak based on weekly target, not daily.
- [ ] A quantifiable habit still requires reaching its target, not just any non-zero log, to count as complete.
- [ ] A shielded day still bridges a streak without incrementing or breaking it, and doesn't show as `.missed` in the heatmap.
- [ ] Archived habits are excluded from Today/Habits but still appear in Stats history and export.
- [ ] Export (CSV and JSON) still includes every habit type correctly, including the `Value` column for quantifiable habits and archived habits.

## Edge Cases Worth Remembering

- **"Today in progress" leniency:** an incomplete *today* doesn't break a streak (it's still in progress), but an incomplete *past* due day does. This distinction matters for quantifiable habits too — a below-target value logged *today* doesn't break the streak; the same shortfall on a past day does. Get this backwards and a test will look like it passes for the wrong reason (see the `quantifiableBelowTargetDoesNotComplete` test's history — it was originally written testing "today" and had to be corrected to test a past day instead, precisely because of this leniency).
- **Shield priority ordering in `dailyHistory`:** full completion always wins outright, even if the day is also shielded. A day that's both fully completed and shielded reports `.completed`, not `.shielded`.
- **Time zone determinism:** `StreakServiceTests` uses `Calendar.current` deliberately (real local-day-boundary behavior); other suites doing exact-string assertions use `TestSupport`'s fixed UTC calendar. Don't mix these up when adding a new test — check what the file you're extending already uses and match it.

## Future Automated Tests

See `TODO.md`'s Testing section — nothing urgent queued. The main candidate, if it ever becomes worth it: a `CompletionServiceTests.swift` if that service ever grows logic beyond simple threshold comparison and dispatch.

## Known Areas Needing Manual (Not Automated) Verification

These are things automated tests structurally can't cover, tracked here rather than treated as gaps:

- Actual biometric Face ID/Touch ID match — the simulator's biometric-match simulation (Features menu → Face ID → Matching/Non-matching) isn't drivable from this session's tooling.
- Actual local notification firing with correct, fresh content at its scheduled time — no simulator tool available to fast-forward wall-clock time or trigger a specific pending notification on demand.
- The three interaction paths listed in `KNOWN_ISSUES.md` (emoji entry, `ColorPicker` opening, shield long-press) — not structurally unverifiable, just not completed yet due to simulator-automation tooling instability in the last session. Worth a real attempt in a fresh, stable session before assuming they need the "manual only" treatment above.

## Simulator-Automation Tooling Quirks (environment notes, not app bugs)

- Plain taps are unreliable on `Toggle` (`UISwitch`) and `ColorPicker` (`UIColorWell`) — both are UIKit-bridged controls. A `touch_path` drag gesture (press, move a few points, release) reliably worked around this for `Toggle`; results were inconsistent for `ColorPicker`.
- `xcrun simctl pbcopy` corrupts UTF-8 input piped from the host shell — don't rely on it to seed the simulator's pasteboard with non-ASCII text (e.g. to test paste-based emoji entry).
- Basic tap responsiveness has, on occasion, degraded across the *entire* app for stretches — re-attach the simulator connection and confirm a known-simple interaction (e.g. a tab bar switch) works before trusting results from a more complex one.
- Coordinate space for taps is in **device points**, not screenshot pixels — always use the `(width, height)` reported by the `attach` call, not pixel measurements eyeballed from a screenshot image.
