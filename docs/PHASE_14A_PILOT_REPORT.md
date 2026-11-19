# Phase 14A gameplay visual pilot

The Godot game has an opt-in presentation prototype for the Stalker and Needle Turret. Launch from the repository root with `NIGHTFALL_VISUAL_REBIRTH=1 godot --path .`. A normal launch uses the existing visuals and sound.

## Stalker

The Level 1 sprite preserves the supplied face, hair, shoulder, arms, fingers and torn dress. A continuous textured mesh deforms weighted regions of the original art so the hair and hem lag behind the body and the hands reach during a strike. The existing model drives approach, warning, release, hit and vanish. Concealment can add faint drifting strands, with reduced effects and motion respected. An original synthesized sob-breath plays on the Effects bus during qualifying approaches, with positional attenuation, volume settings and a 12-second cooldown.

The pose weights provide local movement within one composite. Independent head, hair, torso, arm, hand and garment textures and a skeletal rig are still open. The preview uses one oblique view for supported headings without mirroring it. Other headings and evolution levels draw the existing sprite, so a turn outside the supported range can change art style abruptly. No hidden anatomy or unseen directions were fabricated. The paired 720p viewport shows the pale face and ragged silhouette and readable door HP and warning text. At door contact the sprite covers some of the door face, and the realistic style differs from the existing residents.

[Isolated Godot Master audio](evidence/visual-rebirth/stalker-actual-master.wav) captures a single staged cue at a 200-pixel offset, with the other buses quiet. It has a -36.6 dBFS peak. In-combat perceptual mixing remains unverified.

## Needle Turret

Editable Blender generation code produces the base and separate launcher. The baked atlases cover ten unbranched levels, plus Precision and Suppression at levels 5–10, with 12 launcher bearings per state. The crescent, iron stand and dart cluster draw from the canonical reference. The sprite selects a bearing for the live target and follows the actual shot during the firing flash. Recoil and muzzle effects are presentation only. The new silver dart and small ring-and-spark impact follow the existing projectile and impact event. At close view the sampled bearing steps are visible. The shaft follows the model trajectory from its existing origin, so the decorative muzzle and the first dart position can differ momentarily.

The final bake has no empty or clipped cells in 264 assembled poses. Mean silhouette change across the 12 bearings was **23.5% from Level 1 to 4**, **22.3% from 4 to 7**, and **15.7% from 7 to 10** by symmetric difference over union. The tier changes remain below the Art Bible's approximate 25–35% target. Some branch changes read only at enlarged scale. The preview is ready to inspect in play, with art acceptance and the full batch still open. See the [L1–L10 progression and review criteria](PHASE_14A_ART_PROGRESSION.md) and [asset manifest](evidence/visual-rebirth/ASSET_MANIFEST.json).

## Verification

The opt-in core, Nightmare Hunt, scene, spatial-save and cinematic suites passed **403 assertions**. Stalker pose QA checked **53,856 sampled triangles**, with minimum signed area +1.860 px² after fixing a fold. Audio routing passed ten focused checks and three legacy audio suites passed 705 assertions. The engine imported the assets without script errors. All gameplay and save code stayed at the Phase 13 baseline.

The paired Godot capture passed **185 checks per mode**. Its six-second fixed-step clip recorded seven Needle launches and hits, one Stalker warning and five real door strikes in each run. Sampled model state had the same SHA-256, including matching HP and wallets. The fixture staged the room, purchases and the start of the Stalker approach. The clip then advanced the actual game and renderer.

| 1280×720 dense scene | Phase 13 visuals | Phase 14A pilot |
| --- | ---: | ---: |
| Median viewport frame | 34.24 ms | 31.49 ms |
| 95th percentile | 49.79 ms | 36.97 ms |
| Godot reported render video memory | 105.7 MiB | 125.1 MiB |

Each run captured 240 samples after 30 warmup frames on Linux Mesa llvmpipe with medium graphics. These single serial samples measure presentation and viewport frame pacing with the model frozen. They include run-to-run noise and do not establish a speedup. Neither sample meets the 16.7 ms target on this software renderer. Native Windows and Intel UHD performance remain unmeasured.

- [Before/after combat close-up](evidence/visual-rebirth/pilot/combat-closeup-comparison.png)
- [Six-second Godot animation comparison](evidence/visual-rebirth/pilot/combat-comparison.mp4)
- [Paired event and performance measurements](evidence/visual-rebirth/pilot/comparison.json)

To reproduce the comparison on a Linux X11 display, run `LIBGL_ALWAYS_SOFTWARE=1 python tools/record_visual_rebirth.py /absolute/output/path`. The MP4 uses the actual Godot viewport at a fixed simulation step and is silent. The separate Master FLAC follows wall time.

## Pilot refinement

The Stalker keeps the approved 104-pixel draw height and foot pivot. The current
renderer blends between eight poses from the same reference view, with separate
turn and recovery motions and a charged tell anchored to the deformed hand.
Attack warnings and strikes retain priority over incidental hit flashes.
The topology check covers every sampled pose and pairwise transition.
Independent Stalker views, body-part textures and the L2–L10 art remain open.
A heavy-damage popup briefly obscures the face in one recovery capture. The
door HP and urgent warning stay readable. The mesh check passed 71,808 sampled
pose triangles and 4,847,040 blend intervals with a minimum signed area of
1.860 px² before display scaling.

Needle darts now visually depart the projected muzzle and join the existing
projectile path over the first 100 ms. The muzzle, recoil and dart offset share
the same projection. Existing projectile state supplies the impact location and
combat timing.

The refined 22-state Needle bake has 264 checked, unclipped poses. Mean
silhouette differences across 12 bearings are 26.0% from L1 to L4, 28.1% from
L4 to L7 and 35.4% from L7 to L10. L1 to L2 and L8 to L9 average 0.9% and
3.2%. The L5 Precision and Suppression branches differ by 8.6% on average.
The minor changes still require scrutiny at normal game zoom. [Needle atlas gallery](evidence/visual-rebirth/pilot-refinement/needle-level-gallery.png)

Scene, spatial-save, cinematic and Nightmare Hunt checks passed all 267
assertions. No gameplay model, difficulty, economy or save files changed.

The refreshed six-second Godot pair passed 185 checks per mode. Both runs
produced seven Needle launches and impacts, five Stalker door strikes and the
same sampled model-state checksum. In a separate staged Hard encounter, the
model emitted a charged tell and a recovery event following the actual attack.
At 720p, the single llvmpipe comparison measured median frame times of 33.82 ms
with legacy visuals and 32.32 ms with the pilot. The 95th percentiles were
45.03 ms and 39.85 ms. Render memory increased from 105.7 MiB to 125.1 MiB.
These measurements cover software rendering. Native Windows and Intel UHD
performance remain open. [Refined capture data](evidence/visual-rebirth/pilot-refinement/comparison.json)
