# Phase 2 independent QA report

Agent C reviewed and tested persistent ranked progression, reward calculations, actual reward/loadout/settings UI interaction, and the upgraded hunter. Production fixes were owned by the coordinator. Tests used Godot **4.6.3 stable** in Linux cloud execution.

## Final executed checks

| Command after `godot --headless --path . --script` | Final result | Evidence |
|---|---|---|
| `tests/ranked_progression.gd` | **348 assertions, zero failures**, exit 0 | `docs/evidence/phase2/qa-ranked-final.log` |
| `tests/phase2_ui.gd` | **50 assertions, zero failures**, exit 0 | `docs/evidence/phase2/qa-ui-final.log` |
| `tests/phase2_hunter.gd` | **39 assertions, zero failures**, exit 0 | `docs/evidence/phase2/qa-hunter-final.log` |
| `tests/phase2_matrix.gd` | **48 matches: 24 victories, 24 defeats, zero failures/unresolved**, exit 0 | `docs/evidence/phase2/qa-matrix.log` |

Assertions and whole-match counts are different measures, not additive counts of independent gameplay scenarios. The coordinator runs existing regression and audio suites separately. This report does not substitute for those results or for the experience auditor's graphical/audio evidence.

## Persistence and rank coverage

All persistence tests use unique, isolated paths beginning `user://qa-ranked-phase2-` or `user://qa-phase2-ui-`. They never write the actual `user://profile.json`. The actual scene receives its isolated override through `NIGHTFALL_PROFILE_PATH`. Cleanup only removes the test's own unique prefix.

The persistence suite exercises missing saves, fresh defaults, multiple valid generations, previous-generation backup bytes, temporary-file consumption after successful rename, failed invalid-generation replacement, corrupted primary recovery, preservation of damaged bytes in quarantine, corrupted primary plus corrupted backup, standalone backup recovery, oversized files, and future-schema read-only preservation. It checks that a future primary is never silently replaced by a valid older backup and remains byte-for-byte unchanged after an attempted save.

Bounded typed-schema mutations cover invalid numbers, types, containers and nested snapshots. Forty deterministic valid-profile round trips vary XP, legal loadouts, settings and difficulty snapshots. Comparisons normalize JSON's numeric representation while checking exact match-ID values, difficulty, equipped perks and counter continuity. Failed writes through an absent parent directory report a warning and a failed equip save restores the previous in-memory slot.

Every rank threshold is checked immediately below and at promotion. Locked/unknown perks cannot equip; selecting another unlocked reward replaces the single slot; selecting the same perk unequips it. Loaded top-level perks are filtered to unlocked, unique, capped choices. Active snapshots are validated more strictly, including IDs and chronology. A returned snapshot cannot mutate the saved active selection. Wrong difficulty or wrong perk bonuses cannot settle that snapshot. A completed match cannot award twice in the same instance or after loading a fresh profile instance.

Known award fixtures verify **133 standard victory XP**, **166 hard victory XP**, and legitimate partial-defeat awards of **3 standard / 4 hard XP** for the same small-performance fixture after removing the victory/defense components. Breakdown components sum exactly to their total. Occupied-time and post-preparation eligibility boundaries are checked, including the exact accepted boundary. Theoretical standard/hard and defeat caps remain bounded. At the lifetime XP ceiling, an award is clipped to available capacity with an explicit negative `ceiling_adjustment`; a near-ceiling match grants exactly the remaining ten XP, and an at-ceiling match grants zero while continuing to save and reload correctly.

## Actual perk effects

Tests exercise each perk through production `MatchModel` and `RoomState` calculations:

- Pocket change adds five actual starting gold once, to the player only.
- Reinforcement increases both initial/current maximum HP by five percent and remains applied through door upgrades without erasing prior damage.
- Deep sleeper adds three percent actual occupied-bed income and produces nothing while awake.
- Clean current adds four percent actual generator output.
- Steady aim adds three percent actual projectile impact damage.
- Last light heals ten percent maximum door HP once after a nonlethal threshold-crossing strike. A later strike cannot reuse it, and a lethal strike cannot resurrect a destroyed door.

Unrelated bot rooms retain neutral initial gold and door HP. A claimed active room rejects reconfiguration. The hunter suite additionally verifies the automatic rescue call and actual pre-heal door-damage counter through real attack-state execution; direct helper math alone is not presented as integration proof.

## Actual scene/UI interaction

The UI suite instantiates the real main scene and dispatches real viewport mouse motion/down/up, including the viewport stretch transform. It tests the menu rank/XP display, Ranks & rewards navigation, all six loaded rank badge textures, next reward identification, visible locked rewards and ineffective clicks on them, equip selection and disk reload, three separate music/effects/ambient sliders, mute persistence, single-slot replacement, hard difficulty selection and Start Night.

The selected reinforced loadout changes the actual newly claimed room's HP. Changing the profile's next-match selection does not alter the active room. A controlled eligible terminal fixture then executes the real controller's result handling, produces the transparent post-match breakdown and a visible Gold promotion summary, and persists XP without duplicate terminal processing.

The promotion and rank fixtures supply XP/performance directly to isolate UI transitions. They do not claim that a human match earned those fixture points. Audio controls are verified as controls and persisted settings; this headless suite does not establish physical sound quality or claim that an agent listened to them.

## Hunter difficulty and navigation

The hunter suite verifies standard/hard initial HP, damage and speed; unchanged opening threat through the first 45 active seconds; a gradual eight-second later-stat ramp; correct completed-ramp HP/damage while preserving prior damage; bounded late attack interval and movement speed; actual strike counters; automatic once-only rescue; and destroyed-door breach progression.

Defense-aware target scores respond to actual turret/repair infrastructure while remaining capped. The hunter retains initial commitment, changes to a materially preferable valid alternative after its assessment window, and can escape an unproductive siege without teleporting. A two-window regression is explicit: a door falls from 600 to 200 HP in the first window, so the hunter correctly retains it and refreshes the assessment baseline to 200. If the second window stalls at 200, it can change target even to a stronger door. A sole valid target is retained without a pointless seek loop; a door within two strikes of destruction retains commitment. Navigation reaches occupied doors at legal per-step speed, and the synthetic stuck case recovers through target reassessment while preserving position.

## Bounded rank/difficulty match matrix

The final matrix runs two difficulties × six ranks × two player strategies × seeds 7 and 8: **48 matches**. Each rank equips its newly unlocked perk, with the normal one-slot limit. Starting gold, economy, damage and hunter health are not overridden. Active automation uses the production balanced purchasing policy; passive makes no purchases. Every match must terminate within 1,800 simulated seconds. The test also checks resource finiteness/nonnegativity and award bounds.

| Difficulty | Active victories / defeats | Passive victories / defeats | Highest hunter level |
|---|---:|---:|---:|
| Standard | 12 / 0 | 0 / 12 | 3 |
| Hard | 12 / 0 | 0 / 12 | 3 |

Active standard matches finish approximately **127.9–151.0 seconds** and hard matches **146.2–156.7 seconds** in this sample. Passive defeats occur approximately **40.5–91.3 seconds**. Passive rewards are **4–10 XP**, while active victories receive **160–342 XP**. Master rescue triggers in natural sampled matches but does not guarantee passive survival.

An earlier matrix exposed six standard passive victories carried by bots while the player remained untouched. That observation was reported rather than hidden; progress-based siege escape removed those sampled carries. The prior matrix is preserved as `qa-matrix-before-siege.log`. These finite seeds show useful pressure and viable active play, not comprehensive balance, human enjoyment, or difficulty guarantees across every room and strategy.

## Bugs found and corrected

The first ranked suite executed 96 assertions and reported seven real failures. `qa-ranked-initial.log` preserves them. Fixes reject overflowing sequence IDs, fractional active/award IDs, locked/unknown/over-cap active loadouts, and mismatched model bonuses at settlement. Corrupt JSON initially emitted engine errors despite recovery; the parser now handles it through an error return and a user warning. Expanded checks then found reversed active/previous-award chronology; both decoding and settlement reject stale/replayed sequence IDs. A final valid-boundary review found that reaching the allowed lifetime XP maximum could otherwise make the next award unsavable; explicit clipping and a transparent adjustment now keep that state persistable.

There was also an intermediate test fixture issue: comparing an entire active snapshot dictionary treated JSON floating-point IDs as a different Variant representation from in-memory integer IDs. The fixture was corrected to compare validated numeric ID values and each semantic field. This was not counted as a production bug. A cosmetic rewards-heading text change similarly required updating the UI locator; the real navigation and interaction assertions remained intact.

## Limits

Linux cloud checks do not establish Windows Phase 2 execution, all storage failure modes, power-loss durability, concurrent writers, every graphics driver, or physical audio playback. Atomic generation/backup behavior was tested through actual saves, failures and reloads, not process termination during an OS write. Exactly-once behavior is verified for the supported single local profile and monotonic match sequence; this is not an anti-tamper or multi-device synchronization system.

No Windows release export or public publication was performed by this QA work. Graphical and rendered-audio observations belong to the separate Phase 2 experience review. The existing gameplay regressions remain the coordinator's final integration gate.

## Coordinator final integration follow-up

The final regular run passed the original independent tests again. Two additional reward-description column assertions bring Phase2UI to52/0. A separate-process write→fresh-read test preserves866XP/Gold, Deep sleeper, three mix values and mute while rejecting duplicate settlement. Normal application startup now uses graceful audio drain. Final logs: `regular-final.log`, `extended-final.log`; the latter includes231 complete match executions across the four match suites. Full-load audio cue saturation, Last light text overflow and a SceneTree quit-handler integration error were fixed and rerun; historical failing logs remain labeled separately.
