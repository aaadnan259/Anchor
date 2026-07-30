# PROJECT_STATE.md

Lightweight, session-to-session snapshot. This is the file most likely to be stale — trust it less than `git log`/`git status` for anything it claims about code, and re-verify before acting on it. Update this file at the end of every work session.

Last updated: 2026-07-30, end of the "documentation audit + simulator verification + TODO backlog cleanup" session.

**2026-07-30 session, part 4 — heatmap richness for below-target quantifiable days:** Closed the last open `TODO.md` item that didn't need a physical device. `StreakService.dailyHistory` (`Anchor/Services/StreakService.swift`) now reports `.partial` instead of `.missed` for a quantifiable habit logged below target on a due, unshielded day, reusing the existing `.partial` state/color rather than adding a new `DayCompletionState` case (see `DECISIONS.md` ADR-015 for the reasoning). Also clarified that the "shielded quantifiable day" half of the original gap wording was never actually broken — shield takes priority before the below-target check either way. Updated `StreakServiceTests.swift` (one existing test's expectation changed from `.missed` to `.partial`, one new test added for the zero-logged case). Verified: `xcodebuild build` zero warnings, `xcodebuild test` 47/47 passing, and visually confirmed in the simulator (logging 3 of 8 renders a distinct medium tint vs. an unlogged day's near-invisible tint). `TODO.md`'s Low-priority backlog is now empty except the Medium item blocked on a physical device (emoji entry, custom ColorPicker — see `KNOWN_ISSUES.md` #1/#2).

**2026-07-30 session, part 3 — unit label length cap:** Picked up the last actionable `TODO.md` Low-priority item that didn't need a physical device: `AddEditHabitViewModel.unitLabel` now clamps to 24 characters via a `didSet` (`Anchor/ViewModels/AddEditHabitViewModel.swift`). Emoji-blocking (also mentioned in the original TODO wording) was deliberately not implemented — it would reject legitimate non-ASCII text for no real benefit; length was the actual concern. Verified: `xcodebuild build` zero warnings, `xcodebuild test` 46/46 passing. Remaining `TODO.md` Low item ("Heatmap display richness for shielded + below-target quantifiable days") is a real feature-sized change (new `DayCompletionState` case, new heatmap color, new `StreakServiceTests` cases) rather than a trivial fix — left open for a future session or explicit user direction rather than done opportunistically.

**2026-07-30 session, part 1 — documentation audit:** Audited all `docs/` files against the actual codebase (models, services, tests, git history) rather than trusting them. Found and fixed: a "40+ cases" test-count error for `StreakServiceTests.swift` repeated in `CLAUDE.md`/`CLAUDE_CONTEXT.md`/`TESTING.md` (actual: 20 cases, 46 total suite-wide — that part was correct); off-by-one file counts for `Models/` (10→11) and `Services/` (15→16) in `CLAUDE_CONTEXT.md`; `Completion`/`Occurrence` field docs in `ARCHITECTURE.md`/`PROJECT_SPEC.md` describing `habitID`/`occurrenceID` as raw fields when they're actually SwiftData relationships; a missing `HabitService.duplicate`/`updateOccurrence` mention in `ARCHITECTURE.md`; and a self-contradiction in `PROJECT_SPEC.md` where "Explicitly Out of Scope" still listed Export/Import and charts-beyond-simple-progress after both shipped. No application code was touched. PR merged to `main`.

**2026-07-30 session, part 2 — simulator verification of the `TODO.md` Medium items:** Built and ran the app in the iOS Simulator (iPhone 16 Pro, iOS 18.5) to attempt the interaction paths left unverified by the previous session. Result:
- **Shield long-press quick-action: now verified working, no bug.** Long-press on a Today card → "Shield Today" context menu → shield badge appears → same shielded day correctly shows in the Stats/Habit Insights heatmap and in `ManageShieldsView`'s calendar. This also confirms the two entry points stay in sync (the other open Medium item). See `KNOWN_ISSUES.md` R4.
- **Emoji entry and custom `ColorPicker`: still unverifiable in this tooling, now with a more precise cause.** The Emoji segmented control and text field both work (focuses correctly), but no on-screen software keyboard ever renders in this environment to switch to the emoji keyboard from (not just a pbcopy/UTF-8 problem as previously suspected). For the color picker, confirmed taps land correctly (a regular curated swatch at the same coordinates *does* select correctly) — the gap is isolated specifically to `UIColorWell` not responding to synthetic taps. Neither looks like an app bug; both need a physical device or a human at the keyboard to close out. See `KNOWN_ISSUES.md` #1/#2.
- **Root cause of last session's total tap unresponsiveness, identified:** the simulator control tool's tap/swipe coordinate space is in **points** (402×874 on iPhone 16 Pro), not screenshot pixels. Using pixel-eyeballed coordinates directly (as both this session initially and, per the KNOWN_ISSUES/TESTING notes, likely the previous session did) causes taps to land out of bounds or on the wrong element. Once corrected, taps, swipes, and long-presses were reliable throughout — the "basic taps stopped registering app-wide" symptom described in `TESTING.md`'s tooling-quirks section may be explained by this rather than a genuine connection issue. Left `TESTING.md`'s existing note as-is (not proven to be the *sole* cause) but worth remembering for the next session.
- No application code was touched; a test habit ("Water") was created to drive the verification and deleted afterward, leaving the app in its original empty state. No commits made this part of the session.

---

**Current branch:** `main` (only branch in use; no feature-branch workflow on this project).

**Current milestone:** None in progress. The full v1 feature set (`PROJECT_SPEC.md`) shipped as of commit `82e82bb`. This session's only work is generating the `docs/` knowledge base.

**Current objective:** Documentation generation — creating/updating `CLAUDE.md`, `ARCHITECTURE.md`, `PROJECT_SPEC.md` (moved), and the new `CLAUDE_CONTEXT.md`, `PROJECT_STATE.md`, `DECISIONS.md`, `TODO.md`, `CHANGELOG.md`, `KNOWN_ISSUES.md`, `TESTING.md`, `DEVELOPMENT_GUIDE.md`, and root `README.md`.

**Current task:** Writing the remaining `docs/` files, then a self-review pass, then commit and push.

**Current files being edited:** All of the above; no application (`Anchor/`, `AnchorTests/`) code is touched this session.

**Recently modified (previous session, committed at `82e82bb`):**
- `Anchor/Components/HabitIconView.swift` (new), `Anchor/Extensions/String+Icon.swift` (new) — emoji icon rendering
- `Anchor/Components/AccentColorPickerView.swift`, `Anchor/Extensions/Color+Hex.swift`, `Anchor/Models/Habit.swift`, `Anchor/Services/SettingsService.swift` — custom accent color
- `Anchor/Components/HabitCardView.swift`, `Anchor/ViewModels/TodayViewModel.swift`, `Anchor/Views/TodayView.swift` — quick shields
- Six render call sites swapped to `HabitIconView`; every dynamic `.accentColor.color` swapped to `.tintColor`/`.effectiveAccentColor`
- `AnchorTests/StringIconTests.swift`, `AnchorTests/ColorHexTests.swift` (new)

**Current bugs:** None known in application code. See `KNOWN_ISSUES.md` for interaction paths that couldn't be verified end-to-end due to simulator-automation tooling limitations (not known defects).

**Next coding steps:** None queued. Next actual feature work should pull from `TODO.md`.

**Next testing steps:** None queued for application code. If picking up `TODO.md`'s "Verify emoji entry / ColorPicker / shield long-press end-to-end" item, that would need either a more stable simulator session or a physical device.

**Build status:** Last known good. `xcodebuild build` — zero warnings, `** BUILD SUCCEEDED **`. `xcodebuild test` — 46/46 tests passed. Both verified directly via `xcodebuild` (not through the simulator-automation tool, which was unreliable this session) immediately before the `82e82bb` commit.

**Simulator status:** Unreliable as of the end of the last session — basic taps intermittently stopped registering across the whole app, `ColorPicker`/ `Toggle` needed workaround gestures, `simctl pbcopy` corrupts UTF-8. Re-attach and re-verify device boot state before trusting any simulator interaction in a fresh session; don't assume the instability persists, but don't assume it's resolved either.

**Known blockers:** None for further development. TestFlight/App Store distribution is blocked on the user enrolling in the paid Apple Developer Program themselves (Claude cannot do this — see `CLAUDE_CONTEXT.md`'s Distribution constraints section).

**Outstanding TODOs:** See `TODO.md`. Nothing critical or high-priority open; the interesting remaining items are the deferred backlog (cross-habit correlation insights) and version-gated roadmap (Calendar history v1.1, Widgets v1.2, iCloud Sync v1.3, Apple Watch v1.4).

**Immediate next action:** Finish writing the remaining `docs/` files (`DECISIONS.md`, `TODO.md`, `CHANGELOG.md`, `KNOWN_ISSUES.md`, `TESTING.md`, `DEVELOPMENT_GUIDE.md`, root `README.md`), do a self-review pass for duplication/inconsistency, then commit and push as a single documentation commit.
