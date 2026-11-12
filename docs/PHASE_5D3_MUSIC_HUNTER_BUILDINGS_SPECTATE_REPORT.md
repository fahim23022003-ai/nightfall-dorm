# Phase 5D-3 — music, tactical Hunters, all-building progression and spectating

Version **0.6.1-5d3**, Godot **4.6.3 stable**, private branch **work**.

**IMPLEMENTED:** all four requested workstreams, including actual musical scores,
recorded vocals, tactical AI, eight Level10 systems and camera-only team viewing.
**TESTED:** independent mechanics/accounting/migration/input, genuine earned runs,
actual rendered/audio gates and existing regular/extended regression with affected
failures corrected as described below. Final earned-image refresh is complete and
all source/image hashes verify against the repaired runtime.
**UNVERIFIED:** native Windows execution of this version, physical speakers/input,
subjective musicality/scariness/vocal credibility, universal difficulty/fun and
cross-platform timing equivalence. The owner's earlier Windows feedback is real;
it is not acceptance of this new version.
**INCOMPLETE:** no required workstream remains unimplemented in the tested scope.
The native/human verification limits remain explicit. Final Git delivery is
recorded separately below; a local commit alone is not a successful push.

## Baseline, ownership and checkpoints

Actual clean HEAD/GitHub were `3e6224e649ae7d30de0742e2dc58688a078f43a2`, newer than
the supplied Phase5D2 reference. Existing history/Phase6 repairs are preserved.
This task does not start another Phase6 audit. Recovery tag:
`pre-phase5d3-3e6224e`; baseline `9f37cc6`; licensed source `3a64516`; sampled-score
assets `2df41e3`/`d05e3f4`; coherent runtime `633efc0`; credits/export workflow
`846691e`; final preservation repair `e60a114`. Main remains unchanged.

Read progress, Phase5D1/5D2 reports, actual catalogs/audio/AI/economy/UI/teammate/
Camera2D/save implementation. Nine fresh baseline commands pass: import, core126,
audio281/105streams, Hunter39, buildings512, economy556, migration190, UI1537 and
startup. A genuine old Endless checkpoint was frozen before edits.

B owns production, root documentation/old-test integration/build/Git. C independently
checks mechanics/accounting/migration/UI; A runs bounded real strategy/progression;
D captures actual rendering/audio; a short source-scout task supplies licensed
recordings. Specialists stop after useful gates and reopen only for confirmed
failures. Evidence is under `docs/evidence/phase5d3`.

## P0 — actual music and vocal audio

### Exact previous problem

Intro mode set **all musical targets to zero**; a few synthesized effects could
not replace a score. Previous music was oscillator/drone based. It also passed
through a -12dB loop offset, match gain0.55, pacing reduction, -5dB bus offset,
saved volume and ducking. Footsteps/breathing counted as critical cues and kept
intro music ducked. Earlier nonzero/unclipped output never proved recognizable
music. The owner's listening report supersedes that limited acceptance.

### New recorded-instrument compositions

`compose_horror_scores.py` renders original arrangements from actual CC0 piano,
violin sustain/tremolo, glockenspiel, bass drum and timpani recordings. Chromatic
melodic motifs, changing dissonant harmonies, four-bar contrasts, rhythmic ostinati
and dynamic orchestration replace plain oscillator loops. State themes share a
motif intentionally, with different keys/tempi/density; they are not seven unrelated
commercial recordings. Complete note events/tempo/key/instrument metadata is in
`assets/audio/score-arrangements.json`.

| Score/event | Duration | Tempo | Note events | Use |
| --- | ---: | ---: | ---: | --- |
| music_intro |19s|96 BPM|67|15s pursuit +4s welcome/creator card |
| music_menu |64s|60 BPM|90|ominous menu theme |
| music_calm |64s|60 BPM|90|occupied preparation/low threat |
| music_approach |48s|80 BPM|186|nearby Hunter suspense |
| music_danger |48s|100 BPM|312|door siege rhythm |
| music_reaper |64s|75 BPM|312|distinct lower-register boss identity |
| music_endless |64s|90 BPM|374|alternating Endless-wave variation |

Seven existing/reused score players crossfade smoothly; minor threat changes do
not restart them. Intro deliberately seeks0 on a new/replayed cinematic, is a
one-shot, and continues into the title tail. Menu/tutorial transitions clear its
cues and fade appropriately. Odd/even Endless states and Reaper milestones vary
music using the existing state system. Loops are48–64s, with phrase returns,
room tails and boundary de-clicks, not repeated five-second stingers.

Music receives a -3dB score offset and0.95 match gain; ambience uses -15dB so it
supports the score. Real warnings/speech/impacts still duck music. Running and
breathing retain playback priority but no longer duck the entire opening. The
first0–4s arrangement is stronger without increasing the later climax peak.
Saved Music/Effects/Ambient/mute preferences remain authoritative, including0.

Opening cues preserve visual timing: immediate score, running/breath at0–4s;
threat speech/lightning/intensification at4–8s; door opening/break/impact cues
around8.8/10.7s; recorded vocal climax13s; welcome/Created by Fahim/story at15–19s
with musical tail. Skip/replay stops active and queued cues cleanly.

### Real vocal texture and licenses

Fifteen event assets now derive from genuine recorded human/creature performances:
`death_scream_1/2`, `scream_1/2/3`, Hunter/Reaper laughs, `ghost_hurt/defeat`,
`reaper_hurt/death/charge`, `intro_breath/shriek/whisper`. Rate/filter/crop/fade
processing retains recorded vocal texture; no scream is constructed from a beep.
Reaper has deeper processing and separate growl/warning/death routing. Existing
nonvocal combat/weather effects remain rather than pretending every sound is new.

Instrument source: `sgossner/VSCO-2-CE` commit
`440300901dfe9275fd84e0b7763af1f8443ae62e`, **CC0-1.0**, recorded by Sam Gossner/
Versilian Studios and Simon Dalzell/Ivy Audio; sample editing Elan Hickler/
Soundemote. Upstream license/README and original paths/hashes are retained under
`tools/audio/source/vsco`. The installed GPL TimGM soundfont was not used.

Vocal files have explicit per-file CC0 declarations, original artist descriptions,
URLs and hashes from pinned `mayerwin/halloween-soundboard` and Vertigo mirrors;
selected scream/laugh credits have independent corroboration. The original
Freesound pages are blocked403, so **direct-origin-page license verification is
UNVERIFIED**. Preserved mirror metadata is the evidence basis, not a fabricated
primary-source check. Full credits/source files live under `tools/audio/source/`
(excluded from runtime import/export); derivative mappings are in
`assets/audio/vocal-derivatives.json`. Audio credits/notices accompany the Windows
ZIP. Source recordings are credited, not claimed as the project's own performance.

### Listening controls and measured output

Settings → **Audio listening room** offers all seven scores and major voices,
Stop/Back and the ordinary saved mix controls. Preview uses actual players and
consumes no stock/cash/progress. There are108 valid streams, seven score players,
eleven music/ambient players and sixteen effect voices:27 players, not a new set
on every state change. New score import metadata is explicitly lossless PCM.

[Actual audio review](evidence/phase5d3/audio-render-review.md):140 full audio
checks plus16 genuine scream→laugh→Continue checks pass. At saved Music0.5, a
controlled actual old-route Menu records RMS0.00399895 versus new0.01485796:
**+11.464dB**. Strengthened opening first-second RMS0.004656;0–4s0.008002 versus
initial0.002439 (about+10dB); climax peak remains0.13934 full scale. Title15–19s
is nonzero; muted/zero output is exactly zero. These are actual internal Godot
Master-bus captures, with note/instrument structure and functioning controls,
not just no-clipping assertions. Some first captures used QOA for the three new
imports; final PCM metadata changes neither source composition nor note events.
They are not represented as bit-identical final PCM-decoder output.

Subjective scariness, naturalness and normal-volume speaker experience still need
human audition. Use the listening room and playtest checklist, not RMS as an
artistic approval score.

## P1 — purposeful Hunter behavior and counterplay

The previous score was greedy and required a large improvement to leave a siege;
travel time also exhausted the commitment clock. New logic keeps bounded history
for six rooms, recognizes failed sieges, scores distance/durability/defensive
threat/repairs, and uses small seeded variation among sensible candidates. Actual
siege commitment and cooldowns prevent frame-by-frame switching. Movement stays
on the existing map navigation; no extra attacking enemy or teleport is added.

| Archetype | Actual active mechanics | Limits/counterplay |
| --- | --- | --- |
| Crusher | Charged smash plus20% Siege Pressure for4s | Pressure0.9s warning/20s cooldown; existing deliberate strike/recovery; Normal charged every4, Hard4/Hell3 preserved |
| Stalker |3s concealment:15% approach speed and20% shorter turret acquisition; failed-siege feints walk toward another legal room |0.65s warning/15s cooldown, reveals at doorway; weaker direct damage and first-strike warning |
| Ravager |1.35s dash at1.65× normal movement along valid route; existing three-hit combination |0.65s warning,15s cooldown,0.7s recovery even after early doorway arrival; combo adds0.8s recovery |

No blanket doubling of HP/damage. Ability windup/recovery can offset average
speed/DPS; a burst is not proof of higher sustained damage. Reaper clears normal
tactics rather than stacking them with boss specials. Once-only transformation,
HP accounting, attacks and Legendary interactions remain. Contact/open-door
validation now precedes tactics: illegal contact becomes MOVE, open/broken door
becomes BREACH, stale shadow/tactics clear without refilling/replacing the boss.

[Final A audit](evidence/phase5d3/balance-summary.md):15 controlled cases span all
five maps/three archetypes with cycled difficulties;2–6 valid targets, minimum
observed change gap9.2s, actual telegraphs/navigation/displacement pass. Ten earned
runs contain60 Reaper waves, one actual transformation each. Controlled high-tier
healed-door fixtures are declared artificial and not economy evidence.

Fourteen matched prepared campaign plans yield11 wins/3 defeats, versus prior
10/4; two additional zero-XP/no-perk/no-stock Normal plans both win. New Stalker
beats a Hell plan that previously won, while other strategies benefit from changed
targets. This supports meaningful tactical variety/counterplay, **not universally
harder AI**. Human threat/fun remains unverified; no win-rate target was forced.

## P2 — complete Level10 inventory and specialization

All six registered placeables and both built-in structures support Level10.
Temporary traps, items and scenery keep their existing roles. Existing early
prices/effects remain: machine Levels1–4, structural Levels1–5. Machines choose
one paid exclusive branch4→5 (25Gold/4Electricity fee plus ordinary upgrade);
structural choice5→6 is included in that tier's price, preserving existing L5 saves.
Level11, repeated choices and incompatible branches are rejected atomically.

| System | Late specialization effects/tradeoffs |
| --- | --- |
| Bed | Lucid:25% more income/10% less generator output; Conductor:15% less income, occupied base income×4% Electricity/s |
| Door | Bulwark:20% more HP/10% mitigation/20% weaker manual repair; Renewal:10% less HP/50% stronger manual repair |
| Dynamo | Regulated:20% more power/5% less income; Overcharge:60% more power/20% less income |
| Repair station | Powered:35% more healing,0.25E per level/s and stops without power; Careful:20% weaker healing/manual repair cost25% lower, combined discount cap40% |
| Dream amplifier | Golden:30% stronger income bonus/15% less generator output; Conductive:20% weaker bonus/30% more generator output, combined room cap50% |
| Target relay | Focused:20% stronger damage bonus/10% shorter turret ranges, combined penalty cap20%; Cooling:25% weaker bonus/10% faster firing, combined benefit cap20% |
| Needle | Existing Heavy Precision and Suppression retained, including real slow/projectile effects |
| Arc | Existing Focused Discharge and Storm Coil retained, including range/projectile tradeoffs |

Support output remains additive; amplifier/relay slope halves after4 rather than
creating exponential scaling. Base bed rates are2/4/8/15/26/40/58/80/105/135G/s;
door HP150/300/600/1100/1800/2500/3300/4200/5200/6400 before legitimate modifiers.
Inactive beds earn nothing. Powered repair cannot revive a destroyed door or run
without its Electricity cost. Bots retain original L4-machine/L5-structure budgets,
not automatic invincible Level10 fortresses.

Twelve original geometric branch SVGs, tradeoff descriptions, MAX states and late
support/structural badges accompany actual effects. Existing weapon prestige,
cosmetics, cracks, projectiles and Reduced Effects remain visible. Structural art
reuses existing bodies plus geometry/badges, not a claimed new animation rig.

### Spending, discounts and sales

Six placed machines retain actual separate Gold/Electricity investment ledgers,
including eligible discounted upgrades and branch fees. Sell refunds **50% of
actual eligible paid resources**, never list price; repeated sale/refund fails and
the pad is reusable. Coupon consumes once only after the valid discounted machine
transaction succeeds; failed writes/actions roll back.

Beds/doors remain their existing **unsellable, full-price/no-coupon structures**.
They are not silently excluded from Level10; they are distinguished from placeable
machine sales. Structural cards explicitly say full price and retain an armed
machine coupon. No refundable structural investment or free upgrade loop is added.

### Genuine earned progression

A runs10 unique earned Endless cases/245 cleared waves,15 fresh-profile resumes,
eight genuine safe exits plus duplicate guards, and two advanced actual defeats.
No live Gold/Electricity/HP/position/time/wave index is injected. Walking, claim,
sleep, production, paid upgrades/choices and combat are real. Prepared progression
and finite item budgets and0.2s/1s automated decisions are disclosed, not human
acquisition/reaction evidence. Intermission uses only genuine10% intact-door aid.

| System | Normal Hospital Economy, seed11 | Hell Mansion Fortified, seed47 | Paid single-system1→10 cost, no coupon |
| --- | --- | --- | --- |
| Bed | Wave3 /219.8s, Lucid Dividend | Wave6 /377.6s, Dream Conductor |9155 Gold /952 Electricity |
| Door | Wave3 /231.8s, Cursed Bulwark | Wave6 /386.0s, Living Threshold |9955 Gold /950 Electricity |
| Dynamo | Wave2 /168.2s, Regulated Core | Wave4 /282.4s, Overcharge |2635 Gold /262 Electricity |
| Repair station | Wave8 /396.6s, Powered Sutures | Wave7 /422.6s, Careful Restoration |3505 Gold /697 Electricity |
| Dream amplifier | Wave4 /254.2s, Golden Reverie | Wave7 /394.6s, Conductive Dream |3940 Gold /610 Electricity |
| Target relay | Wave9 /467.2s, Focused Relay | Wave8 /433.0s, Cooling Relay |5680 Gold /958 Electricity |
| Needle | Wave1 /155.6s, Suppression | Wave8 /436.2s, Suppression |1765 Gold /262 Electricity |
| Arc | Wave11 /563.8s, Focused Discharge | Wave3 /263.2s, Storm Coil |8290 Gold /1306 Electricity |

All eight reach10 by Normal wave11/563.8s and Hell wave8/436.2s. Normal uses no
consumable; Hell uses exactly four Frost/one Freeze across its run. The Normal
30-wave arm takes no player-door strikes because the Hunter favors weaker
teammates; that alone is not challenge proof. Its Needle10 deals5389.9 actual
damage. Advanced passive Normal loses wave62 after61 clears/9688.8s; active Hell
loses wave53 after52 clears/5333.4s. Abundant Gold does not prevent eventual defeat.
Observed counts remain bounded: nine projectiles,19 combat/128 presentation
records; engine objects1513 stable in long traces. Canonical all-eight saves are
17,926/17,951 bytes. Finite Linux model traces do not prove infinite stability or
Windows FPS. No further balance tuning was justified by these bounded results.

## P3 — teammate HUD and camera-only observation

T toggles the compact Gothic panel. Actual occupied teammates show survivor name,
room, alive/dead, door HP and incoming/sieging/breached status; live count excludes
the player and vacant rooms. Click a row to smoothly observe that room; Home or
Return to My Room immediately restores your view, Page keys cycle teammates.
The OBSERVE ONLY label makes the mode clear. Opening your own inspector collapses
the roster so it cannot hide upgrade details.

Camera movement never teleports a survivor or changes ownership, resources, AI
or saved fields. World edits/E/own movement are suppressed while watching; own R
and ordinary item actions still work. Home restores physical movement. Own-room
danger is prominently visible and the audio listener stays with your real room/
character. Death keeps a safe ELIMINATED room view; ordinary player defeat ends
the match. Continue/reset/new sessions return the camera home. Combat never pauses
because the camera changed. Dead teammates are not revived or controlled.

C tests1,420 actual input/UI checks across all five maps, physical W suppression/
restoration, own damage/repair/items/listener, invalid edits, death and actual
Endless preparation→watch→Continue. D tests293 real rendered controls at720/1080
on all five maps. Spectator state is transient and never expands the save schema.

## Save compatibility and deterministic challenges

Old progress, inventory, perks, rewards, shop, achievements,20 consumables, all five
maps/modes, tutorial/cinematic and prior systems remain. Old structural branch
fields default empty safely. The previous1–5 structural levels retain their
values/prices. Snapshot whole-number checks handle JSON int/float representation
without accepting fractional versions or silently dropping data. Durable stock/
Legendary/rescue use caps and exact investment ledgers persist.

New challenge conditions use **ruleset2** because AI/economy changed. Old rule1
results remain validated archival records, but old codes cannot start materially
different combat under a false fairness promise. Current valid codes still
normalize rank/resources/loadout and produce no permanent farming rewards. Six
fresh actual Game processes compare beginner/Mythic paired traces byte-for-byte
with final Hell Crusher/Normal Ravager/Hard Stalker configurations. Reproducibility
is supported for tested engine/conditions/inputs, not guaranteed physical timing
or cross-platform bitwise equivalence; results remain self-reported.

The frozen genuine old Endless save migrates, sells an actually owned Arc10 to
fund new structural choices (no injected currency), saves/reloads new fields and
retains original stock/claims. Malformed/future input remains protected by existing
read-only/recovery behavior. Tests use temporary profiles, not owner save files.

## Tests, failures and resolutions

[Independent QA](evidence/phase5d3/qa-summary.md) and
[acceptance receipt](evidence/phase5d3/qa-acceptance.json) preserve exact gates and
pre/post-fix provenance. Accepted checks: audio271; machine accounting1,668 across
48 coupon scenarios; structural effects99; migration/combinations43; tactical
60,251/15 cases plus affected20,076 and final4,033/charged/code workers; spectator
1,420; quote/coupon UI425; preservation support400 and contact235/50 fixtures.
These are repeated assertions, not that many independent human play sessions.

The immutable88-command full regular/extended run completed. Initially83 commands
passed and five failed. The failures were investigated, not hidden or skipped:

- Real **weapon/support role mixing** applied weapon interval/range twice.
  Strict support-kind filtering restores each offensive modifier exactly once.
- Real **contact/door guard ordering** let tactical timers delay MOVE/BREACH.
  Physical validity now preempts tactics and clears stale special state safely.
- Real **Hell Crusher cadence** initially changed three to four; it now preserves
  Hell3/Hard4 and adds Normal4, with actual charged warnings verified.
- Real **old-save version validation** confused JSON whole floats with integer
  array membership; proper whole-number validation preserves old/new checkpoints.
- Real **long scream/laugh expiry** used3s for a3.47s scream. A bounded six-room
  queue now permits completion (60s cap), still cleared by menu/new sessions.
  Actual Continue retains the scream, plays the laugh and drains the queue.
- Rendered roster/inspector stacking, clipped/incorrect structural level labels
  and false structural coupon markers were corrected and actual controls retested.
- Legacy tests assumed four scores, support cap4, linear support10, future ruleset2
  and travel-time siege exhaustion. They now assert seven scores/one-shot intro,
  all support10/sublinear formula, future3 and actual siege clock. Static samples
  keep headroom (75% bound); actual mixer evidence is separate. PCM is cached once
  for long-score sample checks, and new imports explicitly use PCM rather than
  decoding compressed QOA bytes as raw16-bit samples. Existing weapon-only matrix
  remains scoped to weapons; new role suites test every new branch.

All five affected suites pass on the repaired source. Root reran four; B's exact
canonical premium suite after fixes passes176,279 checks/270 actual approaches,
and its clean existing run is accepted rather than redundantly rerun. The affected
receipt identifies that provenance explicitly. All previous failures remain in
logs. Full runner copies regenerated old JSON into this phase and restores
historical evidence byte-identically. Nine new QA suites are registered for
future runs; their accepted independent commands are not falsely counted as part
of the earlier88-command list. A freshly reruns all16 campaign/10 earned/15 AI
cases after the role/contact repair; earlier source physics is archived separately.

## Rendered evidence and Windows build

Final actual rendered acceptance is **775 checks/0**: audio140, real long-voice
Continue16, teammate controls293, branch icons/paid choices133, genuine Normal71
and Hell71, and final coupon/caption/APPROACHING clarity51. The142 earned checks
were freshly repeated after the support/contact fix, using final canonical
profiles.633 unaffected audio/team/branch/clarity checks are retained with exact
provenance rather than falsely represented as repeated. There are **171 PNGs**:
130 current evidence frames and41 explicitly diagnostic frames (40 previous
physics earned views plus one confirmed roster/inspector overlap). All image
hashes/dimensions,49 runtime script hashes and linked files verify against
`e60a114e14bb2515cdfb381023902a32770c98dd`. Root also opened full-size roster,
own-danger and bed-choice frames; a fresh hashed copy confirms all five rows.
The [final source/image manifest](evidence/phase5d3/render-final-manifest.json)
records the exact accepted command/log set. See
[render review](evidence/phase5d3/render-final-review.md),
[screen index](evidence/phase5d3/render-index.md) and the source/hash manifest.
No prior Phase6 screenshots are substituted for new feature evidence.

A real updated Windows x64 cross-export is built from the repaired source.
Matching Godot4.6.3 templates were already checksum-verified in this same runtime;
no new Phase6 audit or public release is started. The private ZIP includes
executable, source version/checksum, playtest guide and Godot/font/music/vocal
notices. PE structure and embedded pack are tested with the Linux engine; this
does not certify native Windows execution. Earlier before-support-fix artifact
is diagnostic, not the final download.

Final archive: `/workspace/NightfallDorm-Phase5D3-Windows-x64.zip`, **80,976,099
bytes**, SHA256
`33ae95cdfa14d86e70b6b5b900e61c33f097f8d6ccaf46f591d6e9c984e504c3`.
[Artifact receipt](evidence/phase5d3/windows-artifact.json) pins repaired source
`e60a114e14bb2515cdfb381023902a32770c98dd`, executable bytes/hash and embedded
pack size. Final import/export,11 actual Linux embedded-pack checks and ZIP CRC/
content verification pass. The ZIP is a workspace binary download; GitHub's work
source ZIP contains the project/assets/export workflow, not the executable.
A first packaging attempt correctly refused an uncommitted credit-manifest change;
its guard log is retained, then the manifest was committed before the clean build.

## Outstanding limits and delivery

No claim of subjective frightening music, convincing voices, universal harder
AI, perfect visuals or Windows hardware approval follows from automated counters.
Fahim/Adie should use the [updated guide](WINDOWS_PLAYTEST_GUIDE.md), including
Audio listening room, fresh/saved mix, all branches and T/Home on real Windows.
Existing simplified sprites, distance-based targeting, local/self-reported codes
and between-wave-only resume remain known limits. Weapon inspector values are
weapon/perk values rather than a total live DPS calculator including every relay/
item effect; room tradeoffs are stated separately and actual combined effects
are tested. This nonblocking display limitation is not claimed as effective-DPS UI. No multiplayer, Android work,
public release, main merge or new Phase6 is included.

**GitHub push VERIFIED SUCCEEDED.** Complete feature implementation, reports,
source recordings, score assets, tests, logs, PCM and all171 images are committed
at `ea8c0eea777e8870eeff050c7646c3a907e2bd19`. A fresh `git ls-remote origin refs/heads/work` matched local HEAD
exactly and the content working tree was clean. Main is unchanged; no public
release or new Phase6 was performed.

[Delivery receipt](evidence/phase5d3/delivery-receipt.json) records the exact
comparison and seven bounded evidence pushes. The subsequent documentation-only
receipt commit also preserves the immutable regression command list/runner; its
own SHA is in Git history and the final response. Runtime/build source remains
`e60a114e14bb2515cdfb381023902a32770c98dd`. Download the current private **work**
source ZIP for all changes, or the separately provided Windows test ZIP.
Stop after Phase5D3.
