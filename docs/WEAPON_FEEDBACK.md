# Weapon Impact & Damage Feedback

The starting GitHub `work` checkpoint was `02d63a8`. Model-owned
projectiles already flew and applied damage on impact. Needle, Arc, Flame
and Frost had small world-scale effects. Short shots could pass between
draws, and launcher visuals used a short history that omitted the source
building ID. The weapon inspector could show expected stats and upgrades.
It had no record of the selected machine's effective hits.

The new renderer follows the existing projectile path. It starts at the
visual socket for the source machine, uses the captured launch bearing and
joins the authoritative path. A very short shot can leave a brief trace
after a real impact. A cancelled shot leaves no impact trace or number.
Needle darts, Arc bolts, flame trails, frost shards and Shock arcs use
distinct silhouettes and branch accents. The Mirror Barrier shows an arc
only when its actual reflect rule deals damage. Passive buildings retain
their own operational visuals. Attack timing, elemental rules, target
selection, applied damage and projectile simulation are unchanged.

The retained receipt records building ID and instance, room, projectile,
level, specialization, target, contact time and HP before and after. The
floating value is the HP actually removed. Regular values round to two
decimal places and trim trailing zeroes. A positive value below `0.005`
reads `<0.01`. Simultaneous compatible hits add their original floating
point values before display rounding. **BURN**, **BLOCKED** and **IMMUNE**
use distinct treatments. Burn ticks do not keep a target in a cosmetic
hurt pose. Standard and Low preserve projectile, contact and number
feedback. The existing audio voice pool and cue cooldowns cap combat audio.

The Settings menu persists **All**, **My weapons**, **Combined** and
**Off**. All is the default. Number layout uses separate positions near
the target, cached text shaping and bounded on-screen effects. The
inspector shows the last successful effective hit, cumulative damage,
separate burn contribution, hit count, target, interval and range. An
existing Endless checkpoint can load without these counters. New
checkpoints carry them as optional per-machine data. A sold weapon's
late shot can still land according to the original rules. It cannot
credit a replacement on that pad.

## Godot recordings and proof

The recordings use the live scene and audio mix at 1280×720, 24 fps,
with normal in-game speed. Each prepared fixture uses real paid machines
and existing combat transactions. [Clips, screenshots and receipts](evidence/weapon-feedback/)

Eight matched performance pairs tested 10, 24, 40 and 60 machines in
Standard and Low. In the 60-machine Low case, the wall median was 59.19
to 57.97 ms and p95 was 73.23 to 75.23 ms on Linux llvmpipe. The captured
busiest volleys can still place adjacent labels close together in **All**
mode. **Combined** reduces the number of labels. [Benchmarks](evidence/weapon-feedback/performance/)

Twenty-nine suites passed. An older audio fixture reproduced the same
six Haunted Hall assertions on both sides. [Regression receipts](evidence/weapon-feedback/regressions/)

## Windows

**Play Weapon Feedback Preview.cmd** uses the existing Living Nightmare
preview save. **Play Phase 16 Preview.cmd** loads the previous presentation
for comparison. Earlier launchers are included. Linux Godot verifies the
Windows executable's embedded pack. Native Windows and Intel UHD remain
untested. [Playtest guide](WEAPON_FEEDBACK_WINDOWS_PLAYTEST.md)
