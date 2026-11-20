# Hell Tactics Windows x64 export

The private Windows playtest was exported from source commit `9bc53ea` with
the official Godot 4.6.3 x64 release template. The launcher profiles are
separate from existing player and playtest saves. Native Windows execution
and Intel UHD performance are unverified. [Export receipt](windows-artifact.json) ·
[Test instructions](../../../HELL_TACTICS_WINDOWS_PLAYTEST.md)

| Embedded pack check | Assertions | Failures |
| --- | ---: | ---: |
| Base pack and scene | 77 | 0 |
| Hell Tactics preview with V2 maps | 57 | 0 |
| Procedural V1 fallback | 57 | 0 |
| Fixed reference fallback | 36 | 0 |
| Phase 14F art enabled | 384 | 0 |
| Phase 14F art disabled | 381 | 0 |

Linux Godot loaded the embedded pack from the same PE x64 executable that
shipped in the archive. The procedural checks exercise all three Campaign
difficulties, paid grid placement, Hall routes, geometry roundtrips and the
unchanged Endless tactics gate. [Preview log](windows-pack-hell-preview.log) ·
[V1 log](windows-pack-v1-fallback.log) · [Reference log](windows-pack-fixed-reference.log)

The two transfer ZIPs pass CRC and reconstruct the exact export SHA-256.
Part 1 includes a CRLF Windows helper that checks the combined checksum
before extracting the game. [Transfer and reconstruction receipt](playtest-parts.json)
