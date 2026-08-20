# DEVELOPMENT_GUIDE.md — Build, Run, Test, Deploy

Operational procedures. Product behavior is in `PROJECT_SPEC.md`, structure in `ARCHITECTURE.md`, test strategy in `TESTING.md`.

---

## Project Setup

Anchor is a single app target (`Anchor`) plus a unit-test target (`AnchorTests`), both defined in `project.yml` and generated into `Anchor.xcodeproj` by [XcodeGen](https://github.com/yonaskolb/XcodeGen).

**`Anchor.xcodeproj` is gitignored and regenerated — never hand-edit or commit it.** To change a build setting, target, dependency, or `Info.plist` key, edit `project.yml` and regenerate. Setting it through Xcode's project-settings UI will *not* stick: `xcodegen generate` rewrites the whole project and silently wipes GUI-only changes (see ADR-003 for the incident this caused).

The one external dependency, [Adhan Swift](https://github.com/batoulapps/adhan-swift), is pulled via SPM from `project.yml`'s `packages:` section.

## Build

```bash
xcodegen generate    # only when project.yml changed — not needed for plain Swift edits
xcodebuild build -project Anchor.xcodeproj -scheme Anchor -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

Confirm zero warnings and `** BUILD SUCCEEDED **` before considering any change done.

## Test

```bash
xcodebuild test -project Anchor.xcodeproj -scheme Anchor -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

Look for `** TEST SUCCEEDED **` and `Test run with N tests passed`. Current suite size, coverage, and the boundary for what gets tested: `TESTING.md`.

> **Pipe-safety.** If you pipe `xcodebuild` through `| tail -N`, the shell's exit code reflects `tail`, not `xcodebuild` — a failed build reads as success. Either grep the output for the literal `** BUILD SUCCEEDED **` / `** TEST SUCCEEDED **`, or redirect to a file and check `$?` immediately after `xcodebuild` itself, never after a pipe.

## Run in the Simulator

Prefer the `mcp__Claude_Code_iOS_Simulator__control` tool where available — it can screenshot and drive the UI. Read `TESTING.md`'s tooling-quirks section first; several of its gaps look like app bugs and aren't. From the command line:

```bash
xcrun simctl boot <UDID>          # if not already booted
xcrun simctl install <UDID> <path-to>.app
xcrun simctl launch <UDID> com.adnan.Anchor
```

The built bundle lives under `~/Library/Developer/Xcode/DerivedData/Anchor-<hash>/Build/Products/Debug-iphonesimulator/Anchor.app`.

## Run on a Physical Device

```bash
xcrun xctrace list devices                                    # UDID for xcodebuild
xcodebuild build -destination 'id=<xctrace-UDID>' -allowProvisioningUpdates \
  -project Anchor.xcodeproj -scheme Anchor
xcrun devicectl list devices                                  # a DIFFERENT identifier, for devicectl
xcrun devicectl device install app --device <devicectl-id> <path-to>.app
xcrun devicectl device process launch --device <devicectl-id> com.adnan.Anchor
```

**Three gotchas, each of which produces a misleading error:**

1. **`xctrace` and `devicectl` report different identifier strings for the same device** (e.g. `00008140-…` vs. a UUID like `CBAAC27C-…`). Use the `xctrace` one for `xcodebuild -destination` and the `devicectl` one for both `devicectl` subcommands. Mixing them gives "Unable to find a device matching the provided destination specifier" even though the device is genuinely connected.
2. **`connected (no DDI)`** in `devicectl list devices` usually just means the "Trust This Computer?" prompt needs confirming on-device, or the device needs unlocking. Try the build/install anyway — it often succeeds.
3. **First launch on any device fails** with *"its profile has not been explicitly trusted by the user"* until a one-time manual trust: Settings → General → VPN & Device Management → tap the developer profile → Trust. This is separate from "Trust This Computer," can only be done on the device, and has no command-line workaround. Afterwards, tap the app icon or re-run `devicectl device process launch`.

**Signing limits.** Free "Personal Team" signing: builds expire after 7 days, and install is USB-only — no OTA, no TestFlight without a paid Apple Developer Program membership, which Claude cannot enroll the user in. See `CLAUDE_CONTEXT.md`'s Distribution Constraints.

## Where to Start Reading Code

- **`Anchor/Services/CompletionService.swift`** — the single choke point for "is this done." Read before touching anything about completion, streaks, or insights.
- **`Anchor/Services/StreakService.swift` + `AnchorTests/StreakServiceTests.swift`** — the most heavily tested logic in the app. Read the tests before changing the implementation.
- **`Anchor/Models/Habit.swift`** — the central model; almost every feature has touched it.
- **`Anchor/App/AnchorApp.swift`** — the 4-way root branch and `ModelContainer` setup.
- **`project.yml`** — the source of truth for the Xcode project.

## Common Pitfalls

- **Editing `Anchor.xcodeproj` directly** — regenerated and gitignored; the edit is silently lost.
- **Forgetting `xcodegen generate` after a `project.yml` change**, then wondering why the build doesn't reflect it.
- **Re-implementing a completion check** instead of calling `CompletionService.isCompleted`/`isFullyCompleted`. The single most important rule to internalize (ADR-002).
- **Adding a required, no-default parameter** to an existing `Habit`/`Completion` initializer or `HabitService` method — every call site including test fixtures breaks. Add new fields as optional with a safe default.
- **Grepping only the obvious call sites** before changing a shared type's shape. `AccentColor` had 13+ non-obvious decorative ones (ADR-012).
- **Assuming a `Toggle`/`ColorPicker` responds to a plain simulated tap** — see `TESTING.md`.
- **Trusting `xcodebuild … | tail -N`'s exit code** — see the pipe-safety note above.

## Working Assumptions

- Local-first: no backend, no accounts, no iCloud. Don't add networking code expecting a server.
- SwiftData is the only persistence layer for habit data; UserDefaults via `SettingsService` is the only one for app-wide preferences. Don't mix.
- Light and dark mode, Dynamic Type, VoiceOver, and Reduce Motion are part of the Definition of Done for every feature — not optional polish.
- The curated `AccentColor` palette and SF Symbol grid are the *defaults*. Both have an escape hatch (custom color, emoji) that must never require changing the defaults themselves.

## Adding a Feature

The full workflow is in `../CLAUDE.md`. The project-specific parts:

1. Confirm the feature is in scope (`PROJECT_SPEC.md`) — v1 is feature-complete; anything not already scoped belongs in `TODO.md`, not implemented ahead of schedule.
2. Research the actual current code. Don't rely on memory, and don't trust `ARCHITECTURE.md` alone — grep and read the real files.
3. If there's a genuine design fork, or a conflict with a `DECISIONS.md` entry, surface it to the user rather than guessing.
4. Implement Services → ViewModels (thin pass-throughs) → Views (rendering only).
5. Add tests only where they fit the boundary in `TESTING.md`.
6. Build, test, verify in the simulator (light + dark).
7. Update documentation per `../CLAUDE.md`'s Documentation Update Policy.
8. Commit and push only when explicitly asked.
