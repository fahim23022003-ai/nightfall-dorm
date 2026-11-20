# V2.3 matched Campaign receipts

Each fixture lists stage, difficulty, seed, zero-based player room, policy,
and expected family. The two arms both enable V2.2 defense-aware rerouting.
The V2.3 arm also enables the defended-door memory and warning. Simulation
receipts log investments, wallet drift, attack and route events, player and
NPC damage and the match result. Walk fixtures use the player navigation
path and collision-limited movement, then ordinary interact actions to
claim the room and sleep. Receipts are compressed JSON.

Run Godot 4.6.3 from the repository with a distinct profile directory for
each arm. Use the same fixture file in both arms.

```sh
XDG_DATA_HOME=/tmp/nightfall-v22 godot --headless --script tools/nightmare_tactics/check_starting_rooms.gd -- /tmp/v22.json v22 docs/evidence/nightmare-maps-v23/matches/fixtures.json
XDG_DATA_HOME=/tmp/nightfall-v23 godot --headless --script tools/nightmare_tactics/check_starting_rooms.gd -- /tmp/v23.json v23 docs/evidence/nightmare-maps-v23/matches/fixtures.json
```

Use `fixtures-broad-1.json` and `fixtures-broad-2.json` for the additional broad
matches and `walk-fixtures.json` for the walked runs, with distinct output paths.
`walk_earned_control` and `earned_control` use a real prior profile victory
and two finite earned items. All other fixtures use no items.
