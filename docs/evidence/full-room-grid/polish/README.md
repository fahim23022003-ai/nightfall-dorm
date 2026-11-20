# Full Room Grid polish verification

[Godot screenshots and gameplay video](visuals/README.md) · [Standard and Low timings, 24–82 buildings](performance/README.md)

The collision and selection changes passed 11,274 geometry checks and 727 grid model checks. The fixtures cover typed rotations, overlapping machines, furniture, active characters, ownership and door-to-bed access. The grid model also checks that movement and undo preserve a machine's identity and wallet, upgrades preserve its anchor and orientation, and sales refund the paid investment. The 61 save checks include the earned wave-45 migration, the next wave, a 17-building roundtrip and fallback when migration cannot fit every investment. [Regression logs](regressions/)

All 60 purchase, upgrade and refund scenarios in each launch mode matched the prior receipts exactly. The six earned gameplay simulations in each mode matched their previous combat, targeting and wallet outcomes. The comparison excludes compute timings. The general regression runs passed 1,397 spatial checks, 64 spatial UI checks, 60 earned continuation checks, 179 save and effect checks, 4,062 input checks, 33 scene checks and 136 core assertions. [Transaction and simulation receipts](regressions/)

The Windows x64 export uses source `c460b71`. ZIP integrity, PE architecture and embedded game resources passed. Linux Godot passed 77 base pack checks, 384 Preview checks and 381 Reference checks. Each launcher has its own test-save profile. Native Windows behavior, Intel UHD performance and owner playtesting remain pending. [Export receipt and logs](windows/) · [Windows playtest checklist](../../../PHASE_14_FULL_ROOM_GRID_WINDOWS_CHECKLIST.md)
