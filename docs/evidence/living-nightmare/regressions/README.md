# Existing gameplay regressions

The logged suite runs cover the legacy Campaign selector and profile,
Core combat, inputs, boss actions, Full Room Grid saves, V2 persistence,
the main scene and Endless. Each finished with zero failed checks.
Use Godot 4.6.3 with an isolated XDG data directory to reproduce.

The two compressed receipts contain 30 paired complete Campaign
simulations across the ten V2 layout families, all three difficulties and
multiple plans using existing mechanics. All case rows matched exactly
between the preview off and on for the same seed, geometry and strategy,
including attack counts, Hunter damage, players, wallets, movement,
recovery and terminal result. The ordinary test does not enable Story
mission profiles. Each arm had zero invalid cases.

```sh
NIGHTFALL_LIVING_NIGHTMARE=0 XDG_DATA_HOME=/tmp/nightfall-regular godot --headless --script tools/nightmare_tactics/check_starting_rooms.gd -- /tmp/regular.json v23 docs/evidence/living-nightmare/regressions/unchanged-fixtures.json
NIGHTFALL_LIVING_NIGHTMARE=1 XDG_DATA_HOME=/tmp/nightfall-living godot --headless --script tools/nightmare_tactics/check_starting_rooms.gd -- /tmp/living.json v23 docs/evidence/living-nightmare/regressions/unchanged-fixtures.json
```

[Story progression tests and mission battles](../qa/) · [Audio tests](../audio/)
