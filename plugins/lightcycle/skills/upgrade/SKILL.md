---
name: upgrade
description: Bring an already-set-up machine up to date after the lightcycle engine upgraded - the guided walk through what `lc upgrade` left for the operator. Use this when the SessionStart hook says the engine version changed, when `lc doctor` reports upgrade findings (a blank required config key, a scheduled workflow not enabled, an obsolete config key, an outdated guidance conventions version, non-conforming guidance entries, a reverted guidance entry), or when someone says "I just upgraded lightcycle" / "bring my machine up to date". It is not first-time onboarding - that is `setup`.
---

# Upgrade a lightcycle machine

An engine upgrade replaces the program but leaves operator-owned state as it was: a new required config key is appended blank, and the guidance repo keeps the conventions it was created with. `lc doctor` reports each such leftover as an **upgrade finding**, reported only, never fixed. This skill walks them with the human and clears them. No emdashes.

**Nothing changes without the human's word.** Read and report freely; before writing a config value, opening a PR or filing an item, say what you will do and wait for a yes. Never invent a config value - ask.

## 0. Stop the pool, upgrade, restart

A running pool keeps the old engine code until it is restarted, and a new engine may migrate the store under it. The SessionStart hook can run `lc upgrade` while a pool is up, so check `lc status`. If a pool is running, ask the human, then stop it with `lc stop --drain` (running work finishes, no new worker starts). The drain returns at once and the pool exits later, and `lc upgrade` refuses while the venv is in use, so wait until `lc status` shows no pool running before you run `lc upgrade`. Restart with `lc start --detach`: a foreground `lc start` blocks you. Say so if the pool is left on the old code.

## 0a. A blocked engine upgrade

If the SessionStart hook says `lc upgrade` did not complete, or `lc upgrade` exits 1 naming workflow origins, an installed workflow bundle's `requires-engine` excludes the new engine; restarting never clears it. Read the output: it names each blocking origin and its requirement. There are two routes, and the human picks:

- `lc workflow upgrade` for those origins, which pulls a bundle that fits the new engine. Then re-run `lc upgrade`.
- `lc upgrade --force` when no compatible bundle exists yet. This installs an engine the bundle does not declare support for, so say so before running it.

Once `lc upgrade` succeeds, carry on with the findings below.

## 1. Read the findings

Run `lc doctor --json`. It prints `{category: [finding, ...]}`; each finding has `category` and `message`, and an upgrade finding also has a stable `kind` and a `fix`. Keep the findings that carry a `kind`: those are this skill's. Any other finding is ordinary health (a stale pin, an orphan, a missing facet page) - report it, but it is not an upgrade finding; point at `driver` for pins and bookkeeping.

If no finding carries a `kind`, say the machine is already current and stop.

Walk the findings one at a time, in the order below, using each finding's own `fix` text as the starting point. If `lc doctor --json` shows a `kind` this skill does not list, read its `message` and `fix` to the human and ask how to proceed - do not guess.

## 2. `config-key-blank` - ask, then set

The finding names the key and what it does. Explain it in a sentence, ask the human for the value, confirm it back, then write it as a `key: value` line in the config file (`~/.lightcycle/config`, or `$LC_CONFIG`) - editing the file directly avoids the `lc config --edit` editor hop, which you cannot drive. Check it with `lc config` and `lc doctor`.

A running pool reloads the config file within a tick, so the new value applies without a restart. Four keys are the exception and need a restart: `poll-seconds`, `pool-upgrade-check-seconds`, `tick-failure-cap` and `spin-cap`. After editing one, `lc doctor` reports a restart is needed while the pool runs. If the edit is rejected (a blank or invalid value), the pool keeps its last good config and `lc doctor` reports that too, so `lc config` alone does not show whether the pool applied it.

For `trusted-authors` (the GitHub logins whose PR comments the pool acts on; blank, it acts on none) follow the `setup` skill's "Trusted authors" section: the human's own login, then teammates and review bots, set in the config file only.

## Workflow config keys and failed hooks

A required key of a workflow's own config block is not an upgrade finding: `lc doctor` reports it as an ordinary `config` problem with no `kind`, naming the key and the block (`workflow-<origin>-<name>:`). Ask the human for the value and write it into that block, as in section 2.

`lc workflow upgrade` runs the workflow's `upgrade` hook before it records the new SHA. If the hook fails, the origin stays at its old SHA and `lc workflow list` still shows the old pin. Read the command's output to see why: the output is the last 2000 characters of the hook's stdout and stderr, and the failure names the full run log to read for the rest. A hook that runs past `lifecycle-timeout-seconds` counts as failed. Fix the cause, then re-run `lc workflow upgrade`. A failed first `install` leaves the origin unregistered in the same way.

## 3. `schedule-not-enabled` - choose a project, then write the block

A built-in job, such as the retro audit, the material audit or the daily summary, now runs as a scheduled workflow, and none is enabled for this machine. Ask which registered project (`lc project list`) the schedule should use. Show the suggested cron and guard from `lc schedule list`, and let the human adjust them. Confirm the result back, then write the `schedule-<id>` block to the config file as the finding's `fix` shows, and check it with `lc schedule list` and `lc doctor`. The block needs a `shortcode:` line when its project has no shortcode of its own; the seeded `guidance` blocks carry one (`AUD`, `SUM`). A `guard` that takes parameters writes them as indented lines, for example `guard: pending-reflections` with `min: <n>`. A workflow already enabled under any id counts as enabled, so never add a second block for it.

## 4. `config-key-obsolete` - read it back, then delete the line

The engine no longer reads this key. Read the key and its value back to the human, say it has no effect, and on their yes delete that line from the config file. Check with `lc config` and `lc doctor`.

## 5. `guidance-conventions-outdated` - file a guidance-entry item

The guidance repo's `CONVENTIONS.md` records an older conventions version than the engine ships. Do not hand-make a guidance PR: the update is filed as a `guidance-entry` item (section 7) and the pipeline opens the PR. Find the repo with `lc guidance-dir`. The brief says to bring `CONVENTIONS.md` to the engine's current conventions; it cites `lc guidance-conventions` as the source of the current conventions text. One item may carry both this update and the backfill in section 6.

## 6. `guidance-entries-nonconforming` - file a backfill

The finding counts the entries on the guidance repo's default branch that fail the current conventions (for example no `purpose`, `when` or `why`) and names the first few. Several entries are one backfill, not one item each. When both findings are present, file one item that carries the conventions update and then the backfill, so the backfill is written against the current rules.

## 6a. `guidance-entry-reverted` - file a restore item

An entry is `draft` on the guidance repo's default branch but was `stable` in its last 200 commits, so it is no longer delivered to agents. Read the finding's `message` for the entry ids. The fix is a `guidance-entry` item (section 7) that restores `status: stable` on each named entry; merging its PR delivers them again. Do not edit the entry by hand.

## 6b. `guidance-shortcode-missing` - set the shortcode on the human's word

The `guidance` project is registered without an id shortcode, so `--project guidance` cannot mint ids. The fix is `lc project set guidance --shortcode <the configured guidance-shortcode>`; read the value from `lc config` (seeded `GDN`). Ids cannot change once items exist under a shortcode, so run it only after the human says so, and show them the exact command first.

## 7. Filing the item

A conventions update or data backfill is filed as an item, never done by hand in the repo. Follow the `driver` skill's filing rules: `lc search` for a duplicate first, then `lc new item "<title>" --workflow lightcycle/guidance-entry --repo guidance --project guidance --description "<brief>"`. `--repo guidance` is the built-in repo name `lc project list` shows, and `--project guidance` mints `GDN-` ids. Confirm the workflow origin with `lc workflow list`. The brief names the failing files and what each is missing, and the conventions update when section 5 applies. Agree the workflow and whether to activate it now with the human before filing.

## 8. Confirm

Once the human has done or deferred each finding, re-run `lc doctor --json`. A config value clears at once; a PR or backfill item clears only after it merges, so say which findings remain and why. Success means no finding with a `kind` is left, or the remaining ones are named as waiting on a PR or item. Finish by pointing at `driver` to continue working.

## Boundary

This skill brings an existing machine current; first-time onboarding (prerequisites, directories, registering repos, starting the pool) is `setup`. It does not drive items through the pipeline - that is `driver` - and it does not fix ordinary `lc doctor` health problems.
