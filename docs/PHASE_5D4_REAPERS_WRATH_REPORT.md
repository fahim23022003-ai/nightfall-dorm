# Phase 5D-4 — The Reaper’s Wrath

## Status: final integration in progress

**IMPLEMENTED:** unified contextual HUD; actual specialization comparisons;
validated evolution/kill credit; two-phase Reaper and combined final domain;
bounded attacking undead; six Level1–10 buildings; sampled interactive audio,
listening tabs and save/ruleset integration.

**TESTED:** focused independent runtime, economy, migration, item, deterministic
process and rendered gates listed below. Baseline97 commands passed before edits.

**FAILURES AND FIXES:** real lifecycle, transaction and presentation defects were
found and repaired; affected acceptance and remaining verification are explicit.

**UNVERIFIED:** native Windows execution/input/hardware performance, human
beginner usability, subjective horror, speaker/headphone balance and human
approval. Linux renders and PCM measurements do not establish these.

**INCOMPLETE:** final full regular/extended regression, final rendered/audio
refresh, long-run report, Windows export and final clean-tree/push receipt.
This document is not yet a completion claim.

## Repository and recovery

Started clean on private `work` at
`d507600f64c3c55ff858a9d5bc5d3c938b6e5f6d`, equal to remote. Recovery tag:
`pre-phase5d4-d507600`. Baseline54ef155, sampled sources53eb50a, sound assets2de0ea2,
contextual UI73c7698, rendered evidence8a392f3, audio evidence9db04a0.
Core `0bc84216ed18c805a98c70bb0a296c473473215d` is VERIFIED PUSHED: remote `work`
matched local HEAD. Later fixes are still being validated. Main was not modified;
no public release, multiplayer, Android work or new Phase6 audit was started.

B owns gameplay production; dedicated Audio specialist owns sound design/runtime;
C independently tests mechanics, saves and input; A audits actual strategies;
D captures and inspects rendered Godot and audio; root owns integration,
regressions, reports, export and verified Git delivery.

## Human-facing HUD and building flow

Resources, time/stage/wave, survivors and Hunter danger stay at the top. Items [I]
and teammates [T] collapse; Help [G] is secondary. A fixed bottom action header
opens one contextual panel for all12 machines, structures and branches. The
camera uses the same available gameplay area whether details are open or closed.

Selecting an empty pad shows illustrated BUILD cards with role, price and actual
requirements. BUILD buys directly into that pad. Existing legacy preview APIs
remain compatible; ordinary desktop play no longer requires moving a following
preview over a distant confirmation panel. Existing selections show current/
next effective stats, literal Gold/Electricity price, repair or actual refund.

Branch selection is a free preview. A separate Confirm performs the exclusive
paid choice; Back cancels it. A cloned room plus the same resolver used by real
projectile launches calculates damage, rate, range, production and support
comparisons. The impact-only Reaper/stage modifiers are not applied twice.
New roles also show burn, slowing, target count, paid healing, shield capacity
and lure range/duration. Advantages and drawbacks remain available in tooltips.

## NPC carry: actual finding and intervention

The owner’s feedback was reproduced with earned resources. The baseline51-case
audit includes45 cases across five maps/stages, three difficulties and three
no-offense policies, plus six controls. Bed/door-only upgrades and repairs won
4/5 Hell cases; support/economy without player offense also won4/5. Literally
idle Hell won0/5. NPCs actually earned/spent currency, with observed Bed5/Door5/
machine4 caps; observed team DPS was39–55, not the theoretical412 figure.

A separate latent NPC defect selected a failed critical-health upgrade without
falling back to affordable repair. That fallback is fixed. It was not observed
as the cause of the baseline carry wins. NPC goals remain bounded and their
competence is preserved. No blanket NPC damage nerf or doubled Hunter HP was used.

The new pressure comes from reliable eligible transformations, real boss casts,
multiple-room pressure, capped minions and kill evolution. Paired Hell bed/door
wins fall4/5→2/5; support4/5→3/5; idle remains0/5. The intermediate pre-cutover matrix retained Normal/Long Night bed/door5/5;
those observations are explicitly diagnostic, with final regular regressions
covering preservation. Final-cutover fresh Hell bed/door2/5; six active prepared Hell controls win with
actual player damage1,296–4,546. These small deterministic scenarios are strategy
evidence, not a human win-rate estimate or arbitrary balance target.

## Hunter tactics and fifteen evolution buffs

Existing Crusher charge/pressure, Stalker concealment/feint and Ravager dash/
combo remain real telegraphed behaviors. Target scoring retains path cost,
weakness, defense pressure, commitment and bounded history variation. Reaper
casts do not stack normal archetype wind-ups on top of boss attacks.

A genuine living Hunter or undead must reach the correct exposed player/bed
through valid combat state. One canonical victim-owner ledger gates each award;
fake presentation events, repeat calls and stale actor IDs cannot farm it.
The seeded pool contains distinct effects, without duplicate buff selections.
The current six-survivor map caps awards at6;15 is the variety pool. Ineligible
Commander/Shadow Step selections are filtered when their role cannot apply.

| Buff | Actual effect |
| --- | --- |
| Blood Frenzy | Attacks recover 10% faster. |
| Iron Skin | Incoming damage reduced by 10%. |
| Predator Rush | Movement speed increased by 12%. |
| Door Crusher | Door strikes deal 15% more damage. |
| Soul Hunger | Recover 4% maximum HP on this and future genuine kills, capped at current maximum. |
| Rapid Recovery | Archetype and Reaper ability cooldowns recover 12% faster. |
| Shadow Step | Approach conceals the Hunter for 1.5s every 12s. |
| Ruthless Pursuit | After 8s of pursuit, move 10% faster until contact. |
| Cursed Armor | After each kill gain a finite 5% maximum-HP shield for 8s. |
| Savage Strike | Telegraphed special attacks deal 12% more damage. |
| Dread Aura | The currently besieged room produces 12% less income and power. |
| Undead Commander | Reaper undead gain 15% HP and damage; dormant until transformation. |
| Soul Drain | Every 20s of door contact drains at most 8 Gold and 2 Electricity. |
| Relentless Siege | After 8s at a door, attacks recover a further 8% faster. |
| Death's Momentum | For 8s after a genuine kill gain 15% movement and 10% attack recovery. |

Death and evolution audio serialize in a six-room bounded queue. Evolution
announcements also queue, showing the actual buff and effect; the acquired
count and tooltip remain inspectable. New independent runs reset the ledger.
Endless saves restore dead survivors and kill credit atomically; a mid-wave
rewind restores both, without separately banking a repeated kill reward.

## Reaper eligibility and phases

The baseline did show transformations in eligible ordinary cases. Normal starts
at campaign stage3; Long Night/Hell at stage2. These restrictions remain and are
explained in UI. An explicitly funded high-NPC stress case killed an eligible
Hunter at69.6s before the old80-active-second opening, so successful stage logic
alone did not ensure players saw the boss. Eligible HP transitions now open at
8active seconds, at55% HP; the210-second campaign deadline remains. Challenge
uses its documented shorter deadline; existing Endless milestones remain.

The same Hunter transforms for2.4s with no HP grant. At35% HP it awakens PhaseII;
at10% the final combined ultimate triggers once. Finite threshold guards prevent
one massive hit skipping the encounter: PhaseII1.2s, final3.3s. They never raise HP,
repeat or prevent a legitimate final kill. Old Scythe Strike, Soul Siege and
Shadow Surge remain contact fallback attacks and retain their counterplay.

| New ability | Mechanics and safeguards |
| --- | --- |
| Spawn Undead | 1.5s warning, up to3 actual minions,24s cooldown. |
| Ten-undead Assault | 2.6s warning, fills up to10 active slots,60s cooldown. |
| Soul Steal | 3s channel; drains at most18 current Gold/5 Electricity;32s cooldown. |
| Scythe Slash | 1.8s warning at actual door contact,25% max-door HP before mitigation,18s cooldown. |
| Rules Judgement | 2s warning;5s turret/manual-item lock;36s cooldown. Automatic rescues remain valid. |
| Enhanced Undead | PhaseII summons up to4 stronger agents;30s cooldown. Existing undead strengthen without HP refill on awakening. |
| Soul Reaper | 3.5s channel; exactly50% of current fractional Gold/Electricity at completion;65s cooldown. |
| Phantom Scream | 2.2s spectral warning;8% max-door HP capped180 to each valid living occupied door;34s cooldown. Explicit victim mitigation applies. |
| Final Judgement | 2.5s warning;6s production pause,48s cooldown. Stored resources remain and missed income is not banked. |
| Eternal Sacrifices / Crimson Execution | One integrated final10% event, described below. No unrelated random second ultimate. |

Only one new cast is pending at a time, followed by5.5s recovery. Resource
channels interrupt on actual HP damage of2% maximum, displacement55px, applicable
Time Freeze or Reaper Seal. Seal prevents new casts during its recovery. Rules
and Final Judgement cannot overlap. Victim-specific Guardian/Feather/Barricade/
Shield logic does not temporarily redirect the Hunter to calculate mitigation.

## Real undead and final domain

There are at most10 real attacking minions. Main Hunter ID1 is distinct from
monotonic minion IDs≥2; stale projectiles cannot retarget a reused slot. Ten
bounded route keys are removed on death, expiry, wave transition and domain.
Minions navigate to valid doors, damage them, enter breached rooms and can
legitimately kill NPCs or the player. All offensive machines can damage them.
Normal agents have120HP/11damage/55speed; enhanced190/17/66, before Commander.
They expire after55s. Original walk, strike, recoil and death poses distinguish
them from decorative creatures. Main-Hunter/minion damage is counted separately.

At10%, one seeded valid living intact room—human or AI—is selected. A3s warning
precedes a0.8s giant-scythe flight; the embedded scythe creates the roughly30s
Crimson Domain. The Hunter uses legal navigation to that room, without teleport,
then applies aggressive but bounded contact attacks and Scythe Slash. Existing
minions clear, foreign projectiles cancel and other rooms’ offense cannot damage
the domain boss. Foreign Inferno/trap/offensive-item routes also respect isolation.

The scythe pulses every3s for3.5% max-door HP, capped120 before mitigation. It can
make at most3 building-destruction attempts,12% each; Level10 is eligible. An
active paid barrier, Emergency Shield, Guardian Shield or Seal wards destruction,
checked before the pulse consumes capacity. Applicable Seal removes the scythe.
Destroyed machines are not sold and grant no refund. Timeout, boss death or
victim death cleans up scythe, locks, casts and domain music. This is a possible
victory/defeat encounter, not a scripted execution or mandatory30s survival.

## Six buildings, costs and real specializations

All12 placeable machines use the existing purchase/coupon/upgrade ledger. Bed
and Door remain their existing unsellable structural systems:14 permanent systems
total. New machine purchases and upgrades cap at10 and require the existing bed/
door prestige prerequisites. Branches are exclusive at the paid Level5 upgrade.

| New machine | Purchase Gold/Electricity | Undiscounted total investment through10 with branch | Branch choices |
| --- | ---: | ---: | --- |
| Flame Turret | 75 /10 | 6550 /1132 | Searing Lance: stronger single-target burn/hit; Wildfire Fan: weaker hits/burn across up to3. |
| Frost Tower | 80 /12 | 6985 /1306 | Deep Chill: stronger one-target slowing/hit; Rime Field: weaker control/hit across up to3. |
| Shock Trap | 65 /10 | 5680 /1132 | Capacitor Burst:50% stronger with25% longer base recharge; Rapid Discharge:35% weaker, one-third shorter recharge. |
| Auto Repair Station | 85 /12 | 7420 /1306 | Efficient Mending:30% less operating Gold; Emergency Protocol:80% larger burst below45% HP, slower and more expensive. |
| Shield Generator | 100 /18 | 8725 /1828 | Aegis Burst: larger2s barrier at higher cost; Steady Veil: smaller4s barrier at lower cost. |
| Decoy Beacon | 70 /10 | 6115 /1132 | Force Lure: short, greater range; Faint Echo: longer, shorter range. |

Upgrade multipliers from current levels1–9 are1,2,3,5,7,10,14,19,25. Each upgrade
costs purchaseGold×factor and (purchaseElectricity+3)×factor. The branch fee is
25Gold/4Electricity. Actual eligible investment records discounts, and a sale
returns exactly half of each separate recorded balance. Operating costs never
inflate refundable investment. No Level11, dual branch or duplicate refund.

Flame’s strongest per-target burn and Inferno do not add unlimited overlapping
DoT. Frost/Shock slow movement/attacks without freezing or stunning permanently;
Reaper resistance applies. Auto Repair pays real Gold/Electricity per burst;
its minimum65% siege effectiveness gives a late-pressure niche. Shield has finite
capacity/duration and a shared12s room refractory. Decoy gains bounded duration/
range through10, with shorter but finite cooldown and reduced boss duration.
Shared repair/shield/lure refractory and exact machine identity survive the
relevant transactions/checkpoints, preventing sale/rebuild cooldown exploits.

Original six machine silhouettes and twelve branch glyphs are reproducible via
`tools/generate_wrath_art.py`. The inspector exposes their actual role statistics.

## Audio and sources

The seven prior recorded-instrument score WAVs remain byte-identical to d507600.
A separate48s/120BPM Crimson score has394 arranged note events using the existing
credited CC0 VSCO2 instruments. Music crossfades reuse permanent players.

Sampled gunfire, electrical/fire/ice impacts, building interactions, Hunter
abilities/evolution, zombies and all major boss warnings use documented recorded
source layers. Source authors, URLs, pinned mirror declarations, CC0 text and
hashes are retained under `tools/audio/source/wrath_sfx/`; derivative recipes and
hashes are in `assets/audio/wrath-sfx-derivatives.json`. Original Freesound pages
returned403, so direct-origin confirmation is UNVERIFIED. No claim is made that
this project recorded those performers. Full credits: [audio sources](AUDIO_SOURCES.md).

The204-stream runtime uses12 persistent loops (eight scores/four ambience),16
pooled effect voices,24 pending critical slots and six serialized room reactions.
Category gains, distance attenuation, critical priority, ducking and variation
bound dense playback. Stop, scene exit and new-run resets clear relevant queues.
Music/Voices/Action SFX tabs expose actual listening previews. New imports use
PCM16 consistently, avoiding ambiguous raw compressed-data inspection.

The early actual Needle/Arc/action gate76/0 records18PCM files with nonzero
Music-muted Master output and no full-scale samples. Final new-building/boss/
evolution/dense-mix captures are pending; asset existence is not playback proof.
Thirty recorded/designed CC0-declared sources produce122 recipes (27 replacements
and95 new effects),116 distinct output hashes. The recorded debris explosion
passes an actual Practice trap→legal Hunter approach→detonation capture:9/0,
13.746s Master PCM, RMS0.005275/peak0.052094, no clipped samples. Menu/result
lifecycle13/0 ensures battle cues stop while terminal death/evolution and valid
listening previews retain their intended behavior.

## Save, modes and deterministic comparison

Old ruleset1/2 checkpoints migrate without changing earned wallets, investments,
branches, stock or records. Ruleset3 requires a bounded evolution ledger and
supports new machine cooldown limits/shared refractory. No mid-wave minion,
scythe or camera state is written into a between-wave checkpoint. Practice
consumes no permanent stock or rewards. Existing shop, ranks, achievements,
pity, cosmetics, campaign and20-item transactions retain their architecture.

New Challenge Codes use ruleset3. Old1/2 results remain archived; old codes are
explicitly incompatible for new play. Six fresh actual engine processes compared
beginner and progressed profiles on three Hell maps: complete traces were
byte-identical with the same legal input policy. Two scenarios reached real
Reaper/ten-undead/evolution events; the third died before the boss. This verifies
intended conditions and fixed-step simulation in Godot4.6.3 Linux, not identical
human timing across operating systems or a verified online leaderboard.

## Evidence and remaining acceptance

| Gate | Current evidence |
| --- | --- |
| Unmodified baseline | 97/97 commands,1456.456s, no errors/assertion failures/warnings; original sources/evidence hash-preserved. |
| Early UI | Initial C698/0, final all12/held input818/0 and minion/Home76/0; D301+209/0,118 current PNGs; fixed camera allfive maps. |
| New building UI | C1625/0 across60 branch/map scenarios; D555/0 and74 PNGs,720p/1080p. |
| Evolution | C648/0, seeded genuine kills/all15 mechanics/caps/stale actors/routes. |
| Boss | C153/0 plus2580/0 real multishot/phase/navigation checks, actual damage/half-drain/item counters/domain/allmap cleanup. |
| New economy/defenses | C972/0 including discounts, exclusive branches, Level10/refunds/actual paid effects and Decoy lifecycle. |
| Save migration | C264/0, three frozen old profiles, atomic death/credit, full cooldown/ledger restore. |
| Existing20 items | C208/0 with new weapons, blocked-stock safety, automatic items and Practice isolation. |
| Challenge | C13/0 with six fresh process traces. |
| Audio | Specialist782/0, pooled-reaction5/0, target-routing209/0, lifecycle13/0, real explosion9/0; legacy491/0, listening256/0, visual/audio103/0. |
| Actual strategy | Final A49 cases/0 integrity errors,7 fresh checkpoint comparisons (intermediate69 cases retained as diagnostics); earned new-building and long-Endless evidence below. |
| Full final regression | IN PROGRESS; baseline success is not reused as final success. |
| Final rendered/audio/stress | IN PROGRESS; initial boss visibility issues require fresh affected frames. |
| Windows x64 export | Pending final committed sources; native Windows remains UNVERIFIED. |

Final-source earned Normal cleared20waves and allsix new roles reached10 bywave12.
Corrected Hell reached allsix10 bywave12 and continued until legitimate defeat44
(after43clears,6425.4s simulated). Its paid Auto Repair restored58,435.443HP over
401activations, Shield absorbed26,587.704HP over186activations, and Decoy activated60
times. Normal did not meet its repair threshold, so it is not natural-healing proof.
A separate Arc-heavy Hell fortress cleared73 and died on74 at2637.4s simulated.
Both started with finite stock, exhausted it and used actual earned resources.

Final49-case audit includes29 Hell cases,3 earned Endless policies and17 controlled
actual-handler repair comparisons. Seven fresh checkpoint comparisons pass. Completed-
wave engine objects stay1520; sampled static memory26.15–26.57MB (fortress) and
26.16–26.47MB (all-six). Projectiles/combat/presentation buffers are bounded; settled
profiles2698/2666bytes. These are accelerated Linux model measurements, not Windows
FPS. Earlier74/75 and52/53 outcomes are retained only under pre-cutover diagnostics.
See [final balance evidence](evidence/phase5d4/balance-final-summary.md).
Final rendered stress and real mixed PCM evidence remain pending.

## Failures and fixes retained in evidence

- Real branch text/close/control overlap; missing current level/branch; stale help.
- Same-pad Decoy sale/rebuild rebound; finite instance-aware cancellation added.
- Wrong main-Hunter/minion audio target dispatch; corrected IDs1 versus≥2.
- Pooled voice cutting death screams and overlapping encounter cues; serialized
  reactions and stream-identity guards added, with frozen-old-code reproduction.
- Bed/door upgrade waveform alias; differentiated recorded designs.
- New compressed imports mismatched old PCM inspection; consistent PCM16 import.
- Boss warning/awakening occlusion and domain camera headroom; affected rendering
  is being refreshed. Evolution reset and held-press/Escape fixes now pass their affected checks;
  final camera headroom is receiving an additional rendered check.
- Old regression fixtures assumed six legacy slots, obsolete future-ruleset3,
  instant unguarded boss death and illegal remote damage. Fixtures are ported to
  current rules while retaining transaction, final-death and no-refill assertions.
  Root’s invalid map-ID and duplicate local-variable test-edit errors were caught,
  corrected and retained as fixture failures, not product defects.

## Final delivery receipt

Final commit, clean-tree status, verified remote equality, Windows archive hashes
and final regression/render/audio receipts will replace this section when all
remaining gates complete. No final delivery or human approval is claimed yet.
