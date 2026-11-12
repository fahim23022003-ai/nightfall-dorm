# Phase 5C-1 rendered cinematic/tutorial/shop evidence

Agent D ran actual Godot 4.6.3 OpenGL/Mesa llvmpipe on a private Xorg display.
Final `tools/capture_onboarding.gd`: **77 checks, zero failures, 26 PNGs**.
`render-final.log` has no script/engine errors (the software driver's expected
unsupported-VSync warning is not a gameplay failure). The coordinator owns
production and commits; D changed only this capture and its render evidence.

The fixture creates an isolated fresh profile. It lets the real opening process
run in wall-clock time, records actual viewport images, and uses physical-key
InputEvents and mouse input for the tutorial and shop. It does not set tutorial
steps, claim a room through the model API, move the player by assignment, buy or
upgrade practice buildings through model calls, or fabricate tutorial completion.
Navigation paths select valid goals; actual WASD movement performs the walk.
The shop alone is explicitly seeded with a 100 RM test budget, not naturally
claimed match earnings. These are automated fixtures, not human play or balance.

## Inspected frames

- `render-01`/`02` show genuinely changing player frames/positions and scrolling
  forest/fog. `render-03` shows the original game's Hunter artwork chasing the
  original four-frame player art. Moonlight, silhouettes and fog move while the
  actor flees; this is an animated scene, not a timed text slide.
- `render-04` shows the dorm approach; `05` shows the actor at the entrance;
  `06` is captured inside the 10.7–11.1-second impact window, with the Hunter
  physically at the shut door and the impact ring visible. `07` shows darkness.
- `render-08`/`09` show the exact **Welcome to NightFall Dorm** and **Created by
  Fahim** text plus all four short story lines at normal/960×540 sizes. Text is
  readable and unobscured. The unskipped 15-second cinematic +4-second title
  automatically enters the mandatory tutorial. The script also uses Space to
  skip a later explicitly restarted capture fixture safely; return-to-menu and
  tutorial replay do not restart the production opening.
- `render-10`–`12a`: actual WASD/arrow-equivalent movement into a valid room,
  real E claim, highlighted bed and real E sleep. The camera now focuses play,
  and the HUD says safe practice instead of a misleading 10,000-second timer.
  The objective panel, progress and markers remain readable at 960×540.
- `render-13`: occupied bed Gold genuinely increases. `14`/`15`: actual floor-pad,
  Dynamo card and Confirm clicks create a Dynamo that generates separate
  Electricity; then actual Needle purchase near the door creates a defense.
- `render-16`: actual turret upgrade plus R repair satisfy the lesson. The
  marker points to the turret, then door, rather than an unrelated empty pad.
- `render-17`/`18`: the weak Hunter really attacks the intact door and the turret
  fires/impacts/kills it; the terminal lesson shows TUTORIAL COMPLETE. The old
  inspector closes, leaving the save-completion action clear. Assertions verify
  XP, RM, item stock, spins and active campaign match data are unchanged.
  Clicking completion persists the flag, reload retains it, and Replay Tutorial
  enters practice then exits without an opening replay or progression reset.
- `render-19`: normal returning menu, RM balance, shop and replay controls.
- `render-20`–`23a`: all four registered Commons show actual effect, rarity,
  icon, price, quantity and RM balance; full/small layouts are readable. Real
  double-click input buys one repair kit for 18 RM, resulting in 82 RM and one
  kit, one serial increment, with reload durability. Insufficient funds disable
  purchase. A deliberately invalid save path shows failure feedback and rolls
  back RM, stock and serial without a false confirmation.
- `render-24`: reduced-effects opening removes the full-screen lightning flash
  and keeps the chase recognizable. Actual keyboard skip leaves the normal menu.

All 26 final images were surveyed in contact sheets and key cinematic, title,
practice, completion and shop frames were inspected at full size. This establishes
rendered behavior in these layouts, not subjective scariness or universal device
readability.

## Actual audio

`render-onboarding-mix.wav` is an AudioEffectRecord master-bus recording from the
actual engine mixer, with Dummy output driver: stereo 44.1 kHz, **34.737052 s**,
peak **608/32767**, RMS **87.01369**, **zero clipped samples**. Measurements and
real voice-start event counts are in `render-audio-measurements.json`.

All nine new cues played: running (4), breathing (3), lightning, impact, shriek,
whisper, eight tutorial-step cues, tutorial completion and shop purchase. All
96 streams load, no assets are missing, four music stems start once, and no
critical sounds remain queued. The original menu soundtrack is a real loop;
existing crossfade/bounded voices and quieter, ducked gameplay music remain.
No human listening, speaker output or subjective mix-quality claim is made.

## Findings, fixes and provenance

The initial capture's three assertion failures were a fixture mistake: it chose
a movement goal 70 pixels left of spawn, outside the walkable corridor. It now
chooses the actual reachable door approach. The same initial run still completed
the later real tutorial and shop. `render-initial.log` preserves this failure.

Actual visual review found a tiny overview camera with partially hidden room
objects, a misleading practice prep timer/normal Hunter HUD, an empty-pad marker
during the turret-upgrade lesson and an old inspector visible at completion.
The developer fixed focus/HUD/markers/cleanup and reused the game's detailed
animated player artwork. The coordinator also identified the early Hunter/door
misalignment; final images verify coherent arrival/impact. `render-second.log`
records the 76-check passing run before the final absolute-time impact capture;
`render-final.log` is the final 77-check run. No gameplay assertion was disabled.

Only D-owned Xorg PID 69304 was stopped. **UNVERIFIED:** native Windows import,
controls, hardware FPS and speaker output; subjective cinematic/audio quality,
fear, comfort and typical human tutorial completion time. The automated expert
walkthrough cannot establish the requested typical 2–3-minute human pacing.
