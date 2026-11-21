#!/usr/bin/env python3
"""Measure V3's old rules before and after the corridor rendering cache."""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess


def measure(project: Path, folder: Path, density: int, quality: str, display: str) -> dict:
    folder.mkdir(parents=True, exist_ok=False)
    env = os.environ | {
        "DISPLAY": display, "LIBGL_ALWAYS_SOFTWARE": "1", "LP_NUM_THREADS": "2",
        "XDG_DATA_HOME": str(folder / "profile"),
        "NIGHTFALL_CLOSE_QUARTERS": "1", "NIGHTFALL_BUILDING_SCALE": "0",
        "NIGHTFALL_VISUAL_REBIRTH": "1", "NIGHTFALL_LIVING_NIGHTMARE": "1",
        "NIGHTFALL_SURVIVOR_REBIRTH": "1", "NIGHTFALL_PHASE16": "1",
        "NIGHTFALL_WEAPON_FEEDBACK": "1", "NIGHTFALL_FULL_ROOM_GRID": "1",
        "NIGHTFALL_PROCEDURAL_MAPS": "1", "NIGHTFALL_PROCEDURAL_MAPS_V2": "1",
    }
    command = [
        "godot", "--path", str(project), "--display-driver", "x11",
        "--audio-driver", "Dummy", "--rendering-method", "gl_compatibility",
        "--resolution", "1280x720", "-s", "res://tools/phase181/measure_equal_workload.gd",
        "--", str(folder), quality, str(density),
    ]
    log = folder / "run.log"
    with log.open("w") as file:
        result = subprocess.run(command, env=env, stdout=file, stderr=subprocess.STDOUT, timeout=90)
    receipt = folder / "measure.json"
    if result.returncode or not receipt.is_file() or re.search(r"SCRIPT ERROR|Parse Error|ERROR:", log.read_text()):
        raise RuntimeError(f"Benchmark failed. See {log}")
    data = json.loads(receipt.read_text())
    if data["failures"] or "close_passages" not in data["combat"]["spans_ms"] or data["buildings"] != density:
        raise RuntimeError(f"Incomplete benchmark. See {receipt}")
    return data


def compare(reference: dict, candidate: dict) -> dict:
    original = reference["combat"]
    optimized = candidate["combat"]
    checks = {
        "layout": reference["geometry_sha256"] == candidate["geometry_sha256"],
        "initial_gameplay": reference["gameplay_initial_sha256"] == candidate["gameplay_initial_sha256"],
        "final_gameplay": original["gameplay_sha256"] == optimized["gameplay_sha256"],
        "camera": reference["camera_scale_end"] == candidate["camera_scale_end"],
        "visible_buildings": all(
            record[key] == reference["buildings"]
            for record in (reference, candidate)
            for key in ("visible_buildings_at_start", "visible_buildings_at_end")
        ),
        "combat_work": all(
            original[key] == optimized[key]
            for key in ("sample_frames", "warmup_frames", "shots", "strikes", "door_hp_delta", "hunter_hp_delta")
        ),
    }
    if not all(checks.values()):
        raise RuntimeError(f"Non-matching workload: {checks}")
    row = {"buildings": reference["buildings"], "quality": reference["quality"], "matching": checks}
    for label, record in [("before", reference), ("after", candidate)]:
        battle = record["combat"]
        row[label] = {
            "frame_ms": battle["frame_ms"], "draw_calls": battle["draw_calls"],
            "corridor_cpu_ms": battle["spans_ms"]["close_passages"],
            "first_view_frame_ms": record["first_view_frame_ms"], "memory": record["memory"],
            "route_query_ms":record["navigation"]["route_query_ms"],
        }
    return row


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reference", type=Path)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--display", default=":84")
    args = parser.parse_args()
    roots = [args.reference.resolve(), args.candidate.resolve()]
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    cases = []
    metadata = {
        "source_markers": [(root / "source-sha.txt").read_text().strip() for root in roots],
        "affinity": sorted(os.sched_getaffinity(0)),
        "llvmpipe_workers": 2,
        "cases": cases,
    }
    fixtures = [(n, quality) for n in (60, 24, 40) for quality in ("medium", "low")]
    for index, (density, quality) in enumerate(fixtures):
        pair = {}
        for version in reversed(range(2)) if index % 2 else range(2):
            label = ("before", "after")[version]
            path = output / f"{label}-{density}-{quality}"
            pair[version] = measure(roots[version], path, density, quality, args.display)
        row = compare(pair[0], pair[1])
        cases.append(row)
        (output / "paired.json").write_text(json.dumps(metadata,indent=2) + "\n")
        print(density, quality, "wall", row["before"]["frame_ms"], "→", row["after"]["frame_ms"],
              "median corridor CPU", row["before"]["corridor_cpu_ms"]["median"], "→", row["after"]["corridor_cpu_ms"]["median"], flush=True)


if __name__ == "__main__":
    main()
