# Grim Reaper animation verification

[Godot gameplay film with live audio](reaper-complete-with-audio.mp4) ·
[Standard graphics receipt](standard-receipt.json) ·
[Movie Maker log](standard-movie.log)

Godot 4.6.3 Movie Maker recorded 67.5 seconds at 1280×720 and 24 fps,
with a 48 kHz stereo Master mix. The prepared Hell Stage 5 fixtures use
legal procedural door approaches. The real model advances movement,
hits, warnings, transformations, cooldowns and audio while the normal
game viewport draws the scene. The fixture seeds rooms and prepares
starting resources, state and cooldowns so each mechanic can be inspected.

| Camera-facing view | Blade edge to door socket | Impact voices started on the damage frame |
| --- | ---: | ---: |
| Front | 0.000 world units | 1 |
| Back | 0.050 world units | 1 |
| Left | 0.000 world units | 1 |
| Right | 0.050 world units | 1 |

Both forms appear in each directional run. Each one starts with 26 frames
of navigation and transitions through a real incoming hit, the existing
boss timer and 24 frames of body overlap. The transformed run shows the
scythe held at impact, an articulated follow-through and a recovery pose.
The rear mantle hides the weapon at rest and the attack draws it in a
visible hand. The finishing blow uses the ordinary damage service with
the earlier phase guards prepared as spent. The world draw stays visible
until the character finishes fading so the result panel cannot obscure it.
Separate navigation runs took each form through a real left-to-front turn
on a legal AStar route.

All ten currently executable Wrath abilities show their warning and
release. Scythe Slash uses a real weapon windup and keeps its blade on
the door at damage time. Crimson Execution enters through the existing
health threshold. Its weapon release and throw occur together and the
scythe embeds 20 frames later. The held weapon remains occluded while
the separate thrown one exists. The old Eternal Sacrifices entry is
explicitly disabled in the model and was left unavailable.

On Low, a separate native run verified Soul Siege's blade contact
(0.0 world units of error), Shadow Surge's suppression, Shadow Dash's
legal movement and Soul Drain's door damage. It also verified the
first form's disappearance after real lethal damage inside the
opening grace period.
[Low receipt](low-supplement-receipt.json) ·
[Low render log](low-supplement.log) ·
[Soul Siege](low-soul-siege-contact.jpg) ·
[Shadow Surge](low-shadow-surge-release.jpg) ·
[First-form fade](low-first-form-fade.jpg)

## Reproduce

Use a graphical session. The normal proof runs on Linux Mesa llvmpipe.
Native Windows and Intel UHD performance require separate verification.

```sh
NIGHTFALL_LIVING_NIGHTMARE=1 NIGHTFALL_VISUAL_REBIRTH=1 \
NIGHTFALL_PROCEDURAL_MAPS_V2=1 XDG_DATA_HOME=/tmp/nightfall-reaper \
godot --path . --resolution 1280x720 --audio-driver Dummy \
  --write-movie /tmp/reaper.avi --fixed-fps 24 \
  --script tools/visual_rebirth/capture_reaper_completion.gd -- /tmp/reaper medium --movie
```

Use `low --supplemental-only` without Movie Maker for the separate
Soul Siege, Shadow Surge, Shadow Dash, Soul Drain and first-form death
checks. Standard and Low runs passed 327 and 267 checks, respectively.
The four headless boss architecture, combat and audio suites passed
7,124 checks. [Architecture](boss_architecture.log) ·
[Boss rules](boss_qa.log) · [Phase transitions](phase5d4_qa_boss.log) ·
[Audio routing](boss_audio.log)
