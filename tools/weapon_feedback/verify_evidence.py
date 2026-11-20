#!/usr/bin/env python3
"""Check the rendered shot trace and compare paired combat benchmark receipts."""

import argparse
import json
import math
from pathlib import Path


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def validate_clip(receipt: dict) -> None:
    assert receipt["failures"] == 0
    projectiles = {}
    settled = set()
    for event in receipt["trace"]:
        projectile = event["projectile_id"]
        if event["type"] == "launch":
            assert projectile not in projectiles
            projectiles[projectile] = event
        elif event["type"] in ("impact", "cancel"):
            assert projectile not in settled
            settled.add(projectile)
            launch = projectiles[projectile]
            for field in ("room", "building_id", "building_instance_id", "target_id", "kind", "level", "specialization", "origin"):
                assert event[field] == launch[field], (projectile, field)
            assert event["time"] >= launch["time"]
            if event["type"] == "cancel":
                assert event["damage"] == 0
        if event["type"] in ("impact", "burn", "reflect", "contact"):
            assert math.isclose(event["hp_before"] - event["hp_after"], event["damage"], abs_tol=1e-7)


def needle_trace(receipt: dict) -> dict:
    hit = next(event for event in receipt["trace"] if event["type"] == "impact" and event["damage"] > 0)
    launch = next(event for event in receipt["trace"] if event["type"] == "launch" and event["projectile_id"] == hit["projectile_id"])
    frames = receipt["flight_frames"][str(hit["projectile_id"])]
    assert len({frame["model"] for frame in frames}) >= 2
    assert frames[0]["visual"] == launch["visual_muzzle"]
    label = receipt["notes"]["damage_label"]
    assert label["raw_total"] == hit["damage"] and math.isclose(label["hunter_hp"], hit["hp_after"], abs_tol=1e-7)
    assert math.isclose(float(label["label"]), hit["damage"], abs_tol=.005)
    return {
        "source": {key: launch[key] for key in ("kind", "level", "specialization", "room", "building_id", "building_instance_id")},
        "projectile_id": hit["projectile_id"],
        "physical_origin": launch["origin"],
        "visible_muzzle": launch["visual_muzzle"],
        "launch_time": launch["time"],
        "target_id": hit["target_id"],
        "flight_frames": frames,
        "impact_time": hit["time"],
        "impact_point": hit["position"],
        "actual_damage": hit["damage"],
        "hp_before": hit["hp_before"],
        "hp_after": hit["hp_after"],
        "visible_label": label,
    }


def compare(path: Path) -> list[dict]:
    rows = []
    for density in (10, 24, 40, 60):
        for quality in ("medium", "low"):
            before, after = [read_json(path / f"final-bench-{density}-{quality}-{flag}" / "receipt.json") for flag in (0, 1)]
            assert before["weapon_feedback"] is False and after["weapon_feedback"] is True
            assert before["failures"] == after["failures"] == 0
            assert before["geometry_sha256"] == after["geometry_sha256"]
            assert before["gameplay_initial_sha256"] == after["gameplay_initial_sha256"]
            assert before["timing"]["gameplay_sha256"] == after["timing"]["gameplay_sha256"]
            rows.append({
                "buildings": density,
                "quality": quality,
                "renderer": after["renderer"],
                "matched_gameplay_sha256": after["timing"]["gameplay_sha256"],
                "shots": after["timing"]["shots"],
                "peak_concurrent_projectiles": after["timing"]["projectiles"]["max"],
                "before": metrics(before),
                "after": metrics(after),
            })
    return rows


def metrics(receipt: dict) -> dict:
    timing = receipt["timing"]
    return {key: timing[key] for key in ("frame_ms", "update_ms", "draw_calls")} | {
        key: receipt[key] for key in ("static_memory_bytes", "video_memory_bytes")
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run_directory", type=Path)
    parser.add_argument("output_directory", type=Path)
    args = parser.parse_args()
    args.output_directory.mkdir(parents=True, exist_ok=True)
    names = ("needle", "mixed", "shield", "cancel", "reaper", "ally", "dense-standard", "dense-low")
    clips = {name: read_json(args.run_directory / f"final-{name}" / "receipt.json") for name in names}
    for receipt in clips.values():
        validate_clip(receipt)
    for name, value in (("needle-shot.json", needle_trace(clips["needle"])), ("paired-performance.json", compare(args.run_directory))):
        (args.output_directory / name).write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
