# Phase 5D-4 — The Reaper’s Wrath

## Status: implemented, tested and ready for the Windows human playtest

**IMPLEMENTED:** unified contextual HUD; actual specialization comparisons;
validated evolution/kill credit; two-phase Reaper and combined final domain;
bounded attacking undead; six Level1–10 buildings; sampled interactive audio,
listening tabs and save/ruleset integration.

**TESTED:** all115 registered regular/extended command gates after affected
reruns; independent gameplay/balance/audio QA; actual rendered interaction,
600-second stress, engine PCM, and Windows export/embedded-pack validation.
Baseline97 commands passed before edits. No confirmed functional failure remains
from this test cycle.

**FAILURES AND FIXES:** real lifecycle, transaction and presentation defects were
found and repaired; raw failed runs and corrected acceptance are retained.

**UNVERIFIED:** native Windows execution/input/hardware performance, human
beginner usability, subjective horror, speaker/headphone balance and human
approval. Linux renders and PCM measurements do not establish these.

**INCOMPLETE:** no known implementation work remains within Phase5D-4.
Native Windows and human acceptance are explicitly UNVERIFIED above; they are
not inferred from automated success. Phase6 has not begun.

## Repository and recovery

Started clean on private `work` at
`d507600f64c3c55ff858a9d5bc5d3c938b6e5f6d`, equal to remote. Recovery tag:
`pre-phase5d4-d507600`. Baseline54ef155, sampled sources53eb50a, sound assets2de0ea2,
contextual UI73c7698, rendered evidence8a392f3, audio evidence9db04a0.
Final verified implementation checkpoint `a4dc1d0e5094825abc3b78b13879c50598f4c047`
is VERIFIED PUSHED: remote `work` matched local HEAD. All115 registered regression
gates are accepted after fixes; final rendered stress and export also pass. Main was not modified;
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
casts do not stack normal archetype wind-ups on top of boss attacks. Baseline
telemetry already recorded target changes, so this was not treated as a proven
universal stale-target bug. Threat evaluation now recognizes every new offensive
machine, existing commitment/history logic remains, and reassessment cannot
abandon a pending boss cast or the committed domain room. Ability names, actual
wind-up countdowns and target rooms are visible, backed by distinct warning SFX.
The main new strategic variation comes from bounded evolution, legitimate decoy
influence and the actual Reaper phase/ability progression.

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
Hunter movement reduction caps at15%, separately from attack-interval increases.
Deep Chill adds30% attack interval (Reaper15%), while movement reduction is15%
(Reaper7.5%); undead movement reduction is30%. Rime uses16% interval/undead
movement (Reaper8% interval), with the same15%/7.5% movement cap. The inspector
and branches expose these differences. Auto Repair pays real Gold/Electricity per burst;
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
Music-muted Master output and no full-scale samples. Final actual weapon capture
passes38 checks, three genuine kill/evolution playback10, boss playback37 and
legal door-breach→resident death→evolution→laughter9. These cover actual dispatched
streams and recorded engine output. The18 final Master PCM recordings total132.725s
with zero clipped samples; this proves digital playback, not human sound approval.
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
| Full final regression | PASS: all115 registered regular/extended command gates covered. Initial112-command sweep2131.205s,15 failing gates corrected and rerun,0 warnings. Original first-pass failures retained. Independent delta302/0, Frost30/0 and HP display6/0 are included. |
| Final rendered/audio/stress | PASS: final feedback99/0, NPC domain19/0, own PhaseII9/0, earned141/0 plus45/0 HP refresh, five-map teammate293/0 and final dense764/0. Actual PCM verified. |
| Windows x64 export | PASS: Godot4.6.3 Windows x64 executable/embedded PCK,20 Linux embedded-pack checks,17 ZIP entries CRC/source/hash verified. Native Windows UNVERIFIED. |

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
The final dense rendered fixture passes764 checks over600.4 simulated seconds
(115.766s accelerated wall time on final committed sources). It deliberately prepares72 paid Level10 machines,
30 weapons and very large temporary budgets/HP, and suppresses random new boss
casts to isolate rendering/object/audio endurance. It is not earned progression
or a full unconstrained boss difficulty test. Real assault spawning reaches the
10-minion cap. Eight-second real-time max-volume captures before/after show
Master RMS0.031064/0.034584, peak0.186310/0.170532, zero clipped samples.
All five weapon families actually dispatch. Nodes165/resources249 stay constant;
static memory starts100.675MB, peaks101.302MB and ends101.264MB.
Projectile/event/visual/route buffers remain bounded.
Mean frame intervals61.280/54.484ms and p95 80.026/63.671ms describe Linux software-Mesa
synthetic stress only; they do not predict native Windows hardware performance.
An initial endurance fixture legitimately died from percentage-based Scythe Slash;
a second reached its wall-time limit before600s. Both diagnostics are retained,
with fixture controls and the final successful run disclosed.

## Reviewable rendered and audio evidence

These are real Godot Linux frames, not mockups. The specialist inspected both
1280×720 and1920×1080; root also inspected the selected full-size frames below.
Prepared Practice/boss fixtures prove interactions and visibility, while the
separate earned profiles establish natural progression. Human usability and
horror intensity remain unverified.

| Feature | Evidence |
| --- | --- |
| Before HUD | [Baseline gameplay](evidence/phase5d4/baseline/render/01-gameplay-hud-720.png) |
| Twelve-card purchase panel | [Actual palette](evidence/phase5d4/core-render/new-twelve-card-palette-720.png) |
| Actual Frost stats and complete price | [Current/next inspector](evidence/phase5d4/core-render/final-frost-current-next-720.png) |
| Exclusive specialization | [Truthful branch comparison](evidence/phase5d4/core-render/final-frost-truthful-branches-720.png) |
| Burn and bottom-door clearance | [Final focused room](evidence/phase5d4/core-render/final-bottom-door-burn-720.png) |
| Evolution | [Queued announcement](evidence/phase5d4/core-render/evolution-first-banner-720.png) |
| PhaseII silhouette | [Own-room Reaper](evidence/phase5d4/core-render/final-own-reaper-phase2-720.png) |
| Ten undead | [Actual spawned assault](evidence/phase5d4/core-render/ten-undead-spread-720.png) |
| Phantom Scream | [Multi-room attack](evidence/phase5d4/core-render/phantom_scream-active-720.png) |
| NPC Crimson encounter | [Legal arrival, warning and Home control](evidence/phase5d4/core-render/final-npc-crimson-arrival-720.png) |
| Actual death/evolution/laughter | [Captured engine PCM](evidence/phase5d4/core-audio-real-breach-death-evolve-laugh.wav) |
| Crimson musical transition | [Captured engine PCM](evidence/phase5d4/core-audio-crimson-real-threshold-transition.wav) |

## Failures and fixes retained in evidence

- Real branch text/close/control overlap; missing current level/branch; stale help.
- Same-pad Decoy sale/rebuild rebound; finite instance-aware cancellation added.
- Wrong main-Hunter/minion audio target dispatch; corrected IDs1 versus≥2.
- Pooled voice cutting death screams and overlapping encounter cues; serialized
  reactions and stream-identity guards added, with frozen-old-code reproduction.
- Bed/door upgrade waveform alias; differentiated recorded designs.
- Frost text overstated main-Hunter movement control. Actual actor-specific
  movement and attack-interval values now appear separately;30 focused engine
  checks verify real paid Frost projectiles/status application without changing
  the balanced physics. Active burn, Decoy duration and actual automatic repairs
  also receive bounded read-only visual feedback, including Reduced Effects.
- New compressed imports mismatched old PCM inspection; consistent PCM16 import.
- Boss warning/awakening occlusion and domain camera headroom; affected rendering
  passes fresh affected screenshots. Evolution reset and held-press/Escape fixes
  pass their affected checks; final head/foot clearance and full price text are
  visible at both target resolutions.
- Challenge preview used a literal unescaped percent sign in a formatted string,
  producing an engine error despite a zero suite exit code. Escaped it and added
  assertions for the actual generated and rendered preview; affected1541/0.
- Actual exposed contact before claiming a room omitted the elimination count,
  preventing legitimate Endless settlement. Count that actual death once without
  fabricating a room owner or evolution credit; affected transaction suite284/0.
- The old map UI fixture ignored a rejected late map configuration and therefore
  silently exercised Legacy instead of its named maps. It now enters actual stages,
  asserts map identity and covers all30 authored rooms plus6 explicit Legacy rooms.
  This exposed a real desktop Legacy framing regression: lower pads overlapped the
  new bottom panel. Legacy focused desktop framing now uses the same safe area;
  full-map and mobile behavior are preserved. Existing touch cards again use
  their retained confirmation/Back flow; desktop cards keep direct BUILD.
  Opening an owned room from overview refocuses once, while ordinary focused
  menu changes leave the camera fixed. The original mobile58/0, desktop818/0,
  overview269/0 and actual map1108/0 checks pass.
- Old regression fixtures assumed six legacy slots, obsolete future-ruleset3,
  instant unguarded boss death and illegal remote damage. Fixtures are ported to
  current rules while retaining transaction, final-death and no-refill assertions.
  The controlled high-wave legacy damage test now explicitly holds new Wrath
  auto-casts for30s to isolate its original damage formula: Charged1539 and Soul
  Siege1155.6 remain below the1620HP fixture door. Mixed real gameplay remains
  tested separately:60 boss-matrix games recorded36 Scythe impacts,17 Soul Siege
  impacts and7 Shadow Surges alongside62 new ability activations. No combat
  parameter was changed to satisfy the old isolated test.
  Full-size review also caught clipped price text, a burn badge behind the action
  bar and a one-point current/max-HP display discrepancy caused by truncating
  floating values. Measured glyph fitting, fixed head/foot clearance and consistent
  display-only rounding fix these without changing resource/HP calculations.
  Root’s invalid map-ID and duplicate local-variable test-edit errors were caught,
  corrected and retained as fixture failures, not product defects.

## Remaining limitations

No confirmed functional bug remains from this cycle. Balance is not an exhaustive
proof: some no-offense Hell strategies still win legitimately, and these finite
seeded scenarios do not establish a universal win rate. Human beginner usability,
subjective horror/SFX quality and Windows hardware/input performance require the
owner-and-Adie playtest. Linux software-renderer stress timings are not Windows
benchmarks. Challenge reproducibility is verified for the stated fixed-input
Linux/Godot setup, not arbitrary cross-platform human timing.

## Final delivery receipt

- Final implementation/test-source commit: **`a4dc1d0e5094825abc3b78b13879c50598f4c047`**.
  Push to private `work` succeeded and remote SHA matched local HEAD. Subsequent
  documentation/evidence commits do not change this executable’s game sources.
- Version **0.6.2-5d4**, Godot **4.6.3**. Main unchanged; no public release.
- Windows archive: **`NightfallDorm-Phase5D4-Windows-x64.zip`**,91,227,595bytes.
- ZIP SHA256: `95e3ee817ea6e8da49ab96eb343018fde87b1ecffa06ab78c87137886e38d03d`.
- EXE SHA256: `49c0cc4c630b94d516349c1c4390e3d085e9fe695c29e3f4d14522042658ce28`.
- PE x64/embedded PCK verified;20 actual Linux embedded-pack checks and all17 ZIP
  entries pass. **Native Windows execution: UNVERIFIED.**
- [Final test acceptance](evidence/phase5d4/final-test-acceptance.json),
  [runtime/visual/PCM verification](evidence/phase5d4/root-final-output-verification.json),
  [render/audio measurements](evidence/phase5d4/final-d-metrics.json),
  [independent rendered review](evidence/phase5d4/final-d-review.md),
  [rendered evidence manifest](evidence/phase5d4/final-d-manifest.json),
  [Windows build receipt](evidence/phase5d4/windows-export/windows-artifact.json),
  [ZIP integrity](evidence/phase5d4/windows-export/zip-integrity.json).
- [Owner and Adie playtest guide](PHASE_5D4_HUMAN_PLAYTEST_GUIDE.md).

Stop after Phase5D-4. No Phase6, Android expansion, multiplayer, payment system,
public release or main merge was performed.
