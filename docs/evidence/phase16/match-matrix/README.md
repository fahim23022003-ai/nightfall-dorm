# Phase 16 complete Story match matrix

The checkpoint is `07b459be3ed0e9b0721464e73c2927f77e8cd9cd`. Each arm runs 35 matches. The 30 primary fixtures cross all ten topology families with Normal, Hard and Hell. Each difficulty covers all six ordinary Hunter archetypes. The full matrix has nine early levels (1–16), 15 mid levels (17–34), and 11 late levels (35–50). Five exact seed-and-policy twins run the assisted defense with an empty item loadout.

A disposable profile stages the Story position and the corresponding prerequisite records. Every measured match uses the real Story entry, deterministic match attempt 100, ordinary settings, production map generation, shared exterior spawn, legal walking, a contested claim, and real sleep. The launch config mirrors real Story initialization, including the candidate encounter hook. Bots use production AI. After the start there are no injected wallets, upgrades, moves, HP, damage or terminal outcomes.

The match policy acts every six 0.15-second model ticks. Its six primary choices include balanced operations, early turrets, economic rush, repair-heavy defense, an earned item with the balanced policy, and an item-free mixed defense. The separate item-free twins use the same balanced policy as the assisted case. The checkpoint earns one Gold item through an achievement after a full warm-up victory. This item is used through the real inventory transaction and the same finite inventory snapshot is copied into each disposable profile. The warm-up also buys a Battery from earned cash. The matrix does not use it.

Each case records terminal outcome, match duration, per-room attack/target time, door damage and Hunter damage, Hall recovery, encounter events, evolution, movement diagnostics, wallets, ledger, item use, and Story settlement. The test verifies that the resulting profile reloads with matching Story, inventory, cash and XP and refuses to award the same result twice. The test reports bots that have yet to reach a bed when a human loss ends a match. The small fixed-case sample does not estimate human win rates.

## Matched results

| Difficulty | Checkpoint victories / matches | Phase 16 victories / matches |
| --- | ---: | ---: |
| Normal | 9 / 11 | 11 / 11 |
| Hard | 7 / 12 | 8 / 12 |
| Hell | 1 / 12 | 4 / 12 |
| **All fixtures** | **17 / 35** | **23 / 35** |

All 70 runs reached a terminal result, settled it and reloaded the profile. At each paired start, the model produced the same map hash, seed, spawn, claimed room, time-to-bed, and starting wallet. Seven checkpoint losses became wins, and one win became a loss. All five NPCs had reached beds at the end of all 35 candidate runs and 33 of 35 checkpoint runs. The two checkpoint exceptions lost before NPC 5 had claimed the remaining room.

The mean number of rooms struck rose from 3.63 to 4.40 per match. Successful Hall visits rose from 12 to 16 and Reaper transformations from 14 to 17. The sampled Hell finale was a defeat in both builds. It lasted 129.00 seconds with Evolution 7 at the checkpoint and 327.15 seconds with Evolution 10 and the Reaper in Phase 16. Both arms recorded zero illegal Hunter motion or speed-budget violations, and all five assisted cases consumed the earned Gold item.

The single win-to-loss change was the Hard Level 29 Electric Ghost in Twin Wings. Both runs claimed Room 4 and spent the same earned Gold item at 20.70 seconds. The checkpoint never directly targeted Room 4 and allied fire killed the Reaper. Phase 16 broke Rooms 3 and 6 before attacking Room 4 at 223.65 seconds. It broke the player's door at 239.85 seconds and defeated the player at 242.10 seconds. The player dealt 2,576 Hunter damage and paid for four manual repairs. The longer preparation and different NPC assignments make this a comparison of the complete encounter, with no isolated causal claim for an individual change.

[Per-map, per-Hunter and per-policy totals](comparison.json)

## Reproduce

The fixture path and result paths are absolute. Set a fresh `XDG_DATA_HOME` for each invocation. Use `git archive` of the exact checkpoint, run headless import, and pass that checkout as `--path` with the same absolute harness script. Record the common inventory in the checkpoint first.

```sh
godot --headless --path /tmp/nf-before --audio-driver Dummy \
  -s /abs/check_phase16_story_matrix.gd -- earn /tmp/nf-earned-stock.json
NIGHTFALL_PHASE16=1 godot --headless --path . --audio-driver Dummy \
  -s tools/nightmare_tactics/check_phase16_story_matrix.gd -- \
  /tmp/nf-candidate.json /abs/fixtures.json /tmp/nf-earned-stock.json 0
```

The optional final argument caps the number of cases for independent shards. Use `summarize_phase16_story_matrix.py` with one or more JSON paths per arm to produce a matched comparison.
