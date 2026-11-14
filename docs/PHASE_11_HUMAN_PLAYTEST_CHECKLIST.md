# Phase 11 — owner and Adie playtest

Human answers and native Windows execution are **UNVERIFIED** until you perform this checklist. Automated Linux input is evidence of working controls, not proof the game is easy or fun.

## Launch safely on Windows

1. Extract **all** of `NightfallDorm-Windows.zip` into a normal writable folder. Run `NightfallDorm.exe`; Godot installation is unnecessary. This is a private test build, not a published release.
2. The ZIP includes `VERSION.txt` with the exact source commit and `SHA256SUMS.txt` for the executable. Do not compare the executable's hash to the ZIP's hash.
3. Existing saves remain in `%APPDATA%\Godot\app_userdata\Nightfall Dorm\`. Back up that folder before testing. Do not delete an existing profile to obtain a fresh launch.
4. For an isolated fresh profile, open PowerShell in the extracted folder and run:

   ```powershell
   $env:NIGHTFALL_PROFILE_PATH = 'user://phase11-human-fresh.json'
   .\NightfallDorm.exe
   ```

   This changes only the profile filename for this process. Use a different name for Adie's test. Close the game; a normal launch without that environment override uses the ordinary profile again.
5. If SmartScreen warns about an unsigned test executable, verify you received the owner's intended private ZIP before deciding to run it. No installer, administrator rights or network login is required.

## First-night journey — do this without developer instructions

- Watch or skip the opening. Does the welcome explain the objective? Close it with X.
- Start the first night. Can you find the highlighted room and claim it with E?
- Approach the bed and press E. Do you understand that sleeping produces Gold?
- Follow Build [B] → Dynamo. Is it clear that the Dynamo produces Electricity and does not shoot?
- Close the build panel, then use Recover. Does it reopen the controls you need?
- Try an unaffordable building. Does it explain the requirement without spending resources or advancing the lesson?
- Build a Needle near the door. Select it and inspect its range with O. Can you tell whether it reaches the Hunter?
- Upgrade the Needle, then repair with R. Does the objective advance only after success?
- Survive the real practice encounter. Can you identify turret shots and door damage?
- Save completion. Is Stage 1 / Normal clearly the next objective? Do practice resources and rewards stay separate?
- Replay Tutorial from the menu. Try Skip and Exit. Relaunch to verify the completion flag remains saved.

## Ordinary play and Endless

- Start Stage 1 on Normal with the normal wallet. Claim, sleep, build, repair, pause/resume and return to menu.
- In Settings try Show Guidance, Minimal Guidance and Off. Urgent door/Hunter warnings must remain visible and audible in every setting.
- In Endless, review the wave report. Can you distinguish your room's damage from allies' damage and gross production from the wallet balance?
- Try Damage, Economy, Defense, Hunter Skills and Insights. Are the horizontal bars and numbers readable? Insights may be absent or say unknown when observations cannot support a conclusion.
- Between waves: Review is optional; Prepare is optional and has a frozen economy; an available Omen is optional; choosing one aid continues. Can you identify the next action without help?
- Save between waves, quit, relaunch and Resume. Check buildings, positions, levels, resources and selected Omen. No duplicated payout should appear.
- Upgrade several buildings rapidly. Check the compact summary and hover its full detail. A combat warning should temporarily take priority.
- Test a full 16-building room, free placement, move V / undo Z, expansion, inventory, Team and spectating. Check at 1280×720, 1600×900 and 1920×1080.
- Listen for music, shots, warnings and repair feedback at your usual volume. Check Reduced Effects/Motion and saved audio settings.

## Record independent answers before discussing them

| Question | Owner | Adie |
| --- | --- | --- |
| Could you understand the objective without help? | UNVERIFIED | UNVERIFIED |
| Did you know what to click? | UNVERIFIED | UNVERIFIED |
| Which action was confusing? | UNVERIFIED | UNVERIFIED |
| Was the interface overwhelming? | UNVERIFIED | UNVERIFIED |
| Did you understand why you won or lost? | UNVERIFIED | UNVERIFIED |
| Would you play another wave? | UNVERIFIED | UNVERIFIED |

For a bug, record source commit from VERSION.txt, resolution, mode/map/wave, exact inputs, screenshot/video and whether it repeats. Keep the backed-up save intact; share only a copy when needed.
