# ARCHITECTURE.md

# Anchor Architecture

Version: 1.0

---

# Purpose

This document defines **how Anchor is built**, not **what Anchor does**.

Product behavior belongs in `PROJECT_SPEC.md`.

Engineering standards belong in `CLAUDE.md`.

---

# Core Philosophy

Anchor should remain:

- Native

- Fast

- Small

- Maintainable

- Predictable

The architecture should make adding features easy without increasing complexity.

Avoid over-engineering.

---

# Technology Stack

Platform

- iOS 17+

Language

- Swift 6

Frameworks

- SwiftUI

- SwiftData

- Foundation

- Observation

- CoreLocation

- UserNotifications

Project

- XcodeGen

External Dependency

- Adhan Swift

Only Adhan is permitted because Apple provides no prayer calculation API.

No additional dependencies without approval.

---

# Architecture Pattern

MVVM

```

SwiftUI Views

↓

View Models

↓

Services

↓

SwiftData

```

Views never contain business logic.

Services never know about UI.

Models never perform application logic.

---

# Project Structure

```

Anchor/

App/

Models/

ViewModels/

Views/

Components/

Services/

Theme/

Utilities/

Extensions/

Resources/

Assets/

Preview Content/

Tests/

```

Never create additional top-level folders.

---

# Dependency Graph

```

Views

↓

ViewModels

↓

Services

↓

SwiftData

↓

Foundation

```

Allowed

View → ViewModel

ViewModel → Service

Service → Model

Forbidden

View → SwiftData

View → Notification APIs

View → CoreLocation

View → Adhan

Service → UI

Model → Service

No circular dependencies.

---

# MVVM Responsibilities

## Views

Responsible for

- Layout

- Rendering

- User interaction

- Animations

- Accessibility

Never responsible for

- Calculations

- Scheduling

- Notifications

- Persistence

- Filtering business data

---

## ViewModels

Responsible for

- UI state

- User intent

- Data transformation

- Calling services

Never responsible for

- Persistence implementation

- Notification scheduling

- Prayer calculations

---

## Services

Responsible for

- Business rules

- Scheduling

- Persistence operations

- Notifications

- Location

- Streak calculations

Services should be stateless whenever practical.

---

## Models

Represent business entities only.

No business logic.

No networking.

No UI.

---

# Data Model

## Habit

Represents one habit.

Fields

- id

- name

- icon

- accentColor

- frequency

- reminderEnabled

- archived

- createdAt

- displayOrder

Relationship

One Habit

↓

Many Occurrences

---

## Occurrence

Represents one completion opportunity.

Examples

Prayer

Breakfast

Lunch

Medication

Evening Walk

Fields

- id

- title

- displayOrder

- scheduleProvider

---

## Completion

Represents one completed occurrence.

Fields

- id

- habitID

- occurrenceID

- day

- completedAt

Never store streaks.

Always calculate.

---

# Scheduling Architecture

Never special-case Prayer.

Instead use a strategy pattern.

```

ScheduleProvider

↓

FixedTimeProvider

PrayerProvider

WeeklyProvider

```

Each provider answers

```

Today's schedule

```

Views never know where schedules originate.

---

# Services

## HabitService

Create

Edit

Archive

Delete

Reorder

Fetch

---

## ScheduleService

Returns today's occurrences.

Uses ScheduleProvider internally.

---

## PrayerService

Wrapper around Adhan.

Never expose Adhan directly.

---

## LocationService

Owns CoreLocation.

Requests permission only when required.

---

## NotificationService

Schedules local notifications.

Never called directly from Views.

---

## StreakService

Calculates

Current streak

Best streak

Completion %

Never persist calculated values.

---

# Navigation

Single TabView

Today

Habits

Stats

Modal sheets

Add Habit

Edit Habit

System permission dialogs

No deep navigation hierarchy.

---

# State Management

Prefer

@State

↓

@Binding

↓

@Bindable

↓

@Environment

↓

@Query

Avoid ObservableObject unless necessary.

Never duplicate state.

Keep a single source of truth.

---

# Persistence

SwiftData only.

No backend.

No accounts.

No iCloud.

Persist only

Habits

Occurrences

Completions

Everything else is derived.

---

# Notifications

Recalculate when

- App launches

- App enters foreground

- Midnight

- Habit edited

- Location changes

- Notification settings change

Keep only next 7 days scheduled.

Never duplicate notifications.

---

# Location

Location permission is optional.

Only request it if a Prayer schedule exists.

If denied

Prayer still exists

Notifications disabled

Display helpful guidance

No blocking alerts.

---

# Design System

Use reusable components.

Examples

ProgressRing

HabitCard

CompletionToggle

IconPicker

ColorPicker

SectionHeader

PrimaryButton

Do not duplicate UI.

---

# Performance

Target

60 FPS

Cold launch under one second where practical.

Rules

No expensive work inside View.body

Lazy stacks

Minimal SwiftData queries

Cache today's prayer calculations

Avoid unnecessary refreshes

Measure before optimizing.

---

# Accessibility

Required

VoiceOver

Dynamic Type

44pt tap targets

High contrast

Reduce Motion

Semantic labels

Accessibility is required for every screen.

---

# Error Handling

Never crash intentionally.

Avoid force unwrap.

Avoid force cast.

Recover gracefully.

Surface user-friendly messages.

Log developer information separately.

---

# Testing

Business logic should be testable.

Prioritize testing

Scheduling

Streak calculations

Notification generation

Persistence

Views should contain minimal logic.

---

# Future Extensibility

Future features should fit existing architecture.

Examples

Widgets

↓

ScheduleService

Watch App

↓

HabitService

iCloud

↓

Persistence layer

Avoid rewriting architecture.

Extend existing systems.

---

# Anti-Patterns

Never

- Put business logic inside Views

- Duplicate state

- Create singleton managers

- Expose Adhan directly

- Persist calculated values

- Special-case Prayer

- Add features outside PROJECT_SPEC.md

- Introduce dependencies without approval

- Rewrite working code without measurable benefit

---

# Definition of Done

Architecture is respected when

✓ Views are presentation only

✓ Business logic lives in Services

✓ Single source of truth

✓ Generic scheduling system

✓ Native SwiftUI

✓ Minimal dependencies

✓ Reusable components

✓ SwiftData is the only persistence layer

✓ No circular dependencies

✓ Project compiles after every milestone

If any of these fail, the implementation is incomplete.