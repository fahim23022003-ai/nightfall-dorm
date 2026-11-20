# Phase 16 Story encounters

The 50 Story missions retain their level IDs, maps, route families, Hunter archetypes, seeds, difficulty tracks, checkpoints and rewards. Phase 16 adds chapter-specific preparation windows, first special attack grace periods and the earliest eligible recovery through a Haunted Hall. Form schedules use the existing Reaper transformation. Six missions emphasize ordinary Hunters, while The Funeral Bell and Dawn or Oblivion explicitly enable the Reaper encounter. Existing warning durations, transformation HP thresholds and base Hunter stats are retained.

The mission briefing lists the selected map and route family, preparation time, Hall recovery eligibility and whether the Reaper can awaken. A successful mission reveals one discovery in the result and archives it against the earned level. The result displays the cleared mission, next level, checkpoint, received XP and RM Cash. Archive entries use the existing highest clear across the three difficulty tracks.

## Evidence

| Evidence | Coverage |
| --- | --- |
| [Model receipt](encounters.log) | 221 checks with 0 failures. All 50 mission seeds and the map, Hunter and base stats of 27 paired configurations were compared across preview off and on. |
| [Blackout Protocol, Level 4](story-level-04-briefing.png) | Prepares a first-form encounter in Twin Wings. A production interference warning and door impact fired after the opening grace. |
| [Echoes of the Lost, Level 29](story-level-29-briefing.png) | Sets the Haunted Hall recovery eligibility to 30 seconds after arrival. A wounded Hunter found a legal route, channeled and recovered 941.76 HP. |
| [The Funeral Bell, Level 36](story-level-36-briefing.png) | Shows the Chapter 8 opening and a Reaper-enabled Hospital encounter. On Standard the existing transformation and awakening fired after the 210-second combat deadline. |
| [Level 29 result](story-level-29-result.png), [Chapter 6 archive](story-chapter-06-archive.png) | A real damage and progression settlement on a prepared profile awards first-clear XP and RM Cash, advances to Level 30 and reveals the earned discovery. |
| [Native render log](capture.log) | Godot 4.6.3 under Linux at 1280×720. |
| [Prior launcher progression](fallback-progress.log), [prior launcher integration](fallback-integration.log), [Phase 16 Story integration](current-integration.log) | 620 baseline progression checks and 65 integration checks per launcher configuration, all with 0 check failures. |

The encounter fixtures stage Hunter position and time to exercise specific production branches. The result fixture stages low Hunter HP before settling through production damage and payout. The receipts establish live rule differences and state compatibility for the sampled situations.

The three desktop gameplay clips use the production Story match and game
render loop. The staged setups start just before each event. Playback
advances at normal gameplay speed at 1280×720 and 24 fps with the Godot
Master audio mix. All event assertions passed.

| Encounter | Actual combat capture | Engine receipt |
| --- | --- | --- |
| Level 4, Blackout Protocol | [Static Cage warning and impact](story-level-04-encounter.mp4) · [still](story-level-04-encounter.png) | [Log](story-level-04-encounter.log) |
| Level 29, Echoes of the Lost | [Retreat, Watch Hunter and completed Hall recovery](story-level-29-encounter.mp4) · [still](story-level-29-encounter.png) | [Log](story-level-29-encounter.log) |
| Level 36, The Funeral Bell | [Reaper transformation and awakening](story-level-36-encounter.mp4) · [still](story-level-36-encounter.png) | [Log](story-level-36-encounter.log) |

Reproduction from the project directory

```sh
godot --headless --path . --script res://tests/phase16_story_encounters.gd

# Run with a graphics display available.
godot --path . --resolution 1280x720 --audio-driver Dummy \
  --script res://tools/capture_phase16_story.gd -- /tmp/nightfall-phase16-story

# Use 4, 29 or 36 in the final argument.
NIGHTFALL_PHASE16=1 NIGHTFALL_LIVING_NIGHTMARE=1 NIGHTFALL_SURVIVOR_REBIRTH=1 \
  NIGHTFALL_VISUAL_REBIRTH=1 NIGHTFALL_FULL_ROOM_GRID=1 NIGHTFALL_PROCEDURAL_MAPS_V2=1 \
  godot --path . --resolution 1280x720 --audio-driver Dummy --fixed-fps 24 \
  --write-movie /tmp/nightfall-encounter.avi \
  --script res://tools/phase16/capture_story_encounter.gd -- /tmp/nightfall-phase16-film 29
```
