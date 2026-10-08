# CollegeOS changelog

## Unreleased

- Turned the bottom navigation back into a floating dock: the strip keeps a 16 px margin from the screen edges and 12 px above the system inset, and paints a 24-sigma backdrop blur under a white 8 % fill (75 % on light) with one soft shadow and a hairline rim at radius 28.
- Replaced the sliding selection capsule with the mockup's minimal active state: the chosen destination shows a cobalt icon, a cobalt label and a 4 px cobalt dot, with the dot's slot reserved so no label ever moves.
- Animated only the newly selected icon: a 240 ms 1.0 → 1.10 → 1.04 pop with a 2.5 px lift, an outline-to-filled cross-fade, and a dot that scales in over 150 ms. Reduced motion collapses all of it and leaves the glass itself unchanged.
- Replaced the Timetable day selector with a rounded day bar: one strip one surface step above the canvas holds the Mon–Sat pills, the selected day is a solid cobalt pill, and the per-day class counts moved to the day heading below.
- Replaced the page slide+fade with an optimized transition: pushed pages appear instantly and popped pages fade out completely, with the first route and reduced motion still skipping the animation entirely.
- Exported the missing v11–v13 drift schema snapshots and regenerated the migration verifier so `make-migrations` runs again and migration tests cover the current schema version; fixed the v12→v13 stacked upgrade adding `last_indexed_page` twice.
- Replaced the floating pill dock with a full-width bottom navigation bar: every destination keeps its icon and label at any width, and selection slides a single indicator between equal slots.
- Made Notes a destination, covering per-subject material plus a search screen over every indexed PDF; a search shortcut sits above the bar on Home and Tasks.
- Moved Settings out of the bar into a header action on every destination, pushed over the shell so it keeps a back button. Pushed screens now show a back button too.
- Wrapped crowded header actions instead of overflowing them on a compact phone at a large text scale.
- Kept reduced-motion behavior: the bar's indicator, icon and label animations collapse to zero duration and the short page move is skipped.
- Turned the bar's selected indicator into a soft rounded rectangle and nudged it clear of the bar's own rounded ends. A pill radius clamped to half a tab's slot width, which is narrower than the bar is tall, so it painted an ellipse that read wrong at the first and last destinations.
- Added AI note search: a natural-language question is answered from the user's own indexed PDF pages, with page references that are validated locally before display.
- Kept AI strictly additive — keyword search still runs entirely offline, and no request is made without a configured key or retrieved context.
- Moved the Gemini credential out of the request URL into the `x-goog-api-key` header and isolated it behind `GeminiConfig`, so a backend proxy can replace direct API access later.
- Made AI retrieval build an OR'd FTS5 expression, since the keyword AND expression matched nothing for full-sentence questions.
- Added a Skip days mode to the attendance planner: choose the dates you plan to miss and see the classes each one costs, the resulting overall attendance next to every affected subject's, and which already-marked classes the plan leaves alone.
- Kept the planner's class-counts mode unchanged and scoped to one subject, and stopped it from subscribing to the timetable it never reads.
- Replaced the multi-hue accent system with a single Electric Cobalt accent: `FeatureColors` now resolves every feature to `#2563EB` in light mode and to the same hue one lightness step up in dark mode, so features no longer own colours. Green, amber and red are reserved for state through `AppSemanticColors`.
- Let progress rings and bars take a status color: attendance indicators now read green when on target, amber when fragile, and red when below, on Home, subject cards, and the planner.
- Removed the blurred glass panel from the navigation dock in favour of a solid surface with one soft shadow: the selected pill is a flat low-opacity cobalt fill with no gradient, border or landing glow. The spring indicator, icon bounce, label slide, hide-on-scroll and reduced-motion behaviour are unchanged.
- Added explicit divider tokens (white/5 on dark, a whisper of neutral black on light) so grouped rows separate with a barely-visible line instead of an outline, and removed the unused cobalt wash gradient helper.
- Added distinctive primary and secondary section headers to Home in place of the uniform icon-plus-title rows, and grouped related sections tighter than the hero areas.
- Replaced hardcoded navy logo plates on Home and Settings with a theme-derived brand tint, and gave cards quieter depth shadows in both modes.

## 1.10.0+30 — 6 September 2026

- Added a local pending-attendance reminder after the next eligible day's final class, refreshed as attendance and schedules change.
- Added Home's weekly attendance summary with prior-week comparison, missed/unmarked classes, and below-target subjects.
- Added atomic, conflict-aware Undo for individual and bulk attendance marking; fixed duplicate inserts when editing manual historical sessions.
- Added selected dock labels and short, reduced-motion-aware page switching while retaining tab state.
- Reduced duplicate daily projections in attendance reports.
- Preserved schema 8, backup format 1, and offline-only operation.

## 1.9.3+29 — 4 September 2026

- Fixed release-only notification initialization failures caused by Android resource shrinking removing the dynamically resolved `ic_notification` drawable.
- Added an explicit resource-retention rule and regression test for the monochrome notification icon.
- Preserved schema-v8 data and backup-format-v1 compatibility.

## 1.9.2+28 — 4 September 2026

- Replaced the unreliable OEM-only notification permission probe with native Android runtime-permission, app, and channel diagnostics.
- Migrated reminders to a fresh maximum-importance `collegeos_reminders_v4` channel so a stale or damaged legacy channel cannot suppress new reminders.
- Added Android precise-alarm access for time-critical reminders and retained an inexact idle-safe fallback when the user does not grant it.
- Added direct, temporary notification diagnostics actions for precise-reminder access, battery settings, channel settings, and immediate delivery testing.
- Declared only the required local notification, exact-alarm, and reboot-rescheduling permissions; CollegeOS remains fully offline with no service or network permission.
- Preserved schema-v8 data and backup-format-v1 compatibility.

## 1.9.1+27 — 30 August 2026

- Removed the dock's broad moving color shade and colored glow shadows for a cleaner translucent finish.
- Removed full-screen opacity, translation, and scale work during bottom-navigation switching.
- Kept lightweight selected-icon motion and preserved every tab's navigation state.
- Preserved schema-v8 data and backup-format-v1 compatibility.

## 1.9.0+26 — 30 August 2026

- Added the student's local display name to first-time setup, College Information editing, Settings profile context, and the Home greeting.
- Added a tested Drift schema-v8 migration that preserves existing installs and defaults the new name field safely.
- Added an Export Data chooser for full `.collegeos` backups or readable attendance CSV reports; full backups continue to include every attendance record.
- Rebuilt the navigation dock as a true page overlay with a soft shade that follows the selected destination and removed the fixed under-dock page strip.
- Tightened timetable subject-color glows into a restrained two-layer rail effect.
- Preserved offline-only operation and backup-format-v1 compatibility, including imports from pre-v8 backups.

## 1.7.3+21 — 23 August 2026

- Reduced monthly calendar height with tighter six-week rows and header spacing.
- Made primary pages consume the floating dock safe inset so content no longer passes behind the dock.
- Fixed reverse page transitions to fade out completely instead of snapping away at 82% opacity.
- Preserved schema v7, offline data, and backup-format-v1 compatibility.

## 1.7.2+20 — 22 August 2026

- Removed full-screen scale and slide rasterization from normal pushed-page transitions while retaining a quick fade.
- Reused the already-active attendance snapshot when opening Analytics instead of starting a duplicate five-table Drift stream.
- Cached the subject and pending-attendance projections used by Attendance so the Planner opens without repeating them.
- Isolated percentage-ring glow into a static cached paint layer; only the inexpensive crisp arc animates.
- Preserved schema v7, offline data, and backup-format-v1 compatibility.

## 1.7.1+19 — 22 August 2026

- Added soft subject-colour glows to timetable accent rails.
- Replaced the analytics ring's broad halo with a focused gradient arc glow.
- Added shared bottom content clearance so cards and controls scroll above the floating glass dock.
- Verified the updated presentation at 360, 390, 412, and 430 logical-pixel widths.
- Preserved schema v7, offline data, and backup-format-v1 compatibility.

## 1.7.0+18 — 22 August 2026

- Added a read-only what-if Attendance Planner using the exact existing attendance calculator.
- Upgraded Pending Attendance with an at-a-glance inbox and faster, safer day review actions.
- Added one-day timetable exceptions for extra and cancelled classes without changing recurring history.
- Added present streaks, perfect-day insights, and a responsive widget attendance progress view.
- Improved screen-reader labels, large-text resilience, touch targets, and Android reduced-motion behavior.
- Preserved schema v7, offline data, and backup-format-v1 compatibility.

## 1.6.4+17 — 21 August 2026

- Starts the splash video before Riverpod, routing, and database-backed screens initialize.
- Preloads the routed screen behind the playing video and begins the 300 ms crossfade before the final frame.
- Removes the video's black tail and normalizes it to a smaller, fast-start 30 FPS H.264 asset.
- Preserved onboarding routing, offline data, database schema, and backup compatibility.

## 1.6.3+16 — 21 August 2026

- Replaced the generated startup animation with the bundled CollegeOS MP4 splash.
- Plays the splash once, muted and full-screen, then crossfades into the existing onboarding or Home route.
- Keeps a navy initialization background, removes the video overlay after completion, and releases the video controller.
- Preserved all offline data, application functionality, database schema, and backup compatibility.

## 1.6.2+15 — 20 August 2026

- Simplified startup to a centered CollegeOS logo with a short fade, 0.75–1.05–1.0 scale settle, and restrained purple/cyan glow.
- Removed the loading label, percentage, progress bar, and spinner from the splash screen.
- Added a coordinated splash-out/content-in crossfade and guaranteed removal of the splash overlay after 1.7 seconds.
- Preserved onboarding and Home routing, local data, database schema, and backup compatibility.

## 1.6.1+14 — 19 August 2026

- Reworked startup into a smoother eased logo fade, scale, and upward-settle animation.
- Strengthened and stabilized the violet/blue/cyan glow behind the CollegeOS mark.
- Added a deliberate purple-glow loading bar with a live 0–100% indicator synchronized to the startup timeline.
- Preserved the native navy launch handoff, reduced-motion behavior, offline architecture, schema, and backup compatibility.

## 1.6.0+13 — 19 August 2026

- Added a polished 2.1-second CollegeOS startup sequence with the requested navy hold, 75–100% logo reveal, violet/cyan glow pulse, still frame, and fade into the routed app.
- Reuses the bundled transparent CollegeOS brand mark and renders the wordmark locally with no new dependency or network asset.
- Changed the native Android launch background to matching navy so startup no longer flashes white before Flutter draws.
- Added a shortened reduced-motion variant and focused tests for the animation timeline.
- Preserved all offline data, database schema, backup compatibility, and navigation behavior.

## 1.5.3+12 — 19 August 2026

- Fixed notification delivery on OEM Android builds that incorrectly report notifications as disabled even after the visible permission is granted.
- Explicit test notifications are now always handed to Android, and enabled task/exam reminder intent is scheduled without the unreliable OEM probe blocking it.
- Reconciliation no longer silently disables CollegeOS notifications because of a false platform status response.
- Added a direct shortcut to Android's exact College reminders channel settings for device-specific suppression controls.
- Rebuilt the navigation dock as a constrained translucent glass overlay with real backdrop blur and content visible beneath it.
- Made every selected navigation surface an exact 46px circle, removing the connected/pill-shaped end appearance.

## 1.5.2+11 — 19 August 2026

- Migrated reminders from the disabled legacy Android notification channel to a fresh high-importance CollegeOS reminder channel.
- Reconciles existing task and exam reminder intent onto the replacement channel without changing stored user data.
- Fixed permission detection to verify Android's final notification state even when an OEM returns a stale permission-request result.
- Removes the obsolete reminder channel after the replacement channel is ready.

## 1.5.1+10 — 18 August 2026

- Refined the bottom navigation into a floating, icon-only transparent glass capsule with an accessible compact selected bubble.
- Made local-notification initialization lazy, idempotent, and retryable so task and exam reminders can schedule reliably even before startup initialization completes.
- Added Android app-permission and reminder-channel checks instead of reporting notifications as enabled when the channel is blocked.
- Added an immediate test-notification action under Settings → Notifications and clear save-time feedback when Android cannot schedule a reminder.
- Preserved the offline-only architecture, database schema, backup format, and existing user data.

## 1.5.0+9 — 17 August 2026

- Added a dedicated Settings App Info view with the installed version and “Made By Tsp” credit.
- Hardened release error handling with a local recovery UI and safe asynchronous platform boundaries.
- Disposed automatic-backup subscriptions with the app and isolated optional home-widget failures.
- Made malformed local route IDs recover safely instead of throwing during navigation.
- Added a labelled Attendance Analytics action and a theme-aware semi-glass navigation dock.
- Streamlined Settings and compacted Attendance Analytics while preserving all existing data and backup compatibility.

## 1.4.2+8 — 16 August 2026

- Compacted the Attendance month calendar with fixed 44px rows so it no longer grows vertically on wider phones.
- Reduced calendar header, weekday, icon, padding, and selection footprint while retaining full-cell date interaction.
- Added a layout regression test that caps the complete six-week calendar at 360px tall.

## 1.4.1+7 — 16 August 2026

- Fixed the undersized Analytics attendance ring by giving it explicit responsive geometry.
- Rebuilt Analytics trend columns so one data point stays centered and narrow instead of filling the card.
- Added focused violet-blue gradients and glow to the overall ring, trend columns, and subject progress bars.

## 1.4.0+6 — 16 August 2026

- Introduced a focused violet (`#7367F0`) and blue (`#4F8CFF`) accent system.
- Added centralized lightweight gradients and glow tokens without changing the established layout.
- Added gradient attendance rings and bars, restrained title glow, an enhanced Next Class card, and a violet-blue selected navigation state.
- Preserved the offline architecture, database schema, and backup format.

## 1.3.1+5 — 16 August 2026

- Restored the established CollegeOS Material 3 interface and discontinued the experimental Stitch visual layer.
- Retained all offline data, attendance, timetable, tasks, reports, notifications, widget, and backup functionality without a schema or backup-format change.
- Returned to system typography, restrained violet accents, standard cards, native segmented controls, and the earlier compact timetable presentation.

## 1.3.0+4 — 15 August 2026

- Integrated all seven requested screens from Stitch project `12713860596305922463` into the existing Flutter presentation layer.
- Bundled the Stitch source screenshots, generated HTML, embedded imagery, and Inter/Geist fonts locally for offline use.
- Added reusable glass cards, gradient progress indicators, profile avatars, settings rows, entrance motion, and a sliding segmented control.
- Rebuilt the timetable around one continuous vertical timeline with aligned class markers.
- Refined the light and dark palettes around a focused violet-blue CollegeOS identity.
- Made primary screen headers and content spacing more compact on phone layouts.
- Restyled the bottom navigation dock with a subtle selected-icon halo while preserving reduced-motion behavior.
- Added a concise college identity card to Settings.
- Reworked whole-day attendance controls into equal, semantic action tiles for faster scanning.

## 1.2.0+3 — 15 August 2026

- Added reactive Month, Semester, and All-Time attendance analytics.
- Added weighted overall totals, period comparisons, trend charts, strongest/lowest subject insights, risk counts, and subject breakdowns.
- Added direct access from the Attendance screen while retaining the Settings shortcut.

## 1.1.0+2 — 15 August 2026

- Added the CollegeOS brand logo and adaptive Android launcher icon.
- Added next-class and attendance Android home-screen widget support.
- Added attendance forecasting for the result of attending or missing the next class.
- Improved Home risk detection to include subjects that will fall below target after one more absence.
- Added academic-calendar quick presets and local timetable-impact previews for holidays, vacations, and study leave.
- Holidays and college-closed dates now hide scheduled classes everywhere while preserving historical marks for undo.
- Retained the offline-only architecture, database schema 7, and backup format 1.

## 1.0.0+1

- Initial personal Android release.
