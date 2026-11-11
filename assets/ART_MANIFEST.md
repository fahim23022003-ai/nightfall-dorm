# Original visual-overhaul assets

The illustrated atlas in `art/source_atlas.png` was created specifically for Nightfall Dorm using the available authorized image-generation workflow. No Haunted Dorm image or copyrighted game asset was supplied, extracted or traced. The source atlas and finished crops are stored locally so the game has no external asset/runtime network dependency.

Art direction: cozy-eerie overhead cartoon illustration, dark plum outlines, warm wood/brass, teal bedding and lights, violet midnight moth antagonist. The atlas contains 24 isolated illustrations: two beds; cabinet/fern/lantern/wood door; player idle/two walking poses/sleeping plus two auburn resident poses; five hunter states and reinforced door; six functional machines.

`tools/art/prepare_art.py` extracts the original 6×4 atlas and builds deterministic wood/corridor textures, foundation sigil, window, contact shadow, lantern glow, currency/power symbols and project icon. Pillow is a development-only dependency. The exported game only needs the prepared PNGs. There are 33 runtime art textures/icons plus the retained source atlas. The ICO is the Windows form of the project icon.

`assets/fonts/Display.ttf` and `Interface.ttf` are DejaVu Serif Bold and DejaVu Sans from the environment, distributed under the notices in `assets/fonts/LICENSE.txt`. Font authorship is not claimed as original game art.

Animation is deliberately lightweight: sprite pose swaps, breathing/walk bob, ghost attack/recoil/dissolve states, turret aim motion/traces, impact sparks and upgrade/income feedback. It is not a fully rigged or four-direction animation set. Two survivor base designs and palette variants are used; every bot does not yet have a unique illustrated body/sleep sheet.
