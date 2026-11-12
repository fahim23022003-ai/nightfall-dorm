# Phase 5D-4 independent no-turret baseline

Frozen before production changes on runtime `d507600` (the completed Phase5D3
source). Godot4.6.3 Linux headless; actual model navigation, room claim/sleep,
full NPC economy/purchasing, Hunter combat and terminal settlement. No player
live currency, HP, position, clock or wave is injected. Source hashes and exact
command receipts are in `balance-baseline-manifest.json`. These are deterministic
policies, not human play or a target win percentage.

## Fresh accepted cases

45 no-player-offense cases cover all five maps with their actual corresponding
campaign stages, all three difficulties, three archetypes and three fixed seeds.
The same map/mode/archetype/seed/room selection is paired across three policies:

| Player policy | Normal victories | Long Night victories | Hell victories |
| --- | ---: | ---: | ---: |
| Claim/sleep and then fully idle |1/5|2/5|0/5|
| Bed/door upgrades and manual repairs only |5/5|5/5|4/5|
| Economic/support machines, bed/door and repairs; no offense |5/5|5/5|4/5|

Every no-offense arm uses zero XP/perks/equipped items and deals **zero actual
player damage/shots**. The only prepared campaign state grants access to the
stage under test. The bed/door-only arm never buys a Dynamo, so it legitimately
cannot afford Electricity-gated later structures: it reaches Bed3/Door3. The
support-only arm separately allows actual Dynamo/repair/amplifier purchases,
so absence of Electricity is not confused with a practical no-turret strategy.
Manual decisions are scripted every0.2s; this is not proof that an inactive human
can win by doing literally nothing.

Six separate Hell controls add:

- Three competent active Master plans, finite4Shields/1Heart, all win and deal
  actual player damage1728–2549; NPCs still supply most Hunter damage.
- Three **counterfactual high-NPC** cases grant each NPC10000Gold/1000Electricity
  once when it claims a room. The player remains fully idle. One wins, two lose.
  These are explicitly seeded NPC advantages, not ordinary earned-economy runs.

Both processes exit0, all51 cases reach legitimate terminals, no engine/error/
warning or integrity failures occur, and original evidence remains unchanged.

## Actual NPC carry, not an assumed static DPS value

The four Hell bed/door-only wins are:

| Stage/map/archetype | Seconds | NPC-only damage to Hunter | Player manual repairs | Actual player spending |
| --- | ---: | ---: | ---: | ---: |
|1 Dorm /Ravager|185.9|6050.0|28|546Gold|
|2 Hospital /Crusher|200.9|8142.3|18|426Gold|
|3 Hotel /Stalker|202.8|6794.8|41|702Gold|
|4 Lab /Ravager|202.5|6694.8|49|798Gold|

The fifth (stage5 Mansion/Crusher) loses at181.1s after76 manual repairs and1122
Gold spent, with NPC damage2926.3. This demonstrates room/map/target dependence,
not universal passive success or an artificial loss condition.

In the four wins, observed team NPC damage averages39–55 damage/s over the
elapsed window from first Hunter damage to terminal. This is measured cumulative
damage over that whole window, not continuous in-range DPS. A theoretical maxed
room's approximately412DPS must **not** be substituted for actual encounter output:
weapons spend time growing, moving targets leave range, and the Hunter changes
rooms. Those four wins' NPCs earn approximately7.9k–14.9k Gold, spend6.2k–9.2k and
perform14–19 manual repairs in addition to repair-station healing. Actual NPC tier
maxima across all51 cases are Bed5/Door5/machine4.

Static code permits emergency structural escalation beyond the advertised NPC
budget and has a branch-failure repair fallback issue. Neither NPC tier>5 nor
free NPC resources was needed to reproduce ordinary carry here. Those latent
semantics merit correction, but are not a measured explanation for these51
outcomes. Fixing an unsuccessful-repair fallback may make NPCs stronger, so
balance must not depend on keeping that bug.

Root cause supported by the paired runs: even modest player survival investment
lets the autonomous team's independently earned weapons finish the Hunter while
the player contributes no offense. It is **not** evidence that fully idle Hell
always wins: all five ordinary fully-idle Hell controls lose. Timing, target
selection, healing, actual travel/downtime and NPC coverage must be considered
before changing any stats. Helpful NPCs need not be removed or given scripted
losses, and the measured sample is not a prescribed final win rate.

## Hunter activity and Reaper eligibility

Every case configures its real StageCatalog stage and difficulty, not just a map
with an empty stage. Stage1 is intentionally Reaper-ineligible in all modes;
Normal stage2 is also ineligible. Stage2+ Hell cases explicitly have boss enabled.

The ordinary Hell bed/door-only Hospital/Hotel/Lab wins actually transform at
152.8/157.5/189.2 seconds. Their Hunter spends roughly119–125 seconds in attack,
23–39 in movement,9–12 exiting rooms,4–9 breaching, plus the existing2.4s transform.
There is no missing transformation/render flag in those model cases. The stage5
Mansion loss has passed the80active-second opening, but the minimum alive HP
ratio is still0.657, above the0.55 threshold, and its terminal precedes the210
active-second deadline. The row labels this eligibility condition rather than
inventing a boss bug.

The high-NPC Hospital counterfactual wins in69.6s with zero player action and
7403.1 NPC damage, before the80active-second transformation opening. The other
counterfactual weak player doors fail at56.1/63.8s. This directly demonstrates a
credible way for highly funded NPC offense to erase the encounter before a boss
can appear. It does not imply the same cause in every human report. Stage choice
and early termination must be visible to the player; forcing Reaper into every
stage would discard an established rule.

No Hunter damage occurs before preparation ends in these accepted cases. All
state-duration, first damage/attack, NPC resource/build levels, target changes,
HP-at-eligibility and boss policy data are retained per row. Actual Windows
rendering/audio visibility and human experience are independent evidence.

## Disposition

Baseline is frozen. No production tuning or source edits were made by A. Parent
may proceed once the broader baseline gate is ready. Reuse these exact inputs
for final paired comparisons, then add fresh seeds and the new boss/minion/
building/domain scenarios when their stable APIs are available. No repeat of the
unchanged full old matrix is needed now. Human difficulty, native Windows and
subjective challenge/fun remain UNVERIFIED.
