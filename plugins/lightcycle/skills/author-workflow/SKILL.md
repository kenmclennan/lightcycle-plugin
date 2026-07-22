---
name: author-workflow
description: Understand and CO-DESIGN a lightcycle workflow - shaping its flow (stages, review gates, triggers) with a human before it is built. Use this when deciding what a new lightcycle/lc workflow should DO, or reshaping an existing one: what the phases and human review gates are, what an agent step vs a human gate vs a terminal is, what triggers rework, and what the design mermaid should show. The full authoring craft (exact grammar, hook syntax, QA) is NOT here - it lives in the workflow-authoring pipeline's own steps and the built-in bundles; this skill is for the design conversation that precedes filing a workflow to be built.
---

# Co-design a lightcycle workflow

A **workflow** is how lightcycle composes many ephemeral agents into a durable pipeline: a graph of **stages** (each an autonomous agent, or a human gate), where a stage's **outcome routes to the next stage**, plus **hooks** that inject outcomes from events outside any agent (a PR merged, CI failed, a comment landed). This skill helps you and a human **shape** that graph. It deliberately does **not** carry the full grammar - once the design is agreed, the `workflow-authoring` pipeline builds the actual bundle, and its own steps carry the authoring craft.

## What to settle in the design conversation

- **The stages, and who runs each.** An **agent step** (autonomous, does the work) vs a **human gate** (a decision only a person makes - a review, a merge) vs a **fileless terminal** (a reached endpoint, no work). Name each stage by what it does, terse.
- **The review gates (phases).** A phase is one ordered gate with its own PR and worktree. Where are the human review points? `spec-driven` has two (the spec PR, then the code PR); a simpler flow has one. Decide them - they are where the human's attention lands.
- **The outcomes and routing.** What can each stage end as, and where does each outcome go? The happy path is one route; a rework loop (a review `rejected` routing back to the build stage) is another. Every way a stage can end needs a destination.
- **The triggers.** What external events drive the flow - a PR merging, CI failing, a review comment? These are **hooks**. The **edge-vs-hook line is the one distinction that matters most**: an **edge** is an outcome the _agent_ emits (`lc done ... <outcome>`); a **hook** is one the _engine_ injects from an event. An agent never emits a hook outcome. Keep them straight when sketching the flow.
- **The design mermaid.** The output of design is a mermaid flowchart of the graph plus a one-line description of each stage, gate, and trigger - reviewed (on a spec PR) before anything is built.

## What NOT to do from this skill

- **Do not hand-write the bundle** (the graph markdown + the step prompts) from memory. That is the pipeline's job, and getting the exact grammar/hook syntax right is where it goes subtly wrong.
- **Do not reconstruct the grammar or hook catalog here.** The authoritative reference is the **built-in bundles** (`lc workflow list` shows their on-disk path - read `spec-driven.md` and its `steps/*.md`) and `lc workflow describe <origin>/<name>` (add `--mermaid` for the rendered graph).

## To actually build the design

File it as an item on the **`workflow-authoring`** workflow, with its `repo` set to a workflow-origin repo. The pipeline's design/build/review steps carry the full craft, author the bundle, and gate it with `lc workflow check` + `lc workflow simulate`; `lc workflow describe --mermaid` then confirms the built graph matches the design. You shape the flow here; the pipeline builds and proves it.
