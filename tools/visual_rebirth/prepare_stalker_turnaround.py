"""Validate independent Stalker turnarounds and write a Godot preview manifest."""

import argparse
import hashlib
import itertools
import json
import math
import os
from pathlib import Path

from PIL import Image, ImageChops, ImageOps

VIEWS = {
    "front": ((0, -1), (0, 1)),
    "rear": ((0, 1), (0, -1)),
    # View labels name the camera side. The character's nose points
    # right in a view from its left, and left in a view from its right.
    "left": ((-1, 0), (1, 0)),
    "right": ((1, 0), (-1, 0)),
}
LANDMARKS = {
    "ground",
    "head",
    "mouth",
    "left_shoulder",
    "right_shoulder",
    "left_hand",
    "right_hand",
    "hem",
}
DISPLAY_WIDTH = 44
DISPLAY_HEIGHT = 104


def alpha_bounds(image):
    alpha = image.getchannel("A")
    bounds = alpha.point(lambda value: 255 if value >= 8 else 0).getbbox()
    if bounds is None or bounds[0] == 0 or bounds[1] == 0 or bounds[2] == image.width or bounds[3] == image.height:
        raise ValueError("Subject is empty or touches a texture edge")
    return bounds


def validate_camera(camera, expected_direction):
    if len(camera) != 3 or not all(math.isfinite(value) for value in camera):
        raise ValueError("Expected a finite camera vector relative to its look target")
    x, y, z = camera
    radius = math.hypot(x, y)
    if radius <= 0 or abs(x / radius - expected_direction[0]) > .01 or abs(y / radius - expected_direction[1]) > .01:
        raise ValueError(f"Camera {camera} does not project the expected orientation {expected_direction}")
    return math.degrees(math.atan2(z, radius))


def validate_landmarks(points):
    if set(points) != LANDMARKS:
        raise ValueError(f"Landmarks must be {', '.join(sorted(LANDMARKS))}")
    for name, coordinates in points.items():
        if len(coordinates) != 2 or not all(math.isfinite(value) and 0 < value < 1 for value in coordinates):
            raise ValueError(f"{name} must have finite top-left normalized UV coordinates")
    if not points["head"][1] < min(points["hem"][1], points["ground"][1]):
        raise ValueError("The head must project above the hem and ground")


def prepare(source_path, output_path):
    source_manifest = json.loads(source_path.read_text())
    if source_manifest.get("projection") != "Orthographic" or set(source_manifest["views"]) != set(VIEWS):
        raise ValueError("Expected an orthographic manifest with front, rear, left and right views")
    views = {}
    silhouettes = {}
    elevations = []
    resolution = None
    for name, (camera_direction, forward) in VIEWS.items():
        source = source_manifest["views"][name]
        image_path = source_path.parent / source["file"]
        if image_path.parent.resolve() != source_path.parent.resolve():
            raise ValueError(f"{name} image must be in the manifest directory")
        if image_path.suffix != ".png":
            raise ValueError(f"Expected a PNG for {name}")
        with Image.open(image_path) as image:
            if image.format != "PNG" or image.mode != "RGBA":
                raise ValueError(f"{name} must be an RGBA PNG")
            if resolution is not None and resolution != image.size:
                raise ValueError("Use one canvas size for all views")
            resolution = image.size
            bounds = alpha_bounds(image)
            silhouettes[name] = image.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
        elevations.append(validate_camera(source["camera"], camera_direction))
        validate_landmarks(source["sockets"])
        views[name] = {
            "image": os.path.relpath(image_path, output_path.parent),
            "sha256": hashlib.sha256(image_path.read_bytes()).hexdigest(),
            "alpha_bounds": bounds,
            "landmarks": source["sockets"],
            "screen_forward": forward,
        }
    if len({view["sha256"] for view in views.values()}) != len(VIEWS):
        raise ValueError("Every orientation requires a different RGBA image")
    if max(elevations) - min(elevations) > .25 or abs(elevations[0] - 42) > 1:
        raise ValueError("Use a consistent orthographic elevation near 42 degrees")

    subject_width = max(x1 - x0 for x0, _, x1, _ in (view["alpha_bounds"] for view in views.values()))
    subject_height = max(y1 - y0 for _, y0, _, y1 in (view["alpha_bounds"] for view in views.values()))
    scale_y = DISPLAY_HEIGHT / subject_height
    scale_x = min(scale_y, DISPLAY_WIDTH / subject_width)
    intersections = {}
    for left, right in itertools.combinations(views, 2):
        left_mask = silhouettes[left]
        right_mask = silhouettes[right]
        intersection = ImageChops.multiply(left_mask, right_mask).histogram()[255]
        union = ImageChops.lighter(left_mask, right_mask).histogram()[255]
        intersections[f"{left}-{right}"] = round(intersection / max(1, union), 4)
    mirrored_overlap = ImageChops.difference(ImageOps.mirror(silhouettes["left"]), silhouettes["right"]).histogram()[255]
    if mirrored_overlap == 0:
        raise ValueError("Side silhouettes are exact mirrors; check projections and identity asymmetry")
    output_path.write_text(json.dumps({
        "schema_version": 1,
        "source_canvas": resolution,
        "display_scale": [scale_x, scale_y],
        "max_body_extent": [round(subject_width * scale_x, 3), DISPLAY_HEIGHT],
        "camera_elevation_degrees": round(sum(elevations) / len(elevations), 3),
        "silhouette_IoU": intersections,
        "mirrored_silhouette_difference_pixels": mirrored_overlap,
        "views": views,
    }, indent=2) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source_manifest", type=Path)
    parser.add_argument("output_manifest", type=Path)
    arguments = parser.parse_args()
    prepare(arguments.source_manifest, arguments.output_manifest)


if __name__ == "__main__":
    main()
