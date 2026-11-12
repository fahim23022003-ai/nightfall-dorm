# Phase 5C-3 — visual identity, Hunter presence and horror game feel

## Delivery and scope

**IMPLEMENTED and TESTED** on Godot 4.6.3 Linux: shared Gothic industrial UI,
haunted menu, five-map material/detail polish, actual-motion Hunter/Reaper
presentation, bounded combat scars, truthful tension pacing and camera-aware
positional audio. Phase 5C-3 is complete within the verified scope below.
Native Windows play and subjective art/audio quality remain **UNVERIFIED**.
No later phase was started.

Started on clean `work` at `f2f69f383e562c0ba8b6178bc3ba8d012da31024`,
matching GitHub. Recovery tag: `pre-phase5c3-f2f69f3`; implementation milestone:
`44445f1`. The previous progress checkpoint and Phase 5C-1/5C-2 reports were read;
existing haunted scenery, elimination, audio and Level 10 systems were inspected
and reused. Before editing production, actual baseline rendering produced 33 PNGs.
`main` was not modified.

B owned production implementation. C independently reviewed navigation and tested
presentation/UI/audio/culling. D independently captured and inspected actual
rendering and recorded engine audio. A was unnecessary because navigation testing
found no rule defect and no model/AI/balance change was made.

Final implementation commit and verified GitHub status are recorded in the
Delivery verification section at the end, after the actual push.

## UI art direction and functional screens

`GothicTheme` is a reusable cached material/theme factory. Authored 256×128
nine-slice metal/glass textures have gradients, restrained grain, bevels, rivets,
hatching and quiet label centers. Alarm, resource, interactive and rarity accents
share charcoal/slate foundations, antique gold, pale green, cyan and burgundy.
These are generated textures with depth detail, rather than flat blue recolors.
The cache is reused across control redraws and screen changes.

- Main menu: original cracked Gothic facade, stained cladding, slow fog, distant
  Hunter, licensed serif wordmark and engraved green/gold primary hierarchy.
- Top HUD: separate Gold/Electricity, survival clock, Hunter HP/state and team
  count; restrained actual-danger styling with Map/Help/Pause still accessible.
- Consumables: framed rarity icons, stock, key hints, active timers, cooldown and
  concise automatic/used/unavailable states. A spent Legendary no longer says
  READY, and automatic labels no longer repeat themselves.
- Bottom HUD: grouped bed income, door durability, construction and repair. Door
  material changes only on actual danger-state transitions, avoiding needless
  per-frame theme invalidation.
- Stage, difficulty/perk preparation, RM shop, all three inventory pages, ranks,
  both achievement pages, results, Lucky Spin, pause, settings and tutorial/
  opening controls use the same theme. Working transactions and actions remain.
- Large resource values compact independently above 100,000 with exact tooltips;
  9,999 item stacks fit. Existing body sans remains readable. Only the wordmark/
  brand uses the already licensed serif font.

Real shop mouse input and a duplicate OS double-click were exercised: the first
purchase succeeds once, the duplicate does not spend again, and a later ordinary
click can purchase normally. Existing placement, cancellation, sales and 50%
actual-investment accounting also pass their regression suites.

## Rooms, corridors and combat history

Five original authored SVG floor surfaces preserve Dorm/Hospital/Hotel/Lab/
Mansion identity. Existing geometry now carries worn floor seams, stains, rails,
lamps and bounded local themed furnishings/papers. Pads retain their explicit
interactive markings and clear placement area. No colliders, rooms, build slots
or navigation paths were changed. Existing exterior scenery, weather and ambient
creatures remain integrated rather than duplicated.

Existing muzzle flashes, Level 10 Needle/Arc armor and projectiles are retained;
subtle trails, impact rings, repair/upgrade feedback and directional attack poses
improve event readability. Reduced Effects lowers ornamental density while
keeping status and essential feedback. Repair feedback at the same point is
aggregated instead of multiplying.

A read-only match-local history records actual door damage scratches, breach
splinters, item explosion scorch and death aftermath. It holds at most **48 scars**
and **512 event observations**, deduplicates actual events and resets with the
match. It does not store a decoration history in the player save or mark pads as
blocked. Eliminated rooms retain the existing genuine collapse/corpse/dim-state
and survivor count; no second death-state system was added.

## Hunter movement review and physical presence

The five maps already use valid AStar visibility edges and physical waypoint
following. C tested six rooms × five maps × three difficulties: **90 actual
approaches / 57,056 movement-step assertions**. Intact doors block room entry,
out-of-contact attacks fail, valid contact deals damage, and real breach allows
bed-contact elimination. No navigation bug or illegal shortcut was confirmed.
Consequently pathfinding, speeds, target selection and combat rules were retained.

Presentation now follows measured actual movement and actual target door/bed
vectors: interpolated heading, directional sprite reflection, bounded lean,
hover/walk motion, readable attack anticipation/contact and trailing motion.
This corrects the old `target < 3` top/bottom-facing assumption on side entrances.
Hunter/Reaper combat animation clocks and heading hold during pause/Time Freeze,
then resume with the real model. No fake acceleration or AI intelligence is claimed.

The Reaper keeps its separately authored robe frames, skull and articulated
scythe, with distinct transformation, movement, warning and impact treatment.
Actual policy-triggered transformation, charged attack, scythe impact and breach
were rendered and checked against real events. There are no duplicate Hunters,
wall crossings, invented damage or new archetypes.

## Tension and information-rich audio

The lightweight read-only coordinator derives quiet, distant, approach, siege,
player danger, elimination and relief from actual state, position and events.
Genuine elimination holds emphasis for two seconds; local relief lasts briefly
after the threat leaves; immediate player danger takes priority. Model resources,
HP, time, target, gameplay RNG and event records are not mutated by presentation.

Camera-aware voices use the inverse canvas transform and listener offset so
left/right remains meaningful after focus/map movement and zoom. Footsteps,
door hits and Reaper anticipation get bounded directional prominence. Existing
world-distance attenuation, priority queues, voice budgets and separate bus
preferences remain. Smooth pacing reduces competing music/ambience during danger,
suppresses weather during danger/elimination and restores ambience gradually.
Menu/practice reset stale tension. No sound files were added or replaced.

An actual Godot Master-bus AudioEffectRecord capture contains **42.818 seconds**
of stereo engine output: peak **0.03653**, RMS **0.00415**, **zero full-scale
samples**. All **105 streams** load; none are missing. Real footstep, door,
scream, laugh, Reaper, item, shop and outcome playback events are recorded.
Bounded low-priority suppression remains intentional; no critical events were
pending at capture end. This is mixer evidence, not a human listening assessment.

## Actual before/after review

[Evidence index and inspection notes](evidence/visual-overhaul/README.md),
[PNG dimensions and SHA256 manifest](evidence/visual-overhaul/comparison-index.json).
There are **33 BEFORE / 50 AFTER** unedited viewport PNGs: 33 paired states plus
17 supplementary after views. D inspected all major screen families; the
coordinator also inspected the actual menu, siege and final overlap/Lab frames.

| View | BEFORE | AFTER |
| --- | --- | --- |
| Main menu | [720p](evidence/visual-overhaul/before/01-main-menu-720.png) | [720p](evidence/visual-overhaul/after/01-main-menu-720.png) |
| Stage selection | [Before](evidence/visual-overhaul/before/02-stage-selection.png) | [After](evidence/visual-overhaul/after/02-stage-selection.png) |
| Perks/difficulty | [Before](evidence/visual-overhaul/before/03-perk-difficulty-loadout.png) | [After](evidence/visual-overhaul/after/03-perk-difficulty-loadout.png) |
| RM shop | [Before](evidence/visual-overhaul/before/04-common-shop.png) | [After](evidence/visual-overhaul/after/04-common-shop.png) |
| Quiet preparation | [Before](evidence/visual-overhaul/before/09-quiet-preparation.png) | [After](evidence/visual-overhaul/after/09-quiet-preparation.png) |
| Hunter approach | [Before](evidence/visual-overhaul/before/10-hunter-approaching.png) | [After](evidence/visual-overhaul/after/10-hunter-approaching.png) |
| Door siege | [Before](evidence/visual-overhaul/before/11-door-siege.png) | [After](evidence/visual-overhaul/after/11-door-siege.png) |
| Genuine elimination | [Before](evidence/visual-overhaul/before/14-survivor-eliminated.png) | [After](evidence/visual-overhaul/after/14-survivor-eliminated.png) |
| Level 10 firing | [Before](evidence/visual-overhaul/before/16-level-ten-firing.png) | [After](evidence/visual-overhaul/after/16-level-ten-firing.png) |
| Gameplay 1080p | [Before](evidence/visual-overhaul/before/25-gameplay-1080.png) | [After](evidence/visual-overhaul/after/25-gameplay-1080.png) |

The index also pairs all five map overviews, inventory/achievements pages, ranks,
settings, pause, results/spin, tutorial, opening/title, menu/shop/loadout 1080p
and Reduced Effects. After-only views expose focused sieges on all maps, actual
Hunter direction, Reaper states, shop success, genuine tutorial progress, max
stock/high resources and overlapping-event stress cases. Prepared isolated
profiles/models expose these states; they are not natural human matches.

The paired tutorial fixture manually selects an objective without claiming a
room, so its top HUD shows the earlier step. The separately captured genuinely
claimed-room tutorial agrees with the HUD. The rank fixture supplies XP without
historical highest-rank statistics. These fixture limitations are documented;
neither is claimed as a production save failure.

## Defects found and corrected

- Tutorial/opening controls outside the main UI root lacked theme inheritance;
  the onboarding root and primary Continue now receive the shared theme.
- Decorative map title could clip beneath focused HUD; focus suppresses it,
  while overview retains it. Laboratory door HP was spaced below the ribbon.
- Original left-side Legendary flourish overlapped notices. The same flourish
  now uses the right status column below the Reaper awakening and above build
  panels. Actual 720p/1080p raster checks and 177 added layout assertions confirm
  clearance across notices, HUD, guide, all inspector modes and all four names.
- Pause/freeze heading and animation, one-frame elimination emphasis, relief
  priority and incorrect camera-origin audio anchoring were corrected during
  independent targeted review.
- Short performance samples prompted whole-room/corridor/exterior offscreen
  culling and transition-only door styling. Updates and cosmetic RNG continue
  independently of visibility; visible geometry is retained at all tested zooms.
- The first transition-only optimization emitted missing `danger_skin` metadata
  errors on match startup despite passing counters. D found them in the engine
  log; an explicit `has_meta` guard fixed them. The failing log is preserved and
  final startup/UI/render/performance logs are clean.
- One early capture assertion expected movement immediately after Freeze even
  when the Hunter had validly reached ATTACK. The corrected fixture checks expiry
  and then a real reachable MOVE route. The original failed run is retained.

No known functional failure remains in the tested paths. Final acceptance uses
engine log scans as well as counters; intermediate errors were not counted as
successful final verification.

## Automated and rendered verification

| Check | Evidence / result |
| --- | --- |
| Shared materials, actual facing, pause/freeze, scars, truthful pacing, nonmutation | `visual_identity_qa.gd`: **186 / 0 failures** |
| Actual UI controls, profile invariance, 720p/1080p, all pages, Legendary clearance | `visual_identity_ui.gd`: **1,315 / 0** |
| Camera-aware panning, buses, distance, critical cues and pacing | `visual_identity_audio.gd`: **103 / 0** |
| Five maps × three camera centers × three zooms; visible envelope/state safety | `visual_identity_culling.gd`: **1,116 / 0**, 150 offscreen regions |
| Baseline actual navigation/contact/breach | `visual_identity_navigation.gd`: **57,056 / 0**, 90 approaches |
| Baseline actual renderer | **51 / 0**, 33 PNGs |
| Final paired/supplementary renderer | **100 / 0** |
| Final actual Reaper/Guardian/Lab/Freeze detail | **26 / 0** |
| Final matched long performance fixture | **6 / 0** |
| Existing full regular regression command | Exit **0**, no engine errors, `regression-all.log` |
| Final editor import / syntax | Exit **0**, no engine errors, `import-final.log` |
| Final actual scene smoke | **24 / 0**, `scene-smoke-final.log` |

Final focused logs are `qa-qa-final.log`, `qa-ui-final.log`,
`qa-audio-final.log`, `qa-culling-final.log`; they have no errors or warnings.
The navigation baseline was captured before presentation edits and not needlessly
rerun: navigation/model files remain byte-identical to baseline. Five visual
suites are now included in `tools/check.sh` for future regular checks.

The full regular regression run includes all 20 items/combinations, Legendary
and advanced effects, haunted systems (78,195 checks plus economy 5,382 and 60
live scenarios), onboarding (164/92 and economy 57,016 over 42 scenarios),
rewards, ranks/perks/achievements, RM shop, saved result/spin transactions,
boss architecture/audio/matrix, five maps, difficulty, campaign, projectiles,
controls, UI, purchasing/cancellation/refunds (512 + 421 checks), 105 audio
streams (281 assertions), 20,000 property transactions (175,889 invariants),
cross-process profile round-trip and actual startup intro. Logs and generated
boss/reward results are preserved in this phase's evidence folder.

The regular suite ran before the late cosmetic culling/status/banner/metadata
patches; all affected presentation/UI/audio/culling suites and actual detail/
performance runs were then rerun on final production source. The unchanged
extended balance matrix was not rerun in this presentation-only phase. Test
counts include repeated invariants, not that many distinct human scenarios.

## Performance observations

Early short shared-host software-renderer samples showed approximately 16–17%
slower normal-effects means, followed by substantial 720p variability. These
results and the metadata-error run are retained, not discarded. B addressed
bounded overdraw and repeated theme invalidation, then a matched **8-second per
case** sequential test compared baseline export `f2f69f3` and final source.
Same Godot/Mesa llvmpipe, occupied-room Hell-stage-1 preparation fixture,
0.35-second warmup; no simultaneous renderer.

| Mode | Baseline mean / p95 ms | Final mean / p95 ms | Mean change |
| --- | --- | --- | --- |
| 1280×720 normal | 31.925 / 43.625 | 31.279 / 40.310 | −2.0% |
| 1920×1080 normal | 48.073 / 55.009 | 46.365 / 54.234 | −3.6% |
| 1280×720 Reduced | 29.313 / 36.804 | 28.265 / 34.047 | −3.6% |

`performance-comparison-long.json` provides exact values; warm material cache
stays **18→18** in each performance-only case. This controlled longer run supports
comparable Linux software-rendering cost and does not reproduce the initial
slower pattern. It is not a Windows hardware FPS guarantee or dense endgame
benchmark. Reduced Effects remains useful; culling changes no simulation state.

## Unverified and incomplete items

**UNVERIFIED:** native Windows import/run, physical keyboard/mouse/display,
hardware FPS/long-session memory, human gameplay, subjective fear/art quality,
headphone/speaker loudness and comfort. No Windows executable export was made.
Linux engine input and rendering do not substitute for a home Windows playtest.

**Remaining art limitations:** repeated functional pad grids, relatively simple
exterior silhouettes and retained colorful survivor/bed sprites. Props are bounded
to preserve combat/placement visibility. This is not a fully rigged four-direction
character replacement or a human-rated premium-art result. No known required
Phase 5C-3 code feature is left **INCOMPLETE**; these quality limits are explicit.

No new archetypes, specializations, modes, contracts, pity system, economy,
practice mode, Android, multiplayer or Phase 6 content was implemented. Existing
model/AI/economy/profile/map/stage catalogs, save format, project configuration
and Windows controls remain unchanged. Stop after Phase 5C-3.

## Delivery verification

Final verified implementation/evidence commit:
`724d998ab8d30b68f07e03f68ca66753f319b361`.
Push to the existing private GitHub `work` branch **SUCCEEDED** (exit 0).
A fresh `git ls-remote origin refs/heads/work` returned exactly the local HEAD
`724d998ab8d30b68f07e03f68ca66753f319b361` after the push; the tree was clean.

This following documentation-only commit records that observed verification.
Its final SHA and the subsequent remote verification are reported in the delivery
response. No force push, merge to `main`, environment publication or later-phase
implementation was performed.
