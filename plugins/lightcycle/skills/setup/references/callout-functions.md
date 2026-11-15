# Writing a callout function

A callout function is the executable behind a `callout-<id>` config block. The engine runs it when a human gate opens and shows what it returns on the gate's Detail tab. The full contract (request, response, preflight, timeouts) is in [the engine's `docs/callouts.md`](https://github.com/kenmclennan/lightcycle/blob/main/docs/callouts.md); this page is only the practice around it, so it does not copy the protocol.

## The shape

- The function reads one JSON request on stdin and writes one JSON response on stdout, then exits. The `verb` field says whether it is a `run` or a `preflight`.
- It never routes, closes or parks a step. Its only effect on the pipeline is what it adds to the Detail tab.

## Practice

- **Preflight answers fast and never does the work.** Check that tools exist and the repository is set up, and return. The engine runs it in `lc doctor`, after `lc config --edit`, and before each gate run.
- **Every error carries a `fix`.** Name the command the operator can run to repair the problem, not only what is wrong.
- **A gate the function does not apply to returns `ok`.** Say so in a short text note instead of failing: a failure is recorded and shown as a problem.
- **The callout's `timeout` is the only bound on a run.** The engine kills the process at the limit, so do not add a second clock inside the function.
- **The function holds only the tool knowledge.** The engine knows nothing of the tools the function calls, and those tools know nothing of the engine, so each can change without the other.

## Testing

Keep the function's own collaborators (the tools it shells out to, any network or paid service) behind ports, so a test can swap in fakes. A test then runs without network or spend, and exercises the request and response handling directly.
