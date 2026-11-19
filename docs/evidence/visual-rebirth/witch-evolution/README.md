# Phantom Witch evolution art

The saved Level 1 oblique source guided the generated Level 4, 7 and 10 anchors. The Level 1 source and the three-anchor sheet guided both intermediate batches. Each of Levels 2–10 has one separately authored lower-left oblique image. The intermediate drawings borrow visual characteristics from nearby anchors. Their camera angle approximates the Art Bible's elevated view.

| Level | Physical change in the saved art |
| --- | --- |
| 2 | Swept hip cloth and a low curling hair lock |
| 3 | Raised hem, exposed calves and upward curls |
| 4 | Two lifted hair hooks and raised cloth shoulders |
| 5 | Long translucent shoulder veil and a large swept hair lock |
| 6 | Twin curved hair lobes and bifurcated veil |
| 7 | Hair halo with a clear opening and a long trailing veil |
| 8 | Broad forked veil, wider reach and outward skirt drape |
| 9 | Raised frozen lace mantle and fanned gray hair |
| 10 | Upswept frost crown, layered shoulders and a divided outer skirt |

The art gallery composites the packed sprites at 104 pixels and at a larger inspection scale. Floor-aligned masks at alpha ≥128 differ from their adjacent levels by 25.7%, 30.9%, 30.4%, 40.8%, 36.6%, 47.7%, 46.3%, 37.1% and 22.7%, measured as symmetric difference divided by union. [Art gallery](witch-evolution-gallery.png)

From the repository root, run `python tools/visual_rebirth/prepare_witch_evolution.py` with ImageMagick 7, Pillow and NumPy. The script maps the isolated pieces in `anchor-source.png`, `early-source.png` and `late-source.png` to Levels 2–10, trims the soft matte and packs each 256-pixel subject on a 328×264 RGBA canvas with nominal floor pivot (164, 260). The added canvas width accommodates the asymmetric late veils. A second packing run reproduced all nine PNG hashes and preserved Level 1's hash.

The new levels have one oblique pose source per evolution. They have no additional directional drawings or skeletal rig. Godot presentation, animation and gameplay verification are recorded separately from this art review.
