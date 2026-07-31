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
- Themes (curated accent color + an exact custom color override are in scope; arbitrary app-wide visual themes are not)

Note: this list reflects original v1 planning. Two items originally listed here — data export/import and charts beyond simple progress — were later scoped in and shipped (CSV/JSON export; the Habit Insights trend and time-of-day charts). See both features' entries under Screens below and `CHANGELOG.md`.

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
- targetValue (optional) — numeric daily target for quantifiable habits, nil for binary habits
- unit (optional) — display label for the target (e.g. "glasses"), nil for binary habits
- customColorHex (optional) — exact custom tint, overrides the curated `color` when set

Occurrence
- id
- habit (relationship, optional)
- title
- scheduleProvider
- displayOrder

Completion
- id
- habit (relationship, optional)
- occurrence (relationship, optional)
- day
- completedAt
- value — logged amount, defaults to 1 for binary habits; compared against the habit's targetValue for quantifiable habits

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
- Daily progress ring, with a soft pulsing glow and a brief celebration animation the moment it reaches 100%
- Due habits
- Expandable occurrences
- One-tap completion — tapping anywhere on a habit card performs its primary action (toggle for binary habits, open the log-value sheet for quantifiable habits, expand/collapse for multi-occurrence habits), not just its small dedicated control
- Quantifiable habits show a fill ring instead of a checkmark; tapping opens a stepper sheet to log today's value
- Swipe left on a habit card to delete the habit
- Long-press a habit card (Daily/Weekdays habits only) for a "Shield Today" quick action — a blue shield badge shows once active
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
- Icon — a curated SF Symbol grid, or a single Apple emoji entered via a text field and the system emoji keyboard
- Color — 8 curated swatches, or an exact custom color via a native color picker
- Frequency
- Occurrences
- Track a Number (Custom/single-occurrence habits only) — numeric daily target + unit label, logged via a stepper instead of a binary checkmark
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
- History: the same completion grid shown on Stats, plus (Daily/Weekdays habits only) a "Manage Shielded Days" sheet — mark a day as exempt via a date picker so it doesn't break a streak, for vacation/illness, past or future. Shielded days render as a distinct color in the grid and don't count toward or break current/best streak. Not available for weekly-target habits. The same shield/unshield toggle is also available faster, for today specifically, via long-press on the habit's Today card.

### Settings
Reached via gear icon on Today.
- Prayer calculation method (13 methods, e.g. Muslim World League, ISNA, Umm al-Qura)
- Prayer Asr calculation (Shafi/Hanafi madhab)
- Appearance override (System/Light/Dark), applies instantly app-wide including the Settings sheet itself
- App-wide accent color (8-color palette or an exact custom color, reuses the same picker as per-habit colors), independent of individual habits' own colors
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
- Curated accent palette, or an exact custom color per habit and app-wide
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

- **Cross-habit correlation insights** — e.g. does completing habit A predict completing habit B
- **Additional chart types** — radial completion charts (line trends and dot-matrix heatmap already shipped in v1)

Note: pausing a habit without losing its history already exists in v1 (Archive/Unarchive).
