# TODO.md

Prioritized backlog. This is the actionable, living companion to `PROJECT_SPEC.md`'s "Future Roadmap" and "Backlog" sections — those describe *what*, this describes *what to do about it and in what order*.

There is currently nothing Critical or High priority open. The v1 feature set is complete.

---

## Critical

None.

## High

None.

## Medium

### Verify emoji entry / custom ColorPicker / shield long-press end-to-end
- **Why it's here:** these three interaction paths were implemented and code-reviewed carefully, and their surrounding UI was confirmed visually via screenshots, but the actual gesture (typing/pasting an emoji, opening the native `ColorPicker` sheet, long-pressing a Today card) could not be driven reliably through the simulator-automation tooling available last session. See `KNOWN_ISSUES.md`.
- **Complexity:** Low (no code change expected — this is a verification task, not a feature).
- **Dependencies:** A working simulator session (basic taps need to be reliable first) or a physical device.

### Re-check `ManageShieldsView` and the new Today quick-action stay in sync
- **Why it's here:** both read/write the same `Shield` model through `CompletionService`, so they *should* always agree, but this specific cross-check (shield a day via one entry point, confirm it shows up via the other) wasn't completed interactively last session.
- **Complexity:** Low.
- **Dependencies:** Same as above.

## Low

### Heatmap display richness for shielded + below-target quantifiable days
- **Why it's here:** `StreakService.dailyHistory`'s `.partial` state only fires for multi-occurrence "some but not all done" habits. A single-occurrence quantifiable habit logged below target, or a shielded quantifiable day, currently renders identically to `.missed`/`.shielded` without distinguishing "attempted but short" from "did nothing." Correctness is unaffected — this is purely a display gap, deliberately not fixed when quantifiable logging shipped (see `DECISIONS.md` ADR-010).
- **Complexity:** Low-Medium — would need a new `DayCompletionState` case or a richer value on the existing ones, plus a new heatmap color, plus new `StreakServiceTests` cases.
- **Dependencies:** None.

### Unit label validation in Add/Edit
- **Why it's here:** `unitLabel` in `AddEditHabitViewModel` is free text with no length cap or emoji-blocking — a user could type something absurd. Not a bug, just unpolished.
- **Complexity:** Trivial.
- **Dependencies:** None.

## Future Ideas (from `PROJECT_SPEC.md`'s roadmap — do not implement ahead of schedule)

- **v1.1 — Calendar history.** A calendar-style view of past completions, distinct from the existing heatmap grid.
- **v1.2 — Widgets.** Needs a new WidgetKit extension target — a genuine scope jump, deliberately deferred every time it's come up.
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

### Add `StreakServiceTests` cases for the heatmap display-richness gap, if that gap is ever closed
- See "Heatmap display richness" above — tracked together since the fix and its tests are the same unit of work.

### Consider one `CompletionServiceTests.swift` if `CompletionService` ever grows non-trivial logic beyond threshold comparison
- Currently it's exercised only indirectly. Revisit if it grows.
