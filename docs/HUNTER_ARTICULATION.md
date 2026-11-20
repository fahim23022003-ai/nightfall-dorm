# Hunter articulation and performance checkpoint

This pass starts from the verified `a71f3e3` Living Nightmare release.
Fourteen more ordinary evolution states have authored anatomical cutouts
and have been verified in game. Each uses the approved direction painting
with its own limb outline and joint anchors. The layered renderer solves
the shoulder, elbow and wrist or the hip, knee and ankle. The belly,
coat or dress follows the pose separately. The original artwork remains
the fallback when a corresponding rig is absent.

| Hunter | Verified articulated evolution levels | Pending levels |
| --- | --- | --- |
| Stalker | 1, 4, 7, 10 | 2, 3, 5, 6, 8, 9 |
| Ravager | 1, 4, 7, 10 | 2, 3, 5, 6, 8, 9 |
| Crusher | 1, 4 | 2, 3, 5, 6, 7, 8, 9, 10 |
| Phantom Witch | 1, 4 | 2, 3, 5, 6, 7, 8, 9, 10 |
| Electric Ghost | 1, 4 | 2, 3, 5, 6, 7, 8, 9, 10 |
| Storm Wraith | 1, 4 | 2, 3, 5, 6, 7, 8, 9, 10 |

Six native 720p films cover all **16 ordinary verified states**.
Each includes four cardinal directions, limb-driven locomotion, a Needle
hit reaction, an ordinary windup, the damage frame, and follow-through.
The level, route and starting room were prepared. Production movement,
weapons, hits and combat timing drive the rendered action. The contact
check measures the pose at one live door orientation per ordinary state.
The level-specific cutouts retain the discrete views of the original
illustrations. [Films and source events](evidence/hunter-articulation/footage/)

The transformed Reaper now swings its scythe from the rear as well.
The rear painting conceals the weapon arm. The swing uses the same
character's sleeve and gauntlet art emerging beside the mantle, then
returns to the original rear silhouette. The front and rear fixtures
show the existing transformation and real Scythe Strike. The blade
reaches the door during the authoritative damage frame in both views.
Other boss skills and all combinations of direction and movement still
require acceptance footage.

An additional 39-second Godot Movie Maker capture records live Master
audio and gameplay. It shows Stalker L10's rebirth and Hollow Oath,
Ravager's quills, Crusher's pressure, Witch's cursed projectile,
Electric Ghost's interference and Storm Wraith's chain lightning.
Verified gameplay events drive the casting poses, impact VFX and door
audio. The fixture prepares the current level and ability cooldowns.
[Live audio and ability evidence](evidence/hunter-articulation/footage/specials-with-game-audio.mp4)

## Rendering improvement

The previous dense Stalker benchmark advanced to L6, which uses a
fallback. The corrected fixture requires the L1 atlas to appear in the
same rendered 24-building room on both arms. It uses the identical
seed, camera, settings, starting state and active strikes. Both arms
retained matching final gameplay digests.

The cutout renderer now submits its atlas quads as an ordered indexed
batch, with a separate submission where weapon layering requires it.
Atlas regions are cached on first use, and the ordinary renderer retains
a bounded atlas cache. The room renderer caches packed static wall
geometry, submits strokes in batches, and skips offscreen corridor
details. Hunter drawing uses a tighter camera margin on the preview.
All of these changes are on the presentation side.

| 720p fixture | Before median / p95 ms | After median / p95 ms | Median draw calls |
| --- | ---: | ---: | ---: |
| Stalker Standard | 39.02 / 46.39 | 36.52 / 45.02 | 404 → 384 |
| Stalker Low | 34.10 / 41.98 | 32.63 / 39.32 | 399 → 379 |
| Reaper Standard | 38.39 / 48.52 | 39.27 / 49.31 | 638.5 → 584.5 |
| Reaper Low | 37.36 / 50.77 | 37.09 / 57.46 | 609.5 → 555.5 |

Stalker improved on both tested presets. Reaper draw calls dropped. Its p95 frame time increased,
particularly on Low.
The sampling platform is Linux Mesa llvmpipe GL Compatibility. Native
Windows and Intel UHD performance remain unmeasured. [Raw timings and frames](evidence/hunter-articulation/performance/)

## Preservation and remaining work

Core combat, Story, audio, contact attribution, boss rules, Full Room
Grid and V2 persistence passed headless regression tests. The update
uses the existing preview switch and a separate preview profile. No
model, combat value, AI, map generation or save schema changes are in
this checkpoint. [Regressions](evidence/hunter-articulation/regressions/)

The remaining milestone is **44 ordinary evolution state rigs**, continued
Reaper motion verification, more door-facing contact checks, and native
performance tuning and owner review. The survivor, defeat, tutorial and
UI workstreams remain separate. [Windows export verification](evidence/hunter-articulation/windows/)
