# KNOWN_ISSUES.md

Dedicated issue tracker. Distinct from `TODO.md`: this file is about defects and unverified areas; `TODO.md` is about planned work. An item can graduate from here to `TODO.md` once it's understood well enough to be actionable.

---

## Open

### 1. Emoji entry not verified end-to-end in a live simulator session

- **Description:** The emoji icon field (`IconPickerView`'s Emoji mode) was code-reviewed and its surrounding UI (segmented control, placeholder, footnote, paste-context-menu) was confirmed via screenshots, but actually typing/pasting a real emoji character and confirming it saves and renders correctly end-to-end was not completed.
- **Affected files:** `Anchor/Components/IconPickerView.swift`.
- **Severity:** Low — the underlying logic (`String.isSFSymbolCompatible`, the `onChange` validation) is unit-tested (`AnchorTests/StringIconTests.swift`) and reasoned through carefully; this is a verification gap, not a suspected defect.
- **Status:** Open, low priority (see `TODO.md`).
- **Possible cause:** Not a code issue. Re-attempted 2026-07-30 in a fresh session with correct point-space coordinates (ruling out the earlier session's coordinate-scaling risk): the Emoji segmented control and text field both work correctly (field focuses, cursor appears), but no on-screen software keyboard ever renders in this tool's simulator stream to switch to the emoji keyboard from — this looks like a headless/streamed simulator that doesn't surface a software keyboard at all, not merely a UTF-8/pasteboard issue. The `text` action confirmed it only accepts printable ASCII (an emoji was silently dropped). `xcrun simctl pbcopy` corrupting UTF-8 remains true but is now a secondary concern next to the missing on-screen keyboard.
- **Possible solution:** Re-verify on a physical device (where a real keyboard is available), or in a simulator session driven by an actual human interacting with the keyboard, or with a tool that can render/drive the on-screen software keyboard.
- **Priority:** Low.

### 2. Custom `ColorPicker` (`UIColorWell`) open-gesture not verified end-to-end

- **Description:** Tapping the 9th "Custom" swatch is supposed to open the native system color picker sheet. This was attempted repeatedly (plain tap, `touch_path` drag, long-press) at confirmed-correct coordinates without the sheet visibly opening in screenshots.
- **Affected files:** `Anchor/Components/AccentColorPickerView.swift`.
- **Severity:** Low — a genuine hit-testing bug *was* found and fixed during this investigation (a decorative overlay was blocking taps from reaching the control at all — see `DECISIONS.md`/`CHANGELOG.md`), which is good evidence the investigation was productive. What remains unconfirmed is only the very last step: does tapping the (now correctly hit-testable) control actually present iOS's system color sheet.
- **Status:** Open, low priority.
- **Possible cause:** `ColorPicker`/`UIColorWell` is known to have quirks with programmatic/synthetic touch injection in iOS Simulator automation more broadly — not unique to this environment or this code. Re-attempted 2026-07-30 in a fresh session: confirmed the tap lands on the correct swatch (a regular curated swatch at the same row/coordinates *does* visibly select, moving the checkmark), isolating the gap specifically to `UIColorWell` not responding to synthetic taps/`touch_path`, not a coordinate-targeting mistake.
- **Possible solution:** Re-verify on a physical device, or with a human at the keyboard in the simulator.
- **Priority:** Low.

### 3. ~~Shield long-press context menu not verified end-to-end~~ — RESOLVED, see Resolved section (R4)

### 4. Heatmap doesn't visually distinguish "shielded" from "below-target quantifiable" from "did nothing"

- **Description:** `StreakService.dailyHistory`'s `.partial` state only fires for multi-occurrence "some but not all done" habits. A single-occurrence quantifiable habit logged below target renders as `.missed`, identical to a day with nothing logged at all. This was a deliberate, documented scope decision when quantifiable logging shipped, not an oversight — see `DECISIONS.md` ADR-010.
- **Affected files:** `Anchor/Services/StreakService.swift`, `Anchor/Components/HabitHistoryGridView.swift`.
- **Severity:** Cosmetic. Streak/completion correctness is unaffected — this is purely a display-richness gap.
- **Status:** Open, tracked as a Low-priority `TODO.md` item, not a bug to fix reflexively.
- **Priority:** Low.

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

---

## Technical Debt

See `TODO.md`'s "Technical Debt" section — nothing currently significant. The one item worth remembering: `Frequency.supportsShields` had zero call sites for one full feature cycle between when it was added (Streak Shields, `5153c15`) and when it was actually wired up (Quick Shields, `82e82bb`). Not a bug, but a reminder to check whether something that looks unused was built ahead of a planned feature before assuming it's dead code.
