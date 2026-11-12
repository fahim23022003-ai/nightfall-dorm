# Nightfall Dorm — private Windows playtest

Current development phase: **5D-4, The Reaper’s Wrath**. Use the source commit in
`VERSION.txt` to distinguish builds; the authoritative export receipt is recorded
in the Phase5D4 report. Native Windows execution is UNVERIFIED by the Linux cloud
build. No public release or main-branch merge is implied.

Extract the private Windows x64 ZIP and launch `NightfallDorm.exe`. The executable
contains its game pack; the accompanying notices identify Godot, fonts, musical
instruments, recorded vocals and sampled effects. A GitHub `work` source ZIP is
for opening `project.godot` with Godot4.6.3; it is not the executable ZIP.

For owner and Adie’s full controls, gameplay, audio and preservation checklist,
read [The Reaper’s Wrath human playtest guide](PHASE_5D4_HUMAN_PLAYTEST_GUIDE.md).
It explains separate test profiles, the single building panel, specializations,
Reaper eligibility, the six buildings, listening-room tabs and useful bug reports.

Windows-specific checks still needed:

- Launch from a newly extracted folder, including a path with spaces.
- Test mouse double-clicks, held-click/Escape cancellation, keyboard controls and
  spectating at1280×720 and1920×1080.
- Verify real soundcard/headphone output and saved Music/Effects/Ambient/mute.
- Check Alt-Tab, fullscreen/windowed behavior and restoring focus during combat.
- Resume a legitimate existing profile without losing progression or inventory.
- Run a long Endless session and record hardware, frame-time symptoms and logs.

Do not infer native Windows validation from successful cross-export, ZIP integrity
or Linux embedded-pack tests. Those are separate checks documented in the report.
