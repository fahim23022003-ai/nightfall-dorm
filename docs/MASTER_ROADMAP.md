# Nightfall Dorm master roadmap

## Owner-approved project — Living Nightmare

The opt-in preview combines articulated Hunter pilots, event-driven combat
feedback, adaptive horror audio, and a linear 50-level Story campaign.
Each verified pilot gates further character coverage. Preserve the V2.3,
V1 and fixed launch modes and the original profile backup.
[Implementation and QA](LIVING_NIGHTMARE.md)

## Mandatory remaining milestone — Hunter articulation and performance

The verified Living Nightmare baseline is `62ecf7a` on `work`. The new
articulated renderer covers Stalker L1, Ravager L1 and both Grim Reaper
forms. The Reaper's rear scythe motion and other movement coverage still
need work. Keep the established art and renderer available for the other
58 ordinary Hunter evolution states until their articulated replacements
have been verified in gameplay.

Use the pilots as the starting point. Verify the L4, L7 and L10 Stalker
and Ravager anchors, then author Crusher, Witch, Electric Ghost and Storm
Wraith anchors before filling the intervening levels. Check locomotion,
turning, attack contact at the actual damage frame, reactions and special
motions at gameplay zoom. Benchmark dense combat at 1280×720 on Standard
and Low, with native Windows and Intel UHD results recorded when available.
[Pilot evidence and remaining acceptance checks](LIVING_NIGHTMARE.md#performance-and-remaining-delivery)

## Upcoming survivor and UI work

The next directive covers shared survivor spawning, first-arrival room
claiming, half-speed NPC movement, fair defeat rewards, interactive
tutorials and a premium UI redesign. Develop and verify those changes in
separate checkpoints from the animation work so changes to room starts or
rendering costs can be traced. Retain the 50-level Story, adaptive score,
heartbeat, combat VFX and verified rigs. Preserve maps, saved progress,
fallback modes and unrelated gameplay.

## Phase 14F — Hunter animation and directional art

Continue the opt-in visual preview. Verify character motion and direction,
building function cues, and render performance against the Phase 14E
checkpoint. Owner review gates the visual preview rollout.

## Owner-approved project — Full room grid building

The owner authorized the grid preview while artistic review and native
Windows testing of Phase 14F are pending. Review the combined build through
the [Full Room Grid preview](FULL_ROOM_GRID_PREVIEW.md).

- Divide the entire usable room floor into buildable grid cells. Allow
  placement anywhere a building footprint fits on valid tiles.
- Replace progressive 3/6/8/10/16 slot unlocking and arbitrary slot-cap
  progression with physical floor constraints.
- Give different building types appropriate physical footprints. Validate
  placement, movement and rotation against walls, doors, room fixtures,
  actors and neighboring buildings.
- Preserve safe access and pathfinding through rooms. Measure navigation,
  rendering and input under dense valid layouts.
- Design and verify save migration for existing buildings, ownership and
  progression. Handle layouts that do not fit the grid without deleting
  saved investments.


## Owner-approved project — Procedural Nightmare Maps

The opt-in preview adds seeded irregular rooms across the five themes,
alternative exterior Hunter routes, four Haunted Halls and optional
recovery spectating. Keep fixed maps and both checkpoint formats
available while the preview is reviewed. [Project and evidence](PROCEDURAL_NIGHTMARE_MAPS.md)


## Owner-approved project — Macro-layout diversity

The V2 preview generates different exterior graphs and room silhouettes
within and across ten map families. Fixed and first-generation maps remain
available during owner review. [V2 preview and evidence](PROCEDURAL_NIGHTMARE_MAPS_V2.md)
