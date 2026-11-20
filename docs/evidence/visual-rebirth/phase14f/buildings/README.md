# Phase 14F building animation audit

The opt-in building renderer was drawn directly in an isolated 1280×720 Godot 4.6.3 viewport using Mesa llvmpipe. The audit resolves the production branch IDs, atlas rows and renderer calls for all 17 families. All 170 baseline looks and 200 reachable branch looks produced distinct idle pixels within their own family. Bed and Door branches begin at displayed level 6.

| Renderer path | Visual states | Observed render variation |
| --- | ---: | --- |
| Nine mechanical phase families | 198 | Eight distinct rendered poses per state |
| Needle, Arc and Flame | 66 | Twelve active bearings plus the idle weapon pose |
| Frost Tower | 22 | Fixed crystal with a rendered discharge response |
| Mirror Barrier, Ward Antenna, Bed and Door | 84 | Fixed building art. Gameplay and room effects are drawn by other presentation paths. |

The harness passed 2,284 staged variation checks and 198 reduced-motion checks. Positions, fire or activity input and presentation time were staged to verify the render paths. Pixel comparisons crop the sprites above their state labels. Player recognition and native hardware frame rates remain unverified by this harness. [Audit JSON](catalog-render-audit.json) · [Godot log](catalog-render-audit.log)

Representative isolated Godot plates show all states for the Needle and Door. [Needle active](needle-catalog-active-720.png) · [Door static](door-catalog-idle-720.png)

## Paid activation and expiry

In a prepared Endless room the test used the actual upgrade and operation methods for both branches of Auto Repair, Shield Generator and Decoy Beacon. It checked the real resource costs and output and verified a local in-game pixel change from activation to expiry for every branch. The camera and presentation time stayed fixed between the sampled states. The crop plate enlarges regions of actual 1280×720 gameplay captures. [Active and expired crop comparison](paid-support-active-expired-crops.png)

| Family | Checks | Failures |
| --- | ---: | ---: |
| Auto Repair | 49 | 0 |
| Shield Generator | 51 | 0 |
| Decoy Beacon | 49 | 0 |

The stricter capture first exposed identical active and expired game frames. The map renderer had overwritten its opt-in support activity with the legacy cooldown-based expression. The opt-in renderer now reads the actual activity state, while the same legacy expressions continue to drive fallback. The vacant Auto Repair mechanism rests even when its model cooldown is paused. The weapon presentation also ignores stale projectiles of a different kind when resolving its bearing. The game still decides the actual target, cooldowns, operation costs and outcomes. [Auto Repair log](paid-auto_repair.log) · [Shield log](paid-shield.log) · [Decoy log](paid-decoy.log)

To reproduce the isolated renderer audit, run on a graphical display from the repository root.

```sh
NIGHTFALL_VISUAL_REBIRTH=1 godot --path . --resolution 1280x720 --audio-driver Dummy \
  --script res://tools/visual_rebirth/audit_building_animation.gd -- /absolute/output/directory
```

For a paid operation fixture, use `res://tools/visual_rebirth/capture_operated_support.gd` and add its family ID after the output directory.
