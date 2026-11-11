# Independent Android adaptation QA

11 November 2026, Singapore. Agent C performed a bounded review of the shared project's mobile input, layout and lifecycle implementation. Production code remained owned by the coordinator; this reviewer owns only the two new test scripts, this report and the `qa-*` evidence logs.

## Final actual executions

Godot **4.6.3 stable**, Linux headless:

```sh
godot --headless --path . --script tests/mobile_controls.gd
godot --headless --path . --script tests/mobile_layout.gd
```

Use the writable XDG variables in README. Final results:

| Suite | Actual result | Raw output |
| --- | --- | --- |
| Mobile controls and lifecycle | **52 checks, 0 failures**, exit0 | `docs/evidence/android/qa-mobile-controls.log` |
| Mobile safe layout and control geometry | **196 checks, 0 failures**, exit0 | `docs/evidence/android/qa-mobile-layout.log` |

Each suite instantiates the actual main scene with `mobile_mode=true` before `_ready`. Profile paths use unique `user://qa-mobile-*` filenames; test cleanup removes only that test's own prefix. No normal `profile.json` is modified.

## Actual input and gameplay coverage

The controls suite dispatches `InputEventScreenTouch` and `InputEventScreenDrag` through `Input.parse_input_event`, including the window's final stretch transform. Native GUI buttons receive the real touch-to-mouse emulation used by Godot, rather than calling button callbacks directly. It checks:

- Main menu → loadout → Start Night using raw finger events.
- Ten bounded mobile effect voices.
- Left-stick capture, real model movement, separate second-finger handling, and release stopping movement.
- Tapping a vacant visible bedroom schedules walking instead of teleporting. The production movement/collision function walks the route, enters and claims the room. Tapping its bed then walks into sleep range and locks/sleeps through production rules. Claimed-but-awake beds still have zero income.
- Floor tap selects the actual owned pad; card selection starts a free preview; Confirm builds the real generator and deducts exactly one catalog price. A second stale confirmation cannot charge again.
- Android Back cancels a turret preview without constructing or spending. Door summary taps do not leak into floor selection. Actual door upgrade increases max HP, and an actual repair restores damaged HP.
- An unaffordable advanced card remains inspectable by touch: its confirmation is disabled with a visible reason, and no resource is deducted. Essential prerequisite feedback is not solely a hover tooltip.
- Application background handling freezes model time/income, clears touch movement/routes, and pauses all six looping streams. Returning to the app leaves the match paused until a real Resume tap. Existing music starts remain unchanged; no restart is substituted for resuming the streams.
- Battery-saver setting requests a30FPS cap, normal mobile mode requests60, and the preference survives loading a fresh profile instance. This tests requested caps, not achieved device frame rate.
- Raw touch drag scrolls the reward list and does not equip a perk. Dragging beginning directly on an Equip button also cancels child activation.

The test freezes the Game node's automatic frame simulation while dispatching GUI input, then advances its production movement methods deterministically for routes. Resource-rich purchase fixtures isolate input/deduction correctness; they are not natural affordability or human play evidence. Full existing economy, hunter, projectile, rank and save regressions are run separately by the coordinator.

## Scroll investigation and corrected evidence

The first exploratory run reported three failures. Two were fixture errors, not production defects: a desired room center projected behind the top HUD while another finger had previously selected a different route, and direct HP mutation left a frozen test UI's Repair button disabled. The fixture now clears the prior route, taps a visible part of the room, and refreshes affordability after direct HP setup. These corrections preserve the actual semantic assertions.

The remaining initial drag-scroll observation required capability diagnosis. Official Godot4.6 `scene/gui/scroll_container.cpp` checks `DisplayServer.is_touchscreen_available()` before enabling native mouse-emulated drag. Linux headless reports false, so an initial raw-touch-only test could not establish Android native-scroll failure. The coordinator added an explicit bounded cross-platform drag adapter with child scroll-begin/end cancellation. The corrected test verifies that path. It additionally enables Godot's documented `Input.emulate_touch_from_mouse` hint so `DisplayServer.is_touchscreen_available()` returns true, then verifies the native-touchscreen-aware path and adapter coexist with a single bounded drag distance and no accidental equip. That is an engine-level compatibility test, not native Android device certification.

Historical exploratory output is retained in `qa-mobile-initial.log`; use the final logs above for the corrected result.

## Layout coverage

Pure safe-fit tests cover1280×720(16:9),1560×720(19.5:9),1600×720(20:9), and2400×1080, with symmetric/asymmetric margins. They verify aspect-preserving fit, positive scale, safe bounds, center placement and invalid-safe-area fallback.

Actual scene checks verify finger-sized menu, settings, help, ranks and loadout controls; scrolling content is intentionally allowed outside the clipped viewport. Every build pad in all six rooms projects outside the fixed HUD and remains clear of the open mobile build drawer after camera focus. Pause/result navigation is finger-sized and remains inside the design area. The actual CanvasLayer panel transform fits a mocked asymmetric safe rectangle.

The aspect-ratio/inset tests are logical geometry checks, not measurements from real Android cutouts. Actual rendered screen review is owned separately by the coordinator/experience auditor; headless success is not presented as visual readability proof.

## Remaining unverified areas

- Native Android APK installation/launch, device-specific input dispatch, cutout/gesture-bar reporting and Android audio focus depend on available emulator/device evidence from the build/coordinator reports.
- Real-device30/60FPS, memory/thermal behavior and mid-range-phone comfort are **UNVERIFIED** by these tests.
- Audible sound quality, speaker mixing, interrupted Bluetooth/headphone behavior and long-term human mobile balance are not established here.
- Windows and Android `user://` saves are separate local platform data unless a synchronization feature is added; these tests do not claim cloud sync.

No production file, export preset, signing credential or release artifact was modified by this independent QA task.
