# Crusher intermediate directional art

Levels 2, 3, 5, 6, 8, and 9 each have four newly authored cardinal views based on the approved oblique at that level. The sets preserve Crusher's weathered coat, cuffs, boots, anguished face, and asymmetric arm growth. Level 2 retains the folded smaller arm and sash, Level 3 raises the ragged shoulder, Levels 5 and 6 expose the enlarged shoulder in different arm poses, Level 8 carries the low spread hand, and Level 9 has the broad upper torso and hanging arm. Hair, folds, and perspective vary by drawing.

Run `python tools/visual_rebirth/prepare_crusher_nonanchor_turnarounds.py` from the repository root with Pillow. The script repacks the archived source sheets into 24 transparent 328×264 PNGs with 256 px subject height and a shared `(164, 260)` floor pivot. Level 6's source sheet places its profiles in the opposite order. The packer assigns them using their actual facing.

The 24 packed textures are distinct, have transparent canvas borders, and reproduced byte for byte in a second run. Each pair of profile alpha masks differs after reflection. All 96 body marks land on alpha ≥128. The marked head position is the visible nape in a rear view. Where a hand is occluded, its mark falls on the adjoining visible silhouette. [Landmark table](landmarks.json)

The gallery shows packed artwork at 104 px alongside its matching existing oblique. Godot bindings and runtime captures are separate evidence. [Art gallery](crusher-intermediate-direction-gallery.png)
