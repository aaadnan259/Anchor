# TODO.md — Actionable Backlog

Work that remains. Shipped work lives in `CHANGELOG.md`; product scope in `PROJECT_SPEC.md`; defects in `KNOWN_ISSUES.md`. Nothing here is historical — if it's listed, it's still to be done.

**Currently open: one Medium verification task. Nothing Critical, High, or Low.**

---

## Critical / High / Low

None.

## Medium

### Verify the "By Day of Week" radial chart end-to-end
`Anchor/Components/WeekdayRadialChartView.swift` builds cleanly and its data side has full `InsightsServiceTests` coverage, but it has never been seen rendered. A `simctl install`/`launch` attempt timed out mid-boot and the session ended before a retry.

- **Where:** Habit Insights, between Time of Day and History.
- **What to check:** that a 0%-rate weekday's floored 8% sliver reads sensibly rather than looking broken, and light/dark contrast.
- **Complexity:** Low — no code change expected unless it visually misbehaves.
- **Needs:** a working simulator session (retry with a fresh boot) or a physical device. If `HabitsView`'s "+" button won't respond and blocks habit creation, that's the known environment gap (`KNOWN_ISSUES.md` R8), not a new problem.

---

## Future Ideas — do not implement ahead of schedule

From `PROJECT_SPEC.md`'s roadmap. Listed for awareness, not as work to pick up.

- **v1.2 — Widgets.** Deferred pending a paid Apple Developer account, and paused at the user's request. See ADR-017.
- **v1.3 — iCloud Sync.** Out of scope for v1 by deliberate product promise.
- **v1.4 — Apple Watch.**
- **Cross-habit correlation insights.** Deferred pending real usage data — statistically meaningless on sparse early history, so this is blocked on data, not effort.

## Already Decided — do not re-litigate

Listed so a future session doesn't reopen a settled question without knowing it was settled.

- **A curated emoji picker grid** instead of the system emoji keyboard — considered and rejected (ADR-011).
- **Per-occurrence shielding** — considered twice, declined twice (ADR-009, ADR-013).
- **Shields for weekly-target habits** — surfaced to the user, who chose to leave the scoping as-is (ADR-009).

## Technical Debt

**No dedicated test suite for `CompletionService`, `NotificationService`, `LocationService`, or `AuthenticationService`.** This is the deliberate testing boundary, not a gap to close reflexively — three wrap live system frameworks that aren't practical to unit-test without mocking infrastructure this project doesn't have, and `CompletionService` is thin dispatch exercised indirectly through `StreakServiceTests`/`InsightsServiceTests`. See `TESTING.md`. Add tests here only if genuinely non-trivial logic accumulates.

## Refactoring · Performance · Accessibility

Nothing flagged in any of the three.

- The architecture has absorbed ten-plus feature additions without needing a rewrite.
- Performance targets (60fps, sub-1s cold launch, no expensive work in `View.body`) have held; no profiling has surfaced a regression.
- VoiceOver labels, Dynamic Type, 44pt targets, and Reduce Motion fallbacks are part of the Definition of Done for every feature shipped.

## Testing

One candidate, not urgent: a `CompletionServiceTests.swift`, *if* `CompletionService` ever grows logic beyond threshold comparison and dispatch. Currently exercised only indirectly.
