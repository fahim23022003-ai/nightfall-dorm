# Living Nightmare door contacts

The 1280×720 Godot reel follows seven real Hunter hits at normal speed.
Each prepared encounter starts at the legal door approach. The ordinary
Hunters use Standard difficulty in Stage 1 at Evolution 1. The transformed
Reaper uses Hard difficulty in Stage 5. Its normal boss selector chooses
the Scythe Strike after the fixture places its other moves on cooldown.
The production simulation determines telegraph duration, actual damage
and the follow-through. The reel is silent. The separate audio evidence
uses actual Godot audio output.
[Contact reel](hunter-impacts-720p.mp4) · [Audio evidence](../audio/)

| Hunter | Contact cue | Confirmed damage in fixture | Screenshot |
| --- | --- | ---: | --- |
| Crusher | Wood fragments, dust and a directional door jolt | 20.14 | [Heavy hit](crusher-contact.png) |
| Stalker | Three spectral claw tracks, local mist and a scored door | 13.76 | [Standard](stalker-contact.png) · [Low](stalker-contact-low.png) |
| Ravager | Shorter red claw tracks and wood chips | 14.26 | [Swipe](ravager-contact.png) |
| Phantom Witch | Pale spectral burst without wood debris | 13.76 | [Cast](witch-contact.png) |
| Electric Ghost | Cyan discharge toward the struck door | 14.77 | [Discharge](electric-contact.png) |
| Storm Wraith | Local wind arcs and pale haze | 14.77 | [Storm impact](storm-contact.png) |
| Grim Reaper | Crimson scythe arc and impact fragments | 30.82 | [Scythe contact](reaper-contact.png) |

Both Standard and Low graphics recorded identical attack times and
damage. In those seven prepared angles, the new Stalker and Ravager
fingertips and the transformed Reaper's blade reported a distance of
zero world units to the shared door socket on their actual HP-loss
frame. Crusher, Witch, Electric Ghost and Storm Wraith use the new
impact effects with their existing illustrated bodies. This reel
measures door contact, so locomotion and the Reaper transformation
need their separate captures.
[Standard receipt](medium-contacts.json) · [Low receipt](low-contacts.json)

The first Low graphics capture passed every check and logged an intermittent
ObjectDB warning after the fixture exited. The diagnostic rerun kept the
identical event receipt and screenshot checksum and exited cleanly.
[Initial exit log](low-first-pass.log) · [Diagnostic rerun](low.log)

The positive model damage event is the source of truth. A fully absorbed
or illegal strike creates no new door contact effect. An embedded
scythe pulse or arcing spell can still mark its confirmed hit without
playing a melee release. Existing ward feedback and tactical warnings
keep working. Wood fragments are confined to physical hits on the
lower wooden tiers. Reinforced tiers use sparks. Low keeps the readable
part of each hit, with fewer draw calls and no airborne fragments.
The queue holds at most 12 recent hits and only processes new event IDs.
[62 focused model assertions](contact-tests.log)

## Reproduce

Run in a graphical session with Godot 4.6.3. Choose a fresh destination
and use `low` to render the second preset.

```sh
XDG_DATA_HOME=/tmp/nightfall-contact-qa godot --path . --resolution 1280x720 \
  --audio-driver Dummy --script tools/capture_living_contacts.gd -- /tmp/nightfall-contacts medium
godot --headless --path . --script tests/living_hunter_contact.gd
```
