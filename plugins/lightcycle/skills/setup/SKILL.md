---
name: setup
description: Set up lightcycle on a machine - the guided, first-time onboarding after installing the plugin. Use this when the `lc` engine is freshly installed but not yet configured for real work: verifying prerequisites, pointing `lc` at your directories, registering your repos in the project registry (via `lc project scan`), and optionally creating a personal workflow origin - before you start driving. Invoke it on a new machine, when someone says "set up lightcycle" / "onboard lightcycle" / "get lightcycle working here", or when `lc doctor` / `lc config` show an unconfigured install.
---

# Set up lightcycle

This is the one-time onboarding for a machine. The plugin's SessionStart hook has already installed the `lc` engine (pipx) and run `lc init` (seeding `~/.lightcycle` and pulling the built-in workflow origin); this skill does the interactive rest - prerequisites, config, registering repos, an optional personal workflow origin - and then hands off to the `driver` skill for actual work.

**Drive the safe commands yourself; hand back only for what you cannot do.** Run the read-only checks and the `lc` commands directly, and act on what they show. The only two things you cannot do for the human are a **browser login** (`gh auth login`, signing into a Claude subscription) and an **interactive editor** - surface the exact command for those and wait. Work one step at a time; confirm before writing anything. No emdashes.

## 1. Health and prerequisites

Run `lc doctor` (store + config + origin health) and check the prerequisites the bootstrap cannot establish:

- `command -v lc` / `command -v pipx` / `command -v git` - present on PATH.
- `gh auth status` - authenticated (needed for PR steps and for cloning private repos on demand).
- `claude` signed in to a Claude subscription (workers bill to it) - run `claude` once to confirm.

Report a short checklist of pass/fail. For anything failing, give the exact fix; for the two logins (`gh auth login`, the Claude subscription) you cannot run them - surface the command and wait for the human to complete it.

## 2. Confirm config

Run `lc config` and show where `projects`, `specs`, and `specs-remote` point (defaults are `~/workspace/{projects,specs}`). If they are correct and the directories exist, move on. If a value needs changing, propose the concrete value, confirm with the human, then write it into the config file (`~/.lightcycle/config`, or `$LC_CONFIG`) as a `key: value` line - this skips the `lc config --edit` editor hop, which you cannot drive. Do not invent values; ask if unsure.

## 3. Register your repos

A project in lightcycle is its GitHub identity (`owner/name`) in the registry; an item's `repo` artifact resolves through it. Register the repos on this machine:

1. `lc project scan --json <dir>` (default the current directory) - it walks the tree, finds git repos, and reports each as a candidate with its `identity`, `path`, proposed `shortcode`, and `status` (`new` / `already-registered` / `no-remote`). Ask the human which directory to scan if the current one is not their workspace.
2. Show the human the `new` candidates (and note any `no-remote` ones it could not identify, and any `already-registered`). Ask which to register - do not bulk-register silently.
3. For each chosen candidate: `lc project add <identity> --path <path>`. Pass `--shortcode <X>` only if the human wants a prefix other than the derived default (the identity's trailing segment, uppercased). `scan` never registers anything itself; this step does.

A repo that lives outside the scanned tree can be registered directly with `lc project add <owner/name> --path <dir>`. A registered repo you have not checked out here is cloned automatically when you activate an item that targets it - no need to clone it now.

## 4. Offer a personal workflow origin

Ask whether the human wants their own workflow origin (a pullable repo of their own `lc` workflows, separate from the built-in `lightcycle` one). If yes, `lc workflow init <name>` scaffolds it, registers it as a source, and sets it as the personal origin. If they only need the built-in workflows, skip this.

## 5. Hand off to the driver

Setup gets the machine and repos usable; it stops there. The first actual item - developing a brief, filing it, clearing the review gates - is the `driver` skill's job. Point the human at it: invoke the `driver` skill to start driving work.

## Boundary

This skill is machine-level onboarding only. It does not develop briefs, file items, or run the pipeline - that is `driver`. It does not author workflows - that is `author-workflow` and the workflow-authoring pipeline. Re-running it on an already-configured machine is safe: every step is a check that reports "already done" and moves on.
