# Visual audit report

11 November 2026, Singapore. One main agent performed implementation and testing; only Agent D was activated for a bounded independent screenshot review. No four-agent continuous audit or duplicate reference research was run.

## Real capture method

All new images are under [screenshots/](screenshots/README.md). They are actual Godot 4.6.3 OpenGL/Mesa rendered frames from the running project on Xorg :99, saved using the viewport image API after frame rendering. They are not generated mockups. The engine's viewport capture avoids fragile synchronous X11 window grabs; it is evidence of rendered game content, not Windows hardware behavior.

The retained helper [capture_fidelity.gd](../tools/capture_fidelity.gd) uses seed 71, explicitly claims room two and positions the player at its bed, then runs production BotAI spending with the normal starting 25 gold. No resources, buildings, damage or terminal result are injected. It captures naturally reached progression and victory. A second seed-eight run claims the nearest room, sleeps and buys nothing, producing natural defeat. Engine time is accelerated 4×. Claim/positioning is a disclosed setup fixture rather than real keyboard navigation; prior real X11-input evidence and the current scene mouse tests cover controls separately.

Combat frames 09 and 10 pause the simulation briefly to preserve actual attack/tracer state while rendering, and display PAUSED. They do not invent a hit or health value. Remaining frames are normal running-state captures. The combat caption was then moved and combat and early-progression frames recaptured with the helper's `--combat-only` mode; old complete-match outcome logs remain distinct from the partial recapture.

## Before / after findings

| Issue | Before evidence | Improvement | Verification |
| --- | --- | --- | --- |
| All actions looked similarly available | Existing `evidence/audit-match-080.png`; known-limitations record | Enabled/disabled styles reflect actual funds, prerequisites, pause, occupancy and caps | Independent review of new 03/05/07/09; 3,209 UI consistency/read-only checks |
| Selected upgrade lacked clear action cost | Previous generic Upgrade selected control | Explicit gold/power cost or MAX on upgrade action; catalog name for selected building | New 05/07 and focused UI assertions |
| Hunter caption overlapped door-level text | Initial new frame 09; independently identified | State caption placed beside the hunter with map-boundary clamping | Recaptured 09 and 10 visually inspected by main agent |

No critical HUD/sidebar overlap was found in the independently reviewed new 1280×800 frames. Original placeholder art is unchanged. New style uses the same design coordinates/fonts; previous 960×600/fullscreen checks remain historical evidence, not a new target-hardware validation. Tooltip presentation, high-DPI Windows behavior, mobile/touch and audible sound still need platform testing.

## Authentic reference comparison

**UNVERIFIED.** TapTap, GamingOnPhone and the listing search remain blocked by proxy 403. No authentic Haunted Dorm screenshot/video was obtained, so camera, proportions, artwork, hierarchy and combat presentation cannot be truthfully scored for visual resemblance. Local top-down rooms/corridors, separate beds/doors/tiles, hunter color, resource counters and traces are recognizable in the new captures; that is an assessment of Nightfall Dorm usability, not comparison evidence.

Independent review score: **visual 7/10, UX 8/10**. The main agent's combined visual/UI score is 7.5/10. Remaining weaknesses are simple geometric art, limited animation/lighting and unverified target-device/audio behavior. Further cosmetic rewrites without reference or usability evidence were deferred to avoid unnecessary usage.

## Reproduce

With the documented Xorg display available:

```sh
DISPLAY=:99 LIBGL_ALWAYS_SOFTWARE=1 \
XDG_DATA_HOME=/workspace/runtime-data XDG_CONFIG_HOME=/workspace/runtime-config \
XDG_CACHE_HOME=/workspace/runtime-cache \
godot --path /workspace/nightfall-dorm --rendering-method gl_compatibility \
--audio-driver Dummy --script tools/capture_fidelity.gd
```

See [GRAPHICAL_TESTING.md](GRAPHICAL_TESTING.md) for display setup. Every capture records filename, simulated time, resources, hunter state/HP, result, pause method and save status in [fidelity-captures.log](evidence/fidelity-captures.log). The full run produced 12 images, victory=true and defeat=true, exit 0. No Windows screenshot is claimed.
