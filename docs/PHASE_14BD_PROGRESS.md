# Phase 14B–14D visual production checkpoint

Source commit `23d002d8351bc1a6e9b404369b0a8f1f470ac98b` continues the Phase 14A preview. Use the Visual Pilot launcher on Windows or set `NIGHTFALL_VISUAL_REBIRTH=1` when launching Godot.

| Catalog | Integrated Phase 14 states | Baseline target |
| --- | ---: | ---: |
| Ordinary Hunters | 11 | 60 |
| Grim Reaper | 0 | 2 |
| Buildings and cores | 40 | 170 |
| **Total baseline** | **51** | **232** |
| Specialization variants | 48 | 204 required branch-level combinations |

The 204 specialization target is based on 34 actual branches in the game, applied at Levels 5–10. The 48 implemented variants are two branches per role for Needle, Arc, Dynamo and Repair Station. The remaining baseline work is 49 ordinary Hunter levels, two Reaper forms and 130 building levels. The integrated figures count a level once. Multiple camera views, frame poses, layers and rotation samples are not additional levels.

## New and revised runtime assets

- **Phantom Witch L1–L10.** Nine generated 2D evolution drawings use the 104-pixel body scale and the same foot pivot. Raised shoulder and hair arcs, split veils, a hair halo, widened veil tails and the final frost crown change the outline. L1 retains five drawn views. L2–L10 use a single oblique gameplay drawing per level. The sprites use visible mesh-deformation regions for hair, dress and gesture, with model-timed tells, attacks and evolution. Independent anatomy textures and skeletal joints remain open. At L8 the veil approaches the edge of the door HP panel, with numeric HP and the bar readable. The 720p gallery uses a prepared 16-slot fixture with level fields staged for comparison. [Godot L1–L10 gallery](evidence/visual-rebirth/witch-evolution/witch-levels-godot-720-crops.png)
- **Dynamo and Repair Station.** Both add ten baseline levels and twelve existing branch states, baked as 2D atlases from authored Blender geometry. An eight-frame moving layer animates a flywheel during production and cranks, carriage and hook during repair. Dynamo follows occupied, active production. Repair uses the existing funded repair status, including the full-door and reserve checks. Reduced motion holds the mechanical frame still. Geometry varies through the intermediate levels. The smallest adjacent silhouettes still require close inspection at normal zoom. [Dynamo bake](evidence/visual-rebirth/phase14bd/dynamo-atlas-gallery.png) · [Repair Station bake](evidence/visual-rebirth/phase14bd/repair-atlas-gallery.png)
- **Needle and Arc.** Revised structures, stabilizers, crank housings and branch housings are readable at gameplay scale. At a common capture bearing, the real Godot silhouette difference for L1→L2 rose from 4.19% to 13.55% on Needle and from 5.14% to 9.80% on Arc. The L2→L3 comparison rose from 5.32% to 10.83% and 5.03% to 10.82% respectively. Measurements use mask symmetric difference divided by union with aligned screenshots. Both turrets have 108 distinct adjacent baseline mask pairs over all twelve headings. Arc's unspecialized L4→L5 remains the subtlest. [Needle bake comparison](evidence/visual-rebirth/phase14bd/turret-baked-comparison.png) · [Arc bake comparison](evidence/visual-rebirth/phase14bd/heavy-baked-comparison.png)

## Rendering costs

The renderer loads a pair of baked atlases when a supported building is drawn. High-quality desktop BPTC and mobile ASTC imports replace uncompressed runtime atlases. Raw PNG sources remain available. A single radial gradient texture replaces eight overlapping translucent haze disks. Viewport bounds reject off-screen room, Hunter, projectile, event and badge drawing. This skips drawing and leaves gameplay updates untouched.

Stalker mesh transitions reuse one dynamic surface and update vertex positions. Twelve real graphical comparisons were pixel-identical to the former rebuild approach. All 36 socket comparisons matched. In an isolated five-trial, 3,500-update microbenchmark, median update workload fell from 67.833 ms to 44.949 ms. This 33.7% improvement measures the pose blend alone.

The matched 1280×720 benchmark compares Phase 14A and this revision with both previews enabled, medium settings, 30 warmup frames and 240 sampled frames per run. It uses AMD EPYC 9V74 and Mesa llvmpipe on Linux.

| Order | Phase 14A median / p95 | Current median / p95 |
| --- | ---: | ---: |
| Phase 14A then current | 32.19 / 38.84 ms | 39.87 / 53.09 ms |
| Current then Phase 14A | 32.55 / 39.97 ms | 37.15 / 44.57 ms |

Godot reported 138.6 → 119.6 MiB of render video memory in both pairs, down 13.7% with the additional catalog art. Frame time got worse in both orders and the 16.7 ms target remains unmet. The comparisons do not isolate the cause of the regression. Results apply only to this software renderer. [Matched A/B evidence](evidence/visual-rebirth/phase14bd/enabled-comparison/)

## Regression checks

Core, scene, spatial-save, cinematic and Nightmare Hunt passed 403 focused checks. Both benchmark pairs passed 185 fixture checks per mode and reproduced the same sampled gameplay-state digest and combat events. The 720p low/reduced-effects test opened all 16 building slots and left sampled state unchanged. The Witch gallery passed 185 preview checks, including exact level bindings and 39,168 positive-area deformation triangles. The matched baseline gallery passed 173 checks.

The final Dynamo and Repair gameplay fixtures passed 32 checks each, including both paid branch ladders through L10. In the staged Dynamo test, the room produced 21 Electricity in half a second and zero while paused. The staged Repair run restored 75.25 HP in half a second and stopped at the 2,070 HP cap. The aligned Godot level matrices exercise each ordinary and branch row. Some support silhouettes miss the Art Bible's approximate major-change target, including Repair L3→L4 and Dynamo L6→L7. [Actual gameplay fixtures](evidence/visual-rebirth/phase14bd/support-work/) · [Level matrices and mask measurements](evidence/visual-rebirth/phase14bd/building-gallery/)

The final action capture uses 144 actual Godot viewport frames at 24 fps. Its prepared Endless encounter produced seven Needle launches and impacts and five Stalker door strikes. The video is silent. [Godot combat demonstration](evidence/visual-rebirth/phase14bd/stalker-and-needle-combat.mp4)

## Quality gate

The runtime catalog remains incomplete. Only the Witch has a full ordinary Hunter level progression, and only its L1 has independent directional 2D views. Other Hunters and the Reaper require character-specific evolution art and animation work. The four new or revised building families establish the production path, while several adjacent states still have subtle transitions and the rest of the catalog has existing fallback art. The L10 Repair canopy partially overlaps small room-trait text on the upper pad in the dense fixture. The target hardware and full-catalog performance remain open.

The private Windows x64 export comes from the source commit above. Linux verified the ZIP CRC, Windows executable headers, the embedded project and actual pilot assets. The standard pack verification passed 77 checks and the additional preview and fallback probes passed 38 checks apiece. The ZIP contains separate launchers that share a dedicated playtest profile. Native Windows execution remains unverified. [Windows export evidence](evidence/visual-rebirth/phase14bd/windows/)
