# Phase 3B actual map render and mouse audit

Agent D used Godot4.6.3/OpenGL/Mesa llvmpipe on a private Xorg dummy display.
Final run: **201 checks, 0 failures, exit0; 18 PNGs saved successfully**.
`render.log` records the final run. Reproduce with `tools/capture_maps.gd` and the
existing Xorg instructions in `docs/GRAPHICAL_TESTING.md`.

Fixtures start an isolated free-play match, configure the selected stage's map
before claiming/sleeping, and provide resources for interaction checks. This
avoids modifying stage unlock records and is not evidence of natural progression,
match balance or a Windows-native run. Simulation is frozen for repeatability;
the helper explicitly settles the same camera used by normal frame processing.
It synchronizes X11 cursor position with injected real mouse events so real
window input and synthetic events agree. Initial unsynchronized fixtures failed;
those are not represented as passing gameplay evidence. Main subsequently made
production clicks use the event's position instead of polling the global cursor.

For each of the five maps, the final fixture:

- Captures a full overview, the highest-pad inspector and the purchased highest
  pad with upgrade/sell controls (`stage_N-*.png`).
- Actually clicks every floor pad in representative room1, not just projects
  coordinates, and checks its selection and usable screen position. The five
  room1 capacities tested here are12/12/10/12/16. Broader all-room coverage belongs
  to the separate automated map UI/core suites.
- Double-clicks the turret card, moves across map space, confirms one purchase
  on the locked highest pad, reopens the inspector and sells the building.
  The tile becomes free, and the exact half-purchase refund is10gold/0electricity.
- Checks the tutorial/feedback box is hidden while the custom-map inspector is
  open and restored after it closes, preserving the tutorial preference.

Agent D visually inspected the final frames. Environments are distinguishable
by geometry and local decoration, not only tint: dorm checker/wood flooring and
room furnishings; hospital tile, IV stand and monitor/medical cabinet; hotel's
long alternating-room corridor, carpet/clock/bell-counter styling; laboratory's
vertical corridor network, wall panels and horizontal-facing room entrances;
mansion rugs, portraits/candles and larger capacity rooms.

`lab-right-side-door.png` complements Stage4's left-room screenshots with the
opposite entrance orientation. `mansion-room1-960x540.png` and
`mansion-room2-960x540.png` show16-pad and10-pad rooms at the smaller viewport.
All pads, owned beds/residents, door graphics/HP, build cards and sale controls
remain clear in these final inspector frames. The actual image size is960×540
inside a requested960×600 physical window because the game preserves its canvas
aspect ratio. Other images are1280×720.

A genuine rendered issue was found: the left-shifted context camera put the
owned bed/head under the tutorial box, especially in laboratory side-door rooms.
Main fixed custom-map guide visibility; final captures and ten dedicated checks
confirm beds/doors are unobscured and tutorial visibility returns after close.
No outstanding inspector/owned-room overlap or highest-pad input defect was
found in the audited final fixtures. Whole-map tutorial overlays remain optional
and can be toggled with G; decorative world map headings may leave the frame
when zoomed into a room. No native Windows, audible-quality or hardware-FPS claim
is made. The unsupported VSync-setting warning is expected on llvmpipe; final
log has no script/parse/error signatures. Only the audit's Xorg display was stopped.
