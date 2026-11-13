# Phase 9 — Freedom to Build

IMPLEMENTED: free-position construction for the human player's Endless room.
The existing game, other modes, NPC construction, combat balancing, prices and
expansion progression are retained. No agents, main-branch edits or release
publication were used. Baseline: `6dfbdce06e8a9c2f22c111fc272266c7be988e99`;
recoverable implementation checkpoint: `20c9994`.

## Playable changes

- Choose BUILD, then move the actual current building-art preview over the floor.
  A world left-click validates, pays the existing price and creates one building
  at that exact position. Invalid clicks explain the reason and spend nothing.
  The blocking structure and invalid footprint turn red; valid placement is green.
- Positions are arbitrary world coordinates. Optional snap is only eight units,
  anchored to the door; F toggles it and Shift bypasses it. There is no large pad
  lattice for the human Endless room. NPC rooms retain their authored pads.
- Select a machine, then **Move [V]**. Preparation and intermission permit moves;
  active combat does not. The same dictionary/object, selector and instance UID
  retain level, branch, paid Gold/Electricity, cooldown, flash and functional state.
  No new purchase, resource grant or cooldown reset occurs. The model reserves
  the instance against simultaneous sale/upgrade/purchase until commit/cancel.
- Right-click or Esc cancels placement/movement. A move preview leaves the actual
  object at its original location until confirmation. The successful move has a
  short render-only easing animation, respecting Reduced Motion.
- P opens the compact room-planning overlay: capacity, unlocked floor, actual
  footprints, furniture reservations and doorway/bed access corridor. It is off
  during ordinary combat. Existing bottom drawer, inspector, Team and spectating
  remain. The Build tooltip documents controls; M map and R repair are preserved.

Rotation and last-move undo were optional and are INCOMPLETE/not implemented.
The buildings' existing directional combat presentation follows their actual
Hunter target; arbitrary furniture rotation would not change mechanics.

## Authoritative geometry and identity

`SpatialConstruction` is attached only when the human claims an Endless room.
`RoomState.tile_count()` remains capacity; `buildings` keys are opaque selectors;
`buildings[id].position` is the physical coordinate. New desktop selectors begin
at 16 and increase monotonically, including after sale/reload. Independent
`instance_id` values survive movement. Old selectors are preserved on migration.
The serialized field `tile` retains its historical name for compatibility, but
is now an opaque selector in spatial rooms, never a coordinate.

`RoomState.tile_position(id)` is the single compatibility resolver. Combat
launches, range checks, targeting, effects, audio, selection and render code use
it. The actual desktop workflow uses `place_building(kind, point)`, not an index.
Older model clients can request an old pad through `build(kind, tile)`; that one
adapter applies the same real footprint/capacity/payment validation and avoids
reusing sold identities. It is not the player construction workflow.

The audit covered the position resolver's consumers in Game, Interface,
MapPresentation, DormPresentation, MatchModel, room transactions, snapshots,
DefenseEffects, MagicDefense, item effects and BotAI. The two historical legacy
render paths are used only for legacy non-Endless maps; authored Endless maps use
MapPresentation. NPC tile loops remain unchanged because those rooms are fixed.

Physical footprint: 44×40 world units, two units of inter-building clearance and
an eight-unit wall inset. Separate reserved regions protect the bed, cabinet,
plant, doorway and door-to-bed route. Decorative glows and tall art do not enlarge
that base footprint. All mutations validate at model level; mouse coordinates
use the viewport canvas inverse, including camera zoom/translation. Furniture
reservations are cached per layout; drag checks scan at most sixteen structures,
not the whole map or navigation graph.

## Expansion remains physical and paid

| Tier | Capacity | Gold | Electricity |
|---|---:|---:|---:|
| Foundation | 3 | — | — |
| Level 1 | 6 | 120 | 15 |
| Level 2 | 8 | 240 | 35 |
| Level 3 | 10 | 450 | 65 |
| Level 4 | 11 | 700 | 110 |
| Level 5 | 12 | 1050 | 180 |
| Ultimate I | 14 | 1600 | 280 |
| Ultimate II | 16 | 2400 | 420 |

Existing bed/door prerequisites are unchanged. Growth extends the real bounds,
refreshes the existing navigation/camera framing and unlocks new usable floor.
Occupied bed/cabinet/plant anchors and every existing building stay fixed. Before
paying, the candidate layout must validate all current structures. The native
video purchases a Dynamo on floor that the old bounds did not permit.

## All fifteen categories

All retain their existing real prices, L1–10 progression, exclusive branches,
upgrade requirements, actual-spend ledger, effects and exact 50% separate-currency
refund. Tests buy/upgrade/specialize/move/sell every category, including L10;
Level 11 and duplicate refunds are rejected.

| Category | Existing positional/mechanical integration |
|---|---|
| Needle | Projectile origin/range from actual position |
| Arc | Projectile origin/range and branch stats from actual position |
| Dynamo | Existing room economy tick; movement cannot generate a bonus |
| Repair station | Existing room-door repair and power rules |
| Dream amplifier | Existing room income multiplier/caps |
| Target relay | Existing room weapon support multiplier/caps |
| Flame turret | Actual-position shot, existing bounded burn |
| Frost tower | Actual-position shot, existing control/refractory rules |
| Shock trap | Actual-position shot/range, persistent cooldown |
| Auto repair station | Existing paid room-door repair/refractory |
| Shield generator | Existing Electricity cost/shared shielding cooldown |
| Decoy beacon | Existing room-door lure from a valid selected instance; cooldown unchanged |
| Mirror barrier | Existing room magic reflection/refractory, no recursion |
| Plasma capacitor | Existing room absorption/storage cap and repair release |
| Ward antenna | Existing room ward/cap/paid regeneration |

Support/ward mechanics were already room-wide or capped/strongest-only, not
neighbor-pad mechanics. Their stacking, resource costs and counterplay were not
changed. Closer legal placement therefore grants no new support multiplier.
Range still matters: a turret placed far at the back may not reach the Hunter.

## Save compatibility and recovery

New Endless snapshots use **schema 2 / ruleset 5**. Historical schema 1/rulesets
1–4 are accepted explicitly. Challenge Codes remain their existing ruleset 4;
they are not silently re-versioned by this Endless-only feature.

Old pads resolve through their corresponding historical expansion geometry,
then receive actual coordinates and stable instance IDs. Existing stored UIDs
are retained; truly old snapshots omitted them, so deterministic room-local UIDs
are assigned without inventing knowledge of a missing historical UID. Building
selectors, types, levels, branches, investments, cooldowns, balances, expansion
and RNG survive. A bounded deterministic load-only relocation fallback is present
for an obstructed historical position; it never deletes a building or charges
money. **No relocation was necessary in the tested original full16 layouts on
five maps or in the canonical earned wave45 checkpoint.**

Schema2 requires finite bounded position pairs, valid footprints, unique selectors
and UIDs, authoritative capacity and valid monotonic-ID metadata. Missing new
positions, overlap, furniture/wall violations, duplicate IDs and nonfinite values
are rejected rather than silently resetting the layout. Schema1 safely supplies
its omitted coordinates from the original geometry.

A confirmed existing recovery gap was fixed: a malformed spatial checkpoint in
an otherwise readable profile can recover only the checkpoint from a compatible
valid backup of the same run/map/seed/difficulty. **Current inventory, consumed
item counters, Legendary/automatic-use ledgers, cash, XP and other current replay
records stay current.** The damaged primary is quarantined and is not overwritten
merely by loading. Without a compatible known-good backup, preservation/read-only
behavior remains. Unknown future checkpoint schemas are not guessed.

Actual disk tests cover JSON roundtrip, Quit/Continue, corrupt coordinates,
backup recovery, incomplete `.tmp`, a real post-checkpoint Repair consumption,
and refusal to save invalid in-memory coordinates. The canonical earned source
and user saves were never edited; profiles are isolated test copies.

## Evidence and testing

[All original screenshots, video, fixtures and logs](evidence/freedom-to-build/INDEX.md).
Screenshots are real Godot 4.6.3 Linux runtime output, mostly 1280×720 plus the
1920×1080 late layout. Controlled capture fixtures use prepared budgets and paid
upgrades; they are not natural progression or human playtests. The earned45
screenshot uses the unchanged canonical earned checkpoint, with its five actual
eliminated teammates, not a fabricated alive count.

[Earned continuation](evidence/freedom-to-build/earned46.json): the unchanged canonical
wave45, one legal turret move, actual repair upgrades and four off-pad Arc10
purchases from original funds defeat the full180,600HP Hell46 Hunter in42.8
simulated seconds. The relocated turret launches44 observed shots; projectiles
peak8 and presentation events45. No money/HP/path injection. This automated
checkpoint strategy is not a natural1→46 or human playthrough. **60 checks/0**.

New focused model tests: **1,397 checks / 0 failures**. Save/effects/recovery:
**179 / 0**. Actual rendered mouse/keyboard checks at both resolutions:
**64 / 0**, including zoomed runtime mouse checks in all four door-normal orientations. Runtime screenshot capture: **199 / 0**. Native scripted input video (88.208s,24fps,1280×720; separate85.914s actual Master audio):
**82 / 0**, plus a direct X11 B-key probe **3 / 0**. Final regression results are appended below after the full run.

Confirmed failures and fixes:

1. JSON parses integer-looking values as floats. Strict array membership rejected
   old versions/IDs; validation now checks whole finite numbers and normalizes IDs.
2. New checkpoint corruption did not consult a usable backup; checkpoint-only
   recovery now retains current permanent transactions, tested with real item use.
3. The frozen capture fixture did not advance the move interpolation timer,
   leaving art at its old render location while badges used the committed one.
   The production `_process` already advanced it; the fixture now does too.
4. Invalid overlap showed a green existing-footprint border beside the red ghost.
   The obstructing footprint and a stronger outer ghost outline now both turn red.
5. Older UI fixtures left the first-visit welcome overlay open, blocking their
   intended gameplay clicks. They now use the existing graduate fixture helper.
   An old fixture tried to restart a killed drawer tween; it checks validity first.
6. Historical-schema tests were constructing a new schema2 body with an old
   ruleset. They now construct actual schema1 data, retaining corruption assertions.
   A save test now compares the independent snapshot ruleset, not ChallengeCode's. Older audio assertions now distinguish the existing Phase8 QOA imports from PCM16; no audio asset or format was changed.
7. A move-event routing gap originally placed its cue at the room door; the
   move event now carries the actual destination, verified by the production
   presentation/audio packet test.
8. A pre-existing replay-opening Skip bug could leave cinematic mode active after
   Welcome had already been dismissed. The narrow replay exit now cleans up and
   returns to menu; current manual-Welcome/tutorial and music checks pass.
   Another existing HUD ordering issue overwrote SAFE PRACTICE with the normal
   evolution label; tutorial labels now retain their intended priority.
9. Initial capture-driver coordinates outside the floor and incorrect category
   names were corrected. Failed staged artifacts were replaced with checked
   final output; no gameplay validation was weakened to accommodate the fixture.

## Performance and limitations

[Measured samples](evidence/freedom-to-build/performance.json): Linux Godot 4.6.3,
GL Compatibility/Mesa llvmpipe software renderer on the shared environment,
1280×720; 30 warmup and 240 measured frames each. Full16 idle mean39.14ms / p95
53.23ms; planning38.82 /56.19; live mouse-drag validation41.83 /56.85. Scene nodes
remain190 throughout, with no building/wallet mutation. This measures incremental
planning/drag workload, **not a paired old-executable benchmark or Windows FPS**.
The short test does not establish hours-long memory or hardware frame pacing.

UNVERIFIED: native Windows launch/performance, human mouse comfort, enjoyment,
subjective sound quality, very long sessions and every possible dense layout.
At720p the expanded room is intentionally zoomed out: role silhouettes remain
visible, but small badges still benefit from selecting a building for details.
Rapid batch upgrades can still briefly overlap their existing temporary prestige
announcements; the steady-state full16 captures wait for those animations to
expire and do not claim to solve every peak-effect composition.
Selection uses the nearest actual core within its hit region; Windows playtesting
should check comfort in tightly packed rooms. Rotation/undo are not advertised.
The desktop workflow is the verified target; a mobile free-placement redesign
was not performed.

## Final quality gates

| Gate | Result and evidence |
|---|---|
| Genuine arbitrary physical positions | PASS — fractional coordinates and real mouse/native clicks |
| No required original pad grid | PASS — player free floor; NPC pads intentionally retained |
| Exact expansion progression/prices | PASS — all tiers, five maps, six room orientations |
| Expansion unlocks usable floor | PASS — real purchase and native new-floor placement |
| No illegal physical overlaps | PASS — authoritative footprints/forged save rejection |
| Door/bed access protected | PASS — reserved route/furniture rejection |
| Safe repositioning | PASS — preparation/intermission model lock |
| Building state retained | PASS — all15 L10 branches/cooldowns/investments |
| Effects resolve actual positions | PASS — tick-driven relocated launch/damage, support/magic checks |
| Existing saves retain buildings | PASS — historical profiles/full16/earned45 and current disk roundtrip |
| AI/other modes remain functional | PASS — complete effective regular gates, fixed-mode UI/maps/AI/spectator checks |
| Full16 readability | PASS for inspected fixtures; human comfort UNVERIFIED |
| Real relocated combat | PASS — tick integration and continuous native-input recording |
| No major performance regression | PARTIAL — short incremental Linux sample bounded; old-executable/Windows/long-run comparison unverified |
| Honest screenshots/video | PASS — originals and staging/clock limitations disclosed |

The task stops at Phase 9. No future phase or release was started.


## Final verification and delivery

**124/124 named regular gates PASS**, plus the main136-assertion model gate,
clean final import,33-check scene smoke, real fresh application startup, and
separate-process profile write/read/cleanup. The six newer retained phase gates
(Omens, Nightmare, Cinematic, adaptive readability, late clarity and gameplay
visual polish) also pass. No effective final test remains failed.

The regular run was completed through staged continuations and focused corrected
reruns, rather than claiming one uninterrupted `tools/check.sh` invocation.
[Effective results with all raw logs](evidence/freedom-to-build/regular-results.json)
and [initial/corrected attempt receipts](evidence/freedom-to-build/logs/attempts/)
retain the distinction. Additional optional `--extended` gates were **not run**;
no prices, AI intelligence or combat-balance values changed. Regular coverage
already includes144 resolved map simulations,90 difficulty matches,540 legal
Hunter/door approaches,120 reward matches,120 Legendary matches,60 advanced-item
matches,60 boss matches and20 campaign matches, alongside transaction/input gates.
These automated outcomes are not human approval of difficulty or usability.

The final high-ID inspector checks actually click Upgrade and Sell after moving,
with exact resource deductions/refunds at both resolutions. Current focused
results are1397 model,179 saves/effects/event-origin,64 rendered UI,64 headless UI,
60 legitimate earned46,199 screenshot checks,82 continuous native-input checks,
3 native B-key checks and29 bounded performance checks, all with zero failures.
The recording predates only the final move-cue origin correction; its actual
position packet is covered by the later179-check suite. Construction/economy
behavior in the movie matches the delivered implementation.

32 historical test-output files were restored byte-for-byte; their current-run
metrics are archived separately. Canonical checkpoint bytes and user profiles
were preserved. No balancing change, release, main merge or next phase occurred.

To run: download the **work** branch, extract it, import `project.godot` in
Godot4.6.3, then choose Endless, occupy a room/bed and use Build/B. Other modes
intentionally retain their prior placement system. The Windows checklist is
[here](PHASE_9_WINDOWS_PLAYTEST_CHECKLIST.md).

The exact final Git SHA and verified remote push status are recorded in the
final delivery message after committing this report and evidence. In a Git
checkout, `git rev-parse HEAD` identifies that same delivered version.
