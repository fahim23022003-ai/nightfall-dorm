# Known limitations

- This is an original small-scale game with configurable approximate balance. Exact Haunted Dorm numerical parity and overall parity are **unverified** because reference access was blocked; see GAMEPLAY_REFERENCE.md and FEATURE_PARITY.md.
- Desktop keyboard/mouse is the supported interaction model. Mobile export, touch controls, controller input, phone-sized screens, and accessibility options are future work.
- Graphics use original procedural placeholder art and simple effects. The fixed overview camera has no zoom/pan; final art, animation and horror lighting are not production quality.
- Sound effects are synthesized locally. Cloud audio output was unavailable, so audible quality/mixing is unverified. Settings are session-local rather than saved preferences.
- Map and collision are deliberately simple rectangular room/corridor geometry. There is one map and one hunter archetype.
- Action buttons remain clickable when unaffordable, but purchases are rejected with specific reasons and exact shortages. Effects and prerequisites are exposed through tooltips; controller/touch alternatives to hover are not implemented.
- Automated tests and Linux software-rendered screenshots do not establish Windows hardware compatibility, mobile compatibility, real-time performance on target devices, or long-term balance quality.
- Export availability and automated QA outcomes are recorded separately in README.md and QA_REPORT.md. Do not infer an export or a passing test from this limitations document.
- An earlier balance revision allowed passive-player wins. The final 144-match matrix recorded 0/72 passive wins and 72/72 balanced automated-player wins (median 141 seconds), with advanced-building construction in all 72 active matches. This is evidence for those deterministic strategies/seeds, not broad human balance or difficulty validation; further playtesting and tuning remain useful.
- No standalone Windows executable was created: matching Godot export templates are absent. The source project runs through Godot; Windows standalone export remains unverified.

- Actual Linux graphical layout was checked at 1280×800 and the 960×600 minimum, plus 1280×800 fullscreen with a window manager. Other aspect ratios, Windows display scaling, and mobile screens remain unverified.
