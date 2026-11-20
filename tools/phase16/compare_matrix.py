#!/usr/bin/env python3
"""Compare matched dense fixture receipts and preserve raw evidence requirements."""
import argparse
import json
from pathlib import Path


def load_report(folder: Path) -> dict:
    record = json.loads((folder / "summary.json").read_text())
    if record["failures"]:
        raise ValueError(f"{folder} has failed scenes")
    return record


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("before", type=Path)
    parser.add_argument("after", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    original, candidate = load_report(args.before), load_report(args.after)
    for key in ("affinity_cpus", "llvmpipe_workers_override"):
        if original.get(key) != candidate.get(key):
            raise ValueError(f"The runs use different {key}.")
    before = {scene["scene"]: scene for scene in original["scenes"]}
    after = {scene["scene"]: scene for scene in candidate["scenes"]}
    if set(before) != set(after):
        raise ValueError("The scene matrices differ.")
    rows = []
    failed = False
    for name, initial in before.items():
        current = after[name]
        exact_geometry = initial["geometry_sha256"] == current["geometry_sha256"]
        exact_gameplay = all(initial[k] == current[k] for k in (
            "gameplay_initial_sha256", "gameplay_final_sha256",
        ))
        exact_pixels = all(initial[k] == current[k] for k in (
            "visual_initial_sha256", "visual_final_sha256",
        ))
        row = {
            "scene": name,
            "exact_geometry": exact_geometry,
            "exact_gameplay": exact_gameplay,
            "exact_pixels": exact_pixels,
        }
        for key in ("frame_ms", "update_ms", "draw_calls"):
            previous, next_value = initial[key], current[key]
            row[key] = {k: round(next_value[k] - previous[k], 3) for k in ("median", "p95", "max")}
            row[f"{key}_before"] = previous
            row[f"{key}_after"] = next_value
        rows.append(row)
        failed |= not (exact_geometry and exact_gameplay)
    args.output.write_text(json.dumps(rows, indent=2) + "\n")
    if failed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
