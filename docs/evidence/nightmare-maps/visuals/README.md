# Procedural Nightmare Maps in Godot

[Watch the gameplay capture](procedural-nightmare-gameplay.mp4). The first two chapters follow the same Hunter from the same junction to the same door using two genuinely different approaches to Room 01. Gold and teal trails mark the sampled positions in the capture. The comparison advances four model steps per recorded frame. The last chapter returns to one step per frame inside the hall so the recovery plays at its real pace. Travel before and after the channel uses the same accelerated sampling as the route comparison.

## Seeded map gallery

| Theme | Seed | Real viewport capture |
| --- | ---: | --- |
| Abandoned Dorm | 41 | [Overview](map-abandoned_dorm.png) |
| Haunted Hospital | 73 | [Overview](map-haunted_hospital.png) |
| Forgotten Hotel | 105 | [Overview](map-forgotten_hotel.png) |
| Underground Lab | 137 | [Overview](map-underground_lab.png) |
| Cursed Mansion | 169 | [Overview](map-cursed_mansion.png) |

- The U-shaped room has 11 machines purchased through the game. The floor plan leaves the exterior recess without build cells. [Irregular grid](irregular-u-floor-grid.png)
- Each alternate approach reaches the same door without crossing its walls. [North-side route](hunter-route-0.png) · [West and south route](hunter-route-1.png)
- The Hunter retreats after combat damage. The notification leaves the room camera and active placement alone until the player clicks Watch Hunter. [Retreat notification](hunter-retreat-notification.png)
- At the West Haunted Hall, the scene shows the Hunter's actual HP and adds recovery effects while the model heals 828 HP over eight seconds. [Hall entry](west-hall-entry.png) · [Mid-channel](west-hall-recovery-2.png) · [Late channel](west-hall-recovery-3.png)
- The Hunter travels back to the room and strikes the door. Clicking Return restores the player's untouched placement preview. [Back at the door](hunter-back-at-door.png) · [Return to room](hunter-return-to-room.png)

These 1280×720 Godot captures use a prepared test wallet for the grid gallery. The other fixtures seed the match and stage the Hunter's starting position and damage. Subsequent movement, channeling, attacks and pointer actions use the production code. The recording uses Linux Mesa llvmpipe and a dummy audio driver. The engine receipt shows the retreat, West Hall and release samples played. The MP4 has no audio track. [Engine log](engine.log) · [Capture receipt and route samples](capture.json)

## Reproduce

Run Godot 4.6.3 in a graphical session with the two previews enabled.

```sh
NIGHTFALL_PROCEDURAL_MAPS=1 NIGHTFALL_VISUAL_REBIRTH=1 NIGHTFALL_FULL_ROOM_GRID=1 \
  godot --path . --audio-driver Dummy --resolution 1280x720 \
  -s tools/capture_nightmare_maps.gd -- /tmp/nightfall-maps
```

Pass `--stills` after the output path to skip the alternate-route sequences and video frames.
