# Independent typed-combat and Hunter QA

**PASS:522 mechanical/economy checks, zero failures, exit0.**
**PASS:40 Challenge checks, zero failures, exit0;12 fresh-engine workers.**

The new tests are `tests/overhaul_qa_combat.gd` and `tests/overhaul_qa_codes.gd`. C changed no production code and no old tests/evidence. `qa-core-receipt.json` records source/artifact hashes and diagnostic lineage.

## Tested

- Independent numeric Physical/Magic damage, explicit source/weapon packet classes, rejection of invalid types/elements/NaN/negative damage, evolution/door-armor application once and all bounded four-element matchups through actual target damage.
- Barrier reflection: real door damage still occurs; bounded actual damage reaches the correct Hunter or registered undead ID. Cooldown, sale/rebuild cooldown retention, Physical exclusion, reflected-packet recursion prevention, stale dead IDs and one-time affinity multiplier pass.
- Plasma: actual25% absorption, finite level1 capacity115, paid-hit energy accumulation, spent stored energy becomes actual bounded door healing, Physical exclusion,12s expiry and sale/rebuild clearing with shared healing cooldown retention.
- Antenna: actual Electricity deduction, finite42 durability, Physical bypass, Magic overflow, no cooldown bypass from multiple machines or sale/rebuild, automatic paid recovery and no purchase when power is insufficient.
- All six new-machine specialization combinations: real purchases/upgrades through Level10, exclusive paid branches, correct discounted base/branch Gold and Electricity ledgers, exact50% actual-capital refunds, duplicate-sale/duplicate-pad/Level11/insufficient-wallet rejection and exact coupon consumption.
- Existing20-item registration, actual Inferno Fire affinity and one-shot Physical/Earth trap paths, successful repair stock consumption with every new defense, and Rules Judgement refusing shield activation without consuming stock.
- Magic-state JSON checkpoint restore keeps storage, shields and room cooldowns together; malformed/negative/nonfinite/over-cap/missing required state rejects. Older rooms without new machines may safely omit the state.
- Actual full Hunter/model ticks for Witch/Electric/Storm on all five maps: visible warning state precedes real Magic damage, one finite cooldown is set, Electric disruption expires. An out-of-range Witch cannot resolve a projectile. Reaper actual drain damages/heals within cap; warned Shadow Dash produces legal navigable movement. All original roster artwork states and existing Reaper robe assets remain present.
- Fresh actual Game challenge startup for all six archetypes, each on beginner and progressed isolated profiles. Twelve separate Godot processes produce byte-identical70-second fixed-input traces per paired code. Starting resources, permanent perk configuration and temporary loadout are normalized. Rulesets1/2/3 archive-only codes and malformed/future codes are handled safely; old three archetype indices are preserved.

## Diagnostics and scope

The first core run contained C fixture errors: attempting to reconfigure an immutable Hunter, using an incorrect item activation API, assuming Earth is neutral against Ice, and asserting invented Reaper asset filenames. Those failed logs remain. A subsequent indentation parse error is also retained. The corrected completed suite is `qa-combat-second.log`; no failing assertion was disabled to obtain success. Challenge workers passed their initial run.

Injected resource fixtures prove accounting/effect contracts, not natural earning or difficulty. Full existing item/boss/rank/save regressions, actual rendered art/SFX review and legitimately earned balance simulations are separate root/D/A gates. Fixed-input Linux engine equality does not imply identical human or cross-platform timing. Native Windows execution and subjective usability, scariness and sound quality remain UNVERIFIED.

No confirmed functional core bug was found by this bounded gate. The highest-level defense selection policy/tie wording was sent to B/root for explicit presentation rather than silently changing balance.
