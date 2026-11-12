# Current Phase 6 Windows candidate

Version 0.6.0-rc1, Godot 4.6.3. Current export/checksums, pack audit and remaining
native validation are recorded in [PHASE_6_FINAL_AUDIT_REPORT.md](PHASE_6_FINAL_AUDIT_REPORT.md).
Use [WINDOWS_PLAYTEST_GUIDE.md](WINDOWS_PLAYTEST_GUIDE.md) for fresh isolated test
profiles, save backup, launch/export and Fahim/Adie playtest instructions.
An export built on Linux is not a native Windows execution pass.

The records below are preserved historical exports and are not the current build.

---

# Windows readiness

Latest visual-overhaul artifact: `/workspace/NightfallDorm-VisualOverhaul-Windows-x64.zip`, from source `e7a7ab12c6e53290e5ae9501fef9d83bfb9b0b86`. It was rebuilt with illustrated assets, new UI, custom icon and font notices. See `evidence/visual_overhaul/windows-export.log`, `windows-artifact.json` and `pack-smoke.log` in that evidence directory. Native Windows runtime remains unverified. The earlier ZIP/checksum described below is historical.


**Release export CREATED; native Windows runtime UNVERIFIED.** The produced file is `builds/windows/NightfallDorm.exe`, with an embedded game pack, x86-64 PE format. A ZIP playtest artifact is available in the task workspace at `/workspace/NightfallDorm-Windows-x64.zip`. No public deployment/release was made. Generated executables are ignored by Git; source, preset, checksums and evidence are backed up on the authorized private branch.

## Verified build process

1. Godot 4.6.3 stable was already installed. Matching export templates were initially absent.
2. Downloaded the official `Godot_v4.6.3-stable_export_templates.tpz` and official `SHA512-SUMS.txt` from the Godot builds GitHub release. The full 1,255,918,323-byte archive matched its published SHA-512 **before** Windows templates were extracted. See [verification](evidence/windows-template-verification.txt).
3. Installed only matching Windows x86-64 release templates into the current machine's writable Godot template directory.
4. Added [export_presets.cfg](../export_presets.cfg) with Windows Desktop/x86-64, embedded PCK and documentation/test/tool exclusions. Export completed with exit 0 and no export errors; [log](evidence/windows-export.log).
5. Verified PE machine `0x8664`, an embedded GDPC pack footer, file size and SHA-256; [artifact record](evidence/windows-artifact.json).
6. Loaded the EXE's embedded pack with the **Linux** Godot engine from an otherwise empty directory, and started the actual main scene without errors; [pack smoke log](evidence/windows-pack-smoke.log). This verifies bundled resources/class paths, not Windows execution.

Production scripts have no `/workspace`, `/tmp`, X11, shell-command or external service dependency. Rendering/capture helpers are excluded. Dependencies listed by PE inspection are Windows system DLLs. The project uses standard Godot/GDScript and local assets, with GL Compatibility rendering. These checks support portability but cannot certify a particular laptop, GPU, audio device or Windows configuration. No Windows host or Wine is available here.

## Local reproduction

Install standard Godot 4.6.3 and its matching official export templates, then:

```sh
godot --headless --path . --export-release "Windows Desktop" builds/windows/NightfallDorm.exe
```

On this cloud machine set the writable XDG directories documented in README first. Export templates and live processes are current-machine state, not proof of a published environment snapshot. The archive checksum verification must not be bypassed if templates are downloaded again.

## Windows manual test

Unzip the artifact and launch `NightfallDorm.exe` on Windows 10/11 x64 with an OpenGL 3.3-capable driver. The editor is not needed. This is an unsigned playtest build; the engine license and executable checksum are included.

Verify menu/settings/fullscreen/volume, room entry and sleeping, income, distinct build tiles, generator power, upgrade prerequisites, repairs, turret attacks, hunter breach, victory, defeat, restart and return to menu. Record Windows/GPU details, performance and exact errors. In particular verify audio and high-DPI scaling, which Linux headless tests cannot establish. Do not classify Windows runtime as PASS until this is actually performed.
