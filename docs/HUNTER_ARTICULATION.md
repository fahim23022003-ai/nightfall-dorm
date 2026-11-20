# Living Nightmare Hunter articulation

All 60 ordinary Hunter evolution states have level-specific articulated
rigs in the opt-in preview. Each of the six Hunters has ten states and
four separately authored direction paintings per state. The two Grim
Reaper forms add eight direction atlases. The verified starting point
`da4ef63` covered 16 ordinary states.

## Coverage and implementation

| Hunter | Articulated levels | Direction atlases |
| --- | --- | ---: |
| Crusher | 1–10 | 40 |
| Stalker | 1–10 | 40 |
| Ravager | 1–10 | 40 |
| Phantom Witch | 1–10 | 40 |
| Electric Ghost | 1–10 | 40 |
| Storm Wraith | 1–10 | 40 |
| Grim Reaper | Approach and transformed | 8 |

The bake starts from the approved paintings. Each new recipe follows
visible anatomy in the corresponding level and direction. It defines
the shoulder, elbow and wrist or the hip, knee and ankle, with
overlapping painted texels at the joints. The runtime solves those
chains separately from the head, torso and garment hem. It uses the
Hunter's gameplay heading, movement and combat events to pose them.
Substantially occluded limbs stay painted into the underlying garment
or body. The Reaper's rear swing uses its own sleeve and gauntlet art
as the weapon arm emerges from behind the mantle.

The ordinary rig blends a body turn into the gait, follows a real
door strike through contact and recovery, and poses when the model
emits an evolution event. The event-driven, L10 rebirth reveal still
controls when the final painting becomes visible. Reaper warning,
release and recovery follow the existing boss
sequencers. Both forms overlap briefly during the transformation.
The held scythe is hidden throughout Crimson Execution flight and
embedding. Damage, the contact effect and impact sound still come from
the gameplay event.

## What Godot verified

Standard and Low each covered 60/60 ordinary states and 240 distinct
direction atlas hashes at 1280×720. Every state rendered articulated
motion in all four cardinal views and landed a real strike against a
door after taking a hit from a purchased Needle. The checks cover
idle, distinct limb motion, windup, contact, follow-through and
recovery. The greatest measured hand-to-socket distance was 0.05 world
pixels on the damage frame. Each preset also verified a real Stalker
evolution, a west Haunted Hall recovery and a lethal hit followed by
a fade. [State matrix and raw receipts](evidence/hunter-articulation-complete/verification/)

The Reaper native fixture exercised both forms in every cardinal
direction, AStar turns, approach, transformation, real scythe hits
and fade. The blade was checked in all four views against door
damage and gameplay audio. The receipts cover the ten executable
Wrath skills plus the legacy Soul Siege, Shadow Surge, Shadow Dash
and Soul Drain pathways. See the recorded fixtures for the visual
checks that apply to each skill. [Reaper evidence and receipts](evidence/hunter-articulation-complete/reaper/)

The six ordinary clips are normal-speed, staged Endless encounters
at early, middle and late levels. The ordinary ability and Reaper
clips include live game audio. The comparison shows the same Stalker
L2 route and door exchange on `da4ef63` and the new renderer with the
same damage frames. [Footage and screenshots](evidence/hunter-articulation-complete/footage/)

## Active-combat performance

Three matched Low Reaper pairs moved the median frame time from
54.01 to 53.19 ms and p95 from 76.42 to 73.26 ms. Draw calls dropped
from 555.5 to 542.5 in every pair. One of the three pairs had a worse
tail. The single Standard Reaper pair moved from 58.31 to 59.64 ms
median and 82.73 to 86.76 ms p95. All gameplay digests matched in the
24-building fixtures. These are Linux software-renderer measurements.
[Both presets, raw samples and crowded-room stills](evidence/hunter-articulation-complete/performance/)

## Regression and playtest

The gameplay model, save schema, 50-level Story, map generation,
construction and economy files were left intact by the source
changes. Tests cover story, grid, V2 saves and match flow, audio,
combat and bosses. One older visual-polish suite reports six
hard-coded balance expectations that fail identically on the starting
commit. [Regression receipts](evidence/hunter-articulation-complete/verification/regressions/)

The atlas renderer is layered 2.5D. It switches between four painted
perspectives, so some silhouettes change sharply during turns.
Details obscured by clothes in a painting cannot articulate
independently in that view. Ordinary contact tests cover one
representative door orientation per state. Reaper contact is
verified in all four view fixtures. Frame checks and footage provide
technical coverage. Artistic acceptance and native Windows and
Intel UHD results are pending.

The Windows x64 preview uses its existing isolated profile and
includes the reference launchers. The embedded resources were
checked with Linux Godot. [Windows playtest instructions](LIVING_NIGHTMARE_WINDOWS_PLAYTEST.md)
