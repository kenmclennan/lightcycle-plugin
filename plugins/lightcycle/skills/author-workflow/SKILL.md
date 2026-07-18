---
name: author-workflow
description: Author, adapt, or fork a lightcycle workflow source - a pullable git origin the `lc` engine turns into a sha-pinned bundle. Use this whenever creating a new workflow for the lightcycle/lc engine, adapting an existing one into a variant (e.g. a BDD-driven flow from spec-driven), forking a workflow from another source into your own, adding a workflow to a source, editing a workflow's graph (entry/edges/hooks/signals), writing or changing a step's role prompt, or debugging why `lc workflow add`/`lc flow` rejects a bundle. Covers the source.toml manifest, the workflows/*.md graph grammar, the engine's hook catalog, the steps/*.md role prompts and their accepts/produces handoff contract, and the self-contained-bundle rule.
---

# Author a lightcycle workflow source

A **workflow source** is a git repo the `lc` engine pulls into an immutable, sha-pinned **bundle**. Every item that runs a workflow pins `<origin>/<name>@<sha>`, so a bundle must be **self-contained**: the flow graph and every step it names live in that one repo. Pin integrity is why steps are copied into a source rather than shared across origins - a pinned sha must always resolve the same bytes.

The engine is workflow-agnostic: it supplies primitives (`lc claim`/`lc done`, worktrees, PR and CI hooks) and knows nothing about your pipeline. A _workflow_ is entirely the markdown in a source. But "agnostic" cuts both ways - a workflow only works if it speaks the engine's contract exactly: the right hooks, valid graph, and every step handing off an outcome the graph routes. That contract is what this skill carries; the rest you lift from the canonical bundle.

## Read the canonical bundle first

`lc workflow list` prints the built-in `lightcycle` origin and its on-disk path. Read its `source.toml`, `workflows/spec-driven.md`, and a few `steps/*.md` before writing. It is the reference implementation; when this skill and the bundle disagree, the bundle wins (it is what the engine loads).

## Adapt an existing workflow - the default path

Most authoring is **not** from scratch. A new workflow shares the bulk of an existing one - the code-build, PR, CI, review, merge, and conflict machinery is identical; only the front differs. Start from the nearest workflow and change what's genuinely different. Two mechanically different cases:

- **A variant in the SAME source** (e.g. a BDD-driven flow beside spec-driven). Steps are shared _within_ a bundle, so you do **not** copy them - add a new `workflows/<name>.md` that **reuses existing steps by name** (`open-pr`, `await-merge`, `watch-ci`, `review-code`, `cleanup`, and the hook block) and add only the genuinely-new steps. For BDD-driven: copy `spec-driven.md`, replace the front (`spec-writer` → a `feature-writer` authoring gherkin `.feature` files; the spec-PR gate → a scenario-review gate), rewire only those front edges - the whole code phase from `write-code` on is reused untouched. This is a **three-gate** flow (spec PR, then a `@wip`-tagged scenario PR in the project repo, then the code PR), so it declares a third `feature` phase in the `phase:` block: `feature` and `code` share the `project` workspace but are distinct gates, each with its own PR, branch, and worktree.
- **Forking from ANOTHER source.** The self-contained rule _requires_ you to copy that source's `workflows/<name>.md` **and every `steps/*.md` it references** into your source, then modify. `lc workflow list` shows where each bundle lives; copy from there. `lc flow` then proves you brought everything across.

From-scratch is the fallback for a novel pipeline - and even then, lift the step prompts and the hook block from the canonical bundle rather than reinventing the PR/CI wiring, which is the most common way to get a workflow subtly wrong.

## source.toml

```toml
name = "lightcycle"
contract = 1
description = "..."
```

`contract` (**required**) is the integer engine contract the source targets; `lc workflow add`/`upgrade` refuses an incompatible pull loudly, at pull time. Match the contract the canonical bundle declares (that is the engine in use). `name`/`description` optional; workflows are discovered from `workflows/`.

## The handoff contract - how steps chain into a workflow

A workflow is a graph of stages. Each stage is an **ephemeral agent** (or a human gate) that claims one step, does the work, and ends with `lc done <STEP> <outcome>`. Two things must line up for the handoff to work:

1. **Outcome → route.** Every `<outcome>` an agent can emit needs a matching **edge** `from-stage  outcome  target` (omit target for a terminal). An emitted outcome with no edge dead-ends the item. Keep the step prompt's outcomes and the graph's edges in exact lockstep - if a step can end three ways, the graph needs three edges.
2. **Artifacts → accepts/produces.** An owned step's frontmatter declares `accepts:` (artifacts it needs, each `required`/`optional`) and `produces:` (artifacts it attaches). The engine proves every `accepts` is satisfied by the workflow's `requires` or an upstream `produces` **before the workflow runs**; an unsatisfiable accept is rejected. This is what makes the chain sound rather than hopeful.

**Edges vs hooks** is the line that matters most: an **edge** is an outcome the _agent_ emits (`lc done ... done`); a **hook** is an outcome the _engine_ injects from an event outside the agent (a PR merged, CI failed). The agent never emits a hook outcome. Confusing the two is the most common graph bug.

**Who runs a stage:** a `steps/<role>.md` with a `model:` is an agent step; a step file _without_ `model:` is a human gate; a stage with _no_ step file is a fileless terminal (a valid endpoint - a reached-and-done cleanup, a human `review-conflict`). Only owned (agent/human) non-terminal stages must have a file.

## The engine's hooks - the catalog

Hooks wire engine-detected events into transitions, in the `hooks:` section. The engine recognizes exactly these (form → meaning):

- `pr_merge <stage> <outcome>` - the stage's PR merged → resolve with `<outcome>`.
- `pr_close <stage> <outcome>` - PR closed unmerged → `<outcome>`.
- `pr_feedback <stage> <target>` - a comment/review landed → route to the `<target>` step to handle it.
- `pr_conflict <stage> <outcome>` - the PR hit a merge conflict → `<outcome>`.
- `pr_conflict_cap <stage> <N>` - resolve conflicts at most N times.
- `pr_conflict_escalate <stage> <outcome>` - past the cap → `<outcome>` (usually a human step).
- `ci_failed_cap <stage> <outcome> <N> <target>` - CI failed: use `<outcome>` up to N times, then route to `<target>`.
- `mention_token <stage> <@token>` - the token in a PR comment that pings the human (e.g. `@lc`).
- `review_bot_allowlist <stage> <bot>...` - review bots whose comments the engine acts on.

The periodic retro audit is NOT a hook - it is an engine service that runs across all workflows automatically (any item that produces feedback gets audited), so you never wire it into a workflow.

You rarely author these from nothing: copy the canonical bundle's whole hook block when adapting and change only what your pipeline needs. `signals:` (`<stage> <name> <decl>`) declare per-stage counters the caps read - copy them alongside the hooks they serve.

## workflows/&lt;name&gt;.md - the rest of the grammar

Beyond `entry`, `edges`, `hooks`, `signals`:

- `entry: <role>` - the first stage (needs a `steps/<role>.md`).
- `requires: <artifact> ...` - artifacts the item must already carry to start; these satisfy the entry step's `accepts`.
- `workspace: <repo-key>` - default worktree repo (usually `project`). Omit the value to open a per-stage `workspace:` section (`<stage> <repo-key>` lines) when a phase's worktree comes from a different repo (a spec phase in `specs`, code in `project`).
- `phase:` - a per-stage section (`<stage> <phase>` lines) declaring which **PR-gate** each stage belongs to. A phase is an ordered gate with its own PR, branch, and worktree; stages that share a phase share all three, so every stage in one PR-segment must declare the same phase. It is **decoupled from `workspace:`** - two phases can run in the _same_ repo (a BDD flow's `feature` and `code` gates both in `project`), which is exactly what a plain repo/workspace split cannot express. Undeclared -> one unlabeled phase (a single PR), so simple one-gate workflows write no `phase:` at all; a multi-gate workflow declares a phase for every PR-segment stage. `spec-driven` declares `spec` for its specs-workspace stages and `code` for the rest.
- `nodes: <stage> <step-file>` - only when one step file serves two positions (e.g. `spec-open-pr` and `code-open-pr` both map to `open-pr`).

For exact indentation and section order, mirror the canonical `spec-driven.md` - don't reconstruct the syntax from memory.

## steps/&lt;role&gt;.md - the role's brief

Frontmatter (`model`, `accepts`, `produces`) plus the system prompt. Study the canonical steps for the house style: terse ephemeral agents that **claim one step, do it in the worktree, `lc done` with a graph outcome, and exit**.

- `lc claim <role>`; if nothing, say so and exit. The printed JSON is the step - read `.id`, `.parent`, `.workspace`, `.branch`, and the artifacts you `accept`.
- Do all git work in `.workspace` (the isolated worktree lc created); never run git in the lightcycle root.
- End with `lc done <STEP> <outcome>` where `<outcome>` is exactly an edge label from the graph.

## The self-contained-bundle rule

Steps are shared _within_ a bundle (two positions, one file) but duplicated _across_ sources. A source that wants `open-pr` behaviour copies the step in; it never reaches into another origin. The duplication is the price of pin integrity - do not factor it out.

## Validate - to ship and to debug

- `lc workflow add <url>` / `lc workflow upgrade <origin>` validates at pull time: contract compatibility, and every edge/hook target naming an owned step resolves to a real file (fileless terminals allowed). A dangling reference is refused before anything registers.
- `lc flow` prints the assembled flow and checks composition: entry, routes, and the `accepts`/`produces` contracts. Run it after any change; a green `lc flow` is your proof the workflow is sound.

When either rejects the bundle, the message names what failed - a missing step file, an unsatisfiable `accepts`, an unreachable stage. Fix the named thing; don't work around the validator.
