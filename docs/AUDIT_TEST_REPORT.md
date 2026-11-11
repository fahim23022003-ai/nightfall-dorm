# Independent QA audit

Agent C performed a second audit against the production Godot project, including adverse scenarios beyond the initial passing suite. Production fixes were owned by Agent B. Godot version: **4.6.3 stable**, Linux, Codex Cloud. The original committed baseline was extracted from `051e681` into `/tmp/nightfall-audit-baseline`; the live checkout was never reverted to conduct baseline tests.

## Results and evidence

| Check | Final result | Evidence |
|---|---|---|
| Import, production gameplay and main startup | Clean import/startup; 125 assertions, zero failures | `evidence/audit-final-checks.log` |
| Actual scene and UI input | 19 checks, zero failures | Same full log; `evidence/audit-input-smoke.log` |
| Focused audit regressions | 71 assertions, zero failures | Full log; `evidence/audit-final-regressions.log` |
| Randomized transaction properties | 20,000 transactions, 18,007 rejected; 175,941 checks, zero failures | Full log; `evidence/audit-properties.log` |
| Original representative natural simulations | 12 matches: nine victories, three defeats, zero unresolved | Full log |
| Expanded natural matrix | 144 matches, zero unresolved | `evidence/audit-final-matrix.log` |
| Frame-step sensitivity | 27 matches at 0.02, 0.05 and 0.1 seconds, zero unresolved; each strategy/room retained its outcome across step sizes | `evidence/audit-final-timesteps.log` |
| Isolated attack rates | Six scenarios; identical counts across the three step sizes | `evidence/audit-final-rates.log` |

Counts represent assertions or bounded scenarios, not an assertion of exhaustive coverage. The 12 representative matches are additional runs, not a replacement for the broader matrix. Intermediate candidate logs are preserved with `checkpoint`, `saving`, or baseline names; they are not final results.

## Bugs reproduced, corrected, and regression-tested

The original baseline focused suite executed 43 assertions and reported **12 failures**. These were actual failing assertions, including several consequences of the same root cause. See `evidence/audit-baseline-regressions.log`.

- Eliminated rooms could buy bed/door upgrades and repairs. Alive guards now reject them without spending.
- Paused and terminal matches accepted purchase commands. Model entry points now reject these actions atomically.
- Large movement frames could jump between adjacent rooms through a wall. Movement now uses bounded substeps; the original tunnel case is rejected.
- A player standing in an unclaimed room reserved that room while the bot allocator also reserved another, leaving only four bots. Physical reservation now allows the fifth bot to use the final other room.
- A player could sleep after the hunter entered their room. Sleep now rejects the intruder with specific feedback. Sleeping while the hunter is inside another room preserves its route through that room's doorway and the common corridor.
- Simultaneous player elimination and hunter death incorrectly chose victory. The real breach followed by a living ally turret kill now produces defeat; eliminated-room turrets do not fire.
- An exposed-player catch ended the match without updating survivor life and elimination count. Assigned and unassigned capture regressions now verify exactly one elimination, dead assigned-room state, no terminal tick double count and no revival by claiming or sleeping.
- Displayed damage included overkill. A hunter with one HP now records one actual damage in team and per-room statistics.
- Resetting action timers discarded fractional elapsed time. An intermediate nearest-room scenario changed between victory and defeat solely with frame step. Timers now preserve bounded overshoot without banking idle attacks. Thirty seconds gives exactly **34 basic turret shots and 28 hunter attacks** at each of 0.02, 0.05, and 0.1 second steps. Separate idle/out-of-range regressions ensure this does not introduce bursts.
- The visual auditor discovered that an overlay consumed real map clicks, and new building tooltips used unsupported format strings. Agent B fixed both. The scene suite now sends actual `Input.parse_input_event` mouse motion/down/up through the viewport: it selects floor tile two, clicks the generator button and verifies the generator occupies that tile. All six building-effect descriptions are evaluated without script errors. Coordinates use the viewport's real stretch transform.

Additional defensive assertions reject negative and nonfinite payment amounts. Level-four generator, repair station, economy amplifier, heavy turret and enhancement relay effects are checked against actual gold, electricity, door HP and hunter HP, rather than merely checking their level counters. Upgrade ceilings for all six building kinds remain atomic. Hunter growth and retargeting are exercised directly.

## Baseline versus final gameplay

Both matrices use six starting rooms × seeds 1–12 × two strategies, with normal starting resources and the production purchase rules. Passive makes no purchases. Balanced uses the production configurable survivor policy, called by the test for the player's room. No test grants funds or reduces hunter HP in these natural runs. Each match has a 1,800 simulated-second ceiling.

| Matrix | Passive victories / defeats | Balanced victories / defeats | Median passive / balanced time |
|---|---:|---:|---:|
| Original commit | 48 / 24 | 72 / 0 | 81.7 / 81.7 s |
| Final | 0 / 72 | 72 / 0 | 68.8 / 141.0 s |

Baseline passive residents in four rooms could be carried by bot defenses. Baseline balanced residents reached only bed and door index one (displayed level two); none bought an advanced heavy turret or enhancement relay. The final hunter pressure, retargeting, survivor savings and emergency-repair policy make investment matter in every sampled room. All 72 final active matches built a heavy turret and enhancement relay, 71 upgraded a building, and some reached bed/door index four (displayed level five). Active player rooms spent **14,109 electricity total** across these matches and reached hunter level three. This establishes that advanced production and spending are exercised in natural play, not just rich-resource fixtures.

An intermediate nearest-room policy matrix lost all 60 runs. That was investigated rather than hidden: repair-first spending prevented saving for progression. Revised savings and emergency repairs fixed it. A separate legal six-turret-focused test policy also wins the nearest room; it generates ordinary resources and never alters production data. This is test automation illustrating viable choices, not a new in-game bot profile.

The final 27 frame-step matches cover rooms 1, 3 and 6 with passive, balanced and turret-focused investment at three step sizes. All nine strategy/room triplets keep the same terminal outcome. Small time differences remain because decisions occur on discrete steps; the largest observed time spread is approximately 2.3 seconds in the custom nearest-room turret strategy. No exact timing equality is claimed.

## Reproduce

From the checkout:

```sh
bash tools/check.sh
bash tools/check.sh --extended
# Equivalent individual bounded audit matrices:
godot --headless --path . --script tests/audit_matrix.gd
godot --headless --path . --script tests/audit_timesteps.gd
godot --headless --path . --script tests/audit_rates.gd
# Optional focused profile sweep:
godot --headless --path . --script tests/audit_matrix.gd -- --near-room-profiles
```

In this managed machine use the writable `XDG_DATA_HOME`, `XDG_CONFIG_HOME` and `XDG_CACHE_HOME` paths configured by `tools/check.sh`. The wrapper retains exit failures and scans error signatures because Godot can print script errors while returning zero. Final wrapper, rates and frame-step probes were rerun after the last production freeze. The 144-match final matrix uses the same final balance and timer logic; subsequent edits were feedback, the equivalent catalog-based initial door HP and exposed-catch elimination bookkeeping.

## Independent assessment

**Stability and automated coverage: 8.5 / 10.** Tested gameplay paths, adverse transitions, financial invariants and natural match termination are well supported. The audit found material bugs despite an initially passing suite and verifies their fixes. The score is a QA judgment, not a benchmark or claim that the whole game is finished.

Remaining limits: Linux cloud testing does not establish Windows behavior, physical audio quality, touch controls, or every graphics driver. Graphical audit evidence is separate. Synthetic real viewport input covers tile selection and one building-button hit path, while other menu checks primarily use Button signals. Forty property seeds and the match matrix are finite samples. The balanced automation wins every sampled room, so optimal-strategy difficulty and long-term replay variety still need broader human playtesting. The work does not establish exact Haunted Dorm numerical parity.
