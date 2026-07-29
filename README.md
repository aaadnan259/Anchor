# Anchor

A focused, native iOS habit tracker built with SwiftUI and SwiftData. Not a task manager, planner, or calendar — Anchor does one thing: help you complete today's habits with minimal friction, including first-class prayer-time-aware scheduling.

## Tech Stack

Swift 6 · SwiftUI · SwiftData · iOS 17+ · [XcodeGen](https://github.com/yonaskolb/XcodeGen) · [Adhan Swift](https://github.com/batoulapps/adhan-swift) (prayer calculation, the only third-party dependency)

## Getting Started

```bash
xcodegen generate
xcodebuild build -project Anchor.xcodeproj -scheme Anchor -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

`Anchor.xcodeproj` is generated from `project.yml` and is gitignored — never edit it directly. See `docs/DEVELOPMENT_GUIDE.md` for full build/run/test instructions.

## Documentation

Start with **[`CLAUDE.md`](CLAUDE.md)** — the engineering constitution and a map of everything else in [`docs/`](docs/):

- [`docs/PROJECT_SPEC.md`](docs/PROJECT_SPEC.md) — what the app does
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — how it's built
- [`docs/CLAUDE_CONTEXT.md`](docs/CLAUDE_CONTEXT.md) — full project history and reasoning
- [`docs/PROJECT_STATE.md`](docs/PROJECT_STATE.md) — where things stand right now
- [`docs/DECISIONS.md`](docs/DECISIONS.md) — why things are built the way they are
- [`docs/TODO.md`](docs/TODO.md) · [`docs/CHANGELOG.md`](docs/CHANGELOG.md) · [`docs/KNOWN_ISSUES.md`](docs/KNOWN_ISSUES.md) · [`docs/TESTING.md`](docs/TESTING.md) · [`docs/DEVELOPMENT_GUIDE.md`](docs/DEVELOPMENT_GUIDE.md)

If you're an AI assistant picking up this project in a new conversation, read `CLAUDE.md` first — it tells you what else to read before writing any code.
