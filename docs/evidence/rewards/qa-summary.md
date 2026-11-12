# Independent Phase 5B-3 QA

Agent C tested the real model/profile APIs with Godot 4.6.3 on Linux. Fixtures
set initial ranks, stock and match outcomes to isolate accounting; they are not
naturally earned playthroughs or native Windows certification.

`tests/rewards_qa.gd`: **342 checks, zero final failures**. Coverage includes:

- All seven rank boundaries, actual gated Mythic eligibility, unchanged 20-item /
  two-consumable slots, one permanent slot below Master and two from Master,
  locked equip rejection, independent removal/replacement, saved loadouts.
- Actual income/door modifiers and owned projectile impacts: Reaper Slayer adds
  exactly 6% only to the player's impacts against the transformed Reaper.
- All twelve deterministic achievement rewards, no unearned claim, exactly-once
  XP and stock, reload preservation, failed-save rollback, full-stock refusal
  without false claim and successful claim after making space.
- Old save migration preserves XP, stock and loadout. Only provable historical
  victory/mode/Reaper records unlock retroactive achievements. Damage, income,
  construction, Legendary use and perfect-team records are not fabricated.
- Real successful building purchase/upgrade/sale cycles and settlement update
  measured counters. Exact condition boundaries, distinct-item history after
  spending, three real Reaper settlements, actual Long Night completion.
- Settlement replay protection, atomic rollback of all rewards/counters/campaign
  and RNG state on failed save, and successful one-time retry.
- Three first-clear choices, exactly one selection, save/reload, intended target
  only, failed choice and failed match-start rollback, once-only consumption,
  replay anti-stacking, actual starting Gold/door HP and timed 8% projectile damage.
- Different first clears preserve the older unresolved offer and queue the next;
  queue survives reload, failed promotion rolls back, and valid consumption
  promotes the next offer once. Damaged/future optional records preserve base
  progression read-only.

`tests/rewards_combos.gd`: **27 checks, zero failures** across all three modes.
Two legal rank perks with Guardian/Barricade retain finite rescue/shields and do
not duplicate First Aid; two offense perks with Time Freeze cannot bypass the
persisted one-Legendary limit or freeze expiry.

Intentional old-test updates preserve their original gameplay assertions:
Mythic now expects seven perks/two maximum slots and chooses a stage bonus before
continuing; failed settlements expect rollback and explicit retry. Campaign
profile chooses its earned bonus; rank fixtures use three unique perks for an
invalid over-cap Master loadout and test independent removal of the second slot.
Focused final runs: Mythic **204/0**, campaign profile **89/0**, rank **354/0**.
Root owns the complete regular/extended regression run.

## Deterministic balance

`tests/rewards_balance.gd`: **120 matches, zero invariant failures**: five maps,
three modes, four ranks (Bronze, Gold, Diamond, proven Mythic), with perk-only
and prepared arms. Seed 11 and balanced purchasing policy. Prepared arms have
a disclosed fixture budget of four Emergency Shields, stocked Guardian Heart
(limited to one actual activation) and one +25-Gold stage bonus; currency after
that is earned. Paired ranks use identical perks.

| Difficulty | Perks only W/L | Prepared W/L |
| --- | ---: | ---: |
| Normal | 20/0 | 20/0 |
| Long Night | 14/6 | 18/2 |
| Hell | 4/16 | 20/0 |

The strong prepared policy wins all five Hell maps at each rank for this seed.
This is a real observed result; it is not hidden or described as proof that Hell
always retains losses. Small rank effects do not establish a monotonic win-rate
increase in this sample.

A separate **40-match Hell challenge** uses seed 47 and a reactive economy
policy on all maps/ranks: perks only **4/16**, prepared **12/8**, zero invariant
failures. At each rank that is 1/4 versus 3/2. This demonstrates that the finite
prepared budget does not universally guarantee victory, while a low-rank win
remains possible. No difficulty tuning was inflated to offset progression.
All outcomes terminate; resources/inventory remain nonnegative and finite,
navigation is bounded, and Legendary use never exceeds one.

The first balance run omitted previous campaign records in its synthetic Mythic
fixture, so the existing campaign validator correctly rejected those 30 starts.
The corrected fixture includes the full historical stage chain; initial log is
preserved. A queue reload assertion initially compared deep arrays with JSON's
2.0 versus in-memory integer 2; all values loaded correctly. The assertion now
compares semantic fields/whole IDs, and loaded IDs are also normalized by B.
Neither was an observed gameplay accounting exploit. Initial logs remain.

Native Windows execution, human play, subjective audiovisual quality and human
win rates remain **UNVERIFIED**. Agent D owns actual rendered/audio evidence.
No confirmed functional failure remains in C's tested scenarios.
