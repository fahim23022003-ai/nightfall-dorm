#!/usr/bin/env python3
"""Check sparse, native combat receipts for all 60 ordinary Hunter states."""

import argparse
from hashlib import sha256
import json
from pathlib import Path
import sys


HUNTERS = ("crusher", "stalker", "ravager", "witch", "electric", "storm")
DIRECTIONS = {"front", "back", "left", "right"}
POSES = {"hit", "windup", "contact", "follow", "recover"}
ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("receipts", type=Path, nargs="+")
    parser.add_argument("--quality", choices=["low", "medium", "high"], default="medium")
    parser.add_argument("--replace", type=Path, action="append", default=[], help="New receipt superseding existing state rows.")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    expected = {(hunter, level) for hunter in HUNTERS for level in range(1, 11)}
    issues = []
    states = {}
    hashes = {}
    sources = []
    superseded = []
    by_state = {}
    receipts = [(path, False) for path in args.receipts] + [(path, True) for path in args.replace]
    for path, replacement in receipts:
        receipt = json.loads(path.read_text(encoding="utf-8"))
        sources.append(
            {
                "file": path.name,
                "sha256": sha256(path.read_bytes()).hexdigest(),
                "replacement": replacement,
                "frames_rendered": receipt["frames_rendered"],
                "checks": receipt["checks"],
                "failures": receipt["failures"],
            }
        )
        if (
            receipt["viewport"] != [1280, 720]
            or receipt["quality"] != args.quality
            or receipt["display"].lower() == "headless"
            or receipt["failures"]
        ):
            issues.append(f"{path}: incorrect viewport, quality or failed renderer assertions")
        for state in receipt["states"]:
            key = (state["hunter"], state["level"])
            if state["failures"] or key not in expected:
                issues.append(f"{path}: failed or unexpected Hunter state {key}")
                continue
            prior = by_state.get(key)
            if replacement:
                if prior is None:
                    issues.append(f"{path}: replacement without a prior row for {key}")
                    continue
                superseded.append(
                    {"hunter": key[0], "level": key[1], "earlier_receipt": prior.name, "retake_receipt": path.name}
                )
            elif prior is not None:
                issues.append(f"{path}: duplicate Hunter state {key}")
                continue
            states[key] = state
            by_state[key] = path
    for key, state in states.items():
        if not POSES.issubset(state["poses"]) or not 0 <= state["contact_error_px"] <= 2 or not state["post_strike_pose"]:
            issues.append(f"{key}: incomplete combat poses or excessive socket error")
        if not state["turn_samples"]:
            issues.append(f"{key}: no authored turn samples")
        if state["door_damage"] <= 0 or state["needle_damage"] <= 0:
            issues.append(f"{key}: missing landed door or Needle damage")
        if set(state["directions"]) != DIRECTIONS or len(state["textures"]) != len(DIRECTIONS):
            issues.append(f"{key}: incomplete directional draw coverage")
        for direction, sample in state["directions"].items():
            texture = sample["path"]
            if sample["poses"] < 2 or texture not in state["textures"] or not texture.endswith(f"_{direction}.png"):
                issues.append(f"{key}: {direction} misses a distinct moving raster")
                continue
            asset = ROOT / texture.removeprefix("res://")
            if not asset.is_file():
                issues.append(f"{texture}: atlas source unavailable")
                continue
            digest = sha256(asset.read_bytes()).hexdigest()
            if sample.get("atlas_sha256", digest) != digest:
                issues.append(f"{texture}: atlas content changed since the recorded sample")
            if digest in hashes:
                issues.append(f"{texture}: identical atlas content to {hashes[digest]}")
            hashes[digest] = texture

    missing = sorted(expected - states.keys())
    if missing:
        issues.append(f"{len(missing)} ordinary Hunter states lack a native receipt")
    report = {
        "quality": args.quality,
        "states_expected": len(expected),
        "states_observed": len(states),
        "directional_atlases_observed": len(hashes),
        "rendered_frames": sum(row["frames_rendered"] for row in sources),
        "checks": sum(row["checks"] for row in sources),
        "maximum_contact_error_px": max((state["contact_error_px"] for state in states.values()), default=None),
        "minimum_relative_limb_motion_px": min((state["joint_range_px"] for state in states.values()), default=None),
        "missing": [{"hunter": hunter, "level": level} for hunter, level in missing],
        "sources": sources,
        "superseded_states": superseded,
        "issues": issues,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"ARTICULATION_RECEIPTS states={len(states)}/{len(expected)} views={len(hashes)} failures={len(issues)}")
    for issue in issues:
        print(issue, file=sys.stderr)
    return int(bool(issues))


if __name__ == "__main__":
    sys.exit(main())
