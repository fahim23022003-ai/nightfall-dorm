# Phase 16 Room Rush pacing

The opt-in Phase 16 launcher enables advisory opening and reroute decisions with `NIGHTFALL_PHASE16=1`. The previous launcher keeps its existing decisions. The new policy compares reachable travel times for the five NPCs and prefers plans with an earlier last arrival. Among similarly paced plans it considers distance, exposed approaches, room traits and individual preferences. NPC intentions do not reserve rooms. A player can claim any available room in person. A displaced NPC replans from its current position while other competitors keep their legal routes when possible. If no matching plan can reuse those routes, the planner checks all reachable routes. If reachable routes overlap, NPCs can still race for the same available room. The player moves at 180 world units per second and NPCs move at 90.

## Reproduction and results

The previous policy sent four NPCs toward the same doorway on Long Spine, seed 8649, attempt 41. The last NPC followed room 02 → 05 → 01 → 06 → 03, walking 14,055 world units. That room was 4,483 units from the original shared spawn by a legal route. With the new decisions, the last NPC walked those 4,483 units and claimed at 50 seconds. The first claim remained 10.25 seconds. The same six bodies start at (2416, 2136), with identical generated geometry and the same available rooms.

Each policy ran 125 fixed-step opening simulations. These reuse the original 35 samples and add 45 longer-route Long Spine, Labyrinth and Branching configurations across all five themes, each run with an idle and with a contesting human. The latter walks to the closest room and claims upon physical arrival. All 125 pairs preserved the same geometry hash, shared spawn and direct route lengths. All 45 human claim times were identical across policies. Each test finished with five NPC claims and no NPC movement-budget violations. These fixtures measure the opening race.

| Fixtures | NPC claim | Previous median / max | Phase 16 median / max |
| --- | --- | --- | --- |
| Original 35 | First | 3.50 / 18.50 s | 3.50 / 18.50 s |
| Original 35 | Third | 39.25 / 63.50 s | 27.00 / 47.25 s |
| Original 35 | Fifth | 75.75 / 156.25 s | 40.25 / 60.25 s |
| Longer routes, 45 idle | First | 4.00 / 18.75 s | 4.00 / 18.75 s |
| Longer routes, 45 idle | Third | 34.25 / 101.00 s | 23.50 / 48.50 s |
| Longer routes, 45 idle | Fifth | 69.50 / 138.00 s | 34.50 / 69.25 s |
| Longer routes, 45 contested | First | 14.75 / 41.75 s | 13.75 / 35.25 s |
| Longer routes, 45 contested | Third | 39.25 / 78.25 s | 29.00 / 49.50 s |
| Longer routes, 45 contested | Fifth | 85.75 / 193.75 s | 46.25 / 76.50 s |

The fifth claim was quicker in all 125 pairs. Median combined NPC travel fell from 17,843 to 11,103 world units on the original 35, from 14,372 to 10,127 on longer idle routes and from 20,213 to 13,519 on contested routes. The focused regression suite completed 516 checks with Phase 16 and 507 with the previous policy, with zero failures in both runs. The suite covers deterministic decisions, no inferred reservation, displaced rivals, saved positions, traversal speed and a blocked approach that triggers local recovery.

The table below also reports nearest-rank p95. The opening conflict count
counts additional runners sharing another runner's initial destination.

| Fixtures | Opening conflicts before → after | Fifth claim p95 before → after | Redirects before → after |
| --- | ---: | ---: | ---: |
| Original 35 | 131 → 0 | 114.50 → 60.25 s | 283 → 0 |
| Longer routes, idle | 169 → 0 | 113.00 → 63.00 s | 353 → 0 |
| Longer routes, contested | 169 → 0 | 144.00 → 72.00 s | 519 → 45 |

An instrumented repeat counted 625 physical NPC claim transactions
per policy. Both arms recorded zero denied NPC claims and zero denied
human claims on their prescribed valid routes. Opening-direction
conflicts show up as later redirects in the previous policy.
[Per-case claim transaction counts](claim-attempts.json)

## Native Godot evidence and performance limits

The nine-second, 1280×720, 24 FPS Godot clips show the same active human route in the Linux Compatibility renderer using llvmpipe, with no soundtrack. The human reaches and legally claims room 02 at 5.0 seconds in both versions. The companion map screenshots show the opening immediately after the claim. The headless logs follow the full opening past the short video.

- [Previous opening](spine-legacy.mp4)
- [Phase 16 opening](spine-phase16.mp4)
- [Shared spawn](spine-shared-spawn.png)
- [Phase 16 human claim](spine-human-claim-phase16-1.png)
- [Previous map positions](spine-map-phase16-0.png) and [Phase 16 map positions](spine-map-phase16-1.png)

Headless Linux wall-clock median setup was 6.21 ms before and 7.62 ms after. In the 80 idle cases, the planner ran once at initialization and took 0.48 ms median and 1.00 ms approximate p95. Each contested case ran one additional replan after the human claim. The per-case peak planner time across those cases fell from 33.39 ms median, 66.19 ms approximate p95 and 88.20 ms max in the full-replan prototype to 10.68 ms median, 25.84 ms approximate p95 and 32.54 ms max with selective replanning. Selective replanning redirected each losing NPC once. Fifth claims were 0.75 seconds later at the median with this refinement. These step costs were measured under shared machine load. They represent a possible one-frame stall on a claim and do not establish render FPS or native Windows or Intel UHD performance. The native Phase 16 capture exited with a Godot ObjectDB warning after reporting successful checks.

- [Original 35 reproduced](baseline-original-35.log)
- [125 previous-policy measurements](matched-baseline.log)
- [125 Phase 16 measurements](matched-candidate.log)
- [125 full-replan prototype measurements](matched-full-replan-prototype.log)
- [Phase 16 regression](phase16-suite.log)
- [Previous-policy regression](fallback-suite.log)
- [Paired benchmark source](../../../../tools/nightmare_maps/measure_room_rush_pacing.gd)
- [Viewport capture source](../../../../tools/capture_room_rush_pacing.gd)
