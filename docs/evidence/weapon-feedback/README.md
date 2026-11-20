# Weapon feedback evidence

These Godot 4.6.3 captures use the live game scene at 1280×720. Movie
Maker advances the simulation at 24 frames per second with the game's
stereo mix. The fixture prepares room ownership, resources, a legal
Full Room Grid layout and the combat opening so the same encounters
can be repeated. It buys the machines and runs projectile movement,
contacts, damage and audio through the existing game systems.

| Scenario | Real video | Screenshots and model receipts |
| --- | --- | --- |
| Needle aim, flight, hit and selected machine | [Clip](clips/needle/capture.mp4) | [Flight](clips/needle/flight-720.png) · [Hit](clips/needle/hit-720.png) · [Inspector](clips/needle/final-720.png) · [Trace](needle-shot.json) |
| Ten-machine mixed volley with Arc, Flame, Frost, Shock and a specialized Needle | [Clip](clips/mixed/capture.mp4) | [Impact and flight](clips/mixed/hit-720.png) · [Zoomed out](clips/mixed/final-720.png) · [Raw trace](clips/mixed/receipt.json) |
| Evolution shield absorbs a Needle | [Clip](clips/shield/capture.mp4) | [Blocked with HP intact](clips/shield/blocked-720.png) · [Raw trace](clips/shield/receipt.json) |
| Undead dies while other weapons are still tracking | [Clip](clips/cancel/capture.mp4) | [Actual canceled projectile IDs](clips/cancel/receipt.json) |
| Reaper hits and immune contacts, 24 structures on Low | [Clip](clips/reaper/capture.mp4) | [Live combat](clips/reaper/final-720.png) · [Raw trace](clips/reaper/receipt.json) |
| Allied room on spectator camera | [Clip](clips/ally/capture.mp4) | [Ally shot and damage](clips/ally/hit-720.png) · [Raw trace](clips/ally/receipt.json) |
| Sixty machines, Standard | [Clip](clips/dense-standard/capture.mp4) | [Wide combat view](clips/dense-standard/final-720.png) · [Raw trace](clips/dense-standard/receipt.json) |
| Sixty machines, Low | [Clip](clips/dense-low/capture.mp4) | [Wide combat view](clips/dense-low/final-720.png) · [Raw trace](clips/dense-low/receipt.json) |

The single Needle trace follows one paid machine to one projectile and
multiple rendered flight samples. Its hit displays **9** and the Hunter's
HUD falls from **6,440 to 6,431**. The last inspector frame credits nine
hits and 81 total HP to that machine. The mixed clip also records applied
burn ticks separately from initial Flame hits. Independent validation
rechecked exact source IDs and every recorded impact's effective HP loss
across all eight captures. The defense, settings and
checkpoint tests verify stored counters, zero-damage guards, target
cancellation, modes, and multiple legitimate targets independently.

[Performance and matching](performance/) · [Regression logs](regressions/) · [Windows checks](windows/)
