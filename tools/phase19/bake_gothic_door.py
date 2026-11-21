"""Bake the small Gothic door atlas in the existing door pivot and state grid."""
from pathlib import Path
from random import Random

from PIL import Image, ImageDraw

CELL = 96
SCALE = 3


def door(level, branch):
    image = Image.new("RGBA", (CELL * SCALE, CELL * SCALE))
    draw = ImageDraw.Draw(image)

    def polygon(points, color):
        draw.polygon([(x * SCALE, y * SCALE) for x, y in points], fill=color)

    def line(points, color, width=1):
        draw.line([(x * SCALE, y * SCALE) for x, y in points], fill=color, width=width * SCALE)

    def rect(box, color):
        draw.rectangle(tuple(n * SCALE for n in box), fill=color)

    def rivet(x, y, bright):
        draw.ellipse(((x-1.4)*SCALE, (y-1.4)*SCALE, (x+1.4)*SCALE, (y+1.4)*SCALE), fill="#1a191b")
        rect((x-.5, y-.8, x+.4, y), bright)

    crown = 34 - level
    left = 27 - (level-1)//3
    right = 96-left
    arch = [(left, 68), (left, 47), (left+3, crown+12), (40, crown+5), (48, crown),
            (56, crown+5), (right-3, crown+12), (right, 47), (right, 68)]
    polygon([(left-3, 72), (right+3, 72), (right+2, 76), (left-2, 76)], "#161a1d")
    polygon(arch, "#1c2026")
    line(arch[1:8], "#626766", 2)
    inset = [(left+4, 69), (left+4, 47), (left+7, crown+14), (41, crown+9), (48, crown+5),
             (55, crown+9), (right-7, crown+14), (right-4, 47), (right-4, 69)]
    polygon(inset, "#684635")
    pixels = image.load()
    rng = Random(4091)
    for y in range(crown*SCALE, 70*SCALE):
        for x in range(left*SCALE, right*SCALE):
            if pixels[x, y] != (104, 70, 53, 255):
                continue
            wood = rng.randrange(-8, 9) + ((x*13) % 17 - 8) + int((68-y/SCALE)*.26)
            plank = -19 if (x // SCALE - 33) % 7 == 0 else 0
            pixels[x, y] = (104+wood+plank, 70+wood+plank, 53+wood+plank, 255)
    line(inset[1:8], "#27242a", 2)
    for y in range(51, 65, 8):
        rect((left, y, left+4, y+4), "#414850")
        rect((right-4, y, right, y+4), "#30343a")
    rails = [62] + ([50] if level >= 3 else []) + ([68] if level >= 7 else [])
    for y in rails:
        rect((left+3, y, right-3, y+3), "#252a30")
        line([(left+4, y), (right-4, y)], "#646a6b")
        for x in [left+7, right-7]:
            rivet(x, y+1, "#a2977b")
    gold = "#d3aa62" if branch != "renewal" else "#86b9ae"
    for n in range(1+(level-1)//2):
        rivet(left+1, 49+n*4, gold)
        rivet(right-1, 49+n*4, gold)
    if level >= 4:
        line([(left+5, 65), (48, 46), (right-5, 65)], "#282c33", 3)
        line([(left+5, 64), (48, 45), (right-5, 64)], "#808182")
    if level >= 6:
        line([(48, crown+2), (48, 43)], "#343844", 3)
        line([(42, crown+9), (48, crown+4), (54, crown+9)], gold)
    if level >= 9:
        polygon([(48, 46), (54, 52), (48, 61), (42, 52)], "#22262d")
        line([(48, 47), (53, 52), (48, 58), (43, 52), (48, 47)], gold)
    if branch:
        for x in [left+7, right-7]:
            line([(x, 52), (x, 61)], gold, 2)
    rect((left-2, 71, right+2, 73), "#424a4b")
    line([(left-1, 71), (right+1, 71)], "#7b7770")
    rivet(54, 57, gold)
    return image.resize((CELL, CELL), Image.Resampling.LANCZOS)


atlas = Image.new("RGBA", (6*CELL, 4*CELL))
for state, (level, branch) in enumerate(
    [(i, "") for i in range(1, 11)]
    + [(i, "bulwark") for i in range(6, 11)]
    + [(i, "renewal") for i in range(6, 11)]
):
    atlas.paste(door(level, branch), ((state%6)*CELL, (state//6)*CELL))
target = Path(__file__).resolve().parents[2] / "assets/visual_rebirth/buildings/door/living_dorm.png"
atlas.save(target, optimize=True)
