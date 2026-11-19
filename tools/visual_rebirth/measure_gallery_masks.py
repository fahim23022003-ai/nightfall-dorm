#!/usr/bin/env python3
"""Measure aligned silhouette differences from the production Godot gallery."""

import argparse
from itertools import pairwise
import json
from pathlib import Path

from PIL import Image


BACKGROUND = (40, 53, 66)


def building_mask(sheet, level, row):
    x = 249 + (level - 1) * 105
    y = 236 + row * 170
    image = sheet.crop((x - 47, y - 97, x + 47, y + 34))
    pixels = image.get_flattened_data() if hasattr(image, "get_flattened_data") else image.getdata()
    return {
        index
        for index, pixel in enumerate(pixels)
        if sum(abs(value - background) for value, background in zip(pixel, BACKGROUND)) > 33
    }


def silhouette_change(previous, current):
    return round(len(previous ^ current) / max(1, len(previous | current)), 4)


def measure(sheet):
    rows = {}
    for row in range(3):
        first_level = 1 if row == 0 else 5
        levels = list(range(first_level, 11))
        masks = [building_mask(sheet, level, row) for level in levels]
        rows[str(row)] = {
            f"{level}-{level + 1}": silhouette_change(previous, current)
            for level, (previous, current) in zip(levels[:-1], pairwise(masks))
        }
    branches = {
        str(level): silhouette_change(building_mask(sheet, level, 1), building_mask(sheet, level, 2))
        for level in range(5, 11)
    }
    return {"adjacent": rows, "branch_pair": branches}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("before", type=Path)
    parser.add_argument("after", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("kinds", nargs="+")
    args = parser.parse_args()
    output = {"basis": "Symmetric difference divided by union of inferred subject masks from same-scale, same-bearing Godot inspection. This raster proxy cannot determine artistic quality or distinguish every fine component."}
    for kind in args.kinds:
        output[kind] = {}
        for mode, parent in (("before", args.before), ("after", args.after)):
            image = Image.open(parent / f"{kind}-adjacent-levels-720.png").convert("RGB")
            output[kind][mode] = measure(image)
    args.output.write_text(json.dumps(output, indent=2) + "\n")


if __name__ == "__main__":
    main()
