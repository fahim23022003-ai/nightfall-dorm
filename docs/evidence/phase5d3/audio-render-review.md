# Phase 5D-3 — independent audio milestone A review

**TESTED:** 156 accepted checks, zero failures, actual Linux Godot rendering and
internal Master-bus PCM. This is the audio milestone, not acceptance of the
ongoing AI, all-building progression or teammate spectator workstreams.

`audio-render-final.log` passes140 checks; `audio-transition-final.log` passes16.
Both processes exit0 and contain no engine/script errors or leak warnings. The
software driver reports its expected unsupported-VSync warning. The final runs
explicitly use the Dummy hardware output driver; no physical speaker is claimed.

## Actual execution and visual output

A genuinely fresh isolated profile starts the actual main scene. The ordinary
Onboarding clock runs the15s pursuit and4s creator/welcome card; no cinematic
pose/time is injected. Actual game process/audio state updates at real wall time.
The20s recording retains nonzero musical signal from the first second through the
welcome card and routes into the unchanged tutorial. All scheduled breathing,
footsteps/thunder/impact/climax voice events use production code.

The existing-profile skip/replay fixture changes only its isolated profile's
tutorial graduation, uses actual Skip input, verifies intro seek to the beginning,
menu crossfade and no queued intro residue. Actual Settings → Audio listening room
controls are clicked at1280×720 and1920×1080. All seven score selections and five
major voice controls play actual decoded streams. Stop/Back work, saved profile
values/bytes remain unchanged and seven music players are retained throughout.

Twelve unedited PNGs are indexed in `audio-render-manifest.json`: actual opening,
climax, title, Settings entry, listening room at both resolutions and five routing
fixtures. D opened the full-size720 listening room/title/opening images; buttons,
labels and Gothic surfaces are legible with no confirmed clipping. No subjective
art-quality score is inferred.

Prepared real model states additionally exercise preparation, approach, siege,
Reaper and even-wave Endless music routing. These are controlled routing fixtures,
not earned economy/progression or balanced human survival. The actual appropriate
score reaches its expected weight, minor transitions retain advancing music
playback and an actual critical warning cue ducks music. No model RNG or combat
outcome is used to claim audio quality.

## Musical and signal evidence

The original score tool records real VSCO CC0 piano/violin/tremolo/glockenspiel/
orchestral percussion samples into seven authored arrangements. Note-event,
harmonic/motif/phrase and tempo metadata are in `assets/audio/score-arrangements.json`.
These are actual musical sample arrangements, not an oscillator/drone rebrand.
Source licenses and genuine human vocal provenance are separately documented by
B/root; D does not claim direct Freesound-origin access or human audition.

Actual solo previews capture4s of each track. The native64s Menu WAV loop is
verified across an explicit seek to its final1.5s; this is an actual boundary
playback test, not a claim that D listened to64s or all complete compositions.
All generated WAV metrics/hashes are in `audio-waveform-metrics.json`.

The refreshed natural cinematic recording includes these Master RMS levels:

| Actual interval | RMS |
| --- | ---: |
| First second |0.004656|
|0–4s |0.008002|
|4–8s |0.007163|
|8–12s |0.010143|
|12–15s climax |0.019940|
|15–19s title |0.004418|

Its peak is approximately0.13934 full scale. The initial quieter first phrase
was measured separately (first second0.001521,0–4s0.002439). B then increased
that sampled phrase and stopped continuous running/breathing from globally
ducking its score; the refreshed real recording verifies approximately10dB
stronger early signal with the same controlled climax peak. Critical attack/
climax warnings retain ducking. These are objective signal observations, not
proof of subjective loudness/scariness on the owner's PC.

A controlled comparison plays the exact old Menu WAV from baseline3e6224e through
an actual engine player with reconstructed original steady-menu routing
(target1 ×0.85 gain,−12dB loop offset, same0.5 Music bus and−5dB headroom), then
compares current production audition at the same0.5 Music setting:

- Old reconstructed route RMS:0.00399895.
- Current sampled Menu RMS:0.01485796.
- Ratio: approximately**11.464dB higher RMS**.

The comparison is neither a full old-application benchmark nor a perceptual
loudness/Windows-speaker test. Music0/all-zero and Mute both produce exact-zero
Master PCM in their settled controlled windows. All25 retained PCM captures have
zero full-scale samples; zero clipping alone is not the audio-completion argument.
The earlier source recording and metadata are preserved rather than relabelled.

## Confirmed failures and repairs

The first exploratory graphical invocation attempted unavailable ALSA hardware,
then fell back to Dummy and logged an infrastructure ERROR. Its129 assertion
checks passed, but this run is not accepted as clean. The final invocation
explicitly selects Dummy and retains actual internal mixer output.

A requested genuine breach→scream→queued laugh→immediate Continue test found a
real compatibility defect: the new recorded first scream lasts3.47s, exceeding
the old pending-laugh3s expiry. The scream survived Continue, but the laugh never
played before its queue silently expired. `audio-transition-fourth.log` preserves
that single actual failing assertion. B increased the bounded room-deduplicated
pending-laugh budget. The accepted retest verifies an actual scream event,
continued playing voice across real Continue, actual Hunter laugh event count1,
completion of that laugh and drained queues. It checks playback, not merely an
empty queue. No fabricated presentation event is injected: controlled actual
door damage/breach/bed contact creates the NPC elimination.

That fixture first exposed an independent in-progress migration defect: ruleset
JSON1.0 was rejected by integer-array membership `[1,2]`. B changed it to numeric
whole/range validation. A genuine frozen pre-phase checkpoint now loads writable
and resumes through Game. Initial migration/probe logs remain. Separate earlier
fixture failures came from disabling Onboarding.active while leaving its
cinematic input phase registered; the harness now uses actual Skip before loading
the checkpoint. Those cascades are not counted as production audio defects.

## Limits and handoff

Native Windows output/import, physical listening, subjective musicality/fear,
vocal convincingness and hardware speaker/headphone balance remain **UNVERIFIED**.
Original Freesound pages remain inaccessible; root's source/license report states
the exact pinned mirror/independent-credit evidence. The owner should audition
all seven cues/voices through the real listening room. Linux internal PCM and
realistic source texture cannot certify emotional effect.

D did not edit production, commit or push. B remains sole production owner. Root explicitly requested one bounded teammate/building follow-up after this
audio milestone; its final evidence is in render-final-review.md. The owned
private display is stopped after that requested follow-up, without touching other
headless audit processes.
