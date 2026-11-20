#!/usr/bin/env python3
"""Pack the existing resting overlay and housing into one Low-preset draw."""
from pathlib import Path

from PIL import Image


KINDS = (
    "auto_repair", "decoy", "economy", "enhancer", "generator",
    "plasma", "repair", "shield", "shock",
)
CELL = 96
COLUMNS = 6
STATES = 22
ROOT = Path(__file__).resolve().parents[2] / "assets/visual_rebirth/buildings"


def pack(kind: str):
    folder = ROOT / kind
    with Image.open(folder / "base.png") as image:
        rest = image.convert("RGBA")
    with Image.open(folder / "motion.png") as image:
        motion = image.convert("RGBA")
    for state in range(STATES):
        y = state * CELL
        first_frame = motion.crop((0, y, CELL, y + CELL))
        position = (state % COLUMNS * CELL, state // COLUMNS * CELL)
        rest.alpha_composite(first_frame, dest=position)
    rest.save(folder / "idle_support.png", optimize=True)


if __name__ == "__main__":
    for kind in KINDS:
        pack(kind)
