# PROJECT_SPEC.md — Product Specification

What Anchor **should do**. How it's built belongs in `ARCHITECTURE.md`; why, in `DECISIONS.md`; what's currently true, in `PROJECT_STATE.md`.

Everything under "Shipped Behavior" is current v1 + v1.1 functionality. Everything under "Roadmap" and "Backlog" is **not** a requirement and must not be implemented ahead of schedule.

---

## Vision

A focused, beautifully designed habit tracker for iPhone. Intentionally **not** a task manager, planner, calendar, or productivity suite. The primary experience is helping users complete today's habits with minimal friction.

**Principles:** fast to open · fast to understand · fast to complete · native iOS · privacy first · local-first · feature depth over breadth.

## Scope

**In scope (v1):** daily checklist · habit streaks · local notifications · flexible scheduling (including prayer-time) · SwiftUI interface · SwiftData persistence · presets (Prayer, Gym, Work, Custom). Data export and the Habit Insights charts were scoped in after original planning and have shipped.

**Explicitly out of scope:** accounts · cloud sync · HealthKit · Siri · AI features · collaboration · arbitrary app-wide visual themes (a curated accent palette plus one exact custom-color override *is* in scope; themes beyond that are not). Widgets, Apple Watch, and iCloud sync are out of scope for v1 specifically and appear on the roadmap below.

---

## Shipped Behavior

### Onboarding
Shown once, gated by `hasCompletedOnboarding`, before Today/Habits/Stats.
- Welcome → choose starter habits (Prayer/Gym/Work presets, multi-select, all preselected; proceeding with none is allowed).
- Notification priming, shown only if a chosen habit wants reminders — explains why before the system prompt fires.
- Location priming, shown only if a chosen habit uses prayer scheduling — explains it's used only for prayer-time calculation, never stored or shared.
- Completing creates the chosen habits and hands off to Today.

### Today
- Date, and a daily progress ring with a soft pulsing glow plus a brief celebration the moment it reaches 100%.
- Due habits, with expandable occurrences for multi-occurrence habits.
- **Tapping anywhere on a habit card performs its primary action** — toggle for binary habits, open the log-value sheet for quantifiable ones, expand/collapse for multi-occurrence ones — not just its small dedicated control.
- Quantifiable habits show a fill ring instead of a checkmark; tapping opens a stepper sheet to log today's value.
- Swipe left on a card to delete the habit.
- Long-press a card (Daily/Weekdays habits only) for a "Shield Today" quick action; a blue shield badge shows once active.
- Smooth animations and haptics.

### Habits
Reorder (long-press drag), archive, delete, duplicate, edit, add.

### Add / Edit
Fields: name · icon (a curated SF Symbol grid, or a single Apple emoji entered via the system emoji keyboard) · color (8 curated swatches, or an exact custom color via a native color picker) · frequency · occurrences · "Track a Number" (Custom/single-occurrence habits only — a numeric daily target plus a unit label, logged via a stepper instead of a checkmark) · reminder toggle. Preset cards: Prayer, Gym, Work, Custom.

### Stats
Current streak · best streak · last-4-weeks completion · completion percentage. Tap a habit to open Habit Insights.

### Habit Insights
Pushed from a Stats card.
- **Trend chart** (line): completion rate over Week (last 12 weeks), Month (last 12 months), or Year (last 5 years), via a segmented picker.
- **Time of Day:** completions bucketed into Night/Morning/Afternoon/Evening, with a "usually completed in the ___" summary.
- **By Day of Week:** a radial wheel, one wedge per weekday, wedge length encoding that weekday's completion rate across the habit's whole history, with a "Best on ___" summary. The app's only genuinely radial chart.
- **History:** the same completion grid shown on Stats, plus — for Daily/Weekdays habits only — a "Manage Shielded Days" sheet. A shielded day is exempt from breaking a streak (vacation, illness), past or future; it renders in a distinct color and neither counts toward nor breaks current/best streak. Not available for weekly-target habits. The same toggle is reachable faster, for today specifically, via long-press on the Today card.
- **"View Full Calendar"** pushes a dedicated Calendar History screen: a month grid (day numbers, not dots) of the same per-day completion states as the heatmap, with month navigation clamped between the habit's creation month and the current month.

### Settings
Reached via the gear icon on Today.
- Prayer calculation method (13 methods) and Asr calculation (Shafi/Hanafi madhab).
- Appearance override (System/Light/Dark), applied instantly app-wide including the Settings sheet itself.
- App-wide accent color (the 8-color palette or an exact custom color), independent of individual habits' colors.
- Notification authorization status (read-only), with a deep link to system settings when denied.
- Smart Reminders (opt-in): one evening check-in at 8:00 PM per habit still due and incomplete as of the last reschedule, independent of per-habit reminders.
- App Lock (Face ID/Touch ID with device-passcode fallback) — the toggle appears only when the device has usable biometry enrolled. Re-locks on every background→foreground transition.
- Data export as CSV (flat, one row per completion) or JSON (per-habit, nested), including archived habits, via the system share sheet.
- App version and build.

### Notifications
Recalculated on app launch, foreground, midnight, location change, habit edit, and notification-permission change. Only the next seven days are kept scheduled.

---

## Cross-Cutting Requirements

**Design:** SF Pro with full Dynamic Type · spacing scale 4/8/12/16/24/32/48 · corner radius 12 for controls, 20 for cards · spring animations · haptics only where meaningful · semantic colors with full light/dark support.

**Accessibility:** VoiceOver labels, 44pt minimum controls, Dynamic Type, Reduce Motion compatibility, high contrast — on every screen.

**Performance:** cold launch under one second where practical · no expensive work in `View.body` · lazy stacks for large collections · cached daily schedules · no unnecessary SwiftData fetches.

**Quality bar:** see `../CLAUDE.md`'s Definition of Done. Functionally, v1 requires create/edit/archive/delete habit, complete habit and occurrence, verified persistence, verified prayer scheduling, and verified notifications.

---

## Roadmap — not requirements

Do not implement these ahead of schedule.

- **v1.1 — Calendar history.** ✅ Shipped; see Habit Insights' "View Full Calendar" above.
- **v1.2 — Widgets.** Deferred, and paused at the user's explicit request — see ADR-017 for the rationale and the standing instruction.
- **v1.3 — iCloud Sync.** Out of scope for v1 by deliberate product promise (no accounts, no cloud).
- **v1.4 — Apple Watch.**

## Backlog — captured, unscoped

Prioritize deliberately, one at a time; don't build speculatively.

- **Cross-habit correlation insights** — e.g. does completing habit A predict completing habit B. Deferred pending real usage data.

Two former backlog items are closed: *additional chart types* shipped as the "By Day of Week" radial wheel, and *pausing a habit without losing history* already exists in v1 as Archive/Unarchive.
