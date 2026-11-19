"""Pack the nine existing Witch evolution illustrations for Godot.

Run from the repository root with Pillow, NumPy and ImageMagick 7 installed:
    python tools/visual_rebirth/prepare_witch_evolution.py
"""

from collections import Counter
from pathlib import Path
import subprocess
import tempfile

from PIL import Image, ImageChops, ImageFilter
import numpy as np


SOURCE_DIR = Path("docs/evidence/visual-rebirth/witch-evolution")
OUTPUT_DIR = Path("assets/visual_rebirth/witch")
SIZE = (328, 264)
PIVOT = (164, 260)
HEIGHT = 256
# Each sheet defines the component threshold and individual level/foot anchors.
SHEETS = {
    "anchor": (15, 18, [(4, 246), (7, 786), (10, 1440)]),
    "early": (35, 86, [(2, 365), (3, 1018), (5, 1746)]),
    "late": (15, 18, [(6, 238), (8, 790), (9, 1544)]),
}


def position_component(image, labels, component, matte_cutoff, foot_x, size, pivot):
    component_mask = Image.fromarray(
        (labels == component).astype(np.uint8) * 255
    ).filter(ImageFilter.MaxFilter(7))
    alpha = image.getchannel("A").point(
        lambda value: round(255 * max(value - matte_cutoff, 0) / (255 - matte_cutoff))
    )
    alpha = ImageChops.multiply(alpha, component_mask)
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError("Missing sprite alpha")

    image = image.copy()
    image.putalpha(alpha)
    sprite = image.crop(bounds)
    scale = HEIGHT / sprite.height
    sprite = sprite.resize((round(sprite.width * scale), HEIGHT), Image.Resampling.LANCZOS)
    left = pivot[0] - round((foot_x - bounds[0]) * scale)
    if left < 0 or left + sprite.width > size[0]:
        raise ValueError("Sprite does not fit the floor-centered canvas")

    canvas = Image.new("RGBA", size)
    canvas.alpha_composite(sprite, (left, pivot[1] - HEIGHT))
    return canvas


def pack_evolution(source_dir, output_dir, sheets, size, pivot):
    output_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as temporary:
        label_path = Path(temporary) / "components.png"
        for sheet, (threshold, matte_cutoff, views) in sheets.items():
            source = source_dir / f"{sheet}-source.png"
            subprocess.run(
                ["magick", str(source), "-alpha", "extract", "-threshold", f"{threshold}%",
                 "-define", "connected-components:mean-color=false", "-connected-components",
                 "8", "-depth", "16", str(label_path)], check=True
            )
            image = Image.open(source).convert("RGBA")
            with Image.open(label_path) as component_image:
                labels = np.asarray(component_image)
            areas = Counter(labels.ravel())
            del areas[0]
            components = [component for component, _ in areas.most_common(len(views))]
            components.sort(key=lambda component: np.nonzero(labels == component)[1].min())
            if len(components) != len(views):
                raise ValueError(f"Expected {len(views)} sprites in {source}")
            for (level, foot_x), component in zip(views, components):
                if level is None:
                    continue
                sprite = position_component(image, labels, component, matte_cutoff, foot_x, size, pivot)
                sprite.save(output_dir / f"level_{level:02d}_oblique.png", optimize=True)


if __name__ == "__main__":
    pack_evolution(SOURCE_DIR, OUTPUT_DIR, SHEETS, SIZE, PIVOT)
