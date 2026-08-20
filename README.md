# Anchor

A focused, native iOS habit tracker built with SwiftUI and SwiftData. Not a task manager, planner, or calendar — Anchor does one thing: help you complete today's habits with minimal friction, including first-class prayer-time-aware scheduling.

## Tech Stack

Swift 6 · SwiftUI · SwiftData · iOS 17+ · [XcodeGen](https://github.com/yonaskolb/XcodeGen) · [Adhan Swift](https://github.com/batoulapps/adhan-swift) (prayer calculation, the only third-party dependency)

## Getting Started

```bash
xcodegen generate
xcodebuild build -project Anchor.xcodeproj -scheme Anchor -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

`Anchor.xcodeproj` is generated from `project.yml` and is gitignored — never edit it directly. Full build, run, test, and device instructions: [`docs/DEVELOPMENT_GUIDE.md`](docs/DEVELOPMENT_GUIDE.md).

## Documentation

**Start with [`CLAUDE.md`](CLAUDE.md)** — the engineering constitution, and the map of when to read everything else.

Each document has one purpose:

| File | Answers |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | How to work on this project |
| [`docs/PROJECT_STATE.md`](docs/PROJECT_STATE.md) | Where the project is right now |
| [`docs/PROJECT_SPEC.md`](docs/PROJECT_SPEC.md) | What the product should do |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | How the software is structured |
| [`docs/DECISIONS.md`](docs/DECISIONS.md) | Why important choices were made |
| [`docs/DEVELOPMENT_GUIDE.md`](docs/DEVELOPMENT_GUIDE.md) | How to build, run, and deploy it |
| [`docs/TESTING.md`](docs/TESTING.md) | How to verify it |
| [`docs/CHANGELOG.md`](docs/CHANGELOG.md) | What happened historically |
| [`docs/KNOWN_ISSUES.md`](docs/KNOWN_ISSUES.md) | What is currently broken |
| [`docs/TODO.md`](docs/TODO.md) | What remains to be done |
| [`docs/CLAUDE_CONTEXT.md`](docs/CLAUDE_CONTEXT.md) | Deep background, when you need it |

**If you're an AI assistant picking this up:** read `CLAUDE.md` and `docs/PROJECT_STATE.md` — those two only. `CLAUDE.md` tells you which of the rest your task actually needs. Don't load the whole corpus.
