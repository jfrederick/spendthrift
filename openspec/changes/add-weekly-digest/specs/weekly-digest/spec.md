# weekly-digest

## ADDED Requirements

### Requirement: Weekly digest computation
The system SHALL provide pure logic in SpendthriftCore that, given expenses and a fire date, computes a digest for the trailing 7-day window ending at the fire date: total dollars spent, the top category by spend (ties broken by category name for determinism), and the delta versus the 7 days immediately before the window. It MUST return nil when the trailing window contains no expenses. All amounts are whole-dollar Ints.

#### Scenario: Normal week with prior data
- **WHEN** the trailing 7 days total $214 with Food & Drink highest, and the prior 7 days total $246
- **THEN** the digest reports total 214, top category "Food & Drink", and a delta of -32

#### Scenario: First tracked week
- **WHEN** the trailing 7 days have expenses but the prior 7 days have none
- **THEN** the digest reports the total and top category with no week-over-week comparison

#### Scenario: Empty week
- **WHEN** the trailing 7 days contain no expenses
- **THEN** no digest is produced

#### Scenario: Window boundaries
- **WHEN** an expense falls exactly 7 days before the fire date and another falls at the fire date
- **THEN** the 7-days-ago expense is in the prior window and the fire-date expense is in the trailing window (window is half-open: (fire-7d, fire])

### Requirement: Digest message wording
The system SHALL format the digest title and body in SpendthriftCore as deterministic strings: the body names the total (whole dollars, "$" prefix), the top category, and the week-over-week change as "up $N" / "down $N" / "same as" versus last week, or omits the comparison for a first tracked week.

#### Scenario: Down week
- **WHEN** the digest has total 214, top category "Food & Drink", delta -32
- **THEN** the body contains "$214", "Food & Drink", and "down $32"

#### Scenario: First week wording
- **WHEN** the digest has no prior-week comparison
- **THEN** the body contains the total and top category and no up/down phrase

### Requirement: Sunday evening delivery
The system SHALL compute the next fire date as the next Sunday at 18:00 in the user's current calendar/time zone (if now is Sunday before 18:00, today at 18:00), and SHALL schedule the digest as a local notification for that instant using a single stable request identifier so rescheduling replaces rather than accumulates.

#### Scenario: Midweek scheduling
- **WHEN** the next fire date is computed on a Wednesday
- **THEN** it is the coming Sunday at 18:00 local time

#### Scenario: Sunday before six
- **WHEN** the next fire date is computed on a Sunday at 17:00
- **THEN** it is that same Sunday at 18:00

#### Scenario: Sunday after six
- **WHEN** the next fire date is computed on a Sunday at 19:00
- **THEN** it is the following Sunday at 18:00

### Requirement: Reschedule on fresh data
The system SHALL recompute and replace the pending digest notification whenever the app process gains fresh data or control: app foreground, in-app expense save, and voice-intent save. When the digest is disabled or the trailing window is empty, any pending digest request MUST be removed.

#### Scenario: Save refreshes content
- **WHEN** the user logs an expense in the app while the digest is enabled
- **THEN** the pending digest request is replaced with content that includes the new expense

#### Scenario: Disabled removes pending
- **WHEN** the user turns the digest toggle off
- **THEN** the pending digest request is removed

### Requirement: Opt-in toggle with permission request
The system SHALL default the weekly digest to off, expose a "Weekly digest" toggle on the Insights screen, store the preference in the App Group UserDefaults, and request notification authorization when the toggle is turned on. If authorization is denied, the toggle MUST revert to off.

#### Scenario: Enabling requests permission
- **WHEN** the user turns the toggle on and grants permission
- **THEN** the preference is stored as enabled and a digest is scheduled (given data)

#### Scenario: Denied permission reverts
- **WHEN** the user turns the toggle on and denies permission
- **THEN** the preference remains disabled and the toggle shows off
