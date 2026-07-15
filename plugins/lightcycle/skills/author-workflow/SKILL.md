---
name: author-workflow
description: Author or edit a lightcycle workflow source (a pullable origin bundle) against the sources convention - the source.toml manifest, workflows/*.md graph files, and steps/*.md role prompts. Use when creating a new workflow origin for the lc engine, adding a workflow to one, or editing an existing workflow's steps/edges/hooks.
---

# Author a lightcycle workflow source

> v1 skeleton. This skill is being hardened with skill-creator (eval-driven); the convention below is correct, the guidance will get sharper.

A workflow **source** is a git repo the `lc` engine pulls into an immutable, sha-pinned bundle. It is self-contained: everything a workflow needs lives inside it.

## Layout

```
<source-repo>/
├── source.toml          # manifest: contract (required), name, description
├── workflows/
│   └── <name>.md         # the flow graph: entry / nodes / edges / hooks / workspace
└── steps/
    └── <role>.md         # one per role: model + system prompt (the agent's brief)
```

## source.toml

- `contract = N` (REQUIRED) - the engine contract this source targets. `lc workflow add` refuses the pull if it is incompatible with the engine.
- `name`, `description` - optional; workflows are discovered from `workflows/`.

## workflows/<name>.md

A graph, authored as labelled sections:

- **entry** - the first step (a role with a `steps/<role>.md`).
- **nodes** - map a graph position to a step file when a step appears at more than one position (e.g. a shared `open-pr` used at two stages).
- **edges** - `from-step  outcome  to-step`: real transitions.
- **hooks** - outcomes that auto-close or bypass a transition (e.g. `pr_merge`, `retro_cadence`); keep these visually separate from edges.
- **workspace** - per-stage repo the step runs in (a spec phase in the specs repo, a code phase in the project repo).

## steps/<role>.md

Frontmatter `model:` plus the system prompt for that role. Every non-terminal step an edge/hook targets by an owned name MUST have a backing file in the same bundle (fileless human terminals like `review-conflict` are allowed).

## The self-contained-bundle rule

Steps are duplicated **per source** - a workflow in another origin that wants `open-pr` behaviour copies the step into its own bundle. Do not reach across origins.

## Validate before shipping

- `lc workflow add <origin-url>` (or `upgrade`) validates the bundle at pull time: contract compatibility + every referenced step resolves to a file.
- `lc flow` prints and checks the assembled flow (steps, routes, contracts, composition).
