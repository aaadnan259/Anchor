# KNOWN_ISSUES.md — Defects & Unverified Areas

Defects and things not yet verified. Distinct from `TODO.md`, which tracks planned work. An item graduates from here to `TODO.md` once it's understood well enough to be actionable.

---

## Open

**None.** Every item ever logged here has been fixed or verified end-to-end.

One unverified area is tracked in `TODO.md` rather than here, because it's a verification task with no suspected defect: the "By Day of Week" radial chart has full data-side unit coverage but hasn't been seen rendered.

---

## Resolved

### R7 — Calendar History and Today-screen polish · user-confirmed working
**2026-07-31.** Confirmed by the user directly on a real device, outside the simulator tooling (which was blocked by R8 for this whole round of features): Calendar History's month grid, full-card tap-to-complete, swipe-to-delete, and the 100%-completion celebration. No bugs found.

*This closed the verification need, not R8's underlying tooling gap — that remains undiagnosed.*

### R6 — Emoji entry and custom `ColorPicker` · verified on a physical device, no bugs
**2026-07-30**, on the developer's iPhone (iOS 26.6, `iPhone17,1`), installed via `xcodebuild`/`devicectl` with free Personal Team signing and a one-time profile trust.

Both work as designed: the Emoji-mode field accepts a real emoji from the system keyboard, and it renders correctly everywhere an icon is drawn; the 9th "Custom" swatch opens the native color picker and applies an exact color as the accent, overriding the curated `AccentColor`. No crashes.

**These had been logged as two app bugs. Both were simulator-tooling limitations** — no on-screen keyboard renders in that environment, and `UIColorWell` doesn't respond to synthetic taps. Files: `IconPickerView.swift`, `AccentColorPickerView.swift`.

### R5 — Heatmap didn't distinguish "below-target quantifiable" from "did nothing" · fixed
**2026-07-30.** `dailyHistory` only reported `.partial` when *some* occurrences of a multi-occurrence habit were done. A single-occurrence quantifiable habit logged below target had `completedCount == 0` (since `isCompleted` is threshold-aware), so it fell into the same branch as an empty day — both `.missed`.

**Fix:** `dailyHistory` now checks `CompletionService.value` when `completedCount == 0` and reports `.partial` if anything was logged. Reuses the existing case and color — no new `DayCompletionState`. See ADR-015. Verified by unit tests and visually.

*A shielded quantifiable day was never part of this gap — `isShielded` is checked before that branch, so it always reported `.shielded` correctly. The original wording bundled the two by association.*

### R4 — Shield long-press context menu · verified working, no bug
**2026-07-30**, in a live simulator session. Long-press → "Shield Today" → blue badge appears; the shielded day shows correctly in the card, the Stats/Insights heatmap, and `ManageShieldsView`'s calendar with a working "Remove Shield" — confirming both entry points read and write the same state.

*The earlier non-response was the previous session's tap coordinates, not app behavior: the tool's coordinate space is points, not screenshot pixels. See `TESTING.md`.*

### R3 — Auto-seeded Prayer habit's reminder silently never scheduled
**Fixed during the Onboarding feature (`8aa9ba3`).** `HabitService.seedStarterHabitsIfNeeded` (since deleted) called `create()` directly, bypassing `AddEditHabitViewModel.save()` — the only path that actually requests notification authorization and schedules. Onboarding now routes all first-run creation through the same flow real habits use.

### R2 — `xcodegen generate` silently wiped physical-device signing
**Fixed during physical-device deployment** (window overlapping `bd2fa6f`). `project.yml` never declared a signing team, and `xcodegen generate` regenerates the whole `.xcodeproj` without preserving Xcode-GUI-only settings. **Fix:** `CODE_SIGN_STYLE` and `DEVELOPMENT_TEAM` now live in `project.yml` permanently. See ADR-003.

### R1 — `AccentColorPickerView`'s decorative overlay blocked taps to the `ColorPicker`
**Found and fixed 2026-07-29.** A stroke-only `Circle()` overlay and a checkmark `Image` sat above the `ColorPicker` in z-order; SwiftUI's default `.overlay()` hit-testing intercepts touches across the full bounds even for a mostly-transparent shape. **Fix:** `.allowsHitTesting(false)` on each decorative layer.

---

## Environment Gaps (not app defects)

### R8 — `HabitsView`'s "+" toolbar button doesn't respond to synthetic taps
**2026-07-31, never diagnosed, could recur.** In this environment's simulator-automation tooling, that one `ToolbarItem` button never responded across 10+ attempts — plain taps, held `touch_path`, coordinates cross-checked against known-good tab-bar positions, full app restart, and a fresh simulator boot — while every other control tested worked normally.

It blocked habit creation and therefore all UI verification for that round of features; resolved as a *blocker* by the user testing directly (R7), not as a bug. Possibly the same UIKit-bridging category as `UIColorWell` and the missing on-screen keyboard, but unconfirmed. Full tooling-quirk list: `TESTING.md`.

---

## Technical Debt

Nothing significant. See `TODO.md`. One durable note: `Frequency.supportsShields` had zero call sites for a full feature cycle between Streak Shields and Quick Shields — a reminder to check whether something apparently unused was built ahead of a planned feature before deleting it as dead code.
