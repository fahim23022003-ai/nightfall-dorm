#!/usr/bin/env python3
"""Run one serial, matched, actual-Godot comparison with both pilots enabled."""

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import platform
import re
import shutil
import sys
import tempfile


CAPTURE_SCRIPT = "tools/capture_visual_rebirth.gd"
PROOF_FILES = ("engine.log", "full16-720.png", "full16-1080.png", "combat-last-720.png")
PARITY_FIELDS = ("combat", "events", "staging")


def import_existing_runner(project):
    sys.dont_write_bytecode = True
    spec = importlib.util.spec_from_file_location(
        "nightfall_visual_rebirth_capture", project / "tools/record_visual_rebirth.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def digest(file):
    return hashlib.sha256(file.read_bytes()).hexdigest()


def cpu():
    host = Path("/proc/cpuinfo")
    if host.is_file():
        match = re.search(r"^model name\s*:\s*(.*)", host.read_text(), re.MULTILINE)
        if match:
            return match[1]
    return platform.processor()


def run(args):
    projects = {"before": args.baseline.resolve(), "after": args.candidate.resolve()}
    if args.reverse:
        projects = dict(reversed(list(projects.items())))
    fixture_hashes = {mode: digest(project / CAPTURE_SCRIPT) for mode, project in projects.items()}
    if len(set(fixture_hashes.values())) != 1:
        raise RuntimeError("The viewport fixture differs between the two projects")
    runner = import_existing_runner(projects["after"])
    runner.MODE_SCALE = {mode: "1" for mode in projects}
    args.output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="nightfall-enabled-pilots-") as temporary:
        capture_directory = Path(temporary)
        results = {}
        try:
            for mode, project in projects.items():
                runner.ROOT = project
                results[mode] = runner.capture(mode, capture_directory, args.timeout)
                if results[mode]["settings"]["baseline"]:
                    raise RuntimeError(f"{mode} unexpectedly used fallback visuals")
            for key in PARITY_FIELDS:
                if results["before"][key] != results["after"][key]:
                    raise RuntimeError(f"The matched viewports produced different {key}")
            for mode in projects:
                for file in PROOF_FILES[1:]:
                    shutil.copyfile(capture_directory / mode / file, args.output / f"{mode}-{file}")
        finally:
            for mode in projects:
                log = capture_directory / mode / "engine.log"
                if log.exists():
                    shutil.copyfile(log, args.output / f"{mode}-engine.log")
    result = {
        "baseline_commit": args.baseline_commit,
        "candidate_commit": args.candidate_commit,
        "fixture_sha256": fixture_hashes["before"],
        "capture_order": list(projects),
        "test_cpu": cpu(),
        "operating_system": platform.platform(),
        "conditions": (
            "Same Godot 4.6.3 binary, X11 display and software OpenGL driver. "
            "Both builds use the opt-in visual pilot, medium quality, fresh isolated profiles, "
            "and a prepared seed-67 legacy Endless fixture. Baseline was exported with git archive. "
            "Thirty warmup and 240 timed frames of the frozen full 16-slot 1280x720 view per build. "
            "One serial pair. Native Windows and Intel UHD performance remain unverified."
        ),
        **results,
    }
    (args.output / "comparison.json").write_text(json.dumps(result, indent=2) + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("baseline", type=Path)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--baseline-commit", required=True)
    parser.add_argument("--candidate-commit", required=True)
    parser.add_argument("--timeout", type=float, default=180)
    parser.add_argument("--reverse", action="store_true")
    run(parser.parse_args())


if __name__ == "__main__":
    main()
