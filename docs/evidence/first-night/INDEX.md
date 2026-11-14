# Phase 11 — real engine evidence

Godot **4.6.3**, Linux Xorg dummy display, Mesa llvmpipe Compatibility renderer. These are original runtime PNGs, not generated gameplay or mockups. Scripted keyboard/mouse `InputEvent`s exercise normal game/UI handlers; XTest focuses the window only. No human playtest or native Windows run is claimed.

## Screenshot gallery

| Required view | Actual capture |
| --- | --- |
| 01 First-time welcome | [PNG](screens/01-first-time-welcome.png) |
| 02 Primary objective | [PNG](screens/02-primary-objective.png) |
| 03 Claim guidance | [PNG](screens/03-claim-room-guidance.png) |
| 04 Sleep guidance | [PNG](screens/04-sleep-guidance.png) |
| 05 Dynamo construction | [PNG](screens/05-dynamo-construction-guidance.png) |
| 06 Turret range instructions | [PNG](screens/06-turret-range-guidance.png), [actual built turret range](screens/06b-built-turret-actual-range.png) |
| 07 Upgrade-confirmed / repair objective | [PNG](screens/07-door-repair-guidance.png) |
| 08 Real practice victory | [PNG](screens/08-tutorial-victory.png) |
| 09 Ordinary match, guidance no longer needed | [PNG](screens/09-normal-gameplay-without-clutter.png) |
| 10 Previous Wave Report | [PNG](screens/10-wave-report-before.png) |
| 11 New Wave Report | [PNG](screens/11-wave-report-redesign.png) |
| 12 Ranked damage bars | [PNG](screens/12-damage-breakdown.png) |
| 13 Economy | [PNG](screens/13-economy-breakdown.png) |
| 14 Factual insights | [PNG](screens/14-strategy-feedback.png) |
| 15 Intermission | [earned46 PNG](screens/15-intermission-decisions.png), [early Omen choices PNG](screens/15b-early-omen-decisions.png) |
| 16 Simultaneous upgrades | [BEFORE](screens/16a-upgrade-overlap-before.png), [AFTER](screens/16b-readable-upgrade-summary.png) |
| 17 Full earned 16-building room | [PNG](screens/17-earned-full16.png) |
| 18 1920×1080 | [gameplay PNG](screens/18-gameplay-1080.png), [report PNG](screens/18-wave-report-1080.png) |
| 19 Guidance preferences | [PNG](screens/19-guidance-settings.png) |
| 20 Windows build evidence | [artifact receipt](windows/windows-artifact.json), [77 embedded-pack checks](windows/windows-pack-final.log), [ZIP contents/CRC](windows/archive-review.json). No Windows runtime screenshot is available. |

Additional: [Defense](screens/defense-breakdown.png), [Hunter Skills](screens/hunter-skills.png), [720p layout](screens/layout-720.png), [900p layout](screens/layout-900.png), [1080p layout](screens/layout-1080.png).

## Continuous capture

[Uncut gameplay video](video/native-input-silent.mp4) — normal speed, 1280×720, 24 fps, silent H.264. The filename is historical: input is scripted **engine InputEvents**, not a human or native OS gameplay-input test. [Separate actual Master PCM](video/cold-master.wav), [signal measurements](video/audio-analysis.json), [capture receipt](video/capture-metadata.json), [engine log](video/engine.log), [timeline and assertions](cold-journey.json).

- Fresh profile, existing temporary tutorial credits only. Claim/sleep/Dynamo/Needle/upgrade/repair/real practice victory/save completion. No unlocks, injected ordinary funds, teleports or manual HP assignments in this cold segment.
- First ordinary Stage 1 / Normal starts through real menu clicks; claims/sleeps, pays Needle and Dynamo from default funds plus bed earnings; pause/resume. It is an opening interaction test, not a completed natural campaign match.
- **41.6 s onward: explicitly separate scenario.** Copy of canonical earned wave45, disposable run identity rebound to allow isolated save/resume. Actual paid Repair/Arc upgrades from the checkpoint's original earned funds. Full16, actual save/exit/resume, full-health wave46 combat, report tabs, intermission and wave47. No Hunter HP edits/free money. This does not claim a fresh natural 1→46 playthrough.
- Video and WAV clocks are not synchronized; the WAV is slightly shorter. Audio signal presence/no clipping is measured; subjective listening and Windows output are unverified.

## Honest comparison and prepared fixtures

The old report PNG is retained from Phase10's actual prepared-wave1 render. The after report uses real earned46 telemetry: compare **presentation**, not equal combat outcomes or DPS. New actual damage bars reconcile to totals; unshown weapons and Other are separately disclosed.

16a/16b use the same prepared three-paid-Needle upgrade scenario (500k test wallet). The before was captured before modifying presentation; after retains premium rings/animation and replaces colliding world text with one summary lane. This is isolated upgrade scheduling evidence, not naturally earned economy.

The early Omen view restores the disclosed Phase10 prepared-wave1 checkpoint. Its wallet is not a fresh-player wallet. The supplemental 1080p/report layouts restore the actual recorded earned46 checkpoint and advance the next wave normally. No screenshot was composited into a fake game state.

## Reproduce

Use writable XDG directories as documented in README. From the repository with a real Linux X display and ffmpeg/X11/XTest available:

```sh
DISPLAY=:98 python tools/record_first_night.py
DISPLAY=:98 godot --path . --audio-driver Dummy --resolution 1920x1080 --script tools/capture_first_night_supplement.gd
python tools/verify_first_night.py
godot --headless --path . --script tests/first_night_endless.gd
```

The baseline capture refuses to overwrite BEFORE evidence using the new presentation. To recreate that historical comparison use the original Phase11 baseline source; do not relabel current renders as BEFORE.
