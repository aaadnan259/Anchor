# PROJECT_SPEC.md

# Anchor — Product Specification (v1)

## Vision
Anchor is a focused, beautifully designed habit tracker for iPhone. It is intentionally **not** a task manager, planner, calendar, or productivity suite. The primary experience is helping users complete today's habits with minimal friction.

## Product Principles
- Fast to open.
- Fast to understand.
- Fast to complete.
- Native iOS experience.
- Privacy first.
- Local-first architecture.
- Feature depth over feature breadth.

## Goals
### Included in v1
- Daily checklist
- Habit streaks
- Local notifications
- Flexible scheduling
- Beautiful SwiftUI interface
- SwiftData persistence
- Presets (Prayer, Gym, Work, Custom)

### Explicitly Out of Scope
- Accounts
- Cloud sync
- Widgets
- Apple Watch
- HealthKit
- Siri
- AI features
- Collaboration
- Calendar view
- Charts beyond simple progress
- Themes
- Export/Import

## Technology
- SwiftUI
- SwiftData
- iOS 17+
- XcodeGen
- Adhan Swift (wrapped behind abstraction)

## Architecture

### Pattern
MVVM with dependency injection.

Views never contain business logic.

### Data Model

Habit
- id
- name
- icon
- color
- frequency
- reminderEnabled
- archived
- createdAt
- displayOrder

Occurrence
- id
- habitId
- title
- scheduleProvider
- displayOrder

Completion
- id
- habitId
- occurrenceId (optional)
- day
- completedAt

### Scheduling

Define:

ScheduleProvider (protocol)

Implementations:
- FixedTimeScheduleProvider
- PrayerScheduleProvider
- WeeklyScheduleProvider

Views consume schedules only. They never know how schedules are generated.

## Services

- HabitService
- ScheduleService
- NotificationService
- LocationService
- StreakService

Services are stateless where practical and injected into consumers.

## Screens

### Onboarding
Shown once, before Today/Habits/Stats, gated by `hasCompletedOnboarding`.
- Welcome
- Choose starter habits (Prayer/Gym/Work presets, multi-select, all preselected — can proceed with none)
- Notification priming, shown only if a selected habit wants reminders — explains why before the system prompt fires
- Location priming, shown only if a selected habit uses prayer scheduling — explains it's used only for prayer-time calculation, never stored or shared
- Completing creates the chosen habits and hands off to Today

### Today
- Date
- Daily progress ring
- Due habits
- Expandable occurrences
- One-tap completion
- Smooth animations
- Haptics

### Habits
- Reorder
- Archive
- Delete
- Duplicate
- Edit
- Add

### Add/Edit
Fields:
- Name
- Icon
- Color
- Frequency
- Occurrences
- Reminder toggle

Preset cards:
- Prayer
- Gym
- Work
- Custom

### Stats
- Current streak
- Best streak
- Last 4 weeks completion
- Completion percentage
- Tap a habit to open Habit Insights

### Habit Insights
Pushed from a Stats card (tap).
- Trend chart (line): completion rate over Week (last 12 weeks), Month (last 12 months), or Year (last 5 years) — segmented picker
- Time-of-day pattern: completions bucketed into Night/Morning/Afternoon/Evening, with a "usually completed in the ___" summary

### Settings
Reached via gear icon on Today.
- Prayer calculation method (13 methods, e.g. Muslim World League, ISNA, Umm al-Qura)
- Prayer Asr calculation (Shafi/Hanafi madhab)
- Appearance override (System/Light/Dark), applies instantly app-wide including the Settings sheet itself
- App-wide accent color (8-color palette, reuses the same picker as per-habit colors), independent of individual habits' own colors
- Notification authorization status (read-only) with a deep link to system settings when denied
- Smart Reminders (opt-in): one evening check-in notification (fixed 8:00 PM) per habit still due and incomplete as of the last reschedule, independent of any per-habit reminder
- App Lock (Face ID/Touch ID, with device-passcode fallback), toggle only shown when the device has usable biometry enrolled — re-locks on every background→foreground transition, gated after onboarding
- Data export as CSV (flat, one row per completion) or JSON (per-habit, nested completions), including archived habits, via the system share sheet
- App version/build (about)

Persisted via UserDefaults (SettingsService), not SwiftData — these are scalar app-wide preferences, not relational business data.

## Design System

Typography:
- SF Pro
- Dynamic Type

Spacing:
4 / 8 / 12 / 16 / 24 / 32 / 48

Corners:
12 small
20 cards

Animations:
- Spring
- Haptics only where meaningful

Colors:
- Semantic colors
- Curated accent palette
- Full Light/Dark support

## Accessibility
- VoiceOver labels
- 44pt minimum controls
- Dynamic Type
- Reduce Motion compatibility
- High contrast

## Notifications

Recalculate when:
- app launch
- foreground
- midnight
- location changes
- habit edits
- notification permission changes

Maintain next seven days only.

## Performance Targets

- Cold launch under one second where practical.
- No expensive work in View.body.
- Lazy stacks for large collections.
- Cache today's calculated schedules.
- No unnecessary SwiftData fetches.

## Folder Structure

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

## Milestones

1. Scaffold project
2. Design system
3. Models
4. Persistence
5. Services
6. Today screen
7. Habit management
8. Notifications
9. Stats
10. Accessibility
11. Polish
12. Final QA

Every milestone must compile before continuing.

## Acceptance Criteria

Functional
- Create habit
- Edit habit
- Archive habit
- Delete habit
- Complete habit
- Complete occurrence
- Persistence verified
- Prayer schedule verified
- Notifications verified

Quality
- Zero compiler warnings
- Zero runtime crashes during QA
- Dark mode
- Light mode
- Dynamic Type
- VoiceOver labels
- Consistent spacing
- Reusable components
- No duplicated business logic

## Future Roadmap

v1.1
- Calendar history

v1.2
- Widgets

v1.3
- iCloud Sync

v1.4
- Apple Watch

Do not implement roadmap items in v1.

### Backlog (captured, unscoped)

Raised after the v1 visual redesign discussion. Not yet assigned to a version — prioritize deliberately, one at a time, rather than building speculatively.

- **Quantifiable logging** — numeric habit values (e.g. ounces of water) instead of binary complete/incomplete
- **Cross-habit correlation insights** — e.g. does completing habit A predict completing habit B
- **Additional chart types** — line trends, radial completion charts (dot-matrix heatmap already shipped in v1)
- **Streak shields** — configurable "skip days" (vacation/illness) that don't reset a streak to zero

Note: pausing a habit without losing its history already exists in v1 (Archive/Unarchive).
