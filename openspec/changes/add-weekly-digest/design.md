# Design: add-weekly-digest

## Context

All data is on-device; there is no server to push a computed summary. iOS local notifications carry content fixed at scheduling time, so "this week's total" must be computed before delivery and refreshed as data changes. Expense writes happen in three processes: the app (keypad, voice intent — App Intents in the app target run in the app process), and the widget extension (quick-log intent).

## Goals / Non-Goals

**Goals:**
- One weekly notification with total, top category, and week-over-week delta; on-device only.
- All computation and wording in `SpendthriftCore`, deterministic and unit-tested.
- Opt-in (default off), permission requested only when the user flips the toggle.

**Non-Goals:**
- Perfect freshness for widget-extension writes (picked up on next app open; the digest is a summary, not a ledger).
- Notification actions/deep links beyond default app open; digest customization (day/time); push infrastructure.

## Decisions

- **D1: Rolling 7-day window ending at the fire instant, not calendar weeks.** `Calendar.current` week starts vary by locale (a US week starts Sunday, so "this calendar week" at Sunday 18:00 would be ~18 hours of data). A trailing window means the Sunday digest always covers the full past week and the comparison window (the 7 days before that) is symmetric. Alternative rejected: locale week-start with fire-at-week-end — inconsistent day-of-week and confusing comparisons.
- **D2: Fixed fire time — Sunday 18:00 local, `WeeklyDigest.nextFireDate(after:calendar:)`.** Sunday evening is the natural "week wrap-up" moment and matches the product idea. Computed in Core so it's testable; uses the passed calendar/time zone.
- **D3: Reschedule-on-write.** `DigestScheduler.refresh(store:)` recomputes the digest for the upcoming fire date and replaces the pending request (stable identifier `weekly-digest`). Called on app foreground, after in-app saves, and after voice-intent saves. This keeps content as fresh as the last write from the app process without background tasks. Alternative rejected: `BGAppRefreshTask` — nondeterministic scheduling, more moving parts, still can't cover widget writes reliably.
- **D4: Preference in App Group `UserDefaults` (`digestEnabled`, default false).** Read/write via a small `DigestPreferences` wrapper so the widget process could read it later. Toggle lives on the Insights screen (the app's "reflection" surface); enabling requests `.alert + .sound` authorization and flips back off if denied.
- **D5: No digest without data.** If the trailing window has no expenses, `WeeklyDigest.compute` returns nil and any pending request is removed — a $0 notification is noise. Delta phrasing handles a zero prior week ("first week tracked" wording) without division.
- **D6: Amounts stay whole-dollar Ints** in all digest math and strings (`$214`), per domain rules.

## Risks / Trade-offs

- [User logs only via widget for a whole week → digest content stale or missing] → acceptable v1 bound, documented; every app open (including Siri logging) refreshes. Future: move scheduling into shared Models code if extension-side scheduling proves reliable.
- [Notification permission denied] → toggle reverts to off; no repeated prompting (system handles subsequent requests via Settings).
- [Time zone changes between scheduling and fire] → `UNCalendarNotificationTrigger` with current-calendar components; next refresh corrects any drift.

## Open Questions

None blocking.
