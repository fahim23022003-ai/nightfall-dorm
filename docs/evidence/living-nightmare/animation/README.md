# Articulated directional Hunter pilots

The V2.3 preview used a single textured grid per body. With Stalker and
Ravager, several regions offset the illustrated fingertips and shoulder
by a few world pixels. The Reaper's scythe pivot followed the painted
grip on a similar cloak grid. At normal room zoom, the model could deal
door damage while the visible arm remained close to its neutral pose.
The baseline runs below capture that behavior with the actual Godot
viewport and combat rules.

The opt-in Living Nightmare runtime uses hand-traced, independently
authored cardinal-source layers for **Stalker Evolution 1, Ravager
Evolution 1, and both Reaper forms**. The atlas bake masks and separates
upper arms, forearms, hands, hoods or heads, and the lower garment. It
also separates a front limb and hind foot for the Ravager crawl. Rebuilt
garment texels fill the overlap left by the painted arm. The in-game
controller rotates each limb section around its modeled joint, solves
the leading hand against the wound-up and contact poses, and lets the
head and cloak lag behind the torso. The transformed Reaper's weapon
follows its grip and swings through the impact. A positive model damage
event supplies the door contact point and the post-impact timing. A
windup that is canceled produces no contact.

Models, balance, procedural layouts, saves and graphics presets retain
their existing rules. The four authored headings are discrete 2D views.
The transformed rear mantle intentionally occludes the hand and uses
hood and cloth articulation without a visible Scythe Strike path.
Individual digits are part of each hand layer.

## Normal-speed Godot evidence

These are silent native **1280×720, 24 fps** viewport recordings. Both
ordinary fixtures stage a known walkable route and a paid Needle.
The Reaper fixture advances the established transformation and offense
through HunterState, and the Scythe Strike recording stages the other
boss cooldowns high. See the synchronized audio team's separate
recordings for sound evidence.

| Pilot | Previous renderer | Living Nightmare preview | Fixture receipt |
|---|---|---|---|
| Stalker Evolution 1 | [Baseline](stalker-baseline.mp4) | [Walk, windup and claw contact](stalker-pilot.mp4) | [After](stalker-pilot.json) |
| Ravager Evolution 1 | [Baseline](ravager-baseline.mp4) | [Crawl, lunge and claw contact](ravager-pilot.mp4) | [After](ravager-pilot.json) |
| Reaper, both forms | [Soul Siege baseline](reaper-baseline.mp4) | [Transformation and Scythe Strike](reaper-pilot.mp4) | [After](reaper-pilot.json) |

A Stalker screenshot pair captures the same landed door-damage tick.
[Before](stalker-contact-before.png) · [After](stalker-contact-after.png)

The matched ordinary runs retained damage, shot timing and impact frames.
At the first damage event, the Stalker measured 0.05 world units from
the door socket at frame 138, and the Ravager measured 0.00 at frame
122. The isolated Scythe Strike measured 0.00 at frame 134 after the
live transformation and warning. The three rendered suites passed
29, 29, and 12 checks respectively. Broader geometry, simultaneous effects and owner art review remain
separate from these prepared fixtures. Crusher, Witch, Electric, Storm,
and Evolutions 2–10 retain the prior body animation. This pilot does not
establish full animation acceptance for the catalog.

## Reproduce

Use Godot 4.6.3 and a graphical display, then run these commands with
an isolated XDG data directory:

```sh
NIGHTFALL_VISUAL_REBIRTH=1 NIGHTFALL_LIVING_NIGHTMARE=1 godot --path . --resolution 1280x720 --audio-driver Dummy --script tools/visual_rebirth/capture_hunter_anchor_combat.gd -- /tmp/living-stalker stalker 1
NIGHTFALL_VISUAL_REBIRTH=1 NIGHTFALL_LIVING_NIGHTMARE=1 godot --path . --resolution 1280x720 --audio-driver Dummy --script tools/visual_rebirth/capture_hunter_anchor_combat.gd -- /tmp/living-ravager ravager 1
NIGHTFALL_VISUAL_REBIRTH=1 NIGHTFALL_LIVING_NIGHTMARE=1 godot --path . --resolution 1280x720 --audio-driver Dummy --script tools/visual_rebirth/capture_reaper_form_motion.gd -- /tmp/living-reaper --scythe
```

Unset the Living Nightmare flag to reproduce the previous renderer.
Omit `--scythe` to reproduce the original Soul Siege fixture.
