---
name: review-workflow-bundle
description: Review a whole lightcycle workflow bundle on demand against the engine's own audit criteria, and report findings with file and line. Use this when a maintainer of the official workflows, or anyone authoring their own, wants the bundle read end to end - "review this workflow bundle", "audit my workflows", "check my steps for drift". It creates nothing by default, so it works without lightcycle's backlog. It is not `author-workflow` (co-designing a new workflow) and not the `review-workflow` step (one PR's diff).
---

# Review a workflow bundle

Read every step and workflow file in a bundle against the engine's criteria, and report what you find in the conversation. The criteria belong to the engine and cover any bundle, official or third-party. This skill never carries its own copy, so it cannot drift from the engine's text.

## 1. Read the criteria

Run `lc audit-criteria workflows` and read its whole output. That output is the only source of criteria: do not restate them from memory, add your own, or paraphrase them into the report beyond naming the criterion a finding falls under. If the command is missing, the engine is older than the criteria - tell the human to run `lc upgrade` and stop.

Mechanical checks belong to `lc workflow check`. Always run `lc workflow check --dir <bundle>`, as the criteria's own Setup says, then spend this skill's effort on judgement.

## 2. Find the bundle

- If the human gave a path to a working copy, use it.
- Otherwise run `lc workflow list`. It names each origin, its pinned version, and whether the origin is writable. Ask which origin and bundle to review when more than one fits.
- With no path given, read the installed pinned bundle itself, at `<home>/workflows/<origin>/<sha>/`, the location `lc audit-criteria workflows` names. Do not ask for a working copy or clone for a version that is installed.
- Ask for a working copy, or clone the origin read-only into a fresh empty directory, only when the human wants a version that is not installed. Never review from a checkout you might edit by accident.

## 3. Read the bundle

Read every workflow file and every step file in the bundle, in full, plus every `fragments/*.md` and the origin's shared-block manifest if it has one. Judge included text where it is included, and flag an origin fragment that shares an engine fragment's name as dead, since the engine's fragment wins. Judge each criterion against what the files say. Steps are shared between workflows, so a finding that depends on a workflow's own stages is judged per workflow, not per file.

Read for intent. A threshold hit is a signal to read closer, and a deliberate, noted copy is not a defect. Say so when you leave something alone, if the criteria name that case.

## Scripts and lifecycle hooks

When the bundle has a `scripts/` tree, a `script:` stage, a `guard: script:` schedule or a `lifecycle:` block, read each script in full as well. The criteria cover steps and workflow files, so judge these against the engine's script contract (`docs/ontology.md`, "script contract" and "lifecycle hook"; `lc workflow check --dir <bundle>` covers the mechanical part: paths under `scripts/`, executable, declared outcomes, a fixture for each script):

- **Tests.** Each script has a test under `scripts/tests/`, and the bundle's CI runs them. Neither `check` nor `simulate` does.
- **Writes only to the data directory.** The script runs with the data directory as its working directory. Flag any write elsewhere: an absolute path, `~`, the bundle directory, or a git worktree the stage did not declare.
- **No secrets.** No token, password or key in a script, a fixture, a `config-example` value or a test. Secrets belong in the operator's `workflow-<origin>-<name>:` config block, read from the `LC_WORKFLOW_CONFIG_<KEY>` environment variable.
- **Every outcome reachable in simulate.** Each outcome the stage declares has an entry in the script's fixture (`scripts/fixtures/<path after scripts/>.json`; a guard's keys are `pass` and `fail`), and the script can print each one. Flag a declared outcome no code path produces.
- **Idempotent.** Delivery is at-least-once, and hooks must be safe to run twice.

## 4. Report

Report each finding in the conversation, most serious first:

- the file and line (`path:line`), and the quoted text;
- the criterion it falls under, by the engine's own name for it;
- why it is a problem, in a sentence;
- a suggested fix, when one is clear.

Close with what you checked and could not judge. Say plainly when a criterion needed context you did not have.

**By default, create nothing**: no files, issues, items or PRs. The report is the output.

## 5. Offer to file, only for a writable origin

Only when `lc workflow list` marks the bundle's origin writable on this machine, offer to draft an issue or item for each finding. Show each draft to the human and file it only after they approve that draft. Never file in bulk, and never file for an origin that is not writable - report those findings and leave routing to the human.
