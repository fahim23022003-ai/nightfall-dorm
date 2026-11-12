# Phase 4B — Grim Reaper transformation

## IMPLEMENTED

Continued the clean existing `work` checkout at `efb81cdb62c58bf11e612e112a5be34da74f4669`.
Recovery tag `pre-phase4b-efb81cd`; architecture checkpoint `517d67e`, original
presentation/audio checkpoint `341c5dd`. No rebuild, new maps, new ranks, Android
work, or replacement save system. Main agent B owns production code. Agent A
reviewed gameplay design, C independently tested rules and balance, D reviews
actual rendering and audio. These are genuine bounded specialist tasks.

### Encounter rules and health

`BossCatalog` holds encounter and ability data. Normal stages 1–2 and Long
Night/Hell stage 1 remain introductory encounters without a transformation.
Normal stages 3–5 enable it after 90 active seconds; Long Night/Hell stages 2–5
after 80 active seconds. At that point HP must be at most 55% of current maximum.
A 210-active-second deadline triggers it regardless of HP. Preparation time is
excluded. Stage preparation explicitly displays the applicable rule. Legacy
standalone encounters retain the original Hunter. Configuration is independent
of map geometry; forced encounter fixtures test the first map too.

The existing Hunter object enters appended `TRANSFORM` state for 2.4 seconds,
marks its once-only flag immediately, stops attacking/moving and remains
vulnerable to projectiles. Current and maximum HP are carried through **without
healing or an additional HP multiplier**. Existing timed threat growth remains
separate; it pauses during the sequence and catches up on the next active tick.
The transformation itself never grants that growth. It is deferred while
breaching/exiting a room. On completion, target selection and physical routes are
revalidated. Death cancels the sequence; a new match creates a fresh Hunter.

Targetless global transformation/death events work independently of room events.
Exposed-player pursuit cannot overwrite the transformation state or eliminate a
player by stationary contact during its warning. The same entity identity is
used by turrets and projectiles throughout. Results use existing stage, XP,
loadout, deduplication, and save paths; there is no new permanent reward grant.

### Attacks, AI and counterplay

Boss abilities **replace** the Phase 4A charged pattern, rather than stacking on
it. Existing difficulty growth, movement, doors, economy and repair pressure are
preserved. No turret damage, purchase-price or income nerfs were introduced.

| Ability | Warning | Effect | Cooldown after execution | Recovery |
| --- | --- | --- | --- | --- |
| Scythe Strike | 1.0 s | 1.15 × current Hunter damage to an intact target door | 3 s | 0.85 × current interval |
| Soul Siege | 1.8 s | 1.6 × current Hunter damage to an intact target door | 14 s | 1.25 × current interval |
| Shadow Surge | 1.5 s | Suppresses that room's new turret/heavy launches for 2.5 s | 20 s | 1.1 × current interval |

Cooldown is reserved when a warning begins and refreshed on execution;
interruption cannot spam a fresh special. Recovery also uses the encounter's
Normal 1.05 / Long Night 1.0 / Hell 1.1 factor. Damage happens only after the
warning, at the real door approach, with the original target still valid.
Retargeting, displacement, opening/breaking the door, death and terminal results
cancel pending attacks. A short interruption recovery prevents immediate hits.
Actual HP loss feeds the existing damage-number, crack, shake and break events.
Survivors still require physical breach after the door breaks.

The Reaper evaluates route cost and nearby defensive threat even on Normal,
reduces excessive door-HP aversion, and chooses Surge only against at least two
in-range turrets behind a sufficiently healthy door. Siege also requires a
healthy door; Scythe handles other situations. Reassessment waits until a warning
resolves. Existing collision-safe navigation and stall recovery remain in use.

Surge does not stop income, building, selling, upgrades, repairs, existing
projectiles or neighboring-room defenses. During its 2.5 seconds the Reaper takes
20% extra projectile damage. Repair through the silence, invest in door HP or
repair facilities before siege, maintain neighboring coverage, and exploit its
warning/recovery windows. Suppression clears on departure, death and result;
it pauses with the match. HUD shows remaining silence and the exposed boss.

### Original presentation and sound

Four authored vector cloak frames show an angular black hood, skeletal face,
red eyes, silver clasp/chain, folded mantle, sleeves, hands and torn hems. An
independently articulated scythe winds up and sweeps through an impact arc.
Cloth breathing, floating motion, curling shadow particles, transformation rings,
attack charge arcs, turret silence markers, hurt flash and dissipating death
particles run in the existing presentation layer. This is lightweight procedural
2D animation with local SVG textures, not a recolored Hunter or cinematic rig.
Sources: `tools/art/generate_reaper.py`, `assets/boss/`, `boss_presentation.gd`.

A prominent awakening banner, persistent Reaper HP bar, per-attack countdown,
own-door repair/silence warning and teammate notifications reuse existing UI.
The result screen identifies a defeated Reaper while retaining campaign actions.

Nine newly authored synthesized WAVs provide transformation, movement/presence
ambience, scythe, charge, surge, impact, hurt, death and a separate 12-second
Reaper score. Source: `tools/audio/generate_boss_audio.py`, standard-library only,
no samples/downloads. Existing 46 audio waveforms remain unchanged. All 55 assets
use real decoded PCM and actual AudioStreamPlayers. Four permanent music stems
crossfade without restarting each frame; boss music and ambience fade out on
results. Obsolete warning voices/queued cues are cleared at a terminal result.
Existing saved volume/mute settings, bounded voice pools, per-event cooldowns,
distance attenuation and conservative mix headroom apply to the new assets.

## TESTED

Focused architecture: 25 checks passed. Independent Agent C rules/navigation/
progression suite: 6,699 checks passed. General audio: 181 checks passed, all
55 streams decoded, four permanent music starts. Dedicated boss audio checks
verify transition, attack, impact/hurt/death cues, pause, terminal fade and retry.

The final matched 60-run comparison uses seed11, 0.1-second ticks, normal starting
resources, balanced and proactive economy policies, five maps and three modes.
One arm disables encounters; the other uses actual campaign defaults. No injected
resources or boss HP edits are used. Introductory stages intentionally remain
nonboss in both arms.

| Mode | Boss disabled | Boss enabled | Actual transformations / boss victories |
| --- | --- | --- | --- |
| Normal | 10W / 0L | 10W / 0L | 6 / 6 |
| Long Night | 6W / 4L | 8W / 2L | 6 / 6 |
| Hell | 1W / 9L | 2W / 8L | 1 / 1 |

All three abilities actually executed in these encounters. The boss's warnings,
recovery, vulnerable transformation and zero extra HP **reduce sustained late
pressure** compared with the existing advanced Hunter. That is intentional
headroom for recognizable mechanics in already severe Hell, not proof of a
harder numerical damage race. These policies do not establish human challenge.
Normal's mean total match time changed177.3→183.3s; Long Night178.3→168.2s;
Hell135.1→135.0s. No balance change was made merely to hit a win-rate target.

Additional final Hell room probes: 30 matches,14W/16L,14transformations and12
boss victories, zero resource/navigation/duplicate/unresolved failures. Earned-
resource Reaper victories occurred in Hospital rooms1/2/6, Hotel1/3/4/5/6,
Laboratory1/2 and Mansion1/2. Two other wins were introductory stage1. This
establishes a tested winning strategy on every eligible boss map, not every
possible room, seed or strategy.

The existing90-policy matrix now gives Normal29W/1L, LongNight18W/12L,
Hell3W/27L, zero failures. Phase4A was29/1,14/16,1/29 respectively. Thus Normal
outcomes stayed stable in these samples and advanced modes gained some victories;
Hell is still severe. These are simulations, never estimates of player win rates.

Confirmed issues fixed during review: equal-valued turret dictionaries resolving
to the wrong pad in range assessment; new WAV imports initially using Godot's
compressed format instead of the existing PCM policy; and an overly long Surge
notification. Focused reruns preserve the failed evidence and verify corrections.
Independent design review also prompted robust targetless events and preservation
of transformation during exposed-player pursuit.

Regular and extended suites completed in resumed batches. The initial wrapper
passed all suites through the12-match legacy simulation, then the unchanged
idle-Hunter regression exposed an unintended0.5-second recovery on ordinary
cancellation. Recovery now applies only when a real boss warning is interrupted.
The final continuation reran model126, architecture25, boss audio42, difficulty
behavior268 and audit72 checks before completing the remaining suites. Agent C
then reran its expanded6,699-check suite against the final edge fixes. Large
matched matrices were not repeated for these narrowly isolated interruption
fixes: their legal policies sleep before transformation and do not displace a
sieging Hunter. No assertions were removed or relaxed.

Retained regression evidence: map core15,348 / integration5,107 / UI922 checks;
144 map matches79W/65L; campaign85profile +54flow checks and20matches9W/11L;
Phase1 purchasing/double-click/cancel/refund314+421checks; horror319+21+5;
rank/save348; audio181; prior controls, projectiles, scenes, furniture and3,209
UI-availability checks. Legacy12matches9W/3L. Extended20,000transactions with
175,941invariants,27timestep matches,144room/strategy matches and48rank/perk
matches22W/26L all passed. Separate-process profile write/read and main startup
passed. Logs: `regression-prefix.log`, `regression-extended.log`, `qa-edges-final.log`.

Actual Linux Godot/Mesa presentation:63checks passed and22rendered PNGs inspected,
including transformation, all three attacks, hurt/death, results/retry, five maps
and960×540. Agent D independently inspected them; the coordinator additionally
viewed transformation, Siege impact, small-window Surge and lab-side-door frames.
The repaired Surge notice measures322/370available pixels; longest HUD warning
433/476. Dedicated boss audio42checks passed. An actual31.67-second engine master-
bus recording is non-silent, peak3129/32767 with zero clipped samples. This proves
functional mixing, not human listening or native Windows playback. Four permanent
music starts,55decoded streams, no missing assets, correct fades and one death
cue were verified. See `docs/evidence/boss/README.md` for provenance and limitations.

Final review additionally fixed sleeping elsewhere interrupting transformation
(exit is now deferred until the animation finishes) and Surge vulnerability
outliving suppression after displacement. Added regressions cover both and the
ordinary idle delay. No known unresolved failures remain in tested paths.
Project settings and Windows export presets are unchanged from `efb81cd`.

## UNVERIFIED

Native Windows import, launch, exports, FPS, keyboard/mouse feel and speaker
balance require the Windows checklist below. Linux Godot 4.6.3 is the available
engine; Linux rendering or waveform capture is not Windows certification.
Human fear, musical quality, comfort and difficulty are subjective and have not
been validated with players. Simulations are diagnostic policies, never human
win rates or a claim every room/strategy is winnable.

## INCOMPLETE / scope limits

No requested production feature remains incomplete. Native Windows manual checks
remain unverified as stated above; they cannot be certified by the Linux runtime. No Mythic rank, Android,
additional map or Phase 5 work belongs to this change. Artwork is coherent
layered vector animation rather than a high-frame-count hand-painted sprite rig.

## Windows manual checklist

1. Download the GitHub **work** branch ZIP at the final reported SHA, extract,
   and import `project.godot` in Godot 4.6.3. Check the debugger for script/import
   errors; launch the main scene. No new executable was exported in cloud.
2. Confirm existing profile, unlocked stages, ranks, equipped perk and audio
   settings remain intact. Stage 1 should remain the introductory Hunter;
   use unlocked stage 3+ Normal or stage 2+ Long Night/Hell for Reaper encounters.
3. Walk/occupy with WASD/E, click a build pad, double-click a purchase option,
   move to Confirm/Cancel, cancel/retry, upgrade, sell and rebuild. Check separate
   gold/electricity refunds and verify the preview stays anchored.
4. Reach an eligible encounter naturally. Check the preparation rule, one
   awakening banner, visible hood/scythe/smoke, unchanged transformation HP and
   continuous music transition. Turrets should keep hurting it during awakening.
5. Watch Scythe and Soul Siege countdowns before real door damage; repair/upgrade
   during warnings. Surge should silence only the targeted room for 2.5 seconds;
   repairs, income, placement and neighboring projectiles must still function.
6. Check all five map layouts, including side-facing lab doors and large mansion
   rooms, focused and full-map cameras, 1280×720 and smaller windows. Listen for
   offscreen teammate warnings, proximity and restrained overlapping effects.
7. Defeat the boss, confirm one result/XP settlement, retry and change loadout.
   Also lose during a special warning, retry, pause/resume, mute/unmute and return
   to menu. No pending strike, silence, boss music or transformation should leak
   into the next match. Report any PC-specific failure with stage/mode and steps.

## GitHub backup

Private `work` push and exact remote SHA verification are performed after final
validation. Final response records the actual latest commit and push outcome.
