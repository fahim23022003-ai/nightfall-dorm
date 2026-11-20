# Living Nightmare audio preview

The existing audio director launched the whole music library at zero
gain and let Classic retain simultaneous calm and danger beds. Shuffle
could choose the same track during approach and siege, and a saved menu
track could become a Manual gameplay track. Both kinds of results returned
to menu music. There were no dedicated Hall, Hell, or sustained-siege
routes and no direct-siege heartbeat.

The opt-in `NIGHTFALL_LIVING_NIGHTMARE=1` preview selects one present
score with at most one outgoing score. Its menus use only the three menu
tracks. Preparation, approaching danger, a live player siege, desperate
defense, Hall recovery, regular Endless combat, Hell ambience, the Reaper
and Crimson each have a defined route. Victory and defeat have separate
one-shot cues. The preview preserves the existing Classic, Manual,
Shuffle and Off preference values. Manual stays active for eligible
ordinary gameplay tracks. Dedicated combat and result music overrides it.
The adaptive shuffle history has its own sidecar.

The heartbeat uses the main Hunter's active attack state at the human
player's occupied, closed, intact door. It does not trigger on an approach,
NPC attack, or repeated damage. The sampled cue is 4.96 seconds long,
ducks music without changing the Effects bus, and needs both 45 seconds
of active match cooldown and an eight-second break in direct pressure to
trigger again. The opt-in also layers Hunter-specific release sounds on
actual landed door damage events.

## Live mixed audio

Godot 4.6.3 recorded its Master bus under the Dummy audio driver before
and after the change. The harness drives staged combat states in the
existing match model. These recordings are consecutive real mixed audio
with the project's normal bus gains. The Ogg files are encoded from
Godot's PCM and contain no added effects or playback normalization.

- [Baseline Master audio](baseline-master.ogg) · [Routing timeline](baseline-timeline.json)
- [Adaptive Master audio](after-master.ogg) · [Routing timeline](after-timeline.json)

| Approx. scene start | Baseline settled track | Adaptive settled track |
| --- | --- | --- |
| 0:00 menu | Portraits at Midnight | Portraits at Midnight |
| 0:04 preparation | Dust Waltz | Dust Waltz |
| 0:08 approach | Broken Vespers | Footsteps Below |
| 0:12.5 attack on the player's door | Door Siege | Door Siege and one heartbeat |
| 0:18.5 desperate defense | Door Siege | Broken Vespers |
| 0:23.5 Haunted Hall | Door Siege | Below the Chapel |
| 0:28.5 Reaper | Reaper | Reaper |
| 0:33.5 Crimson | Crimson | Crimson |
| 0:38.5 victory | The Night Watch | A Moment at Dawn |
| 0:43.5 defeat | The Night Watch | No Morning Bell |

The timings in the table come from the staged route timeline. The Dummy
driver's recorded audio can vary slightly in duration under load. Without
other critical cues, the heartbeat lowered live music gain to 0.55 and
returned it to 1.0 after the cue. Capture peaks were -16.4 dBFS and
-16.7 dBFS, with no clipping. The opt-in runtime settles to one audible
score, with the existing four ambience players on a separate bus.

The original sampled arrangements are reused. The four new compositions
and the heartbeat were rendered from the in-repository CC0 VSCO piano,
violin, glockenspiel, timpani and drum recordings. [Note and timing data](../../../../assets/audio/living-score-arrangements.json)

## Synchronized Godot playback

Godot Movie Maker recorded the actual menu and match view with the live
Master bus in a 40.5-second, 1280×720, 24 fps capture with 48 kHz stereo.
The fixture stages the Hall and boss transitions and extends the first
siege's cooldown after an authentic strike so the complete heartbeat
can play before the low-door-health demonstration. The captured sequence
settles to nine distinct scores. Its event receipt records one heartbeat.
[Watch with sound](synchronized-playback.mp4) ·
[Scene and score receipt](synchronized-playback.json) ·
[Godot capture log](synchronized-engine.log)

## Reproduce

Use an isolated profile and the supplied capture tool.

```sh
NIGHTFALL_LIVING_NIGHTMARE=0 XDG_DATA_HOME=/tmp/nightfall-audio-base godot --headless --audio-driver Dummy --max-fps 60 --script tools/capture_living_nightmare_audio.gd -- /tmp/nightfall-audio-base-evidence
NIGHTFALL_LIVING_NIGHTMARE=1 XDG_DATA_HOME=/tmp/nightfall-audio-preview godot --headless --audio-driver Dummy --max-fps 60 --script tools/capture_living_nightmare_audio.gd -- /tmp/nightfall-audio-preview-evidence
```

For the video, use a 1280×720 graphical session and the same preview flags.

```sh
NIGHTFALL_LIVING_NIGHTMARE=1 NIGHTFALL_PROCEDURAL_MAPS_V2=1 NIGHTFALL_VISUAL_REBIRTH=1 NIGHTFALL_FULL_ROOM_GRID=1 XDG_DATA_HOME=/tmp/nightfall-movie-profile godot --resolution 1280x720 --audio-driver Dummy --fixed-fps 24 --write-movie /tmp/nightfall-audio.avi --script tools/record_living_nightmare_audio.gd -- /tmp/nightfall-audio.json
```

The focused runtime suite passed 67 assertions. The legacy audio, session
and boss suites passed 617, 18 and 48 assertions. Native Windows playback
and human listening approval are pending.
[Preview tests](living_nightmare_audio.log) · [Legacy audio](audio_system.log) · [Session](session_audio.log) · [Boss](boss_audio.log)
