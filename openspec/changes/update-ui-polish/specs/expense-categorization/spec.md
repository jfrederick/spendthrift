# expense-categorization

## MODIFIED Requirements

### Requirement: Category suggestion for new descriptions
When a description has no remembered category, the app SHALL suggest the most likely category using on-device heuristics (e.g., keyword and token similarity to remembered descriptions), and SHALL require the user to confirm or change it before the expense is saved. Confirming SHALL record the description→category mapping. The inline category confirmation area SHALL open the category picker when tapped anywhere within its bounds, and its background SHALL match the app background (no distinct gray fill).

#### Scenario: New description prompts with a suggestion
- **WHEN** the user enters the never-before-seen description "tacos"
- **THEN** a category picker is shown with a single suggested category preselected

#### Scenario: One-tap confirm
- **WHEN** the suggestion is shown and the user taps Save/Confirm
- **THEN** the expense is saved with the suggested category
- **AND** the mapping "tacos" → that category is remembered

#### Scenario: Override the suggestion
- **WHEN** the suggestion is "Shopping" but the user selects "Groceries" instead
- **THEN** the expense is saved with "Groceries" and "Groceries" is remembered for that description

#### Scenario: No confident suggestion falls back to Other
- **WHEN** no heuristic produces a confident match for a new description
- **THEN** the picker is shown with "Other" preselected

#### Scenario: Whole confirmation area opens the picker
- **WHEN** the category confirmation area is visible and the user taps anywhere on it (not just the "Change" label)
- **THEN** the category picker opens
