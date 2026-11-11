# Extended visual and interaction audit

## Evidence method

This independent Agent D review runs actual Godot 4.6.3 OpenGL windows on the available Xorg dummy display `:99`, using Mesa llvmpipe. Frames in `docs/evidence/audit-*` are actual renderer output. Deterministic fixtures set up specified game states to inspect edge cases; they are **not** evidence that a player naturally reached those states. Prior natural room selection, spending, combat, and defeat evidence remains in VISUAL_REVIEW.md.

The initial audit score is **6/10 for visual presentation and interaction clarity**, not gameplay correctness. The layout is readable and functional at 1280×800, but the art is intentionally simple and purchase choices initially lack actionable requirements/stat information. The score is an audit judgment, not an automated metric.

## Baseline inspected

- The final result veil now has actual rendered evidence: `audit-result-before.png`. This is a deliberately set defeat fixture at 0 seconds, not a simulated natural loss. The title, statistics, Restart and Main menu are clearly readable over the dimmed map.
- `audit-long-tile-before.png` exercises a selected Dream amplifier L1. Text fits the sidebar at 1280×800 and does not overlap Bed action. The full room uses five buildings because the fixture deliberately leaves the advanced turret prerequisite unsatisfied.
- `audit-rejection-before.png` exercises insufficient bed-upgrade gold: the user sees the same combined generic rejection used for unrelated causes, without a precise missing resource amount.
- `audit-small-window-before.png` is a viewport framebuffer at the virtual 1280×800 canvas and must **not** be treated as proof of physical 800×500 readability. A separate X11 physical-window audit follows.

## Findings sent to production owner

1. Explain precise purchase failures and prerequisites; the previous generic message combines empty tile, resources, cap and prerequisites, leaving players guessing.
2. Expose building effect statistics at purchase/upgrade choice time: turret damage/range/fire interval; E/s; repair HP/s; economy percentage; enhancement percentage. Prices alone are insufficient strategy information.
3. Add clear valid/affordable/invalid action states or useful tooltips, including full/destroyed door and maximum upgrade level.
4. Provide a way to return to Main menu from a paused match.
5. Protect the fixed composition with a minimum window size or validated scaling behavior.

Changes and retest results will be recorded below only after execution.

## Executed natural-input regression

`python tools/graphical_smoke.py` exited 0. The retained helper starts the game and uses real XTest inputs; no MatchModel mutations occur. Manual inspection of its actual frame `audit-input-sleep-build.png` confirms ROOM 2 SLEEPING, 2.0 gold/s, a closed door, a Needle turret L1, and 6 gold remaining from the 25-gold initial balance after the 20-gold purchase and a short income interval. `audit-input-menu.png` confirms menu rendering. `audit-input-baseline.log` records the real renderer output; only the known unsupported VSync warning appears.

## Low-level resize test and correction

A deterministic fixture explicitly requested an 800×500 X11 window; `xwininfo` confirmed 800×500 and Godot logged physical size `(800, 500)` with a 1280×800 framebuffer. Actual root-display frame `audit-physical-800-before.png` shows the top HUD and right purchase controls cropped, with the map camera shifted. This initially appeared to be a normal resize failure. Follow-up isolated a harness issue: directly resizing via DisplayServer bypassed the Window node bookkeeping. It is not evidence that a normal OS/user resize crops the game. The corrected fixture uses Window.size and verifies physical 960×600 successfully, as described below. At the intended 1280×800 size, `audit-max-level-before.png` confirms the long Dream amplifier L4 description and upgrade costs fit the sidebar.

## Additional critical input defect and fix

Extending the real-input smoke to click a second empty slot exposed a real gameplay interaction failure: selection stayed on tile 1. The full-screen UI Control consumed map mouse events before `_unhandled_input`. Production owner set passive UI controls and labels to `MOUSE_FILTER_IGNORE`, retaining normal button input. Rerunning the actual XTest sequence confirmed tile 2 now highlights and the sidebar says `Tile 2: Empty floor`. Evidence: `audit-tile-selection-before.png` and `audit-input-selection.png`.

The newly added effect tooltips also initially used unsupported GDScript `%g` formatting, causing runtime errors in `building_effect`. The smoke helper failed with exit 1 and retained `audit-tooltip-error.log`. After replacing with supported `%.1f`, the same smoke exited 0 with no runtime errors (`audit-input-final.log`). This is why executed graphical interaction is required in addition to import success.


## Verified layout and feedback improvements

- Proper Window.size resize to physical 960×600 displays the entire six-room map, HUD, sidebar actions and Return to main menu: `audit-physical-960-final.png`. Text is smaller but legible in the actual frame.
- With Xfwm4 running under a local D-Bus session, fullscreen actually reaches physical 1280×800 and preserves the whole composition: `audit-fullscreen-final.png`. A fullscreen request without a window manager staying 960×600 was an environment limitation, not claimed as game failure.
- `audit-rejection-final.png` shows the exact actionable `Need 25 more gold.` message following the actual Bed button callback, replacing the generic combined rejection. This is a deliberately constructed insufficient-funds state.
- `audit-max-level-final.png` shows all six original building symbols, clear Bed/Door MAX labels and the selected Economy L4 MAX state without sidebar overflow.
- `audit-result-final.png` verifies the final result veil and controls at the minimum physical size. This is a deliberately constructed result fixture.
- Tooltips now contain functional building stats and prerequisites; code uses supported numeric formatting and the real-input smoke has no script errors.

Revised visual/interaction score: **7/10**. The functional UI is clearer and map selection now works across tiles. Original art remains simple geometric placeholders, motion/lighting is minimal, audio is not audibly verified, and there is no mobile/touch validation. The score is intentionally not a claim of final commercial presentation.

## Rendered automated-player match

The retained `tools/visual_match.gd` actually ran on final production source with fixed seed 71, default 25 starting gold, time-zero room 2 claim/sleep setup, and BotAI assistance for player spending. Engine time ran at 4× speed. There were no resource, damage, upgrade or result injections after that setup.

The match naturally ended in **victory at 149.4326 simulation seconds**, hunter HP 0, hunter level 3, with 238 total turret shots. The visible end screen reports the player's own 36 shots, 1,424 damage and 2,660 gold earned, with 0 residents lost. This verifies the actual final result UI and a complete rendered match with functioning resource accumulation, advanced buildings, upgrades, AI and combat.

- `audit-match-040.png`: actual early defenses and electricity production.
- `audit-match-080.png`: all six player building kinds, 60 electricity, bed/door level 3, and hunter attacking a bot door.
- `audit-match-120.png`: progressed economy/door upgrades and hunter damaged to 2,265 HP.
- `audit-match-terminal.png`: actual natural DAWN SURVIVED terminal overlay, not a result fixture.
- `audit-rendered-match.log`: actual JSON snapshots and terminal result; renderer warning only, no script errors.

## Input-harness timing correction

One intermediate window-manager run executed without runtime errors but failed to approach the bed far enough during software-renderer startup stutter: the resident remained AWAKE and the game correctly rejected building. This was caught by manual screenshot inspection, not treated as a passing gameplay outcome. The helper movement was changed to clamp against the north-room wall near the bed, and semantic OCR assertions were added so a no-error log alone cannot pass this path. `audit-input-timing-failure.png` records that intermediate harness failure; final results follow below.

## Final repaired real-input run

`python tools/graphical_smoke.py` exited **0** on final production source after the movement timing correction. The helper's rendered OCR assertions passed, and Agent D independently inspected the actual frames:

- `audit-input-sleep-build.png`: room 2 **SLEEPING**, 2 gold/s, 6 gold, closed door and selected Turret L1.
- `audit-input-selection.png`: the second floor slot is selected; the original passive-UI mouse interception defect is resolved.
- `audit-input-generator.png`: at 24 seconds, room 2 remains SLEEPING with Turret L1 on slot 1, Generator L1 on slot 2, **13 gold and 4 electricity**. These resources were earned/spent through real inputs and elapsed gameplay, with no model mutation.
- `audit-input-tooltip.png`: actual hover on the Arc turret shows **28 damage / 1.3 seconds, range 300 px, upgrade effects, and bed level 2 prerequisite**.
- `audit-input-return-menu.png`: clicking Return to main menu from the paused active match successfully returns to the real menu.
- `audit-input-ocr.txt`: actual OCR text used by the semantic guards; `audit-input-final.log`: real clean engine output (known VSync warning only).

Final visual/interaction assessment remains **7/10**, with no critical visual or interaction failures found in these executed desktop flows. This does not certify other platforms, audible sound, commercial art quality, or every balance strategy.

Final state-fixture cleanup: `audit-visual-fixtures.log` records actual physical sizes after starting at the documented 960×600 client size. `audit-physical-960-final.png`, max-level/rejection/result frames are 960×600; `audit-settings-fullscreen-final.png` and `audit-fullscreen-final.png` are 1280×800. The Settings frame uses the real CheckButton callback (not a direct fullscreen replacement), confirming the existing fullscreen setting works with the available window manager. All captures returned exit 0 and the log has no script errors. These final frames were independently viewed after capture.
