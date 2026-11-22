# Writing a callout function

A callout function is the executable behind a `callout-<id>` config block. The engine runs it when a human gate opens (and again to clean up when it closes) and shows what it returns on the gate's Detail tab. The full contract (request, response, preflight, timeouts) is in [the engine's `docs/callouts.md`](https://github.com/kenmclennan/lightcycle/blob/main/docs/callouts.md); this page is only the practice around it, so it does not copy the protocol.

## The shape

- The function reads one JSON request on stdin and writes one JSON response on stdout, then exits. The `verb` field says whether it is a `run`, a `preflight` or a `cleanup`; switch on it explicitly, because a function that treats every unknown verb as `run` rebuilds its output when the gate closes.
- The request's `step.principal_output` is the principal output of the gate the function was started for, such as `spec` or `code`; the engine starts the function only at gates whose principal output its config block lists in `principal-outputs`.
- It never routes, closes or parks a step. Its only effect on the pipeline is what it adds to the Detail tab and the cost it reports.

## Practice

- **Preflight answers fast and never does the work.** Check that tools exist and the repository is set up, and return. The engine runs it in `lc doctor`, after `lc config set` changes a callout, and before each gate run.
- **Report what the function spends.** A function that runs agents or a paid service may add an optional `usage` object, `{cost_usd, model}`, to its `run` response. The engine adds `cost_usd` to the gate step's cost, on an `ok` or a `failed` answer alike, but not when the function exits non-zero, times out or writes invalid output. `model` is optional. A malformed `usage` makes the whole response invalid, so keep `cost_usd` a number from 0 to 1000000. A preflight carries no `usage`.
- **Answer `cleanup` by removing only what the function built.** The engine sends it once after the gate that ran the callout closes (within 7 days), with the same item and subject as the run plus the gate's `outcome`. Removing a view or a ref that is already gone is success, so make it idempotent: it can arrive for a run that failed partway or built nothing, and again after an engine upgrade. Do not assume `repos.workspace` exists, since a gate closed by merge has no open workspace. The response is the run response; `artifacts` are discarded and `usage` is recorded.
- **A cleanup never holds anything.** It cannot hold the gate, change the step's state, outcome or routing, or be retried. A failure, timeout or bad output shows only as a `callout:<id>: cleanup failed - <message>` condition note on the step, so put the reason in `message`.
- **Every error carries a `fix`.** Name the command the operator can run to repair the problem, not only what is wrong.
- **Scope the function with its block's `principal-outputs`, not with a check of its own.** The engine starts it only where the principal output matches, so a spec view lists `spec` and a review view lists `code`. If a gate still gives it nothing to act on, return `ok` with a short text note instead of failing: a failure is recorded and shown as a problem.
- **The callout's `timeout` is the only bound on a run.** The engine kills the process at the limit, so do not add a second clock inside the function.
- **The function holds only the tool knowledge.** The engine knows nothing of the tools the function calls, and those tools know nothing of the engine, so each can change without the other.

## Testing

Keep the function's own collaborators (the tools it shells out to, any network or paid service) behind ports, so a test can swap in fakes. A test then runs without network or spend, and exercises the request and response handling directly.
