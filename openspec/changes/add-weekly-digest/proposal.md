# Proposal: add-weekly-digest

## Why

Logged data should pay the user back without being asked. A Sunday-evening local notification — "You spent $214 this week, mostly on Food & Drink, down $32 from last week" — closes the loop on the logging habit with zero effort, entirely on-device.

## What Changes

- A weekly local notification, delivered Sundays at 18:00 local time, summarizing the trailing 7 days: total spent, top category, and the delta versus the prior 7 days.
- Digest math and message wording are pure logic in `SpendthriftCore` (`WeeklyDigest`): rolling 7-day window ending at the fire date, top-category selection, delta phrasing, and next-fire-date computation (locale-independent fixed weekday).
- A "Weekly digest" toggle on the Insights screen enables the feature; turning it on requests notification permission. The preference lives in the App Group `UserDefaults` (default off).
- Because local notification content is fixed at scheduling time, the pending notification is re-computed and re-scheduled (single stable identifier) whenever fresh data or a fresh chance arises in the app process: app foreground, in-app expense save, and voice-intent save. Widget-extension writes are picked up at the next app open — documented staleness bound.
- No expense is required for delivery: a week with no spending schedules no digest (nothing to say beats a $0 notification).

## Capabilities

### New Capabilities

- `weekly-digest`: rolling-week summary computation, digest notification scheduling/rescheduling, opt-in toggle with permission request.

### Modified Capabilities

<!-- none: additive; totals/insights/entry requirements unchanged -->

## Impact

- New pure logic + tests in `SpendthriftCore` (no dependencies).
- App target: `DigestScheduler` (UserNotifications), refresh hooks in app lifecycle and save paths, a toggle section in `InsightsView`.
- No schema changes, no new targets, no entitlement changes (local notifications need no entitlement; permission is runtime).
- `project.yml` regenerated via xcodegen for the new files.
