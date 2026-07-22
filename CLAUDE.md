# CLAUDE.md - lightcycle-plugin

The Claude Code companion for lightcycle: a **plugin marketplace** repo. Its SessionStart hook bootstraps the `lc` engine (pipx install / `lc upgrade` / `lc init`), and its skills help you work with it. The engine stays a separate pipx program; this repo is the claude-side front door.

## The lightcycle repos

lightcycle is four coordinated repos (engine / workflows / specs / plugin); this is the plugin - see `lightcycle/CLAUDE.md` for the full map. A change that spans them lands in tandem.

The plugin bootstraps the engine and ships the authoring skills; it can't _be_ the engine (a plugin is claude config, not a daemon).

_Cross-repo process (PR-flow, coupled changes) is a driver operation - see the engine's `prompts/driver.md`._

## Conventions

- Structure: `.claude-plugin/marketplace.json` (root) -> `plugins/lightcycle/{.claude-plugin/plugin.json, hooks/, skills/}`. `plugin.json` carries no `version` - every commit is an update.
- The bootstrap reuses the engine's own `lc upgrade` (which respects its pool-busy guard) and never fails a session (always exits 0); its one prerequisite is `pipx` on PATH.
- Skills are built and iterated with **skill-creator** (eval-driven), grounded in the actual engine - not written from memory. Keep a skill in step with any engine contract it actually teaches. The `author-workflow` skill is co-design only - it defers grammar and hook-catalog detail to the built-in workflow-authoring bundle, so a change to those contracts updates the bundle, not this skill.
- Hyphens not emdashes. Format markdown with `prettier --prose-wrap=never`.
