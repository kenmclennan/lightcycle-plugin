# lightcycle-plugin

The Claude Code companion for [lightcycle](https://github.com/kenmclennan/lightcycle) - the workflow-agnostic agent-pipeline engine (`lc`).

The **engine** is a separate pipx-installed Python program (the pool, the store, the workers). This **plugin** is the claude-side front door: it bootstraps the engine onto a machine and ships the skills for working with it. Install the plugin on any machine - including a locked-down work laptop - and you get a working `lc` plus its authoring skills.

## Install

```
/plugin marketplace add kenmclennan/lightcycle-plugin
/plugin install lightcycle@lightcycle
```

**Prerequisites:** [`pipx`](https://pipx.pypa.io/) and `git`, both on your PATH. Bootstrap installs `pipx` itself when it can - via Homebrew, or `pip` under Python 3.11+ - so most machines don't need it preinstalled. If `git` is missing, or `pipx` is missing and can't be installed automatically, the bootstrap stops with an error and installs nothing - install the missing piece and start a new session.

**Installing does not run the bootstrap.** `/plugin install` does not fire SessionStart, so **start a new session** after installing. The first session installs the engine and runs `lc init`; if any of that fails it says so and retries on your next session rather than marking itself done.

## Getting started

The canonical way onto a new machine:

1. **Install the plugin** (above), then start a new session. Its SessionStart hook installs the `lc` engine with pipx, runs `lc init`, and checks for an engine upgrade once a day. A failure at any of those steps is reported and retried next session.
2. **Invoke the `setup` skill.** It walks you through the rest - verifying prerequisites (`gh` / Claude login), pointing `lc` at your directories, and registering your repos in the project registry (discovering them with `lc project scan`), plus an optional personal workflow origin.
3. **Invoke the `driver` skill to work.** Develop an idea into a brief, file it to the pipeline, and clear the human review gates (spec PRs, code `await-merge`) that surface in `lc inbox`.

The session nudge points you at the right one: `setup` when no projects are registered yet, `driver` once you are set up.

## What it does

- **Bootstrap (SessionStart hook).** Ensures the `lc` engine is installed and current: on a fresh machine it `pipx install`s lightcycle; where `lc` already exists it runs `lc upgrade` (the engine's own upgrade, which respects its pool-busy guard); then `lc init` (idempotent). Rate-limited to once a day so it is not a per-session network hit. It also emits a one-line nudge each session: `setup` on a machine with no registered projects, otherwise `driver`.
- **Skills.**
  - `setup` - one-time machine onboarding: verify prerequisites, point `lc` at your directories, register your repos in the project registry (via `lc project scan`), and optionally create a personal workflow origin, then hand off to `driver`. Invoke it on a fresh machine.
  - `driver` - the human's seat for driving lightcycle: developing an idea into a brief, filing items to the pipeline, and clearing the human review gates (spec PRs, code await-merge) in `lc inbox`. Invoke it to drive a session.
  - `author-workflow` - co-design the shape of a workflow (its flow - stages, routes, hooks) before it is built; the authoring craft itself lives in the built-in workflow-authoring bundle's steps.
  - `autopilot` - take over a scoped, bounded run of driving lightcycle unattended: a named scope agreed with the human up front and three exit conditions. Invoke it before an unattended run starts.

The plugin owns getting the engine onto the machine and keeping it current; the engine owns everything at runtime.

## Layout

```
.claude-plugin/marketplace.json     # catalogs the one plugin
plugins/lightcycle/
├── .claude-plugin/plugin.json       # metadata (no version -> every commit is an update)
├── hooks/
│   ├── hooks.json                    # SessionStart -> bootstrap.sh
│   └── bootstrap.sh                  # install / upgrade / init
└── skills/
    ├── setup/SKILL.md
    ├── driver/
    │   ├── SKILL.md
    │   └── references/why.md      # level 3 - loaded on demand
    ├── author-workflow/SKILL.md
    └── autopilot/SKILL.md
```
