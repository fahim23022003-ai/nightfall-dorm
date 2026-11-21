# Phase 22.1 · Targeted UI polish

[Download the Windows x64 preview](https://github.com/fahim23022003-ai/nightfall-dorm/releases/download/phase22.1-targeted-ui-preview/NightfallDorm-Phase22.1-Windows-x64.zip) · [Install and playtest](../../PHASE221_PLAYTEST.md)

## Changes verified in Godot

- The catalogue is 394 design pixels wide, down from 830. It chooses the side with less overlap with the room and nearby siege, then keeps that side until dismissal. All four categories and 15 machines remain accessible. The browse view leaves floor clear. **Plan [P]** and placement still show the full grid. Opening and closing Build preserve camera position and zoom in the tested scene. The drawer covered 0% of the projected room bounds in that siege, and the opposite anchor left Plan clear with the camera panned. [Before and after](build-comparison.jpg) · [Build during a live siege](build-siege.png)
- Catalogue costs, placement feedback, inspector values, upgrade requirements and important Shop and Story labels are at least 18 design pixels in the tested layouts, equivalent to 13.5 physical pixels at 960×540. Tutorial instructions are 15 physical pixels. Secondary card subtitles retain a smaller font. [Inspector before and after](inspector-comparison.jpg) · [Blocked placement](placement-blocked.png) · [Dynamo lesson](tutorial-dynamo.png) · [Needle lesson](tutorial-needle.png)
- Normal Story Level 1 used the same `crusher` archetype and seed from preparation to gameplay. The older objective used the archetype label “The Crusher,” while the lobby and HUD used the character name “The Bonebreaker.” Preparation now displays The Bonebreaker too. The Hell Level 50 objective names the opening Hunter and separately shows The Final Reaper where the existing policy allows it. The identity fixture passed 92 checks per resolution across Normal Level 1 and Hell Levels 2 and 50. [Preparation, lobby and HUD comparison](story-identity.png)
- The same construction, repair, refund, progression and save systems power the preview. The localized map drawing change applies to tactical practice on the fixed Abandoned Dorm map. [Real-input walkthrough](walkthrough.mp4)

## Performance

All results are from Godot 4.6.3 Compatibility on Linux X11 using Mesa llvmpipe, two software raster threads and isolated profiles. The Build comparison reuses Phase 22 evidence from the same Story seed, Room 3 and fixed model tick. Each surface discarded five warm-up frames and kept 45 samples. The ranges show separate runs. The game continued drawing the live world while the catalogue was open.

| Build workload | Phase 22 median / p95 / p99 | Phase 22.1 median / p95 / p99 |
| --- | ---: | ---: |
| Low · 960×540 | 23.71–27.13 / 30.97–36.30 / 34.46–48.59 ms | 20.87–21.88 / 26.55–27.42 / 27.04–28.45 ms |
| Standard · 1280×720 | 42.65–48.19 / 55.73–89.71 / 58.50–111.69 ms | 38.78–39.68 / 43.57–48.22 / 55.25–56.29 ms |

The initial regression tracked retained rendering more closely than game-process time. The smaller drawer avoids redrawing the room grid during browsing. The catalogue writes prices and states when the displayed quote or readiness changes, and refreshes the selected live stats at a bounded rate. Hover and focus still update immediately when selection changes. Median draw calls dropped from 196 to 177 on Low and from 249 to 225 on Standard. Low Build p95 remains above Phase 21's published 24.38 ms. The median category click-to-present intervals measured 40–44 ms on Low and 75–80 ms on Standard.

The same complete tutorial input route ran twice per arm with screenshot writes and framebuffer readbacks disabled. The map renderer batches fixed corridor seams and culls architecture outside the visible area with a margin for protruding art. The single-machine lesson renders a one-row atlas. The actual simulation, graphics preset and camera behavior were preserved.

| Tutorial workload | Phase 22 median / p95 / p99 | Phase 22.1 median / p95 / p99 |
| --- | ---: | ---: |
| Low · 960×540 | 22.49–25.85 / 34.59–36.20 / 67.75–76.36 ms | 21.90–23.93 / 32.03–35.02 / 66.75–85.12 ms |
| Standard · 1280×720 | 37.54–37.82 / 49.85–50.08 / 87.15–105.75 ms | 35.50–37.45 / 46.74–55.35 / 85.96–133.67 ms |

Tutorial median draw calls fell by 36 in each preset. Both full screenshot walkthroughs passed 50 checks, including actual purchases and a real Needle hit. The Low median improved in one paired run and rose in the other. Continued p99 variation leaves the worst-frame improvement unverified. The single-core diagnostic traced about 454 ms of one cold entry to fixed-map navigation setup. Regular practice measured 0.60–0.64 ms median for HUD refresh. The cold navigation setup remains a distinct problem from live rendering.

[Frame timings, input samples, Story identity receipts and regression results](metrics.json) · [Package verification and SHA-256](windows-package.json)

## Regression results

The interactive transaction route passed 258 checks on Low, including move and undo, paid upgrade, sale cancellation and verified refund, critical Ward, Help, Settings and keyboard navigation. The timed input route passed 352 checks per resolution. The core suite passed 136 assertions, scene smoke 33, Full Room Grid saves 64, Story progression 620, survivor lobby 89, weapon feedback 148, procedural persistence 62, Player First 27 and Campaign profile 89.

## Source

- Catalogue and construction HUD work lives in [build_catalogue_view.gd](../../../scripts/build_catalogue_view.gd), [bottom_context_panel.gd](../../../scripts/bottom_context_panel.gd), [construction_controls.gd](../../../scripts/construction_controls.gd), [machine_inspector.gd](../../../scripts/machine_inspector.gd) and [tactical_hud.gd](../../../scripts/tactical_hud.gd).
- Story and economy presentation changes live in [story_interface.gd](../../../scripts/story_interface.gd), [cash_shop.gd](../../../scripts/cash_shop.gd) and [item_interface.gd](../../../scripts/item_interface.gd). Practice presentation lives in [quick_tutorial.gd](../../../scripts/quick_tutorial.gd) and [map_presentation.gd](../../../scripts/map_presentation.gd).
- The updated test and export entry points are [capture_ui.gd](../../../tools/phase22/capture_ui.gd), [capture_story_identity.gd](../../../tools/phase221/capture_story_identity.gd) and [export_hell_tactics_playtest.py](../../../tools/windows/export_hell_tactics_playtest.py).

## Verification boundaries

Two specialists independently handled Story identity and practice profiling. The catalogue, HUD, inspector, regression and export were integrated by the lead agent. The video uses real Godot mouse and keyboard input with the dummy audio driver. No native Windows, Intel UHD frame pacing or human comfort test was available.
