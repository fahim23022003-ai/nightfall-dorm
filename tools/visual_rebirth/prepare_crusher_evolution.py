"""Pack the nine Crusher evolution illustrations for Godot.

Run from the repository root with Pillow, NumPy and ImageMagick 7 installed:
    python tools/visual_rebirth/prepare_crusher_evolution.py
"""

from pathlib import Path

from prepare_witch_evolution import pack_evolution


SOURCE_DIR = Path("docs/evidence/visual-rebirth/crusher-evolution")
OUTPUT_DIR = Path("assets/visual_rebirth/crusher")
# Segmentation threshold, matte cutoff and frame-specific horizontal foot centers.
SHEETS = {
    "anchor": (15, 18, [(4, 341), (7, 1049), (10, 1850)]),
    "early": (15, 18, [(2, 349), (3, 1020), (5, 1850)]),
    "late": (15, 18, [(6, 325), (8, 1089), (9, 1865)]),
}


if __name__ == "__main__":
    pack_evolution(SOURCE_DIR, OUTPUT_DIR, SHEETS, (328, 264), (164, 260))
