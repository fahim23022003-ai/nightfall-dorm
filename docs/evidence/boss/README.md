# Phase 4B visual and audio evidence

Agent D ran actual Godot 4.6.3 OpenGL on Mesa llvmpipe with a private Xorg dummy
display. Final `tools/capture_boss.gd`: **63 checks, zero failures, 22 PNGs**.
`render-final.log` records successful saves, exact text measurements, real attack
warnings/impacts, music diagnostics and retry assertions. The capture script uses
an isolated profile. All PNGs are real rendered frames, not mockups.

The fixtures deliberately give resources, raise door level, set time and health,
and select attack availability. The Hunter's actual methods then perform the
transformation, warnings, damage, suppression and death. These frames are not
naturally played matches or balance evidence. The isolated campaign is unlocked
through prepared eligible settlements; the all-map test explicitly enables the
encounter on the introductory map, where normal campaign play does not transform.

## Inspected frames

- `render-01-preparation`: stage/difficulty/perks remain readable; the actual
  80-second/55%-HP or210-second trigger and no-heal rule are shown.
- `render-02-normal-hunter`, `render-03-transformation`, and
  `render-04-transformation-960x540`: normal Hunter becomes a distinct hooded,
  skull-faced Reaper with layered torn robes, glowing eyes and an articulated
  scythe. Smoke/ring effects and a large awakening banner are visible. The boss
  health bar retains the existing health values, and the HUD shows the countdown.
- `render-05-reaper-awakened`, `render-06-*-warning`, `render-07-*-impact`:
  attack windups visibly raise the weapon, draw progress/target rings and warn
  before damage. Actual Scythe/Siege impacts produce existing floating damage
  numbers and lower the door bar. Surge marks the room's turrets and shows its
  duration. Tests confirm no early hits and non-damaging Surge activation.
- `render-08-silence-960x540`: silence countdown, repair counterplay, Reaper
  vulnerability and affected turret markers remain visible at960×540. Final
  Surge notice width is322px within370px; largest HUD warning433px within476px.
- `render-09-hurt` and `render-10-death`: damage tint and fading/dissipating body
  with spreading shadow particles; zero-health bar. `render-11-victory` shows
  REAPER DEFEATED and the existing campaign/result controls. This fixture's
  zero occupied-time correctly produces no XP, rather than manufacturing rewards.
- `render-12-*`: distinct boss silhouette at the actual door approach on all five
  maps, including the laboratory side door. The temporary transformation banner
  is allowed to expire before these frames. Room controls remain available.
- `render-13-defeat-retry`, `render-14-retry-normal`: existing failure/result UI,
  followed by a real Retry Stage button click. Stage5/Hell remain selected; the
  new Hunter is normal, with no retained transformation or suppression.

The original art is a stylized front-facing vector character with four robe
frames, a separate animated scythe, eye glow, bounded procedural smoke, attack
rings/arcs and death fade. It is distinguishable from the original ghost. This
is not a cinematic or a full set of directional hand-painted animations.

## Audio evidence

`tests/boss_audio.gd` independently passes **42 checks, zero failures**, with a
clean final log (`render-audio-tests.log`). All nine boss assets decode as16-bit
PCM. Actual production observers play transformation, three warning types,
impacts, hurt and death. Boss music and nearby ambience fade in, other match
scores fade out, and death/retry clear them. Four permanent music players remain
started once across updates/retries. Pausing freezes the mix. Death event plus
snapshot detection produces one death cue. The test waits for the audio thread
to drain after shutdown; the earlier abrupt test exit leaked pending playback
objects, not model references or gameplay nodes.

`render-engine-mix.wav` is an actual AudioEffectRecord master-bus recording from
the final render run: stereo44.1kHz,31.672seconds, peak3129/32767, RMS273.50,
zero clipped samples. Measurements are retained in `render-audio-measurements.json`.
This proves non-silent functional engine mixing; it is not a claim of subjective
human audition. The renderer uses the Dummy output device while the engine mix
is recorded. Existing voice/cooldown limits intentionally drop some competing
noncritical cues in accelerated fixtures. Dedicated audio tests verify both
impact cues when spaced normally. No audio assets are missing.

## Fixed finding and limits

Initial audit found the Surge notice measured433px in a370px text area and was
visibly truncated. The main developer shortened its hint; final recaptures and
measurements pass. `render-initial.log` retains the two original failing width
checks; `render-final.log` is the final passing result.

UNVERIFIED: native Windows launch/audio/input/FPS, subjective horror/music
quality, natural human play, every screen size and every map-room composition.
The Linux software-rendered fixtures establish real rendering and functional
mixing, not target-hardware performance. An unsupported VSync warning is expected
on llvmpipe; the final run has no script/parse errors. Only the audit-owned Xorg
process was stopped; other displays and parallel tests were left running.
