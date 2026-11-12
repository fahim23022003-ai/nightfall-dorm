# Nightfall Dorm 3.0 — Phase 2 horror and immersion

Continued existing clean `work` at `f66c0265440b9ce46f27e13ec039070bd696ffea`.
Local recovery tag: `pre-horror-phase2-f66c026`; the commit also remains in Git
history. Phase 1 anchored placement and paid-investment refunds were verified.
No rebuild, later-phase features, Android SDK installation or APK build.

## Implemented

- Model-owned bounded events record real target approach, encounter arrival,
  exact applied door damage before rescue, destruction, elimination and
  successful transactions. Room signal relays use weak references, so no model
  ownership cycle survives shutdown. Presentation never consumes gameplay RNG.
- Door numbers rise/fade and retain actual fractional HP loss, including
  overkill-clamped damage and immediate rescue/repair. Hits while a number is active aggregate into one rising/fading total per door;
  at most12 numbers are active, with per-door shake/red flash, existing low-HP
  cracks/HP bars and bounded destruction shards/rings.
- Named survivors and numbered rooms supply real alerts. Three nonblocking
  left-side cards slide/fade below the guide, away from building controls.
  Cooldowns, duplicate suppression, priority replacement and expiry apply.
  Escalating danger replaces stale lower-priority alerts for that same room.
  Doors/rooms also show compact world/map danger indicators.
- Three original scream variations trigger on encounter transitions, with
  per-room10s and global2s minimum spacing and no overlapping scream voice.
  Breaks have a separate reaction. Manual distance attenuation and pooled
  AudioStreamPlayer2D playback make teammate events quieter at distance.
- Nine new original WAVs add screams, destruction reaction, sale/refund,
  distinct insufficient-gold/electricity cues and eerie ambience. Disabled
  economic buttons can audibly explain an unaffordable click without spending.
  All37 prior WAVs are unchanged; all46 assets decode and import.
- Existing Needle/Arc firing, impact, hunter hurt/defeat, construction/upgrades,
  repair, generator, button/start/outcome sounds remain. Precise events prevent
  repair/damage being lost between rendered frames. Last-tick destruction cues
  are consumed even when the host enters the result screen.
- Existing menu/calm/danger stems crossfade without repeated playback starts.
  Distance, player attack and low door health drive tension; occasional eerie
  cues supplement calm ambience. Music/Effects/Ambient and mute preferences
  remain persistent with the existing compatible profile schema.
- Voice/frame limits, headroom and cooldowns remain in force.

## Verification

`bash tools/check.sh` completed with exit0 and no script/parse/error signatures.
New tests: independent events/audio319, UI resource failures5, feedback17 in
that regular run. The final presenter escalation change then passed21 feedback
checks, including replacement of stale alerts and nonoverlapping per-door damage totals. Existing tests passed:
model126, audio157 (46streams/3music starts), ranks/save348, Phase2UI52/hunter39,
projectiles22/edges12, camera/UI221, scene24, contextualUI53, furniture30,
availability3209, audit72; 20,000 transactions/175,941 property checks; six rate
scenarios; 12 representative matches (9victories/3defeats/0unresolved);
separate-process saves and actual-main startup. Phase1 suites314 and421 passed.
Counts are different measures and are not a combined scenario total.

Confirmed and fixed during work: reference cycle in room event relays,
terminal-frame audio events omitted by active-only observation, stale
lower-priority room notifications and overlapping rapid-hit damage labels. First new WAV imports were corrected to
uncompressed PCM for consistent validated playback. No unresolved failure in
tested Phase2 paths. Extended balance matrix was not rerun; no balance prices,
AI decisions, economy rules, ranking rules or save schema were changed.

Actual Linux Godot/Mesa screenshots and engine audio recording are in
`docs/evidence/horror/`, with reproducible `tools/capture_horror.gd`.
They are explicit prepared fixtures, not claims of natural human gameplay.
Rendered damage and destruction match real hunter damage; alerts leave controls
clear at1280×720 and960×540. Engine mix is non-silent and has zero clipped samples;
the evidence README/JSON records precise measured values.

Native Windows execution/export, subjective audible quality, human balancing
and target hardware performance remain UNVERIFIED. Windows project/export preset
files are byte-unchanged. Linux import, main startup, real mouse/key/touch event
tests and compatible save roundtrips pass. No Windows executable was exported.

## Backup

Commit/push only verified changes to existing `work`, without force. Compare
remote full SHA with local HEAD after push; final chat reports the exact verified
commit. Nothing is deployed or publicly published. Stop after this Phase2.
