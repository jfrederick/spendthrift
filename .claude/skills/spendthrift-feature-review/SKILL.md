---
name: spendthrift-feature-review
description: Execution-verified multi-agent review for a Spendthrift feature branch before its PR. Use after the full simulator gate passes and before creating any pull request in this repo.
---

# Execution-verified feature review

Pre-PR review process for this repo. It caught 6 real parser bugs on its
first run (PR #8) — the yield comes from (a) diverse finder angles and
(b) refusing to trust any "bug" claim until it is reproduced by execution.

## When

After: OpenSpec change valid (`--strict`), core `swift test` green, full
simulator gate green, work committed on the feature branch in its worktree.
Before: `gh pr create`.

## Phase 1 — 8 finder angles, in parallel, one message

Spawn 8 subagents (Agent tool, single message so they run concurrently).
Each gets: the worktree path, `git diff main...HEAD` as scope, the domain
rules (Int whole dollars 1...99999, normalize() for all matching, "Other"
always exists, logic belongs in SpendthriftCore), and returns up to 6
candidates as JSON `{file, line, summary, failure_scenario}`.

Match model/effort to angle difficulty:

| Angle | What it hunts | Model/effort |
|---|---|---|
| A line-by-line | trace concrete inputs through every hunk by hand | strongest available |
| B removed-behavior | invariants deleted/replaced lines used to enforce | small |
| C cross-file tracer | callers/callees, target membership (project.pbxproj!), API drift vs widget/app twins | mid, high effort |
| Reuse | re-implemented helpers (DescriptionRules, Normalize, CategoryRules…) | mid, low |
| Simplification | derivable state, copy-paste, dead grammar | mid, low |
| Efficiency | repeated I/O, container-per-call, quadratic scans (flag only if real at personal-app scale) | mid, low |
| Altitude | policy duplicated across entry paths (app/widget/voice) instead of one ExpenseStore/Core function | mid, medium |
| Conventions | CLAUDE.md rule violations, quoted rule + line | small |

Prompt finders to pass through every candidate with a nameable failure
scenario — self-censoring finders are the main source of misses.

## Phase 2 — verify by EXECUTION, not judgment

For every pure-logic claim (SpendthriftCore): write a throwaway test file
(`Tests/SpendthriftCoreTests/VerifyScratch.swift`) that feeds the exact
claimed inputs to the real code and prints actual outputs; run
`swift test --filter VerifyScratch`; delete the file. A claim is CONFIRMED
only by its printed output. For store/UI claims, verify by reading the code
path end-to-end (or an in-memory-container test if cheap). Judgment-only
verification is how plausible-but-wrong findings survive.

## Phase 3 — report, fix, re-gate

1. Report survivors with ReportFindings (verdicts CONFIRMED/PLAUSIBLE),
   ranked by severity.
2. Fix confirmed correctness bugs and cheap high-value cleanups; skip
   style-only findings. Extend the OpenSpec delta spec when grammar or
   behavior legitimately grows (scenarios for each fixed bug).
3. Add a regression test per fixed bug.
4. Re-run: core `swift test`, full simulator gate, `openspec validate --strict`.
5. Commit fixes as a separate "Fix <feature> bugs found in code review"
   commit so the PR shows the review trail; note findings count in PR body.

## Known flake

The first `xcodebuild test` run immediately after `xcodegen` regenerates
the project has failed transiently twice (stale incremental state); re-run
once before debugging a red gate.

## Known refutation patterns (don't re-report)

- "Logic should move to SpendthriftCore" is refuted when it requires
  SwiftData/ExpenseStore — only the pure part belongs in Core.
- Double-fetch of a LabelMapping key (resolve + upsertMapping) is known,
  accepted at this app's scale.
