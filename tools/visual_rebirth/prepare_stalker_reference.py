"""Rebuild the pilot texture from the canonical Stalker L1 concept."""

import argparse
from pathlib import Path

from PIL import Image


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reference", type=Path, help="Extracted 02_Stalker_L1.png")
    parser.add_argument("output", type=Path, help="Destination PNG")
    args = parser.parse_args()

    with Image.open(args.reference) as reference:
        if reference.format != "PNG" or reference.mode != "RGBA" or reference.size != (1024, 1536):
            raise ValueError("Expected the original 1024 × 1536 RGBA Stalker reference")
        framed = reference.crop((231, 0, 759, 1536))
        args.output.parent.mkdir(parents=True, exist_ok=True)
        framed.resize((264, 768), Image.Resampling.LANCZOS).save(args.output, optimize=True)


if __name__ == "__main__":
    main()
