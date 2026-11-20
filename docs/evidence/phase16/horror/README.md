# Door pressure and horror feedback

A live hit marks the two jambs and throws a brief outward spark at the actual doorway orientation. Breaking a door sends a short draft out of the threshold. The strategic map uses compact markers at the real entrances. The two-hit types retain their own damage labels and the exact HP lost.

An ally alert chooses a free lane around the machine list, inspector and other visible controls. The existing top warning handles repeated notices for the same personal siege. Ally damage, destruction and elimination still use the actual model events. Reduced Motion and Low keep the threshold readable with fewer moving details. Reduced Flash removes the transient impact spark.

[Watch the native Godot capture with engine audio](door-pressure.mp4)

| Scene | Previous preview `07b459b` | Phase 16 |
| --- | --- | --- |
| Ally warning with inspector and machine list open | [Baseline](checkpoint/ally-warning-720.png) | [Unobstructed ally warning](ally-warning-720.png) |
| First direct siege | [Baseline](checkpoint/first-heartbeat-720.png) | [First heartbeat](first-heartbeat-720.png) |
| Actual door hit | [Baseline](checkpoint/door-contact-720.png) | [Door contact](door-contact-720.png) |
| Door breaks | [Baseline](checkpoint/door-breach-720.png) | [Breach draft](door-breach-720.png) |

The clip uses an isolated seeded Hell Endless fixture. It stages the wallets, doors and initial Hunter approach positions. The attack state, damage, heartbeat, break and draft use normal game systems. Godot records sound from the Master bus. The video retains that mix and pads any short end with silence. This was captured on Linux Mesa llvmpipe at 1280×720 with the Dummy audio output. The engine's audio clock can lag wall time during software rendering.

The direct siege emitted one opening heartbeat. It ended under sustained pressure. The remote siege did not start it. Existing Hall, Reaper, attack, victory, defeat and mix behavior remain in use. Calm Story preparation selects chapter music from the existing original score library. Manual and Off retain their existing behavior. [Capture receipt](capture.json) · [Regression checks](regressions/)

## Reproduce

```sh
NIGHTFALL_PHASE16=1 NIGHTFALL_LIVING_NIGHTMARE=1 NIGHTFALL_VISUAL_REBIRTH=1 \
NIGHTFALL_FULL_ROOM_GRID=1 NIGHTFALL_PROCEDURAL_MAPS=1 \
  godot --path . --display-driver x11 --audio-driver Dummy --resolution 1280x720 \
  -s tools/phase16/capture_pressure.gd -- /tmp/nightfall-pressure
```

Use the same capture script against `07b459b` with `NIGHTFALL_PHASE16=0` and `--stills` for the checkpoint comparison. The script saves frame images and direct Master PCM for the video.
