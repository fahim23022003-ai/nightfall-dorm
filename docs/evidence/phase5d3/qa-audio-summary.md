# Phase5D3 independent audio acceptance

Accepted **271 checks, zero failures**, exit0, no engine errors/warnings.
`tests/phase5d3_qa_audio.gd` runs actual Game, Onboarding, AudioDirector and UI
with temporary saved profiles; exact source hashes are in qa-audio-acceptance.json.

- A truly absent profile starts the musical cinematic with default non-muted
  settings. Skip routes to the existing mandatory tutorial with preparation music.
- Returning profile preserves saved Music.37/Effects.41/Ambient.22 and Mute.
  Muting buses never prevents score/player initialization or resets preferences.
- All108 declared streams decode; seven music players plus four ambience players
  and16 effects voices reuse27 nodes. Cinematic duration19s and nonlooping; six
  other actual tracks are at least48s and loop through AudioStreamWAV.
- Production Onboarding clocks advance through running/breath0–4,threat/thunder
  4–8,door/impact8–12,shriek13 and title15–19. Musical intent persists into title.
  Completion, skip and replay seek/cleanup behave correctly. These accelerated
  clock checks verify routing/timing, not real-time waveforms or human audition.
- Actual Settings→Audio listening room and ordinary injected mouse input selects
  each of seven scores and five major vocal auditions. Stop/Back restore normal
  music intent; real event-budget saturation queues a voice and Stop cancels
  that queued request before it can play unexpectedly. Buttons/labels remain
  inside the design viewport with visible focus and nonoverlapping hit areas.
- Real prepared model states select preparation, approach, siege, Reaper and
  alternating Endless musical targets with crossfades; existing player identities
  and music_start_count remain stable. Prepared threat states are not natural
  combat/balance evidence.
- Auditions/cinematic do not change permanent profile fields or saved bytes.

The first10 failures were solely fixture text lookup using lowercase second
words; Godot String.capitalize produces title case. The original log remains
qa-audio-initial.log; correction does not change product behavior. Intermediate
248/250-check passes remain recorded; final271 acceptance includes stronger
queued-cancel, fresh-profile and actual-model-state cases.

No production audio defect remains in these tested paths. Actual engine mixer
capture, sampled instrument/source licenses and genuine recorded vocal texture
are reviewed separately by root/D. Native Windows, physical speakers/listening
and subjective musicality/scariness remain UNVERIFIED by this headless test.
