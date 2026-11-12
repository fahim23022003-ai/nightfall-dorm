# Independent QA C — first sliding-HUD milestone

Functional HUD gate accepted after focused retests. Exact source hashes and honest command outcomes are in `qa-hud-receipt.json`.

- The first full probe ran **2,416 assertions across ten scenarios**: all five maps at actual physical 1280×720 and 1920×1080, with a 1280×720 logical viewport. Its eight failures were limited to a reset fixture: directly starting a map did not set the setup UI's selected map, which Reset correctly uses. The fixture now sets that real selection first. No production fix was needed for those failures.
- The corrected reset probe passed **60 checks / ten scenarios / zero failures / exit 0**, including old animated-panel cleanup, the selected map and permanent save isolation.
- The latest toolbar ordering patch passed **90 checks / ten scenarios / zero failures / exit 0**. The drawer was held at a position physically overlapping the toolbar; real mouse events still reached the toolbar button and changed the relevant panel without charging or moving the camera.

Twenty unpaused transitions measured **0.2515–0.2661 seconds**. Each moved monotonically between the closed and lower-middle endpoints, reused one panel and left camera, player, model and RNG unchanged. Mid-transition input was tested separately with the tween paused to keep the target under real mouse events: the actual BaseButton emitted its press, while the economic callback rejected it.

The full probe also verified twenty rapid open/close cycles per scenario without accumulating panels/tweens; real double-click BUILD/upgrade/sale with exactly one charge/refund; cancellation of held BUILD with Escape and successful reuse afterward; actual door damage without auto-closing the panel; paid keyboard R repair; relevant bed/door panels; and permanent profile byte/value preservation. Existing engine tests contain the actual 12 registered building controls. Fifteen planned card rectangles fit the new layout, but this milestone does not claim the three future machines are already functional.

The corrected default test `tests/overhaul_qa_hud.gd` is ready for the final integration run. This bounded milestone reran only the affected reset and toolbar scopes rather than falsely reporting the initial full command as passing. D owns actual screenshots and visual quality. Native Windows hardware input remains unverified. Expansion, typed combat, new defenses and Hunter changes require later independent gates.
