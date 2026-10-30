---
name: autopilot
description: Take over a scoped, bounded run of driving lightcycle unattended. Use this when a human hands the driver a named set of items (plus whatever is already active or queued) to see through to completion without them present - reviewing gates, filing findings, sending work back for rework - until the goal is met, a decision only the human can make blocks everything, or the human says stop. Invoke it before an unattended run starts, to agree the Scope Statement first; do not assume a hand-over is autopilot just because the human is stepping away.
---

# Autopilot

Autopilot is how the driver runs unattended: a named scope, three exit conditions, and a standing rule for what you may never decide alone. It does not replace the driver skill's standing disciplines - reviewing every gate against `origin/main` rather than trusting a clean pass, verifying empirically rather than by reasoning, filing findings the moment they are judged, serializing work that touches the same files - it composes with them for the stretch where the human is not present to be asked.

## Agree the Scope Statement before starting

Never assume a scope. Before any autonomous action, propose a Scope Statement and get the human's explicit agreement - the same propose-and-agree ceremony already used for workflow choice. It has exactly four parts:

1. **Named items** - the explicit item ids the human is handing over. Check each exists (`lc show <id>`) before the run starts.
2. **In-flight snapshot** - the item ids already active or queued at the moment the run starts, captured once as a frozen list. Take the item-id prefix (the segment before the first `.`) from every id `lc active` and `lc queue` return, run once, unfiltered - never re-query this live during the run. `lc queue` shows only 10 rows by default, so an unfiltered run silently drops anything past row 10: pass a large row count (`lc queue <large N>`) or use `lc status --json`. Freezing it is what stops a live re-query from silently pulling in whatever the pool starts next.
3. **Explicit negative** - the human's own exclusion, recorded verbatim (e.g. "no further remediation work"). Read every newly-discovered candidate against it before considering adding it to (1).
4. **Merge authority** - explicit, no default: does the driver merge the run's own PRs directly, once it meets the merge criteria in `await-merge` step 2 (which includes running any `(driver, at review)` lines and any `Checked after merge:` bullets and naming any `Companion item still needed:`), or does every merge still wait for the human's own click even during this run? Record whichever the human states, verbatim. If granted, it authorizes only that mechanical merge, and only for items inside the Scope Statement's named-items and in-flight-snapshot sets - never a merge that turns on a judgement call not priced into this run (see "Never in scope, ever" rule 5), never a PR with an undecided held comment, and never a mid-run arrival (see "Mid-run arrivals" below).

Also agree, at the same time, as part of hand-over rather than discovered later: that the watch (see "Arm the watch" below) will be started before anything else happens, and that it **dies with this session**: autopilot cannot resume itself across a session restart or a crash, and nothing pages the human if that happens.

**Goal condition.** The run's goal is met when every item in (1) and (2) has reached a terminal state (`done`, or `backlogged` after triage - see "Mid-run arrivals" below) and nothing has been added to (1) beyond what that section permits. Check this by iterating the two lists against `lc show <id>`, the same bookkeeping weight phase-gating already carries.

## Arm the watch before any autonomous action

Agreeing the Scope Statement does not itself watch anything - it is a conversation, not a mechanism. Before filing or activating a single thing, start the watch: a running poll or monitor against `lc inbox`, `lc active`, and `lc queue`, using whatever primitive the driving session offers. This is a separate, checkable action with its own artifact (a scheduled wakeup, a monitor id, a running loop) - state that artifact back to the human as part of the hand-over, rather than only a promise to keep watch. The run has not started until it exists.

Fire the watch on three conditions, watched together rather than any one in isolation:

- **A gate arrives** - `lc inbox`'s relevant-state count increases: a new spec-PR review, an `await-merge`, a blocked/parked step, a `review-findings` step, or a `review-held-comment` (an `HLD-` item's human step, decided with `lc done <step> approve|reject`).
- **A genuine stall** - nothing is active, nothing is queued, and `lc inbox` holds nothing for this scope either: work has stopped with no gate to show for it. Do not fire on "nothing is active" by itself - that is the ordinary state whenever a gate is already sitting in the inbox waiting on the driver, and a check that fires on it trains the driver to ignore the alert on the day it means something.
- **The board empties** - active and queued both reach zero, regardless of the inbox: wake to check whether that means the goal condition is met or everything is quietly blocked.

Arm two primitives, not one. An event monitor on `lc inbox` - a background loop that emits a line whenever a new in-scope gate id appears - is what wakes the driver within seconds of a gate arriving. A gate can also close as `head-moved` when the PR head changes under it, and come back with a new step id once CI and review re-run, so a watch that tracks ids should expect a gate to vanish and a fresh one to appear for the same item. While a `handle-feedback` step is open, the gate it watches is hidden from `lc inbox`, and the same gate can return with the same id - so a monitor that fires only on ids it has never seen misses it. Diff consecutive polls instead. A periodic check (a scheduled prompt or wakeup) is the backstop for the stall and empty-board conditions, which no new inbox line signals. A scheduled prompt fires only while the session is idle, so on its own a gate can wait a whole interval; a monitor expires on its own timeout and must be re-armed each time it does. State both artifacts back to the human. There is no fixed interval to recommend for the backstop, for the same reason there is none for a stall timer.

## File in batches, interleaved with driving

Never file every named item's derived work before reviewing a single gate. File one named item's worth of work at a time, then return to `lc inbox` and work whatever has arrived before filing the next named item's batch. If a gate is already waiting when a batch's filing finishes, work it before filing another batch - the board should never run more than one named item's filing ahead of what has actually been reviewed.

## Exit conditions

All three produce the same five-section Resumption Report (see below); only the report's one-line header differs.

1. **Goal met** - the Scope Statement's full set (named + snapshot) is terminal, with nothing added outside it.
2. **A decision only the human can make blocks all remaining in-scope progress** - every remaining item is waiting on it, or "Never in scope, ever" forbids proceeding without it. Surface the question the moment you find it, never batched. If the human is present in the same session, get the answer and continue without ending the run - this is the ordinary case, not an exit. The run only actually ends on this condition when the human is not present to answer and nothing else in scope can proceed without one. This condition is about a decision blocking ALL remaining progress; a question that blocks nothing is never grounds for this exit - see "Non-blocking questions" below.
3. **Explicit stop** - the human says stop, at any point, no ceremony required. "Stop" ends the autopilot run; it is not a request for the driver to run `lc stop`.

## Non-blocking questions are decided, not escalated

Exit condition 2 is for a decision that blocks everything remaining in scope. It says nothing about the far more common case: a question that blocks nothing, which feels safer to ask than to decide. During an unattended run it is not safer - asking stops the run dead until the human returns, for a question that was never actually in the run's way.

During an unattended run, a question that does not block progress is not asked; it is decided, recorded on the item or the PR the question arose on, and reported at the next checkpoint (see "Checkpoint report" below). Where the skill's own text already answers the question, follow the skill rather than escalating the apparent contradiction.

## Mid-run arrivals: retros, audits and findings

A `review-findings` step can appear on an audit/retro item mid-run, with no human involved in filing it: it is a stage of the scheduled audit workflows - scheduled audits route normally, so the audit step's report (its closing note) arrives in the gate's `inputs`, not as a `findings: lc show <step>` pointer. Match a watch on the `review-findings` stage rather than a note suffix, and read the audit step's `findings` artifact with `lc show` to learn what they are (a clean audit produces no step and nothing to see). Retros are not the only source: the periodic material audit also lands findings at `review-findings`. A material-audit finding is routed by kind: a guidance finding becomes a `guidance-entry` item; a workflow finding becomes an edit to the origin's step (when the origin is writable) or an upstream issue (when read-only); a `Promotion candidate:` line goes to the repo it names. The driver files any of these only after discussing it with the human, so unattended, record it as `DISCUSS:` or leave it for the human - never file one alone. This is the concrete event, not a vague "something new arrived."

**Rule: a `review-findings` step is always worked, but what it surfaces is never automatically in scope.** Read the report in `inputs`. Search the backlog first (the driver's existing "search before you file" discipline). If it names nothing new, close it out. If it names a genuine gap, file it into the backlog and stop there - never activate it in the same motion, no matter how urgent it looks. Activating it is a scope change, and only the human makes those (see "Never in scope, ever"). `review-findings` accepts only the outcomes `done`, `filed` or `reviewed`, and `lc done` refuses anything else: close with `filed` after filing, otherwise `reviewed`. `lc show <step>`'s `valid_outcomes` lists what is accepted.

**Mark every filed item with one of two states, stated on the item itself:**

- **A `DISCUSS:` title prefix**, only when what to do about the finding turns on what the human wants rather than something answerable by reading the code, running something, or measuring (the driver skill's open-question test) - and only after splitting off any part of the finding that is already settled into its own ready-to-build item. This marker is for a mid-run arrival under this heading; it is not a general license to withhold an ordinary filing elsewhere. Pair it with a `## Before activating - discussion required` section in the description naming specifically what must be settled, and list deleting the item as a live option wherever that is genuinely on the table.
- **No prefix, with readiness stated explicitly** (e.g. "Ready to build - no discussion needed"), when the finding and its fix are both settled and the item needs no conversation before it becomes work.

Never put either marker in the description's first 60 characters - `lc backlog`/`lc inbox` truncate a row's rendered description to that window, and a leading marker there would replace what the item is about. Where the workflow cannot yet be named because it depends on the discussion's outcome, its trailing `Workflow:` line reads `Workflow: undecided - see "Before activating"` rather than naming one prematurely.

## Never in scope, ever

1. **A design decision.** Propose a direction; never choose between open tradeoffs alone. Escalate per exit condition 2.
2. **Reverting a decision the human made.** Retraction is the human's hand on the PR comment that withdraws a request, same as the driver skill's own standing discipline; autopilot does not manufacture that on the human's behalf.
3. **Activating anything outside the Scope Statement's named-items set.** Covers "Mid-run arrivals" exactly, and any other new discovery mid-run.
4. **Anything touching the loader/spawner/config boundary.** The pipeline builds engine changes, loader and spawner included, but adopting one is the human's stop and `lc upgrade`: a change to what the pool spawns, claims or loads takes effect for every workflow at once. Build it, never adopt it.
5. **A merge or a park resolution that turns on a judgement call not priced into the Scope Statement.** Merge authority is scoped by the Scope Statement's fourth part (see "Agree the Scope Statement before starting") - granted or not, it covers only the mechanical merge of in-scope items, and never extends to a new judgement call surfacing mid-run. Authorization stands for the scope specified, not beyond it. Merging a no-change spec PR at `nochange-await-merge` closes the item with nothing delivered, so it is such a judgement call and sits outside mechanical merge authority.
6. **A trust decision on a held comment.** Never approve a held comment and never edit `trusted-authors`; both are trust decisions. Unattended, leave the held comment (or reject it if it is plain noise) and report it.
7. **Raw process control.** The pool's own shutdown is already safe - interrupting `lc start` (Ctrl-C, or SIGTERM) runs it, each worker has its own process group, and the pool's kill never signals its own group. `lc stop` signals a detached pool, and `lc stop --drain` spawns nothing new and exits once no worker is alive and no engine step (such as `poll-ci` or a script stage) is in flight; these are the safe routes. Never reach around them with a direct `kill`/`killpg`; stopping the pool at all stays the human's call, per `lc start` being theirs to run.

## Cost

No CLI command sums cost across items or a session - `lc`'s cost lookup resolves exactly one node at a time. Compute total spend for an item by listing its step ids (`lc trace <item> --json`) and summing each step's own `usage_cost_usd` (`lc show <step-id>`, which carries it directly), across every item currently in scope. If a TUI session is open, its already-rendered per-item cost total may be read directly instead of re-deriving it by hand. Each step also records `usage_api_calls`, a lower bound on its `gh` calls metered through the gh call log; sum it the same way when reporting API load. This is an observation for the two reports below, not a gate - nothing about the running total stops or slows activation.

## Rework: a new-defect test

Any rework edge without a cap is bounded only by this new-defect test. That includes `review-code rejected -> write-code` and the human `code-await-merge changes`, the `changes` edges of spec gates (`nochange-await-merge` included), and in `guidance-entry`, whose only cap is `pr_conflict_cap await-merge 3`, the `check-entries broken` loop. Continue sending an item back for another round for as long as each round's rejection or change request names something genuinely new - a defect the prior round's fix did not address, or that the prior round's own request did not already raise. The moment a round repeats a prior ask or finds nothing new to add, that is the trigger to stop and escalate (exit condition 2) instead of sending it back again, regardless of how many rounds have already run. Do not apply a numeric cap - a converging item can legitimately take several rounds, each finding something genuinely new, and a naive count would wrongly escalate it. The capped loops have an engine backstop: `ci_failed_cap` is real and escalates a CI-failure loop independently of autopilot, and every workflow with a CI stage declares `review_rounds_cap` on `watch-ci review-rework ... review-ci` (the `review-rounds-cap` config key).

## Reading a writer's decisions at a gate

`open-pr` quotes the previous step's closing note in the PR body under `## Closing note from <stage>`, and that note must name any deviation from the spec or brief. Read it there: it is where a writer's decisions surface at a gate.

## Sequencing engine and workflow items

A workflow item that uses a new engine field needs the origin's CI `ENGINE_PIN` bumped first. Follow the driver skill's rule on an item gated on an engine release also needing the origin's CI pin past it, rather than restating it here.

## Checkpoint report

Do not let the only report be the one at the end. Emit a checkpoint report at each merge, and at minimum once per named item that reaches a terminal state without one - whichever comes first - so a stretch with no merges still reports. Surface it through whatever channel this driving session normally uses to reach the human (a message, a posted note); do not leave it only in the session's own scrollback where nothing points the human at it.

Content is a lighter version of the Resumption Report's vocabulary below:

- **Merged** - since the last checkpoint, with PR links.
- **In flight** - what is currently active or queued.
- **Sent back or decided** - what was sent back and the new defect each round named, a round that corrected the driver's own earlier direction (a fix it proposed that was wrong, or a review claim it overstated) is marked as driver-caused, saying what the driver got wrong, and any non-blocking question decided per "Non-blocking questions" above, with what was decided.
- **Filed** - new ids since the last checkpoint, same split as the Resumption Report.
- **Cost so far** - total spend across items touched this run so far (per "Cost" above).

## The Resumption Report

Every exit produces the same five sections, headed by which exit condition fired:

- **Merged** - what, with PR links.
- **Sent back** - what, and the specific new defect each round's request named, not just "changes requested." A round that corrected the driver's own earlier direction (a fix it proposed that was wrong, or a review claim it overstated) is marked as driver-caused, saying what the driver got wrong, so the item does not read as troublesome for the driver's mistake. This stays inside "Sent back"; the report keeps exactly five sections.
- **Filed** - what, with new ids, split by kind: which carry the `DISCUSS:` marker and are waiting on the human's judgement, and which are stated ready to build outright - and, for all of them, that they landed in the backlog, never activated.
- **Deliberately not done** - what was in scope but left, and why: blocked on a never-in-scope call, or the run ended first.
- **Cost** - total spend across every item touched this run (per "Cost" above).
