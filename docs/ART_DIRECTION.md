# Nightfall Dorm — cartoon art direction

Current direction: approachable, outlined cartoon students and bedrooms, interrupted by a tall ragged purple shadow hunter with crimson eyes. This replaces the ornate illustrated prototype; the game remains an original dormitory defense game. No Haunted Dorm art, audio or characters were extracted.

## Palette and scale

Walls `#607D8B`, primary floor `#82929A`, corridor `#263746`, warm safety light `#FFD27A`, gold `#F4C542`, electricity `#4DDDF3`, damage `#F05467`, hunter `#A88CEB`, selection `#7BE3A1`. Room-specific floor accents distinguish standard, student, messy, cozy, old dorm and maintenance rooms without changing their mechanics or collision geometry.

The design canvas is **1280×720**, continuous canvas-item scaling, 960×540 minimum. This is the alternative to a 640×360 integer pixel-art canvas: these original shaded cartoon sprites are not pixel art. HUD values use 25px text, headings 18–30px, contextual card text 16px; the focused room camera enlarges world labels. The overview deliberately sacrifices fine object detail for strategic context. Native Windows high-DPI and ultrawide validation remain unverified.

## Assets and identity

`assets/cartoon/source_objects.png`, `source_students.png` and `source_hunter.png` are original generated atlases, each 1536×1024, six columns and four rows. The hunter atlas underwent an image-generation background-removal edit after actual captures exposed a rectangular low-alpha haze. The source atlas is retained; export excludes source sheets. `tools/art/prepare_cartoon.py` extracts cells to transparent 256px canvases, builds deterministic floor surfaces and machine attachments, and converts the student sprite to a Windows icon. Pillow is an offline tooling dependency only.

- Beds: five actual-level silhouettes, from simple metal frame to cyan-lit upgraded bed.
- Doors: five actual-level sprites, from plain door through braced and electrified security door.
- Player: four directions, four walking frames per direction, sleeping, entry and elimination sprites.
- Bots: five visibly distinct students (purple glasses, green bob, auburn sleepy, red ponytail, yellow cap), five sleeping poses and cutout gait frames. Bot locomotion is less complete than the player's directional animation; do not describe it as full directional animation.
- Hunter: idle, movement, raised/back attack, forward attack, hurt and dissolving death. Attack feedback follows the real attack cooldown and damage event.
- Needle/Arc turrets: four upgrade appearances each; supports: four attachment stages each. Generator spokes, relay pulses and advanced Arc electrical accents animate while occupied.
- Decorations: school desk/laptop/chair, cabinet, shelf, plants, bedside lights, window, posters, books, clothing, rug and utility pipes. Small wall pictures/floor clutter are decorative, not extra blocked floor pads.
- Existing neutral coin, electricity, glow and contact-shadow assets remain local originals. DejaVu Sans regular/bold fonts use the license at `assets/fonts/LICENSE.txt`.

## Interaction and feedback rules

The room camera follows the awake player, then frames the occupied room. M switches to the whole map; wheel adjusts focus zoom. Actual attacks on the player's door widen and shift attention toward the doorway. A placement ghost is green only when a real transaction is allowed and red otherwise. Cards never deduct resources until confirmation; Escape/cancel costs nothing. Existing machines use a separate inspector.

Construction dust, upgrade rings, door shake/cracks, repair sparks and projectile impact effects follow production model changes. Turret damage applies at actual travelling-projectile impact, not at a decorative muzzle flash. Floating gold derives from earned income. The short tutorial can be disabled with G/Help/settings.

## Remaining art work

Complete bot directional animation and additional hunter directions, improve small character poses and shadow consistency, inspect more aspect ratios and Windows display scaling, and obtain human readability/comfort feedback. This is a coherent playable cartoon milestone, not a claim of commercial-final art or exact reference fidelity.
