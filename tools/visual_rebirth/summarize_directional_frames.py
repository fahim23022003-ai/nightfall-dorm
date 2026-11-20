#!/usr/bin/env python3
"""Summarize matched Godot frame-time traces and validate the staged route."""

import argparse
import json
import math
import statistics
from pathlib import Path


def stats(frames):
    times = sorted(frame["frame_ms"] for frame in frames)
    return {
        "frames": len(times),
        "median_ms": round(statistics.median(times), 3),
        "p95_ms": times[math.ceil(0.95 * len(times)) - 1],
        "p99_ms": times[math.ceil(0.99 * len(times)) - 1],
        "max_ms": times[-1],
        "frames_over_33_3_ms": sum(time > 33.3 for time in times),
    }


def summarize(case):
    frames = case["frame_times"]
    first_pass = [frame for frame in frames if frame["pass"] == 0]
    warmed = [frame for frame in frames if frame["pass"] > 0]
    return {
        "all_frames": stats(frames),
        "all_turn_windows": stats([frame for frame in frames if frame["is_turn"]]),
        "first_route_turn_windows": stats([frame for frame in first_pass if frame["is_turn"]]),
        "warmed_turn_windows": stats([frame for frame in warmed if frame["is_turn"]]),
        "steady_frames": stats([frame for frame in frames if not frame["is_turn"]]),
        "bound_texture_change_frames": stats([frame for frame in frames[1:] if frame["texture_changed"]]),
        "observed_mesh_instances": case.get("observed_mesh_instances"),
        "observed_texture_names": sorted({frame["texture"] for frame in frames}),
        "estimated_render_memory_bytes": case["estimated_render_memory_bytes"],
        "model_hashes": case["pass_model_hashes"],
        "checks": case["checks"],
        "failures": case["failures"],
    }


def frame_sequence(case):
    return [
        (frame["pass"], frame["leg"], frame["step"], frame["heading"], frame["is_turn"])
        for frame in case["frame_times"]
    ]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkpoint_standard", type=Path)
    parser.add_argument("checkpoint_low", type=Path)
    parser.add_argument("final_standard", type=Path)
    parser.add_argument("final_low", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    traces = {
        name: json.loads(getattr(args, name).read_text())
        for name in ("checkpoint_standard", "checkpoint_low", "final_standard", "final_low")
    }
    reference = traces["checkpoint_standard"]
    if any(
        entry["failures"]
        or entry["pass_model_hashes"] != reference["pass_model_hashes"]
        or frame_sequence(entry) != frame_sequence(reference)
        for entry in traces.values()
    ):
        parser.error("Frame routes, model states or Godot checks failed parity.")
    for name, entry in traces.items():
        expected = "medium" if name.endswith("_standard") else "low"
        if entry["quality"] != expected:
            parser.error(f"{name} used {entry['quality']} instead of {expected}.")
    summary = {name: summarize(entry) for name, entry in traces.items()}
    args.output.write_text(json.dumps(summary, indent=2) + "\n")


if __name__ == "__main__":
    main()
