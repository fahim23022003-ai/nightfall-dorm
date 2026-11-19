# Phase 14A pilot art progression

This plan translates the Visual Rebirth Art Bible into Stalker and Needle Turret construction specifications. The level table describes planned art. The current Stalker experiment uses a single Level 1 concept cutout. Its facing hint selects when Godot may draw that view. Four-view coverage, a complete rig and later level designs still require production and review.

## Camera and scale

The approved Phase 14 Hunter scale reference is the current Stalker pilot. Its neutral draw height is **104 game pixels**, twice the standing survivor's 52-pixel draw height, with a roughly 44-pixel-wide draw box and a fixed foot pivot. Use this scale when reviewing future Hunter art at the same camera zoom. [Approved in-game comparison](evidence/visual-rebirth/pilot/stalker-survivor-scale.png)

Use one orthographic render at 42.5° elevation, centered on the feet or base. Render Stalker yaw at quarter turns from a single coherent source, preserving asymmetrical hair and garment details. Keep her visible eye, bare shoulder, ragged dress and extended hands recognizable across the anchor forms. Reserve the dark floor-contact shadow for Godot compositing so it does not contaminate the art alpha.

The prepared Phase 13 Godot baseline at 1280×720 shows 16 tightly packed pads, the Hunter immediately below the selected room and the door HP just above the Hunter's right shoulder. It ran on Linux llvmpipe. The renderer's nominal building box is 54×67.5 with a pivot at 78% of height, before zoom or presentation scaling. Review alternate compositions inside this box and at actual zoom. Use slim pale or brass edge contrast where the dark room consumes material detail. Keep attack motion bounded around the door and preserve the existing warning overlays.

In the prepared 720p Stalker experiment, the pale face and shoulder read against the dark room. At door contact, the narrow body leaves the door HP and urgent warning readable. The dress crosses the door face and the head approaches the occupied bed. The experiment demonstrates scale and silhouette for one view. Turning continuity and room-wide art cohesion still need review.

## Physical progression

| Level | Stalker | Needle Turret |
| --- | --- | --- |
| 1 · Anchor | Thin hunched apparition, pale shoulder and one exposed eye, heavy asymmetric wet-black fringe, lowered long hands and torn charcoal dress. | Slender dark iron stand on a low stone base. One articulated launcher holds a tight cluster of spectral darts under a brass crescent. |
| 2 | Add a hanging lock across the cheek and a split at the off-shoulder sleeve. Extend the outer hem enough to read at room scale. | Add an external support collar with a distinct forked brace from stand to swivel. |
| 3 | Increase the forward shoulder roll and angle one long hand out from the dress to expose the finger silhouette. | Add a guided rear draw-slide with a visibly separate reciprocating rod. |
| 4 · Anchor | Drop the hair below the shoulder line, extend the fingers and separate both feet from the hem and visible ground shadow into a true hover. | Rebuild the single launcher into a pair of carriages on one swivel, with a wider dark-iron yoke and low crescent. Both carriages visualize the existing shot. |
| 5 | Add a strip of burial cloth tied at the bare shoulder. Keep one free end above the extended forearm for a readable secondary motion. | Fit the Heavy Precision reinforced cradle or the Suppression split-feed module when the saved specialization is present. Retain the base silhouette for an unspecialized turret. |
| 6 | Shift the rib cage ahead of the pelvis during holds. Extend the split train behind the body with a separate weighted drape. | Add a heavier slide guide and visible return stroke for Precision, or short alternate feed motion for Suppression. Fit an external return spring on the unspecialized carriage. |
| 7 · Anchor | Break the upright line with a pronounced torso bend, a widened hair mantle and long arms that frame the body. Keep fingers visibly connected to the hands. | Rebuild as a gothic spear flower with a compact radial housing and articulated arms that settle toward the existing target. |
| 8 | Give the two mantle tips separate drag and release motion through turns. Keep a gap between the tips and the arms in silhouette. | Add a rotating breech collar behind the radial assembly. Keep the shot count and projectile timing from the model. |
| 9 | Push the shoulders out of alignment, raise the veiled head and draw the train into two angular cloth points beside the torso. | Add a reinforced rib arch rising behind the breech and keep the stone footprint inside the pad. |
| 10 · Anchor | Tall hair-veiled phantom with a narrow column of dragged cloth and a markedly expanded reach. Keep the pale skin, bare shoulder and hair direction from Level 1. | Shape the final iron crown from fine projectile rails and one guarded central swivel. Heavy Precision keeps a reinforced central cradle and Suppression keeps paired feed guides. |

## Level 1 experiment checks

- Test the existing view inside Godot for alpha edges, scale, readable stance, movement and response to gameplay events. Compare with the Phase 13 baseline at the same camera and depth. Keep the current renderer for unsupported headings and levels.
- Inspect the Needle base, rotating carrier and visible recoil in the same room layout. Verify muzzle alignment and replay the reported movement using authentic target and shot events.
- Record findings at 1280×720 with 16 occupied pads and inspect positioning relative to door HP and attack warnings. Mark separately which tests exercised an event, a prepared pose or existing fallback.

## Full pilot and batch acceptance

- Compare the 1/4/7/10 rendered anchors at equal scale before finishing intermediate art. Measure silhouette difference using the symmetric difference divided by the union of aligned subject masks with alpha at or above 0.5. Compare neutral poses at a shared foot or base pivot, excluding particles and detached floor shadows. Review the Art Bible's approximate 25–35% Needle silhouette changes at Levels 4 and 7 alongside the actual images.
- Review Stalker front, back, left and right plus gameplay angles. Verify hair asymmetry, intact anatomical joins, occlusion at the shoulder and wrist during the attack and hair and cloth trailing through motion. Compare alpha edges on dark rooms and a light test background.
- Keep turret yaw on the separate swivel about the stand and recoil local to the carriage. Use a muzzle position derived from the presented firing direction for visual effects. Existing gameplay remains the source of targeting, hit and shot events. Never add a projectile for a visually articulated rail.
- `turret` specialization keys `precision` and `suppression` are defined in `scripts/strategy_catalog.gd`. `scripts/room_state.gd` applies an eligible specialization at the Level 4 to Level 5 purchase in strategy-enabled modes. Verify unspecialized upgrades and the two branches separately through Level 10. For Stalker use the model's existing movement, conceal, warning, attack, hit, recovery and evolution state. Render control must remain read-only.
- Compare Phase 13 and the pilot in prepared 720p and 1080p captures with the same room layout, camera and Hunter position. Inspect placement, selection, warning and door HP overlays and verify a real paid upgrade and real combat event. Track performance against the captured baseline in each rendering tier. Native Windows Intel UHD measurements and human approval require separate evidence.
