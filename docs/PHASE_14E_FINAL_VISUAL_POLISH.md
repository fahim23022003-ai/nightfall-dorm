# Phase 14E visual polish preview

Phase 14E builds on `deda944`. Enable the preview with
`NIGHTFALL_VISUAL_REBIRTH=1` before launching Godot. The ordinary launch still
uses the existing fallback. In desktop Settings, **Standard** uses the existing
`medium` preset and **Low** keeps the new art, silhouette lighting and combat
telegraphs while reducing atmospheric and secondary effects. High and the
accessibility overrides remain available. Saved graphics preferences keep their
existing keys.

## Gameplay presentation

- The projected Hunter and Reaper bodies receive localized backlighting and a
  cool midtone lift. Concealment and death still attenuate the light. Rooms
  retain their existing lighting. Low omits optional spectral trails and lowers
  Reaper smoke density.
- All 15 Level 10 placeable machines use function-specific front details and
  materials on the existing atlases. Needle gets polished dart guides, Arc
  copper conductor clips, Flame heat vents, and Shield stained glass. Animated
  assemblies, recoil and gameplay effect anchors retain their existing timing.
- Focused desktop rooms reserve space for the HUD, toolbar and a side
  inspector. The camera includes nearby attackers smoothly as they approach.
  The side inspector opens without moving the room or changing click-to-world
  mapping. Strategic overview, onboarding and mobile retain their established
  framing and controls.
- The catalog still contains **232 baseline states and 200 reachable
  specialization states**. Stalker L1/L10, Phantom Witch L10 and Storm Wraith
  L10 add independent front, rear, left and right 2D art alongside their
  checkpoint obliques. Witch L1 retains its five views. The other 55 ordinary
  states retain their correct art at all headings. A single oblique can reflect
  left and right and holds that projection for near-vertical movement. These
  states still need independent cardinal art.

## Visual evidence

The captures use the running Godot game with a scripted approach, legal
placement and upgrades from prepared funds.

- [Crowded room before](evidence/visual-rebirth/phase14e/dense/checkpoint-standard-720.png) · [Standard after](evidence/visual-rebirth/phase14e/dense/final-standard-720.png) · [Low after](evidence/visual-rebirth/phase14e/dense/final-low-720.png)
- [Inspector before](evidence/visual-rebirth/phase14e/dense/inspector-before-720.png) · [Side inspector after](evidence/visual-rebirth/phase14e/dense/inspector-after-720.png)
- [Standard settings](evidence/visual-rebirth/phase14e/dense/settings-standard-720.png) · [Low settings](evidence/visual-rebirth/phase14e/dense/settings-low-720.png)
- [24 anchor views at native gameplay scale](evidence/visual-rebirth/phase14e/hunters/hunter-anchors-720.png)
- [Previously reviewed Storm Wraith L10](evidence/visual-rebirth/continuous-final/storm/storm-level-10-720.png)
- [Previously reviewed Ravager L10](evidence/visual-rebirth/continuous-final/ravager/ravager-level-10-720.png)

- [Polished Storm Wraith L10 and all 15 L10 machine families](evidence/visual-rebirth/phase14e/hunters/storm-l10-720.png)
- [Polished Ravager L10 and all 15 L10 machine families](evidence/visual-rebirth/phase14e/hunters/ravager-l10-720.png)
- [Stalker L10 movement and Hollow Oath](evidence/visual-rebirth/phase14e/hunters/stalker-l10-direction-and-oath.mp4)
- [Storm Wraith L10 turning](evidence/visual-rebirth/phase14e/hunters/storm-l10-direction-motion.mp4)
- [Phantom Witch L1 turning](evidence/visual-rebirth/phase14e/hunters/witch-direction-motion.mp4)
- [Direction artwork and source process](evidence/visual-rebirth/directional-stalker/README.md)

The comparison plate uses 24 unscaled crops from 1280×720 in-game frames.
The Stalker clip follows model navigation along a scripted walkable route.
Once the Hunter reaches the door, the fixture sets the existing skill
cooldown to zero. Normal game ticks emit the warning at frame 177 and release
and impact at frame 245. The model records 14.432 HP lost on the door and the
renderer binds the tell and strike poses. Both clips use silent 24 fps
viewport frames.

## Performance

Matched 1280×720 Stalker and 16-slot Endless fixture, seed 67. It contains
one Level 10 machine from each of the 15 placeable families and one additional
Level 1 Needle. Each run sampled 240 frame waits after 30 warm-up frames.
Godot 4.6.3 used GL Compatibility on Linux with Mesa llvmpipe software
rendering. These are wall-clock frame waits and Godot's render-memory estimate.

| 720p preset | Median | p95 | Max | Godot render-memory estimate |
| --- | ---: | ---: | ---: | ---: |
| Checkpoint `deda944`, medium | 40.464 ms | 55.980 ms | 78.616 ms | 140.77 MiB |
| Phase 14E Standard | 42.688 ms | 49.212 ms | 100.415 ms | 146.41 MiB |
| Phase 14E Low | 41.580 ms | 47.764 ms | 74.108 ms | 146.41 MiB |

Standard's median was 5.50% higher than the checkpoint, and its p95 was
12.09% lower. Low reduced the Standard median by 2.60% and p95 by 2.94%.
The three samples produced the same model digest. Native Windows hardware
was unavailable. The timing fixture exercised Stalker. [Benchmark receipt](evidence/visual-rebirth/phase14e/dense/comparison.json)

## Verification

- The source resource and startup gate passed **146 checks per launch mode**
  on Linux, covering both opt-in and fallback and the added runtime textures.
- Camera assertions passed **90 opt-in and 30 fallback** checks. The HUD
  gate passed **135 opt-in and 130 fallback** checks, including real purchase
  callbacks and stable framing. The atmosphere test passed **1,116** checks.
  [Engine logs](evidence/visual-rebirth/phase14e/validation/)
- Hunter captures passed **338** progression and direction checks. The
  Stalker L10 clip passed **25**, the Witch L1 clip **20**, and the Storm
  Wraith L10 clip **20**. [Capture and animation receipts](evidence/visual-rebirth/phase14e/hunters/)
- Core gameplay, scene startup, graphics preferences, spatial save/effects and
  Nightmare Hunt passed **403** checks. All **16** real building selections
  opened their inspector under Low and Reduced settings with the fixture
  state unchanged. Each matched benchmark passed **174** checks. [Dense room evidence and logs](evidence/visual-rebirth/phase14e/dense/)

This pass verifies visual integration and sampled gameplay compatibility.
Artistic approval remains open. Fine details can still disappear when machines
are packed close together, and the Storm mantle can approach the door HP
plate. The independent angles are 2D interpretations, with small differences in
hair and cloth between angles. The other 55 ordinary states still use a single
projection. Performance measurements cover a short staged scene with a
closed inspector. Extended sessions and turning spikes remain unmeasured.
