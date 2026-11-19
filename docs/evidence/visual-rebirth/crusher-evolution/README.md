# Crusher evolution art

The verified Crusher reference establishes the haggard face, weathered taupe coat, restraints, oversized human hands and boots. Levels 2–3 change shoulder tilt, forearm position and hanging cloth. Level 4 tears one shoulder and separates the bent arm from the torso. Levels 5–6 change the coat's weight, expose a wider shoulder and raise the elbow. Level 7 expands one arm and rib silhouette. Level 8 extends the large hand nearly to the floor while the smaller hand braces the body. Level 9 widens the back ridge and curls the small arm inward. Level 10 clears the upper body of coat layers and uses the giant hanging arm to exaggerate its asymmetry.

Run `python tools/visual_rebirth/prepare_crusher_evolution.py` from the repository root with ImageMagick 7, Pillow and NumPy. The three generated source sheets produce nine 328×264 sprites with a common (164, 260) pivot and a 256-pixel subject height. The known canonical source supplies Level 1. Adjacent floor-aligned masks differ by 33.1%, 30.6%, 27.6%, 39.6%, 34.8%, 30.1%, 38.4%, 35.0% and 22.4% at alpha ≥128, measured as symmetric difference divided by union. [Art gallery](crusher-evolution-gallery.png)

Each generated stage represents a single gameplay oblique. The gallery is for static art inspection at 104 px and enlarged. Gameplay captures and presentation verification are separate evidence.
