# Automated validation

Run `bash tools/check.sh` from the repository. Godot 4.x is required. The script imports the project, runs gameplay assertions, menu/scene integration checks, fixed-seed match simulations and a main-scene startup smoke check. It preserves Godot exit failures and scans for script errors that Godot can sometimes log despite exiting zero.

Individual checks:

```sh
godot --headless --editor --import --quit
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --script tests/scene_smoke.gd
godot --headless --path . --script tests/simulate_matches.gd
godot --headless --path . --quit-after 120
```

Tests execute the production GDScript model and actual instantiated scene. They do not copy gameplay calculations into a substitute engine. Resource expectations are derived from `Catalog`. Fixed seeds are 7, 8 and 99; each runs passive, balanced, guard and economist player automation. This uses the production `BotAI` to choose legal purchases from earned resources, without adding money or changing hunter statistics. Controlled unit tests separately inject resources/positions to isolate individual rules. Both kinds of evidence are identified in `docs/QA_REPORT.md`.

Headless UI checks emit real Button signals and inspect state transitions. They also dispatch actual viewport mouse events to select the second tile and build a generator, using the viewport stretch transform. They cannot establish visual quality, physical audio quality, or platform display behavior. Graphical testing is recorded separately.

The default wrapper also runs `audit_regressions.gd`, `audit_properties.gd` and `audit_rates.gd`. `bash tools/check.sh --extended` additionally runs the 27 match frame-step probe and the 144-match all-room matrix. Both paths preserve exit failures and scan script-error output. The extended run is bounded by simulated-time limits, rather than waiting indefinitely for a match.

The gameplay suite counts assertions, the scene suite counts integration checks, the property suite counts invariants across 20,000 transactions, and simulation counts are whole matches. These are different measures and must not be added together as a count of distinct gameplay scenarios. See `docs/AUDIT_TEST_REPORT.md` for baseline failures, final evidence and remaining limits.
