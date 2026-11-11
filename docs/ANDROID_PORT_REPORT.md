# Android port and cross-platform delivery

11 November2026, Singapore. Engine4.6.3 stable. Continued existing private `work` from `0de14345e6f4f66f027fd1038a82a6278947eca3`, protected by recovery tag `pre-android-2026-11-11`.

**PARTIAL — shared Windows/Android implementation and real signed debug APK delivered; native Android execution and hardware performance remain UNVERIFIED.** The game was not rebuilt. Existing Windows controls/UI remain the desktop branch, and its preset is byte-for-byte preserved. Core map/economy/AI/door/turret/rank rules have no source changes; see `evidence/android/windows-preservation.txt`.

## Shared implementation and touch controls

Android selects a mobile presentation/input path in the same `project.godot`/main scene. Desktop continues WASD/arrows, E, mouse, wheel, M/G/R and Escape with the prior interface.

- Left analog stick moves through the existing collision rules. A tap on a vacant room starts corridor/door waypoint movement and claims it on arrival; it does not teleport. Tap your claimed bed or Bed / Sleep to approach it and sleep.
- Tap an owned floor pad to open building cards. Tap a card for the preview/reason/cost, then Confirm to purchase once. Cancel/Android Back costs nothing. Raw touch world handling ignores its extra emulated mouse path; GUI callbacks retain Godot's touch-to-mouse behavior.
- Tap built machines, beds and doors for shared upgrade/repair logic. Unaffordable cards remain inspectable by touch with a visible rejection reason rather than requiring hover. Existing machine/bed/door detail panels expose cost/effects/prerequisites.
- Menus, settings, rewards and loadout use large controls. Reward/help lists scroll by swipe with child-press cancellation; tests cover a swipe beginning on Equip. Map, Help and Pause are accessible on screen.
- Android Back cancels placement, closes the inspector, then pauses; menu Back returns to the menu. Result, pause and confirmation controls are enlarged. The optional guide uses touch instructions and hides while an inspector would cover the bed.

New modules: `touch_controls.gd`, `mobile_layout.gd`, `mobile_interface.gd`. Existing core systems stay shared, with no fake mobile economy/combat implementation.

## Landscape, safe area and lifecycle

The design canvas remains1280×720. Mobile expands the viewport for16:9/19.5:9/20:9 and centers an aspect-preserving UI inside the usable safe rectangle. Actual Android safe area is mapped from DisplayServer screen coordinates through the viewport transform; a synthetic override supports deterministic cutout testing. Room focus adapts to the open drawer while the level geometry stays unchanged.

On app pause/focus loss, progression/settings save, touch movement/routes clear, simulation stops and looping/effect streams pause. Returning restores audio playback positions and leaves an interrupted match paused until Resume is tapped; there is no wall-clock catch-up or automatic combat while returning. Music starts remain3, not restarted on every resume.

The original37 audio assets and independent persisted mix/mute settings remain. Android uses10 effect voices versus16 on desktop, plus the existing persistent loop players. Mobile HUD updates are limited to20Hz while movement/camera rendering remain frame-based. Battery saver requests30FPS; normal mobile requests60. These are frame-cap requests, **not proven achieved device rates**.

Both platforms keep Godot `user://profile.json` with the existing validated write/backup/recovery system. Windows and Android saves are separate; no synchronization exists. Android system backup is disabled in this offline debug preset. Uninstalling the app removes its private data; keep the same signing key/package for updates and do not uninstall casually to resolve a signature mismatch.

## Actual build

A real installable artifact exists: **`/workspace/NightfallDorm_Android_Test.apk`**, also under ignored `builds/android/`. It is an APK containing Android manifest/dex, Godot data/scripts and both native ARM libraries, not a source ZIP. Exact size/SHA256 are recorded in `evidence/android/APK_MANIFEST.json`; the adjacent workspace `.sha256` file allows verification.

- App:Nightfall Dorm; package:`org.nightfalldorm.game`; version:`0.3.0-test`/code1.
- Godot/template4.6.3; minimumAPI24(Android7), targetAPI36(Android16), landscape.
- ARM64 and ARMv7; OpenGL ES3/Compatibility explicitly selected for mobile, no required Vulkan feature.
- Original main/adaptive/monochrome launcher graphics. No internet/microphone/external-storage permission requested.
- Debug signature, v2/v3 certificate verification and16KB native alignment passed. No keys/passwords are tracked or packaged.

SDK platform36, build-tools36.0.0, platform-tools and matching official templates were installed in user-owned workspace locations. The official Godot docs were accessed via their GitHub source when the docs website was blocked. The installed engine/template's actual target36 supersedes an older SDK35 recipe. Templates and SDK packages were verified against official release/repository checksums. Java21 was available; local Windows docs recommend17.

`final-export.log` records successful export. The SDK's optional adb server cannot create its default read-only home directory, so the exporter reports an unavailable adb connection after packaging; this did not invalidate the separately verified APK. There is no emulator/KVM or attached phone. **No installation/launch on native Android was performed.** No Play Store publication, release signing or Windows executable export occurred.

## Executed QA and actual rendering

The unmodified baseline regular suite passed before port changes. The final regular suite passes again:

| Check | Actual final result |
| --- | --- |
| Import and actual main startup | PASS |
| Mobile real touch/lifecycle |52 checks,0 failures |
| Mobile layout |196 checks,0 failures |
| Gameplay / projectile / projectile edges |126 /22 /12 assertions,0 failures |
| Audio / rank-save / Phase2UI / hunter |139 /348 /52 /39 assertions,0 failures |
| Existing camera/input, scene, contextual UI |173 /24 /53 checks,0 failures |
| Furniture / availability / audit |30 /3209 /72 checks,0 failures |
| Transaction conservation |20,000 transactions /175,941 checks,0 failures |
| Combat-rate scenarios |6 passed |
| Representative complete matches |12 resolved:9 victories,3 defeats |
| Separate-process profile persistence |Write/read/duplicate-settlement guards passed |
| Static APK verification |Signature, alignment, manifest, package/API, ARM ABIs, offline GLES launcher and resource checks PASS |

Tests use isolated QA saves, never normal player progress. Independent Agent C sends real ScreenTouch/ScreenDrag events through the production scene; joystick/second-finger behavior, room/bed routes, preview/confirm/double-charge rejection, upgrades/repair, background freeze, resume, scrolling and saved frame caps pass. Headless safe-fit tests cover all six rooms and requested aspect ratios with asymmetric insets. Both ordinary headless preview scrolling and Godot's touchscreen-aware path pass without duplicate scrolling/equip activation.

Nineteen actual Linux/Mesa software-rendered viewport captures show all three aspect ratios and a synthetic safe area, including menu/loadout/build/confirmation/pause/settings/rewards/resumed-pause and a no-XP result fixture. Funds/claim/sleep/terminal setup are explicitly prepared visual fixtures. They prove rendered layout behavior on that host, **not native Android rendering or physical finger comfort**. The final source includes a bounded two-line no-XP notice, larger mobile card text and guide/drawer visibility correction.

Independent Agent D reproduced two defects: a close control overlapping the Dynamo card and a floor-pad edge opening the bed inspector. Both were corrected, independently rechecked and regression tested. Agent B owned SDK/preset/build tooling, Agent C owned independent tests, D reviewed actual render/audio lifecycle evidence; the main agent integrated presentation/input and audited shared Windows rules. Specialists were bounded rather than continuously reviewing the whole project.

## Performance evidence and limits

`host-profile.log` is a **Linux headless model benchmark**, not phone FPS:12 additional normal/hard balanced matches completed, mean simulation step89.68μs over37,941 steps, worst15,724μs under host load, peak6 travelling shots against a256 cap; reported static allocation22.3MB. This measures core simulation only, not Android rendering/audio/GPU/RSS.

Software preview sampling during PNG readback/capture ran roughly10–17FPS; those values include capture overhead and are not a standalone game/device benchmark. No30/60FPS or memory/thermal target is claimed on Android. Device profiling, touch-target comfort on a real phone, OS-specific safe-area/audio-focus behavior, native Windows retest after this port and longer human balance remain unverified. Controller/accessibility support and cross-platform cloud saves remain future work.

## Next steps

Download the actual APK and install on an ARM Android7+ GLES3 phone for private testing; see `ANDROID_EXPORT.md`. Test movement→room→bed→economy→defense→result, both outcomes, upgrade/cancel and scrolling. Background/lock/unlock during combat, verify explicit Resume, listen for music continuity and check saved rank/rewards/settings after relaunch. Record phone model/Android version/FPS/thermal behavior instead of inferring from Linux.

For Windows, pull `work`, import the same `project.godot` in Godot4.6.3 and F5; original controls remain. Local Android SDK/JDK/export instructions and debug-key update caveats are in `ANDROID_EXPORT.md`. Source/tools/reports are committed to private Git; large APK output remains a local downloadable build artifact rather than a public release.

## Final packaged-project and backup verification

Feature commit `b80e75e1ccc75bb451dae0158a262b32804a7ad5` and the pre-port recovery tag were pushed and remote SHAs verified. The actual delivered APK's Godot assets were extracted to a temporary directory; Linux Godot loaded that exported project, started the actual main scene and passed52 touch/lifecycle plus196 layout checks using external test harnesses. This is exported-resource/bytecode validation, **not Android native ABI/OS execution**. Logs: `packed-project-startup.log`, `packed-project-touch.log`, `packed-project-layout.log`. Final source/backup details: `evidence/android/BACKUP.md`.

Background/resume preserves an in-progress match while its process remains alive. Full world-state save/resume after Android kills the process is not implemented; a relaunch returns to the menu, with completed XP/rewards/settings preserved and an unfinished match abandoned.
