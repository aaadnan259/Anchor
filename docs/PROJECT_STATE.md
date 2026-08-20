# PROJECT_STATE.md — Current State Snapshot

**Last updated:** 2026-08-20.

A snapshot of where the project is *right now* — not a session journal. History belongs in `CHANGELOG.md`; rationale in `DECISIONS.md`. Re-verify anything here against the repo and `git log` before acting on it.

## Current Milestone

None in progress. v1 is feature-complete, and v1.1 (Calendar History) is shipped and user-verified. The last backlog item — "additional chart types" — shipped as the "By Day of Week" radial chart. No version work is queued; the next feature should come from a new user request, not be picked up unprompted.

## Current Version

`MARKETING_VERSION: 1.0` (`project.yml`). Pre-release: installed on physical devices via direct USB only, never submitted to TestFlight or the App Store. Free "Personal Team" signing — see `CLAUDE_CONTEXT.md` for what that rules out.

## Build & Test Status

Verified 2026-08-20 at `26bd240`:

- `xcodebuild build` — `** BUILD SUCCEEDED **`, zero compiler warnings.
- `xcodebuild test` — `** TEST SUCCEEDED **`, **54/54 tests passing**.

Still valid at the current HEAD: the two commits since are documentation-only, with zero diff to `Anchor/`, `AnchorTests/`, or `project.yml`. This is a snapshot, not live CI — re-run before trusting it.

## Repository State

- Branch `main`, clean working tree, in sync with `origin/main` (pushed 2026-08-20).
- HEAD: `ba4bd58` — the documentation context-architecture refactor.
- `main` is the only branch, local and remote. All spent PR branches have been deleted.

## Recently Verified

- **"By Day of Week" radial chart** — visually verified in the simulator (2026-08-20), light and dark. Habit creation via the UI was skipped (see `KNOWN_ISSUES.md` R8 — the "+" button's known unreliability in this environment); instead a temporary, launch-argument-gated seed path was added to `AnchorApp.init`, used to populate a 21-day, all-weekdays completion history via SwiftData directly, then fully reverted (`git checkout`) before the final build. Confirmed: a 0%-rate weekday's floored 8% sliver renders as a small but clearly visible full-opacity wedge — not broken, invisible, or overlapping — and contrast holds in both light and dark. No bugs found; no code change needed.
- **Calendar History and the Today-screen interaction/motion polish** — full-card tap-to-complete, swipe-to-delete, and the 100%-completion celebration — confirmed working end-to-end by the user on a real device (2026-07-31). No bugs found.
- **Emoji habit-icon entry and the custom `ColorPicker`** — confirmed working on a physical device (2026-07-30), closing out what had looked like two app bugs but were simulator-tooling limitations.

## Current Work

None in progress. The documentation architecture was refactored on 2026-08-20 for progressive context loading (`cb1a964`, `ba4bd58`) — committed, merged, and pushed. No application code was touched.

## Open Blockers

- **WidgetKit (v1.2)** is blocked on the user enrolling in a paid Apple Developer Program account, which Claude cannot do for them (payment information). TestFlight and App Store distribution share the same blocker. Also paused by the user — see ADR-017.

## Explicitly Deferred

- **Cross-habit correlation insights** — deferred pending real usage data, not engineering effort.
- **iCloud Sync (v1.3), Apple Watch (v1.4)** — version-gated roadmap; not to be implemented ahead of schedule.

Full list with reasoning: `CLAUDE_CONTEXT.md`'s "Deliberately Not Built."

## Important Current Constraints

- Free "Personal Team" signing limits distribution — see Current Version above, and `CLAUDE_CONTEXT.md` for the full list.
- This environment's simulator-automation tooling has known gaps with UIKit-bridged controls (no on-screen keyboard, `UIColorWell`, and at least one `ToolbarItem` button). A non-responding control there is not evidence of an app bug — see `TESTING.md`.

## Open Issues

`KNOWN_ISSUES.md` Open section: none. `TODO.md`: none — the last open item (visual verification of the "By Day of Week" radial chart) closed out 2026-08-20.

## Next Recommended Step

None queued. Wait for the next user request.
