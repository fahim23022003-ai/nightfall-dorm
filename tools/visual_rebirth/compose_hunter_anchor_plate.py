"""Compose a comparison of unscaled crops made by capture_hunter_anchors.gd."""

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

LABELS = {
    "crusher": "Crusher",
    "stalker": "Stalker",
    "ravager": "Ravager",
    "witch": "Phantom Witch",
    "electric": "Electric Ghost",
    "storm": "Storm Wraith",
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("captures", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    record = json.loads((args.captures / "anchor-captures.json").read_text())
    levels = record["levels"]
    width, height = record["crop"][2:]
    gutter, label_width, header = 10, 135, 54
    size = (
        label_width + gutter + len(levels) * (width + gutter),
        header + len(LABELS) * (height + gutter),
    )
    plate = Image.new("RGB", size, (18, 21, 30))
    draw = ImageDraw.Draw(plate)
    title = ImageFont.truetype("DejaVuSans.ttf", 22)
    label = ImageFont.truetype("DejaVuSans.ttf", 17)
    draw.text((gutter, 8), "Hunter evolution", font=title, fill=(230, 226, 217))
    for column, level in enumerate(levels):
        left = label_width + gutter + (width + gutter) * column
        draw.text((left + width / 2, 34), f"L{level}", font=label, anchor="mm", fill=(207, 194, 171))
    for row, (archetype, name) in enumerate(LABELS.items()):
        top = header + (height + gutter) * row
        draw.text((gutter, top + height / 2), name, font=label, anchor="lm", fill=(230, 226, 217))
        for column, level in enumerate(levels):
            left = label_width + gutter + (width + gutter) * column
            with Image.open(args.captures / f"{archetype}-l{level:02d}.png") as crop:
                if crop.size != (width, height):
                    raise ValueError("Crop dimensions differ from recorded native size")
                plate.paste(crop.convert("RGB"), (left, top))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    plate.save(args.output, optimize=True)


if __name__ == "__main__":
    main()
