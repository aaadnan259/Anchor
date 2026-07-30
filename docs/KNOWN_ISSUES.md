# KNOWN_ISSUES.md

Dedicated issue tracker. Distinct from `TODO.md`: this file is about defects and unverified areas; `TODO.md` is about planned work. An item can graduate from here to `TODO.md` once it's understood well enough to be actionable.

---

## Open

None. All four items originally logged here have been verified end-to-end — see the Resolved section below. This section is kept as a template for future verification gaps; an item belongs here only while it's genuinely unconfirmed, not indefinitely.

### 1. ~~Emoji entry not verified end-to-end~~ — RESOLVED, see Resolved section (R6)

### 2. ~~Custom `ColorPicker` (`UIColorWell`) open-gesture not verified end-to-end~~ — RESOLVED, see Resolved section (R6)

### 3. ~~Shield long-press context menu not verified end-to-end~~ — RESOLVED, see Resolved section (R4)

### 4. ~~Heatmap doesn't visually distinguish "shielded" from "below-target quantifiable" from "did nothing"~~ — RESOLVED, see Resolved section (R5)

---

## Resolved

### R1. `AccentColorPickerView`'s decorative overlay blocked taps to the native `ColorPicker`

- **Found and fixed:** 2026-07-29, during Quick Shields/Custom Color verification.
- **Root cause:** `.overlay(Circle().stroke(...))` and a checkmark/plus `Image` overlay sat on top of the `ColorPicker` in z-order; SwiftUI's default `.overlay()` hit-testing intercepts touches across its full bounds even for a stroke-only (mostly transparent) shape, unless explicitly opted out.
- **Fix:** `.allowsHitTesting(false)` added to each decorative overlay individually, so touches pass through to the `ColorPicker` beneath.
- **Files:** `Anchor/Components/AccentColorPickerView.swift`.

### R2. `xcodegen generate` silently wiped physical-device signing team

- **Found and fixed:** during physical-device deployment (window overlapping the Quantifiable Logging feature, `bd2fa6f`).
- **Root cause:** `project.yml` never declared a signing team; `xcodegen generate` regenerates the entire `.xcodeproj` on every run and doesn't preserve settings only made through Xcode's GUI.
- **Fix:** `CODE_SIGN_STYLE: Automatic` and `DEVELOPMENT_TEAM: X264QUS42N` added to `project.yml`'s `settings.base` permanently.
- **Files:** `project.yml`. Full detail: `DECISIONS.md` ADR-003.

### R3. Auto-seeded Prayer habit's reminder silently never scheduled

- **Found and fixed:** during the Onboarding feature (`8aa9ba3`).
- **Root cause:** `HabitService.seedStarterHabitsIfNeeded` (since deleted) called `HabitService.create()` directly, bypassing `AddEditHabitViewModel.save()` — the only code path that actually requests notification authorization and schedules.
- **Fix:** onboarding routes all first-run habit creation through the same explicit flow real user-created habits use.
- **Files:** `Anchor/Services/HabitService.swift`, `Anchor/ViewModels/OnboardingViewModel.swift`.

### R4. Shield long-press context menu — verified end-to-end, no bug found

- **Verified:** 2026-07-30, in a live simulator session (iPhone 16 Pro, iOS 18.5).
- **Result:** Long-pressing a Today habit card correctly reveals the "Shield Today" context menu item with a shield glyph; tapping it correctly shows a blue shield badge on the card, correctly shows the shielded day in blue in both the Today card and the Stats/Habit Insights heatmap, and correctly appears as a shielded day (with a working "Remove Shield" toggle) in `ManageShieldsView`'s calendar — confirming the Today quick-action and `ManageShieldsView` read/write the same state and stay in sync.
- **Files:** `Anchor/Components/HabitCardView.swift`, `Anchor/ViewModels/TodayViewModel.swift`, `Anchor/Views/ManageShieldsView.swift`.
- **Note:** the earlier non-response (previously logged as open issue #3) was traced to the *previous* session's tap coordinates, not app behavior — this session confirmed the tool's tap coordinate space is in points (402×874 on iPhone 16 Pro), not screenshot pixels; once corrected, taps and long-presses registered reliably throughout the app.

### R5. Heatmap didn't visually distinguish "below-target quantifiable" from "did nothing" — fixed

- **Found and fixed:** 2026-07-30.
- **Root cause:** `StreakService.dailyHistory` only ever reported `.partial` when some (but not all) occurrences of a multi-occurrence habit were completed. A single-occurrence quantifiable habit logged below its target had `completedCount == 0` (since `isCompleted` is threshold-aware), so it fell into the same branch as a day with nothing logged at all — both rendered `.missed`.
- **Fix:** `dailyHistory` now checks `CompletionService.value` when `completedCount == 0`; if any occurrence has a logged value greater than zero, it reports `.partial` instead of `.missed`. Reuses the existing `.partial` case and its existing heatmap color — no new `DayCompletionState` case or color was needed. See `DECISIONS.md` ADR-015 for why this was simpler than the alternatives originally anticipated in `TODO.md`.
- **Verified:** unit tests (`StreakServiceTests.dailyHistoryQuantifiablePartialToCompleted`, `dailyHistoryQuantifiableNothingLoggedIsMissed`) and visually in the simulator — logging 3 of 8 on a quantifiable habit renders today's heatmap cell in the same medium tint as a multi-occurrence partial day, distinctly different from an unlogged day's near-invisible tint.
- **Files:** `Anchor/Services/StreakService.swift`, `AnchorTests/StreakServiceTests.swift`.
- **Note:** a shielded quantifiable day was never actually part of this gap — `isShielded` is checked before the `completedCount == 0` branch, so it already correctly reported `.shielded` regardless of logged value. The original `TODO.md`/`KNOWN_ISSUES.md` wording bundled it in by association, not because it was broken.

### R6. Emoji entry and custom `ColorPicker` — verified end-to-end on a physical device, no bugs found

- **Verified:** 2026-07-30, on the developer's own physical iPhone (iOS 26.6, `iPhone17,1`), installed via `xcodebuild`/`xcrun devicectl` (free "Personal Team" signing, one-time manual developer-profile trust via Settings → General → VPN & Device Management).
- **Emoji entry result:** working as expected. `IconPickerView`'s Emoji mode field accepts a real emoji typed via the system emoji keyboard; the habit saves and the emoji renders correctly wherever the icon is drawn (Today, Habits, Stats). Confirms the simulator-only gap (`KNOWN_ISSUES.md`'s prior #1) was a tooling limitation (no on-screen software keyboard in that streamed environment), not an app defect.
- **Custom `ColorPicker` result:** working as expected. Tapping the 9th "Custom" swatch opens the native iOS color picker sheet; picking an exact color applies it as the habit's (or app-wide) accent, taking priority over the curated `AccentColor` as designed. Confirms the simulator-only gap (prior #2) was `UIColorWell` not responding to synthetic taps in that environment, not an app defect.
- **No crashes or unexpected behavior reported for either path.**
- **Files:** `Anchor/Components/IconPickerView.swift`, `Anchor/Components/AccentColorPickerView.swift`.

---

## Technical Debt

See `TODO.md`'s "Technical Debt" section — nothing currently significant. The one item worth remembering: `Frequency.supportsShields` had zero call sites for one full feature cycle between when it was added (Streak Shields, `5153c15`) and when it was actually wired up (Quick Shields, `82e82bb`). Not a bug, but a reminder to check whether something that looks unused was built ahead of a planned feature before assuming it's dead code.
