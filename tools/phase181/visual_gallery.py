#!/usr/bin/env python3
"""Arrange unscaled native Godot crops and copy the source evidence."""

import argparse
import json
from pathlib import Path
import shutil

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FONTS = ROOT / "assets/fonts"
CROP = (547, 238, 733, 454)
GROUPS = {
    "weapon-scale": {
        "turret": "Needle Turret",
        "heavy": "Arc Turret",
        "flame": "Flame Turret",
        "frost": "Frost Tower",
        "shock": "Shock Trap",
    },
    "support-scale": {
        "generator": "Dynamo",
        "repair": "Repair Station",
        "auto_repair": "Auto Repair Station",
        "economy": "Dream Amplifier",
        "enhancer": "Target Relay",
    },
    "utility-scale": {
        "barrier": "Mirror Barrier",
        "shield": "Shield Generator",
        "decoy": "Decoy Beacon",
        "plasma": "Plasma Capacitor",
        "antenna": "Ward Antenna",
    },
}


def font(size):
    return ImageFont.truetype(str(FONTS / "Interface.ttf"), size)


def crop(folder, scene):
    with Image.open(folder / f"{scene}.png") as source:
        if source.size != (1280, 720):
            raise ValueError(f"Incorrect source viewport for {scene}")
        return source.convert("RGB").crop(CROP)


def receipt(folder):
    data = json.loads((folder / "receipt.json").read_text())
    if data["failures"]:
        raise ValueError(f"Capture has failed checks: {folder}")
    return data["scenes"]


def dimensions(data):
    width, height = (int(value) for value in data["footprint"])
    return f"{width // 16}×{height // 16} cells"


def match_pair(old, new):
    if old["camera_zoom"] != new["camera_zoom"]:
        raise ValueError("Comparison camera scales differ")
    if old["scale"] >= new["scale"]:
        raise ValueError("The art did not become larger")


def family_gallery(filename, names, old, new, baseline_folder, preview_folder):
    board = Image.new("RGB", (1028, 292 * len(names) + 32), "#111822")
    draw = ImageDraw.Draw(board)
    for row, (kind, name) in enumerate(names.items()):
        key = f"{kind}-l01"
        match_pair(old[key], new[key])
        y = row * 292
        draw.text((48, y + 28), name, "#f4f0e8", font=font(25))
        draw.text((48, y + 72), "Level 1", "#bac8d6", font=font(15))
        for x, tag, folder, data in (
            (395, "Previous", baseline_folder, old[key]),
            (678, "Building Scale", preview_folder, new[key]),
        ):
            draw.text((x, y + 17), f"{tag} · {dimensions(data)}", "#d2b47b", font=font(19))
            board.paste(crop(folder, key), (x, y + 48))
        draw.line((48, y + 282, 982, y + 282), "#2d3d4c")
    board.save(filename, optimize=True)


def specialization_gallery(filename, old, new, baseline_folder, preview_folder):
    names = {
        "turret": "Needle · Heavy Precision",
        "heavy": "Arc · Storm Coil",
        "generator": "Dynamo · Overcharge",
        "repair": "Repair · Powered Sutures",
    }
    board = Image.new("RGB", (970, 272 * len(names) + 32), "#111822")
    draw = ImageDraw.Draw(board)
    for row, (kind, title) in enumerate(names.items()):
        y = row * 272
        draw.text((34, y + 15), title, "#f4f0e8", font=font(22))
        for index, (tag, folder, level) in enumerate(
            [
                ("Previous L1", baseline_folder, 1),
                ("Previous L10", baseline_folder, 10),
                ("Building Scale L1", preview_folder, 1),
                ("Building Scale L10", preview_folder, 10),
            ]
        ):
            key = f"{kind}-l{level:02d}"
            match_pair(old[key], new[key])
            if level == 10 and (new[key]["level"] != 10 or not new[key]["branch"]):
                raise ValueError("Missing specialized L10")
            x = 34 + index * 236
            draw.text((x, y + 46), tag, "#d2b47b", font=font(17))
            board.paste(crop(folder, key), (x, y + 70))
    board.save(filename, optimize=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("baseline", type=Path)
    parser.add_argument("preview", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    args.destination.mkdir(parents=True, exist_ok=True)
    old = receipt(args.baseline)
    new = receipt(args.preview)
    for group, names in GROUPS.items():
        family_gallery(args.destination / f"{group}.png", names, old, new, args.baseline, args.preview)
    specialization_gallery(args.destination / "specializations.png", old, new, args.baseline, args.preview)
    for tag, folder in (("before", args.baseline), ("after", args.preview)):
        for name in ("turret-l01", "heavy-l01", "small-defense", "large-defense", "crowded-comparison", "placement-valid", "placement-blocked"):
            shutil.copyfile(folder / f"{name}.png", args.destination / f"{name}-{tag}.png")
        shutil.copyfile(folder / "receipt.json", args.destination / f"{tag}.json")


if __name__ == "__main__":
    main()
