# CLAUDE.md — Anchor Engineering Constitution

Timeless engineering rules and the documentation-loading protocol. This file rarely changes.

## Project Identity

A focused, native iOS habit tracker — deliberately *not* a task manager, planner, or productivity suite. One job: help the user complete today's habits with minimal friction. Prayer-time-aware scheduling is a first-class differentiator, not a niche add-on.

Swift 6 (strict concurrency) · SwiftUI · SwiftData · iOS 17+ · MVVM + DI · XcodeGen. Local-first: no accounts, no backend, no iCloud, no analytics. One approved dependency: Adhan Swift (Apple has no prayer-time API).

Priorities in order: simplicity, maintainability, performance, native UX, scalability. Never trade code quality for speed.

## Startup Protocol

**Read only these two by default:**
1. This file.
2. `docs/PROJECT_STATE.md` — where the project is right now.

Then read the user's request and load *only* what it requires. Do **not** read the whole `docs/` corpus at session start.

| Your task involves | Also read |
|---|---|
| Product behavior, screens, what's in/out of scope | `docs/PROJECT_SPEC.md` |
| Architecture, layers, data model, services | `docs/ARCHITECTURE.md` |
| An architectural choice, or something that feels already-settled | `docs/ARCHITECTURE.md` + `docs/DECISIONS.md` |
| Core logic (completion, streaks, scheduling, insights) | `docs/ARCHITECTURE.md` + `docs/TESTING.md` |
| Building, running, simulator, device, signing | `docs/DEVELOPMENT_GUIDE.md` |
| Test strategy, what to test, regression checks | `docs/TESTING.md` |
| "Why is it like this?" / historical rationale | `docs/DECISIONS.md`, then `docs/CHANGELOG.md` |
| Deep background, gotchas, distribution constraints | `docs/CLAUDE_CONTEXT.md` |
| Open defects or unverified behavior | `docs/KNOWN_ISSUES.md` |
| What work remains | `docs/TODO.md` |

## Source of Truth

**The current source code is always authoritative about what the app does.** Documentation is authoritative about intent: `PROJECT_SPEC.md` for product requirements, `ARCHITECTURE.md` for structure, `DECISIONS.md` for rationale and constraints. Everything else records status, history, or background.

**Conflict handling.** When code and a doc disagree, the code is what the app does — investigate *why* they diverged before changing either. Stale doc → fix the doc. Code contradicting an ADR or `PROJECT_SPEC.md` → that's a real finding; surface it rather than silently "correcting" either side. Never treat `PROJECT_STATE.md` as proof of what's implemented; verify against the repo and `git log`.

## Engineering Invariants

Full detail in `docs/ARCHITECTURE.md`; these are the rules worth knowing without opening it.

- **MVVM + DI, one direction: `View → ViewModel → Service → SwiftData`.** Views render state only. Services own all business logic and are the only layer touching SwiftData. Models are dumb data holders. No circular dependencies, no singleton managers.
- **Views never** touch SwiftData directly, `UserNotifications`, `CoreLocation`, or Adhan.
- **`CompletionService.isCompleted` / `isFullyCompleted` is the single choke point for "is this done."** Never re-implement a completion check.
- **Never special-case Prayer** — schedules come from the `ScheduleProvider` strategy pattern.
- **Never persist derived values** (streaks, rates, history). Always compute.
- **SwiftData** for habit data (`Habit`, `Occurrence`, `Completion`, `Shield`); **UserDefaults via `SettingsService`** for scalar app-wide preferences. Don't mix.
- **State ownership:** `@State` / `@Binding` / `@Bindable` / `@Environment` / `@Query`. Avoid `ObservableObject` — zero currently exist; everything is `@Observable`.
- **`project.yml` is the source of truth for the Xcode project.** `Anchor.xcodeproj` is generated and gitignored — never hand-edit or commit it.
- **Swift 6 strict concurrency.** Services and ViewModels are `@MainActor`. Wrap pre-Sendable Apple types behind `@preconcurrency import` in the one file touching them; never leak them outward.
- **Use `Anchor/Theme/` tokens only** — no ad-hoc spacing, radii, colors, or animation curves, and a Reduce Motion fallback at every animating call site. No `.shadow()` anywhere; that's deliberate.
- **Accessibility is not optional polish** — VoiceOver, Dynamic Type, 44pt targets, Reduce Motion, High Contrast, light + dark, on every control.
- **Folders under `Anchor/`:** `App/`, `Models/`, `ViewModels/`, `Views/`, `Components/`, `Services/`, `Theme/`, `Utilities/`, `Extensions/`, `Assets.xcassets/`, `Preview Content/`; tests in `AnchorTests/`. Never add a top-level folder. Views `*View`, Services `*Service`, models/enums singular nouns, protocols capability names; Swift API Design Guidelines throughout.

## Never Change Without Explicit Approval

- **The 8 existing `AccentColor` cases or their raw values** (`Anchor/Theme/AccentColor.swift`). Persisted via `rawValue` in both SwiftData (`Habit.accentColor`) and UserDefaults (`SettingsService.accentColor`). Renaming, reordering, or removing one corrupts existing installs. Add capability *alongside* them (see `customColorHex`), never inside them.
- **`CODE_SIGN_STYLE: Automatic` / `DEVELOPMENT_TEAM: X264QUS42N` in `project.yml`'s `settings.base`.** Without these, `xcodegen generate` silently wipes any signing team set through Xcode's GUI and device builds fail with a confusing "No Account for Team." See ADR-003.
- **`CompletionService.isCompleted` / `isFullyCompleted` as the single completion choke point.** See ADR-002.
- **`HabitService.update(...)`'s non-optional `targetValue` / `unit` / `customColorHex` parameters.** Deliberately without defaults, unlike `create(...)`'s — it forces every call site to decide explicitly rather than silently erasing config via a forgotten argument.
- **Adding a third-party dependency.** Adhan is the only approved one.
- **Removing or renaming a shipped SwiftData model field.** The app is installed on real devices; schema changes must be additive (new optional fields with safe defaults), never destructive.

## Always Verify Before Modifying

- **Read the current file before editing it**, even if you wrote it earlier in the same conversation.
- **Grep every call site before changing a shared enum or model's shape.** `AccentColor` alone had 13+ call sites hardcoding cases as decorative tints, far outside the obvious per-habit-color ones — missing them is a silent visual regression, not a compile error.
- **Before adding a field to `Habit` or `Completion`**, confirm it's optional or safely defaulted and that every `AnchorTests/` fixture still compiles unchanged.
- **Before touching `Frequency`, `DueDateRule`, or `StreakService`, read `StreakServiceTests.swift` first.** The most heavily tested file in the project; it encodes previously-debugged subtlety — today-in-progress leniency, shield priority over partial completion, quantifiable thresholds that behave differently today vs. on a past due day.
- **After any `project.yml` change, run `xcodegen generate`.** After any Swift change, `xcodebuild build` (zero warnings) and `xcodebuild test` — exact commands in `docs/DEVELOPMENT_GUIDE.md`.

## Scope Discipline

Do not add features outside `docs/PROJECT_SPEC.md`. Future ideas go in `docs/TODO.md`. Roadmap items (v1.2+) are not to be implemented ahead of schedule. If a request conflicts with a shipped decision in `docs/DECISIONS.md`, surface the conflict and let the user choose — don't silently override history.

**WidgetKit is paused.** Do not raise, suggest, or ask about widgets until the user says they're ready — full rationale and the standing instruction in `docs/DECISIONS.md` ADR-017.

## Workflow

1. Understand the request; inspect the **actual current implementation** — never rely on documentation alone.
2. Read only the docs the task calls for (table above); check `docs/DECISIONS.md` if an architectural choice is involved.
3. Search for an existing implementation before writing a new one.
4. Plan substantial changes (3+ files, or a real design fork) — surface design forks to the user rather than guessing.
5. Implement the smallest correct change: Services first, then ViewModels (thin pass-throughs), then Views.
6. Build (zero warnings) → test (all passing) → verify the UI in the simulator, light and dark, when applicable.
7. Update the appropriate documentation (below), then report exactly what changed and what was actually verified.

## Definition of Done

- Builds cleanly with zero warnings; all tests pass; no runtime errors.
- Accessible (VoiceOver, Dynamic Type, 44pt targets, Reduce Motion); light and dark both verified.
- No duplicated business logic, no dead code, no force unwraps or force casts.
- Matches `docs/PROJECT_SPEC.md`; documentation updated per the policy below.

## Documentation Update Policy

Update only what actually changed:

| What changed | Update |
|---|---|
| Product behavior | `docs/PROJECT_SPEC.md` |
| Architecture | `docs/ARCHITECTURE.md` (+ `docs/DECISIONS.md` if a real alternative was rejected) |
| Current status | `docs/PROJECT_STATE.md` |
| Build/test workflow | `docs/DEVELOPMENT_GUIDE.md` / `docs/TESTING.md` |
| A new defect or unverified area | `docs/KNOWN_ISSUES.md` |
| New future work | `docs/TODO.md` |
| A shipped milestone | `docs/CHANGELOG.md` |

**`PROJECT_STATE.md` policy.** Rewrite it at the end of a meaningful session as a *snapshot*, not a journal: what is currently true, unfinished, blocked, recently verified, and what should happen next. Never let it accumulate session transcripts, command logs, failed attempts, or debugging narrative — if a historical event matters permanently, it belongs in `docs/CHANGELOG.md` or `docs/DECISIONS.md`.

## Forbidden

- Don't invent APIs or assume a file's contents; don't update documentation with guesses.
- Don't mark anything "verified" that you did not actually verify.
- Don't rewrite working architecture without measurable benefit.
- Don't add dependencies or out-of-scope features without approval, or edit the generated `.xcodeproj`.
- Don't treat historical docs (`CHANGELOG.md`, `CLAUDE_CONTEXT.md`) as current truth.
- Don't resurrect deferred or rejected work — see `docs/TODO.md` and `docs/DECISIONS.md`.

## Guiding Principle

Anchor should always feel simple, fast, native, and reliable.
