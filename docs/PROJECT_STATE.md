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

This is a snapshot, not live CI. Re-run before trusting it.

## Repository State

- Branch `main`, in sync with `origin/main`. Working tree clean apart from the in-flight documentation refactor.
- HEAD: `26bd240` — "Add 'By Day of Week' radial chart to Habit Insights."
- Several merged PR branches (`docs/*`, `feature/*`) still exist locally and on the remote; they're spent and safe to delete.

## Recently Verified

- **Calendar History and the Today-screen interaction/motion polish** — full-card tap-to-complete, swipe-to-delete, and the 100%-completion celebration — confirmed working end-to-end by the user on a real device (2026-07-31). No bugs found.
- **Emoji habit-icon entry and the custom `ColorPicker`** — confirmed working on a physical device (2026-07-30), closing out what had looked like two app bugs but were simulator-tooling limitations.

## Current Work

None in progress. The documentation architecture was refactored on 2026-08-20 for progressive context loading; no application code was touched.

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

`KNOWN_ISSUES.md` Open section: none. `TODO.md`: one open Medium item — visual verification of the "By Day of Week" radial chart, which has full data-side unit coverage but hasn't been seen rendered yet.

## Next Recommended Step

Visually verify the "By Day of Week" radial chart in Habit Insights (between Time of Day and History), light and dark mode — checking that a 0%-rate weekday's floored 8% sliver reads sensibly. Then wait for the next user request.
