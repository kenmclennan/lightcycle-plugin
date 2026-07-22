# lightcycle-plugin

The Claude Code companion for [lightcycle](https://github.com/kenmclennan/lightcycle) - the workflow-agnostic agent-pipeline engine (`lc`).

The **engine** is a separate pipx-installed Python program (the pool, the store, the workers). This **plugin** is the claude-side front door: it bootstraps the engine onto a machine and ships the skills for working with it. Install the plugin on any machine - including a locked-down work laptop - and you get a working `lc` plus its authoring skills.

## Install

```
/plugin marketplace add kenmclennan/lightcycle-plugin
/plugin install lightcycle@lightcycle
```

**Prerequisite:** [`pipx`](https://pipx.pypa.io/) on your PATH. If it is missing the bootstrap prints a notice and does nothing else - install pipx and restart your session.

## What it does

- **Bootstrap (SessionStart hook).** Ensures the `lc` engine is installed and current: on a fresh machine it `pipx install`s lightcycle; where `lc` already exists it runs `lc upgrade` (the engine's own upgrade, which respects its pool-busy guard); then `lc init` (idempotent). Rate-limited to once a day so it is not a per-session network hit. It also emits a one-line nudge each session to invoke the `driver` skill.
- **Skills.**
  - `driver` - the human's seat for driving lightcycle: developing an idea into a brief, filing items to the pipeline, and clearing the human review gates (spec PRs, code await-merge) in `lc inbox`. Invoke it to drive a session - it is the playbook that replaces the retired `lc driver` command.
  - `author-workflow` - co-design the shape of a workflow (its flow - stages, routes, hooks) before it is built; the authoring craft itself lives in the built-in workflow-authoring bundle's steps.

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
    ├── driver/SKILL.md
    └── author-workflow/SKILL.md
```
