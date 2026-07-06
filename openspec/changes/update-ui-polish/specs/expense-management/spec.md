# expense-management

## ADDED Requirements

### Requirement: Filtering the expense list by category
The period expense list (day, week, or month drill-in) SHALL offer a category filter listing the categories present in that period's expenses plus an "All Categories" option. Selecting a category SHALL show only that category's expenses (matched via normalize()), keeping the day grouping; selecting "All Categories" SHALL restore the full list. The filter SHALL default to all categories on entry. An active filter whose category no longer has expenses in the period SHALL remain listed and selected so it can be seen and cleared.

#### Scenario: Filter to one category
- **WHEN** today's list contains a $20 Food & Drink expense and a $5 Transport expense and the user filters to Transport
- **THEN** only the $5 Transport expense is listed

#### Scenario: Reset the filter
- **WHEN** a category filter is active and the user selects "All Categories"
- **THEN** the full period list is shown again

#### Scenario: Filtered list emptied by deletion
- **WHEN** the only expense matching the active filter is deleted
- **THEN** the list shows an empty state rather than falling back to unfiltered results
