"""Normalize the canonical and transformed Reaper cutouts to one foot anchor."""
import argparse
from pathlib import Path

from PIL import Image

SIZE = (224, 264)
PIVOT_Y = 260
BODY_HEIGHT = 256


def normalize(source, destination):
    with Image.open(source) as original:
        art = original.convert("RGBA")
    alpha = art.getchannel("A")
    bounds = alpha.point(lambda value: 255 if value >= 20 else 0).getbbox()
    if not bounds:
        raise ValueError(f"{source} has no visible subject")
    art = art.crop(bounds)
    art = art.resize((round(BODY_HEIGHT * art.width / art.height), BODY_HEIGHT), Image.Resampling.LANCZOS)
    if art.width >= SIZE[0]:
        raise ValueError(f"{source} exceeds the normalized cloak width")
    sprite = Image.new("RGBA", SIZE)
    sprite.alpha_composite(art, ((SIZE[0] - art.width) // 2, PIVOT_Y - BODY_HEIGHT))
    sprite.save(destination, optimize=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("canonical", type=Path)
    parser.add_argument("transformed", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    for name, source in (("approach", args.canonical), ("transformed", args.transformed)):
        normalize(source, args.output / f"{name}.png")
