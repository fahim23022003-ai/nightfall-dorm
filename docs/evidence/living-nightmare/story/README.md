# Living Nightmare Story Mode

The Windows preview flag `NIGHTFALL_LIVING_NIGHTMARE=1` exposes **Continue
Story**. The prep screen lets the player change difficulty, edit their
two consumable slots or their permanent perks, and launch the current
mission. Endless keeps its own mode. **Extras → Story Archive** offers
chapter openings, the final ending and the classic five Campaign stages.

The [50-mission catalog](catalog.md) combines authored Hunter encounters,
five existing settings, all ten V2 topology families and deterministic
per-mission seeds. The first chapter allows 44 seconds of preparation,
chapters 2–3 allow 42, and later chapters use the current 40-second
baseline. Each mission selects one of the five existing encounter
baselines and the corresponding boss eligibility per difficulty. The
final Standard mission permits the Reaper. Story maintains the ordinary
victory condition and existing combat values. Preparation and results
deliver the narrative in brief text. The archive can replay these
briefings.

Normal, Long Night and Hell store independent positions, highest clear,
last clear and latest settlement. A defeat moves one level back, with
floors at Level 1 and every five completed levels through 45. Level 50
ends a track. First-clear XP is shared across difficulties, including
historical clear credits for the first five missions. Legacy migration
uses only explicitly recorded contiguous wins for each mode and
preserves the original profile in a separate backup before writing.
A retry uses the same seed and layout for its mission.

## Real Godot captures

The capture harness uses an isolated profile and the game's own menu and
settlement screens. It invokes the connected buttons, runs normal
income and construction commands, and lets Godot resolve all shown
battles through ordinary combat. The survivor starts at the test
bed in the two defense cases. Levels 17 and 50 begin with prefilled
progression to reach the screenshots without playing all prior levels.

| Capture | Result |
| --- | --- |
| [Main menu](main-menu.png) | One primary Story entry and separate Endless entry |
| [Level 01 prep](level-01-preparation.png) · [Long Night track](hard-track.png) | Difficulty, encounter, checkpoint, loadout controls |
| [Level 01 victory](level-01-victory.png) | Ring, clear at 484.60s, advances to Level 02, promotion to Silver |
| [Chapter 02](chapter-02-opening.png) | The briefing for The Rooms Remember |
| [Level 17 defeat](level-17-defeat.png) | Branching, ordinary exposed-survivor defeat at 90.60s, returns to Level 16 |
| [Level 50 prep](level-50-preparation.png) · [Dawn survived](level-50-victory.png) | Hybrid, actual Reaper transformation, victory at 365.00s, track complete |
| [Story archive](story-archive.png) | Accessible chapter pages and final ending |

The [motion capture](story-motion.mp4) shows the native victory count-up,
chapter opening reveal and defeat count-down. It is a silent UI capture.
[Match receipts](capture.json) · [Capture log](engine.log)

Reproduce with Godot 4.6.3 from a graphical session using an isolated
`XDG_DATA_HOME`.

```sh
godot --path . --resolution 1280x720 --audio-driver Dummy --disable-vsync \
  --script tools/capture_living_story.gd -- /tmp/nightfall-living-story
```
