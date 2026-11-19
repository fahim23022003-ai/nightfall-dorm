# Storm Wraith evolution art

The verified Level 1 image establishes the drowned blue-gray face, straight wet hair, weathered slate overcoat and bare feet. Levels 2–3 change the knee, cuff, collar and lean. Level 4 lifts both arms and throws an asymmetrical coat curl to the rear. Levels 5–6 separate the overcoat's weight into a trailing point and dipped mantle. Level 7 expands the cape into a broad diagonal. Level 8 splits the coat into two horizontal wave-like folds. Level 9 lifts a hooked shoulder crest. Level 10 raises the hair and collar into a broad crown and separates the lower coat into angled falls.

Run `python tools/visual_rebirth/prepare_storm_evolution.py` from the repository root with ImageMagick 7, Pillow and NumPy. The three generated source sheets produce nine 432×264 sprites with a common (216, 260) pivot and a 256-pixel subject height. The extra canvas width preserves the long asymmetric hems at the same height. The Level 1 reference pack has a 328×264 canvas. Adjacent floor-aligned masks differ by 43.1%, 53.7%, 47.8%, 49.1%, 40.9%, 57.6%, 36.4%, 41.0% and 50.3% at alpha ≥128, measured as symmetric difference divided by union. [Art gallery](storm-evolution-gallery.png)

Each new state has one oblique source. Separate action deformation and motion evidence appear in the Godot verification records.
