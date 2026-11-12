# Independent QA C — Phase 5D-4 focused acceptance

TESTED: **10 suites, 7,357 assertions, zero failures; every process exited 0** in Linux Godot 4.6.3 (`7d41c59c4`). Exact final logs, source hashes, limitations and fixture corrections are in `qa-source-acceptance.json`. These include repeated safety assertions; 7,357 is not a count of independent playthroughs.

| Executable test suffix (`tests/phase5d4_qa_*.gd`) | Checks | Evidence |
|---|---:|---|
| `ui` | 818 | `qa-ui-all12-held-final.log` |
| `evolution` | 648 | `qa-evolution-third.log` |
| `boss` | 153 | `qa-boss-cleanup-final.log` |
| `save` | 264 | `qa-save-final.log` |
| `defenses` | 972 | `qa-defenses-final.log` |
| `challenge` | 13 | `qa-challenge-final.log`, six process traces, `qa-code3-summary.json` |
| `items` | 208 | `qa-items-initial.log` |
| `ui_branches` | 1,625 | `qa-ui-newbranches-held-final.log` |
| `ui_threat` | 76 | `qa-ui-minion-home-accepted.log` |
| `combat` | 2,580 | `qa-combat-final.log`, `qa-integrated-phases.json` |

## Actual integration evidence

- Actual mouse events on the three rightmost palette rows across all five maps: one successful purchase on rapid double-click, no unintended upgrade, no stuck preview, and no spending when Escape cancels a held BUILD before release. Fixed bottom-panel geometry, camera, player position and model/RNG remain stable during inspection and previews.
- All six new machine cards, both exclusive branches, all five maps: 60 real UI purchase/choice/confirmation/sale scenarios. The selected preview has original branch art and numeric changes; preview selection is free. A held Confirm followed by Escape cancels without spending; reopening works. Rapid Confirm charges once, paid upgrades reach 10, Level 11 is unavailable, UI sale transfers the actual investment refund and the same pad reopens.
- Genuine main-Hunter and registered-undead contact kills share one canonical owner ledger. Fake presentation events, nonexistent actors, remote attacks, intact doors, invalid exposed-NPC flags and repeated victims earn nothing. Six identities cap awards; 45 seeded pairs of genuine kill sequences reproduce choices and collectively reach all 15 buffs. All 15 mechanical effects are independently exercised. Exposed-player death credits its buff before terminal cleanup.
- Ten live undead is a strict cap. Actual selected-undead damage cannot harm another actor; reused slots receive fresh IDs, so stale projectiles cannot hit replacements or the boss. Forty cycles of ten summons keep navigation routes bounded and cleanup removes slot routes.
- All six new roles × two branches × coupon at base/branch/late upgrade: actual paid transactions, fees and separate Gold/Electricity ledgers reach Level 10. Invalid Level 11/repeated branch and duplicate sale are atomic. Real paid repair/shield/lure operations spend their stated resources, operating spend stays outside capital refunds, empty wallets do not produce free effects, and sell/rebuild cannot reset shared operation cooldowns. Real flame/frost/shock homing shots affect correct single/multiple undead, actual DoT and bounded slows.
- Completed Soul Reaper drains exactly half of the *current* fractional Gold and Electricity after its warning, once. Real damage, freeze, displacement or victim loss interrupts without resource loss. Cooldowns prevent immediate retry. Player-only Guardian/Feather cannot trigger on NPC damage; automatic player rescues work even when the main Hunter targets an NPC. Seal counters real player/global warnings and does not cancel an unrelated NPC-only resource channel.
- Rules Judgement fails manual item activation without consuming stock, expires, and restores use. Final Judgement preserves stored resources, generates nothing while locked, restores normal production without catch-up, and cannot overlap the other lock.
- Three actually purchased Needle turrets launch same-batch homing shots through prepared HP-threshold fixtures on all five maps. The 55% crossing immediately begins one readable transformation without healing; later packets cannot kill it in the same batch. Full `MatchModel.tick` reaches Phase II at 35%, then the one-time 10% combined domain before the finite guard expires. Each scenario runs 25 more seconds of actual domain navigation/combat; only its selected room receives damage. Evidence records about 909–1,812 px of real navigation and measurable selected-room pressure, rather than only isolated cast methods. These prepared thresholds are **not** naturally earned difficulty evidence.
- Actual NPC and player domain targets, giant scythe pressure, limited destruction attempts, no extra undead, valid chosen-room attacks, suppression of foreign projectiles/burns/Inferno/armed traps, and failed foreign offensive items without stock consumption. Timeout, boss death, target death and terminal paths clean state. Actual lethal burn/trap clears undead/locks immediately before another update; central victim death immediately clears its domain/scythe.
- All 20 existing consumables activate through actual valid transactions with the new offensive machines; all 20 preserve stock on Rules lock, and actual stock reloads correctly. New flame/frost/shock support Overdrive and owned-hit Inferno DoT on undead. Practice runs every selected item/new-building case without changing a real permanent profile file.
- Actual undead contact updates own warning, the correct teammate identity/door status and own-danger spectator label on all five maps. Camera observation changes no ownership/player/resource state; audio listener stays at the player's bed. The real Home mouse button works with the roster expanded, and keyboard Home also returns safely. Despawn clears the warnings.

## Save and challenge evidence

Three frozen genuine profiles from Phase 5D-2 and Phase 5D-3 Normal/Hell preserve earned wallets, structural and machine tiers/branches, actual investment, ownership, life state and inventory. Migration writes a writable ruleset-3 checkpoint. A mid-wave interruption rewinds both victim death and its buff/credit together; a completed checkpoint preserves both atomically. Stripped or mismatched current-version ledgers are rejected. All six new paid Level 10 machines, per-machine live cooldowns and shared shield/lure/repair cooldowns survive actual save/reload. Historical Challenge rulesets 1/2 remain archival, readable and writable records; they cannot silently play with the new rules.

Six fresh actual-scene Challenge workers compare three Hell maps using beginner versus progressed profiles (20,000 XP, large inventory/cash and equipped perks). Under the same legally paid scripted strategy, complete traces are byte-identical. Two map pairs genuinely reach Reaper Phase I, a ten-undead assault and other real casts; the third loses before transformation. This supports equivalent conditions on this Linux engine/ruleset, not unrestricted cross-platform timing determinism. Each run uses a distinct temporary profile.

## Confirmed failures and corrections

1. **Fixed and retested:** selling a live Decoy then rebuilding the same kind on the same pad could rebind the original lure. Exact-instance identity and immediate sale/destruction invalidation now cancel the old lure while preserving its shared cooldown.
2. **Fixed and retested:** Escape while an enabled BUILD was held could cause a paid button callback before mouse release. Pre-GUI cancellation and consumed eventual release prevent this. The same regression is tested against every new exclusive Confirm in all 60 branch scenarios.
3. **Fixed and retested:** rapid packets could skip the promised transformation after its first clipped hit; actual same-batch homing shots now verify immediate transition. A finite 3.3s final guard permits the real ultimate warning to complete.
4. **Fixed and retested:** a lethal item hit could otherwise leave transient boss actors/locks until a later update; immediate death and victim cleanup are exercised without granting an extra tick.

Initial failing logs are retained. Other failures were fixture issues and are explicitly listed in the acceptance manifest; they were not resolved by weakening product behavior. Nominal prices pass through existing Godot `Vector2` float32 arithmetic (observed discrepancies below 0.001 resource). Actual sale transfer must equal the quoted separate currencies within `1e-8`; the test does not silently round currencies to integers.

## Boundaries

UNVERIFIED: native Windows hardware input, subjective fear/music/SFX quality, human readability and enjoyment. Input tests inject real Godot events with the double-click flag; they do not prove Windows mouse-driver behavior. D owns rendered and actual audio captures; A owns naturally earned progression and difficulty strategy tests. Root owns final immutable complete regular/extended regressions, final report, commit and verified GitHub push. This focused QA acceptance does not substitute for those gates or claim Phase 6 completion.
