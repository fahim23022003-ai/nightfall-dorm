# Windows x64 playtest export

The archive was built with the official Godot 4.6.3 Windows x86-64
template from source commit `2b302a0`. The exporter checked the PE
architecture, embedded Godot pack, executable checksum and every
entry's ZIP CRC. Linux Godot then loaded the embedded pack separately
from the source tree. It verified 248 rig atlases, all 50 Story entries,
Story match startup, the fallback launch modes and the visual catalog.
[Export receipt](windows-artifact.json) · [Story and rig check](windows-pack-living-nightmare-story.log)

The two private delivery ZIPs reconstruct the exact verified archive.
Both outer ZIPs passed CRC verification and the names and sizes matched
their uploaded entries. Download and extract both into the same empty
folder, run **Join and Extract.cmd**, then open **Play Living Nightmare
Preview.cmd**. The existing test profile, V2.3, V1 and fixed reference
launchers remain available. Native Windows play and Intel UHD
performance were unmeasured.
[Transfer checksum receipt](playtest-parts.json) · [Owner checklist](../../../LIVING_NIGHTMARE_WINDOWS_PLAYTEST.md)
