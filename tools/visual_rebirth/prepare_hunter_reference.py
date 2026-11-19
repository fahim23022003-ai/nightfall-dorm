"""Convert an original transparent Hunter reference to the gameplay canvas."""

import argparse
from pathlib import Path

from PIL import Image


# Image dimensions and the midpoint of the two boot centers in source pixels.
REFERENCES = {
    "crusher": ((1173, 1341), 554),
    "electric": ((1024, 1536), 470),
    "storm": ((1024, 1536), 388),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reference", type=Path, help="Extracted canonical PNG")
    parser.add_argument("--hunter", choices=REFERENCES, default="crusher")
    parser.add_argument("output", type=Path, help="Destination PNG")
    arguments = parser.parse_args()
    with Image.open(arguments.reference) as source:
        dimensions, foot_x = REFERENCES[arguments.hunter]
        if source.mode != "RGBA" or source.size != dimensions:
            raise ValueError(f"Expected the original {arguments.hunter} RGBA reference")
        visible = source.getchannel("A").point(lambda value: 255 if value >= 26 else 0)
        bounds = visible.getbbox()
        sprite = source.crop(bounds)
        scale = 256 / sprite.height
        sprite = sprite.resize((round(sprite.width * scale), 256), Image.Resampling.LANCZOS)
        sheet = Image.new("RGBA", (328, 264))
        sheet.alpha_composite(sprite, (164 - round((foot_x - bounds[0]) * scale), 4))
        arguments.output.parent.mkdir(parents=True, exist_ok=True)
        sheet.save(arguments.output, optimize=True)


if __name__ == "__main__":
    main()
