"""Pack the Ravager's distinct crouched views at a stable ground pivot."""
import argparse
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

SIZE = (328, 264)
HEIGHT = 208
FLOOR = 260


def subjects(sheet, count):
    mask = np.array(sheet.getchannel("A")) > 120
    regions, _ = ndimage.label(mask)
    weights = np.bincount(regions.ravel())
    weights[0] = 0
    indices = sorted(np.argsort(weights)[-count:], key=lambda i: int(np.nonzero(regions == i)[1].min()))
    for index in indices:
        core = regions == index
        edge = ndimage.binary_dilation(core, iterations=4)
        sprite = sheet.copy()
        sprite.putalpha(Image.fromarray(np.where(edge, np.array(sheet.getchannel("A")), 0)))
        yield sprite


def pack(image, destination):
    bounds = image.getchannel("A").point(lambda a: 255 if a >= 16 else 0).getbbox()
    if bounds is None:
        raise ValueError(f"Missing art for {destination.name}")
    image = image.crop(bounds)
    width = round(HEIGHT * image.width / image.height)
    if width > SIZE[0] - 8:
        raise ValueError(f"{destination.name} exceeds the available gameplay envelope")
    art = image.resize((width, HEIGHT), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", SIZE)
    canvas.alpha_composite(art, ((SIZE[0] - width) // 2, FLOOR - HEIGHT))
    canvas.save(destination, optimize=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("canonical", type=Path)
    parser.add_argument("source_dir", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    images = {1: Image.open(args.canonical).convert("RGBA")}
    anchors = Image.open(args.source_dir / "anchors-source.png").convert("RGBA")
    images.update(zip((4, 7, 10), subjects(anchors, 3), strict=True))
    middle = Image.open(args.source_dir / "intermediates-source.png").convert("RGBA")
    for row, levels in enumerate(((2, 3, 5), (6, 8, 9))):
        for column, level in enumerate(levels):
            width, height = middle.width // 3, middle.height // 2
            images[level] = middle.crop((column*width,row*height,(column+1)*width,(row+1)*height))
    for level, image in images.items():
        pack(image, args.output / f"level_{level:02d}_oblique.png")
