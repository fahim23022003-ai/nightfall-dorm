"""Pack the authored Hunter cardinal sheets with Pillow.

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

PHASE_14F_SHEETS = (
    ("crusher", 1, "phase14f/directions/crusher-l01-source.png", 328,
     (313, 909, 314, 922)),
    ("crusher", 4, "phase14f/directions/crusher-l04-source.png", 328,
     (320, 907, 330, 907)),
    ("crusher", 7, "phase14f/directions/crusher-l07-source.png", 328,
     (300, 925, 324, 956)),
    ("crusher", 10, "phase14f/directions/crusher-l10-source.png", 328,
     (353, 909, 300, 972), 256, ("front", "right", "back", "left")),
    ("stalker", 2, "phase14f/directions/stalker-l02-source.png", 328,
     (350, 919, 324, 914)),
    ("stalker", 3, "phase14f/directions/stalker-l03-source.png", 328,
     (366, 933, 353, 922)),
    ("stalker", 4, "phase14f/directions/stalker-l04-source.png", 328,
     (324, 935, 308, 935)),
    ("stalker", 5, "phase14f/directions/stalker-l05-source.png", 328,
     (319, 899, 318, 941)),
    ("stalker", 6, "phase14f/directions/stalker-l06-source.png", 328,
     (314, 869, 374, 1013)),
    ("stalker", 7, "phase14f/directions/stalker-l07-source.png", 328,
     (325, 892, 322, 964)),
    ("stalker", 8, "phase14f/directions/stalker-l08-source.png", 328,
     (319, 860, 306, 1042)),
    ("stalker", 9, "phase14f/directions/stalker-l09-source.png", 328,
     (368, 930, 306, 912)),
    ("ravager", 1, "phase14f/directions/ravager-l01-source.png", 328,
     (313, 991, 310, 814), 208),
    ("ravager", 4, "phase14f/directions/ravager-l04-source.png", 328,
     (316, 971, 274, 872), 208),
    ("ravager", 7, "phase14f/directions/ravager-l07-source.png", 328,
     (363, 990, 330, 908), 208, VIEWS, (584, 627)),
    ("ravager", 10, "phase14f/directions/ravager-l10-source.png", 328,
     (310, 937, 317, 881), 208),
    ("witch", 4, "phase14f/directions/witch-l04-source.png", 328,
     (312, 921, 315, 958)),
    ("witch", 7, "phase14f/directions/witch-l07-source.png", 328,
     (314, 896, 306, 977)),
    ("electric", 10, "phase14f/directions/electric-l10-source.png", 328,
     (315, 931, 318, 912)),
    ("electric", 1, "phase14f/directions/electric-l01-source.png", 328,
     (321, 958, 321, 944)),
    ("electric", 4, "phase14f/directions/electric-l04-source.png", 328,
     (306, 954, 314, 920)),
    ("electric", 7, "phase14f/directions/electric-l07-source.png", 328,
     (304, 904, 314, 924)),
    ("storm", 1, "phase14f/directions/storm-l01-source.png", 328,
     (292, 898, 331, 980)),
    ("storm", 4, "phase14f/directions/storm-l04-source.png", 432,
     (306, 890, 327, 967)),
    ("storm", 7, "phase14f/directions/storm-l07-source.png", 432,
     (303, 771, 330, 1089)),
    ("grim_reaper", 0, "phase14f/directions/reaper-approach-source.png", 224,
     (322, 925, 329, 920), 256, VIEWS, None, "approach"),
    ("grim_reaper", 0, "phase14f/directions/reaper-transformed-source.png", 224,
     (345, 873, 368, 925), 256, VIEWS, None, "transformed"),
)


def pack_sheet(family, level, source_path, width, foot_anchors, height=256,
               views=VIEWS, split_columns=None, output_stem=None, split_rows=None):
    source = Image.open(EVIDENCE / source_path).convert("RGBA")
    for index, (view, foot_x) in enumerate(zip(views, foot_anchors, strict=True)):
        column, row = index % 2, index // 2
        split = split_columns[row] if split_columns is not None else source.width // 2
        left, right = (0, split) if column == 0 else (split, source.width)
        split = split_rows[column] if split_rows is not None else source.height // 2
        top, bottom = (0, split) if row == 0 else (split, source.height)
        sprite = source.crop((left, top, right, bottom))
        alpha = sprite.getchannel("A").point(lambda value: round(255 * max(0, value - 12) / 243))
        sprite.putalpha(alpha)
        box = alpha.getbbox()
        if box is None:
            raise ValueError(f"Missing alpha for {family} level {level} {view}")
        sprite = sprite.crop(box)
        scale = height / sprite.height
        sprite = sprite.resize((round(sprite.width * scale), height), Image.Resampling.LANCZOS)
        x = width // 2 - round((foot_x - left - box[0]) * scale)
        if x < 1 or x + sprite.width >= width:
            raise ValueError(f"Clipped art for {family} level {level} {view}")
        canvas = Image.new("RGBA", (width, 264))
        canvas.alpha_composite(sprite, (x, 260 - height))
        stem = output_stem or f"level_{level:02d}"
        canvas.save(ASSETS / family / f"{stem}_{view}.png", optimize=True)


if __name__ == "__main__":
    for sheet in SHEETS + PHASE_14F_SHEETS:
        pack_sheet(*sheet)
