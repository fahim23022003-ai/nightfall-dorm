# Phase 16 · Nightmare polish and performance

Phase 16 starts from `07b459b`. The local rollback branch
`phase16-rollback-07b459b` keeps that exact commit. The dedicated
launcher enables Phase 16 on the existing Living Nightmare preview
profile. Earlier launchers retain their earlier rules and can be used
for comparisons. The new release retains the same save schemas.

## Room Rush

In the slow Long Spine fixture, four runners chose the same initial
doorway. The final runner covered 14,055 world units through repeated
redirects, despite a 4,483-unit route from the common spawn. Advisory
destination selection now compares whole-route travel time, observable
competition, approach risk and room traits. It prefers to keep a
competitor's legal route when another runner loses a claim. Room
ownership still changes only through the existing physical claim.
Survivor speeds remain 180 and 90 world units per second.

The exact Spine fifth claim improved from 156.25 to 50.00 seconds.
Across the original 35 seeds, fifth-claim median and p95 improved from
75.75/114.50 to 40.25/60.25 seconds. All 125 matched opening cases
improved the fifth claim. All 45 matched human routes took the same
time to claim their room. A reroute remains synchronous and had a
25.84 ms headless p95 in the selected contest tests. Longer routes
remain possible on wide layouts.
[Room-race measurements and before/after Godot clips](evidence/phase16/room-rush-pacing/)

## Story and horror

The ten chapters now use distinct preparation periods and stagger
existing tactical and arcane threats. They also vary when Haunted Hall
recovery can start and which chapters foreground ordinary Hunters or
the Reaper. No new ability or global HP or damage multiplier was added.
The chapter and next mission, existing checkpoint, recorded rewards,
and newly discovered story information appear in the Story flow.
[Live encounter evidence and progression checks](evidence/phase16/story/)

Door impact and breach feedback follow the actual doorway direction.
Context alerts find space beside active controls. Existing original
tracks give quieter Story chapters different preparation moods. The
adaptive combat score, the one-time first personal siege heartbeat,
and control over volume and accessibility remain.
[Door pressure and live audio](evidence/phase16/horror/) · [Stalker and Reaper combat clips](evidence/phase16/combat/)

## Rendering

The 60-building Low baseline separated script submission from observed
wall time. The HUD update took 3.92 ms at the median, with 3.26 ms in
the action list on a second scoped run. Architecture command building
took 2.05 ms, including 1.14 ms in machine rendering. The articulated
rig took 0.125 ms. The remaining wall time includes software
rasterization and presentation. The separate instrumented comparison
measured the HUD update at 4.09 → 0.70 ms and its action list at
3.26 → 0.05 ms on the 60-building Low replay. World draw command time
was 3.25 → 3.55 ms in that diagnostic run.

The closed Build drawer no longer recalculates hidden card prices,
tooltips and availability. It updates them when opened. The Hunter
readout resizes when its displayed value changes. Low draws inactive
ordinary support machines using composited rest frames from the
existing atlases. Operating parts, attack rhythms, telegraphs and
all Hunter and Reaper rigs remain in the normal render path.

Matched 1280×720 Linux llvmpipe combat results, in milliseconds per
frame. Each pair retained identical geometry and combat event hashes.

| Live combat | Standard median / p95 | Low median / p95 |
| --- | ---: | ---: |
| Stalker, 24 machines | 61.16 / 80.67 → 53.03 / 77.99 | 50.37 / 60.44 → 39.42 / 42.82 |
| Stalker, 40 machines | 67.58 / 79.92 → 60.79 / 81.68 | 63.39 / 85.11 → 42.07 / 52.78 |
| Stalker, 60 machines | 81.70 / 100.54 → 79.44 / 110.50 | 74.13 / 97.39 → 43.18 / 54.12 |
| Grim Reaper, 60 machines | 80.51 / 109.81 → 79.92 / 108.45 | 74.01 / 103.12 → 41.71 / 52.06 |

The Low Stalker median draw-call count at 60 machines fell from 613
to 525. Standard median improved in every replay, while the 40- and
60-machine Stalker p95 rose. Standard therefore still has dense-room
frame-pacing work outstanding. At 60 machines on Low, Godot's software
renderer graphics memory increased from 131.9 to 139.8 MiB for Stalker
as the rest atlas was cached, while engine static memory went from
165.5 to 165.8 MiB. Hardware GPU timing was unavailable.
[Matched timings, images and raw instrumentation](evidence/phase16/performance/)

## Release verification

The complete Story matrix covers ten procedural families, all six
ordinary Hunter archetypes, three difficulties and several sensible
defense policies, including earned-item and item-free pairs. The
receipts retain both wins and losses, including a Hard room that was
breached after Phase 16 despite the player dealing 2,576 damage. All
five AI survivors reached beds in 35/35 Phase 16 runs (33/35 before).
The automated matrix recorded 23 wins after Phase 16 versus 17 before.
These are outcomes for the tested policies and seeds. Two item-free
attempts in the same Hell finale reached the Reaper and still lost.
Fifteen regression suites passed 2,941 checks.
[Full match receipts and regression results](evidence/phase16/match-matrix/)

The Windows x64 release uses the official Godot 4.6.3 template.
Linux Godot verifies the playable offline Story lobby and the
preserved Hunter atlas inventory from the embedded pack. Native
Windows and Intel UHD verification remain pending.
[Windows instructions and reproduction steps](PHASE16_WINDOWS_PLAYTEST.md) · [Package checksums](evidence/phase16/windows/)
