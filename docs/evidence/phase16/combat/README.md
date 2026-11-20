# Dense combat and Build interaction captures

Godot 4.6.3, 1280×720, Linux llvmpipe. Each 6.5-second clip comes
from one continuous Godot Movie Maker run at a fixed 24 fps with
normal in-game progression and Godot's stereo Master mix. These clips
document the view, combat and feedback. Uncapped performance is measured
separately. [Independent performance runs](../performance/)

| Live 60-machine exercise | Clip | Gameplay still | Engine tests |
| --- | --- | --- | --- |
| Stalker evolution 6, Standard | [MP4](stalker-medium.mp4) | [PNG](stalker-medium.png) | 138 passed |
| Stalker evolution 6, Low | [MP4](stalker-low.mp4) | [PNG](stalker-low.png) | 138 passed |
| Reaper evolution 6, Standard | [MP4](reaper-medium.mp4) | [PNG](reaper-medium.png) | 141 passed |

The crowded fixture uses actual Full Room Grid footprints, real
combat, animated Hunter strikes, projectiles and the player's door.
It supplies funds and a late-match setup to reproduce a dense fight.
The Reaper starts from a deliberately prepared transformation at a
reachable doorway. The clips are controlled QA captures rather than
recordings of unscripted human play. Per-clip stream metadata and
engine output accompany each video.

The compact 960×540 interaction run exercised the menu and verified
that current Build prices and selection previews load when the drawer
opens. All 46 checks passed. [Story preparation](compact-story-preparation.png)
· [Build drawer](build-compacted.png) · [Needle placement](build-needle-placement-compact.png)
· [Dynamo placement](build-dynamo-placement-compact.png) · [Godot log](ui.log)
