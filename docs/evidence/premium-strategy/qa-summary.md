# Independent Phase 5D-1 QA

Agent C verified clean `work` at `496b9b9df9efbe95f99f2efc0e7a5de3c6597815`
before implementation. Godot4.6.3 Linux; prepared profiles/models/resources/HP are
functional and transaction fixtures, **not natural balance or human win-rate evidence**.
A owns earned-currency strategy simulations; D owns actual before/after raster,
audio and subjective visual inspection; root owns full regular/extended regressions.

## Baseline

All12 commands in `qa-baseline-results.json` exited0 without engine errors:
import, core126, Phase1 purchase512/independent421, economy5382, campaign89,
rank354, twenty-item11203, rewards342, properties175889 over20000 transactions,
scene24 and actual startup PASS. Separate existing cross-process profile
write/read/cleanup also passed. Raw `qa-baseline-*.log` retained.

`qa-legacy-profile.json` was frozen using the **previous production profile
writer**, before strategy schema changes. It includes all20 nonuniform item
stacks, Mythic8200XP, two perks, five stage records, statistics, an already-rolled
spin, achievements, settings and tutorial completion. A real old shop transaction
deducted18RM, leaving102RM and purchase token4. It contains no strategy block.

## Current focused results

| Suite/log | Executed checks | Result |
|---|---:|---|
| `qa-mechanics-final.log` |172324, including270 actual approaches|PASS|
| `qa-mechanics-tuning-final.log` |983 focused, after final Precision range tuning|PASS|
| `qa-economy-final.log` |556 across16 paid branch/coupon scenarios|PASS|
| `qa-contracts-final.log` |425|PASS|
| `qa-migration-final.log` |159|PASS|
| `qa-ui-final.log` |3190|PASS|

Every final command exited0. These final logs contain no ERROR, SCRIPT ERROR or
WARNING. Check counts include repeated invariants, not that many unique scenarios.
The complete navigation run preceded the later range-only Precision204px tuning;
the affected weapon/range suite was rerun afterward. No unchanged navigation
rerun is claimed. Root's integration runner may execute the final source again.

### Actual mechanics

Five maps ×three difficulties ×three archetypes ×six doors=270 approaches:
real Hunter stays on authored floor, obeys speed bounds, cannot pass intact target
doors, rejects remote attacks, warns before first damage, physically breaches and
kills only at the actual bed before exiting. Archetype speed/damage/durability
tradeoffs and Ravager's third-strike recovery are measurable.

Four genuinely paid branches at5/10 ×normal/Reaper ×Overdrive launch actual
projectiles and apply real hit damage, shot speed and firing interval. Suppression
causes15% normal/7.5% Reaper movement slow; Frost selects the strongest slow,
freeze holds clocks, expiry clears suppression. Actual legal allied firing lane
is covered by Storm but not Focus, and Hunter's threat estimate sees this range.
Final Precision rejects a real door between204–240px; Suppression fires there.

All five maps retain six usable rooms, two of each trait. Actual occupied income,
generator electricity and initial/maximum door HP reflect benefit and drawback.
Sleeping/inactive income rules remain. Five bots physically reach beds and build
paid defenses on every map, retaining their established cap4 budgets.

Real one-entity Reaper transformation occurs once without healing or compounded
stats; archetype factors stay within0.9–1.1. All three actual warned special attacks
still complete and damage/apply their real effect across modes/archetypes.

### Accounting and result transactions

Both turret kinds ×two branches ×four coupon timings verify actual paid purchase,
upgrades and branch fee. Wrong/early/repeated/switched choices, insufficient
electricity, failed coupon save, pause and terminal actions cannot partially debit
or consume stock. Specialized buildings reach10, never11. Separate actual Gold/
Electricity ledgers produce the exact configured half-refund; sale pays once,
reuses the pad without stale branch and repeated buy/sell cannot generate resources.

All three contracts ×three modes use actual paid actions and projectile terminal
paths. These prepared wins do not prove natural balance. Violations remain failed
after selling the third turret, manual repair or activating a Legendary. Actual
automatic Guardian rescue also fails No Legendary once; failed item-save activation
consumes nothing/applies nothing and does not falsely fail it.

Abort/new-ID/reload cannot reroll the encounter. Forged unsealed results and
changed Hunter/contract/time/result/match/counters are rejected. Valid defeat,
failed contract, duplicate settlement and later repeat-key wins cannot grant a
contract bonus. Stage records and normal XP/spins still settle. Failed settlement
restores cash, claims, XP, inventory, stage, achievements, active receipt and reward
RNG; retry produces the exact control award, once. A full wallet postpones rather
than invents a contract payout; after legitimate spending, a later qualifying win
can earn the postponed bonus.

### Save and UI evidence

The frozen previous save preserves progression, items, shop tokens and spin receipt
through migration/save/reopen. Eleven malformed/future optional strategy blocks
and five partial/unknown active strategy snapshots preserve known data read-only
and retain original bytes. Existing spin/shop tokens stay duplicate-safe.
No mid-match save claim: runtime building dictionaries remain transient.

Actual scene/mouse/Enter input at720p and1080p exercises menu→stage→preparation,
Hell selection, optional contract choose/opt-out, permanent perks, shop/inventory/
rank/achievements, actual branch purchase/return to next upgrade, pause/Resume.
Ordinary720p and reduced-effects1080p include actual keyboard-focus emphasis.
Buttons/material states, glyph coverage, original icon distinctions, visible
control/label bounds and button nonoverlap pass. Owned-nearest room cannot hide a
farther available room; no-vacant fallback is honest. TEAM count follows actual
living-owned survivor state.

Confirmed glyph guards use local-font raster glyph metrics, not broad Label
rectangles with empty descent padding. Final title ink y183–279 and subtitle
y287–298 leave8px; narrow How to Play requires151/160px, Settings118/160px,
including actual icon, text, gap and padding. D separately inspects actual frames.

Final bounded follow-up retains the earlier3055 pass in
`qa-ui-before-sell-fix.log`. Actual paid Level10 Needle/Arc, with and without a
coupon-discounted specialization, show both exact resource refunds and50% inside
the real Sell button at720p/1080p. Full glyph+icon+gap+padding requires319/336px
for Needle and329/336px for Arc. Real mouse sales transfer precisely the displayed
refunds. Examples:882.50G/131.00E and4145.00G/653.00E at full price;
857.50G/127.20E and4045.00G/637.20E after discounted branch choice.

The same UI-only rerun tests actual Replay Tutorial with deliberately stale combat
warning, danger, level, shot/attack and floating-income state. Entry clears those
transients, shows SAFE PRACTICE with no threat ribbon, preserves stored inventory/
active receipt/rewards and lets the real Exit practice button return to menu.
No finished economy, navigation or contract suite was repeated for these UI fixes.

## Defects and test corrections

- C confirmed a production load failure when active archetype existed but contract
  key was missing: direct dictionary access threw, leaving writable partially loaded
  data. B safely validates both fields and preserves known progress read-only.
  `qa-migration-active-edge.log` retains the failure; current159 checks pass.
- C identified successful branch purchase retaining a disabled choice panel and
  misleading “keep level4” back action. B returns to selected-building upgrades;
  real input now verifies selected branch, exact debit and truthful next-level text.
- D confirmed original wordmark/subtitle ink overlap and clipped narrow menu text;
  B fixed line spacing/icon padding. C added ink/combined-width guards. Root found
  occupied-nearest guide and lost TEAM-count regressions; B fixed both, C tests them.
- D also caught Level10 Sell text clipping behind the new icon and stale Hunter
  warnings after returning to practice. B adjusted only Sell's typography/icon
  budget and reset practice's transient combat feedback; the final3190 UI run
  verifies both fixes without weakening the earlier tests.
- Initial C fixture failures are retained: large-wallet Vector2 float32 subtraction,
  JSON integer-versus-float dictionary equality, omitted original timestep carry,
  turret outside range, growth healing a1HP target, insufficient cash freed below
  wallet cap, and broad Label bounds mistaken for visible ink. Tests now use scalar
  wallet/quoted-price checks, exact recursive numeric comparisons and real feasible
  combat paths. No production rounding or broad tolerance was introduced.

## Limits

No confirmed failure remains in C's current tested paths. Root's full regressions,
A's live balance and D's final raster review are separate evidence, not claimed
here. Native Windows execution/import/hardware FPS/physical input/speakers,
subjective horror/premium quality and universal human balance remain UNVERIFIED.
No Phase5D-2 or Phase6 work was requested by C. C made no production edits/commits.
