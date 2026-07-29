# ARCHITECTURE.md

# Anchor Architecture

Version: 1.0

---

# Purpose

This document defines **how Anchor is built**, not **what Anchor does**.

Product behavior belongs in `PROJECT_SPEC.md`.

Engineering standards belong in `../CLAUDE.md`.

The reasoning behind non-obvious choices belongs in `DECISIONS.md` — this file describes the current shape, not why every alternative was rejected.

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

- icon (SF Symbol name, or a single emoji — see `String.isSFSymbolCompatible`)

- accentColor (one of the 8 curated cases; always set, even when customColorHex overrides it)

- customColorHex (optional; exact color that overrides accentColor when set)

- frequency

- reminderEnabled

- archived

- createdAt

- displayOrder

- targetValue (optional; numeric daily target, nil for binary habits)

- unit (optional; display label for targetValue, e.g. "glasses")

Computed, not stored

- tintColor → customColorHex.map(Color.init) ?? accentColor.color

Relationships

One Habit

↓

Many Occurrences

One Habit

↓

Many Completions (via Occurrence)

One Habit

↓

Many Shields

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

- value (defaults to 1; for quantifiable habits, compared against Habit.targetValue — see CompletionService.isCompleted)

Never store streaks.

Always calculate.

---

## Shield

Represents one day a habit is exempt from breaking its streak (vacation, illness).

Fields

- id

- habitID

- day

Habit-day granularity only — a Shield protects the whole habit for one day, not one occurrence within it. Only meaningful for Daily/Weekdays habits (see Frequency.supportsShields); never persist a Shield for a `.timesPerWeek` habit.

Never counted as a completion. Read only by StreakService (streak continuity) and the History grid (display).

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

Daily history (for the heatmap)

Reads CompletionService.isCompleted/isFullyCompleted and CompletionService.isShielded — never re-implements either check.

Never persist calculated values.

---

## CompletionService

The single choke point for "is this done."

Owns

isCompleted / isFullyCompleted (occurrence- and habit-level; threshold-aware for quantifiable habits)

toggle (binary habits) / logValue (quantifiable habits)

isShielded / toggleShield

Every other service or view model that needs completion state calls through this — never re-implemented elsewhere.

---

## InsightsService

Calculates trend and time-of-day data for Habit Insights.

Trend (week/month/year buckets)

Time-of-day distribution (Night/Morning/Afternoon/Evening)

Reads CompletionService; never re-implements completion logic.

---

## ExportService

Stateless. Operates on `[Habit]` passed in — no ModelContext dependency.

CSV (flat, one row per completion) and JSON (nested per habit) export.

Includes archived habits. Never special-cases habit type (quantifiable habits export their raw `value`).

---

## AuthenticationService

Wraps LocalAuthentication (`LAContext`). Never expose `LAContext`/`LABiometryType` outside this file.

biometryKind() — none / touchID / faceID, for choosing the right icon and toggle label.

authenticate() — `.deviceOwnerAuthentication` (biometrics with device-passcode fallback), never biometrics-only.

---

# Navigation

Root branch (`AnchorApp`), in order

1. Test host → straight to RootTabView, no gating

2. `!hasCompletedOnboarding` → OnboardingView (full-screen flow, one-time)

3. `biometricLockEnabled && !isUnlocked` → LockScreenView (re-locks on every background→foreground)

4. else → RootTabView

Single TabView (RootTabView)

Today

Habits

Stats

Modal sheets

Add Habit / Edit Habit (from Today, Habits)

Settings (from Today's gear icon)

Log Value (from Today, quantifiable habits only)

Manage Shielded Days (from Habit Insights)

System permission dialogs

Push navigation

Stats → Habit Insights (tap a stat card)

Quick actions (no navigation, no new screen)

Today: long-press a habit card → Shield Today / Remove Shield (Daily/Weekdays habits only)

No deeper hierarchy than this. If a feature needs a third level of push navigation, reconsider whether it belongs in Anchor at all.

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

Shields

Everything else is derived.

App-wide preferences (appearance, accent color, calculation method, biometric lock, smart reminders) are UserDefaults via SettingsService, not SwiftData — they're scalar settings, not relational business data.

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

HabitIcon (renders an SF Symbol or an emoji from the same `icon: String` — see `String.isSFSymbolCompatible`)

CompletionToggle

IconPicker (Symbols/Emoji segmented)

AccentColorPicker (8 curated swatches + 1 custom via native ColorPicker)

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

- Add features outside `PROJECT_SPEC.md`

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