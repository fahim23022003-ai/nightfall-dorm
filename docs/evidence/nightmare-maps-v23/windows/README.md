# V2.3 Windows playtest verification

The official Godot 4.6.3 Windows x64 release template exported the
executable from gameplay source `f44a835`. Linux Godot opened the same
embedded pack from an otherwise empty project directory. The ZIP CRC
and packaged executable checksum passed. The export includes the
V2.3 preview, V1 fallback and fixed reference launchers, each with
its own isolated playtest profile.

| Embedded pack suite | Checks | Failures |
| --- | ---: | ---: |
| Base executable and Godot scene | 77 | 0 |
| Fair Starting Rooms preview | 57 | 0 |
| Exact Hell Labyrinth room warning and wallet | 61 | 0 |
| V1 fallback | 57 | 0 |
| Fixed reference | 36 | 0 |
| Phase 14F assets enabled | 384 | 0 |
| Phase 14F assets disabled | 381 | 0 |

Native Windows operation and Intel UHD performance remain unverified.
[Archive SHA-256 and launcher profiles](windows-artifact.json) ·
[Windows instructions](../../../FAIR_START_WINDOWS_PLAYTEST.md)

The two Drive transfer ZIPs passed CRC and reconstructed the full archive
at the exact export SHA-256. Drive metadata readback matched both filenames,
sizes and the destination folder. Extract both parts into the same empty
folder and open **Join and Extract.cmd**. The helper checks the combined
archive's SHA-256 before extracting the game.
[Transfer verification](playtest-parts.json)
