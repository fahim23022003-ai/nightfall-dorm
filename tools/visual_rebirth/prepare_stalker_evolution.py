"""Pack the nine Stalker evolution illustrations for Godot.

Run from the repository root with Pillow, NumPy and ImageMagick 7 installed:
    python tools/visual_rebirth/prepare_stalker_evolution.py
"""

from pathlib import Path

from prepare_witch_evolution import pack_evolution


SOURCE_DIR = Path("docs/evidence/visual-rebirth/stalker-evolution")
OUTPUT_DIR = Path("assets/visual_rebirth/stalker")
# Segmentation threshold, matte cutoff and frame-specific horizontal foot centers.
SHEETS = {
    "anchor": (15, 34, [(None, 211), (7, 629), (10, 1233)]),
    "anchor-revised": (15, 18, [(4, 609)]),
    "early": (15, 18, [(2, 329), (3, 887), (5, 1412)]),
    "late": (15, 18, [(6, 312), (8, 1034), (9, 1835)]),
}


if __name__ == "__main__":
    pack_evolution(SOURCE_DIR, OUTPUT_DIR, SHEETS, (328, 264), (164, 260))
