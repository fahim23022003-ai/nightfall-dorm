# Known limitations

- This is an original small-scale game with configurable approximate balance. Exact Haunted Dorm numerical parity and overall parity are **unverified** because reference access was blocked; see GAMEPLAY_REFERENCE.md and FEATURE_PARITY.md.
- Desktop keyboard/mouse is the supported interaction model. Mobile export, touch controls, controller input, narrow screens, and accessibility options are future work.
- Graphics use original procedural placeholder art and simple effects. The fixed overview camera has no zoom/pan; final art, animation and horror lighting are not production quality.
- Sound effects are synthesized locally. Cloud audio output was unavailable, so audible quality/mixing is unverified. Settings are session-local rather than saved preferences.
- Map and collision are deliberately simple rectangular room/corridor geometry. There is one map and one hunter archetype.
- Purchase rejection messages combine several possible causes rather than identifying the precise missing resource/prerequisite. Players should read the visible prices and handbook.
- Automated tests and Linux software-rendered screenshots do not establish Windows hardware compatibility, mobile compatibility, real-time performance on target devices, or long-term balance quality.
- Export availability and automated QA outcomes are recorded separately in README.md and QA_REPORT.md. Do not infer an export or a passing test from this limitations document.
- Passive-player simulations show bots can sometimes defeat the hunter without player spending. Match difficulty and the contribution required from the player need further balancing.
- No standalone Windows executable was created: matching Godot export templates are absent. The source project runs through Godot; Windows standalone export remains unverified.
