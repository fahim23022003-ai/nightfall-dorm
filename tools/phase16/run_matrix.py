#!/usr/bin/env python3
"""Run Phase 16 benchmarks in fresh isolated profiles, one viewport at a time."""

import argparse
import itertools
import json
import os
from pathlib import Path
import re
import subprocess


def source_revision(project: Path) -> str:
    marker = project / "source-sha.txt"
    if marker.is_file():
        return marker.read_text().strip()
    return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=project, text=True).strip()


def measure(args, project: Path, folder: Path, quality: str, density: int, encounter: str, enabled: str) -> dict:
    folder.mkdir(parents=True, exist_ok=False)
    env = os.environ | {
        "DISPLAY": args.display,
        "LIBGL_ALWAYS_SOFTWARE": "1",
        "NIGHTFALL_PHASE16": enabled,
        "NIGHTFALL_VISUAL_REBIRTH": "1",
        "NIGHTFALL_LIVING_NIGHTMARE": "1",
        "NIGHTFALL_SURVIVOR_REBIRTH": "1",
        "NIGHTFALL_FULL_ROOM_GRID": "1",
        "NIGHTFALL_PROCEDURAL_MAPS": "1",
        "NIGHTFALL_PROCEDURAL_MAPS_V2": "1",
        "XDG_DATA_HOME": str(folder / "profile"),
    }
    command = [
        args.godot, "--path", str(project), "--display-driver", "x11", "--audio-driver", "Dummy",
        "--rendering-method", "gl_compatibility", "--resolution", "1280x720",
        "--script", "res://tools/phase16/measure_dense_active.gd", "--",
        str(folder), quality, str(density), encounter,
    ]
    log = folder / "run.log"
    with log.open("w") as file:
        status = subprocess.run(command, env=env, stdout=file, stderr=subprocess.STDOUT, timeout=90)
    receipt = folder / "benchmark.json"
    if status.returncode or not receipt.is_file() or re.search(r"SCRIPT ERROR|Parse Error|ERROR:", log.read_text()):
        raise RuntimeError("Godot failed or reported errors")
    data = json.loads(receipt.read_text())
    if data["failures"] != 0:
        raise RuntimeError("benchmark assertions failed")
    return {
        "scene": folder.name,
        "checks": data["checks"],
        "frame_ms": data["timing"]["frame_ms"],
        "update_ms": data["timing"]["update_ms"],
        "draw_calls": data["timing"]["draw_calls"],
        "geometry_sha256": data["geometry_sha256"],
        "gameplay_initial_sha256": data["gameplay_initial_sha256"],
        "gameplay_final_sha256": data["timing"]["gameplay_sha256"],
        "visual_initial_sha256": data["visual_initial_sha256"],
        "visual_final_sha256": data["visual_final_sha256"],
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--reference-project", type=Path, help="Interleave reference and candidate scenes")
    parser.add_argument("--display", required=True)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--quality", nargs="+", choices=("medium", "low"), default=("medium", "low"))
    parser.add_argument("--density", nargs="+", type=int, choices=(24, 40, 60), default=(24, 40, 60))
    parser.add_argument("--encounter", nargs="+", choices=("stalker", "reaper"), default=("stalker", "reaper"))
    args = parser.parse_args()

    project, output = args.project.resolve(), args.output.resolve()
    variants = [(project, output, os.environ.get("NIGHTFALL_PHASE16", "0"))]
    if args.reference_project:
        variants = [(args.reference_project.resolve(), output / "before", "0"), (project, output / "after", "1")]
    runs = {}
    for directory, folder, enabled in variants:
        runs[folder] = {
            "source_revision": source_revision(directory),
            "phase16_enabled": enabled == "1",
            "affinity_cpus": sorted(os.sched_getaffinity(0)),
            "llvmpipe_workers_override": os.environ.get("LP_NUM_THREADS"),
            "scenes": [],
            "failures": [],
        }
    for sequence, (encounter, density, quality) in enumerate(itertools.product(args.encounter, args.density, args.quality)):
        label = f"{encounter}-{density}-{quality}"
        order = variants[::-1] if sequence % 2 else variants
        for directory, folder, enabled in order:
            record = runs[folder]
            scenario = folder / label
            try:
                result = measure(args, directory, scenario, quality, density, encounter, enabled)
                record["scenes"].append(result)
                print(f"{folder.name} {label} {result['frame_ms']}", flush=True)
            except (RuntimeError, subprocess.TimeoutExpired) as error:
                record["failures"].append({"scene": label, "error": str(error)})
                print(f"{folder.name} {label} failed: {error}. See {scenario / 'run.log'}", flush=True)
            (folder / "summary.json").write_text(json.dumps(record, indent=2) + "\n")
    if any(record["failures"] for record in runs.values()):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
