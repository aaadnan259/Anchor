# CLAUDE.md

# Anchor Engineering Constitution

> This document defines how the project should be engineered.
> Product behavior belongs in PROJECT_SPEC.md.

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
Future ideas belong in ROADMAP.md.

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

## Guiding Principle

Anchor should always feel:

- Simple
- Fast
- Native
- Reliable
