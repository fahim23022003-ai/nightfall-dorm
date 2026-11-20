# Nightmare Maps V2 independent QA

The seed matrix ran 600 maps across five themes. It covers 500 theme, family and seed combinations and 100 ordinary automatic family selections. All ten families appeared automatically. Godot passed 92,788 assertions and 10,200 legal path probes. Each map had six separate rooms, four reachable cardinal Halls, working bed access and space for different machine sizes. The checks validated intact door blocking, breached door entry, real paid grid placement and cutout rejection without a charge. Every Hall faced its named cardinal direction within the outer 30% of the room extent or beyond. 950 of 2,400 Hall centers sat short of the furthest room edge in their named direction, using a recess or offset on that side of the map. [Full seed metrics](diversity.json) · [Geometry log](diversity.log)

## Structural diversity

The sample had 600 distinct coordinate-free exterior graph fingerprints across all 600 maps. The fingerprint compares vertex degrees and four rounds of neighbor signatures independent of graph indexing. The raster test sampled occupied floor, corridors and Halls in a tight 18×18 map extent. It flagged 0 of 595 adjacent within-theme pairs at the stated threshold of matching loop rank and 82% occupied-area overlap. This threshold compares the captured orientations, and the results describe the sample. Room adjacency, pairwise spacing, room area, nearest Hall entrance, exact Hunter approach distance, outer aspect and symmetry are recorded per seed. The largest floor appeared at every room number, from 85 to 118 times across the six positions.

| Family | Maps | Graph signatures | Loop rank | Branch junctions | Width / height | Tested alternate paths | Earned defender wins |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Ring / Courtyard | 59 | 59 | 1–3 | 10–17 | 0.71–1.60 | 5/5 | 4/6 |
| Branching / Fork | 61 | 61 | 0–3 | 9–14 | 0.45–2.62 | 2/5 | 4/6 |
| Scattered Asymmetric | 59 | 59 | 0–4 | 9–15 | 0.59–1.88 | 4/5 | 6/6 |
| Long Spine | 58 | 58 | 0–4 | 11–16 | 0.55–1.99 | 5/5 | 5/6 |
| Zigzag / Staircase | 58 | 58 | 0–4 | 9–15 | 0.64–2.04 | 4/5 | 6/6 |
| Radial / Spokes | 60 | 60 | 0–4 | 8–15 | 0.38–2.43 | 5/5 | 5/6 |
| Twin Wings | 64 | 64 | 2–4 | 11–16 | 0.54–2.13 | 5/5 | 2/6 |
| Labyrinth | 62 | 62 | 1–9 | 10–19 | 0.56–2.54 | 4/5 | 5/6 |
| Asymmetric Courtyards | 58 | 58 | 2–5 | 12–19 | 0.69–1.66 | 5/5 | 3/6 |
| Mixed Hybrid | 61 | 61 | 0–8 | 9–19 | 0.59–2.22 | 5/5 | 5/6 |

Loop rank counts independent cycles in the saved exterior graph. The alternate column counts five targeted maps per family in which an actual alternative path was found against the sampled origin and destination pairs. Sparse families can legitimately have no alternate for a given pair. The Hunter’s shortest spawn-to-door distance ranged from 126 to 2824 world units. Its shortest spawn-to-Hall path ranged from 168 to 3768 units.

## Complete matches

The same 30 fixtures ran with three policies. All 90 Campaign matches reached victory or defeat through game ticks. Each fixture used ordinary income and model transactions after placing the survivor at the bed for the normal sleep action. Passive players spent nothing while NPC teammates acted normally. The runs recorded 49 completed Hunter recoveries and 315 target changes, with zero invalid movement, broken ledgers or over-budget Hall attempts. Players won with an earned strategy in every family. The spread describes these automated strategies and seeds. [Match outcomes and combat events](matches.json) · [Execution log](matches.log)

| Difficulty | Passive wins | Balanced wins | Needle-first wins |
| --- | ---: | ---: | ---: |
| Standard | 2/10 | 10/10 | 10/10 |
| Hard | 2/10 | 9/10 | 5/10 |
| Hell | 1/10 | 7/10 | 4/10 |

## Persistence and edge seeds

All 62 checks passed. Disk tests used the existing PlayerProfile API and normal sealed wave checkpoint. V1 resumed while V2 was enabled. V2 resumed with both previews disabled. Both preserved their exact geometry, purchased machine identity, footprint, investments and Hall recovery budget. An illegal move into a cutout preserved the machine, and a legal rotated move and undo preserved each balance. The next wave retained the saved map. The fixed checkpoint stayed fixed. The generator and codec round-tripped zero, negative and signed 64-bit edge seeds. Malformed family metadata, missing Halls and invalid links were rejected. [Profile and edge-seed log](persistence.log)

## Reproduce

Run from the repository root with Godot 4.6.3. The harnesses select the appropriate preview and isolate save fixtures.

```sh
godot --headless --script tests/nightmare_maps_v2_diversity.gd -- /tmp/nightmare-v2-diversity.json
godot --headless --script tests/nightmare_maps_v2_matches.gd -- /tmp/nightmare-v2-matches.json
godot --headless --script tests/nightmare_maps_v2_persistence.gd
```
