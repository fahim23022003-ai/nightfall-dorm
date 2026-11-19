# Phase 14 visual production preflight

The Phase 13 playable baseline is `36b771f3819d1a978833e19088b575a4bb360d66` on `work`. Phase 14 has verified the handoff and production tools. The Stalker and Needle Turret art pilot remains pending, and the full batch has not started.

## Handoff and coverage

Google Drive delivered the standalone Master Prompt and asset manifest and the separate Hunters and Buildings ZIPs. The ZIPs passed CRC checks. All 24 RGBA images decoded, have distinct SHA-256 digests, and match the manifest's paths. The Art Bible was present. The original combined ZIP was skipped. The four input digests and each reference's dimensions and digest are in the [production inventory](evidence/visual-rebirth/ASSET_MANIFEST.json).

| Inventory | Verified input | Planned baseline | Verified production output |
| --- | ---: | ---: | ---: |
| Ordinary Hunters | 6 concepts | 60 levels | 0 |
| Grim Reaper | 1 concept | 2 forms | 0 |
| Placeables, bed and door | 17 concepts | 170 levels | 0 |
| Specializations | 34 branch IDs in source | 204 L5–L10 variants | 0 |

The baseline includes unbranched L5–L10 for legacy saves. Needle maps to runtime kind `turret`, with `precision` and `suppression` branches. Bed and door use an internal index one below their displayed level. The inventory records production status and leaves output records empty until verified.

## Capability checks

- Tripo API, website and documentation returned proxy CONNECT 403 before reaching the origin. No Tripo connector or configured Tripo credential was found. No upload, model generation, credit purchase or paid request was made.
- Blender 4.3.2 Cycles CPU rendered a transparent 64×64 PNG and exported a GLB from a generic scene. Godot 4.6.3 imported both in an isolated project. This confirms the local render and import path. CPU denoising needed to be disabled because OpenImageDenoise is missing. The GLB used no Draco compression.
- A dummy Xorg display ran Godot's OpenGL Compatibility renderer on Mesa llvmpipe. Intel UHD timing and native Windows execution require a target machine. The first comparison should use identical 1280×720 room, quality and camera settings, a 60 fps target (16.7 ms/frame), and record frame-time median and p95, startup, RAM and atlas sizes for both builds.

## Phase 13 baseline

The [1280×720 Godot viewport capture](evidence/visual-rebirth/phase13-full16-720.png) shows a Level 1 Stalker at the door, the warning HUD and all 16 occupied slots including a Level 1 Needle. The deterministic seed 71 legacy fixture used prepared resources, bed and door upgrades, and bots. It executed seven paid expansions, 16 legal purchases and upgraded the other 15 structures to L10 through gameplay APIs. The Hunter pose, time and evolution were staged and the model was frozen while presentation ran. The Linux software-rendered capture passed 163 fixture checks. The core, Nightmare Hunt, scene and spatial-save suites passed 136, 10, 33 and 179 checks respectively with zero failures. These checks establish the comparison baseline.

## Pilot recipe

1. Author the Stalker and Needle source geometry offline or obtain equivalent editable source. Start at L1 using the supplied identities. Both references are single posed views with partial-alpha fringes. The Stalker's rear, flanks and covered anatomy and the Needle's occluded launcher parts must be authored. Validate L1 under fixed orthographic lighting and a 40–45° elevated gameplay camera at native room scale.
2. Keep the Stalker's asymmetrical hair, exposed shoulder and reaching hands consistent across four independent views. Rig the anatomy, cloth and hair with a common ground pivot and cast, fingertip, chest and mouth sockets. Author L4, L7 and L10 around the lowered hair and hover, bent torso and widened mantle, then tall veiled form. Fill intermediate levels from their adjacent anchors.
3. Build the Needle as an independently aimed carriage above a stationary base. Retain the tripod, brass crescent and darts through the paired carriage at L4, spear-flower at L7 and fine rail crown at L10. Author reinforcement, spring or reload assemblies at intervening levels. From L5, give Precision a concentrated carrier and Suppression a linked feed. Use fixed ground/footprint anchors, yaw samples, muzzle coordinates and recoil transforms. An extra visible rail must never imply an extra shot.
4. Bake to straight-alpha 2.5D sprites. Export the editable source, explicit rig/layer or joint hierarchy, pivots, event-to-clip mapping, and an output record keyed by runtime ID, level or boss form, branch, direction and animation. Record dimensions, source/output digests and QA status. Check alpha against a light background and the actual room. Compare silhouette masks aligned at the shared pivot, then review each level at room scale. Inspect Needle anchor differences against the Art Bible's approximate 25–35% guideline.
5. Integrate at the draw layer with a reversible fallback. For the Stalker, keep overlays and boss routing in `dorm_presentation.gd` and `nightmare_presentation.gd`. Use visual heading and the model's existing warning, strike, conceal, recovery, Lantern Snare and Hollow Oath events. For Needle, use `building_evolution_visual.gd` and the existing render and preview routes. Aim and animate from actual projectile targets, including undead, and ensure a new decorative muzzle flash replaces the current flash when enabled. Keep projectile origin, target, timing, collision, economy, model state and save schemas untouched.
6. Capture actual attack and upgrade sequences alongside the fallback view and verify all four Stalker directions, honest socket placement, branch motion, reduced motion, 16-slot readability, paid upgrade visuals, warnings and door HP. Run the existing core, scene, Nightmare Hunt and spatial-save regressions and compare the old save path. Measure on Intel UHD-class Windows before scaling the 232-state batch.

Five specialists reviewed the art identity, segmentation/tooling, Hunter rigging, building/VFX/audio, and Godot integration and QA. Their preflight confirmed that direct cutouts or mirroring the supplied PNGs cannot satisfy the independent-view requirement. The local Blender route is viable for manual authoring. It still needs reference-matched pilot sculpts and rigs before the aesthetic and animation gates can be evaluated.
