# Tasks: add-weekly-digest

## 1. Core digest logic (TDD)

- [x] 1.1 Failing tests for `WeeklyDigest`: compute (normal/first/empty week, boundary half-open windows, top-category tie-break), message wording (down/up/same/first-week), nextFireDate (midweek, Sunday before/after 18:00, time zone via injected calendar)
- [x] 1.2 Implement `WeeklyDigest` in SpendthriftCore until green (`swift test`)

## 2. App integration

- [x] 2.1 `DigestPreferences` (App Group UserDefaults, default off) + `DigestScheduler` (UserNotifications: refresh/replace pending request with stable id, remove when disabled/empty)
- [x] 2.2 Refresh hooks: app foreground (scenePhase), in-app expense save, voice-intent save
- [x] 2.3 "Weekly digest" toggle section in InsightsView with authorization request and denied-reverts-off behavior
- [x] 2.4 xcodegen regen, commit project

## 3. Tests

- [x] 3.1 Store/scheduler-level tests where UN framework allows (preferences default, digest request content building); UI test asserting the Insights toggle exists

## 4. Gate & ship

- [x] 4.1 Full simulator suite green
- [x] 4.2 `openspec validate add-weekly-digest --strict` passes
- [x] 4.3 Execution-verified multi-agent review, fix findings, PR, merge, cleanup
