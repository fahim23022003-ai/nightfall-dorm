"""Audit paired V2.1/V2.2 receipts and prepare the game evidence report."""
import argparse
from collections import Counter
import json
from pathlib import Path
from statistics import median


def read(path):
    source = json.loads(path.read_text())
    if source["failures"]:
        raise ValueError(f"{path} contains {source['failures']} invalid cases")
    cases = {tuple(row["case"]): row for row in source["cases"]}
    if len(cases) != len(source["cases"]):
        raise ValueError(f"{path} has duplicate fixtures")
    if any(row["outcome"] not in ("victory", "defeat") or row["invalid"] for row in cases.values()):
        raise ValueError(f"{path} contains an unfinished case")
    return cases, source


def pair(before, after):
    if before.keys() != after.keys():
        raise ValueError("The two arms did not use the same cases")
    for key, row in before.items():
        if row["map_sha256"] != after[key]["map_sha256"]:
            raise ValueError(f"The map changed for fixture {key}")


def group(rows, difficulty, policy=None, family=None):
    return [
        row for key, row in rows.items()
        if key[1] == difficulty and (policy is None or key[4] == policy)
        and (family is None or row["family"] == family)
    ]


def wins(rows):
    return sum(row["outcome"] == "victory" for row in rows)


def metric(rows, key):
    return median(row[key] for row in rows)


def win_pair(old, new):
    return f"{wins(old)}/{len(old)} → {wins(new)}/{len(new)}"


def compact(path, data):
    path.write_text(json.dumps(data, separators=(",", ":")) + "\n")


def mechanism(old, new):
    before = [event for event in old["decision_timeline"] if event["type"] == "door_damage"]
    after = [event for event in new["decision_timeline"] if event["type"] == "door_damage"]
    result = []
    for row, damage in ((old, before), (new, after)):
        first = damage[0] if damage else {}
        results = {
            "outcome":row["outcome"], "first_hit": first.get("time"), "opening_wallet":row["opening_wallet"],
            "first_hit_wallet":[first.get("gold_after_tick"),first.get("power_after_tick")],
            "machines":dict(Counter(event.get("kind","unknown") for event in row["decision_timeline"] if event["type"]=="build")),
            "paid_wards":row["event_counts"].get("emergency_ward",0), "uses":row.get("item_uses",[]),
            "specializations":[event for event in row.get("strategy_actions",[]) if event["type"]=="specialized"],
            "repositions":[event for event in row.get("strategy_actions",[]) if event["type"]=="reposition"],
            "counterplay":row.get("tactical_breaks",[]), "control_hits":row.get("control_hits",0),
        }
        result.append(results)
    return result


def report(root, output):
    output.mkdir(parents=True, exist_ok=True)
    baseline = {}
    candidate = {}
    for shard in range(3):
        before, _ = read(root / f"baseline-{shard}.json")
        after, _ = read(root / f"initial-{shard}.json")
        if len(before) != 90:
            raise ValueError("The broad cohort is incomplete")
        pair(before, after)
        compact(output / f"v21-{shard}.json", list(before.values()))
        compact(output / f"v22-{shard}.json", list(after.values()))
        baseline.update(before)
        candidate.update(after)
    if len(baseline) != 270:
        raise ValueError("Expected 270 matched cases")
    standard = [key for key in baseline if key[1] == "standard"]
    standard_exact = sum(all(value == candidate[key].get(field) for field,value in baseline[key].items()) for key in standard)
    if standard_exact != len(standard):
        raise ValueError("Standard telemetry changed")

    focused = {}
    for cohort in ("exact", "probes", "late", "alternate", "staged"):
        a = root / f"baseline-{cohort}.json"
        b = root / f"{'initial' if cohort == 'exact' else 'final'}-{cohort}.json"
        if not a.exists() or not b.exists():
            continue
        old, one = read(a)
        new, two = read(b)
        pair(old, new)
        compact(output / f"v21-{cohort}.json", one)
        compact(output / f"v22-{cohort}.json", two)
        focused[cohort] = (old, new)
    primary = focused["exact"]

    lines = [
        "# V2.2 matched combat and counterplay QA", "",
        "The independent broad cohort ran 270 ordinary Campaign matches per arm. Each of ten map families ran "
        "three seeds on each difficulty with passive, Balanced and Needle-first plans. The same seeds, room, generated "
        "map hash and policy matched in all pairs. The harness places the survivor beside the bed, then uses the normal "
        "sleep action. Resources thereafter come from income and normal transactions. Every match settled with valid movement, "
        "wallet and Hall accounting. Standard matched in all 90 full telemetry rows.", "",
        "| Difficulty | Passive wins | Balanced wins | Needle-first wins | Defense-induced switches |",
        "| --- | ---: | ---: | ---: | ---: |",
    ]
    summary = {"paired_matches":270,"standard_exact_matches":standard_exact,"broad":{},"focused":{}}
    for difficulty in ("standard", "hard", "hell"):
        original = group(baseline,difficulty)
        revised = group(candidate,difficulty)
        policies = [win_pair(group(baseline,difficulty,policy), group(candidate,difficulty,policy)) for policy in ("passive","balanced","needle_defense")]
        delayed = sum(len(row["tactical_breaks"]) for row in revised)
        lines.append(f"| {difficulty.title()} | {' | '.join(policies)} | {delayed} |")
        summary["broad"][difficulty] = {
            "outcomes":[Counter(row["outcome"] for row in arm) for arm in (original,revised)],
            "by_policy":dict(zip(("passive","balanced","needle_defense"),policies)),
            "defense_delays_breach": delayed,
            "team_retarget_median":[metric(arm,"hunter_retargets") for arm in (original,revised)],
            "player_exposure_median":[metric(arm,"peak_player_exposure") for arm in (original,revised)],
            "elapsed_median":[metric(arm,"simulated_seconds") for arm in (original,revised)],
        }
    lines.extend([
        "", "### Outcomes across families", "",
        "| Family | Hard active wins | Hell active wins |",
        "| --- | ---: | ---: |",
    ])
    for family in dict.fromkeys(row["family"] for row in baseline.values()):
        values = []
        for difficulty in ("hard","hell"):
            arms = [[row for row in group(arm,difficulty,family=family) if row["case"][-1]!="passive"] for arm in (baseline,candidate)]
            values.append(win_pair(*arms))
        lines.append(f"| {family.replace('_',' ').title()} | {' | '.join(values)} |")
    lines.extend([
        "", "Hell remained demanding. Branching, Courtyards and Labyrinth each stayed at 0/6 on these two broad "
        "active strategies. The targeted plans and alternate room choices below test different decisions. The paired "
        "sample supports a new defense interaction. It shows a modest change in broad active win counts.", "",
        "### Hard passive results", "",
        "Hard passive wins rose from one to four. The three additional wins had zero player damage. Genuine NPC "
        "damage and upkeep contributed to their doors holding; all three traces show at least one defense-induced "
        "switch from an NPC room. Those shifts changed exposure and let teammates land more damage. NPC contribution "
        "is valid gameplay, and the increase in this paired sample is a trade-off. The sample does not establish the "
        "general passive win rate. Hell passive remained at zero.", "",
        "| Family and seed | NPC damage to Hunter | Player direct siege | Hunter switches between NPC rooms |",
        "| --- | ---: | ---: | ---: |",
    ])
    passive_flips = []
    for key, row in candidate.items():
        previous = baseline[key]
        if key[1] != "hard" or key[4] != "passive" or previous["outcome"] != "defeat" or row["outcome"] != "victory":
            continue
        passive_flips.append({"case": key,"family":row["family"],"before":previous,"after":row})
        npc = f"{previous['npc_hunter_damage']:.0f} → {row['npc_hunter_damage']:.0f}"
        time = f"{previous['peak_player_exposure']:.1f}s → {row['peak_player_exposure']:.1f}s"
        rooms = ", ".join(f"R{event['room']}→R{event['next_room']+1}" for event in row["tactical_breaks"])
        lines.append(f"| {row['family'].title()} {key[2]} | {npc} | {time} | {rooms} |")
    summary["hard_passive_flips"] = passive_flips
    lines.extend([
        "", "## Exact Hell starts", "",
        "Both exact starts begin with 25 Gold and zero Electricity. The nine initial policies are matched per room. "
        "Some policies converged on the same early purchases once low door HP took priority. Their win counts are separate "
        "attempts and should not be treated as independent strategic styles.", "",
        "| Exact start | Plan | V2.1 → V2.2 | V2.2 realized purchases and tools |",
        "| --- | --- | --- | --- |",
    ])
    for cohort in ("exact","probes"):
        if cohort not in focused:
            continue
        old, new = focused[cohort]
        for key,row in new.items():
            one,two = mechanism(old[key],row)
            summary["focused"][str(key)] = [one,two]
            tools = [f"{count} {build}" for build,count in two["machines"].items()]
            if two["paid_wards"]:
                tools.append(f"{two['paid_wards']} paid Ward")
            if two["uses"]:
                tools.extend(item["item"] for item in two["uses"])
            if two["repositions"]:
                tools.append("reposition")
            if two["specializations"]:
                tools.append("specialization")
            lines.append(f"| {row['family'].title()} {key[2]} R{key[3]+1} | {key[4].replace('_',' ').title()} | {one['outcome']} → {two['outcome']} | {', '.join(tools) or '—'} |")
    lines.extend([
        "",
        "On Labyrinth 10358 R2, the first player strike was at 48.0 seconds, eight seconds after preparation. "
        "At first contact the original no-item defended plans generally held 35.4–40.6 Gold and zero Electricity, "
        "against a 120 Gold Dynamo and an 18 Electricity Frost Tower. Immediate repair and cheaper Needles competed "
        "for that income. The Balanced variant gained a real defensive switch at 63.0 seconds and later paid for "
        "a Dynamo and Repair Station, but lost. That trace identifies an opening constraint without proving the seed or room unwinnable.",
        "",
        "In Hybrid 12336 R4, the five successful original V2.2 replays all show a change from room 4 to room 5 "
        "at 154.65 seconds with reason `defense_delays_breach`. The matched V2.1 policies lost. Their positive response "
        "actually used earned infrastructure and paid Ward. Repair, Needle, and Shock purchases are recorded by policy. "
        "The two reposition scripts moved an existing paid Needle during preparation and verified its identity and wallet "
        "on the move. The one-use Repair Kit came from an actual prior Standard victory and First Victory achievement.",
        "",
        "The extra Earned Control experiment won Labyrinth R2 on both versions. The prior Campaign victory funded "
        "the normal First Blood Gold Crate and a 16 RM shop Battery. The test equipped and consumed each once through "
        "the profile API. That purchased a Frost Tower at 3.75 seconds and registered 53 controlled hits on either "
        "version. The same finite loadout lost Hybrid R4, despite landing 17 Frost hits. The five-Needle "
        "approach-aware experiment lost both rooms. The assisted Labyrinth result shows a practical route using "
        "earned items. The ordinary no-item plans tested for that room still lost.",
        "",
    ])

    for cohort in ("late","alternate"):
        if cohort not in focused:
            continue
        old,new = focused[cohort]
        lines.extend([
            "### Longer matches for control and specialization" if cohort == "late" else "### Same Hell seeds, alternate rooms",
            "",
            "| Fixture | Policy | V2.1 → V2.2 | V2.2 controlled hits | V2.2 specializations |",
            "| --- | --- | --- | ---: | ---: |",
        ])
        for key,row in new.items():
            one,two=mechanism(old[key],row)
            summary["focused"][str(key)] = [one,two]
            label=f"{row['family'].replace('_',' ').title()} {key[2]} R{key[3]+1}"
            lines.append(f"| {label} | {key[4].replace('_',' ').title()} | {one['outcome']} → {two['outcome']} | {two['control_hits']} | {len(two['specializations'])} |")
        lines.extend([
            "",
            "The longer subset deliberately tests paid capabilities that the exact early deaths did not leave time to reach." if cohort == "late" else
            "A different room keeps the same seed, archetype and corridor layout. These three R1/R4/R3 victories on "
            "V2.1 became losses under V2.2. Each recorded a defense-induced switch. These are matched counterexamples "
            "to a uniform improvement across room choices.",
            "",
        ])
    if "staged" in focused:
        old,new=focused["staged"]
        lines.extend([
            "### Separately prepared specialization fixture", "",
            "These Stage 5 Hell Hybrid 70169 R2 controls add a documented 2,250 Gold and 210 Electricity test "
            "treasury. The fixture records it as other income. Bed, Door, Needle and branch upgrades are paid "
            "through the original transactions. These two pairs are excluded from all earned results above.", "",
            "| Paid Needle branch | L5 payment | Session time at purchase | V2.1 → V2.2 | Hunter defensive switch in V2.2 |",
            "| --- | ---: | ---: | --- | --- |",
        ])
        for key,row in new.items():
            spec=next(event for event in row["strategy_actions"] if event["type"]=="specialized")
            break_routes = ", ".join(f"R{event['room']}→R{event['next_room']+1} at {event['time']:.1f}s" for event in row["tactical_breaks"])
            lines.append(f"| {spec['branch'].title()} | {spec['paid_gold']:.0f}G / {spec['paid_power']:.0f}E | {spec['time']:.1f}s | {old[key]['outcome']} → {row['outcome']} | {break_routes or '—'} |")
            summary["focused"][str(key)] = mechanism(old[key],row)
        lines.extend([
            "",
            "None of the unprepared focused runs reached a paid specialization. The prepared branch checks verify "
            "payment, branch selection and combat through a normal ending.", "",
        ])
    lines.extend([
        "## Reproduce", "",
        "Use Godot 4.6.3. Run the base matrix on the frozen V2.1 checkpoint with the existing tactics gate enabled. "
        "Run the same seed cohort on the V2.2 source with the fair-siege gate enabled. Use a distinct profile home per process.", "",
        "```sh",
        "godot --headless --script tools/nightmare_tactics/check_complete_matches.gd -- /tmp/baseline-0.json candidate 0",
        "godot --headless --script tools/nightmare_tactics/check_fair_counterplay.gd -- /tmp/initial-0.json v22 0",
        "godot --headless --script tools/nightmare_tactics/check_fair_counterplay.gd -- /tmp/baseline-exact.json v21 exact",
        "godot --headless --script tools/nightmare_tactics/check_fair_counterplay.gd -- /tmp/initial-exact.json v22 exact",
        "```", "",
        "Repeat the broad cohort for repetitions 1 and 2. The focused harness also accepts `probes`, `late`, `alternate` and `staged` "
        "for both arms. Run this report generator on the receipt folder. [Structured summary](summary.json)", "",
    ])
    (output / "README.md").write_text("\n".join(lines))
    (output / "summary.json").write_text(json.dumps(summary, indent=2)+"\n")
    print(f"Compared 270 primary pairs. Verified {sum(len(pair[0]) for pair in focused.values())} focused pairs.")
    print(f"Counterplay in {sum(len(row['tactical_breaks']) for row in candidate.values())} broad recorded switches.")


if __name__ == "__main__":
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("receipts", type=Path)
    cli.add_argument("output", type=Path)
    args = cli.parse_args()
    report(args.receipts,args.output)
