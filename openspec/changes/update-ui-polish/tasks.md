# Tasks: update-ui-polish

## 1. Tap targets

- [x] 1.1 EntryView Next/Save: move sizing/background styling into the button label and add a matching content shape so the whole rounded rectangle is tappable
- [x] 1.2 Category confirmation area: whole area is one button opening the picker; background matches the app background (hairline outline, no gray fill)

## 2. Post-save navigation

- [x] 2.1 Replace the root `TabView` with a horizontal pager (both screens stay alive, preserving in-progress entry state) plus a custom bottom tab bar with `tab-entry`/`tab-totals` identifiers
- [x] 2.2 On save, EntryView notifies the root, which slides to Totals with animation and shows the transient checkmark confirmation over Totals; entry resets behind the navigation
- [x] 2.3 Keep the `spendthrift://entry` deep link selecting the Entry screen

## 3. Category filter on the period expense list

- [x] 3.1 Toolbar filter menu in ExpenseListView listing "All Categories" plus categories present in the period; selection filters the grouped list
- [x] 3.2 Empty-state text when the active filter matches no expenses

## 4. Tests

- [x] 4.1 Update UI tests: tab switches use the custom bar identifiers; post-save flow lands on Totals; seeded data gains Transport $5 today (today's seeded total 20 → 25, full-flow assertion 35 → 40)
- [x] 4.2 New UI test: drill into today, filter to Transport, see only the Transport expense, reset to All Categories
- [x] 4.3 Full simulator gate passes
