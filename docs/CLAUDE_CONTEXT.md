# CLAUDE_CONTEXT.md — Deep Background

**Not startup context.** Read this when you need durable project knowledge that the repository itself can't tell you: platform constraints, distribution limits, hard-won gotchas, and things that were deliberately *not* built. For what the app does see `PROJECT_SPEC.md`; for how it's built, `ARCHITECTURE.md`; for why, `DECISIONS.md`; for where it stands now, `PROJECT_STATE.md`; for what happened when, `CHANGELOG.md`.

Everything discoverable by reading the repo — file maps, file counts, per-file descriptions — was deliberately removed from this document. Grep and read the real files instead.

---

## Product Philosophy

Anchor solves one problem: completing today's habits with minimal friction. Every scope decision has flowed from that.

- **Depth over breadth.** A small set of things done exceptionally well. Prayer-time scheduling — which most habit trackers don't attempt at all — is a genuine differentiator and a first-class preset, not a niche bolt-on, and not the whole point of the app either. The target audience is anyone who wants a simple, beautiful daily habit checklist.
- **Local-first is a promise, not a default.** No accounts, no backend, no analytics, no iCloud. This is why "just add sync" is never a small change — it's a reversal of a product commitment, version-gated to v1.3 for that reason.
- **Native over convenient.** Apple's recommended approach wins over the clever one. This is why there's no dependency list to speak of, no custom navigation stack, and no design system borrowed from the web.
- **Restraint is the feature.** Several plausible, requested features were deliberately declined or scoped down. See "Deliberately Not Built" below before proposing any of them again.

## Distribution Constraints

The project signs with a **free Apple "Personal Team"** — no paid Apple Developer Program membership. This is the single most consequential external constraint on the project:

- Builds installed on a device **expire after 7 days**.
- Install is **only** possible via direct USB + Xcode/`devicectl`. No OTA, no wireless distribution, at all.
- **TestFlight and Ad Hoc distribution both require the paid $99/year membership.**
- App Group entitlements (needed for a WidgetKit extension to share data with the app) are unreliable on this tier, and a failed provisioning attempt can leave signing in a broken state — jeopardizing the working device-build pipeline. This is why Widgets are paused, not merely unprioritized (ADR-017).
- **Enrolling requires entering payment information, which Claude must never do on the user's behalf.** This is a hard safety constraint, not a preference. If the user wants TestFlight, they have to enroll themselves.

The app has been installed on two physical devices (the developer's own iPhone, and a friend's for one-off feedback). It has never been submitted to TestFlight or the App Store.

## Deliberately Not Built

Do not propose or implement these without the user raising them first.

- **Widgets (v1.2).** Scoped and researched, then explicitly paused by the user pending a paid Apple Developer account. See ADR-017 for the standing instruction.
- **iCloud Sync (v1.3) and Apple Watch (v1.4).** Version-gated roadmap items, not backlog. Real scope jumps; don't implement ahead of schedule.
- **Cross-habit correlation insights.** Deferred — blocked on real usage data, not engineering effort. Statistically meaningless against the sparse completion history any single user accumulates early on.
- **A curated emoji picker grid.** Considered and rejected in favor of the system emoji keyboard (ADR-011). Don't re-litigate without a new reason.
- **Per-occurrence shielding.** Considered twice, declined twice, at habit-day granularity both times (ADR-009, ADR-013). The user was asked directly and chose to leave the scoping alone.
- **Replacing the curated `AccentColor` enum with an open color model.** Rejected in favor of an additive custom-color override (ADR-012).
- **A Notification Service Extension** for "live" reminder content (ADR-007), and **a cloud backend** — both are the same category of scope jump as Widgets.
- **"Quit Habit Logic"** and a **`Habit` → subtype split.** Both proposed by a third-party "master audit" the user shared. The first describes a smoking-cessation feature that has never existed anywhere in Anchor's scope — hallucinated or copied from a different app's audit. The second would have been an architecture regression. Neither implemented.

## Hard-Won Gotchas

Operational specifics live in `DEVELOPMENT_GUIDE.md` (build, device, signing) and `TESTING.md` (simulator-automation quirks). These are the judgment lessons behind them.

- **If a build setting isn't in `project.yml`, it does not durably exist.** XcodeGen regenerates the entire `.xcodeproj` on every run, silently discarding anything set only through Xcode's GUI. This cost a confusing "No Account for Team" debugging session once already — see ADR-003 for the incident and the permanent fix.
- **A single choke point makes cross-cutting features safe.** Quantifiable Logging conceptually touches streaks, insights, notifications, export, and the completion UI. Because all of them already routed through `CompletionService.isCompleted`/`isFullyCompleted` instead of re-implementing their own check, it shipped by changing one method rather than ~15 call sites. This is a demonstrated payoff, not a theoretical one — protect it (ADR-002).
- **Grep every call site before changing a shared type's shape, including the non-obvious ones.** `AccentColor` had 13+ call sites using specific cases as decorative tints, well outside the "per-habit color" usages that come to mind first. Missing them would have been a silent visual regression, not a compile error.
- **Fact-check third-party audits and copy-pasted prompts against the actual code before implementing anything from them.** One such audit mixed genuinely accurate observations (the old app icon glyph really was ambiguous) with an entirely hallucinated feature. Treat every specific, checkable claim as needing verification.
- **When a new request conflicts with a shipped, deliberate decision, surface the conflict and let the user choose.** "Make colors fully custom" collided with the curated-palette decision; naming the conflict produced a better middle path (a 9th swatch) than either silently overriding or silently ignoring it would have. The same pattern resolved the shields-for-weekly-goal-habits request.
- **Planning earns its cost when a request bundles a safe feature with a risky one.** Researching Calendar History and WidgetKit together surfaced the App Group signing risk *before* any `project.yml` change was made, letting the user drop the risky half and keep the safe one.
- **Don't conclude a UI interaction is broken from simulator automation alone.** Three separate "known issues" — emoji entry, the custom `ColorPicker`, and `HabitsView`'s "+" toolbar button — all turned out to be limitations of this environment's simulator tooling, not app defects, once tested on a real device or by a human. Verify with a device or a person before logging an app bug. Details in `TESTING.md`.
- **A user's explicit "don't ask me about X again" is a standing instruction**, worth writing to persistent memory rather than only to a project file, since it must survive across separate conversations.

## Repository Conventions Worth Knowing

- **`AnchorTests/AnchorTests.swift` is misleadingly named.** Despite the generic Xcode-scaffold name, it holds the `DueDateRule` suite — not a catch-all.
- **`AnchorTests/TestSupport.swift`** provides a fixed UTC `Calendar` for date-math determinism and an in-memory `ModelContext` factory. `StreakServiceTests` deliberately uses `Calendar.current` instead, because it tests real local-day-boundary behavior — match whatever the file you're extending already uses.
- **Something that looks like dead code may be built ahead of a planned feature.** `Frequency.supportsShields` had zero call sites for a full feature cycle between Streak Shields and Quick Shields. Check git history before deleting an apparently-unused member.
- **ViewModels are constructed fresh per screen in a `.task` block**, not environment-injected. Only Services (plus `SettingsService`/`LocationService`) are injected via `@Environment`, because those are genuinely shared and long-lived.
- **`Habit.frequency` and `Occurrence.scheduleProvider` are computed accessors** over privately-stored `Data` (JSON-encoded), not stored properties. `AccentColor` persists as a raw-value string. Keep this in mind when reasoning about schema changes.

## History

Full milestone-by-milestone record is in `CHANGELOG.md`, with real commit hashes. Two notes that the log alone won't tell you:

- **The initial commit (`c8ecfb1`) is a snapshot, not a work session.** It landed the entire v1 scaffold — design system, models, services, every core screen, the early test suite — in one commit, representing substantial iterative work that predates the git history's granularity.
- **The documentation has been audited against the code twice** (`d293b88`, and the pass that produced this file's current form), each time finding real drift — inflated test counts, off-by-one file counts, model fields documented as raw IDs when they're actually SwiftData relationships. Treat documentation claims about the code as needing verification, including the ones in this file.
