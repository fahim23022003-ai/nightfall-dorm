# Nightfall Dorm — private Windows playtest

Version: **0.6.0-rc1**, Godot **4.6.3 stable standard**, Windows 10/11 x64.
This is a private release candidate pending native Windows validation, not a
public release. Test with Fahim and Adie; no login or multiplayer is required.

## Launch and preserve progress

1. For the supplied Windows ZIP, extract everything to a normal folder and run
   `NightfallDorm.exe`. Keep the accompanying notices and version/checksum files.
   The editor is not required. The executable is unsigned.
2. For source, sign into the private GitHub repository, select **work**, download
   ZIP, extract, import `project.godot` into Godot 4.6.3 and press F5. Never run
   from inside the ZIP. See [home instructions](HOME_TESTING_WINDOWS.md).
3. Before deliberate recovery testing, close the game and copy the entire folder
   `%APPDATA%\Godot\app_userdata\Nightfall Dorm` to a separate backup folder.
   It contains `profile.json`, previous generation `.bak` and any preserved
   damaged files. Do not edit your ordinary save to unlock test content.
4. For a separate fresh test profile, open Command Prompt in the extracted EXE
   folder and enter these two lines. This leaves your ordinary profile untouched:

   ```bat
   set "NIGHTFALL_PROFILE_PATH=user://phase6-fahim-test.json"
   NightfallDorm.exe
   ```

   Adie can use `user://phase6-adie-test.json`. Reusing a name resumes that test;
   a new filename creates another fresh profile. Close the Command Prompt after
   testing. To play your ordinary profile, launch the EXE normally from Explorer.
   Source users can set the same variable before launching Godot from that prompt.

If the game cannot save, keep the window open, report the warning and retry the
operation after resolving disk permissions. Do not overwrite a valid backup.

## Playtest checklist

- [ ] Fresh launch shows opening, **Created by Fahim**, title and all nine tutorial
  steps. Follow movement/claim/sleep/build instructions, then enter campaign.
- [ ] Play Normal: WASD/arrows move, E claims a room and E near its bed sleeps.
  Check income only while occupied, Gold versus Electricity, bed/door upgrades,
  Dynamo production and readable danger warnings.
- [ ] Click a floor pad, pick a building and Confirm. Try rapid double clicks,
  cancellation/Escape and moving to confirmation controls. Check one purchase,
  one charge and stable preview. Upgrade/sell; verify separate 50% refunds of
  actual paid Gold and Electricity, and reuse the freed tile.
- [ ] Finish a match, follow rewards/Spin/Next Stage and restart. Check stage
  records, inventory and equipped perks after closing/reopening. Five maps and
  higher stages require ordinary progression; do not change saved unlocks.
- [ ] Try Long Night and Hell. Watch Crusher/Stalker/Ravager differences and
  Reaper warnings. Try dodging damage through repair/item timing, not hidden
  debug advantages. Defeat is a valid test outcome; report unfair/stuck behavior.
- [ ] Earn RM Cash, buy a Common supply in Shop, equip it in inventory, use 1/2
  during a real match and reopen the game. Check exact cash/stock changes. With
  no earned cash yet, use Practice for temporary item testing instead.
- [ ] Open Endless Siege's skull button. Clear waves, prepare defenses during
  the frozen intermission, continue and confirm paid buildings/resources carry.
  At an intermission choose Save & exit, close/reopen and Resume. Mid-wave
  progress replays from the checkpoint; permanent items spent stay spent.
  **End run here** closes the run; **Save & exit** suspends it. Verify neither
  reload nor repeated milestones duplicate RM/XP.
- [ ] Generate/copy a Challenge Code and send it to Adie. Both import the exact
  code in this version. Compare shown map, mode, archetype and normalized rules.
  Play and copy the result summary. Results are self-reported; different inputs
  and timing produce different performance. Cross-platform bitwise identity is
  not certified. Try invalid/very long codes: useful errors, no crash.
- [ ] Preview/equip legitimately unlocked cosmetics, enter gameplay and restart.
  Check visible shapes and saved equipment, unchanged stats, readable cracks,
  specialization and Level 10 effects. Locked appearances must stay locked.
- [ ] After a genuine defeat, open Why did I lose? Compare damage/repair history,
  unused equipped stock and remaining currency with what actually happened.
- [ ] Practice each archetype and Reaper, repair, choose turret branches and use
  temporary items. Pause → Reset Practice. Exit and confirm permanent stock,
  RM, XP, spins, campaign and Endless records did not change.
- [ ] Check Victory pity progress versus the saved draw's odds. Consolation must
  not advance/reset Victory pity. Reopening results must not reroll rewards.

## Presentation and longer sessions

Test 1280×720 and 1920×1080, windowed/fullscreen and your Windows scaling.
Check all menus, keyboard focus, disabled tooltips, item descriptions and dense
combat. Toggle Reduced Effects and independent Music/Effects/Ambient/Mute;
restart and check saved settings. Listen for warnings, screams/laughter across
Continue, no clipped/painfully loud cues, and no stale audio after exit.

Play a longer Endless session and several matches without restarting. Report
stutter, escalating memory, stuck targeting, repeated spawns, missing attacks,
save warnings or growing delays. Linux software-renderer measurements do not
predict your Windows hardware. Human enjoyment and difficulty feedback matter.

## Report a bug

Copy and fill this in; screenshots/video are helpful but optional:

- Version and commit: from the build's `VERSION.txt` or `git log -1`.
- Windows version and approximate CPU/GPU/RAM:
- Mode, map, wave/stage, Hunter, equipped items/perks:
- Steps to reproduce:
- Expected result:
- Actual result and any exact warning/error:
- Does it recur after restart? Did stock/currency/progress change?
- Screenshot/video and relevant time:

## Export from source on Windows

Install Godot **4.6.3 standard** and its matching **4.6.3 export templates** through
Editor → Manage Export Templates. Import the latest `work` project and wait for
asset import. Project → Export → **Windows Desktop** → **Export Project**:
choose an empty output folder, keep x86-64 and embedded PCK, and **uncheck Export
With Debug**. The preset supplies title/icon/version and excludes docs/tests/tools.
Do not select the historical Android preset for this audit.

The equivalent CLI, from the source folder with a Godot executable on PATH:

```bat
mkdir builds\windows
godot --headless --path . --export-release "Windows Desktop" builds/windows/NightfallDorm.exe
```

Package the executable, this guide, version identification, Godot license and
third-party/font notices together. Templates alone are not proof the export ran;
inspect the command result, then execute the build on Windows and run this list.
No public release or merge to main is authorized by these instructions.
