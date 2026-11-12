# Independent Phase 5B-2A QA

Agent C ran real Godot4.6.3 headless tests against production code.
`tests/advanced_items_qa.gd`: **7,988 checks, zero failures**, exit0.
`qa-final.log` is the passing final run. Fixed-case profiles, resources, HP and
positions are explicit fixtures; they are not naturally played matches.

Coverage includes:

- All16 registrations/icons, positive weighted tables summing100, exact rarity
  distribution, seeded repeatability and reachability of all implemented items.
- Existing eight-item inventory stacks and pending reward receipts, rank/perk
  preservation, receipt acknowledgement without regrant, and saved reduced-FX.
- Actual25% door mitigation in all5maps/3modes, shielding applied after mitigation,
  real expiry and same-frame use rejection.
- Real occupied-bed Pillow income, inactive-bed exclusion, exact25boosted seconds
  across0.1/0.5/1/30second model steps, then restored income.
- Explicit selected teammate rescue, exact25%heal, absent/invalid and eliminated
  target rejection without spending inventory.
- Real discounted building purchase/upgrade in both currencies, actual-paid
  investment ledgers, half-of-paid sale refunds, no second sale, no second
  discounted purchase, insufficient-funds/invalid-position preservation, failed
  save rollback and successful retry. Heavy purchases test nonzero electricity.
- Automatic Feather cannot be manually spent, requires a downward nonlethal
  intact25% crossing, heals15% once per match, does not revive a broken door,
  and does not spend/heal on failed persistence. Existing Last Light and Feather
  each trigger once and yield a bounded combined result.
- Inferno originates from owned projectile impacts, repeated ignition refreshes
  one bounded burn rather than multiplying DPS, exact configured damage and
  Reaper resistance apply, teammate impacts do not ignite, and expiry stops DOT.
- Decoy/Smoke control recovery blocks alternating refresh, Reaper durations are
  bounded, all-map movement remains walkable and within real speed limits, effects
  expire and the final living room remains attackable.

The initial `qa-initial.log` contains23 fixture/readiness failures: eight icon
assets were not yet generated and fifteen Pillow checks called RoomState directly,
bypassing the model's partial-duration bonus integration. Final tests use actual
MatchModel ticks. `qa-boundary-initial.log` retains one floating-point fixture
boundary failure; replacing fractional cancellation with an exact threshold+1HP
minus1HP tests the same boundary deterministically. No production defect is
claimed from these test setup issues. No semantic assertions were disabled.

`tests/items_qa.gd` was adapted only for sixteen registrations/table entries and
seed reachability; its original eight-item all-map/all-mode effect loop remains
explicitly preserved. The primary agent owns the full regression-wrapper results.

## Matched balance comparison

`tests/advanced_items_balance.gd`: **60 matches, zero invariant failures**.
Five maps × three modes × two strategies × baseline/advanced-item arms.
Actual ordinary starting currency and income are used. The item arm is given a
clearly disclosed fixture budget of four units each in two equipped item types:
Barricade/Inferno for balanced play, Pillow/Feather for proactive economy.
This is equivalent in quantity to two Victory Spin stacks, not proof the items
were naturally earned or randomly rolled in these particular matches.

| Mode | Baseline | Advanced item budget |
| --- | --- | --- |
| Normal |10W/0L|10W/0L|
| Long Night |8W/2L|9W/1L|
| Hell |2W/8L|5W/5L|

The final run uses12DPS Inferno and retains115 successful **manual** activations.
Automatic Feather consumption is not included in that manual event counter.
Earlier6DPS evidence is preserved as `balance-initial.log`/`.json`; final outcomes
were unchanged after the configured increase. Final evidence:
`balance-final.log`, `balance-results.json`.

These finite strategies demonstrate helpful items without guaranteed victory in
Hell. They are not human win rates, universal balance certification or tests of
every possible item pair, stockpile, seed or control timing. Graphical/audio and
native Windows checks are outside this headless evidence; consult Agent D and
the phase report for actual rendering and limitations.

## Focused simultaneous combinations

`tests/advanced_item_combos.gd`: **27 checks, zero failures**
(`qa-combos.log`, exit0). Actual turret launch/projectile-impact simulation with
Inferno plus Overdrive produces12launches versus9with Inferno alone in the same
8seconds. Both ignite one bounded burn at configured DPS; Overdrive does not
multiply the DOT, and both expire correctly.

Frost plus Decoy and Frost plus Smoke are tested simultaneously on a Reaper:
real movement respects slowed speed and valid navigation, resistance remains25%,
shared control recovery prevents alternating refresh, and both effects expire.
The Reaper then resumes a real Soul Siege warning followed by actual door damage,
demonstrating specials are not permanently disabled. These are explicit setup
fixtures, not naturally acquired inventory or human balance evidence.
