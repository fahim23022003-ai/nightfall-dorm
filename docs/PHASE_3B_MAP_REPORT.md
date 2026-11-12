# Phase 3B — maps and expanded building system

Continued clean `work` at `788442c72edb46051f825daff9734b3f9e9ffa2e`.
Verified Phase3A with the full regular baseline before core/render changes.
Recovery tag: `pre-phase3b-788442c`; prior commits remain in history.

## Implemented environments and assignments

| Stage | Map | Meaningful layout differences | Pads per room |
| --- | --- | --- | --- |
| 1 | Abandoned Student Dorm | Compact paired room rows and traditional single hall, worn student furniture | 12 |
| 2 | Haunted Hospital | Parallel halls/crosslinks, smaller center rooms, medical checker floor/IV/cross motifs | 10/12 |
| 3 | Forgotten Hotel | Long alternating guest rooms, spread-out support, carpet/runners/guest decorations | 10 |
| 4 | Underground Laboratory | Two vertical trunks with loop connections, side-facing doors, grates/pipes/consoles | 12 |
| 5 | Cursed Mansion | Branched halls, large/small rooms, parquet/portraits/candles, wider utility space | 10/16 |

MapCatalog owns room bounds, cardinal doors, reserved bed/access space, furniture,
build positions, corridor rectangles, graph points, spawns and overall bounds.
Stages reference map IDs; map themes can be reused independently of difficulty
and stage modifiers. All six rooms on every map support the existing loop.
No whole-game duplication or external downloaded art. Procedural original
environment art reuses existing character/building components at fixed scale.

## Placement, camera and presentation

All placement, validity, bot construction and sale/refund bounds use tile_count,
not a six-slot constant. Pads do not overlap or occupy furniture; max-level
building art remains within53×56 on58-unit centers. Beds/doors retain access.
Expanded slots are numbered and real input is checked at the highest slot in
every room. A sold tile is immediately reusable, with exactly half of paid gold
and electricity refunded. Mouse motion never moves the anchored preview.

Camera fitting uses actual room/map bounds, reserves the right inspector and
top/bottom HUD, and supports varied10/16-slot rooms and side entrances.
Click coordinates come from the click event through the current canvas transform.
Tutorial/feedback hides while the custom-map inspector is open so it cannot
cover the bed/side door; it returns after close without changing preferences.
Environment names appear in stage selection and preparation.

Existing horror damage numbers, danger notifications, sounds and music remain.
Distant sounds use map-size-aware hearing range with attenuation so larger maps
do not silently suppress teammate encounters. No new permanent rewards or
save-schema changes beyond Phase3A. Windows project/export config unchanged.

## Navigation and bots

Shared collision geometry produces separate cached AI and furniture-safe player
visibility graphs. Walls require a real doorway aperture; room-corridor overlaps
cannot bypass wall collision. Paths are sampled at2-unit precision. Hunter
movement is bounded by speed/delta and routes through corridors to the selected
door, then the victim and back out; no teleportation or catch-up relocation.
Bots walk from corridor spawn to their own claimed beds instead of spawning
instantly at doors. Five unique owners arrive, sleep, earn, build and react under
the existing AI. Legacy standalone geometry remains for compatibility tests.

Initial QA found real player paths crossing a bed or too-wide connector edge;
separate player graphs, solid-wall priority, doorway precision and additional
bed-corner approach nodes fixed the root cause. Retests traverse actual player
movement, not just a planned path. Hunter tests cover all30 rooms through
attack/breach/elimination/exit and verify events and no speed jumps.

## Balance and performance

Prices, damage rates, door durability and rank rewards were not arbitrarily
changed. Extra pads have opportunity costs and range tradeoffs: only5–7 Needle
positions in these rooms reach their own door approach. Independent earned-
resource turret/economy probes reached12/16 buildings without free resources.
See [MAP_BALANCE_REVIEW.md](MAP_BALANCE_REVIEW.md) for measured samples/limits.
The final regression matrix also compares balanced/passive and extra-slot stacks.
Automated policies are not a claim of human difficulty or complete balance.

Static graph construction is per map load; cached actor routes avoid rebuilding
the world graph per frame. Measured cloud load samples were approximately
0.33–0.49seconds per map. This is not a Windows FPS/performance certification.

## Verification and evidence

- Full pre-change regular baseline passed.
- Final core geometry/navigation suite:15,348 checks, zero failures.
- Independent integration:5,107 checks, zero failures, including real player
  movement and sleeping, all-room hunter lifecycle, five bots per map, pads,
  ownership, building/refund and actual mouse interactions.
- Additional main UI suite:922 checks, zero failures across all30 rooms.
- Final regular wrapper includes the144-match all-map matrix, existing20-stage
  campaign matches, old12representative matches, Phase1/2 input/audio/notifications,
  Phase3A persistence/loadout, rank/save/property/combat and main startup.
  Final wrapper exited 0 with no script/parse/error signatures: 144 map matches
  (84 wins/60 defeats, zero unresolved/resource failures), 20 campaign matches
  (10 wins/10 defeats), and 12 legacy matches (9 wins/3 defeats).
- Independent 72-match balance probe uses actual starting25 gold and earned
  resources. It is a separate sample, not additional unique human coverage.
- AgentD actual Linux Godot/Mesa audit:201 checks, zero failures,18captured frames
  at1280×720/960×540. Every pad in representative rooms was selected by real
  mouse events, with highest-pad purchase/double-click/cancel-free preview/sale
  checked on every map. Both mansion capacities and lab side doors were inspected.
  Initial tutorial overlap was corrected and recaptured.

Screenshots/reproducible fixture: `docs/evidence/maps/` and
`tools/capture_maps.gd`. Screenshots are prepared fixtures, not natural
Windows playthroughs. Headless simulations exercise real production rules.
Counts above are distinct measures, not a sum of gameplay scenarios.

No known remaining failure in the verified paths. Native Windows execution,
physical audio quality, human balance and target hardware performance remain
UNVERIFIED. The hotel overview necessarily shows more zoomed-out small rooms;
focused rooms retain usable targets. Targeted test coverage is finite.
No Phase4/Hell/Grim Reaper/Mythic/Android/APK work or unrelated mechanics.

## Checkpoint and backup

The final response records the exact verified committed/pushed SHA. Push existing
`work` without force and compare remote full SHA to local HEAD; a local commit
alone is not proof of backup. No public deployment or publication.

Verified implementation commit: `ea5d4f85135d736b533432380779b3961d484b6f`.
GitHub push succeeded to existing `work`; `git ls-remote origin refs/heads/work`
returned that exact full SHA after push. This documentation follow-up records the
verified content checkpoint; the final chat reports the latest documentation SHA.
