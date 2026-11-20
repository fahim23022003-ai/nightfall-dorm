# Native Hunter catalog verification

The Godot verifier loads the real game scene into an X11 graphical
viewport at 1280×720. It stages an ordinary seeded Endless room, an exact
Hunter evolution level, legal hallway lanes and a purchased Needle
turret. It uses real movement calls and staged starting conditions.
The Needle damage, Hunter windup and door impact come from normal game
ticks. Each row samples four authored directional atlases while the
Hunter walks or turns. The arm endpoint must move relative to the
shoulder. After the damage event the same render path must show physical
contact, follow-through, recovery and return to ordinary posture.
An exact-level atlas is required for the sampled poses.

The catalog run samples the actual draw path at key frames. The
adjacent motion evidence contains continuous real-time films.
Rendering uses Linux Mesa llvmpipe. Human approval and native Windows
or Intel UHD performance are separate.

The optional lifecycle fixture starts a wounded Stalker in a seeded
V2 Campaign. It observes a genuine `nightmare_level` event, takes the
production Hunter spectate path during an actual Hall retreat, and
samples the rendered heal. The normal damage API then triggers a
death pose and fade. Lifecycle checks use one representative level
transition. The four-direction check covers all ordinary levels.

## Results

| Graphics preset | States | Distinct cardinal atlases | Raster samples | Assertions | Max socket error |
| --- | ---: | ---: | ---: | ---: | ---: |
| Standard | 60/60 | 240/240 | 1798 | 2095 | 0.05 world px |
| Low | 60/60 | 240/240 | 1798 | 2087 | 0.05 world px |

Both aggregates passed without failures. The counts include nine
retake rows on each preset after seam and overlap cleanup. Each retake
records the rendered atlas file hashes and supersedes the matching
earlier row. The independent aggregate checks all 240 files for unique
content. Both presets recorded Level 2 evolution, recovery in the
west Haunted Hall and the subsequent death fade.

[Standard aggregate](standard-summary.json) · [Low aggregate](low-summary.json) ·
[Named Hall recovery](stalker-hall-recovery.png) · [Gameplay regressions](regressions/README.md)

## Reproduce

Run in a graphical Godot 4.6.3 session, using a fresh temporary profile
directory for each preset. The verifier applies the animation preview
flags for the isolated fixture.

```sh
XDG_DATA_HOME=/tmp/nd-catalog-standard godot --path . --resolution 1280x720 --audio-driver Dummy \
  --script tools/visual_rebirth/verify_articulation_catalog.gd -- /tmp/nd-standard all all --lifecycle
XDG_DATA_HOME=/tmp/nd-catalog-low godot --path . --resolution 1280x720 --audio-driver Dummy \
  --script tools/visual_rebirth/verify_articulation_catalog.gd -- /tmp/nd-low all all --low --lifecycle
python3 tools/visual_rebirth/verify_articulation_receipts.py \
  --output /tmp/nd-standard-summary.json /tmp/nd-standard/articulation-catalog.json
python3 tools/visual_rebirth/verify_articulation_receipts.py --quality low \
  --output /tmp/nd-low-summary.json /tmp/nd-low/articulation-catalog.json
```

The verifier also accepts a single Hunter identifier and a comma-separated
list of levels to resume a shard. The strict aggregator requires one
passed row for each ordinary state and distinct hashes for all 240 atlas
files. Use the separate prescribed Reaper phase evidence for both
boss forms.

The `--cases=crusher:6,witch:7` option records targeted replacement
rows. The aggregator's `--replace` option maps each such row to its earlier
receipt and checks the latest art hash.
