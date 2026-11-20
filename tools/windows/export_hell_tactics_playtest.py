#!/usr/bin/env python3
"""Export an isolated Windows Hell tactics playtest and verify the embedded pack."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from zipfile import ZIP_DEFLATED, ZipFile

sys.dont_write_bytecode = True
from export_release import ROOT, run


MODE_SWITCHES = (
    "NIGHTFALL_VISUAL_REBIRTH",
    "NIGHTFALL_FULL_ROOM_GRID",
    "NIGHTFALL_PROCEDURAL_MAPS",
    "NIGHTFALL_PROCEDURAL_MAPS_V2",
)
MODES = {
    "hell-preview": (
        "Play Hell Tactics Preview.cmd", "user://nightfall-v21-playtest.json", (1, 1, 0, 1),
    ),
    "v1-fallback": (
        "Play Procedural V1 Fallback.cmd", "user://nightfall-v21-v1-playtest.json", (1, 1, 1, 0),
    ),
    "fixed-reference": (
        "Play Fixed Reference.cmd", "user://nightfall-v21-fixed-reference.json", (0, 0, 0, 0),
    ),
}


def mode_environment(profile: str, switches: tuple[int, ...]) -> dict[str, str]:
    settings = {key: str(value) for key, value in zip(MODE_SWITCHES, switches, strict=True)}
    return {"NIGHTFALL_PROFILE_PATH": profile, **settings}


def launcher(environment: dict[str, str]) -> bytes:
    return "\r\n".join([
        "@echo off",
        "setlocal",
        'cd /d "%~dp0"',
        *(f'set "{key}={value}"' for key, value in environment.items()),
        '"%~dp0NightfallDorm.exe"',
        "exit /b %errorlevel%",
        "",
    ]).encode("ascii")


def verify_modes(
    godot: str,
    executable: Path,
    working: Path,
    evidence: Path,
) -> dict[str, dict[str, str]]:
    empty = working / "empty"
    empty.mkdir()
    environments = {}
    for label, (_, profile, switches) in MODES.items():
        environment = mode_environment(profile, switches)
        environments[label] = environment
        env = os.environ | environment | {"XDG_DATA_HOME": str(working / ("data-" + label))}
        log = evidence / f"windows-pack-{label}.log"
        run([
            godot, "--headless", "--quit-after", "1200", "--path", str(empty), "--main-pack", str(executable),
            "--script", str(ROOT / "tools/windows/verify_hell_tactics_pack.gd"),
        ], log, env)
        if "HELL_TACTICS_WINDOWS_PACK_CHECKS=" not in log.read_text() or "FAILURES=0" not in log.read_text():
            raise RuntimeError(f"Tactics pack verification did not complete. Inspect {log}.")

    # Exercise the exact Phase 14F assets and reach the original construction
    # comparison fixture without replacing its room layout with either preview.
    for visual in ("0", "1"):
        env = os.environ | {
            "XDG_DATA_HOME": str(working / ("art-data-" + visual)),
            "NIGHTFALL_PROFILE_PATH": "user://nightfall-v21-pack-art.json",
            **dict.fromkeys(MODE_SWITCHES, "0"),
            "NIGHTFALL_VISUAL_REBIRTH": visual,
            "NIGHTFALL_FULL_ROOM_GRID": visual,
        }
        log = evidence / f"windows-pack-phase14f-{visual}.log"
        run([
            godot, "--headless", "--quit-after", "1200", "--path", str(empty), "--main-pack", str(executable),
            "--script", str(ROOT / "tools/windows/verify_full_visual_pack.gd"),
        ], log, env)
        if "FULL_VISUAL_WINDOWS_PACK_CHECKS=" not in log.read_text() or "FAILURES=0" not in log.read_text():
            raise RuntimeError(f"Phase 14F pack verification did not complete. Inspect {log}.")
    return environments


def add_playtest_files(base: Path, output: Path, environments: dict[str, dict[str, str]]) -> None:
    with ZipFile(base) as source, ZipFile(output, "w", ZIP_DEFLATED) as target:
        for entry in source.infolist():
            with source.open(entry) as body, target.open(entry, "w") as copy:
                shutil.copyfileobj(body, copy)
        for label, (name, _, _) in MODES.items():
            target.writestr(name, launcher(environments[label]))
        guide = ROOT / "docs/HELL_TACTICS_WINDOWS_PLAYTEST.md"
        target.write(guide, guide.name)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--zip", required=True, type=Path)
    parser.add_argument("--evidence-dir", required=True, type=Path)
    args = parser.parse_args()
    branch = subprocess.check_output(["git", "branch", "--show-current"], cwd=ROOT, text=True).strip()
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    source = subprocess.check_output(
        ["git", "rev-parse", "--verify", args.source_commit + "^{commit}"], cwd=ROOT, text=True,
    ).strip()
    if branch != "work" or commit != source:
        raise RuntimeError("Check out the verified source commit on branch work before exporting.")
    archive = args.zip.resolve()
    evidence = args.evidence_dir.resolve()
    archive.parent.mkdir(parents=True, exist_ok=True)
    evidence.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="nightfall-v21-", dir=archive.parent) as scratch:
        working = Path(scratch)
        base = working / "base.zip"
        subprocess.run([
            sys.executable, str(ROOT / "tools/windows/export_release.py"),
            "--godot", args.godot, "--zip", str(base), "--evidence-dir", str(evidence),
        ], cwd=ROOT, env=os.environ | dict.fromkeys(MODE_SWITCHES, "0"), check=True)
        with ZipFile(base) as exported:
            executable = Path(exported.extract("NightfallDorm.exe", working))
        environments = verify_modes(args.godot, executable, working, evidence)

        receipt_path = evidence / "windows-artifact.json"
        receipt = json.loads(receipt_path.read_text())
        if receipt["source_commit"] != source:
            raise RuntimeError("The export receipt points to a different source commit.")
        combined = working / "playtest.zip"
        add_playtest_files(base, combined, environments)
        with ZipFile(combined) as packaged:
            bad_entry = packaged.testzip()
            if bad_entry is not None:
                raise RuntimeError(f"Package CRC failed for {bad_entry}")
            with packaged.open("NightfallDorm.exe") as packaged_executable:
                if hashlib.file_digest(packaged_executable, "sha256").hexdigest() != receipt["executable_sha256"]:
                    raise RuntimeError("The package does not contain the verified executable.")
        with combined.open("rb") as file:
            checksum = hashlib.file_digest(file, "sha256").hexdigest()
        combined.replace(archive)
        receipt.update(
            archive=archive.name,
            archive_bytes=archive.stat().st_size,
            archive_sha256=checksum,
            launcher_environments=environments,
        )
        receipt_path.write_text(json.dumps(receipt, indent=2) + "\n")
        print(json.dumps(receipt, indent=2))


if __name__ == "__main__":
    main()
