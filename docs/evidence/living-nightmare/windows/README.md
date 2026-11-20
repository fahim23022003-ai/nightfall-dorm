# Windows x64 Living Nightmare preview

The export uses official Godot 4.6.3 Windows x64 templates and gameplay
source `ac95e17`. The PE executable and embedded resource pack passed
structural checks. Linux Godot verified the pack from an empty directory.

| Embedded verification | Checks | Failures |
| --- | ---: | ---: |
| Base pack | 77 | 0 |
| Living Nightmare V2 route | 57 | 0 |
| V2.3 fallback | 57 | 0 |
| V1 fallback | 57 | 0 |
| Fixed fallback | 36 | 0 |
| V2.3 fast-route and ordinary wallet | 61 | 0 |
| Story launch, catalog, 16 rig textures and five new audio assets | 80 | 0 |
| Phase 14F enabled | 384 | 0 |
| Phase 14F disabled | 381 | 0 |
| Total | 1190 | 0 |

An initial invocation reached all 80 assertions and logged a transient
ObjectDB warning at shutdown. The verifier now follows the existing
pack-test teardown protocol with time for Godot to release audio and
return-to-menu resources. The notes here use the clean export run.

The launchers use separate preview profiles. The archive includes the prior
V2.3, V1, and fixed modes. Native Windows playback and Intel UHD results
are unverified. [Package instructions](../../../LIVING_NIGHTMARE_WINDOWS_PLAYTEST.md)

Both transfer ZIPs passed CRC and recreated the consolidated archive at its
exact SHA-256. Extract the two downloads into the same empty directory,
run **Join and Extract.cmd**, then start **Play Living Nightmare Preview.cmd**.
[Export receipt](windows-artifact.json) · [Transfer hashes](playtest-parts.json)
