# Survivor Rebirth desktop UI

These 1280×720 captures use Godot 4.6.3 on Linux with a rendered OpenGL viewport. The harness prepares an isolated profile with 40 RM Cash and claims a room in a seeded Endless game. It uses production buttons and callbacks for purchases, item equipment, settings, and construction.

| Screen | Evidence |
| --- | --- |
| Main menu | [Story, Endless and Campaign destinations](main-menu-720.png) |
| Shop | [Stock and prices](shop-720.png), [completed in-game purchase](shop-purchase-720.png) |
| Inventory | [Repair Kit equipped](inventory-720.png) |
| Settings | [Audio, display and guidance](settings-720.png) |
| Build | [Catalog with Needle and Dynamo](build-720.png), [Needle preview](build-needle-placement-720.png), [Dynamo preview](build-dynamo-placement-720.png) |
| Survivor preview disabled | [Original menu](fallback-menu-720.png), [original settings](fallback-settings-720.png) |

The Shop action spends 18 RM Cash and adds one Instant Repair Kit. The inventory equips that purchased kit. The Settings quality picker changes to Low through its production callback. The in-match checks exercise the Build menu, start Needle placement, cancel without spending Gold, then start Dynamo placement. The captures use a prepared wallet and room while buy and cancel use actual input.

Run from the project directory with a graphics display available. The tool saves to separate user profiles.

```sh
NIGHTFALL_LIVING_NIGHTMARE=1 NIGHTFALL_SURVIVOR_REBIRTH=1 NIGHTFALL_VISUAL_REBIRTH=1 \
  godot --path . --resolution 1280x720 --audio-driver Dummy \
  --script res://tools/capture_survivor_premium_ui.gd -- /tmp/nightfall-premium-ui

NIGHTFALL_LIVING_NIGHTMARE=1 NIGHTFALL_SURVIVOR_REBIRTH=0 NIGHTFALL_VISUAL_REBIRTH=1 \
  godot --path . --resolution 1280x720 --audio-driver Dummy \
  --script res://tools/capture_survivor_premium_ui.gd -- /tmp/nightfall-fallback-ui fallback
```
