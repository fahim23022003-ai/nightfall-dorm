# Hunter decisions in Story

[Watch the Godot recording](walkthrough.mp4). The captions sit below the original 960×540 Low gameplay image. Each combat excerpt plays at 20 frames per simulated second at normal speed. Between excerpts, simulation and presentation keep processing events. The recorder warms the camera and audio for the two seconds leading into each cut. Godot Movie Maker captures the game mix during each excerpt. The audio cuts follow the same edit points as the picture.

The recording follows a single isolated profile from Story Level 1. An automated survivor walks the shortest currently reachable route from the shared spawn, claims the room, then walks into bed range and sleeps. Defending attempts make one construction decision every 1.5 seconds, using the existing paid balanced-defense policy. The repair decision uses visible Door HP and the regular profile item activation. The capture uses the actual Story launcher method and its configured Hunter, match ID, economy and result UI. Camera tracking is scripted for clarity.

| Story match | What happens |
| --- | --- |
| Hell L1, Ring 452733, player Room 04 | The Bonebreaker selects Room 04 at 48.05 s and reaches its door at 52.45 s. The passive player loses at 68.60 s and earns 7 RM. |
| Normal L1, Ring 452733, player Room 04 | The balanced opening invests in defenses. The same Hunter reaches the door at 53.00 s and recommits at 87.55 s. The terminal victory at 280.65 s includes 3,780 player damage. |
| Normal L2, Spine 844960, player Room 06 | The Stalker attacks Room 03 starting at 61.25 s. The Hunter commits to its productive siege at 82.85 s. After Door HP repeatedly recovers, at 104.45 s the Hunter reports a stalled siege, with a cost of 55.00 for the current door and 32.39 for Room 01, and physically leaves for Room 01. Later it reaches the player at 310.10 s. |
| Same Normal L2 match | The previous results fund an 18 RM Repair Kit. At 315.00 s it restores the player's door from 424.24 to 596.74 HP. The team wins at 326.60 s with 3,061.87 damage attributed to the player. The result awards 41 RM. |

The examples demonstrate available responses under these particular match conditions. The cross-difficulty footage changes both player policy and difficulty. The paired cohort measures outcomes across the wider set of strategies and rooms. No human session or native Windows run was recorded.

## Reproduction

Use the Phase 23 preview flags, including `NIGHTFALL_HUNTER_INTELLIGENCE=1`, on Godot 4.6.3. The script uses seed base 91737 for Story and the profile reward generator, with a new scratch profile on every invocation. It records complete result and event traces even in headless mode. In graphical mode, the optional shot list requests only the native frames used in the cut.

```sh
godot --headless --path . --script res://tools/capture_phase23.gd -- /tmp/nightfall-film 91737
godot --path . --windowed --resolution 960x540 --write-movie /tmp/nightfall-session.avi --fixed-fps 20 --script res://tools/capture_phase23.gd -- /tmp/nightfall-film-movie 91737 "$PWD/docs/evidence/phase23/film-shots.json"
```

[Event and render receipts](film-traces.json) · [Excerpt timings](film-shots.json)
