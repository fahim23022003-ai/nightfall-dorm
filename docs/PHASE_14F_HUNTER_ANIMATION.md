# Phase 14F — Hunter animation and directional art

Phase 14F starts from Phase 14E at `0fce840`. The updated art and motion
are available in the Godot preview with `NIGHTFALL_VISUAL_REBIRTH=1`.
The regular launch continues to use the established fallback. The catalog
retains 232 baseline states and 200 reachable specialization variants.

## Hunter motion

The preview uses the existing model's attack count and ability release
events for motion cues. An impact from a delayed bolt or persistent
channel no longer restarts the release pose. The localized deformation
keeps the character connected through the movement, strike and recovery
poses. Animation advances with the encounter clock when time freeze
is active.

Crusher shifts weight into the planted leg and drags the second arm behind
the step. Ravager alternates front contacts and hind-leg movement. Stalker
separates the motion of hair locks and the dress hem. Witch shows a glide,
sleeve follow-through, and gestures for telegraph and release. Electric
Ghost moves its wrists and coat out of phase. Storm Wraith delays cloth
motion along the length of its mantle. The Reaper reacts to the existing
approach, transformation, ability warnings, attacks and recovery. The held
scythe leaves the hand while the actual model scythe is flying or embedded.

A continuous texture mesh supplies each character's silhouette. Full
cardinal sets are separate, view-specific 2D illustrations informed by
the matching approved oblique. Only states with all four reviewed views
count toward independent direction coverage. The same-stage oblique is
still available at unsupported angles. Motion on a projected silhouette
can represent gliding, reaching, or contact shifts within the limits of
the painted pose.

## Direction coverage and footage

| Catalog | Independent front, rear, left and right | Oblique-only states |
| --- | ---: | ---: |
| Crusher | L1–L10 | 0 |
| Stalker | L1–L10 | 0 |
| Ravager | L1–L10 | 0 |
| Phantom Witch | L1–L10 | 0 |
| Electric Ghost | L1–L10 | 0 |
| Storm Wraith | L1–L10 | 0 |
| Grim Reaper | Both forms | 0 |

Phase 14F added **228 cardinal sprites** across the remaining 55 ordinary
states and both Reaper forms. The prior five sets and all original southwest
art are retained. The strict Godot verifier checked every direction, the
original oblique route and **20,099,712** pose triangles with zero inverted
triangles. [Art sources, galleries and geometry log](evidence/visual-rebirth/phase14f/directions/README.md) · [Exact asset mapping](evidence/visual-rebirth/ASSET_MANIFEST.json)

The six chaptered films contain 3,836 real 1280×720 Godot frames. Each of the
24 L1/L4/L7/L10 chapters demonstrates five texture bindings, movement,
turning, normal approach, an ordinary attack warning and strike, and a reaction
to a paid Needle hit. The rooms and comparison levels were prepared for repeatability.
[Hunter gameplay gallery](evidence/visual-rebirth/phase14f/hunters/hunter-telegraph-gallery-720.png) · [All six films and event receipts](evidence/visual-rebirth/phase14f/hunters/README.md)

The Reaper footage confirms the actual transformation and Soul Siege impact.
A second controlled capture sets transformed HP to 9% to exercise the
existing Crimson Execution trigger. The release pose, scythe throw and
throw audio cue occur at frame 73. The embed event and cue occur at frame 93.
[Both forms’ cardinal views](evidence/visual-rebirth/phase14f/hunters/reaper-cardinals-720.png) · [Transformation and Siege](evidence/visual-rebirth/phase14f/hunters/reaper-forms-and-siege.mp4) · [Crimson Execution](evidence/visual-rebirth/phase14f/hunters/reaper-crimson-execution.mp4) · [Crimson event receipt](evidence/visual-rebirth/phase14f/hunters/crimson-motion.json)

The footage uses staged fixtures and silent MP4s. Audio cue timing comes
from the actual audio director. In-game proof covers the 24 ordinary anchor
states and both boss forms. The other ordinary stages have resource,
direction and geometry checks. The 2D views still change discretely on a
turn, and hair, folds and obscured limbs can vary across angles. Subjective
motion and artistic approval remain open.

## Building and core review

Godot rendered all **17 families**, **170 baseline states** and **200
specialization variants** in the catalog audit. The 2,284 staged variation
checks and 198 reduced-motion checks distinguish tracked weapon headings,
recoil and firing from operating support cycles and fixed housings. Bed, Door,
Mirror Barrier and Ward Antenna have fixed authored bodies and separate
purpose-specific effects. The renderer now separates live support activity
from cooldown status. The six paid Auto Repair, Shield and Decoy branches
passed 149 checks and visibly returned to rest after expiry.
[Building audit and paid gameplay captures](evidence/visual-rebirth/phase14f/buildings/README.md)

## Performance

Matched 1280×720 Stalker L10 turns in a 16-slot room. The benchmark used
Linux Mesa llvmpipe with Godot 4.6.3 and identical route and sampled model
digests. Each trace sampled 348 frames, including 29 actual texture switches.

| Preset | Median before / after | Overall p95 before / after | Texture-switch p95 before / after |
| --- | ---: | ---: | ---: |
| Standard | 42.084 / 43.588 ms | 55.116 / 55.650 ms | 72.459 / 55.650 ms |
| Low | 40.002 / 40.364 ms | 48.022 / 50.737 ms | 48.401 / 58.249 ms |

The current-level pose cache and retained mesh reduced actual distinct mesh
instances from **30 to 1** in both presets. Estimated rendering memory stayed
near 148.58 MB. Standard’s switch tail improved in the paired run. Low’s
paired tail was higher and an earlier Low baseline varied substantially.
The benchmark isolates the Stalker changes at `2542e93`. Windows and Intel
UHD performance remain unmeasured. [Raw traces and reproduction](evidence/visual-rebirth/phase14f/performance/README.md)

## Regressions

The final preview passed 1,837 gameplay, scene, settings, save, visual
identity, culling and Nightmare checks. The audio gate passed 169 checks.
Fallback startup passed 33 checks. The commits are scoped to assets,
presentation, evidence and the roadmap. [Final engine logs](evidence/visual-rebirth/phase14f/final-validation/)

## Future room grid

The [owner-approved roadmap](MASTER_ROADMAP.md#owner-approved-next-project--full-room-grid-building)
records full-floor grid placement after visual approval, with physical
footprints, collision-safe movement and rotation, pathfinding, performance
and save migration.
