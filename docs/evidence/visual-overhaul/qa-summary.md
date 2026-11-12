# Independent Phase 5C-3 QA

Agent C exercised production Godot 4.6.3 code on Linux. Fixtures are prepared
profiles/models; these are not native Windows play or subjective art/audio ratings.
Root owns full legacy regressions. D owns paired actual before/after renders,
animation inspection, mixer recording and visual performance observations.

## Navigation inspection and baseline

The five current maps already use AStar2D with visibility-tested edges and cached
physical waypoint following. Corridors are authored valid floor, not an arbitrary
movement restriction. Hunter MOVE approaches the actual door; ATTACK checks contact;
BREACH permits bed routing only after an open/destroyed door. No production
navigation bug was confirmed, so no new archetype, damage, target selection or
pathfinding system was requested by C.

`visual_identity_navigation.gd` passes **57,056 checks across 90 approaches**:
six rooms ×five maps ×three difficulties. Actual Hunter movement stays on valid
floor and within speed bounds; intact target rooms are not entered; approach
cannot damage; out-of-contact attacks fail; valid contact deals actual damage;
a broken door enables real breach and bed-contact elimination/exit. This was
captured against baseline `f2f69f3` before production edits. Most assertions are
repeated movement-step invariants, not 57,056 distinct gameplay scenarios.

Source review did find visual weaknesses: the previous normal-Hunter attack
frame used `target<3`, a legacy top/bottom-room assumption inappropriate for side
entrances; the animation clock also advanced during pause. Both are addressed by
state-aware actual-vector facing and held combat animation clocks. Model/AI rules
remain unchanged.

## Current focused presentation checks

`visual_identity_qa.gd`: **186 checks, zero failures**.

- Shared components use actual textured/layered materials, with distinct hover/
  press states, center/edge/depth variation and cached resource reuse.
- Measured button-text contrast meets the tested 4.5:1 normal and 3:1 disabled
  thresholds. This is not a blanket accessibility certification for every label.
- Five-map pacing uses actual Hunter state/position, damaged player door and real
  elimination records. It does not mutate model time/RNG, HP, damage, target,
  resources, inventory effects, projectiles or event records.
- Real door-direction heading works for all map orientations. Pause/Time Freeze
  hold both the presence orientation/clock and actual Hunter/Reaper sprite clocks.
- Local relief is possible after the actual threat leaves, and a real elimination
  remains emphasized beyond one frame. Immediate player danger retains priority.
- Fake living-survivor/intact-door callbacks do not create death/breach scars.
  Real damage does; duplicate observation does not add copies. Event pressure
  retains at most48 scars and512 observations. Reset/new-model clears history;
  history is not part of persistent profile progression.

These tests were added while B implemented fixes. API review caught heading
continuing during freeze, one-frame elimination emphasis, relief being overridden
by a still-living distant threat, and teammate death overriding immediate danger.
B corrected them before the passing focused run. No failing result is concealed;
the first executed focused file already passed.

## UI and resource ownership

`visual_identity_ui.gd`: **1,138 checks, zero failures**. A prepared legitimate
Mythic graduate profile is saved and reopened through the actual scene and opening
skip API. At1280×720 and1920×1080, menu/stages/loadout/shop/ranks/achievements/
settings and all three inventory pages retain functional buttons, shared material
states and on-screen logical control bounds. Compact inventory, shop and
achievement actions fit their actual cards after minimum-size layout. Pure screen
navigation cannot grant/spend or alter the saved progression snapshot. Repeated
known-screen changes do not grow the material texture cache.

The resolution checks exercise engine control rectangles and scaling; D's actual
raster comparisons independently assess text/art readability. C did not replace
working interactions with mock controls or disable existing assertions.

## Positional audio and pacing

`visual_identity_audio.gd`: **103 checks, zero failures**.

Camera projection checks put real AudioStreamPlayer2D voices left/right at three
widely separated camera centers and three zooms. Both projected direction and
panning strength remain meaningful after focus/map movement. Ordinary far cues
are culled; true distant death cues retain bounded prominence. Existing Ambient
and Effects bus preferences remain independent; music player count stays four.

C caught that the first proposed source anchor used a local viewport center as
world coordinates, which would pan incorrectly far from origin. B now converts
through the inverse canvas transform and accounts for zoom. Current tests pass.
Danger attenuates competing music/ambience; relief returns gains gradually;
reset clears stale tension. Audio pacing does not alter combat, RNG or difficulty.
D verifies actual mixed output/clipping; C's checks do not claim human listening.

## Limits

No confirmed functional failure remains in C's tested paths. Native Windows
import/input/hardware FPS/speakers, subjective excitement/fear/visual appeal and
human gameplay balance remain UNVERIFIED. Future features remain out of scope.
