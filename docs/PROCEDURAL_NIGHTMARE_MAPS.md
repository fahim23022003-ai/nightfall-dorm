# Procedural Nightmare Maps preview

Set `NIGHTFALL_PROCEDURAL_MAPS=1` before launching Godot to generate layouts
for new Campaign and Endless matches. A Campaign stage keeps its theme.
Endless uses the theme and seed entered at setup. The map overview shows
the seed. Phase 14F art remains available through its existing
`NIGHTFALL_VISUAL_REBIRTH=1` flag. Regular launches, the tutorial, Practice
and fixed Challenge codes retain their existing maps and rules.

The generator shuffles six rooms across the map and varies their sizes,
shapes, door orientations and approach lengths. Every seed includes a
rectangle, a long room, an L, a U and a zigzag. Exterior lanes connect the
rooms and four cardinal Haunted Halls. The same theme and seed produce
the same layout. Some rooms favor concentrated fire at a short approach.
Others offer more construction space, longer attack lines or a better
angle against a Hunter moving between rooms.

The entire usable player floor is available from the first purchase.
Footprints can cross an internal seam between occupied floor strips.
Walls, cutouts, furniture, other machines, active characters and the
door-to-bed route still block construction. Existing move, turn and undo
rules apply. NPCs keep their regular fixed-pad purchase and expansion
rules within the generated floor.

## Hunter and Haunted Halls

The Hunter follows the exterior AStar2D graph, can take an alternative
lane around a room, and enters rooms through their door. An intact closed
door blocks entry. A broken door still uses the normal breach mechanics.
Exterior paths and room interiors check whole movement segments against
walls and corridors.

A wounded Hunter can retreat to a reachable Hall. A successful eight-second
channel restores up to 18% of maximum HP. Normal damage still applies.
Damage totaling 8% of maximum HP during the channel interrupts it. The
Hunter must wait 75 seconds after an attempt and gets two attempts per
Campaign match or Endless run. A failed attempt uses one slot. Recovery
time does not advance ordinary combat growth. The transformed Reaper
keeps its existing combat phases and Crimson Execution.

The retreat banner identifies the Hall. **Watch Hunter** follows the
actor as it travels, recovers and returns to combat. **Return**, **Home**
or **Esc** returns to your room and restores any pending construction.

## Checkpoints

Endless saves continue to occur at sealed intermissions. A procedural
checkpoint stores the seed, generated geometry, Hall placements, recovery
attempts and cooldown. Resuming a procedural checkpoint uses the saved
geometry even with the flag off. Opening an older checkpoint with the
flag on keeps its existing map. Wave continuation does not reroll either
format. Campaign keeps its existing stage progression and save behavior.

## Evidence

[Godot screenshots and gameplay video](evidence/nightmare-maps/visuals/) ·
[Seeded navigation, save, balance and rendering QA](evidence/nightmare-maps/qa/)
