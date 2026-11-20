# Offline Story lobby

The genuine Story **Start Mission** control opens a rendered roster with
one player and five local AI survivors. The briefing uses the selected
mission's Hunter illustration. The countdown arms after the first
render. Early **Ready** marks the human card while the AI continue
joining. The last ready slot queues a short loading view with Back
available. Leaving the window freezes both clocks.

| Verification | Gameplay evidence | Receipt |
| --- | --- | --- |
| Early Ready | [Real input and Master audio](early-ready-with-audio.mp4) | [Native trace](early-receipt.json) |
| Automatic Ready at 15 seconds | [Full countdown and Master audio](auto-ready-with-audio.mp4) | [Native trace](auto-receipt.json) |
| Clock, focus, loading cancellation and audio preferences | [29 headless checks](controller-audio-tests.log) | [Reproducible fixture](../../../../tests/nightmare_lobby.gd) |

The early run marks human readiness at 1.875 seconds and enters loading
at 6.292, when the fifth AI independently joins. The untouched player
readies at exactly 15.000 seconds in the second run. Each creates one
Campaign match. The existing model time, Story record, inventory and
active-match entry stay intact throughout the wait. Both recordings
use live X11 window focus, the normal Godot UI and Master audio.
[Initial roster](lobby-waiting.png) · [Waiting for the remaining AI](lobby-human-ready.png)

The audio director routes Story preparation to the existing calm
composition, the lobby to a quieter opening composition and the new
match to its gameplay score. Both traces record five accepted join
sounds, one opening sound and one Ready sound. The focused fixture
also checks mute, music off and menu fade routing. The 67 living audio
checks and 617 legacy audio assertions passed, including the established
five-second siege warning.
[Living audio regressions](living_nightmare_audio.log) ·
[Audio system regressions](audio_system.log)

## Reproduce

Run Godot 4.6.3 in a graphical session. The evidence renderer uses
Linux Mesa llvmpipe. Use a distinct test profile folder for each run.

```sh
NIGHTFALL_SURVIVOR_REBIRTH=1 NIGHTFALL_LIVING_NIGHTMARE=1 \
NIGHTFALL_VISUAL_REBIRTH=1 NIGHTFALL_PROCEDURAL_MAPS_V2=1 NIGHTFALL_FULL_ROOM_GRID=1 \
XDG_DATA_HOME=/tmp/nightfall-lobby-qa godot --path . --resolution 1280x720 \
  --audio-driver Dummy --write-movie /tmp/nightfall-lobby.avi --fixed-fps 24 \
  --script tools/visual_rebirth/record_nightmare_lobby.gd -- /tmp/nightfall-lobby auto
```
