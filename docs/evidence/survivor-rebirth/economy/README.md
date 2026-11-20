# Survivor Rebirth defeat cash

The opt-in preview credits a completed defeat to the permanent RM wallet.
The player must have occupied a room before a real terminal elimination
in Campaign, Story or Endless. The payout starts at 6 RM and can earn up
to 3 more from time in bed and 5 from contribution. Each complete
45 seconds of occupancy earns 1 RM. Each complete 200 combined damage
dealt and door damage taken earns 1 RM. The maximum is 14 RM, and an
eligible victory still starts from the existing 24 RM base. The existing
wallet cap applies to the actual credit recorded in the result.

Tutorials, Practice, Challenge, unclaimed deaths and abandoned runs yield
no preview defeat cash. Safe Endless retirement retains its existing
milestone rules. Story position, permanent rank XP, spin reward eligibility,
purchase prices and match resources use their existing rules.

| Actual recorded result | Verification |
| --- | --- |
| Early Campaign loss after 39.3 seconds of occupancy | 6 RM and 0 loss XP |
| Two early Campaign defeats, then open the next match | 12 RM buys one Radar. The player equips it and activates it in the following match. |
| Story victory and subsequent defeat | Victory advances the Story position. Defeat moves it back and pays earned RM with existing XP rules. |
| Endless defeat after reloading an actual cleared-wave checkpoint | 7 RM, unchanged XP and item stock |
| Successful settlement at the wallet limit | Receipt records only the credited amount and includes the final balance. |
| Failed write, then successful retry and reopen | Transaction rolls back on failure. The same result cannot pay a second time. |

The focused 85-check Godot 4.6.3 suite runs production model attacks,
settlements, saves, shop purchases and consumable activation. The short
loss fixtures position the Hunter for an imminent breach. The model
then produces the actual attack, resident elimination and terminal
record. Dedicated rule fixtures cover time and damage thresholds, the
wallet cap, fallback behavior, XP and reward compatibility. Native
Windows playtesting is pending.

```sh
XDG_DATA_HOME=/tmp/nightfall-defeat-cash godot --headless --audio-driver Dummy --script tests/survivor_defeat_cash.gd
```

[Focused log](focused.log)

The legacy launcher configuration also passed the [currency audit](onboarding.log)
with 57,016 checks, the [Endless transaction stress suite](replay.log) with
284, and the [Campaign profile suite](campaign.log) with 89.
