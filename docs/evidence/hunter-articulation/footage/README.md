# Godot footage at normal gameplay speed

The films use the native 1280×720 viewport at 24 frames per second.
Each Hunter film includes a prepared walk through four directions,
a live Needle impact and the damage-event contact and follow-through.

| Hunter | Gameplay film | Recorded levels |
| --- | --- | --- |
| Stalker | [Watch](stalker-anchors.mp4) | L1, L4, L7, L10 |
| Ravager | [Watch](ravager-anchors.mp4) | L1, L4, L7, L10 |
| Crusher | [Watch](crusher-anchors.mp4) | L1, L4 |
| Phantom Witch | [Watch](witch-anchors.mp4) | L1, L4 |
| Electric Ghost | [Watch](electric-anchors.mp4) | L1, L4 |
| Storm Wraith | [Watch](storm-anchors.mp4) | L1, L4 |
| Grim Reaper | [Front scythe](reaper-front.mp4) · [Rear scythe](reaper-rear.mp4) | Existing transformation and actual damage |

- [Stalker L4 before and after](stalker-l4-before-after.mp4) shows the old
  fallback at `a71f3e3` and the articulated layer pose on the matched route.
- [Specials and synchronized gameplay audio](specials-with-game-audio.mp4)
  is a separate 39.4-second Movie Maker recording with a 48 kHz stereo
  Master capture. The other clips are silent.
- [Ordinary state verification](ordinary-verification.json) records all
  16 levels, four views per level and errors below 0.06 world units on
  the tested damage frames. The [rear](reaper-rear.json) and
  [front](reaper-front.json) Reaper clips have separate receipts.

The ordinary capture stages a room, Hunter level and initial route.
The Reaper capture starts just before the transform threshold and
isolates an ordinary scythe strike. The movement, damage, effects and
rendered action use the game's existing systems.
[Articulation report](../../../HUNTER_ARTICULATION.md)

## Reproduce

Use Godot 4.6.3 from a graphical session with a private test profile.
The capture harnesses use actual game rendering.

```sh
export NIGHTFALL_LIVING_NIGHTMARE=1 NIGHTFALL_VISUAL_REBIRTH=1 NIGHTFALL_FULL_ROOM_GRID=1
XDG_DATA_HOME=/tmp/nightfall-anchor godot --path . --resolution 1280x720 --audio-driver Dummy --script tools/visual_rebirth/capture_hunter_anchor_combat.gd -- /tmp/anchor stalker 4
XDG_DATA_HOME=/tmp/nightfall-rear godot --path . --resolution 1280x720 --audio-driver Dummy --script tools/visual_rebirth/capture_reaper_form_motion.gd -- /tmp/rear --scythe-rear
XDG_DATA_HOME=/tmp/nightfall-special godot --path . --resolution 1280x720 --audio-driver Dummy --write-movie /tmp/specials.avi --fixed-fps 24 --script tools/visual_rebirth/record_articulated_specials.gd -- /tmp/specials.json
```
