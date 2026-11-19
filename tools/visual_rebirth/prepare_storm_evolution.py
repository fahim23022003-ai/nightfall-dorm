"""Pack the nine Storm Wraith evolution illustrations for Godot.

Run from the repository root with Pillow, NumPy and ImageMagick 7 installed:
    python tools/visual_rebirth/prepare_storm_evolution.py
"""

from pathlib import Path

from prepare_witch_evolution import pack_evolution


SOURCE_DIR = Path("docs/evidence/visual-rebirth/storm-evolution")
OUTPUT_DIR = Path("assets/visual_rebirth/storm")
# Segmentation threshold, matte cutoff and frame-specific horizontal foot centers.
SHEETS = {
    "anchor": (15, 18, [(4, 266), (7, 887), (10, 1683)]),
    "early": (15, 18, [(2, 309), (3, 879), (5, 1777)]),
    "late": (15, 18, [(6, 310), (8, 908), (9, 1716)]),
}


if __name__ == "__main__":
    pack_evolution(SOURCE_DIR, OUTPUT_DIR, SHEETS, (432, 264), (216, 260))
