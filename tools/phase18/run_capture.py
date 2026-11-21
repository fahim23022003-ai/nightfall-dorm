#!/usr/bin/env python3
"""Capture repeatable native Close Quarters stills, movies or dense measurements."""

import argparse
import os
from pathlib import Path
import re
import subprocess


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("scenario", choices=["views", "approach", "rush", "hall", "measure"])
    parser.add_argument("--version", choices=["2", "3"], required=True)
    parser.add_argument("--display", default=":89")
    parser.add_argument("--difficulty", default="hell", choices=["standard", "hard", "hell"])
    parser.add_argument("--theme", default="haunted_hospital")
    parser.add_argument("--seed", type=int, default=10358)
    parser.add_argument("--room", type=int, default=1, help="Zero-based room index")
    parser.add_argument("--height", default="720", choices=["540", "720"])
    parser.add_argument("--quality", default="medium", choices=["medium", "low"])
    parser.add_argument("--buildings", default="60", choices=["24", "40", "60"])
    parser.add_argument("--movie", action="store_true")
    args = parser.parse_args()

    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    env = os.environ | {
        "DISPLAY": args.display, "LIBGL_ALWAYS_SOFTWARE": "1", "LP_NUM_THREADS": "2",
        "XDG_DATA_HOME": str(output / "profile"),
        "NIGHTFALL_VISUAL_REBIRTH": "1", "NIGHTFALL_LIVING_NIGHTMARE": "1",
        "NIGHTFALL_SURVIVOR_REBIRTH": "1", "NIGHTFALL_PHASE16": "1", "NIGHTFALL_WEAPON_FEEDBACK": "1",
        "NIGHTFALL_FULL_ROOM_GRID": "1", "NIGHTFALL_PROCEDURAL_MAPS": "1", "NIGHTFALL_PROCEDURAL_MAPS_V2": "1",
        "NIGHTFALL_CLOSE_QUARTERS": "1" if args.version == "3" else "0",
    }
    width = "960" if args.height == "540" else "1280"
    command = [
        "godot", "--path", str(args.project.resolve()), "--display-driver", "x11",
        "--audio-driver", "Dummy", "--rendering-method", "gl_compatibility",
        "--resolution", f"{width}x{args.height}",
    ]
    if args.movie:
        if args.scenario in ["views", "measure"]:
            parser.error("--movie requires an active approach, rush or hall scenario")
        command += ["--write-movie", str(output / "gameplay.avi"), "--fixed-fps", "24"]
    if args.scenario == "measure":
        command += [
            "-s", "res://tools/phase18/measure_close_quarters.gd", "--",
            str(output), args.quality, args.buildings,
        ]
        receipt = "measure.json"
    else:
        command += [
            "-s", "res://tools/phase18/capture_close_quarters.gd", "--", str(output),
            args.scenario, args.difficulty, args.theme, str(args.seed), str(args.room), args.height,
        ]
        receipt = "capture.json"

    log_path = output / "run.log"
    with log_path.open("w") as log:
        process = subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=150)
    content = log_path.read_text()
    if process.returncode or not (output / receipt).is_file() or re.search(r"SCRIPT ERROR|Parse Error|ERROR:", content):
        raise SystemExit(f"Godot capture failed. See {log_path}")
    print(f"{args.version} {args.scenario} passed. Receipt: {output / receipt}", flush=True)


if __name__ == "__main__":
    main()
