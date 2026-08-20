# DECISIONS.md — Active Architectural Decisions

One entry per non-obvious choice where a reasonable alternative existed and was consciously rejected. **These still constrain future work** — read the relevant one before changing anything it touches.

Historical and superseded decisions (ADR-004, ADR-005, ADR-008, ADR-014) live in `archive/DECISIONS_ARCHIVE.md`. Numbering is global and never reused.

---

## ADR-018 — "Additional chart types" means a weekday completion wheel
**2026-07-31 · Constrains: `WeekdayRadialChartView`, `InsightsService.weekdayDistribution`**

The backlog item ("radial completion charts") was only a placeholder phrase. Three designs were considered: a By-Day-of-Week wheel (seven equal-angle wedges, wedge length encoding that weekday's completion rate); a single large ring showing one lifetime percentage; and a radial re-skin of the existing time-of-day bars.

**Chose the weekday wheel**, proposed to and confirmed by the user before implementation. It's the only one that is both authentically radial (angular position is meaningful) and a *new insight* — "which days are you best and worst at this habit" — rather than a new shape on data the trend and time-of-day charts already show. It maps onto existing data (`DueDateRule.isDue`, `CompletionService.isFullyCompleted`) with no model or persistence change.

**Load-bearing detail:** `SectorMark`'s `outerRadius` has no `PlottableValue`-bound overload in this SDK, so each wedge's radius is computed per-mark (`.ratio(max(slice.rate, 0.08))`) inside the `Chart` closure rather than declared once via a chart-wide mapping. A 0%-rate weekday is floored to an 8% sliver so it stays visible and tappable.

## ADR-017 — WidgetKit deferred rather than risking free-account provisioning
**2026-07-31 · Constrains: any widget, extension target, or App Group work**

A Home Screen widget needs an App Group (`group.com.adnan.Anchor`) to share data with the main app, which requires Apple to register a new App ID capability. The user is on a free "Personal Team" account — the same tier that already caused a real signing incident (ADR-003).

**Chose to drop it entirely** rather than add the extension target and find out empirically. App Group provisioning failures on free accounts don't fail cleanly; they can leave signing in a broken state, jeopardizing the working physical-device pipeline. Calendar History had no such dependency and shipped in the same session.

Nothing is half-scaffolded — there is no unbuilt extension target sitting around. Revisiting requires a paid Apple Developer Program account, which Claude cannot enroll the user in (payment information).

**Standing instruction — this is the authoritative statement of the pause.** After seeing the researched risk the user paused the feature themselves: *"Put a pin on the widgets — don't ask me about it until I'm ready."* Treat that as standing across sessions, not a one-turn preference: **do not raise, suggest, or ask about WidgetKit until the user says they're ready.** Other documents reference this decision; none of them restate it.

## ADR-016 — Future-dated calendar cells reuse `.notDue`
**2026-07-31 · Constrains: `StreakService.dayCompletionState`, `DayCompletionState`**

`dailyHistory` only ever computes a trailing window ending at today, so its per-day branch never sees a future date. Calendar History needs single-day lookups for arbitrary dates in a browsable month, including days after today. Extracting the per-day branch verbatim would have made an unlogged future day fall through to `.missed` — reporting a day as missed before it happened.

**Chose an explicit `day > today` guard returning the existing `.notDue`**, rather than adding a `.future` case. Same precedent as ADR-015: `.notDue`'s meaning ("nothing to show for this day yet") already covers "hasn't happened yet" as well as "predates the habit," and its faint-neutral color is visually right for both. Zero UI changes needed.

**Tradeoff:** `.notDue` now covers two reasons that render identically. Acceptable — a user glancing at a calendar has no need to distinguish "this habit didn't exist yet" from "this hasn't happened yet."

## ADR-015 — Below-target quantifiable days reuse `.partial`
**2026-07-30 · Constrains: `StreakService.dailyHistory`, `DayCompletionState`**

A quantifiable habit logged below target rendered identically to a day with nothing logged (both `.missed`), so the heatmap couldn't distinguish "attempted but short" from "did nothing."

**Chose to reuse `.partial`** — `dailyHistory` checks `CompletionService.value` in its `completedCount == 0` branch and reports `.partial` when anything was logged — rather than adding a new `DayCompletionState` case with its own color. `.partial` already means "attempted but not fully done" for multi-occurrence habits; extending it to "attempted but below target" is coherent, not overloaded. One-line change versus touching the enum, the color function, and every `switch` over it.

**Tradeoff:** a multi-occurrence "some done" day and a quantifiable "some progress" day now look the same. Acceptable — they mean the same thing to a user, and no habit is ever both (ADR-010 scopes quantifiable to single-occurrence habits), so the meanings never collide on one habit's history.

**Also settled:** a shielded quantifiable day was never part of this gap. `isShielded` is checked *before* the `completedCount == 0` branch, so it always correctly reported `.shielded` regardless of logged value. The original backlog wording bundled the two together by association.

## ADR-013 — Quick Shields stay at habit-day granularity
**2026-07-29 · Constrains: `Shield`, `TodayViewModel.toggleShield`, `HabitCardView` context menu**

The feature request said "shield either the whole day or just the task for that day." For single-occurrence habits those are identical; for multi-occurrence habits (Prayer) they aren't, and `Shield` has no occurrence reference.

**Chose to keep habit-day granularity**, selected by the user via `AskUserQuestion` after the tradeoff was surfaced. True per-occurrence shielding would require deciding how a partial shield interacts with the already-tested `isFullyCompleted`/streak-priority logic — genuine new streak semantics, not just new UI, and risk to the most heavily tested code in the project. The chosen option needed zero changes to `Shield`, `StreakService`, or any tested logic; only UI wiring plus activating the previously-dead `Frequency.supportsShields`.

**Tradeoff:** a user can't shield a single prayer within a Prayer habit's day. Acceptable — Gym/Work/Custom habits, the majority case, have no such gap.

## ADR-012 — Custom accent color is an additive override, not a replacement
**2026-07-29 · Constrains: `AccentColor`, `Habit.customColorHex`, `SettingsService.customAccentColorHex`**

A request for "exact custom colors," taken literally, conflicted with the already-shipped curated closed palette (ADR-008, archived).

**Chose to add a "Custom…" swatch alongside the existing 8**, backed by a native `ColorPicker` and stored as an optional hex override — `AccentColor` itself untouched. Selected by the user via `AskUserQuestion` after research showed the blast radius of the alternative: `AccentColor` is persisted by `rawValue` in *both* SwiftData and UserDefaults, and 13+ view call sites hardcode named cases as decorative tints. Replacing it wholesale would have touched every one of those, both persistence layers, and every test fixture — for an ask the additive option satisfies just as well.

**Tradeoff:** two color concepts coexist (`accentColor`, always set; `customColorHex`, the override). **Every "what color is this habit" call site must read the computed `tintColor` accessor, never `accentColor.color` directly**, or an active custom color is silently ignored.

## ADR-011 — Emoji icons via a text field and the system keyboard
**2026-07-29 · Constrains: `IconPickerView`**

**Chose a constrained text field relying on iOS's own emoji keyboard** over a curated emoji grid, selected by the user via `AskUserQuestion`. It gives access to every Apple emoji with zero curation or yearly upkeep, and matches how Notes/Notion/Reminders solve the same problem. A curated grid would always be a strict subset needing maintenance.

**Tradeoff:** no in-app visual browsing — the user must reach for the system keyboard. Acceptable; it mirrors standard iOS conventions. Don't re-litigate this without a new reason.

## ADR-010 — Quantifiable habits are `Int`, single-occurrence only
**2026-07-24 · Constrains: `Habit.targetValue`, `Completion.value`, `CompletionService.isCompleted`**

**Chose `Int` targets on single-occurrence (Custom) habits only**, over `Double` targets or allowing them on multi-occurrence habits. `Int` matches the existing `timesPerWeekTarget: Int` precedent and avoids floating-point threshold comparisons; every realistic use case (glasses, minutes, pages, steps) is whole numbers. Restricting to single-occurrence habits keeps "reached target" unambiguous — a numeric target doesn't map cleanly onto "5 prayers."

**Tradeoff:** no fractional targets, no numeric tracking on Prayer-style habits. Both out of scope for the feature's actual purpose.

**Load-bearing detail:** making `CompletionService.isCompleted` threshold-aware was the *only* change required — every consumer already called through it rather than re-implementing "is this done," so the new semantics propagated for free. This is ADR-002's payoff in practice.

## ADR-009 — Streak Shields are habit-day granularity, and excluded from weekly-target habits
**2026-07-24, reconfirmed 2026-07-31 · Constrains: `Shield`, `StreakService`, `Frequency.supportsShields`**

**Chose a `Shield` model at habit+day granularity** with no occurrence reference. The requirement ("vacation/illness — don't reset a streak to zero") never called for occurrence-level granularity, and it's simpler to reason about inside already-tested streak logic. Revisited and reconfirmed for the dashboard quick-action in ADR-013.

**Excluded from `.timesPerWeek` habits** deliberately: a weekly-target streak is already forgiving, and shielding one would require inventing ambiguous semantics — does a shield count as a free completion, or reduce the effective target? — that nothing asked for.

**Reconfirmed 2026-07-31:** a request to enable Shields for the Gym preset (which defaults to `.timesPerWeek`) surfaced this exclusion again. Rather than silently extending shield semantics, the conflict was surfaced via `AskUserQuestion`; the user chose to leave the scoping untouched. No code changed.

## ADR-007 — Smart Reminders don't try to be "live"
**2026-07-23 · Constrains: `NotificationService`**

A local notification scheduled ahead of time can't know at fire time whether its habit has since been completed.

**Chose to make content "fresh as of the last reschedule"** and reschedule often enough that staleness is rare, rather than build a Notification Service Extension. `NotificationService.rescheduleAll` already runs on launch, every foreground, and every habit edit; as long as the user opens the app once during the day — safe for a habit tracker they're using — the evening nudge is recomputed against real state. An extension is the same category of scope jump as Widgets, for a gap that's narrow (complete a habit, background the app, never reopen before 8pm) and low-stakes (one redundant gentle nudge).

**Tradeoff:** that narrow gap is real and accepted, documented rather than glossed over.

## ADR-006 — Biometric lock re-locks on every background→foreground
**2026-07-23 · Constrains: `AnchorApp` root branch, `AuthenticationService`**

**Chose re-locking on every background→foreground transition** over cold launch only, matching the standard pattern in banking apps and password managers. The extra friction (a quick app-switch re-triggers Face ID) is deliberate — it's the point of the feature, not a bug to file.

## ADR-003 — XcodeGen signing config must live in `project.yml`
**2026-07-23 · Constrains: `project.yml` — protected, do not remove**

Deploying to a physical device failed with "Signing for 'Anchor' requires a development team" even after setting the team through Xcode's Signing & Capabilities GUI. **Root cause:** `xcodegen generate` regenerates the entire `.xcodeproj` from `project.yml` on every run, silently wiping anything set only through the GUI.

**Decision:** `CODE_SIGN_STYLE: Automatic` and `DEVELOPMENT_TEAM: X264QUS42N` live permanently in `project.yml`'s `settings.base`. The team ID is specific to the developer's Apple ID and would need updating if the project changed hands.

## ADR-002 — `CompletionService` is the single choke point for completion state
**Established at initial scaffold, 2026-07-23 · Load-bearing for every feature since**

Many parts of the app need to know "is this occurrence/habit done" — streaks, insights, notifications, the heatmap. If each re-implements its own check, new completion semantics mean finding and updating every one.

**Decision:** every consumer calls through `CompletionService.isCompleted(occurrence:on:)` / `isFullyCompleted(habit:on:)` rather than querying `Completion` records directly. Verified by repo-wide grep across multiple features that zero call sites bypass it.

This is what made Quantifiable Logging (ADR-010) safe to build by changing one method instead of ~15 call sites — a demonstrated payoff, not a theoretical one. `../CLAUDE.md` protects it explicitly: any new feature needing completion state calls through these methods, never duplicates the logic.

## ADR-001 — MVVM + DI, `View → ViewModel → Service → SwiftData`, one direction
**Initial scaffold, 2026-07-23 · Constrains: everything**

The foundational pattern, chosen as standard and well-understood over anything more novel. Ten-plus major features have since fit it without an architecture change. Full dependency graph and layer responsibilities in `ARCHITECTURE.md`.
