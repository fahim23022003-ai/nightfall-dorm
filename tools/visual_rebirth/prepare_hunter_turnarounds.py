"""Pack the authored Phase 14E cardinal sheets with Pillow.

Run from the repository root. Existing oblique sprites remain independent.
"""

from pathlib import Path

from PIL import Image


EVIDENCE = Path("docs/evidence/visual-rebirth")
ASSETS = Path("assets/visual_rebirth")
VIEWS = ("front", "left", "back", "right")
SHEETS = (
    ("stalker", 1, "directional-stalker/base-source.png", 216, (341, 944, 328, 914)),
    ("stalker", 10, "directional-stalker/apex-source.png", 328, (330, 852, 321, 904)),
    ("witch", 10, "witch-directional/apex-source.png", 328, (356, 900, 363, 1066)),
    ("storm", 10, "storm-evolution/apex-turnaround-source.png", 432, (268, 852, 384, 1022)),
)


def pack_sheet(family, level, source_path, width, foot_anchors):
    source = Image.open(EVIDENCE / source_path).convert("RGBA")
    for index, (view, foot_x) in enumerate(zip(VIEWS, foot_anchors)):
        column, row = index % 2, index // 2
        left = column * source.width // 2
        top = row * source.height // 2
        sprite = source.crop((left, top, (column + 1) * source.width // 2,
                              (row + 1) * source.height // 2))
        alpha = sprite.getchannel("A").point(lambda value: round(255 * max(0, value - 12) / 243))
        sprite.putalpha(alpha)
        box = alpha.getbbox()
        if box is None:
            raise ValueError(f"Missing alpha for {family} level {level} {view}")
        sprite = sprite.crop(box)
        scale = 256 / sprite.height
        sprite = sprite.resize((round(sprite.width * scale), 256), Image.Resampling.LANCZOS)
        x = width // 2 - round((foot_x - left - box[0]) * scale)
        if x < 1 or x + sprite.width >= width:
            raise ValueError(f"Clipped art for {family} level {level} {view}")
        canvas = Image.new("RGBA", (width, 264))
        canvas.alpha_composite(sprite, (x, 4))
        canvas.save(ASSETS / family / f"level_{level:02d}_{view}.png", optimize=True)


if __name__ == "__main__":
    for sheet in SHEETS:
        pack_sheet(*sheet)
