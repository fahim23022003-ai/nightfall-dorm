# Known limitations — current Phase 5D-3

Current scope is five campaign stages/maps, Normal/Long Night/Hell, three Hunter
archetypes, Grim Reaper, twenty consumables and six Phase 5D-2 replay systems.
Earlier statements describing one map, one archetype or eight items are historical.
See the [Phase 5D-3 report](PHASE_5D3_MUSIC_HUNTER_BUILDINGS_SPECTATE_REPORT.md) for current evidence/status.

- Native Windows execution, GPU/drivers, high-DPI, physical keyboard/mouse/audio,
  accessibility comfort and human long-session enjoyment/balance are UNVERIFIED.
  Linux Godot tests/screens/mixer output cannot certify those matters.
- A 2D layered art style retains limited directional actor animation, simple
  ambient silhouettes and repeated building pads. Shadows/glow are procedural,
  not a dynamic light-occlusion simulation. Cosmetics are visual overlays.
- Turret targeting retains distance/range rules rather than wall raycasting.
  Navigation uses the existing six-room corridor graph per map, one attacking
  Hunter, and autonomous local teammates. This is offline single-player.
- No multiplayer, verified online leaderboard, server anti-cheat or cloud save.
  Manually shared Challenge results are self-reported. Identical supported code
  conditions reproduce with matching ruleset/engine/inputs in tested simulations;
  timing differences and cross-platform bitwise determinism are not certified.
- Endless saves one between-wave checkpoint, not arbitrary mid-wave state.
  Already-consumed permanent items and per-run rescue/Legendary limits cannot
  rewind. Destroyed doors and eliminated teammates carry between waves. Recent
  defeat telemetry covers start/resume; older recent events are not fabricated.
- Endless milestone cash/XP is once per profile and bounded. Prepared progressed
  profiles, scripted fast repair policies and finite automated wave runs are not
  evidence of natural human inventory acquisition, human skill or infinite-run
  stability. Balance needs Fahim/Adie's feedback.
- Fonts, original effects and licensed recorded/sampled audio are local. Internal engine recordings
  establish valid nonzero playback, not subjective mix quality or speaker safety.
- The historical Android test preset/artifacts remain preserved; this audit adds
  no Android work and does not certify native phone performance. Controller/full
  screen-reader support is not implemented. Windows PC remains the priority.
- Unsigned private Windows builds may encounter local trust prompts. No public
  release, signing certificate, installer, auto-updater or production deployment
  is provided. Source and export instructions remain available on private work.
- No exact Haunted Dorm parity claim is made. This is an original game, with
  original artwork/audio and separately attributed local fonts/engine components.
