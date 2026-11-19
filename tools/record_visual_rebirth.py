#!/usr/bin/env python3
"""Record matched Godot viewports with an existing X11 display."""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time


ROOT = Path(__file__).resolve().parents[1]
MODE_SCALE = {"before": "0", "pilot": "1"}
STILLS = (
    "full16-720.png",
    "full16-1080.png",
    "stalker-crop.png",
    "needle-crop.png",
    "combat-last-720.png",
)


def capture(mode, directory, timeout_seconds):
    target = directory / mode
    target.mkdir()
    environment = os.environ.copy()
    environment["NIGHTFALL_VISUAL_REBIRTH"] = MODE_SCALE[mode]
    environment["XDG_DATA_HOME"] = str(target / "user-data")
    environment["XDG_CONFIG_HOME"] = str(target / "user-config")
    environment["XDG_CACHE_HOME"] = str(target / "user-cache")
    command = [
        "godot", "--path", str(ROOT), "--resolution", "1280x720",
        "--audio-driver", "Dummy", "--script", "res://tools/capture_visual_rebirth.gd",
        "--", str(target),
    ]
    started = time.monotonic()
    result = subprocess.run(
        command, env=environment, text=True, capture_output=True, timeout=timeout_seconds
    )
    elapsed = time.monotonic() - started
    log = result.stdout + result.stderr
    (target / "engine.log").write_text(log)
    if result.returncode or any(marker in log for marker in ("SCRIPT ERROR:", "ERROR:")):
        raise RuntimeError(f"{mode} capture failed. See {target / 'engine.log'}")
    metadata = json.loads((target / "capture.json").read_text())
    if metadata["failures"]:
        raise RuntimeError(f"{mode} reported failed checks. See {target / 'capture.json'}")
    metadata["capture_wall_seconds"] = elapsed
    metadata["renderer"] = next((line for line in log.splitlines() if "Using Device" in line), "")
    return metadata


def encode(directory, target):
    filter_graph = (
        "[0:v]scale=960:540,pad=960:578:0:38:black,"
        "drawtext=text='PHASE 13 PRESENTATION':x=16:y=8:fontsize=20:fontcolor=white[a];"
        "[1:v]scale=960:540,pad=960:578:0:38:black,"
        "drawtext=text='PHASE 14 PILOT':x=16:y=8:fontsize=20:fontcolor=white[b];"
        "[a][b]hstack=inputs=2"
    )
    subprocess.run(
        [
            "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
            "-framerate", "24", "-i", str(directory / "before/frames/%04d.png"),
            "-framerate", "24", "-i", str(directory / "pilot/frames/%04d.png"),
            "-filter_complex_threads", "1", "-filter_complex", filter_graph,
            "-c:v", "libx264", "-threads", "2", "-crf", "18", "-pix_fmt", "yuv420p",
            "-movflags", "+faststart", str(target),
        ],
        check=True,
    )


def run(args):
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="nightfall-visual-rebirth-") as scratch:
        directory = Path(scratch)
        try:
            rows = {mode: capture(mode, directory, args.timeout) for mode in MODE_SCALE}
            if rows["before"]["combat"] != rows["pilot"]["combat"]:
                raise RuntimeError("Fallback and pilot combat snapshots differ")
            if rows["before"]["events"] != rows["pilot"]["events"]:
                raise RuntimeError("Fallback and pilot combat event counts differ")
            encode(directory, output / "combat-comparison.mp4")
            subprocess.run(
                ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
                 "-i", str(directory / "pilot/master-unsynced.wav"),
                 "-c:a", "flac", str(output / "pilot-master-unsynced.flac")],
                check=True,
            )
            for mode in MODE_SCALE:
                for name in STILLS:
                    shutil.copyfile(directory / mode / name, output / f"{mode}-{name}")
        finally:
            for mode in MODE_SCALE:
                log = directory / mode / "engine.log"
                if log.is_file():
                    shutil.copyfile(log, output / f"{mode}-engine.log")
        rows["conditions"] = (
            "Same Godot executable and driver, fallback then pilot in fresh processes. "
            "Prepared legacy Endless seed 67, frozen full16 timing sample, separate staged "
            "room 4 approach with ordinary model ticks at fixed 1/24 second. A fixture-only "
            "door placement on frame 24 may occur if pathfinding has yet to reach it. "
            "Frames are captured directly from the game viewport. Video shows fallback "
            "on the left and pilot on the right, without audio. The separate Master "
            "recording follows actual mixer wall time and is not synchronized."
        )
        (output / "comparison.json").write_text(json.dumps(rows, indent=2) + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("--timeout", type=float, default=180, help="seconds per Godot run")
    args = parser.parse_args()
    if not os.environ.get("DISPLAY"):
        parser.error("DISPLAY must identify a running X11 display")
    run(args)


if __name__ == "__main__":
    main()
