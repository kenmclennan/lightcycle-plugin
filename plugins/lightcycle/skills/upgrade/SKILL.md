---
name: upgrade
description: Bring an already-set-up machine up to date after the lightcycle engine upgraded - the guided walk through what `lc upgrade` left for the operator. Use this when the SessionStart hook says the engine version changed, when `lc doctor` reports upgrade findings (a blank required config key, an outdated guidance conventions version, non-conforming guidance entries), or when someone says "I just upgraded lightcycle" / "bring my machine up to date". It is not first-time onboarding - that is `setup`.
---

# Upgrade a lightcycle machine

An engine upgrade replaces the program but leaves operator-owned state as it was: a new required config key is appended blank, and the guidance repo keeps the conventions it was created with. `lc doctor` reports each such leftover as an **upgrade finding**, reported only, never fixed. This skill walks them with the human and clears them. No emdashes.

**Nothing changes without the human's word.** Read and report freely; before writing a config value, opening a PR or filing an item, say what you will do and wait for a yes. Never invent a config value - ask.

## 1. Read the findings

Run `lc doctor --json`. It prints `{category: [finding, ...]}`; each finding has `category` and `message`, and an upgrade finding also has a stable `kind` and a `fix`. Keep the findings that carry a `kind`: those are this skill's. Any other finding is ordinary health (a stale pin, an orphan, a missing facet page) - report it, but it is not an upgrade finding; point at `driver` for pins and bookkeeping.

If no finding carries a `kind`, say the machine is already current and stop.

Walk the findings one at a time, in the order below, using each finding's own `fix` text as the starting point. If `lc doctor --json` shows a `kind` this skill does not list, read its `message` and `fix` to the human and ask how to proceed - do not guess.

## 2. `config-key-blank` - ask, then set

The finding names the key and what it does. Explain it in a sentence, ask the human for the value, confirm it back, then write it as a `key: value` line in the config file (`~/.lightcycle/config`, or `$LC_CONFIG`) - editing the file directly avoids the `lc config --edit` editor hop, which you cannot drive. Check it with `lc config`.

For `trusted-authors` (the GitHub logins whose PR comments the pool acts on; blank, it acts on none) follow the `setup` skill's "Trusted authors" section: the human's own login, then teammates and review bots, set in the config file only.

## 3. `guidance-conventions-outdated` - file a guidance-entry item

The guidance repo's `CONVENTIONS.md` records an older conventions version than the engine ships. Do not hand-make a guidance PR: the update is filed as a `guidance-entry` item (section 5) and the pipeline opens the PR. Find the repo with `lc guidance-dir`. The brief says to bring `CONVENTIONS.md` to the engine's current conventions; until `lc guidance-conventions` (LC-1086) lands, it cites the engine's `guidance/conventions.py` as the source. One item may carry both this update and the backfill in section 4.

## 4. `guidance-entries-nonconforming` - file a backfill

The finding counts the entries on the guidance repo's default branch that fail the current conventions (for example no `purpose`, `when` or `why`) and names the first few. Several entries are one backfill, not one item each. When both findings are present, file one item that carries the conventions update and then the backfill, so the backfill is written against the current rules.

## 5. Filing the item

A conventions update or data backfill is filed as an item, never done by hand in the repo. Follow the `driver` skill's filing rules: `lc search` for a duplicate first, then `lc new item "<title>" --workflow lightcycle/guidance-entry --repo guidance --project <the operator's own project> --description "<brief>"`. `--repo guidance` is the built-in repo name `lc project list` shows, and `--project` is the operator's own project (never `guidance`). Confirm the workflow origin with `lc workflow list`. The brief names the failing files and what each is missing, and the conventions update when section 3 applies. Agree the workflow, the project and whether to activate it now with the human before filing.

## 6. Confirm

Once the human has done or deferred each finding, re-run `lc doctor --json`. A config value clears at once; a PR or backfill item clears only after it merges, so say which findings remain and why. Success means no finding with a `kind` is left, or the remaining ones are named as waiting on a PR or item. Finish by pointing at `driver` to continue working.

## Boundary

This skill brings an existing machine current; first-time onboarding (prerequisites, directories, registering repos, starting the pool) is `setup`. It does not drive items through the pipeline - that is `driver` - and it does not fix ordinary `lc doctor` health problems.
