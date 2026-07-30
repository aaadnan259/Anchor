# PROJECT_STATE.md

Lightweight, session-to-session snapshot. This is the file most likely to be stale — trust it less than `git log`/`git status` for anything it claims about code, and re-verify before acting on it. Update this file at the end of every work session.

Last updated: 2026-07-30, end of the "documentation audit and cleanup" session.

**2026-07-30 session:** Audited all `docs/` files against the actual codebase (models, services, tests, git history) rather than trusting them. Found and fixed: a "40+ cases" test-count error for `StreakServiceTests.swift` repeated in `CLAUDE.md`/`CLAUDE_CONTEXT.md`/`TESTING.md` (actual: 20 cases, 46 total suite-wide — that part was correct); off-by-one file counts for `Models/` (10→11) and `Services/` (15→16) in `CLAUDE_CONTEXT.md`; `Completion`/`Occurrence` field docs in `ARCHITECTURE.md`/`PROJECT_SPEC.md` describing `habitID`/`occurrenceID` as raw fields when they're actually SwiftData relationships; a missing `HabitService.duplicate`/`updateOccurrence` mention in `ARCHITECTURE.md`; and a self-contradiction in `PROJECT_SPEC.md` where "Explicitly Out of Scope" still listed Export/Import and charts-beyond-simple-progress after both shipped. No application code was touched — see the full audit findings earlier in this conversation for detail. No further doc issues found.

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
