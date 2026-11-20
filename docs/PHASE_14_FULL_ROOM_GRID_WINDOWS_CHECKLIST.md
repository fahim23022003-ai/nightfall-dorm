# Phase 14 visuals and Full Room Grid Windows playtest

Extract the entire ZIP and open **Play Visual Preview.cmd**. It uses a separate Full Room Grid playtest profile. Close the game and open **Play Reference Visuals.cmd** for the previous visual and construction mode. This launcher uses the earlier Phase 14 playtest profile.

To compare existing progress, close the game and browse to `%APPDATA%\Godot\app_userdata\Nightfall Dorm`. Copy `profile.json` or an earlier playtest profile into `phase14-full-room-grid-playtest.json` before launching Preview. Keep the original and its backup. Start a fresh Endless run to test Full Room Grid.

## Construction

- Claim a room and sleep. Open **Build** with **B**. Move a building preview over empty cells, furniture, the door approach, the room edge, and occupied cells. Confirm one legal purchase, then try invalid placement, a rapid double-click, and cancellation with **Esc** or right-click. Watch Gold and Electricity for duplicate or rejected charges.
- Press **Q** to rotate clockwise, **Shift+Q** to turn back, and **P** to show the plan. Test compact and wide footprints near room edges and with a crowded room. Check the 16-pixel alignment, visible cells, rejection reasons, and which cells each building occupies. Full Room Grid is available in desktop Campaign and Endless. Check that Practice and Challenge retain their designed layouts.
- Fill more than three valid sites without buying an expansion. Check that the entire legal room floor starts available, the bed and door stay put, and footprint size and access determine how much fits. Compare with Reference on the same map and difficulty.
- Select a built machine by its footprint or open **Find machines** and choose its level and floor coordinates from the list. Verify that the highlighted footprint matches the inspector, and check that the room trait and door HP stay readable. Use **Move** during preparation or between waves, test **Z** where the undo action is offered, and try an illegal move. Verify that a successful move preserves upgrade, specialization, cost, and building identity. Confirm that active combat keeps its existing restrictions.
- Save after a cleared wave, quit, relaunch Preview, and Continue. Check positions, room capacity, resources, upgrades, specialization, inventory, and subsequent construction. Use a copy to check that an earlier saved run still loads.

## Art, combat, and performance

- Check Crusher, Stalker, Ravager, Phantom Witch, Electric Ghost and Storm Wraith at L1, L4, L7 and L10. Use Practice for initial encounters and Campaign or Endless for evolved encounters. Record any stage you could not reach. Watch a full front, rear, left and right turn sequence. Check hair, clothing and limbs during movement, warning, strike, reaction, recovery and disappearance.
- Review both Grim Reaper forms, including the awakening, scythe attacks and Crimson Execution. Confirm that the warning, release and audible impact cues follow the action.
- Check L1–L10 art across the 15 placeable buildings plus Bed and Door, including both specialization paths where available. Watch Needle, Arc, Flame and Frost aim, recoil and impact at valid targets. Listen for their firing and impact sounds. Check that support machinery follows the actual active effect and that door HP and warnings stay readable.
- Compare the same crowded room at 1280×720 and 1920×1080 with both graphics presets. Toggle Reduced Motion and Reduced Flash. Check selection and preview responsiveness during combat, positional effects, controlled flashes, and readability around the doorway.
- On Windows, record CPU, exact Intel UHD model and driver if available, resolution, preset, and FPS over the same 60 seconds of crowded combat on Low and Standard. Note visible stutters. For a problem, include the source commit from `VERSION.txt`, launch mode, map, wave, exact steps, expected and observed result, and a screenshot or clip.

The package uses the Godot Windows x64 release template. Its embedded game data was tested with Linux Godot. Native Windows rendering, input, audio, and performance still need a Windows playtest.
