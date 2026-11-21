#!/usr/bin/env python3
"""Export an isolated Windows Campaign playtest and verify the embedded pack."""

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

FAIR_START_MODES = {
    "fair-start-preview": (
        "Play Fair Starting Rooms Preview.cmd", "user://nightfall-v23-playtest.json", (1, 1, 0, 1),
    ),
    "v1-fallback": (
        "Play Procedural V1 Fallback.cmd", "user://nightfall-v23-v1-playtest.json", (1, 1, 1, 0),
    ),
    "fixed-reference": (
        "Play Fixed Reference.cmd", "user://nightfall-v23-fixed-reference.json", (0, 0, 0, 0),
    ),
}

LIVING_NIGHTMARE_MODES = {
    "living-nightmare": (
        "Play Living Nightmare Preview.cmd", "user://nightfall-living-nightmare-preview.json", (1, 1, 0, 1),
    ),
    **{label: mode for label, mode in FAIR_START_MODES.items() if label != "fair-start-preview"},
    "fair-start-preview": FAIR_START_MODES["fair-start-preview"],
}

SURVIVOR_REBIRTH_MODES = {
    "survivor-rebirth": (
        "Play Nightmare Lobby Preview.cmd", "user://nightfall-living-nightmare-preview.json", (1, 1, 0, 1),
    ),
    **LIVING_NIGHTMARE_MODES,
}
PHASE16_MODES = {
    "phase16": (
        "Play Phase 16 Preview.cmd", "user://nightfall-living-nightmare-preview.json", (1, 1, 0, 1),
    ),
    **SURVIVOR_REBIRTH_MODES,
}
WEAPON_FEEDBACK_MODES = {
    "weapon-feedback": (
        "Play Weapon Feedback Preview.cmd", "user://nightfall-living-nightmare-preview.json", (1, 1, 0, 1),
    ),
    **PHASE16_MODES,
}
CLOSE_QUARTERS_MODES = {
    "close-quarters": (
        "Play Close Quarters Preview.cmd", "user://nightfall-living-nightmare-preview.json", (1, 1, 0, 1),
    ),
    **WEAPON_FEEDBACK_MODES,
}
BUILDING_SCALE_MODES = {
    "building-scale": (
        "Play Building Scale Preview.cmd", "user://nightfall-building-scale-preview.json", (1, 1, 0, 1),
    ),
    **CLOSE_QUARTERS_MODES,
}


def mode_environment(profile: str, switches: tuple[int, ...], living: bool = False,
                     survivor: bool = False, phase16: bool = False, weapons: bool = False,
                     close_quarters: bool = False, building_scale: bool = False) -> dict[str, str]:
    settings = {key: str(value) for key, value in zip(MODE_SWITCHES, switches, strict=True)}
    return {"NIGHTFALL_PROFILE_PATH": profile, "NIGHTFALL_LIVING_NIGHTMARE": str(int(living)),
            "NIGHTFALL_SURVIVOR_REBIRTH": str(int(survivor)), "NIGHTFALL_PHASE16": str(int(phase16)),
            "NIGHTFALL_WEAPON_FEEDBACK": str(int(weapons)),
            "NIGHTFALL_CLOSE_QUARTERS": str(int(close_quarters)),
            "NIGHTFALL_BUILDING_SCALE": str(int(building_scale)), **settings}


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
    modes: dict,
) -> dict[str, dict[str, str]]:
    empty = working / "empty"
    empty.mkdir()
    environments = {}
    for label, (_, profile, switches) in modes.items():
        close = label in ("close-quarters", "building-scale")
        phase16 = close or label in ("phase16", "weapon-feedback")
        environment = mode_environment(profile, switches, phase16 or label in ("living-nightmare", "survivor-rebirth"),
                                       phase16 or label == "survivor-rebirth", phase16,
                                       close or label == "weapon-feedback", close, label == "building-scale")
        environments[label] = environment
        env = os.environ | environment | {"XDG_DATA_HOME": str(working / ("data-" + label))}
        log = evidence / f"windows-pack-{label}.log"
        run([
            godot, "--headless", "--quit-after", "1200", "--path", str(empty), "--main-pack", str(executable),
            "--script", str(ROOT / "tools/windows/verify_hell_tactics_pack.gd"),
        ], log, env)
        if "HELL_TACTICS_WINDOWS_PACK_CHECKS=" not in log.read_text() or "FAILURES=0" not in log.read_text():
            raise RuntimeError(f"Tactics pack verification did not complete. Inspect {log}.")

    if modes is FAIR_START_MODES or "living-nightmare" in modes:
        log = evidence / "windows-pack-fair-start-probe.log"
        env = os.environ | environments["fair-start-preview"] | {
            "XDG_DATA_HOME": str(working / "data-fair-start-probe"),
            "NIGHTFALL_CHECK_FAIR_START": "1",
        }
        run([
            godot, "--headless", "--quit-after", "1200", "--path", str(empty), "--main-pack", str(executable),
            "--script", str(ROOT / "tools/windows/verify_hell_tactics_pack.gd"),
        ], log, env)
        if "FAIR_START_PACK_CHECKED=true" not in log.read_text() or "FAILURES=0" not in log.read_text():
            raise RuntimeError(f"Fair start pack verification did not complete. Inspect {log}.")

    if "living-nightmare" in modes:
        env = os.environ | environments["living-nightmare"] | {"XDG_DATA_HOME": str(working / "living-package-data")}
        log = evidence / "windows-pack-living-nightmare-story.log"
        run([
            godot, "--headless", "--quit-after", "1200", "--path", str(empty), "--main-pack", str(executable),
            "--script", str(ROOT / "tools/windows/verify_living_nightmare_pack.gd"),
        ], log, env)
        if "LIVING_NIGHTMARE_PACK_CHECKS=" not in log.read_text() or "FAILURES=0" not in log.read_text():
            raise RuntimeError(f"Living Nightmare pack verification did not complete. Inspect {log}.")
    if "survivor-rebirth" in modes:
        for label in (name for name in ("survivor-rebirth", "phase16", "close-quarters", "building-scale") if name in modes):
            env = os.environ | environments[label] | {"XDG_DATA_HOME": str(working / ("lobby-data-" + label))}
            log = evidence / f"windows-pack-{label}-lobby.log"
            run([
                godot, "--headless", "--quit-after", "1200", "--path", str(empty), "--main-pack", str(executable),
                "--script", str(ROOT / "tools/windows/verify_survivor_rebirth_pack.gd"),
            ], log, env)
            if "SURVIVOR_REBIRTH_PACK_CHECKS=" not in log.read_text() or "FAILURES=0" not in log.read_text():
                raise RuntimeError(f"Story lobby pack verification did not complete. Inspect {log}.")

    if "weapon-feedback" in modes:
        env = os.environ | environments["weapon-feedback"] | {"XDG_DATA_HOME": str(working / "weapon-feedback-data")}
        log = evidence / "windows-pack-weapon-feedback-shot.log"
        run([
            godot, "--headless", "--quit-after", "1200", "--path", str(empty), "--main-pack", str(executable),
            "--script", str(ROOT / "tools/windows/verify_weapon_feedback_pack.gd"),
        ], log, env)
        if "WEAPON_FEEDBACK_PACK_CHECKS=" not in log.read_text() or "FAILURES=0" not in log.read_text():
            raise RuntimeError(f"Weapon feedback pack verification did not complete. Inspect {log}.")

    # Exercise the exact Phase 14F assets and reach the original construction
    # comparison fixture without replacing its room layout with either preview.
    for visual in ("0", "1"):
        env = os.environ | {
            "XDG_DATA_HOME": str(working / ("art-data-" + visual)),
            "NIGHTFALL_PROFILE_PATH": "user://nightfall-v21-pack-art.json",
            **dict.fromkeys(MODE_SWITCHES, "0"),
            "NIGHTFALL_LIVING_NIGHTMARE": "0",
            "NIGHTFALL_WEAPON_FEEDBACK": "0",
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


def add_playtest_files(
    base: Path, output: Path, environments: dict[str, dict[str, str]], modes: dict, guide: Path,
) -> None:
    with ZipFile(base) as source, ZipFile(output, "w", ZIP_DEFLATED) as target:
        for entry in source.infolist():
            with source.open(entry) as body, target.open(entry, "w") as copy:
                shutil.copyfileobj(body, copy)
        for label, (name, _, _) in modes.items():
            target.writestr(name, launcher(environments[label]))
        target.write(guide, guide.name)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    preview = parser.add_mutually_exclusive_group()
    preview.add_argument("--fair-start", action="store_true", help="Use the V2.3 guide and isolated profiles.")
    preview.add_argument("--living-nightmare", action="store_true", help="Use the Living Nightmare guide and isolated profiles.")
    preview.add_argument("--survivor-rebirth", action="store_true", help="Add the offline Story lobby and Room Rush preview.")
    preview.add_argument("--phase16", action="store_true", help="Include the Phase 16 preview and prior launchers.")
    preview.add_argument("--weapon-feedback", action="store_true", help="Enable weapon feedback with the Phase 16 preview and prior launchers.")
    preview.add_argument("--close-quarters", action="store_true", help="Add Close Quarters with prior launchers.")
    preview.add_argument("--building-scale", action="store_true", help="Add Building Scale with a separate profile and prior launchers.")
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
    modes = MODES
    guide_name = "HELL_TACTICS_WINDOWS_PLAYTEST.md"
    if args.fair_start:
        modes = FAIR_START_MODES
        guide_name = "FAIR_START_WINDOWS_PLAYTEST.md"
    elif args.living_nightmare:
        modes = LIVING_NIGHTMARE_MODES
        guide_name = "LIVING_NIGHTMARE_WINDOWS_PLAYTEST.md"
    elif args.survivor_rebirth:
        modes = SURVIVOR_REBIRTH_MODES
        guide_name = "SURVIVOR_REBIRTH_WINDOWS_PLAYTEST.md"
    elif args.phase16:
        modes = PHASE16_MODES
        guide_name = "PHASE16_WINDOWS_PLAYTEST.md"
    elif args.weapon_feedback:
        modes = WEAPON_FEEDBACK_MODES
        guide_name = "WEAPON_FEEDBACK_WINDOWS_PLAYTEST.md"
    elif args.close_quarters:
        modes = CLOSE_QUARTERS_MODES
        guide_name = "CLOSE_QUARTERS.md"
    elif args.building_scale:
        modes = BUILDING_SCALE_MODES
        guide_name = "BUILDING_SCALE.md"
    guide = ROOT / "docs" / guide_name
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
        ], cwd=ROOT, env=os.environ | dict.fromkeys(MODE_SWITCHES, "0"), check=True)
        with ZipFile(base) as exported:
            executable = Path(exported.extract("NightfallDorm.exe", working))
        environments = verify_modes(args.godot, executable, working, evidence, modes)

        receipt_path = evidence / "windows-artifact.json"
        receipt = json.loads(receipt_path.read_text())
        if receipt["source_commit"] != source:
            raise RuntimeError("The export receipt points to a different source commit.")
        combined = working / "playtest.zip"
        add_playtest_files(base, combined, environments, modes, guide)
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
