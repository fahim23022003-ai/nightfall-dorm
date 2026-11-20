# Procedural Nightmare Maps V2

Set `NIGHTFALL_PROCEDURAL_MAPS_V2=1` before starting Godot to use V2 in
new Campaign and Endless matches. Add `NIGHTFALL_VISUAL_REBIRTH=1` for
the existing Phase 14F visuals. With only `NIGHTFALL_PROCEDURAL_MAPS=1`,
new matches use V1. A regular launch keeps fixed maps. Tutorial, Practice,
and fixed Challenge codes keep their original behavior.

Campaign picks a fresh seed. In Endless, leave the seed field blank for a
fresh layout or enter a seed to reproduce a layout for the selected theme.
Fresh seeds avoid the last three V2 families played in this session where
a different family is available. A seed entered by the player stays exact.

## What changes across matches

V1 shuffled six rooms around a fixed two-row exterior grid. V2 varies the
exterior network and room positions together. The selection includes ring,
branching, scattered, long spine, zigzag, radial, twin wings, labyrinth,
asymmetric courtyards, and mixed hybrid layouts. The same family can have
different distances, widths, branches, room and door orientations, and Hall
connections. Each map still has six survivor rooms and four cardinal Haunted
Halls. A Hall can sit in a clear recess near its cardinal edge. Placement
uses legal travel distance from the doors to keep more recovery approaches
within the existing time limit.

On the desktop map, scroll to zoom around the pointer, middle-drag to pan,
and press **0** to fit again. Click a room to inspect its location. The
overview identifies the family and seed. At room scale, **P** still shows
the buildable floor, including the cutouts in irregular rooms. Hunter
pathing, door breaches, grid transactions, Hall recovery, and Watch Hunter
use the existing game rules.

## Saves and fallback

The saved geometry carries an explicit version. V2 saves store the family,
the lane widths and the exact room and Hall geometry. The current game
reads fixed, V1 and V2 checkpoints with either preview flag enabled or
disabled. Starting another wave uses the stored layout. Existing
intermission save timing and the separate fixed Challenge rules still apply.

## Evidence

[Godot gallery and routing demonstrations](evidence/nightmare-maps-v2/visuals/) ·
[Structural, save and gameplay verification](evidence/nightmare-maps-v2/qa/) ·
[Performance measurements](evidence/nightmare-maps-v2/performance/)
