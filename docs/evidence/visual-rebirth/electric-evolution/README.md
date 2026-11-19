# Electric Ghost evolution art

The verified Level 1 technician establishes the gray coat, worn boots, pale gaunt face, static-swept hair and under-skin filaments. Levels 2–3 extend a sleeve, raise the collar and swing the tail. Level 4 opens the coat into an uneven staggered silhouette with separate hands. Levels 5–6 add a stiff coil of folded cloth and open a shoulder seam. Level 7 expands one side into a translucent partial coat shroud. Level 8 stretches the sleeve and coat as a broad attached sweep. Level 9 lifts one narrow fold above the shoulder, and Level 10 spreads the sleeves and coat around the crown of lifted hair.

Run `python tools/visual_rebirth/prepare_electric_evolution.py` from the repository root with ImageMagick 7, Pillow and NumPy. The three generated source sheets produce nine 328×264 sprites with a common (164, 260) pivot and a 256-pixel subject height. Adjacent floor-aligned masks differ by 46.8%, 57.2%, 38.2%, 60.1%, 52.0%, 39.2%, 54.3%, 66.3% and 47.7% at alpha ≥128, measured as symmetric difference divided by union. [Art gallery](electric-evolution-gallery.png)

Each new state has one oblique source. The Level 8 body leans left of the canvas pivot so its attached coat can extend to the right within the frame.
