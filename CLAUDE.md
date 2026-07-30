# CLAUDE.md

# Anchor Engineering Constitution

> This document defines how the project should be engineered.
> Product behavior belongs in `docs/PROJECT_SPEC.md`.
> Timeless — this file should rarely change. Session-specific status lives in `docs/PROJECT_STATE.md`.

**Before starting any work, read `docs/CLAUDE_CONTEXT.md` and `docs/PROJECT_STATE.md`.** They contain the full project history, architecture rationale, and exactly where the last session left off. This file only tells you the rules; those two tell you the situation.

## Mission

Build Anchor as a production-quality native iOS application that feels like it was designed by Apple.

Priorities:
1. Simplicity
2. Maintainability
3. Performance
4. Native UX
5. Long-term scalability

Never sacrifice code quality for speed.

## Engineering Philosophy

- Prefer Apple's recommended approach.
- Prefer the simplest implementation.
- Prefer readability over cleverness.
- Avoid premature optimization.
- Avoid unnecessary abstraction.

## Scope Discipline

Do not add features outside the specification.
Future ideas belong in `docs/TODO.md`.

## Native First

Prefer:
- SwiftUI
- SwiftData
- Foundation
- CoreLocation
- UserNotifications
- SF Symbols
- Haptics

Minimize third-party dependencies.

## Architecture

- MVVM
- Dependency Injection
- Business logic in Services
- Views render state only
- Avoid global mutable state
- Prefer composition over inheritance

## State Management

Preferred ownership:
- @State
- @Binding
- @Bindable
- @Environment
- @Query

Avoid ObservableObject unless necessary.

## Data Principles

- Store source-of-truth only.
- Avoid duplicate data.
- Compute derived values.
- Explicit relationships.

## UI Philosophy

- Native-first design.
- Reusable components.
- Whitespace over clutter.
- Meaningful animations.
- Continuous corner radius.
- Semantic colors.
- Dynamic Type.
- Light & Dark Mode.

## Accessibility

Every interactive control should support:
- VoiceOver
- Dynamic Type
- 44pt touch targets
- Reduce Motion
- High Contrast

## Performance

- Avoid expensive work in View.body
- Lazy containers when appropriate
- Measure before optimizing
- Minimize unnecessary refreshes

## Code Style

- Swift API Design Guidelines
- Early returns
- Small focused functions
- No force unwraps or force casts
- No dead code
- No duplicated business logic
- Comment why, not what

## Folder Structure

Allowed top-level folders:

App/
Models/
Views/
Components/
Services/
Theme/
Utilities/
Extensions/
Assets/
Resources/
Preview Content/
Tests/

## Naming

- Views: *View
- Services: *Service
- Managers: *Manager
- Models: singular nouns
- Enums: singular nouns
- Protocols: capability names

## Workflow

After every milestone:
1. Build
2. Fix warnings
3. Run
4. Verify
5. Continue

Never leave the project broken.

## Definition of Done

- Builds cleanly
- No warnings
- No runtime errors
- Accessible
- Light/Dark mode verified
- No duplicated logic
- Matches PROJECT_SPEC.md

## Documentation Map

- `CLAUDE.md` (this file) — timeless engineering rules. Rarely changes.
- `docs/PROJECT_SPEC.md` — product behavior: what each screen does, what's in v1, what's explicitly out of scope.
- `docs/ARCHITECTURE.md` — how the app is built: layers, dependency graph, data model, services.
- `docs/CLAUDE_CONTEXT.md` — the full project knowledge base: history, features, design decisions, lessons learned. Read this first in a new session.
- `docs/PROJECT_STATE.md` — exactly where the last session stopped. Updated every session; the other docs are not.
- `docs/DECISIONS.md` — architectural decision record, one entry per non-obvious choice.
- `docs/TODO.md` — prioritized backlog.
- `docs/CHANGELOG.md` — what shipped, grouped by milestone.
- `docs/KNOWN_ISSUES.md` — open bugs and unverified areas.
- `docs/TESTING.md` — what gets automated tests vs. manual simulator verification, and why.
- `docs/DEVELOPMENT_GUIDE.md` — how to build, run, test, and add a feature.

Keep these in sync as you work. A decision made but not written to `docs/DECISIONS.md` and a stopping point not written to `docs/PROJECT_STATE.md` are both lost the moment the session ends.

## Never Change Without Explicit Approval

- **The 8 existing `AccentColor` enum cases or their raw values** (`Anchor/Theme/AccentColor.swift`). They're persisted via `rawValue` in both SwiftData (`Habit.accentColor`) and `UserDefaults` (`SettingsService.accentColor`). Renaming, reordering, or removing a case corrupts existing installs' saved colors. Add new capability alongside them (see `customColorHex`), never inside them.
- **`CODE_SIGN_STYLE: Automatic` / `DEVELOPMENT_TEAM: X264QUS42N` in `project.yml`'s `settings.base`.** Without these, `xcodegen generate` silently wipes any signing team set through Xcode's GUI, and physical-device builds fail with a confusing "No Account for Team" error.
- **`CompletionService.isCompleted` / `isFullyCompleted` as the single choke point for "is this done."** `StreakService`, `InsightsService`, `NotificationService`'s smart-reminder gate, and the heatmap all call through these two methods rather than re-implementing their own completion check. A new feature that needs completion state must call these, never duplicate the logic.
- **`HabitService.update(...)`'s non-optional `targetValue`/`unit`/`customColorHex` parameters.** They deliberately have no default value, unlike `create(...)`'s. This is intentional — it forces every call site to explicitly decide what happens to a habit's quantifiable/custom-color config on edit, rather than silently erasing it via a forgotten parameter.
- **Adding a third-party dependency.** `Adhan` is the only approved one (no Apple API exists for prayer-time calculation). Anything else needs explicit sign-off first.
- **Removing or renaming a SwiftData model field that has already shipped** (i.e., is in a commit on `main`). The app has been installed on real devices; schema changes must be additive (new optional fields with safe defaults), never destructive.

## Always Verify Before Modifying Code

- **Read the current file before editing it**, even if you just wrote it earlier in the conversation. Don't rely on memory of what a file "should" contain — the harness enforces this for `Edit`, but the same discipline applies to reasoning about any file you haven't just read.
- **Before changing a shared enum or model's shape, grep every call site first.** `AccentColor` alone had 13+ call sites hardcoding specific cases as decorative tints, well outside the obvious "per-habit color" usages — missing them would have been a silent visual regression, not a compile error.
- **Before adding a new field to `Habit` or `Completion`, confirm it's optional or has a safe default**, and that every fixture in `AnchorTests/` still compiles unchanged. Existing habits on real devices must load correctly with the new field absent.
- **Before touching `Frequency`, `DueDateRule`, or `StreakService`, read `StreakServiceTests.swift` first.** It's the most heavily tested file in the project (21 cases) and encodes a lot of previously-debugged subtlety: today-in-progress leniency, shield priority over partial completion, quantifiable-threshold breaking vs. non-breaking depending on whether the shortfall is "today" or a past due day.
- **After any `project.yml` change, run `xcodegen generate` before building.** After any Swift change, run `xcodebuild build` (zero warnings) and `xcodebuild test` before considering a task done — see `docs/DEVELOPMENT_GUIDE.md` for exact commands.

## Guiding Principle

Anchor should always feel:

- Simple
- Fast
- Native
- Reliable
