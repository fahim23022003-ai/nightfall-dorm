# Independent Phase 5B-1 item QA

Agent C tests the production catalog, profile, item effects, Hunter/model and
existing campaign interface. Fixtures deliberately set room/time/resources for
focused behavior checks; they are not human gameplay or balance evidence.

`tests/items_qa.gd`: **3,179 checks passed, zero failures**, exit0 (`qa-final.log`). Coverage includes:

- Eight implemented IDs, positive tables totaling100%, exact seeded repeatability,
  and1,000rolls for each outcome reaching only functional Common/Rare items.
- Persisted settlement grants, Victory quantity4/Consolation1, reveal acknowledgment
  without another stock grant, failed acknowledgment write rollback, repeated
  claim/settlement and reload deduplication. Stock ceiling receipts report the
  actual granted quantity rather than overflowing9,999.
- Two owned types, no equip consumption, rejection of zero stock/unknown/third
  selection, inventory/loadout save roundtrip and old-version profile migration.
- All eight effects across five maps and three difficulties: exact repair/gold/
  electricity, radar duration, actual shield interception/overflow, Frost normal/
  boss resistance and real movement, actual increased turret-launch cadence,
  real trap damage/once-only trigger, timer expiry and terminal/reset cleanup.
- Invalid full/broken door, paused/result/unclaimed/dormant/no-turret activation,
  wrong match/slot, zero stock and save failure cannot consume or apply effects.
  Global cross-slot debounce and nonstacking active effects are verified.
- Corrupt/future inventory schemas preserve known XP read-only; invalid active
  item snapshots become safe without crashing activation. Last-stock spending
  keeps the active hotbar snapshot, removes future selection and rolls both stock
  and selection back on a failed save.
- A Hunter crossing an armed trap during1-second real navigation must trigger it
  once, including all five maps. This regression was added after reproducing
  discrete-distance tunneling; the production fix checks swept movement.

Confirmed production findings: trap tunneling on long frames, and malformed
active-match item snapshots loading without validation. Both were reported to
Agent B and fixed; final tests include regressions. The original initial four
failures in `qa-initial.log` were test-fixture errors (numeric dictionary equality
across JSON, and a full-door fixture taking a real Hunter hit before checking),
not gameplay defects; fixtures were corrected rather than weakening semantics.

`tests/campaign_flow.gd` now passes126checks with the real Results → Lucky Spin →
Skip → Save reveal → original continuation flow. Its original54stage, scaling,
retry, loadout and persistence assertions remain; new checks verify persisted
stock does not change during visual reveal and repeat acknowledgment is rejected.
Defeat fixtures now actually eliminate the resident. `qa-campaign-initial.log`
retains the old test's expected failures when it attempted to bypass the new
reward gate. `tests/phase2_ui.gd` passed unchanged63checks.

## Matched balance diagnostics

`tests/items_balance.gd`:60fixed-seed matches, zero resource/navigation/unresolved
failures (`balance-final.log`, `balance-results.json`). Same earned-currency
policies, seed11,0.1-second ticks and one normal action attempt every0.5seconds:
5maps ×3modes ×2policies ×with/without items. Inventory is an **explicit fixture**:
four units of each of two selected types (equivalent to two selected Victory
Spin stacks), not a claim those precise types were naturally rolled.

Balanced policy uses Gold/Shield; proactive economy policy uses Battery/Repair.
The baseline has no consumables. Starting currency and bot behavior are unchanged.

| Mode | No items | With item budget | Successful activations |
| --- | --- | --- | --- |
| Normal |10W/0L|10W/0L|40|
| Long Night |8W/2L|10W/0L|40|
| Hell |2W/8L|8W/2L|54|

The finite sample shows a significant benefit, with two Hell losses despite this
budget. It does not establish human win rates, universal victory or all possible
item combinations. Unused stock remains; no currency was injected for building.
The earlier `balance-initial.log` is an interrupted staging run with one unit per
type, stopped when the intended Victory-stack budget became four; it is not the
final comparison.

Victory4units over160–200seconds gives1.2–1.5units/minute; an earliest eligible
60-second consolation gives1unit/minute. Rare-unit expectation is higher for
Victory(40%) than Consolation(10%). These arithmetic rates reduce the obvious
loss-count incentive but do not prove all targeted Common-item farming impossible,
especially for slow victories. Human economy observations remain necessary.
Native Windows, subjective item feel/audio and broad long-term farming behavior
are outside this headless diagnostic evidence.
