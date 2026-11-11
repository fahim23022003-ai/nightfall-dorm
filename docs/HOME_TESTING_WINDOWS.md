# Test Nightfall Dorm at home in Godot 4

Source repository: https://github.com/fahim23022003-ai/nightfall-dorm  
**Branch: `work` — select this branch, not `main`.**

Cloud-verified editor: **Godot 4.6.3 stable, standard Windows x86-64 build**. The project uses GDScript; .NET, Python, export templates and paid assets are not required to play in the editor. Other Godot 4 versions have not been validated for this checkpoint.

## Download and run

1. Sign in to GitHub with the account that can access this private repository. Open the repository link above.
2. Open the branch selector, select **work**, then choose **Code → Download ZIP**. Alternatively open https://github.com/fahim23022003-ai/nightfall-dorm/tree/work first. Do not download an older build ZIP or the `main` branch.
3. Extract the entire ZIP to an ordinary local folder, for example `C:\Games\nightfall-dorm-work`. Keep `project.godot`, `scenes`, `scripts` and `assets` together. Do not import from inside the ZIP.
4. Open Godot **4.6.3 standard**. In Project Manager choose **Import**, browse to the extracted `project.godot`, then choose **Import & Edit**. Wait for first-time asset import to finish; Godot creates its own `.godot` cache.
5. Press **F5 / Run Project**. Use F5 rather than running an arbitrary individual scene. The configured main scene is `res://scenes/main.tscn`, attached to `res://scripts/game.gd`.
6. Click **Start Game**, optionally equip an unlocked boost and choose **Night watch** (normal) or **Long night** (hard), then **Start Night**. During the 30-second preparation, walk through an open doorway into a vacant room. Press **E** to claim it, move near its bed, then press **E** again to sleep and lock the door. The tutorial can help locate the bed. You remain in bed for that match.
7. Click an empty marked floor pad, choose **Needle turret**, then click **Confirm placement** while the preview is green. Construct a **Dynamo** when affordable to produce electricity. Use the bottom bed/door summaries for upgrades. Hover disabled actions to see resource/prerequisite reasons.
8. Defend against the hunter. Hunter death gives victory; your elimination gives defeat. Test **Restart** and **Main menu** on the result screen. Use Godot's **F8 / Stop** to stop the running project.

Optional Git download instead of ZIP, in PowerShell with Git installed:

```powershell
git clone --branch work --single-branch https://github.com/fahim23022003-ai/nightfall-dorm.git
cd nightfall-dorm
git log -1 --oneline
```

Use your normal private GitHub sign-in if prompted. The final checkpoint response reports the pushed commit. Source gameplay is preserved from feature commit `f497ca105debe69934fe9fc6c0ed3c8a125d9b44`; later checkpoint commits update documentation/evidence.

## Controls

| Input | Action |
| --- | --- |
| WASD or arrow keys | Move the awake player; walking stops after sleeping |
| E | Claim a vacant room from inside; interact near its bed to sleep/lock door |
| Left click on an empty owned floor pad | Select a tile and open building cards |
| Left click on a building card | Begin a placement preview; no resources deducted yet |
| Mouse movement / left click on another owned pad | Preview or select the intended placement tile |
| Confirm placement | Construct and spend resources once, only if valid |
| Cancel or Escape while previewing | Cancel without spending |
| Left click on an existing machine | Open that building's upgrade inspector |
| Bottom Bed / Door summary buttons | Open bed / door upgrade and repair controls |
| R or Repair button | Buy an immediate door repair when allowed and affordable |
| M or Map / Focus button | Switch focused play / whole-dorm overview |
| Mouse wheel over the world | Adjust focused-camera zoom; overview stays at its map zoom |
| G or Help button during a match | Toggle the short tutorial |
| Escape | Cancel preview first, close inspector next, otherwise pause/resume |
| HUD pause button | Pause/resume; overlay also offers return to main menu |
| Settings in main menu | Sound volume, fullscreen and first-night tutorial |
| Result screen buttons | Restart with clean state or return to main menu |

Keyboard shortcuts apply while the game window has focus. Click the running game if the editor receives your keys. Fullscreen can be changed through Settings; no extra fullscreen hotkey is implemented.

## Suggested first playtest

- Open How to Play and Settings, then start. Confirm that movement, walls, bed/furniture collision and room claiming feel clear.
- Sleep: gold should start rising only while occupied. Check bed upgrade income, door durability and the separate electricity counter.
- Try a build card, cancel it, then confirm a valid placement. Cancellation must not charge; occupied tiles and unaffordable purchases must reject.
- Build a turret and Dynamo; later try Repair station, Dream amplifier, Target relay and Arc turret as their prerequisites allow. Click built machines to upgrade them.
- Watch five autonomous bots, travelling shots, actual hunter damage and your door's warning/HP/repair behavior. Test M, wheel, G and pause.
- Play through a result, restart and ensure the room/resources reset. Try a passive match to observe defeat; seeded automation reaches both outcomes, but a particular human match is not guaranteed to reproduce a scripted outcome.
- If something fails, note Godot version, room number, approximate match time, action and exact error text from Debugger/Output. A screenshot is useful if available.

## What is verified and what remains open

The project imported and passed actual Godot headless scene/gameplay tests from a fresh Git-only source snapshot for this home checkpoint. Original assets are tracked, and runtime imports regenerate locally; `.godot`, previous exports and test artifacts are intentionally ignored. No external runtime downloads are needed.

Prior actual Linux/Xorg/Mesa captures show the menu, six room themes, focused/map cameras, build cards, green/red placement, upgrade stages, hunter door warning, projectiles, impacts and both result screens. Two normal-fund automated rendered matches reached one victory and one defeat. Prepared resource/level/attack fixtures are labeled separately in [VISUAL_REDESIGN_REPORT.md](VISUAL_REDESIGN_REPORT.md). Graphics were not rerun for this documentation-only checkpoint.

**Not verified graphically on the target platform:** native Windows/GPU execution, high-DPI and other aspect ratios, audible sound/mixing, and every animation frame/direction. Cloud captures do not prove human enjoyment or target-hardware performance. Touch/controller/mobile play is not implemented. Bots/hunter have limited directional animation, settings/rank/XP/equipped boosts now persist in `user://profile.json`, and small art cleanup remains. The map has six rooms and one hunter; turret targeting is distance-based without wall occlusion. Exact Haunted Dorm parity remains unverified because requested sources were inaccessible. See [KNOWN_LIMITATIONS.md](KNOWN_LIMITATIONS.md).

No new executable export, public release or deployment is part of this checkpoint. Test the source in Godot using the steps above; older export records remain historical.

## Phase 2 home checks

- On the menu open **Ranks & rewards**. A fresh profile starts at Bronze with Pocket change unlocked but unequipped. Equip it or leave the slot empty; one slot is allowed. Higher rewards need the displayed XP thresholds. Re-clicking the equipped reward removes it.
- In **Settings**, adjust Music, Effects and Ambient separately and test Mute. Listen for the separate menu track, calm/danger crossfade, nearby hunter movement, door impacts/cracking/breach, turret/impact and rank/result cues. Cloud captured non-silent mixed audio but did not listen through Windows speakers.
- Complete a match and check the transparent XP breakdown. Eligible play needs20 seconds sleeping and10 seconds after hunter arrival. Wins grant120 base plus capped performance; defeats grant35% performance capped80. Restart/returning to results must not grant the reward again.
- Close and reopen Godot's game. Verify rank XP, equipped reward, volumes/mute, tutorial and fullscreen preferences survive. Difficulty can be reselected in loadout; Restart uses the previous selected difficulty/loadout.
- User data normally lives at `%APPDATA%\Godot\app_userdata\Nightfall Dorm\profile.json` on Windows. Godot's **Project → Open User Data Folder** locates it. `.bak` is the previous valid generation; `.corrupt.*` preserves damaged input. Back up the profile before deliberate recovery testing. Tests use isolated `qa-*` profiles and do not touch your normal profile.
- New Phase2 code has not been run on native Windows in cloud. Baseline Windows success was reported by you; new mixer loudness, long-term rank pace and difficulty still need your own feedback. Do not use an old EXE to test these changes; import the latest `work` source.
