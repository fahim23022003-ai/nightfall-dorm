# Nightfall Dorm Phase 16 Windows playtest

Extract both download parts into the same empty folder and run
**Join and Extract.cmd**. The script checks the joined archive's
SHA-256 before extraction. Open **Play Phase 16 Preview.cmd**. It
uses your existing Living Nightmare preview profile. Previous
Nightmare Lobby, Living Nightmare, V2.3, V1 and fixed launchers
remain alongside it. Run one launcher at a time.

- Start a Story match. Try Ready and the 15-second auto-ready on
  separate visits. Watch where the survivors go from the shared
  spawn. Beat a bot to its room and watch it replan.
- Compare the first chapter to a Haunted Paths mission and a Reaper
  chapter. Look for the authored opening, the relevant Hunter warning
  and the result's chapter and checkpoint information.
- In a crowded room, compare Standard and Low at 1280×720. Check that
  aiming, attack and impact animations remain readable. Open Build
  under pressure and check the price, cooldown and repair controls.

## Reproduce native desktop frame timings

The paired tool is available from the source checkout and uses a
separate profile. Use official Godot 4.6.3 on Windows. Close other
rendering workloads, record the GPU, driver, power mode and Godot
renderer, and repeat each case at least three times in alternating
order. Compare the reported wall median, p95, draw calls and memory
for 24, 40 and 60, using both `medium` (Standard) and `low`,
plus the `reaper` encounter in at least one crowded room.

```powershell
$env:NIGHTFALL_LIVING_NIGHTMARE = "1"
$env:NIGHTFALL_VISUAL_REBIRTH = "1"
$env:NIGHTFALL_SURVIVOR_REBIRTH = "1"
$env:NIGHTFALL_FULL_ROOM_GRID = "1"
$env:NIGHTFALL_PROCEDURAL_MAPS_V2 = "1"
$env:NIGHTFALL_PROFILE_PATH = "user://phase16-render-test.json"
$env:NIGHTFALL_PHASE16 = "1"
& 'C:\Godot\Godot_v4.6.3-stable_win64_console.exe' --path . --resolution 1280x720 --disable-vsync --script tools/phase16/measure_dense_active.gd -- "$PWD\benchmark" medium 60 stalker
```

Use a separate output folder per run. For the baseline, use source
`07b459b` with the same measurement script copied into its tools
directory. The embedded Windows pack was verified with Linux Godot.
Native Windows runtime and Intel UHD timings require a Windows run.
