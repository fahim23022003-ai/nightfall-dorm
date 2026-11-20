# Hunter artwork Windows x64 preview

The archive uses Godot 4.6.3 and production source `4a41219`.
The executable is a Windows PE x64 file with embedded resources.
Linux Godot loaded that pack from a separate empty workspace and
passed 1,246 checks, including all 72 rig atlases, the Story launch,
audio resources, Full Room Grid and existing fallback paths.
Windows execution and Intel UHD performance were not measured.

Both transfer ZIPs passed CRC. Their payloads reconstructed the exact
archive SHA-256. Extract them to the same empty directory, run
**Join and Extract.cmd**, then open **Play Living Nightmare Preview.cmd**.
The previous preview profile name and fallback launchers are retained.

[Package hashes](playtest-parts.json) · [Export receipt](windows-artifact.json) ·
[Playtest instructions](../../../LIVING_NIGHTMARE_WINDOWS_PLAYTEST.md)
