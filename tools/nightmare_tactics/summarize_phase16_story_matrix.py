"""Summarize the paired Phase 16 complete-match receipts."""
import argparse
from collections import Counter, defaultdict
import json
from pathlib import Path
from statistics import median


def read_arm(paths):
    matches = {}
    for path in paths:
        receipt = json.loads(path.read_text())
        for row in receipt["cases"]:
            key = row["fixture"]["id"]
            if key in matches:
                raise ValueError(f"Duplicate fixture {key} in {path}.")
            matches[key] = row
    return matches


def summarize(rows):
    groups = defaultdict(lambda: defaultdict(Counter))
    for row in rows:
        case = row["fixture"]
        stage_range = "early" if case["level"] <= 16 else "mid" if case["level"] <= 34 else "late"
        result = row.get("outcome", "invalid")
        for category, label in (("difficulty", case["difficulty"]), ("archetype", case["archetype"]),
                                ("family", case["family"]), ("policy", case["policy"]), ("story_range", stage_range)):
            groups[category][label][result] += 1
    results = [
        row for row in rows if row.get("outcome") in ("victory", "defeat")
    ]
    return {
        "planned": len(rows),
        "completed": len(results),
        "audit_failures": {row["fixture"]["id"]: row["invalid"] for row in rows if row["invalid"]},
        "outcomes": Counter(row.get("outcome", "invalid") for row in rows),
        "by_group": groups,
        "median_match_seconds": median(r["seconds"] for r in results) if results else None,
        "reaper_matches": sum(r["reaper"] for r in results),
        "hall_matches": sum(r["hall_visits"] > 0 for r in results),
        "hall_visits": sum(r["hall_visits"] for r in results),
        "item_assisted_completed": sum(bool(r["items_used"]) for r in results),
        "saved_complete_results": sum(r["settlement"]["saved"] and not r["invalid"] for r in results),
        "max_ledger_error": max((r["max_ledger_error"] for r in results), default=0),
    }


def compare(checkpoint, candidate):
    if checkpoint.keys() != candidate.keys():
        raise ValueError("Checkpoint and candidate fixture keys differ.")
    differences = []
    for key, before in checkpoint.items():
        after = candidate[key]
        settings = ("fixture", "map_hash", "seed", "opening_gold", "opening_power")
        mismatches = [field for field in settings if before.get(field) != after.get(field)]
        if mismatches:
            differences.append({"fixture": key, "unmatched_opening": mismatches})
            continue
        if before.get("outcome") not in ("victory", "defeat") or after.get("outcome") not in ("victory", "defeat"):
            differences.append({"fixture": key, "incomplete": True})
            continue
        differences.append({
            "fixture": key,
            "opening_drift": [field for field in ("spawn", "room", "seconds_to_bed") if before[field] != after[field]],
            "outcome": [before["outcome"], after["outcome"]],
            "seconds": [before["seconds"], after["seconds"]],
            "player_door_damage": [before["player_door_damage"], after["player_door_damage"]],
            "non_player_doors_struck": [sum(door["strikes"] > 0 and door["owner"] != 0 for door in row["doors"])
                                         for row in (before, after)],
            "multi_room_pressure": [sum(door["strikes"] > 0 for door in row["doors"]) for row in (before, after)],
            "evolution": [before["max_evolution"], after["max_evolution"]],
            "hall_visits": [before["hall_visits"], after["hall_visits"]],
            "reaper": [before["reaper"], after["reaper"]],
        })
    return differences


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--checkpoint", type=Path, nargs="+", required=True)
    parser.add_argument("--candidate", type=Path, nargs="+", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    before, after = read_arm(args.checkpoint), read_arm(args.candidate)
    differences = compare(before, after)
    summary = {
        "checkpoint": summarize(list(before.values())),
        "candidate": summarize(list(after.values())),
        "matched": sum("outcome" in row for row in differences),
        "outcome_changes": Counter("→".join(row["outcome"]) for row in differences if "outcome" in row),
        "pairs": differences,
    }
    args.output.write_text(json.dumps(summary, indent=2) + "\n")


if __name__ == "__main__":
    main()
