"""Write paired combat QA summaries from the six ordinary Godot receipts."""

import argparse
from collections import Counter
import json
from pathlib import Path
from statistics import median


def read_focus(root, label):
    data = json.loads((root / f"focused-{label}.json").read_text())
    if data["failures"]:
        raise SystemExit(f"Invalid targeted {label} fixtures")
    return {tuple(row["case"]): row for row in data["cases"]}


def read_arm(root, prefix, focused):
    rows = []
    for shard in range(3):
        data = json.loads((root / f"{prefix}-{shard}.json").read_text())
        if len(data["cases"]) != 90:
            raise SystemExit(f"Missing fixtures in {prefix} shard {shard}")
        for row in data["cases"]:
            if row["invalid"]:
                key = tuple(row["case"])
                revised = focused.get(key, {})
                if (
                    revised.get("context") != "npc_arrival_oracle"
                    or not revised.get("all_npcs_slept")
                    or revised["invalid"]
                    or any(value != revised.get(field) for field, value in row.items() if field != "invalid")
                ):
                    raise SystemExit(f"Unverified {prefix} fixture: {key} {row['invalid']}")
                row["invalid"] = []
            rows.append(row)
    indexed = {tuple(row["case"]): row for row in rows}
    if len(indexed) != len(rows):
        raise SystemExit(f"Duplicate match fixtures in {prefix}")
    return indexed


def group_summary(rows):
    first = [row["first_player_strike"] for row in rows if row["first_player_strike"] >= 0]
    return {
        "count": len(rows),
        "wins": sum(row["outcome"] == "victory" for row in rows),
        "player_under_attack": len(first),
        "median_player_first_strike": median(first) if first else None,
        "median_player_exposure_seconds": median(row["peak_player_exposure"] for row in rows),
        "median_match_seconds": median(row["simulated_seconds"] for row in rows),
        "median_player_hunter_damage": median(row["player_hunter_damage"] for row in rows),
        "median_npc_hunter_damage": median(row["npc_hunter_damage"] for row in rows),
        "median_retargets": median(row["hunter_retargets"] for row in rows),
        "median_evolution_level": median(row["evolution_level"] for row in rows),
        "successful_hall_visits": sum(row["recovery_visits"] for row in rows),
        "hall_attempts": sum(row["recovery_attempts"] for row in rows),
        "breach_commitments": sum(row["event_counts"].get("hunter_commit", 0) for row in rows),
        "eliminations": sum(row["eliminations"] for row in rows),
        "median_surviving_npcs": median(sum(room["owner"] > 0 and room["alive"] for room in row["rooms"]) for row in rows),
        "shots_into_player_door": sum(row["rooms"][int(row["case"][3])]["door_strikes"] for row in rows),
    }


def between(old, new, key, digits=1):
    def label(value):
        return f"{value:.{digits}f}" if value is not None else "—"
    return f"{label(old[key])} → {label(new[key])}"


def write_report(root, baseline_prefix, candidate_prefix, output):
    baseline_focus = read_focus(root, "baseline")
    candidate_focus = read_focus(root, "candidate")
    baseline = read_arm(root, baseline_prefix, baseline_focus)
    candidate = read_arm(root, candidate_prefix, candidate_focus)
    if baseline.keys() != candidate.keys():
        raise SystemExit("A/B fixture keys differ")
    if any(baseline[key]["map_sha256"] != candidate[key]["map_sha256"] for key in baseline):
        raise SystemExit("Generated geometry differs between matched fixtures")

    levels = ("standard", "hard", "hell")
    strategies = ("passive", "balanced", "needle_defense")
    grouped = {}
    scopes = {}
    for level in levels:
        for plan in strategies:
            keys = [key for key in baseline if key[1] == level and key[4] == plan]
            grouped[f"{level}/{plan}"] = [group_summary([arm[key] for key in keys]) for arm in (baseline, candidate)]
        keys = [key for key in baseline if key[1] == level]
        scopes[level] = [group_summary([arm[key] for key in keys]) for arm in (baseline, candidate)]

    families = dict.fromkeys(row["family"] for row in baseline.values())
    active_family_groups = {}
    for family in families:
        active_family_groups[family] = {}
        for difficulty in ("hard", "hell"):
            keys = [
                key for key, row in baseline.items()
                if key[1] == difficulty and key[4] != "passive" and row["family"] == family
            ]
            active_family_groups[family][difficulty] = [group_summary([arm[key] for key in keys]) for arm in (baseline, candidate)]

    standard_keys = [key for key in baseline if key[1] == "standard"]
    standard_exact = sum(baseline[key] == candidate[key] for key in standard_keys)
    audit = [
        {"fixture": list(key), "before": old, "after": candidate[key]}
        for key, old in baseline.items() if old["prior_passive_win"]
    ]
    if len(audit) != 5 or any(case["before"]["outcome"] != "victory" for case in audit):
        raise SystemExit("Did not reproduce all five historical passive wins")
    flips = {
        level: dict(Counter(
            f"{baseline[k]['outcome']} → {candidate[k]['outcome']}"
            for k in baseline if k[1] == level
        ))
        for level in levels
    }
    output.mkdir(parents=True, exist_ok=True)
    for prefix, rows in ((baseline_prefix, baseline), (candidate_prefix, candidate)):
        for shard in range(3):
            selected = [row for row in rows.values() if row["repetition"] == shard]
            (output / f"{prefix}-{shard}.json").write_text(json.dumps(selected, separators=(",", ":")) + "\n")
    for label, rows in (("baseline", baseline_focus), ("candidate", candidate_focus)):
        (output / f"focused-{label}.json").write_text(json.dumps(list(rows.values()), separators=(",", ":")) + "\n")
    (output / "audit-fixtures.json").write_text((root / "audit-fixtures.json").read_text())
    focused_keys = [
        key for key, row in candidate_focus.items()
        if row["context"] == "hell_balanced_loss" and key[4] == "balanced"
    ]
    alternate_room_results = {}
    for seed in (10358, 12336):
        receipt = root / f"alternate-{seed}.json"
        if not receipt.exists():
            continue
        raw = json.loads(receipt.read_text())
        if raw["failures"] or len(raw["cases"]) != 15:
            raise SystemExit(f"Unverified alternate rooms for seed {seed}")
        rows = raw["cases"]
        original = next(key for key in focused_keys if key[2] == seed)
        if any(row["map_sha256"] != candidate[original]["map_sha256"] for row in rows):
            raise SystemExit(f"Alternate room run changed geometry for seed {seed}")
        (output / f"alternate-{seed}.json").write_text(json.dumps(rows, separators=(",", ":")) + "\n")
        (output / f"room-fixtures-{seed}.json").write_text((root / f"room-fixtures-{seed}.json").read_text())
        alternate_room_results[seed] = {
            "family": rows[0]["family"], "original_room": original[3] + 1,
            "trials": len(rows), "wins": sum(row["outcome"] == "victory" for row in rows),
            "wins_by_room": {
                room: [row["case"][4] for row in rows if row["case"][3] + 1 == room and row["outcome"] == "victory"]
                for room in sorted(set(row["case"][3] + 1 for row in rows))
            },
        }
    summary = {
        "matched_fixtures": len(baseline), "geometry_hashes_matched": len(baseline),
        "exact_standard_traces": standard_exact, "standard_trials": len(standard_keys),
        "difficulty_and_strategy": grouped, "by_difficulty": scopes, "outcome_transitions": flips,
        "active_results_by_family": active_family_groups,
        "five_passive_wins": audit,
        "focused_hell_fixtures": [list(case) for case in focused_keys],
        "same_map_alternate_rooms": alternate_room_results,
    }
    (output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    report = [
        "# Matched Campaign tactics QA",
        "",
        f"The test ran {len(baseline)} cases on the frozen baseline and {len(candidate)} on the candidate. "
        "The seed, generated geometry hash, room, difficulty and automated policy matched in each pair. "
        "Every family ran three seeds per difficulty. Passive players made no purchases. Both defensive "
        "policies spent only resources earned through ordinary play. Each survivor started at the bed so "
        "the test could use normal sleep and focus on siege balance. NPCs claimed and reached all five other "
        "beds in every case. In one Courtyards fixture the first NPC was eliminated before the last NPC fell "
        "asleep, so simultaneous occupancy peaked at four. A targeted replay verified that all five reached "
        "their beds in all three policy pairs. All runs settled without illegal Hunter movement, economy "
        "or Hall budget failures.",
        "",
        "## Wins by difficulty and policy",
        "",
        "| Difficulty | Passive | Balanced | Needle-first |",
        "| --- | ---: | ---: | ---: |",
    ]
    for level in levels:
        values = [
            " → ".join(f"{arm['wins']}/{arm['count']}" for arm in grouped[f"{level}/{plan}"])
            for plan in strategies
        ]
        report.append(f"| {level.capitalize()} | {' | '.join(values)} |")
    report.extend([
        "",
        f"Standard had {standard_exact}/{len(standard_keys)} exactly matching outcome and telemetry rows. "
        "The tactics gate does not target the player's identity. Pressure can land on any room the Hunter reaches.",
        "",
        "## Family comparison",
        "",
        "Each difficulty-family pair has six active-plan runs across three exact seeds and two defense plans. "
        "The candidate recorded zero of six Hell wins in Branching, Courtyards and Labyrinth. "
        "The counts characterize the picked rooms and strategies.",
        "",
        "| Family | Hard active wins | Hell active wins |",
        "| --- | ---: | ---: |",
    ])
    for family, groups in active_family_groups.items():
        values = [
            " → ".join(f"{arm['wins']}/{arm['count']}" for arm in groups[level])
            for level in ("hard", "hell")
        ]
        report.append(f"| {family.replace('_', ' ').title()} | {' | '.join(values)} |")
    report.extend([
        "",
        "## Exposure and team damage",
        "",
        "Each cell gives baseline → candidate. First-strike medians use matches in which the player door "
        "was actually hit. The adjacent count shows how often that happened.",
        "",
        "| Difficulty | Player door hit cases | First strike, median s | Player siege, median s | Hunter damage from player, median | Hunter damage from NPCs, median | Retargets, median | Evolution level, median | Hall visits |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
    ])
    for level, (old, new) in scopes.items():
        values = [
            between(old, new, key, digits) for key, digits in [
                ("player_under_attack", 0), ("median_player_first_strike", 1), ("median_player_exposure_seconds", 1),
                ("median_player_hunter_damage", 0), ("median_npc_hunter_damage", 0), ("median_retargets", 0),
                ("median_evolution_level", 0), ("successful_hall_visits", 0),
            ]
        ]
        report.append(f"| {level.capitalize()} | {' | '.join(values)} |")
    report.extend([
        "",
        "| Difficulty | Match duration, median s | NPC rooms surviving, median | Total eliminations |",
        "| --- | ---: | ---: | ---: |",
    ])
    for level, (old, new) in scopes.items():
        report.append(f"| {level.capitalize()} | {between(old, new, 'median_match_seconds')} | {between(old, new, 'median_surviving_npcs')} | {between(old, new, 'eliminations', 0)} |")
    report.extend([
        "",
        "Room survival counts include the five NPC residences. Total eliminations also count a player loss.",
        "",
        "## The five original passive wins",
        "",
        "All five reproduced on the frozen V2 checkpoint. Each delivered zero player damage to the Hunter. "
        "The team damage records show how much damage the NPCs supplied, including any damage needed "
        "to overcome Hall healing. No first strike means the player door remained untouched.",
        "",
        "| Theme family, difficulty, seed and room | Result | NPC damage to Hunter | Player siege s | First player strike s | Retargets | Evolution | Hall visits |",
        "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |",
    ])
    for case in audit:
        old, new = case["before"], case["after"]
        fixture = case["fixture"]
        label = f"{old['family'].replace('_', ' ').title()}, {fixture[1].title()}, {fixture[2]}, R{int(fixture[3]) + 1}"
        values = [old["outcome"].title() + " → " + new["outcome"].title()]
        for key, digits in [
            ("npc_hunter_damage", 0), ("peak_player_exposure", 1), ("first_player_strike", 1),
            ("hunter_retargets", 0), ("evolution_level", 0), ("recovery_visits", 0),
        ]:
            a = old[key] if old[key] >= 0 else None
            b = new[key] if new[key] >= 0 else None
            values.append(between({key: a}, {key: b}, key, digits))
        report.append(f"| {label} | {' | '.join(values)} |")
    report.extend([
        "",
        "Every baseline passive win had zero direct player siege. The Hall and door hit timelines show one "
        "untouched room and four rooms damaged by a cursed projectile, Phantom Scream, or Undead. "
        "The unchanged two Standard wins and the surviving Hard win still had zero direct siege. "
        "In the two flipped matches, direct pressure did reach the player. "
        "[Summary and five exact timelines](summary.json) · [Door hit sources](focused-baseline.json)",
        "",
        "## What changed in five Hell losses",
        "",
        "The first repeat supplied five fixtures where the baseline Balanced policy won and the candidate "
        "lost. These are targeted losses, so this table tests counterplay on difficult cases. "
        "The focused survival policy bought an early Door upgrade and used repairs or a paid Ward under "
        "direct pressure, then added Needle, Frost and Arc machines as funds allowed.",
        "",
        "| Family and seed | Player first hit after prep, old → new | Candidate breach time | Permanent purchases before breach | Repairs before breach | Candidate Needle-first | Candidate survival-transition |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: |",
    ])
    for key in focused_keys:
        old, new = baseline_focus[key], candidate_focus[key]
        breach = next(event["time"] for event in new["events"] if event["type"] == "door_break" and event["room"] == key[3] + 1)
        decisions = [event for event in new["decision_timeline"] if event["time"] <= breach]
        permanent = sum(event["type"] in ("build", "building_upgrade", "bed_upgrade", "door_upgrade") for event in decisions)
        repairs = sum(event["type"] == "repair" for event in decisions)
        first_hit = " → ".join(f"{r['first_player_strike'] - r['preparation']:.1f}s" for r in (old, new))
        label = f"{new['family'].replace('_', ' ').title()} {key[2]}"
        needle = candidate_focus[(*key[:4], "needle_defense")]["outcome"].title()
        survival = candidate_focus[(*key[:4], "survival_transition")]["outcome"].title()
        report.append(f"| {label} | {first_hit} | {breach:.1f}s | {permanent} | {repairs} | {needle} | {survival} |")
    report.extend([
        "",
        "On Labyrinth 10358, the first encounter and strike matched, but continued productive siege removed "
        "the breaks the previous Hunter gave the defenders. The candidate breached at 110.7 seconds and "
        "received zero damage from NPC weapons. In the corresponding baseline the Hunter rotated back through "
        "Room 6, taking 3,513 NPC damage before losing at 424.8 seconds. On Hybrid 12336 the first player "
        "strike came later under the candidate, but the Hunter then held the approach and breached 26.1 "
        "seconds after the first strike. Those two selected rooms lost under all three tested policies. "
        "Needle-first won the other three selected losses, and survival-transition won two. "
        "[Focused decision and combat timelines](focused-candidate.json) · [Matched baseline timelines](focused-baseline.json)",
        "",
    ])
    if alternate_room_results:
        report.extend([
            "## The same two maps from other rooms",
            "",
            "These two tests kept the same Hell seed, Hunter archetype and geometry. "
            "The three active plans ran all five other rooms. All 30 matches settled with legal movement "
            "and correct income. Each map produced wins from other choices, even though the original room "
            "lost with all three tested policies.",
            "",
            "| Family and seed | Original room | Wins across other rooms | Other rooms with wins |",
            "| --- | ---: | ---: | --- |",
        ])
        names = {"balanced":"Balanced", "needle_defense":"Needle-first", "survival_transition":"Survival-transition"}
        for seed, result in alternate_room_results.items():
            details = " · ".join(
                f"R{room} " + ", ".join(names[plan] for plan in plans)
                for room, plans in result["wins_by_room"].items() if plans
            )
            label = result["family"].replace("_", " ").title()
            report.append(f"| {label} {seed} | R{result['original_room']} | {result['wins']}/{result['trials']} | {details} |")
        report.extend([
            "",
            "[Labyrinth reruns](alternate-10358.json) · [Hybrid reruns](alternate-12336.json)",
            "",
        ])
    report.extend([
        "## Reproduce",
        "",
        "Run the same harness from the clean baseline checkout and from the candidate checkout, with a separate "
        "output per repetition. Use Godot 4.6.3. The script sets the V2 and grid previews internally.",
        "",
        "```sh",
        "godot --headless --script tools/nightmare_tactics/check_complete_matches.gd -- /tmp/baseline-0.json baseline 0",
        "godot --headless --script tools/nightmare_tactics/check_complete_matches.gd -- /tmp/candidate-0.json candidate 0",
        "```",
        "",
        "Repeat for shards 1 and 2. To reproduce the targeted HUD-independent replay, pass "
        "[the case manifest](audit-fixtures.json) to `tools/nightmare_tactics/audit_siege_pressure.gd` after the output "
        "path and arm. Use `tools/nightmare_tactics/report_complete_matches.py` to compare receipts.",
        "",
    ])
    (output / "README.md").write_text("\n".join(report))
    for level, totals in scopes.items():
        print(level, totals)
    for case in audit:
        print(case["fixture"], case["before"]["outcome"], case["after"]["outcome"])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("receipts", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--baseline-prefix", default="baseline")
    parser.add_argument("--candidate-prefix", default="candidate")
    args = parser.parse_args()
    write_report(args.receipts, args.baseline_prefix, args.candidate_prefix, args.output)
