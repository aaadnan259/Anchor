# TODO.md

Prioritized backlog. This is the actionable, living companion to `PROJECT_SPEC.md`'s "Future Roadmap" and "Backlog" sections — those describe *what*, this describes *what to do about it and in what order*.

One Medium item open (a verification blocker, not a known app defect) — see below. Nothing Critical, High, or Low.

---

## Critical

None.

## High

None.

## Medium

### Verify Calendar History (and the previous session's Today-screen interactions) end-to-end
- **Why it's here:** `HabitsView`'s "+" (Add Habit) toolbar button stopped responding to synthetic taps in the simulator-automation tooling this session (10+ attempts, multiple techniques, a full app restart, and a fresh simulator boot all failed the same way, while every other control tested — tab bar, in-view buttons — worked normally). Since it's the only way to create a habit, it blocked verifying Calendar History (`Anchor/Views/CalendarHistoryView.swift`), and re-blocked the three items already carried over unverified from the previous session (full-card tap, swipe-to-delete, 100%-completion celebration). See `KNOWN_ISSUES.md` #5.
- **Complexity:** Low (no code change expected — this is a verification task; nothing about the button's code suggests an app-level cause).
- **Dependencies:** A physical device, or a simulator session driven by an actual human at the keyboard — the same resolution path that closed out the emoji-entry/`ColorPicker` gaps (`KNOWN_ISSUES.md` R6).

~~Verify emoji entry / custom ColorPicker end-to-end~~ — **done 2026-07-30, on a physical device.** Both work as expected: a real emoji typed via the system keyboard saves and renders correctly wherever a habit's icon is drawn; the 9th "Custom" swatch opens the native iOS color picker and an exact color applies correctly. No crashes or unexpected behavior. See `KNOWN_ISSUES.md` R6.

~~Re-check `ManageShieldsView` and the new Today quick-action stay in sync~~ — **done 2026-07-30.** Verified in a live simulator session: shielding today via the Today card's long-press quick-action correctly shows up in `ManageShieldsView`'s calendar and vice versa. See `KNOWN_ISSUES.md` R4.

## Low

~~Heatmap display richness for shielded + below-target quantifiable days~~ — **done 2026-07-30.** `StreakService.dailyHistory` now reports `.partial` (reusing the existing state/color, not a new one) for a due, unshielded, single-occurrence day with a logged value greater than zero but below target — distinguishing "attempted but short" from "did nothing." A shielded quantifiable day already correctly reported `.shielded` regardless of logged value (that part was never actually a gap — a shielded day is a shielded day irrespective of value). See `DECISIONS.md` ADR-015.

~~Unit label validation in Add/Edit~~ — **done 2026-07-30.** `AddEditHabitViewModel.unitLabel` now clamps to 24 characters via a `didSet`, preventing an absurdly long value. Emoji-blocking was considered and deliberately skipped — it would reject legitimate non-ASCII unit labels (accented characters, other scripts) for no real benefit, since a long value was the actual "something absurd" concern, not the character set.

## Future Ideas (from `PROJECT_SPEC.md`'s roadmap — do not implement ahead of schedule)

- ~~v1.1 — Calendar history.~~ **Shipped 2026-07-31.** See `Anchor/Views/CalendarHistoryView.swift`, `CHANGELOG.md`.
- **v1.2 — Widgets.** Needs a new WidgetKit extension target sharing data via an App Group — deferred pending a paid Apple Developer account (free "Personal Team" signing makes App Group provisioning unreliable and risks the existing physical-device build pipeline). See `DECISIONS.md` ADR-017. Paused at the user's explicit request as of 2026-07-31 — do not raise this again until they say they're ready.
- **v1.3 — iCloud Sync.** Explicitly out of scope for v1 (no accounts, no cloud is a deliberate v1 promise per `PROJECT_SPEC.md`).
- **v1.4 — Apple Watch.**

## Technical Debt

### `Frequency.supportsShields` had zero call sites for one full feature cycle
- **Status:** resolved as of Quick Shields (`82e82bb`) — it's now wired into `HabitCardView`'s context-menu gate. Listed here only as a historical note: it's worth grepping for other properties/methods that look similarly unused before assuming something is dead code vs. "planned for a feature that hasn't landed yet."

### No dedicated test suite for `CompletionService`, `NotificationService`, `LocationService`, or `AuthenticationService`
- **Why it's this way, not a gap to close reflexively:** established, deliberate testing boundary (see `TESTING.md`) — these either wrap live system frameworks not practical to unit-test without mocking infrastructure this project doesn't have (`LocationService`, `NotificationService`, `AuthenticationService`), or are thin CRUD/pass-through glue exercised indirectly through the services that depend on them (`CompletionService`, exercised via `StreakServiceTests`/`InsightsServiceTests`). Don't add tests here reflexively — only if genuinely non-trivial logic accumulates in one of these files.

## Refactoring

Nothing currently flagged. The architecture has absorbed 10+ feature additions without needing a rewrite (per `ARCHITECTURE.md`'s "Future Extensibility" section) — no signs of that changing.

## UX Improvements

### Curate emoji picker as an alternative to the free-text field (rejected once, revisit only if requested)
- **Why it's here:** considered and explicitly rejected in favor of the system emoji keyboard (`DECISIONS.md` ADR-011). Not a task to pick up proactively — listed only so a future session doesn't re-litigate it without knowing it was already decided.

## Performance

Nothing currently flagged. `ARCHITECTURE.md`'s performance targets (60fps, sub-1s cold launch, no expensive work in `View.body`) have held through every feature added; no profiling has surfaced a regression.

## Accessibility

Nothing currently flagged outstanding. VoiceOver labels, Dynamic Type, 44pt touch targets, and Reduce Motion fallbacks have been part of the Definition of Done for every feature shipped — see `TESTING.md` for the manual verification checklist.

## Testing

~~Add `StreakServiceTests` cases for the heatmap display-richness gap~~ — **done 2026-07-30**, alongside the fix itself. See `dailyHistoryQuantifiablePartialToCompleted` and `dailyHistoryQuantifiableNothingLoggedIsMissed` in `StreakServiceTests.swift`.

### Consider one `CompletionServiceTests.swift` if `CompletionService` ever grows non-trivial logic beyond threshold comparison
- Currently it's exercised only indirectly. Revisit if it grows.
