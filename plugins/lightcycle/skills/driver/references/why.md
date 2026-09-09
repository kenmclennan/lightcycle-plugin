# Why: the incident behind select driving disciplines

Read this for the story behind a rule, not to act on it - the rule itself is in `SKILL.md`.

## An approved spec is FILED, never implemented

A session once carried an approved design to the brink of self-implementation because the brainstorming skill's terminal state captured the driver - the human had to ask "are we using lc to do the build?". That question should never be needed.

## Freeze a spec once its item is building

The one time a driver parked a spec-contradicting decision on the item description instead of raising it on the code PR, an agent that found it there had no sanctioned route but to manufacture the PR comment that authorized it.

## Verify the inputs before you activate - the description is now a stale-value problem, not a missing-value one

This used to be a missing-value problem before `lc new item` started refusing activation without a `--description`; now the same failure shows up as a stale value instead - the field is never empty, but it can still be the wrong text, an old capture never developed into a brief.

## A finding an agent cannot file is yours to file, at the gate it surfaces on

This has cost four findings so far, all recovered late and only by accident. LC-333's spec declined two defects, wrote "Left for the driver to file", and was read by five agents and merged with neither filed (now LC-358, LC-359). And the same flaky test was fixed ad hoc in two unrelated items, LC-332 and LC-344; `review-code` rejected both hunks correctly and both times wrote that a human should file it as its own item - nobody did, so the defect was independently rediscovered and reimplemented months apart and is still unfixed (now LC-366). A rejected hunk plus an unfiled finding is worse than either alone: the work is thrown away AND the knowledge that it was needed goes with it.

## Search the backlog before you file a finding

This has already happened: a finding sat in the backlog through three retros, was independently rediscovered, and was re-filed two batches later after three agents each re-derived the underlying fact.

## Fetch before you claim something is absent

This has already produced a brief whose central premise was false - two rules it called "never filed" were filed and merged, so the item was scoped to restate text that already existed.

## A clean pass from the reviewing step is an input to your review, not a substitute for it

This has already caught two defects past a clean pass in a single session: a spec that argued a never-cleared label was harmless because the step is an agent's "from the moment unblock returns", missing that the same step id parks again later for a different reason; and a new sort key over a field the domain declares `Optional`. Neither was findable by checking the diff against its spec, because both matched it exactly.
