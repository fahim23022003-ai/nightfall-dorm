# Gameplay, Hunter and HUD overhaul

Status: IMPLEMENTED AND TESTED. All requested workstreams are complete within the tested scope.
Native Windows execution and subjective human usability/art/audio judgments remain
UNVERIFIED. No incomplete check is presented as a passed test.

## Project inspection and preservation

Started clean on `work` at `457560dc4a8712dd644b7a7cdca509218fe83f70`.
Recovery tag `pre-gameplay-overhaul-457560d`. Existing Godot 4.6.3 project and its
single authored `scenes/main.tscn` are reused. No new project, replacement Ranked
system, duplicate Reaper, multiplayer or release was created. [Initial inspection](evidence/gameplay-overhaul/inspection.md)
records existing systems and assets. Tests use isolated profiles.

Existing campaign/rank progression, stage rewards, NPCs, five map identities,
Endless intermissions/checkpoints, Challenge normalization, twenty consumables,
Legendary limits, shop/RM Cash, pity, cosmetics, tutorial/cinematic, music and
spectating are retained. Final regression acceptance is recorded below when ready.

## HUD and building workflow

The previous header stayed at y460–506 on a1280×720 canvas even when its body was
hidden. It crossed gameplay and reserved a short camera view. The closed toolbar
now sits at y650–704. One contextual drawer slides between y724 and y438 in0.26s
using a cubic Tween. Build, selected Upgrade, Bed, Door and Repair remain accessible;
actual current/next stats, resource prices, branch preview/confirmation and sale
quotes reuse the existing transactions. Fifteen illustrated cards fit a5×3 grid.

The toolbar stays above the moving drawer in both draw and Control input order.
Repeated transitions kill the previous tween; moving controls reject transactions.
Held-Escape cancellation, double-click deductions/refunds and keyboard repairs
remain guarded. Attacks do not dismiss an intentionally opened drawer. Camera
framing stays fixed across panel changes; the closed view has more vertical room.
[HUD rendered review](evidence/gameplay-overhaul/hud/REVIEW.md) and
[independent input review](evidence/gameplay-overhaul/qa-hud-summary.md) retain
actual engine evidence and initial fixture failures.

## Physical Endless room expansion

| Purchase | Usable pads | Gold | Electricity | Bed and Door requirement |
| --- | ---: | ---: | ---: | --- |
| Foundation | 3 | — | — | — |
| Level1 | 6 | 120 | 15 | Level2 |
| Level2 | 8 | 240 | 35 | Level3 |
| Level3 | 10 | 450 | 65 | Level3 |
| Level4 | 11 | 700 | 110 | Level4 |
| Level 5 | 12 | 1050 | 180 | Level4 |
| Ultimate I | 14 | 1600 | 280 | Level 5 |
| Ultimate II | 16 | 2400 | 420 | Level 5 |

Total expansion spending is6,560Gold/1,105Electricity. Existing corridors, door
anchors and map themes remain; rooms grow backward with visibly longer floors and
moved back walls. Pad coordinates append without changing the existing prefix.
Navigation graphs/routes, camera bounds and placement use the same geometry.
Purchase errors explain resources/requirements. Campaign capacity is unchanged.

Old ruleset1–3 saves retain their exact original bed, door, bounds and10/12/16-pad
layouts. Later expansion appends safely to that historical layout. New checkpoints
store a validated expansion header, and restore geometry before validating tiles.
[Independent QA](evidence/gameplay-overhaul/QA_EXPANSION_SUMMARY.md) and
[actual rendered review](evidence/gameplay-overhaul/expansion-render/REVIEW.md)
cover all five maps and both desktop resolutions. Controlled visual budgets are
separate from the balance auditor's earned-resource simulations.

## Damage and elements

`DamageRules` centralizes Physical/Magic packets and separate affinities. Claws,
Needles, trap impacts, undead strikes and scythes are Physical; Arc, Fire, Ice,
Shock, Inferno, curses, souls, phantoms and supernatural attacks are Magic.
Explicit source mappings preserve legacy calls. Real projectile, burn, consumable,
minion and boss damage routes carry the type; this is not a presentation-only stat.

Fire→Ice→Earth→Electric→Fire is the small counter loop:1.15 against the favored
affinity,.90 against the reverse,1.0 otherwise. Neutral has no modifier. Original
icons and concise tooltips disclose it. No affinity grants immunity. Physical hits
use warm claw/impact marks; Magic uses purple spectral pulses. Reduced Effects
reduces moving beams and pulses.

Outgoing Hunter evolution and door armor resolve before magic-defense capacity,
then existing general barriers, item shields and rescue rules resolve. This keeps
stated absorption limits truthful. Applied damage and actual attacker identity
remain the basis of credit, healing and reflection.

## Three magic defenses

All three are permanent machines using the existing purchase, requirements,
exclusive Level 5 branches, Level 10 cap, discounts, actual-investment accounting
and separate50% Gold/Electricity sale refunds. Original artwork is used in-world
and in the palette. Actual computed previews and activation effects are visible.
Only the highest-level installed device of each kind applies (first placed wins equal-level ties); room cooldowns survive
selling/rebuilding. Physical damage bypasses these magic-specific effects.

| Device | Actual effect | Exclusive branches |
| --- | --- | --- |
| Barrier | Reflects10%+1.5% per level of eligible Magic damage to the actual attacker, shared4s cooldown. Original hit still reaches defenses; reflection is explicitly nonrecursive. | Mirror:20% greater return/5s cooldown; Quick Silver:20% weaker return/3s cooldown. |
| Plasma | Absorbs25% Magic up to90+25×level temporary energy; expires after12s. Every3s spends at most30+10×level energy for20% door healing, requiring an intact damaged door. Energy never becomes permanent Electricity. | Reservoir:20% absorption/18s retention; Converter:30% absorption/35% healing. |
| Antenna | Magic shield durability30+12×level. Recharges only after depletion and its10s cooldown, paying2+0.5×level Electricity. | Dome:35% more capacity/12s cycle; Pulse:20% less capacity/7s cycle. |

Base prices are Barrier 90 Gold/15 Electricity, Plasma 100/18 and Antenna 85/14. Existing upgrade factors are 1, 2, 3, 5, 7, 10, 14, 19 and 25 times base Gold and (base Electricity + 3); an exclusive branch adds 25 Gold/4 Electricity. Undiscounted total investments through Level 10 are respectively 7,855/1,567, 8,725/1,828 and 7,420/1,480 Gold/Electricity. Operating shield Electricity is not refundable. For example, a 40%-discounted Barrier costs 54 Gold/9 Electricity and its base investment refunds exactly 27 Gold/4.5 Electricity, rather than half the list price.

Storage/shield/cooldowns are saved and validated against installed capacities.
Removing the device clears its unavailable shield/storage while preserving shared
refractory. Older checkpoints without magic buildings migrate with zero state.

## Hunters and actual animations

Crusher, Stalker and Ravager retain their established attacks and tactical roles.
Crusher already covers the proposed physical tank; a cosmetic duplicate Brute was
not added. The existing Reaper remains the hybrid elite, preserving both phases,
undead cap, previous counters and combined Eternal Sacrifices/Crimson encounter.

| Hunter/addition | Measurable behavior and counterplay |
| --- | --- |
| Phantom Witch | Magic/Ice cursed projectile,1.1s warning,16s cooldown, launches within140px through a clear corridor;220px/s bolt revalidates collision and its living door target;1.15× attack damage. |
| Electric Ghost | Legal door-contact Magic/Electric strike at0.8× damage;3s turret interference with18s protection against renewed disruption; repairs and inventory remain usable.1.1s warning/16s cooldown. |
| Storm Wraith | Contact Magic/Electric strike and up to two secondary visible corridor doors within240px at45% damage. Walls block secondary targeting.1.1s warning/16s cooldown. |
| Reaper Soul Drain | Magic door damage; heals25% of actual damage, at most1.5% maximum HP. No healing after death. Shared22s cooldown. |
| Reaper Shadow Dash |0.7s warning,1.2s movement burst at1.4× speed through existing legal navigation; shared22s cooldown. |

Forty-two original SVG poses cover six archetypes×idle, walk, attack, hurt,
defend, special and death. Actual velocity, strikes, hit flash, suppression,
tactical warnings and lethal state select them; bobbing, stride, lean and fade
provide motion. Distinct masks, horns, torn robes, weapons/coils/staves and glowing
eyes preserve a readable cartoon horror style. Existing layered Reaper robe,
scythe and smoke remain. These are coherent original vector-cartoon assets, not a
claim of hand-painted pixel sprite sheets or human-approved final art.

Campaign encounter choice, Endless rotation, Practice and Challenge expose the
expanded roster. Challenge ruleset4 keeps old roster indices stable and archives
versions1/2/3; old codes are not silently played under new combat rules. Existing
challenge normalization remains. Reproducibility remains scoped to supported
engine/fixed-input conditions, not arbitrary human timing across platforms.

## Bots, audio and balance

Bots pay actual costs, retain their existing priorities and can purchase Endless
expansion when near capacity. Against casters, a sufficiently healthy and powered
bot can prioritize Antenna. No free resources or online multiplayer were added.

Existing recorded effects supply distinct ability warnings, magic impacts,
reflection, shields and release cues through the existing bounded audio routing.
All eight existing music files, including the seven earlier scores and Crimson music, and proximity behavior are preserved. No new third-party
sound source or redistribution dependency was introduced. Engine PCM and final visual review are accepted within their stated scope; audible signal is not human audition.

[Independent balance review](evidence/gameplay-overhaul/balance/REVIEW.md): 39 final scenarios, 1,369,972 repeated invariant checks, zero failures. Repeated per-frame checks are not unique gameplay scenarios. All three initial Hell passive controls lost. Active strategies won without requiring the new magic defenses. Electric Ghost on Underground Lab defeated both tested fresh active policies; other maps/seeds supplied winning controls. This is a demanding manual-playtest case, not proof of universal unfairness or a prescribed win rate.

Three earned-resource Endless runs reached 16 slots and Level 10 Needle, Arc, Barrier, Plasma and Antenna. They paid all expansion and upgrade costs without resource, HP, position, clock or wave injection, perks or consumables. At 3,600.1 simulated seconds they had cleared 39/35/35 waves. A separate Hell run lost naturally on wave 46 after 45 clears at 4,487.5 simulated seconds (74.79 minutes); all five NPC allies died. Ten minions and bounded projectile/navigation pools remained controlled. Checkpoints were JSON-round-tripped at genuine intermissions. Finite observations do not prove unlimited-session memory safety or universal balance.

After the first-contact warning defect was fixed, all 39 balance cases were rerun. Earlier results remain archived and are not relabeled final. Subsequent targeted cleanup cancels pending arcane effects at death, transformation and combat termination. The affected 30/0 engine gate covers those cancellation paths; prices, scaling and damage formulas remain unchanged. Balance results are bound to their audited source, with this later cleanup validated separately.

## Failures and fixes

- Drawer briefly covered toolbar controls inconsistently during transition. Full
  Control child ordering now fixes both drawing and hit priority; affected tests pass.
- Fresh horizontal Lab bed approach was inside the navigation wall margin. Its
  furniture rail moved inward without moving pad prefixes or historical saves.
  Independent all-map navigation and legacy checkpoint retests pass.
- Lab trait text overlapped furniture after growth. Orientation-aware lower-strip
  placement passes affected rendered checks.
- Initial magic absorption preceded outgoing evolution damage. Ordering now
  applies the scaled attack before consuming finite shield capacity.
- Three new defense tooltip descriptions were missing. Explicit descriptions were
  added; the affected scene test passes33/0.
- Old all-buildings fixture had12 pads for the now15 registered machines. It uses
  an existing16-pad Mansion room; campaign geometry was not enlarged to satisfy it.
- Old instantaneous UI fixtures are being adapted to the real animated transition.
  Original failure logs are retained; no failing assertion is disabled.

- The three new Hunters initially lacked the ordinary first-contact wind-up because the old eligibility list included only the original roster. All six now use the proper first warning; independent combat, fresh Challenge workers and all 39 balance cases were rerun. Their basic warnings also route to valid existing recorded cues.
- Legacy no-strategy tooltips accumulated text per frame, and a Challenge preview still showed ruleset 3. The base tooltip resets every refresh and the preview uses the actual current constant; 2,003 focused checks and the affected UI regression pass.
- New roster portraits were absent from a premium menu path. All six icons now load and assign to actual buttons.
- Ranged Witch framing, Plasma's stored-energy label, tooltip opacity and dense Bed/Door prestige captions were corrected and affected rendered frames accepted.
- A Witch bolt could remain visually frozen after terminal combat. Immediate transient cleanup now handles death, defeat, transformation and wave cancellation; real engine cleanup checks pass 30/0. There was no post-death damage in the original finding.

## Final acceptance

**IMPLEMENTED:** all requested systems above, reusing the existing project. No known unfinished implementation work or confirmed unresolved product defect remains from this cycle.

**TESTED:** [132 registered command gates accepted](evidence/gameplay-overhaul/final-test-acceptance.json), including the regular/extended preservation suite, corrected affected runs and focused added gates. The original 122-command sweep took 2,565.154 seconds and had 21 failed gates and zero warnings. Runtime fixes occurred during that cycle, so its raw `passed:false` result remains unchanged. [Independent triage](evidence/gameplay-overhaul/final-affected/QA_TRIAGE_SUMMARY.md) explains each failed gate and preserves passing affected logs; no test was disabled. The acceptance is assembled coverage, not a claim of a clean first pass on one immutable revision.

- Baseline: model 133/0, scene 30/0, real render 16/0.
- HUD: developer 115/0; independent rendered 192/0; adversarial input plus affected reset/overlap probes accepted. Actual transitions measured 0.2515–0.2661 seconds.
- Expansion: developer 19,201/0; independent 31,294/0; rendered 3,084/0 across all maps and both resolutions.
- Final core: independent 522/0, Challenge 40/0 with 12 fresh paired engine workers, first-contact 108/0, terminal cleanup 30/0. Paired beginner/progressed traces matched for all six Hunters.
- Focused repairs: branch previews/assets 96/0; camera 30/0; roster menu assets 18/0; bounded tooltip/current preview 2,003/0; first-contact developer 73/0; actual warning audio 36/0.
- [Final rendered/audio review](evidence/gameplay-overhaul/combat-render/REVIEW.md): eight groups, 660/0, 134 current actual PNGs and 13 engine Master recordings totaling 36.5018 seconds with zero clipped samples. The genuine earned-state images use an immutable prior earned checkpoint restored in the newer engine; final post-fix natural progression is documented separately by the balance auditor.
- Final balance: 39 actual simulated scenarios, zero invariant failures, including legitimate Level 10 progression and eventual Hell defeat.
- Windows package: 77 Linux embedded-pack checks and all 17 ZIP-entry CRC checks pass. This is not native Windows execution.

**UNVERIFIED:** native Windows execution/input/soundcard/GPU performance; human beginner usability, art/horror intensity, subjective mix quality and owner/Adie difficulty approval. Challenge reproducibility is scoped to the tested engine/fixed inputs, not arbitrary human timing across platforms. Existing tutorial, music and progression are covered by preservation checks rather than claimed human playtesting.

**INCOMPLETE:** no requested implementation feature is knowingly left unfinished. The native Windows and human verification listed above remains outstanding. Run the [playtest guide](GAMEPLAY_HUNTER_HUD_PLAYTEST_GUIDE.md), especially the demanding Lab/Electric/Hell scenario.

Representative engine output: [six Hunter identities (derived from actual viewports)](evidence/gameplay-overhaul/combat-render/derived-six-hunter-contact.png), [expanded sixteen-slot room](evidence/gameplay-overhaul/expansion-render/abandoned_dorm-slots16-720.png), [prior earned wave-45 state restored in the newer engine](evidence/gameplay-overhaul/combat-render/earned-hell-wave45-sixteen-slots-720.png). [Independent root hash/PCM verification](evidence/gameplay-overhaul/root-final-output-verification.json) checks the final evidence and all runtime files.

## Modified files and scenes

[Full readable changed-file inventory](GAMEPLAY_OVERHAUL_CHANGED_FILES.md) lists source, art, tests, tools and documentation against starting commit 457560d. Key components are `bottom_context_panel.gd`, `interface.gd`, `game.gd`, `room_expansion.gd`, `expansion_interface.gd`, `damage_rules.gd`, `magic_defense.gd`, `arcane_hunter.gd`, `hunter_state.gd`, `match_model.gd`, `building_stats.gd`, `catalog.gd`, `strategy_catalog.gd`, `replay_snapshot.gd`, `challenge_code.gd`, `audio_director.gd`, `gothic_theme.gd` and the presentation/item components. New original assets include 42 Hunter state plates, four affinity icons, three device illustrations, six branch glyphs, three Hunter portraits and the expansion-plan icon. Existing `scenes/main.tscn` is unchanged; its script-driven world and HUD reuse the same scene.

## Final build and Git delivery

Version **0.7.0-overhaul**, Godot **4.6.3**. Final implementation/build-source commit: **9fc87e51daa86a61911405c0c895065da56096d8**. Documentation/evidence-only commits follow without changing the executable's game sources. The final repository tip and verified private `work` push are recorded in the delivery response; main is unchanged and no public release or Phase 6 was started.

- Windows archive: `NightfallDorm-Gameplay-Overhaul-Windows-x64.zip`, 91,555,222 bytes.
- ZIP SHA256: `acd46995706a04182ab21fcf783af2403e7e08ebfda76204b82b26d887b9e420`.
- EXE SHA256: `628766a431655572259a97b8ad85b70124c9855f379dece82d507cf15f66b116`.
- [Build receipt](evidence/gameplay-overhaul/windows-export/windows-artifact.json), [archive integrity](evidence/gameplay-overhaul/windows-export/zip-integrity.json).
- The earlier package built before terminal spell cleanup is retained only as diagnostic evidence under `windows-export-before-terminal-cleanup`; it is superseded by this build.


## Running the project

Open `project.godot` from the `work` branch in Godot 4.6.3 and press F5. Choose Endless
Siege for physical room growth; select a floor pad to open the Build drawer, or
select a building/Bed/Door to inspect upgrades. Close the drawer with its close
control or Escape. Practice offers isolated temporary resources for learning the
expanded roster and defenses. Preserve the existing user profile; tests use
separate profiles. Final commit/push and modified-file inventory follow acceptance.
