# Phase 12B — independent bounded QA

Checkpoint: `35c813c` (full SHA in `source-integrity.json`). All ten requested invocations passed, totaling **6,577 assertions, zero failures**. Tested Godot4.6.3 on Linux headless; no native Windows or human-playtest claim.

| Script/stage | Checks | Failures |
|---|---:|---:|
| fair_difficulty |34|0|
| earned_power |67|0|
| earned_power_combinations |86|0|
| earned_power_accounting |261|0|
| earned_power_ui |31|0|
| earned_power_availability |6089|0|
| process cleanup |—|0|
| process write |5|0|
| process read |4|0|
| process cleanup |—|0|

`results.json` records exits, durations and counts; individual logs retain complete output. The six source tests and process script were unchanged. No assertions were removed or weakened.

## Isolation

The combination script writes a fixed `res://docs/evidence/earned-power/strongest-combination.json`. To avoid touching main evidence, QA used a temporary non-Git resource sandbox with exact copied source/test/scene bytes. `source-integrity.json` verifies those tracked bytes against35c813c. Assets/imported textures were reused read-only. XDG data/config/cache were separate `/tmp/nightfall-independent-qa12b-*` roots; the separate process tests therefore used an isolated profile, not a user save. The sandbox's generated combination result is retained here. All QA deliverables are in this directory; no production file or main evidence was edited by this auditor.

## What passed

- Fresh zero-XP/no-stock Long Night and Hell entry remain allowed; no new lock hides failures.
- Revised Campaign growth clock preserves the opening and leaves legacy1/Endless/Practice clocks unaffected; high elapsed combat growth and levels remain capped in current rules.
- Critical repair station reserve releases and actual healing spends real Electricity. Zero power restores no HP; full doors burn no upkeep. Live funded/blocked status and reserve description are present.
- A genuine actor charged hit produces a recorded recovery window; new arcane/signature casts cannot erase that recovery, and original skills return afterward.
- Tactical bots cannot spend more than their actual budgets; shared prices/prerequisites remain enforced.
- Defeat advice captures pre-breach resources and affordable actions, distinguishes unavailable repairs and disclaims a guaranteed save.
- Existing run-perk effects retain bounded healing/retaliation, genuine-hit control gating, one-charge consumption and production drawbacks.
- All15 building kinds preserve actual-spend coupon/upgrade/refund arithmetic, separate Gold/Electricity, duplicate-sale rejection and move/undo investment safety.
- Merchant UI, fractional rollback, current2 availability and durable activation journal pass. Separate process resume does not restore consumed stock or grant permanent inventory/XP/RM.
- Canonical earned45 legacy snapshot restores with retained wealth/buildings and unchanged hash. Pausing cannot farm currency.

## Qualification

These are correctness/transaction checks, not independent evidence of strategy win rates, enjoyment, native Windows stability or a universal absence of all crowd-control/repair stalemates. The main agent owns full regression and actual gameplay balance/recording evidence.

Read-only edge observation: `repair_status` reports nominal funded output whenever Electricity exceeds reserve by a tiny epsilon, while a full next economy step requires reserve plus upkeep×delta. Around that narrow threshold it is an instantaneous potential-rate preview, not an exact last-tick delivered-healing measurement. No requested test failed; the main agent was notified so wording/claims can remain precise.
