# Phase 10 — actual runtime evidence

All game PNGs are unchanged Godot 4.6.3 viewport captures on Linux, GL Compatibility,
Mesa llvmpipe. No image generation or mockups. Scripted prepared fixtures are not
human playtests or natural economy progression. The baseline is retained Phase 9
runtime output from the verified baseline, not a freshly rerun old executable.

| Evidence | Actual file / conditions |
| --- | --- |
| Before | [Phase 9 baseline](screens/before-phase10-baseline.png), original `freedom-to-build/screens/05-three-flexible.png` |
| A/B | [Dynamic Shuffle settings 720p](screens/A-shuffle-settings-720.png), [1080p](screens/A-settings-1080.png), [all 14 listening previews](screens/B2-listening-all14.png) |
| C | [20 independent engine processes](logs/independent-launches.log), [sequence and waveform analysis](audio/analysis.json) |
| D | [Actual live placement range](screens/D-live-range-placement-720.png) |
| E | [Paid L10 specialized Needle range](screens/E-specialized-L10-range.png) |
| F | [Actual room-wide support information](screens/F-room-wide-support.png) |
| G | [Intermission entry](screens/G1-intermission-report-link.png), [actual report](screens/G2-actual-wave-report.png), [reconciliation](screens/reconciliation.json) |
| H | [Moved, Undo available](screens/H1-move-undo-available.png), [restored](screens/H2-undo-restored.png) |
| I | [All 16 prestige cores selected in turn](screens/I-full16-selected.png); selected IDs in reconciliation JSON. Later sale/replacement is L2. |
| J | [Night seed 10](screens/J1-night-seed10.png), [seed 20](screens/J2-night-seed20.png). Same gameplay state; cosmetic-only seed. |
| K | [Real live combat 720p](screens/K-live-combat-720.png) |
| L | [Full room 1080p](screens/L-full16-gameplay-1080.png), [next wave live combat 1080p](screens/L2-next-wave-live-1080.png) |
| M | [Uncut native-input video](video/native-input-silent.mp4), [actual Master audio separately](video/native-input-master.wav), [timeline](video/timeline.json) |
| N | [25s actual engine crossfade recording](audio/engine-crossfade-master.wav), [per-frame gains](audio/crossfade-timeline.json), [analysis](audio/analysis.json), [actual combat PCM](screens/N-live-combat-master.wav) |

The video uses real OS XTest mouse/keyboard input with an automated driver.
Prepared isolated wallet/room, frozen preparation showcase, then ordinary wall-time
combat. No cuts or speedup. The MP4 has no audio track; separate internal Master WAV
is supplied without claiming exact video/audio synchronization. See ffprobe metadata.

The full-room fixture pays actual building/branch/upgrade prices from a disclosed
500,000 Gold/Electricity temporary budget. Hunter is positioned at the door at full
normal wave HP. This demonstrates integration, not legitimate resource earning or
human strategic skill. All sixteen prestige cores are clicked before testing sale,
replacement and upgrade. The later room has one L2 replacement.

The wave report is produced by live normal-time combat until wave clear. Displayed
statistics are collected at actual impact/heal/production events; see reconciliation,
and the real captured prepared checkpoint. It is never substituted for the canonical
naturally earned wave-45 checkpoint, whose bytes remain unchanged.

Original music source assets and note-level composition manifest live under
`assets/audio/`; source licenses are documented in `docs/AUDIO_SOURCES.md`.

Native Windows execution, headphone listening, subjective enjoyment/scariness,
human click comfort and hours-long frame pacing remain UNVERIFIED.

Final pass/fail summary: [final-gates.json](logs/final-gates.json). The remaining-run
JSON preserves original attempt statuses, including two subsequently corrected
retries; use final-gates for the final result. Failed attempts remain archived.
