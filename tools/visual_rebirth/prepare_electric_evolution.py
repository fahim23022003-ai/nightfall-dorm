"""Pack the nine Electric Ghost evolution illustrations for Godot.

Run from the repository root with Pillow, NumPy and ImageMagick 7 installed:
    python tools/visual_rebirth/prepare_electric_evolution.py
"""

from pathlib import Path

from prepare_witch_evolution import pack_evolution


SOURCE_DIR = Path("docs/evidence/visual-rebirth/electric-evolution")
OUTPUT_DIR = Path("assets/visual_rebirth/electric")
# Segmentation threshold, matte cutoff and frame-specific horizontal foot centers.
SHEETS = {
    "anchor": (35, 62, [(4, 249), (7, 783), (10, 1379)]),
    "early": (15, 18, [(2, 292), (3, 756), (5, 1416)]),
    "late": (15, 18, [(6, 279), (8, 846), (9, 1577)]),
}


if __name__ == "__main__":
    pack_evolution(SOURCE_DIR, OUTPUT_DIR, SHEETS, (328, 264), (164, 260))
