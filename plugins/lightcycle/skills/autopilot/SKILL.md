---
name: autopilot
description: Take over a scoped, bounded run of driving lightcycle unattended. Use this when a human hands the driver a named set of items (plus whatever is already active or queued) to see through to completion without them present - reviewing gates, filing findings, sending work back for rework - until the goal is met, a spend ceiling is reached, a decision only the human can make blocks everything, or the human says stop. Invoke it before an unattended run starts, to agree the Scope Statement first; do not assume a hand-over is autopilot just because the human is stepping away.
---

# Autopilot

Autopilot is how the driver runs unattended: a named scope, four exit conditions, and a standing rule for what you may never decide alone. It does not replace the driver skill's standing disciplines - reviewing every gate against `origin/main` rather than trusting a clean pass, verifying empirically rather than by reasoning, filing findings the moment they are judged, serializing work that touches the same files - it composes with them for the stretch where the human is not present to be asked.

## Agree the Scope Statement before starting

Never assume a scope. Before any autonomous action, propose a Scope Statement and get the human's explicit agreement - the same propose-and-agree ceremony already used for workflow choice. It has exactly three parts:

1. **Named items** - the explicit item ids the human is handing over. Check each exists (`lc show <id>`) before the run starts.
2. **In-flight snapshot** - the item ids already active or queued at the moment the run starts, captured once as a frozen list. Take the item-id prefix (the segment before the first `.`) from every id `lc active` and `lc queue` return, run once, unfiltered - never re-query this live during the run. Freezing it is what stops a live re-query from silently pulling in whatever the pool starts next.
3. **Explicit negative** - the human's own exclusion, recorded verbatim (e.g. "no further remediation work"). Read every newly-discovered candidate against it before considering adding it to (1).

Also agree, at the same time, as part of hand-over rather than discovered later:

- A **spend ceiling** in dollars (see "Spend ceiling" below) - there is no default. A contested item can run 6-35x the cost of a clean one, so do not assume a figure.
- That the **wake mechanism dies with this session** (see "The wake mechanism is session-bound" below).

**Goal condition.** The run's goal is met when every item in (1) and (2) has reached a terminal state (`done`, or `backlogged` after triage - see "Mid-run arrivals" below) and nothing has been added to (1) beyond what that section permits. Check this by iterating the two lists against `lc show <id>`, the same bookkeeping weight phase-gating already carries.

## Exit conditions

All four produce the same five-section Resumption Report (see below); only the report's one-line header differs.

1. **Goal met** - the Scope Statement's full set (named + snapshot) is terminal, with nothing added outside it.
2. **Spend ceiling reached** - computed per "Spend ceiling" below, re-checked before every new item is allowed to start, not only at the end. Reaching it does not abort an item already in progress; it stops new activation and reports.
3. **A decision only the human can make blocks all remaining in-scope progress** - every remaining item is waiting on it, or "Never in scope, ever" forbids proceeding without it. Surface the question the moment you find it, never batched. If the human is present in the same session, get the answer and continue without ending the run - this is the ordinary case, not an exit. The run only actually ends on this condition when the human is not present to answer and nothing else in scope can proceed without one.
4. **Explicit stop** - the human says stop, at any point, no ceremony required.

## Mid-run arrivals: retros and findings

The engine can fire a `review-findings` step on an audit/retro item mid-run, on its own, with no human involved in filing it - visible in plain `lc inbox` text by its distinct `findings:<excerpt>` suffix (a clean audit produces no step and nothing to see). This is the concrete event, not a vague "something new arrived."

**Rule: a `review-findings` step is always worked, but what it surfaces is never automatically in scope.** Read the note. Search the backlog first (the driver's existing "search before you file" discipline). If it names nothing new, close it out. If it names a genuine gap, file it into the backlog and stop there - never activate it in the same motion, no matter how urgent it looks or how much room remains under the spend ceiling. Activating it is a scope change, and only the human makes those (see "Never in scope, ever").

**Mark every filed item with one of two states, stated on the item itself:**

- **A `DISCUSS:` title prefix**, when what to do about the finding is not yet settled. Pair it with a `## Before activating - discussion required` section in the description naming specifically what must be settled, and list deleting the item as a live option wherever that is genuinely on the table.
- **No prefix, with readiness stated explicitly** (e.g. "Ready to build - no discussion needed"), when the finding and its fix are both settled and the item needs no conversation before it becomes work.

Never put either marker in the description's first 60 characters - `lc backlog`/`lc inbox` truncate a row's rendered description to that window, and a leading marker there would replace what the item is about. Where the workflow cannot yet be named because it depends on the discussion's outcome, its trailing `Workflow:` line reads `Workflow: undecided - see "Before activating"` rather than naming one prematurely.

## Never in scope, ever

1. **A design decision.** Propose a direction; never choose between open tradeoffs alone. Escalate per exit condition 3.
2. **Reverting a decision the human made.** Retraction is the human's hand on the PR comment that withdraws a request, same as the driver skill's own standing discipline; autopilot does not manufacture that on the human's behalf.
3. **Activating anything outside the Scope Statement's named-items set.** Covers "Mid-run arrivals" exactly, and any other new discovery mid-run.
4. **Anything touching the loader/spawner/config boundary.** Already "substrate by hand" territory; autopilot inherits that rule rather than restating a copy that can drift.
5. **A merge or a park resolution that turns on a judgement call not priced into the Scope Statement.** The Scope Statement authorizes the mechanical merges and filings the named items were filed to produce - it does not extend to a new judgement call surfacing mid-run. Authorization stands for the scope specified, not beyond it.
6. **Raw process control.** `lc stop`'s kill path is already safe - each worker has its own process group, and the pool's own kill never signals its own group. Never reach around it with a direct `kill`/`killpg`.

## Spend ceiling

No CLI command sums cost across items or a session - `lc`'s cost lookup resolves exactly one node at a time. Compute running spend for an item by listing its step ids (`lc trace <item> --json`) and summing each step's own `usage_cost_usd` (`lc show <step-id>`, which carries it directly), across every item currently in scope. If a TUI session is open, its already-rendered per-item cost total may be read directly instead of re-deriving it by hand. Re-check the running total before every new item is allowed to start, not only at the end.

## Rework: a new-defect test

Continue sending an item back for another round for as long as each round's rejection or change request names something genuinely new - a defect the prior round's fix did not address, or that the prior round's own request did not already raise. The moment a round repeats a prior ask or finds nothing new to add, that is the trigger to stop and escalate (exit condition 3) instead of sending it back again, regardless of how many rounds have already run. Do not apply a numeric cap - a converging item can legitimately take several rounds, each finding something genuinely new, and a naive count would wrongly escalate it. This is a session-level judgement layered on top of, and never a substitute for, the workflow's own `review_rounds`/`ci_failed_cap` engine hooks, which escalate independently regardless of what autopilot decides.

## The wake mechanism is session-bound

Hold a live watch on `lc inbox`-relevant state and pool activity for the run's duration, using whatever polling/monitor primitive the driving session offers, rather than burning attention on a fixed timer. State plainly, as part of agreeing the Scope Statement - not discovered later - that this mechanism dies with the session: autopilot cannot resume itself across a session restart or a crash, and nothing pages the human if that happens.

## The Resumption Report

Every exit produces the same five sections, headed by which exit condition fired:

- **Merged** - what, with PR links.
- **Sent back** - what, and the specific new defect each round's request named, not just "changes requested."
- **Filed** - what, with new ids, split by kind: which carry the `DISCUSS:` marker and are waiting on the human's judgement, and which are stated ready to build outright - and, for all of them, that they landed in the backlog, never activated.
- **Deliberately not done** - what was in scope but left, and why: blocked on a never-in-scope call, or the run ended first.
- **Cost** - total spend across every item touched this run (per "Spend ceiling" above), against the agreed ceiling if one was set.
