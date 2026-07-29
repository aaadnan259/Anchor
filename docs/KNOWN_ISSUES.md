# KNOWN_ISSUES.md

Dedicated issue tracker. Distinct from `TODO.md`: this file is about defects and unverified areas; `TODO.md` is about planned work. An item can graduate from here to `TODO.md` once it's understood well enough to be actionable.

---

## Open

### 1. Emoji entry not verified end-to-end in a live simulator session

- **Description:** The emoji icon field (`IconPickerView`'s Emoji mode) was code-reviewed and its surrounding UI (segmented control, placeholder, footnote, paste-context-menu) was confirmed via screenshots, but actually typing/pasting a real emoji character and confirming it saves and renders correctly end-to-end was not completed.
- **Affected files:** `Anchor/Components/IconPickerView.swift`.
- **Severity:** Low — the underlying logic (`String.isSFSymbolCompatible`, the `onChange` validation) is unit-tested (`AnchorTests/StringIconTests.swift`) and reasoned through carefully; this is a verification gap, not a suspected defect.
- **Status:** Open, low priority (see `TODO.md`).
- **Possible cause:** Not a code issue — the simulator-automation `text` action only supports printable ASCII, and `xcrun simctl pbcopy` corrupts UTF-8 input when used from the host shell to seed the simulator's pasteboard for a paste-based workaround.
- **Possible solution:** Re-verify on a physical device (where a real keyboard is available), or in a simulator session driven by an actual human interacting with the keyboard.
- **Priority:** Low.

### 2. Custom `ColorPicker` (`UIColorWell`) open-gesture not verified end-to-end

- **Description:** Tapping the 9th "Custom" swatch is supposed to open the native system color picker sheet. This was attempted repeatedly (plain tap, `touch_path` drag, long-press) at confirmed-correct coordinates without the sheet visibly opening in screenshots.
- **Affected files:** `Anchor/Components/AccentColorPickerView.swift`.
- **Severity:** Low — a genuine hit-testing bug *was* found and fixed during this investigation (a decorative overlay was blocking taps from reaching the control at all — see `DECISIONS.md`/`CHANGELOG.md`), which is good evidence the investigation was productive. What remains unconfirmed is only the very last step: does tapping the (now correctly hit-testable) control actually present iOS's system color sheet.
- **Status:** Open, low priority.
- **Possible cause:** `ColorPicker`/`UIColorWell` is known to have quirks with programmatic/synthetic touch injection in iOS Simulator automation more broadly — not unique to this environment or this code.
- **Possible solution:** Re-verify on a physical device, or with a human at the keyboard in the simulator.
- **Priority:** Low.

### 3. Shield long-press context menu not verified end-to-end

- **Description:** Long-pressing a Today habit card is supposed to reveal a "Shield Today"/"Remove Shield" context menu. Attempted with several `touch_path` hold durations (600ms, 900ms) without the menu appearing in screenshots. Basic taps on the same screen (the plain completion-toggle circle) also stopped responding during the same window, suggesting a broader tooling/connection issue rather than something specific to the context menu.
- **Affected files:** `Anchor/Components/HabitCardView.swift`.
- **Severity:** Low — the wiring (`isShielded`/`supportsShields`/`onToggleShield` params, the `.contextMenu` modifier, the `TodayViewModel` pass-throughs) is straightforward, code-reviewed, and follows an already-working pattern (`ManageShieldsView`'s toggle, which calls the same `CompletionService.toggleShield`).
- **Status:** Open, low priority.
- **Possible cause:** Same simulator-tooling instability as #1/#2, compounded by a period where basic tap responsiveness degraded across the whole app, not just this control.
- **Possible solution:** Re-verify with a stable simulator session (re-attach, confirm basic taps work first) or on a physical device.
- **Priority:** Low.

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

---

## Technical Debt

See `TODO.md`'s "Technical Debt" section — nothing currently significant. The one item worth remembering: `Frequency.supportsShields` had zero call sites for one full feature cycle between when it was added (Streak Shields, `5153c15`) and when it was actually wired up (Quick Shields, `82e82bb`). Not a bug, but a reminder to check whether something that looks unused was built ahead of a planned feature before assuming it's dead code.
