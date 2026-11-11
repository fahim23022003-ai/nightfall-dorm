# Visual overhaul report

11 November 2026, Singapore. **Substantial overhaul implemented and verified; final commercial visual polish remains PARTIAL.**

The previous presentation used programmer placeholders: flat room rectangles, circle residents, a triangular hunter, letter-marked machines and a permanent text-button sidebar. Those visuals should not have been described as finished artwork. This task rebuilt the actual presentation rather than recoloring that layout.

## Preserved gameplay and checkpoints

- Starting verified implementation: `ca22bd5b042b36a8e86f5729d05aa15e74c1340e`.
- Pre-overhaul checkpoint: `19201bb503ecce78fa09780c1448eb77c864872b`.
- Tested overhaul source/art checkpoint: `e7a7ab12c6e53290e5ae9501fef9d83bfb9b0b86`.

Economy, purchase rules, building effects, turret damage/range/cooldowns, hunter FSM, survivor spending policies and terminal rules were retained. Presentation is now separated into `dorm_presentation.gd`; `game.gd` handles input/orchestration and `interface.gd` handles UI. A fixed view offset translates unchanged model coordinates into the new centered composition. Furniture foot-point collision was added, with all six door-to-bed routes explicitly retested. Sleeping remains proximity-gated, so the player need not walk into the mattress.

## Actual changes

### Art and environment

- Created a coherent original illustrated atlas specifically for Nightfall Dorm: beds, quilt/pillow detail, cabinets/books/ferns, lantern, wood and reinforced doors, two survivor bases, walking/sleep poses, a five-state midnight moth hunter, and six recognizable machines.
- Stored 24 atlas crops, eight original environment/HUD textures and a project icon: **33 runtime PNG assets**, plus the retained original atlas and Windows ICO. No Haunted Dorm assets were extracted or copied. Preparation source and provenance are in [ART_MANIFEST.md](../assets/ART_MANIFEST.md).
- Replaced flat floors with staggered timber/grain textures and a tiled corridor with an inlaid runner. Added raised wall faces, trim, windows, room plaques, furniture, lantern glows and contact shadows.
- Replaced numbered empty boxes with engraved foundation sigils. The player room has an explicit YOUR ROOM badge, stronger border and brighter build markers.
- Replaced all circle/square actor placeholders with illustrated sprites. The hunter is an original masked moth-like apparition, not the old triangle.

The six-room corridor topology remains deliberately intact to preserve navigation. This is a complete rendering redesign, not a new map/navigation graph. Authentic Haunted Dorm layout equivalence remains unverified because reference access is blocked; the overhaul is based on the user's visual requirements and actual before/after frames, not invented reference details.

### Interface

- Removed the permanent right-side debugging panel. A compact top HUD now has currency/power art, preparation/night phase, hunter HP and pause control.
- Added an illustrated bottom room dock for bed, door and repair, including current/max door HP and real prices.
- Floor selection opens six illustrated build cards in a **compact bottom tray below both wings**. Selecting a built machine opens its focused upgrade inspector. The tray blocks input from reaching controls underneath it.
- Availability, specific failure reasons, costs, caps and tooltips remain functional. Unavailable controls are disabled and visually distinct.
- Added a real pause overlay with Resume and Return to main menu. Escape closes a context tray first, then pauses/resumes.
- Rebuilt the menu as an illustrated moonlit bedroom vignette with display typography; rebuilt results as a framed outcome report with original trophy/hunter art.

### Animation and feedback

- Idle breathing and pose-based walking, actual sleeping art, five resident palette variants using two base designs.
- Hunter float/move poses, attack pose tied to attack cooldown, hurt/recoil pose, dissolving death art and a brief result reveal that lets the death read before the report.
- Turret aim motion, real attack traces, muzzle glow, hit sparks, level pips, income floats and purchase feedback.
- Wood/reinforced door art, damage cracks/flash, broken planks, conspicuous own/target door HP and a pulsing attack target mark.

These are lightweight sprite/transform animations, not a professionally rigged four-direction animation set. Lighting is layered glow/contact-shadow art, not a dynamic occlusion/light simulation.

## Genuine before / after evidence

All AFTER images are actual Godot viewport captures, not artwork mockups. The [screenshot index](screenshots/visual_overhaul/README.md) records setup and capture qualifications.

| View | Before | After |
| --- | --- | --- |
| Main menu | [Original](screenshots/01-main-menu.png) | [Illustrated menu](screenshots/visual_overhaul/01-main-menu.png) |
| Full dormitory | [Flat map](screenshots/02-full-dormitory.png) | [Furnished environment](screenshots/visual_overhaul/02-full-dormitory.png) |
| Build interaction | [Sidebar](screenshots/06-turret-built.png) | [Context cards](screenshots/visual_overhaul/06-turret-built.png) |
| Developed room | [Letter machines](screenshots/07-electricity-support-buildings.png) | [Illustrated machines](screenshots/visual_overhaul/07-electricity-support-buildings.png) |
| Hunter / door combat | [Triangle](screenshots/09-hunter-attacking.png) | [Moth hunter and HP](screenshots/visual_overhaul/09-hunter-attacking.png) |
| Turret fire | [Original traces](screenshots/10-turrets-firing.png) | [Sprite combat](screenshots/visual_overhaul/10-turrets-firing.png) |
| Outcome | [Original report](screenshots/11-victory.png) | [New victory](screenshots/visual_overhaul/11-victory.png), [defeat](screenshots/visual_overhaul/12-defeat.png) |

The final capture session uses fixed seeds and scripted room claim/bed positioning, then production BotAI spending from ordinary starting resources; no funds, damage, buildings or result are injected. A passive run naturally loses. Engine time is accelerated fourfold. Combat captures briefly pause actual reached states, and display PAUSED. Walking/idle frames use actual parsed keyboard input, with `player_walking=true/false` in the log. These are disclosed automated runs, not manual-player skill evidence.

Seventeen final images were saved, including developed room, contextual upgrade inspector, pause overlay and hunter dissolution. The native captured viewport is **1137×800** on the available 1280×800 Xorg display, letterboxed from the 1280×900 logical design. Do not describe these as native Windows frames. [Raw final capture log](evidence/visual_overhaul/rendered-matches.log).

## Problems caught and corrected during implementation

- Source-sized TextureRects initially overflowed the HUD and cards. Fixed expansion/sizing order and added explicit illustration-bound assertions.
- Card text initially competed with the illustrations. Replaced newline-padded button text with separately positioned art/name/price components.
- Independent visual review found faint owned-room markers, weak tactical HP readability and context panels hiding another wing. Added owner badge/bright sigils, current/max HP sidecars, and a bottom-only tray. The reviewer re-inspected updated frames and confirmed all three corrections.
- A new input test initially omitted global mouse coordinates; the test fixture was corrected. It is not counted as a product defect. Final real viewport input checks pass in both wings.
- A synchronous external window grab stalled a preview capture; the helper now saves the engine's actually rendered viewport after `frame_post_draw`. Failed/oversized previews were not used as final acceptance screenshots.

## Tests actually executed

The final regular `bash tools/check.sh` passed with exit 0 and clean error scans:

| Check | Result |
| --- | --- |
| Import/main-scene startup | PASS |
| Production gameplay assertions | 125 passed |
| Adapted scene/input checks | 31 passed; prior behaviors retained, actual card hit path and sprite bounds added |
| Overhaul-specific interaction checks | 46 passed: bottom-wing selection, contextual purchase, no wing occlusion, no covered-control click-through, Escape/pause, delayed result/restart |
| Furniture collision/reachability | 30 passed across all six rooms |
| Purchase availability | 3,209 passed |
| Audit regressions | 71 passed |
| Financial properties | 20,000 transactions, 175,941 checks passed |
| Attack-rate scenarios | 6 passed |
| Representative headless matches | 12 completed: 9 wins, 3 losses, zero unresolved |

[Consolidated verified output](evidence/visual_overhaul/verified-regressions.log). Final rendered acceptance additionally completed two natural matches: active victory at about **149.56 simulated seconds**, passive defeat at about **41.74 seconds**. Preview iterations were used to find/fix integration problems and are not substituted for the final acceptance run. The older 144-run matrix was not needlessly repeated because AI/economy/combat rules were unchanged.

Existing UI tests were adapted to the new positions/control identities, preserving their behavioral assertions. No failing gameplay assertion was removed to obtain a pass. New UI and collision cases are part of the reusable regular wrapper.

## Independent judgment and remaining weaknesses

Only one specialist role, Agent D, was activated for a bounded screenshot critique and confirmation of its three findings. [Independent review](VISUAL_OVERHAUL_REVIEW.md): **visual 7/10, UX 8/10** after corrections. It judged the old programmer-art impression largely removed and all major objects recognizable, but described the result as an **illustrated indie prototype rather than finished commercial presentation**. This report accepts that distinction.

- A player can now identify furnished bedrooms, illustrated characters, doors, machines and contextual controls. It is visibly a dormitory defense game.
- Final art/animation polish is not complete: only two survivor base designs, shared sleep art and sparse walk/ghost poses; no complete directional animation system or bespoke elimination sheet.
- The map retains one rectangular six-room plan. Furniture and materials are coherent but decoration variety, wall perspective refinement and atmosphere can improve.
- Lighting/shadowing is stylized/baked; turret aiming is limited sprite aim motion, not a full directional turret-art set.
- Small-screen typography, high-DPI Windows behavior, physical audio and target-device performance still need validation.
- Exact Haunted Dorm gameplay/visual similarity remains UNVERIFIED; no accessible authentic screenshot/video was used to claim parity.

The correct outcome is **a substantial, working visual overhaul saved for playtesting, with commercial-grade finishing still partial**. No final-polish or reference-equivalence completion claim is made.

## Build, Git and continuation

The updated Windows x64 export is created from the tested source checkpoint using the previously SHA-512-verified official Godot 4.6.3 templates. Its executable uses embedded game data and the new original project icon. The exported pack is smoke-tested with Linux Godot from an empty directory; **native Windows execution remains UNVERIFIED**. Generated binaries are not pushed into source Git.

Updated artifact: `/workspace/NightfallDorm-VisualOverhaul-Windows-x64.zip`. [Export log](evidence/visual_overhaul/windows-export.log), [artifact checksum](evidence/visual_overhaul/windows-artifact.json), [pack smoke](evidence/visual_overhaul/pack-smoke.log). The engine and DejaVu font notices are included in the ZIP.

The source/art checkpoint above was pushed successfully to authorized private `work`. Report/evidence completion is committed and pushed afterward, with a fresh remote-SHA comparison before the final response. No public deployment or release is performed.

Next: inspect this new build on the actual laptop, then prioritize one dedicated art/animation finishing pass using the screenshot critique. Preserve the tested model and adapted input checks. Do not restart the project or silently treat prior prototype scores as commercial art approval.
