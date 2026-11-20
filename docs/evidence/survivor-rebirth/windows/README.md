# Nightmare Lobby Windows x64 export

The build uses source `af59104` and the Godot 4.6.3 Windows x86-64
template. The export verified the PE header, the embedded resource
pack and the final ZIP CRCs and hashes. Linux Godot opened the embedded
pack in isolation. It drove the Story lobby through auto-ready, then
verified five physical runners, their common spawn, empty initial
room ownership and a physical Full Room Grid claim. It also checked
the retained launchers, all 50 Story entries and all 248 Hunter and
Reaper atlases.

The two private delivery pieces matched their uploaded names and byte
counts. The local join check reproduced the full archive byte for byte.
Extract both downloaded ZIPs into the same directory, run
**Join and Extract.cmd**, then launch **Play Nightmare Lobby Preview.cmd**.
Native Windows and Intel UHD performance remain unmeasured.
[Archive receipt](windows-artifact.json) · [Embedded lobby check](windows-pack-survivor-lobby.log) · [Delivery checksums](playtest-parts.json)
