#!/usr/bin/env python3
"""Bake hand-traced joint layers from approved cardinal Hunter art.

Recipes trace the arm or leg silhouette in source pixels and specify bone pivots
and overlapping cover. Cloak underlays are rebuilt from neighboring garment
texels so moving limbs don't reveal a second painted hand.
"""
from pathlib import Path
import json

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy.ndimage import distance_transform_edt

from articulated_anchor_traces import STROKED_TRACE, TRACE


ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets/visual_rebirth"
DEST = ASSETS / "articulated"
ATLAS_WIDTH = 512


def limb(polygon, shoulder, elbow, wrist, fingertips, cover=None):
    return {"polygon": polygon, "bones": [shoulder, elbow, wrist, fingertips], "cover": cover}


def recipe(pivot, head, hem, near=None, far=None, leg=None, other_leg=None):
    segments = {"near": near, "far": far, "foot": leg, "far_foot": other_leg}
    return {"pivot": pivot, "head": head, "hem": hem,
            "chains": {name: chain for name, chain in segments.items() if chain is not None}}


# Head is an occlusion boundary rather than a cross-cut of the whole body.
# Hem starts behind intact cloth in neutral pose. Mesh segments share elbow
# texels over a short overlap to hide creases, including at maximum extension.
RECIPES = {
    "stalker": {
        "left": recipe(
            (108, 260), (97, 47, 102, 41, 62, 118), (126, 169),
            limb([(98,47),(110,46),(119,50),(124,65),(119,87),(118,107),(111,124),(102,142),(102,153),(96,164),(81,164),(79,153),(85,142),(99,113),(99,96),(102,78),(94,64)],
                 (106,58),(109,105),(92,143),(86,156),[(89,96),(110,76),(134,75),(143,166),(85,173)]),
            limb([(84,80),(95,86),(96,112),(91,127),(88,143),(82,161),(75,162),(72,152),(77,141),(81,122),(81,103)],
                 (89,90),(87,117),(80,143),(78,155),[(88,86),(111,81),(116,160),(84,169)]),
        ),
        "right": recipe(
            (108,260), (133,46,126,43,69,162), (93,169),
            limb([(103,76),(115,77),(119,97),(120,110),(126,127),(133,150),(132,166),(121,168),(117,158),(118,147),(110,135),(103,121),(98,96)],
                 (107,83),(111,118),(122,145),(126,157),[(72,79),(126,77),(125,168),(73,171)]),
            limb([(123,84),(137,88),(138,107),(140,120),(149,143),(148,153),(138,157),(135,143),(131,126),(123,112)],
                 (131,91),(132,117),(142,137),(145,148),[(104,84),(135,81),(136,162),(103,166)]),
        ),
        "front": recipe(
            (108,260), (101,45,106,48,61,116), (111,173),
            limb([(117,45),(130,42),(143,47),(147,59),(143,81),(143,101),(141,124),(134,146),(135,158),(130,168),(119,168),(115,156),(121,145),(124,124),(125,104),(125,84),(121,69),(115,58)],
                 (129,55),(133,110),(126,143),(122,159),[(113,59),(136,58),(138,172),(110,173)]),
            limb([(77,86),(90,86),(91,108),(92,134),(97,149),(102,162),(99,170),(89,168),(84,158),(84,148),(78,127),(77,110)],
                 (83,92),(84,121),(90,145),(94,159),[(83,82),(107,85),(110,173),(77,173)]),
        ),
        "back": recipe(
            (108,260), (112,51,111,51,76,161), (108,174),
            limb([(78,37),(89,39),(92,51),(88,69),(86,91),(87,118),(81,131),(78,147),(74,150),(69,142),(72,123),(76,105),(77,83),(74,67),(76,54)],
                 (83,47),(81,96),(76,132),(73,143),[(82,43),(107,58),(104,153),(75,161)]),
            limb([(134,86),(142,90),(143,116),(145,126),(145,143),(141,150),(136,147),(136,127),(132,114)],
                 (137,92),(138,118),(141,135),(140,146),[(115,85),(138,84),(140,154),(118,156)]),
        ),
    },
    "ravager": {
        "left": recipe(
            (164,260), (103,99,95,102,45,119), (203,182),
            limb([(113,84),(132,76),(153,89),(159,108),(153,126),(159,155),(149,180),(130,202),(111,225),(97,236),(93,250),(73,258),(59,257),(58,248),(53,251),(35,258),(27,253),(32,243),(59,232),(74,224),(87,206),(106,179),(122,157),(128,147),(116,138),(118,120),(110,101)],
                 (131,102),(137,158),(93,230),(43,247),[(112,82),(189,80),(188,196),(140,214),(108,200)]),
            limb([(94,105),(103,109),(120,131),(122,154),(131,187),(133,209),(148,216),(155,228),(143,231),(129,224),(110,232),(100,229),(108,216),(110,199),(105,172),(100,138)],
                 (102,118),(118,177),(121,213),(146,225),[(102,108),(148,120),(147,224),(105,222)]),
            limb([(152,133),(182,135),(211,157),(217,178),(211,199),(218,224),(221,240),(218,253),(195,260),(150,259),(143,255),(146,248),(171,240),(189,234),(197,229),(186,202),(165,188)],
                 (184,161),(191,195),(207,234),(148,253),[(149,130),(229,151),(217,204),(191,228),(161,217),(146,184)]),
        ),
        "right": recipe(
            (164,260), (258,101,245,101,226,303), (150,182),
            limb([(212,98),(229,94),(245,101),(247,116),(239,136),(227,152),(238,174),(249,191),(261,211),(276,231),(288,232),(299,240),(308,252),(307,257),(300,259),(286,252),(277,245),(279,257),(268,258),(256,248),(248,234),(234,213),(208,184),(191,163),(188,150),(190,139),(192,120)],
                 (225,112),(200,157),(262,231),(300,251),[(175,92),(237,88),(245,169),(234,203),(213,196),(173,178)]),
            limb([(205,125),(224,128),(228,146),(220,184),(222,209),(229,226),(242,231),(240,237),(215,237),(200,232),(192,219),(199,204),(200,167)],
                 (217,136),(210,179),(208,222),(235,233),[(183,120),(242,128),(234,222),(191,223)]),
            limb([(133,145),(158,144),(194,171),(198,189),(178,205),(154,218),(143,229),(150,240),(169,246),(170,252),(139,254),(126,251),(116,238),(112,227),(118,219),(142,205),(155,191)],
                 (166,166),(145,197),(131,232),(164,248),[(128,144),(188,150),(207,198),(151,222),(124,213)]),
        ),
        "front": recipe(
            (164,260), (159,112,156,103,123,192), (167,173),
            limb([(192,94),(211,99),(221,118),(218,141),(209,166),(207,188),(210,216),(222,230),(236,238),(236,251),(212,259),(195,258),(183,251),(181,239),(190,228),(185,213),(185,188),(183,170),(189,138),(185,115)],
                 (204,107),(198,167),(196,227),(220,250),[(181,95),(238,93),(229,216),(188,226)]),
            limb([(116,98),(131,98),(140,108),(136,124),(119,133),(103,142),(97,159),(99,185),(98,216),(112,230),(116,245),(111,259),(85,260),(64,254),(64,242),(75,231),(79,217),(78,182),(76,156),(84,135),(101,122)],
                 (123,119),(87,155),(88,225),(76,252),[(105,102),(146,106),(145,175),(102,220),(91,219)]),
            limb([(224,127),(251,128),(267,140),(275,152),(272,179),(257,205),(253,218),(260,226),(274,230),(274,243),(244,244),(220,237),(216,228),(219,217),(229,201),(229,184),(222,160)],
                 (245,151),(246,188),(235,225),(267,237),[(207,124),(268,120),(280,185),(248,222),(219,218)]),
        ),
        "back": recipe(
            (164,260), (181,90,171,91,142,213), (177,174),
            limb([(183,95),(213,98),(234,112),(246,131),(263,143),(267,154),(267,176),(260,194),(256,217),(274,225),(280,232),(275,240),(263,237),(252,232),(230,236),(224,231),(233,221),(237,206),(239,179),(240,157),(230,145),(216,139),(204,127),(184,119)],
                 (209,115),(251,157),(248,222),(269,231),[(185,94),(237,95),(251,143),(258,211),(231,219),(188,199)]),
            None,
            limb([(151,152),(177,156),(193,173),(204,197),(201,214),(197,229),(202,244),(222,252),(222,259),(199,260),(181,252),(180,238),(183,219),(181,205),(171,201),(147,187)],
                 (173,170),(191,209),(190,240),(216,254),[(149,150),(203,156),(207,213),(177,224),(144,200)]),
        ),
    },
    "reaper_approach": {},
    "reaper_transformed": {},
}

REAPER_CHAINS = {
    "approach": {
        "left": ([(99,47),(113,44),(130,49),(139,62),(139,81),(130,95),(117,119),(114,132),(105,148),(95,148),(93,139),(99,123),(100,112),(108,92),(103,76)],
                 (121,57),(123,97),(108,120),(101,137)),
        "right": ([(100,50),(113,46),(128,47),(134,58),(130,73),(133,91),(143,103),(152,120),(153,137),(143,144),(134,131),(130,119),(119,108),(108,95),(100,76)],
                  (115,58),(124,95),(137,110),(145,127)),
        "front": ([(130,48),(143,48),(152,62),(155,77),(157,93),(171,105),(174,118),(173,141),(169,148),(160,149),(157,136),(159,124),(151,111),(141,102),(133,87),(129,68)],
                  (141,58),(148,97),(165,117),(166,135)),
        "back": ([(134,45),(149,48),(157,62),(153,81),(166,96),(176,110),(175,125),(173,141),(165,143),(158,131),(157,118),(150,106),(140,95),(136,80),(134,62)],
                 (146,61),(154,97),(168,117),(169,133)),
    },
    "transformed": {
        "left": ([(100,49),(117,43),(135,52),(143,68),(143,82),(133,103),(120,115),(114,130),(99,141),(93,138),(92,128),(100,117),(103,104),(111,87),(100,73)],
                 (121,60),(124,102),(108,119),(100,130)),
        "right": ([(102,48),(117,46),(130,51),(138,68),(136,83),(140,100),(150,112),(154,128),(147,139),(139,131),(132,117),(120,107),(109,97),(107,81),(100,67)],
                  (121,60),(127,100),(137,113),(145,127)),
        "front": ([(140,51),(155,56),(164,71),(160,91),(168,102),(176,113),(176,137),(171,143),(165,144),(160,132),(159,119),(151,110),(145,98),(141,84),(139,68)],
                  (151,65),(157,105),(165,119),(167,134)),
    },
}

for form, directions in REAPER_CHAINS.items():
    for direction, (shape, shoulder, elbow, wrist, fingers) in directions.items():
        cover = [(71, 42), (153, 46), (174, 107), (180, 163), (83, 165)]
        facing_x = {"left": 111, "front": 120, "right": 128, "back": 105}[direction]
        RECIPES[f"reaper_{form}"][direction] = recipe(
            (112, 260), (facing_x, 57, 122, 52, 72, 164), (117, 164),
            limb(shape, shoulder, elbow, wrist, fingers, cover),
        )
RECIPES["reaper_transformed"]["back"] = recipe((112,260), (109,56,106,51,64,147), (112,166))


def make_outline(points, widths):
    joints = np.asarray(points, dtype=float)
    axes = np.diff(joints, axis=0)
    axes /= np.linalg.norm(axes, axis=1)[:, None]
    before, middle, after = axes
    normals = np.array([before, before + middle, middle + after, after])
    normals = np.column_stack((-normals[:, 1], normals[:, 0]))
    normals *= (np.asarray(widths) / np.linalg.norm(normals, axis=1))[:, None]
    joints[0] -= before * 6
    joints[-1] += after * 4
    return [(round(x), round(y)) for x, y in np.concatenate((joints + normals, (joints - normals)[::-1]))]


for hunter, views in STROKED_TRACE.items():
    TRACE[hunter] = {
        view: (pivot, head, hem, {part: (make_outline(joints, widths), joints)
                                  for part, (joints, widths) in paths.items()})
        for view, (pivot, head, hem, paths) in views.items()
    }

for hunter, views in TRACE.items():
    RECIPES[hunter] = {}
    for view, (pivot, head, hem, paths) in views.items():
        data = recipe(pivot, head, hem)
        for name, (outline, points) in paths.items():
            x, y = points[0]
            join = [(x-15,y-9),(x+15,y-9),(x+15,y+15),(x-15,y+15)] if not name.endswith("foot") else None
            data["chains"][name] = limb(outline, *points, join)
        RECIPES[hunter][view] = data


def polygon_mask(size, polygon):
    scale = 3
    mask = Image.new("L", (size[0] * scale, size[1] * scale))
    ImageDraw.Draw(mask).polygon([(x * scale, y * scale) for x, y in polygon], fill=255)
    return np.array(mask.resize(size, Image.Resampling.LANCZOS), dtype=np.float32) / 255


def cut(image, mask):
    result = image.copy()
    result[..., 3] = np.rint(image[..., 3] * np.clip(mask, 0, 1)).astype(np.uint8)
    return Image.fromarray(result, "RGBA")


def soft_step(v, start, end):
    blend = np.clip((v - start) / (end - start), 0, 1)
    return blend * blend * (3 - 2 * blend)


def joint_split(x, y, pivot, left, right, width):
    before = np.asarray(pivot) - np.asarray(left)
    after = np.asarray(right) - np.asarray(pivot)
    axis = before / np.linalg.norm(before) + after / np.linalg.norm(after)
    axis /= np.linalg.norm(axis)
    projection = (x - pivot[0]) * axis[0] + (y - pivot[1]) * axis[1]
    return soft_step(projection, -width, width)


def rebuild_underlay(source, erase, cover):
    destination = source.copy()
    hidden = erase > .05
    valid = (source[..., 3] > 210) & ~hidden
    donor_rows, donor_cols = distance_transform_edt(~valid, return_distances=False, return_indices=True)
    replaced = source[donor_rows, donor_cols].copy()
    replaced[..., :3] = np.asarray(Image.fromarray(replaced[..., :3]).filter(ImageFilter.GaussianBlur(.9)))
    strength = np.asarray(erase, dtype=np.float32)[..., None]
    destination[..., :3] = np.rint(source[..., :3] * (1 - strength) + replaced[..., :3] * strength).astype(np.uint8)
    destination[..., 3] = np.rint(source[..., 3] * (1 - erase * (1 - cover))).astype(np.uint8)
    return destination


def layers_for(image, data):
    source = np.asarray(image.convert("RGBA"))
    y, x = np.mgrid[:image.height, :image.width]
    erase = np.zeros(source.shape[:2], dtype=np.float32)
    cover = erase.copy()
    layers = {}
    # Near silhouettes win shared pixels. Far shapes keep their own alpha.
    for name, chain in data["chains"].items():
        shape = polygon_mask(image.size, chain["polygon"])
        selected = shape * (1 - erase)
        erase = np.maximum(erase, shape)
        if chain["cover"]:
            cover = np.maximum(cover, shape * polygon_mask(image.size, chain["cover"]))
        shoulder, elbow, wrist, fingers = chain["bones"]
        lower = joint_split(x, y, elbow, shoulder, wrist, 6)
        hand = joint_split(x, y, wrist, elbow, fingers, 4)
        layers[f"{name}_upper"] = cut(source, selected * (1 - .98 * lower))
        layers[f"{name}_lower"] = cut(source, selected * lower * (1 - .97 * hand))
        layers[f"{name}_end"] = cut(source, selected * lower * hand)
    base = rebuild_underlay(source, erase, cover)
    x0, y0, neck_x, neck_y, left, right = data["head"]
    hood = (1 - soft_step(y, neck_y - 5, neck_y + 9)) * soft_step(x, left - 7, left + 2) * (1 - soft_step(x, right - 2, right + 7))
    tail = soft_step(y, data["hem"][1] - 12, data["hem"][1] + 21)
    layers["hem"] = cut(base, tail)
    layers["torso"] = cut(base, (1 - hood) * (1 - tail * .97))
    layers["head"] = cut(base, hood)
    metadata = {"pivot": data["pivot"], "neck": (x0, y0), "hem": data["hem"],
                "chains": {name: chain["bones"] for name, chain in data["chains"].items()}}
    return layers, metadata


def pack(layers):
    atlas = Image.new("RGBA", (ATLAS_WIDTH, 1024))
    x, y, row_height = 2, 2, 0
    regions = {}
    for name, image in layers.items():
        bounds = image.getbbox()
        if bounds is None:
            continue
        tile = image.crop(bounds)
        if tile.width + x + 2 > atlas.width:
            x, y, row_height = 2, y + row_height + 4, 0
        if y + tile.height > atlas.height:
            raise ValueError("Layer atlas exceeds 512 × 1024")
        atlas.paste(tile, (x, y))
        regions[name] = ([x, y, tile.width, tile.height], [bounds[0], bounds[1]])
        x += tile.width + 4
        row_height = max(row_height, tile.height)
    return atlas.crop((0, 0, ATLAS_WIDTH, y + row_height + 2)), regions


def main():
    DEST.mkdir(exist_ok=True)
    catalog = {}
    for hunter, views in RECIPES.items():
        for view, recipe_data in views.items():
            if hunter.startswith("reaper_"):
                source = ASSETS / "grim_reaper" / f"{hunter.removeprefix('reaper_')}_{view}.png"
            else:
                family, _, level = hunter.partition("_l")
                source = ASSETS / family / f"level_{level or '01'}_{view}.png"
            with Image.open(source) as image:
                layers, rig = layers_for(image, recipe_data)
            if hunter == "reaper_transformed" and view == "back":
                # The approved back painting occludes the weapon arm. Reuse
                # the model's own right-facing sleeve/gauntlet underneath
                # the rear mantle as it appears during a committed swing.
                dx, dy = 24, -6
                donor = RECIPES[hunter]["right"]
                with Image.open(source.with_name("transformed_right.png")) as image:
                    donor_layers, donor_rig = layers_for(image, donor)
                    for part in ("upper", "lower", "end"):
                        key = f"near_{part}"
                        layer = Image.new("RGBA", image.size)
                        layer.paste(donor_layers[key], (dx, dy))
                        layers[key] = layer
                rig["chains"]["near"] = [(x + dx, y + dy) for x, y in donor_rig["chains"]["near"]]
            atlas, rig["regions"] = pack(layers)
            name = f"{hunter}_{view}"
            atlas.save(DEST / f"{name}.png", optimize=True)
            catalog[name] = rig
    manifest = ROOT / "scripts" / "articulated_hunter_atlas.gd"
    manifest.write_text("extends RefCounted\n## Generated by tools/visual_rebirth/bake_articulated_hunters.py.\n\nconst POSES := "
                        + json.dumps(catalog, separators=(",", ":")) + "\n")


if __name__ == "__main__":
    main()
