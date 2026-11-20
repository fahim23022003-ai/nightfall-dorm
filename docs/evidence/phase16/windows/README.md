# Phase 16 Windows x64 playtest package

The package was exported from `9cd4ed56456f77e70a271be342c4e6daa848ccc1`
on `work` with the official Godot 4.6.3 Windows x64 template. Later
commits add verification, captures and documentation. The packaged game
sources and assets are identical.

The Windows executable passed archive CRC and SHA-256 checks. Linux
Godot opened its embedded PCK, verified the fallback launch modes and
the Living Nightmare visual inventory, and ran 28 Phase 16 checks
covering Story rules, offline auto-ready, shared spawn, legal placement,
and the new Low graphics textures. The Linux run verifies packed
resources and game logic. Native Windows and Intel UHD are untested.

Extract both download ZIPs into the same folder. Run **Join and
Extract.cmd** and then **Play Phase 16 Preview.cmd**. Keep the older
launchers for comparison. The launcher uses your current Living
Nightmare profile. [Playtest and on-device benchmark instructions](../../../PHASE16_WINDOWS_PLAYTEST.md)

The full ZIP is 174,750,217 bytes and its SHA-256 is
`199de3dfca9b67f9bfcad02620c76f1cf25a81da176ec884d8f814eb388b059b`.
The delivery parts were reassembled and verified against that checksum.
[Full archive and executable receipt](windows-artifact.json) · [Part checksums](playtest-parts.json)
