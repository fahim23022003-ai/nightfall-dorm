"""Find a common padded visible rectangle within every cell of each atlas layer."""
from pathlib import Path

from PIL import Image

ATLAS_ROOT = Path("assets/visual_rebirth/buildings")
OUT = Path("scripts/rebirth_atlas_bounds.gd")


def cell_bounds(file, tile):
    with Image.open(file) as source:
        alpha = source.getchannel("A")
    width, height = alpha.size
    if width % tile or height % tile:
        raise ValueError(f"Incorrect cell size for {file}")
    bounds = []
    for top in range(0, height, tile):
        for left in range(0, width, tile):
            if box := alpha.crop((left, top, left + tile, top + tile)).getbbox():
                bounds.append(box)
    if not bounds:
        raise ValueError(f"No visible art in {file}")
    x = max(0, min(box[0] for box in bounds) - 3)
    y = max(0, min(box[1] for box in bounds) - 3)
    end_x = min(tile, max(box[2] for box in bounds) + 3)
    end_y = min(tile, max(box[3] for box in bounds) + 3)
    return f"Rect2({x},{y},{end_x-x},{end_y-y})"


def main():
    lines = ["extends RefCounted", "# Generated with tools/visual_rebirth/generate_atlas_bounds.py.", "const LAYERS = {"]
    for folder in sorted(ATLAS_ROOT.iterdir()):
        if not (folder / "base.png").exists():
            continue
        tile = 112 if folder.name == "turret" else 96
        layers = []
        for name in ("base", "launcher", "motion"):
            file = folder / f"{name}.png"
            if file.exists():
                layers.append(cell_bounds(file, tile))
        lines.append(f' "{folder.name}":[{",".join(layers)}],')
    lines.append("}")
    OUT.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
