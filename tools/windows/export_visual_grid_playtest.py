#!/usr/bin/env python3
"""Export, verify, and package the private Phase 14 visual / grid Windows build."""

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


PREVIEW_PROFILE = "user://phase14-full-room-grid-playtest.json"
REFERENCE_PROFILE = "user://phase14-windows-playtest.json"


def launcher(mode: int, profile: str) -> bytes:
    return "\r\n".join([
        "@echo off",
        "setlocal",
        'cd /d "%~dp0"',
        f'set "NIGHTFALL_VISUAL_REBIRTH={mode}"',
        f'set "NIGHTFALL_FULL_ROOM_GRID={mode}"',
        f'set "NIGHTFALL_PROFILE_PATH={profile}"',
        '"%~dp0NightfallDorm.exe"',
        "exit /b %errorlevel%",
        "",
    ]).encode("ascii")


def verify_modes(godot: str, executable: Path, working: Path, evidence: Path) -> None:
    empty = working / "empty"
    empty.mkdir()
    for mode, profile, label in [
        (1, PREVIEW_PROFILE, "visual-grid-preview"),
        (0, REFERENCE_PROFILE, "reference-visuals"),
    ]:
        env = os.environ.copy()
        env.update(
            XDG_DATA_HOME=str(working / ("data-" + label)),
            NIGHTFALL_VISUAL_REBIRTH=str(mode),
            NIGHTFALL_FULL_ROOM_GRID=str(mode),
            NIGHTFALL_PROFILE_PATH=profile,
        )
        log = evidence / f"windows-pack-{label}.log"
        run([
            godot, "--headless", "--quit-after", "1200", "--path", str(empty), "--main-pack", str(executable),
            "--script", str(ROOT / "tools/windows/verify_full_visual_pack.gd"),
        ], log, env)
        report = log.read_text()
        if "FULL_VISUAL_WINDOWS_PACK_CHECKS=" not in report or "FAILURES=0" not in report:
            raise RuntimeError(f"Combined smoke did not complete; inspect {log}")


def add_playtest_files(base: Path, output: Path) -> None:
    with ZipFile(base) as source, ZipFile(output, "w", ZIP_DEFLATED) as target:
        for entry in source.infolist():
            with source.open(entry) as body, target.open(entry, "w") as copy:
                shutil.copyfileobj(body, copy)
        target.writestr("Play Visual Preview.cmd", launcher(1, PREVIEW_PROFILE))
        target.writestr("Play Reference Visuals.cmd", launcher(0, REFERENCE_PROFILE))
        checklist = ROOT / "docs/PHASE_14_FULL_ROOM_GRID_WINDOWS_CHECKLIST.md"
        target.write(checklist, "PHASE_14_FULL_ROOM_GRID_WINDOWS_CHECKLIST.md")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--zip", required=True, type=Path)
    parser.add_argument("--evidence-dir", required=True, type=Path)
    args = parser.parse_args()
    branch = subprocess.check_output(["git", "branch", "--show-current"], cwd=ROOT, text=True).strip()
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    expected = subprocess.check_output(
        ["git", "rev-parse", "--verify", args.source_commit + "^{commit}"], cwd=ROOT, text=True
    ).strip()
    if branch != "work" or commit != expected:
        raise RuntimeError("The verified source commit must be checked out on branch work.")
    archive = args.zip.resolve()
    evidence = args.evidence_dir.resolve()
    archive.parent.mkdir(parents=True, exist_ok=True)
    evidence.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="nightfall-playtest-", dir=archive.parent) as scratch:
        working = Path(scratch)
        base = working / "base.zip"
        subprocess.run([
            sys.executable, str(ROOT / "tools/windows/export_release.py"),
            "--godot", args.godot, "--zip", str(base), "--evidence-dir", str(evidence),
        ], cwd=ROOT, env=os.environ | {
            "NIGHTFALL_VISUAL_REBIRTH": "0", "NIGHTFALL_FULL_ROOM_GRID": "0",
        }, check=True)
        with ZipFile(base) as exported:
            executable = Path(exported.extract("NightfallDorm.exe", working))
        verify_modes(args.godot, executable, working, evidence)

        receipt_path = evidence / "windows-artifact.json"
        receipt = json.loads(receipt_path.read_text())
        if receipt["source_commit"] != commit:
            raise RuntimeError("The export record does not match the selected source.")
        combined = working / "combined.zip"
        add_playtest_files(base, combined)
        with ZipFile(combined) as final:
            bad_entry = final.testzip()
            if bad_entry is not None:
                raise RuntimeError(f"Package CRC failed for {bad_entry}")
            with final.open("NightfallDorm.exe") as packaged_exe:
                if hashlib.file_digest(packaged_exe, "sha256").hexdigest() != receipt["executable_sha256"]:
                    raise RuntimeError("The packaged executable does not match the verified export.")
        with combined.open("rb") as file:
            checksum = hashlib.file_digest(file, "sha256").hexdigest()
        combined.replace(archive)
        receipt.update(
            archive=str(archive), archive_bytes=archive.stat().st_size, archive_sha256=checksum,
            preview_profile=PREVIEW_PROFILE, reference_profile=REFERENCE_PROFILE,
            preview_environment={"NIGHTFALL_VISUAL_REBIRTH": "1", "NIGHTFALL_FULL_ROOM_GRID": "1"},
            reference_environment={"NIGHTFALL_VISUAL_REBIRTH": "0", "NIGHTFALL_FULL_ROOM_GRID": "0"},
        )
        receipt_path.write_text(json.dumps(receipt, indent=2) + "\n")
        print(json.dumps(receipt, indent=2))


if __name__ == "__main__":
    main()
