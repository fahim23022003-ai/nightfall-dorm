"""Build an unscaled comparison from the recorded Godot telegraph frames."""

import argparse
import io
import json
from pathlib import Path
import subprocess

from PIL import Image, ImageDraw, ImageFont


HUNTERS = {
    "crusher": "Crusher",
    "stalker": "Stalker",
    "ravager": "Ravager",
    "witch": "Phantom Witch",
    "electric": "Electric Ghost",
    "storm": "Storm Wraith",
}
CROP = (404, 160, 672, 332)
LEVELS = (1, 4, 7, 10)


def load_frame(video: Path, frame: int) -> Image.Image:
    data = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", str(video), "-vf", f"select=eq(n\\,{frame})",
         "-frames:v", "1", "-f", "image2pipe", "-vcodec", "png", "pipe:1"],
        check=True, capture_output=True,
    ).stdout
    image = Image.open(io.BytesIO(data)).convert("RGB")
    if image.size != (1280, 720):
        raise ValueError(f"Expected 1280×720 recorded viewport for {video}")
    return image


def compose(directory: Path) -> None:
    cell_width = CROP[2] - CROP[0]
    cell_height = CROP[3] - CROP[1]
    gap = 8
    header_width = 137
    header_height = 52
    plate = Image.new(
        "RGB",
        (header_width + gap + len(LEVELS) * (cell_width + gap),
         header_height + len(HUNTERS) * (cell_height + gap)),
        "#111821",
    )
    text = ImageDraw.Draw(plate)
    title_font = ImageFont.load_default(size=20)
    label_font = ImageFont.load_default(size=16)
    text.text((gap, gap), "Hunter evolution during attack telegraphs", font=title_font, fill="#f1eadb")
    for column, level in enumerate(LEVELS):
        x = header_width + column * (cell_width + gap)
        text.text((x + gap, 32), f"Level {level}", font=label_font, fill="#c7d8db")
    for row, (archetype, name) in enumerate(HUNTERS.items()):
        y = header_height + row * (cell_height + gap)
        text.text((gap, y + 76), name, font=label_font, fill="#f1eadb")
        metadata = json.loads((directory / f"{archetype}-anchors.json").read_text())
        chapters = metadata["segments"]
        if tuple(chapter["level"] for chapter in chapters) != LEVELS:
            raise ValueError(f"Unexpected chapter order for {archetype}")
        first_frame = 0
        for column, chapter in enumerate(chapters):
            events = chapter["events"]
            telegraph_frame = (events["ordinary_warning"] + events["door_strike"]) // 2
            frame = load_frame(directory / f"{archetype}-anchors.mp4", first_frame + telegraph_frame)
            x = header_width + column * (cell_width + gap)
            plate.paste(frame.crop(CROP), (x, y))
            first_frame += chapter["frame_count"]
    plate.save(directory / "hunter-telegraph-gallery-720.png")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("capture_directory", type=Path)
    compose(parser.parse_args().capture_directory)
