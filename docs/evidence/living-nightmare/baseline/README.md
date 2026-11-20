# Living Nightmare pre-edit baseline

The tracked project and GitHub `work` were at
`32c205d1bb73aa4eedf84c513433d619886f146a` before production edits.
Both captures used the native Godot 4.6.3 game scene at 1280×720 with
Full Room Grid, procedural V2 and Phase 14F art enabled. Mesa llvmpipe
provided the Linux renderer. These files cover motion and contact.
The audio workstream collects playback separately.

## Crusher from a complete Hell Campaign match

Stage 2, seed 10358, Room 02. The survivor walked from the ordinary
spawn, entered and slept through the production controls, and paid for
normal defenses without items. The excerpt starts around 43.2 seconds
in the match and contains the Hunter's approach, first landed strike
at 48.0 seconds, and early repair. The source simulated 0.15 seconds
per recorded Godot frame. This 12-second export preserves the elapsed
simulation time and repeats frames to fit a standard MP4 cadence.
The source reached victory at 435.60 seconds with zero capture failures.

[Normal-speed contact footage](32c205d-crusher-approach-strike.mp4) ·
[First-strike frame](32c205d-crusher-contact.png) ·
[Model event receipt](32c205d-crusher-events.json) ·
[Renderer log](32c205d-crusher-engine.log)

## Stalker at a committed siege

Stage 1, seed 21, Room 01. A deterministic fixture starts at an
occupied room during a siege. The fixture places the Hunter and
defenses before recording. The normal game process produces the
commit warning, paid repair, incoming fire and four subsequent
Hunter strikes. The 6.6-second clip contains 132 consecutive 0.05-second
game steps with playback at the elapsed simulation speed. The
capture completed with zero failures.

[Normal-speed siege footage](32c205d-stalker-siege.mp4) ·
[Siege warning frame](32c205d-stalker-commit.png) ·
[Model event receipt](32c205d-stalker-events.json) ·
[Renderer log](32c205d-stalker-engine.log)

## What the baseline establishes

Damage feedback, particles, real door-damage events and attack timing
already exist. At normal gameplay scale the whole-body sprite silhouette
stays largely intact during contact. In the controller, a single UV mesh
contains the body and small weighted offsets pull near a few landmarks.
There is no separate rotation chain from shoulder to elbow to hand and
no constraint from a moving hand to the real door socket. The clips are
a comparison for articulated movement and contact, with previous
gameplay balance and pathing as controls.

Reproduce the Stalker fixture in an isolated graphical session:

```sh
XDG_DATA_HOME=/tmp/nightfall-pre-edit NIGHTFALL_PROCEDURAL_MAPS_V2=1 \
  NIGHTFALL_VISUAL_REBIRTH=1 NIGHTFALL_FULL_ROOM_GRID=1 \
  godot --path . --resolution 1280x720 --audio-driver Dummy --disable-vsync \
  --script tools/capture_hell_tactics.gd -- /tmp/nightfall-stalker-frames
```
