# Phase 18 geometry and model receipts

Controlled tests compare the same seeds and scripted purchase policies.
Normal, Hard and Hell Story runs include all ten macro-layout families.
The focused Campaign cases walk from spawn, claim through the normal
interaction and use the actual economy. Geometry samples cap outward
rays at 400 logical units. These are Linux Godot 4.6.3 tests.

- [200 matched map fixtures](structure-release.log)
- [35 original Room Rush fixtures, V2](rush-final-0.log) · [V3](rush-final-1.log)
- [Complete Story baseline](story-0.json) · [Close Quarters](story-final.json)
- [Reproduced Hell opening policies, V2](counterplay-0.json) · [V3](counterplay-1.json)
- [Other walked Labyrinth and Hybrid routes, V2](physical-fair-0.json) · [V3](physical-fair-1.json)
- [Endless V2 with 17 paid structures and inverse toggle on resume](regressions/dense-endless-0.log) · [V3](regressions/dense-endless-1.log)

Both dedicated Endless runs passed 38 checks. The normal save regression
also passed with its default fixed-geometry fixture. Forcing the entire
old suite onto procedural geometry reproduced the same two setup failures
in V2 and V3 in its deliberately impossible migration fixture. The saves
tested by the focused procedural subtest resumed successfully.

[Legacy and integration regression logs](regressions/)
