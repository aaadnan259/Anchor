# DEVELOPMENT_GUIDE.md

Onboarding documentation — how the project works day to day, for any future Claude session or human contributor.

---

## How The Project Works

Anchor is a single-target iOS app (`Anchor`) plus a unit-test target (`AnchorTests`), both defined in `project.yml` and generated into `Anchor.xcodeproj` by [XcodeGen](https://github.com/yonaskolb/XcodeGen). **`Anchor.xcodeproj` is gitignored and regenerated, never hand-edited or committed.** If you need to change a build setting, a target, a dependency, or an `Info.plist` key, edit `project.yml` and regenerate — don't open Xcode's project settings UI and expect it to stick (see `DECISIONS.md` ADR-003 for what happens if you do).

The one external dependency is [Adhan Swift](https://github.com/batoulapps/adhan-swift) (prayer-time calculation), pulled via Swift Package Manager, declared in `project.yml`'s `packages:` section.

## How To Build

```bash
cd /path/to/Anchor
xcodegen generate
xcodebuild build -project Anchor.xcodeproj -scheme Anchor -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

Only run `xcodegen generate` when `project.yml` has changed — it's not needed for plain Swift source edits. Confirm zero warnings and `** BUILD SUCCEEDED **` before considering any change done (see `CLAUDE.md`'s Definition of Done).

## How To Run

Prefer the `mcp__Claude_Code_iOS_Simulator__control` tool over raw `xcrun simctl`/Bash where available — it can screenshot and drive the UI directly. If using the command line:

```bash
xcrun simctl boot <UDID>                                    # if not already booted
xcrun simctl install <UDID> <path-to>.app
xcrun simctl launch <UDID> com.adnan.Anchor
```

The `.app` bundle after a build lives under `~/Library/Developer/Xcode/DerivedData/Anchor-<hash>/Build/Products/Debug-iphonesimulator/Anchor.app`.

**For a physical device** (see `CLAUDE_CONTEXT.md`'s Distribution constraints for what this can and can't do):

```bash
xcrun xctrace list devices                                                    # find the UDID for xcodebuild
xcodebuild build -destination 'id=<xctrace-UDID>' -allowProvisioningUpdates \
  -project Anchor.xcodeproj -scheme Anchor
xcrun devicectl list devices                                                  # find the (different!) identifier for devicectl
xcrun devicectl device install app --device <devicectl-identifier> <path-to>.app
xcrun devicectl device process launch --device <devicectl-identifier> com.adnan.Anchor
```

**Important:** `xcrun xctrace list devices` and `xcrun devicectl list devices` report *different identifier strings for the same physical device* (e.g. `00008140-...` vs. a UUID like `CBAAC27C-...`). Use the `xctrace` one for `xcodebuild -destination`, the `devicectl` one for both `devicectl` subcommands — passing the wrong one gives a confusing "Unable to find a device matching the provided destination specifier" error even though the device is genuinely connected.

If `devicectl list devices` shows a device as `connected (no DDI)` rather than `connected`, it usually just needs the "Trust This Computer?" prompt confirmed on the device itself (or the device unlocked) — try the build/install anyway, it can still succeed.

First **launch** on any device fails with `"...its profile has not been explicitly trusted by the user"` until a one-time manual trust: Settings → General → VPN & Device Management → tap the developer profile → Trust. This is a separate trust step from "Trust This Computer" above and can only be done on the device itself — no command-line workaround. After trusting, either tap the app icon on the device or re-run `devicectl device process launch`. Free "Personal Team" signing expires after 7 days and only supports direct USB install — no OTA distribution, no TestFlight without a paid Apple Developer Program membership (which Claude cannot enroll the user in — see `CLAUDE_CONTEXT.md`).

## How To Test

```bash
xcodebuild test -project Anchor.xcodeproj -scheme Anchor -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

Look for `Test run with N tests passed` at the end. As of the last update to this file, N = 47. See `TESTING.md` for what's covered and what isn't, and why.

**Pipe-safety note:** if you pipe `xcodebuild`'s output through `| tail -N`, the shell's exit code reflects `tail`, not `xcodebuild` — it will read as success even if the build failed. Either check for the literal `** BUILD SUCCEEDED **`/`** TEST SUCCEEDED **` string in the output, or redirect to a file and check `$?` immediately after the `xcodebuild` command itself, not after a pipe.

## Where Important Code Lives

See `CLAUDE_CONTEXT.md`'s Repository Structure section for the full file-by-file map. The highest-leverage files to understand first:

- `Anchor/Services/CompletionService.swift` — the single choke point for "is this done." Read this before touching anything related to completion, streaks, or insights.
- `Anchor/Services/StreakService.swift` + `AnchorTests/StreakServiceTests.swift` — the most heavily tested logic in the app; read the tests before changing the implementation.
- `Anchor/Models/Habit.swift` — the central model; almost every feature has touched it.
- `Anchor/App/AnchorApp.swift` — the root branch (test / onboarding / lock / main) and `ModelContainer` setup.
- `project.yml` — the source of truth for the Xcode project.

## Development Workflow

Matches `CLAUDE.md`'s "Workflow" section. After every milestone:

1. Build (zero warnings).
2. Run.
3. Verify in the simulator (light and dark mode).
4. Update `PROJECT_SPEC.md` if product behavior changed.
5. Update `PROJECT_STATE.md` and, if the change was architecturally significant, `DECISIONS.md` and `CHANGELOG.md`.
6. Commit (only when explicitly asked) and push (only when explicitly asked).

For substantial features (touching 3+ files, involving a real design choice), use plan mode: research the actual current code first (don't assume), surface any design forks to the user rather than guessing, get the plan approved, then implement with task tracking.

## Important Assumptions

- The app is local-first with no backend, no accounts, no iCloud — don't add networking code expecting a server to exist.
- SwiftData is the only persistence layer for habit data; UserDefaults (via `SettingsService`) is the only persistence layer for app-wide preferences. Don't mix the two.
- Every screen must work in both light and dark mode and support Dynamic Type, VoiceOver, and Reduce Motion — this isn't optional polish, it's part of the Definition of Done for every feature.
- The curated `AccentColor` palette and the SF Symbol icon grid are the *defaults*; both now have an escape hatch (custom color, emoji) that must never require changing the defaults themselves.

## Common Pitfalls

- **Editing `Anchor.xcodeproj` directly.** It's regenerated from `project.yml` and gitignored — any direct edit will be silently lost.
- **Forgetting `xcodegen generate` after a `project.yml` change**, then wondering why the build doesn't reflect it.
- **Re-implementing a completion check instead of calling `CompletionService.isCompleted`/`isFullyCompleted`.** This is the one architectural rule most worth internalizing — see `DECISIONS.md` ADR-002.
- **Adding a required (non-optional, no-default) parameter to an existing `Habit`/`Completion` initializer or `HabitService` method.** Every existing call site (including test fixtures) breaks. Add new fields as optional with a safe default instead.
- **Assuming a `Toggle`/`ColorPicker` will respond to a plain simulated tap.** It might need a `touch_path` drag gesture instead — see `TESTING.md`'s tooling-quirks section.
- **Trusting `xcodebuild ... | tail -N`'s exit code.** See the pipe-safety note above.
- **Grepping only the "obvious" call sites before changing a shared enum's shape.** `AccentColor` had 13+ non-obvious decorative call sites — see `DECISIONS.md` ADR-012 and `CLAUDE.md`'s "Always Verify" section.

## How New Features Should Be Implemented

1. Read `PROJECT_SPEC.md` to confirm the feature is actually in scope for the current version (v1 is feature-complete; anything not already in the v1 scope belongs in `TODO.md`'s Future Ideas, not implemented ahead of schedule).
2. Research the actual current code — don't rely on memory of what a file contains, and don't assume based on `ARCHITECTURE.md` alone (it can go stale; grep and read the real files).
3. If there's a genuine design fork (multiple reasonable approaches, or a conflict with an existing decision in `DECISIONS.md`), surface it to the user rather than guessing.
4. Implement in Services first (business logic), then ViewModels (thin pass-throughs), then Views (rendering only) — matching the MVVM direction.
5. Add tests only where they fit the established boundary (`TESTING.md`) — non-trivial derived computation, not thin glue or pure UI.
6. Build, test, verify in the simulator (light + dark), update `PROJECT_SPEC.md` if product behavior changed.
7. Add a `DECISIONS.md` entry if a real choice was made between alternatives.
8. Update `PROJECT_STATE.md` and `CHANGELOG.md`.
