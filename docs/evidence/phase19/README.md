# Phase 19 · Living Dorm verification

## Desktop Godot evidence

- Low at 960×540. [Healthy door](hud-960/door-healthy.png), [critical hit](hud-960/door-critical.png), [paid repair](hud-960/door-repaired.png), [room effects](hud-960/room-effects.png), [item inspection](hud-960/item-details.png)
- Standard at 1280×720. [Door damage](hud-1280/door-critical.png), [Settings](hud-1280/settings.png), [Shop](hud-1280/shop.png), [Inventory](hud-1280/inventory.png)
- Godot gameplay capture. [Performance baseline](before-needle-combat.mp4), [Phase 19 Low](after-needle-combat.mp4)
- A live-input tutorial at each window size verified all 19 steps and the return to Story preparation. These show the real repair control at [960×540](hud-960/tutorial-door-repair.png) and [1280×720](hud-1280/tutorial-door-repair.png).
- The staged screenshot fixture uses the real door damage and manual repair transactions. Looking at equipped stock did not spend an item. Explicit Use consumed exactly one.

## Soundtrack

Five actual Godot master-mix excerpts capture the preparation scores for
[Abandoned Dorm](soundtrack/dorm.ogg), [Haunted Hospital](soundtrack/hospital.ogg),
[Forgotten Hotel](soundtrack/hotel.ogg), [Underground Lab](soundtrack/lab.ogg)
and [Cursed Mansion](soundtrack/mansion.ogg). The map palettes rearrange the
existing recorded soundtrack. They route distinct preparation and contextual
approach, attack, danger and recovery choices. The recordings cover preparation
and reuse some pieces across other phases. The two gameplay clips are silent.
[Observed score routing](soundtrack/score-routing.json)

## Performance

Figures are milliseconds from actual rendered 120-frame samples on Linux
llvmpipe with Godot 4.6.3. The baseline is `a941901`. Each matched seven-machine
enlarged-grid fixture fired five shots and removed 140 Hunter HP. The pilot
was disabled in this comparison.

| Preset | Before median / p95 / p99 | Phase 19 median / p95 / p99 | Draw calls |
| --- | ---: | ---: | ---: |
| Low 960×540 | 31.28 / 43.12 / 47.26 | 30.63 / 38.00 / 42.60 | 301 → 306 |
| Standard 1280×720 | 59.82 / 73.36 / 77.97 | 58.38 / 71.93 / 75.52 | 556 → 556 |

Additional Low pairs ranged from 27.85–34.97 ms median on the baseline
and 27.62–31.31 ms on earlier Phase 19 checkpoints. Linux variance
overlaps the measured difference. Native Windows frame pacing remains open.
[Raw benchmark receipts](benchmarks/)

## Main Hunter targeting

The sample 90-match matrix reached all normal win/loss states across ten
families, five themes, three difficulties and three policies in both arms.
The room starts from normal wages with the survivor staged at the bed.
The changed model still pays all ordinary expenses.

| Difficulty | Active wins before → after, out of 20 | Passive wins before → after, out of 10 |
| --- | ---: | ---: |
| Standard | 18 → 19 | 2 → 3 |
| Hard | 10 → 14 | 1 → 1 |
| Hell | 10 → 6 | 1 → 0 |

Mid-siege retargets fell from 104 to 64. In a 15-pair trace at the preceding
checkpoint, the Hunter chose a different opening room in four matches.
Median distinct attacked rooms stayed at three. Human rooms were sieged
in 12 versus 14 matches. The focused tests cover commitment under meaningful
door damage and rerouting from a stalled siege to a reachable weaker door.
Both established item-free Hell Labyrinth 10358 Room 2 openings still won.
These policies expose a Hell difficulty increase worth owner testing.
[Old matrix](benchmarks/matrix-0.json) · [Final matrix](benchmarks/matrix-1.json) ·
[Detailed trace](benchmarks/trace-1.json) · [Known Hell openings](benchmarks/hell-labyrinth.json)

## Experimental Shadowlings

The Stalker pilot summons from a valid exterior node after a call and uses
ordinary routes, door damage and turret projectiles. It excludes the main
Hunter's planned or active siege room, waits when no eligible target remains,
and imposes a six-living cap. No lifetime despawn or new permanent reward.
The 197 model checks include a Needle projectile kill, exact effective damage,
and persistence beyond five simulated minutes.

The stress fixture stages 0, 1, 2 or 5 living Shadowlings in legal map space.
Low p99 was 39.37 ms without one, 49.45 ms with one, 51.06 ms with two and
39.35 ms with five. Standard p99 was 97.31, 128.42, 90.01 and 79.24 ms.
These are single samples per load. The crowds can visually bunch at the door.
The pilot remains disabled in the Windows launcher and has not been expanded
to other families. [Staged siege view](mini-hunters/five-shadowlings.png) · [Stress receipts](mini-hunters/)

## Save and package checks

Wall-side fixtures moved in 273 of 300 sampled layouts. Door, bed, reserved
routes and pads remained fixed. Existing serialized construction rules and
layouts round-trip. There is no new active combat save format. Standard
regressions and the separate Phase 19 Story lobby pack verify the important
fallback and opt-in paths. The legacy scene smoke assumes the fallback
`Start Game` menu and is run with the preview flags off.

[Regression logs](regressions/) · [Windows export receipt](pack/windows-artifact.json) ·
[SHA-256](pack/SHA256SUMS.txt) · [Windows playtest instructions](../../LIVING_DORM.md)
