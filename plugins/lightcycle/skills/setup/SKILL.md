---
name: setup
description: Set up lightcycle on a machine - the guided, first-time onboarding after installing the plugin. Use this when the `lc` engine is freshly installed but not yet configured for real work: verifying prerequisites, pointing `lc` at your directories, registering your repos in the project registry (via `lc project scan`), and optionally creating a personal workflow origin - before you start driving. Invoke it on a new machine, when someone says "set up lightcycle" / "onboard lightcycle" / "get lightcycle working here", or when `lc doctor` / `lc config` show an unconfigured install.
---

# Set up lightcycle

This is the one-time onboarding for a machine. A machine that is already set up and has just had its engine upgraded needs the `upgrade` skill instead, which walks what `lc doctor` reports the upgrade left behind. The plugin's SessionStart hook has already installed the `lc` engine (pipx) and run `lc init` (seeding `~/.lightcycle`, creating and registering the `specs` and `guidance` projects, and seeding `trusted-authors` from your `gh` login only when `gh` is authenticated - on a fresh machine it usually is not yet, so the "Trusted authors" section below re-checks it; it pulls the built-in workflow origin only if `workflows-remote` is already configured, which a fresh install is not - step 1 below covers getting it configured); this skill does the interactive rest - prerequisites, config, registering repos, an optional personal workflow origin, starting the pool - and then hands off to the `driver` skill for actual work.

**Drive the safe commands yourself; hand back only for what you cannot do.** Run the read-only checks and the `lc` commands directly, and act on what they show. The only two things you cannot do for the human are a **browser login** (`gh auth login`, signing into a Claude subscription) and an **interactive editor** - surface the exact command for those and wait. Work one step at a time; confirm before writing anything. No emdashes.

## 1. Health and prerequisites

Run `lc doctor` (store, pins, contract, origin, config, orphans, facets and guidance health) and check the prerequisites the bootstrap cannot establish:

- `command -v lc` / `command -v pipx` / `command -v git` - present on PATH.
- `gh auth status` - authenticated (needed for PR steps and for cloning private repos on demand).
- `git config user.name` and `git config user.email` set - `lc init` (when it creates the guidance repo) and `lc workflow init` refuse without them.
- `claude` signed in to a Claude subscription (workers bill to it) - run `claude` once to confirm.

Report a short checklist of pass/fail. For anything failing, give the exact fix; for the two logins (`gh auth login`, the Claude subscription) you cannot run them - surface the command and wait for the human to complete it.

`lc doctor` reports a `"config"` problem naming `workflows-remote` when it is set but blank - a fresh install has no default anymore. If present, ask the human for their workflow source URL, set `workflows-remote` to it first (write the `key: value` line into the config file, or `lc config --edit`), then run `lc workflow add <url> --name lightcycle` (`lightcycle` is the seeded default origin name). `lc workflow add` alone does not set `workflows-remote`, so `lc doctor` stays unhealthy.

## 2. Confirm config

Run `lc config` and show where `projects` points (default `~/workspace/projects`). Run `lc project list` (identity, shortcode, path and facets - no remote) and show the `specs` and `guidance` projects' paths, then `lc specs-dir --check` and `lc guidance-dir --check` to verify each repo's `origin` matches its registered remote. If they are correct and the directories exist, move on. If `projects` needs changing, propose the concrete value, confirm with the human, then write it into the config file (`~/.lightcycle/config`, or `$LC_CONFIG`) as a `key: value` line - this skips the `lc config --edit` editor hop, which you cannot drive. Do not invent values; ask if unsure.

**Moving `specs`.** `lc project add` cannot target it (its identity isn't `owner/name`-shaped). Write `specs`/`specs-remote` into the config file, run `lc project rm specs`, then `lc init` to re-register it from the new values, then delete both `specs` and `specs-remote` from the config file - left behind they are obsolete, and `lc doctor` reports them as "set but not read by this version". `lc init` now seeds a `specs-path` config key for the `specs` project's path, beside `guidance-path`; on a fresh config, set `specs-path` rather than the legacy keys.

**The guidance repo.** `lc init` creates and registers one, with the `guidance-shortcode` id prefix (seeded `GDN`) so `--project guidance` mints ids (default `~/workspace/agent-guidance`; `lc init --guidance-path <dir>` overrides it); `lc guidance-dir [--check]` prints the registered path and verifies its `origin`. If `lc guidance-dir --check` or `lc specs-dir --check` fails because the repo gained an `origin` after it was registered, re-run `lc init`: it reads each repo's `origin`, stores it when it differs from the registered remote (empty included) and prints `<repo>: remote updated to <url>`. Keep `lc project rm` for moving the path. To adopt a team's shared guidance repo instead: `lc project rm guidance`, clone the repo to the target path, then `lc init --guidance-path <dir>`.

## Trusted authors

`trusted-authors` is the list of GitHub logins whose PR comments the pool acts on; blank, it acts on none. `lc init` seeds it with your `gh` login only when `gh` is authenticated, and never overwrites it - and the SessionStart hook runs it before you have done `gh auth login`, so it may be unset. `lc doctor` reports a blank one as `required config key 'trusted-authors' is set but blank`.

1. Once `gh auth login` is done, re-run `lc init` (or write a `trusted-authors:` line into the config file) and confirm with `lc config` that it holds your login, before the pool starts.
2. Ask which teammates and review bots to add (for example Copilot, which takes both logins: `Copilot` for its line comments and `copilot-pull-request-reviewer[bot]` for its reviews). A review bot can post under more than one login, so check the authors on its real comments. No bot is trusted by default. Set the key in the config file only - never in a workflow bundle.
3. Explain held comments: a comment from an untrusted author becomes an `HLD-` item with a `review-held-comment` step in `lc inbox`; the human decides it with `lc done <step> approve|reject`.

## 3. Register your repos

A project in lightcycle is its GitHub identity (`owner/name`) in the registry; an item's `repo` artifact resolves through it. Register the repos on this machine:

1. `lc project scan --json <dir>` (default the current directory) - it walks the tree, finds git repos, and reports each as a candidate with its `identity`, `path`, proposed `shortcode`, `status` (`new` / `already-registered` / `no-remote` / `unreadable`), and `suggested_facets` (a list of `{facet, file}`). Ask the human which directory to scan if the current one is not their workspace.
2. Show the human the `new` candidates (and note any `no-remote` ones it could not identify, any `unreadable` ones git could not read, and any `already-registered`). Skip the specs and guidance repos: scan lists them as `new` although they are already registered as `specs` and `guidance`, and registering them again duplicates them. Ask which to register - do not bulk-register silently.
3. For each chosen candidate: `lc project add <identity> --path <path>`. Pass `--shortcode <X>` only if the human wants a prefix other than the derived default (the identity's trailing segment, uppercased). `scan` never registers anything itself; this step does.

Facets tag a project for guidance: `lc project add <identity> --path <path> --facets a,b,c` sets them at registration, and `lc project set <identity> --facets a,b,c` changes them later. A facet is valid only if the guidance repo has a `<facet>.md` concept page; `lc doctor` flags one that does not. `scan` suggests facets for each repo (conventions v4+): a concept page in the guidance repo may carry a `detected-by` list of file names or globs, and a facet is suggested when one matches a tracked file, shown with the file that matched. When no page carries `detected-by`, scan prints one `no facet suggestions: <reason>` line. Treat suggestions as proposals to show the human; scan sets nothing, so apply the chosen ones with `--facets`.

A repo that lives outside the scanned tree can be registered directly with `lc project add <owner/name> --path <dir>`. A registered repo you have not checked out here is cloned automatically when you activate an item that targets it - no need to clone it now.

## 4. Offer a personal workflow origin

Ask whether the human wants their own workflow origin (a pullable repo of their own `lc` workflows, separate from the built-in `lightcycle` one). If yes, `lc workflow init <name>` scaffolds it at `<projects>/<name>`, registers it as a writable source, and sets it as the personal origin. It is local only: no GitHub remote and no project registration. To build in it through `workflow-authoring`, add a remote and run `lc project add` for it. To adopt an origin that already exists, run `lc workflow add <url> --writable`; toggle later with `lc workflow set <origin> --writable|--read-only`. If they only need the built-in workflows, skip this.

A workflow can declare config keys of its own. `lc doctor` reports a required one that is missing or blank as `workflow <origin>/<name> needs config key '<key>' in block '<block>'`. The block is named `workflow-<origin>-<name>:` and is written into the config file like a `schedule-<id>` block; ask the human for each value, never invent one, and confirm with `lc config` and `lc doctor`. Adding such an origin runs the workflow's `install` hook first. If `lc workflow add` fails, the origin is not registered: read the command's output (the hook's output is shown as a 2000-character tail, and the failure names the full run log), fix the cause it names, and re-run. `lc workflow list` shows what was registered.

## 5. Start the pool

Run `lc start --detach` to start the pool in the background, or `lc tui --start` (engine 0.6.299+) to start it and open the dashboard. Mention `developer-mode` (`lc config`) only for a machine that develops lightcycle itself.

**Scheduled audits.** A fresh config enables four schedules, `retro-audit`, `material-audit`, `daily-summary` and `ratchet-sweep`, run in the `guidance` project's repo and file their items under a purpose name as project: `audit` for the retro audit, the material audit and the ratchet sweep, `summary` for the daily summary. `lc schedule list` shows both, the registered `project` the work runs in and, as its last column (`name` in `--json`), the purpose name (`-` when a schedule has none). Show them with `lc schedule list` (each reads `on`, `off` or `paused`, with the reason) and check `schedules-paused` in `lc config`: while it is `true` the pool files nothing. To run one on demand, use `lc schedule run <id>` (see the `driver` skill). Once the pool runs, `AUD` items (the audits and the Monday ratchet sweep, whose `repos-active` guard files nothing when it fails) and `SUM` items (the daily summary) start appearing, and their findings surface in `lc inbox`. They resolve only after `workflows-remote` is set and the `lightcycle` origin is pulled (step 1), so a machine that skipped that sees them stay unresolved; `lc doctor` flags a schedule naming a workflow it cannot resolve. Some workflows ship a suggested schedule that `lc schedule list` shows as `off - bundle suggestion`; list any such rows and offer each to the human, and never enable one unasked. An existing config gets no seeded blocks - there `lc doctor` reports `schedule-not-enabled` instead.

**Editing config later.** A running pool reloads the config file within a tick and prints `config reloaded`, so edits apply without a restart. The exceptions are the four restart-required keys, `poll-seconds`, `pool-upgrade-check-seconds`, `tick-failure-cap` and `spin-cap`: after one changes, the tick line says `restart needed for: <keys>` and `lc doctor` reports it. An invalid edit is rejected and the last good config stays in force; `lc doctor` reports it.

## 6. Hand off to the driver

Setup gets the machine and repos usable; it stops there. The first actual item - developing a brief, filing it, clearing the review gates - is the `driver` skill's job. Point the human at it: invoke the `driver` skill to start driving work.

## Boundary

This skill is machine-level onboarding only. It does not develop briefs, file items, or run the pipeline - that is `driver`. It does not author workflows - that is `author-workflow` and the workflow-authoring pipeline. Re-running it on an already-configured machine is safe: every step is a check that reports "already done" and moves on.
