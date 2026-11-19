# Phase 14 horror visual rebirth progress

The existing Godot 4.6.3 game remains a 2D game. The preview uses reference-led character sprites deformed on local meshes and Blender-baked structure atlases with separately aimed launchers. The original Hunter cutouts lack cohesive anatomy and the original machines use four interchangeable visual tiers and simple aiming marks. The replacement pipeline addresses these with common sprite pivots, physically different geometry and visuals driven by existing game state. The fallback remains the normal launch path. To see the preview on Linux, run `NIGHTFALL_VISUAL_REBIRTH=1 godot --path .`.

## Verified coverage

| Runtime inventory | Integrated preview states | Planned baseline |
| --- | ---: | ---: |
| Ordinary Hunters | 2 | 60 |
| Grim Reaper | 0 | 2 |
| Buildings and core structures | 20 | 170 |
| Building specialization variants | 24 | Additional to baseline |

These counts cover Phase 14 preview output. Existing fallback art remains available in every mode. The Stalker and Phantom Witch are the two Level 1 Hunter states. The Needle and Arc cover L1–L10 each, plus two branches apiece at L5–L10. Bearings, poses and direction sprites are not counted as extra evolution states. [Asset manifest](evidence/visual-rebirth/ASSET_MANIFEST.json)

- **Phantom Witch.** Five generated and normalized 2D projections now display in Godot. Each shares the foot pivot and 104-pixel body scale. The renderer animates the veil, dress and attack gesture and takes its cues from the existing model. Hair and posture can shift at angle boundaries. The art is a set of directional sprites and a deformation mesh. Separate head, eyelids, anatomy and garment textures and skeletal skinning remain open. [In-game direction comparison](evidence/visual-rebirth/witch-directional/witch-gameplay-direction-comparison.png)
- **Stalker.** The approved L1 single-view animation remains playable in the preview. An editable Blender anatomy, hair and cloth study produced four independent directions from one real mesh. The modeled form loses facial fidelity and the back cloth reads lighter than the supplied art at gameplay scale. That study is excluded from the runtime assets. Its view sockets and 2D deformation plate support continued art review. [Study and source](../tools/visual_rebirth/stalker_sculpt/README.md)
- **Arc Turret.** Twenty-two baked states support 12 bearings each with separate base and launcher atlases. Copper electrodes, coil stacks and the lower plinth mark the role at room scale. The rendered bolt leaves between the electrodes and follows the existing projectile. The charge, recoil and impact read the existing shot state. Across all bearings the mean aligned alpha-mask difference was 25.3% from L1 to L4, 27.1% from L4 to L7 and 31.7% from L7 to L10. All 108 adjacent baseline mask pairs differed. Focus and Storm average 5.7% silhouette difference at L5, so some branch changes remain subtle. No transparent tile edges are clipped in the 264 assembled poses. The decoded Arc atlas cost is about 10 MiB in the preview.
- **Audio.** Five new original positional cues add characteristic breath, chains, chatter, vocal flutter, radio interference and low wind. Together with the existing Stalker cue, all six ordinary Hunters have an opt-in approach sound. Existing attack cues, Effects settings, cooldowns and distance attenuation continue to apply.

The 232-state batch remains incomplete. The Stalker turnaround, independently articulated body parts and all later Hunter levels need further art work. The other four ordinary Hunters, both boss forms and the other fifteen building systems still use their existing visuals.

## Verification

Godot rendered a staged 16-slot view at 1280×720 with the five Witch directions exercised through the production draw path. It passed 175 fixture checks versus 168 fallback checks. The sampled Witch poses retained positive triangle areas across 65,280 triangles. Six ordinary archetype approach cues passed 24 opt-in, attenuation and cooldown checks. The existing core, scene, audio, visual audio, cinematic, Nightmare Hunt and spatial-save suites passed 1,105 assertions. No game model, prices, difficulty, damage, save schema or balance files changed.
