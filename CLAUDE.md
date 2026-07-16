# CLAUDE.md - lightcycle-plugin

The Claude Code companion for lightcycle: a **plugin marketplace** repo. Its SessionStart hook bootstraps the `lc` engine (pipx install / `lc upgrade` / `lc init`), and its skills help you work with it. The engine stays a separate pipx program; this repo is the claude-side front door.

## The lightcycle repos

lightcycle is four coordinated repos. A change that spans them lands in tandem.

- **lightcycle** - the `lc` engine: CLI, agent pool, and store. Pipx-installed, zero runtime deps, workflow-agnostic. The only home for engine code.
- **lightcycle-workflows** - the built-in workflow origin: pullable bundles (`source.toml` + `workflows/*.md` + `steps/*.md`) the engine turns into sha-pinned, per-item pins. Content, not engine code.
- **lightcycle-specs** - design docs (`lightcycle/*.md`) and briefs (`briefs/*.md`). Specs land there through the spec-PR review gate before code is built.
- **lightcycle-plugin** (this repo) - the Claude Code companion: a marketplace repo whose SessionStart hook bootstraps the engine (pipx) and whose skills (e.g. `author-workflow`) help you work with it.

The plugin bootstraps the engine and ships the authoring skills; it can't _be_ the engine (a plugin is claude config, not a daemon). A change to the engine's contract, the workflow grammar, or the audit/hook model usually spans several repos - the skills here must track it.

## Working across the repos

- **PR-flow for every repo.** Branch, open a PR, get it reviewed, merge. No direct-to-main - engine, origin, specs, and plugin alike.
- **Coupled changes land in tandem.** When a change spans repos (e.g. an engine change that removes a workflow hook), open the PRs together and note the coupling in each. Roll out live with `lc upgrade` (engine) + `lc workflow upgrade` (origin).

## Conventions

- Structure: `.claude-plugin/marketplace.json` (root) -> `plugins/lightcycle/{.claude-plugin/plugin.json, hooks/, skills/}`. `plugin.json` carries no `version` - every commit is an update.
- The bootstrap reuses the engine's own `lc upgrade` (which respects its pool-busy guard) and never fails a session (always exits 0); its one prerequisite is `pipx` on PATH.
- Skills are built and iterated with **skill-creator** (eval-driven), grounded in the actual engine - not written from memory. When the engine changes a contract the skill teaches (grammar, hook catalog), update the skill in the same coupled change.
- Hyphens not emdashes. Format markdown with `prettier --prose-wrap=never`.
