"""Summarize matched, settled Story runs from phase23_campaign.gd.

Usage: python summarize_phase23.py SHARDS_DIR OUTPUT_DIR
The source JSONL remains available as lossless, timestamp-independent gzip.
"""
import collections
import gzip
import json
import statistics
import sys
from pathlib import Path


def aggregate(rows):
    n = len(rows)
    if not n:
        return {}
    wins = [r for r in rows if r["outcome"] == "victory"]
    doors = [next(d for d in r["doors"] if d["owner"] == 0) for r in rows]
    events = [[e for e in r["events"] if e["type"] == "encounter"] for r in rows]
    contested = [r for r, d in zip(rows, doors) if d["strikes"]]
    repeats = [len(visits) - len({e["room"] for e in visits}) for visits in events]
    sums = [sum(d["hunter_damage"] for d in r["doors"] if d["owner"] > 0) for r in rows]
    encounters = [es[0]["time"] - r["preparation"] for r, es in zip(rows, events) if es]
    return {
        "n": n, "wins": len(wins),
        "human_door_struck": len(contested),
        "human_room_physically_encountered": sum(any(e["room"]==r["room"] for e in es) for es,r in zip(events,rows)),
        "human_zero_damage_no_door_damage_wins": sum(r["player_damage"] == 0 and r["player_door_damage"] == 0 for r in wins),
        "wins_without_hunter_damage": sum(r["player_damage"] == 0 for r in wins),
        "first_arrival_after_prep_median_s": round(statistics.median(encounters), 2) if encounters else None,
        "room_arrivals": sum(map(len, events)), "repeat_room_arrivals": sum(repeats),
        "reassessments": sum(r["event_counts"].get("hunter_reassess", 0) for r in rows),
        "successful_hall_visits": sum(r["hall_visits"] for r in rows),
        "boss_transformations": sum(r["reaper"] for r in rows),
        "median_seconds": round(statistics.median(r["seconds"] for r in rows), 2),
        "mean_main_hunter_damage_player": round(statistics.mean(r["player_damage"] for r in rows), 2),
        "mean_main_hunter_damage_allies": round(statistics.mean(sums), 2),
        "median_seconds_in_transit": round(statistics.median(r["trace"]["motion_seconds"] for r in rows),2),
        "median_player_attack_contact_s": round(statistics.median(d["seconds_under_attack"] for d in doors),2),
        "npc_eliminations": sum(sum(d["owner"] > 0 and not d["alive"] for d in r["doors"]) for r in rows),
    }


def trajectory(r):
    return [(e["time"], e["type"], e["room"], e.get("reason", ""))
            for e in r["events"] if e["type"] in {"approach","encounter","door_break","hunter_reassess","boss_transform","hunter_retreat","elimination"}]


def first_divergence(a, b):
    before, after = trajectory(a), trajectory(b)
    for i in range(max(len(before),len(after))):
        left = before[i] if i < len(before) else None
        right = after[i] if i < len(after) else None
        if left != right:
            return [left,right]
    return None


def load_rows(paths):
    indexed = {}
    for p in sorted(paths):
        with p.open() as file:
            for line in file:
                row = json.loads(line)
                key = row["fixture"]["id"]
                if key in indexed:
                    raise ValueError(f"Duplicate {key}")
                indexed[key] = row
    return indexed


def main(shards, dest):
    output = {}
    allrows = []
    for split in ["development","held-out"]:
        arms = {}
        for arm in ["baseline","candidate"]:
            arms[arm] = load_rows(shards.glob(f"{arm}-{split}-*.jsonl"))
            for row in arms[arm].values():
                allrows.append({"arm":arm, **row})
        if not arms["baseline"] or set(arms["baseline"]) != set(arms["candidate"]):
            raise ValueError(f"{split}: unequal fixture sets")
        for k in arms["baseline"]:
            before, after = arms["baseline"][k], arms["candidate"][k]
            for r in (before,after):
                if r["invalid"] or not r["terminal_recorded"] or not r["settlement"]["saved"]:
                    raise ValueError(f"{k}: unsuccessful trial {r['invalid']}")
                if any(r["movement_diagnostics"].values()):
                    raise ValueError(f"{k}: movement outside navigation or speed budget")
            for field in ["fixture","map_hash","spawn","seed","room","seconds_to_bed","preparation","opening_gold","opening_power","opening_door_hp","opening_hunter_max_hp"]:
                if before[field] != after[field]:
                    raise ValueError(f"Unmatched {field} in {k}")
        summary = {}
        for name, rows in arms.items():
            vals = list(rows.values())
            data = {"overall":aggregate(vals)}
            for group in ["difficulty","policy","level","archetype","family","room"]:
                get_key = lambda r: r["room"] if group == "room" else r["fixture"][group]
                data[group] = {str(k):aggregate([r for r in vals if get_key(r)==k]) for k in sorted({get_key(r) for r in vals})}
            bands = {"early_1_15":range(1,16),"middle_16_34":range(16,35),"late_35_50":range(35,51)}
            data["chapter_band_by_difficulty"] = {
                band:{d:aggregate([r for r in vals if r["fixture"]["difficulty"]==d and r["fixture"]["level"] in levels])
                      for d in data["difficulty"]} for band,levels in bands.items()}
            data["difficulty_policy_wins"] = {d:{p:[r["outcome"] for r in vals if r["fixture"]["difficulty"]==d and r["fixture"]["policy"]==p].count("victory") for p in data["policy"]} for d in data["difficulty"]}
            data["unassisted_carries"] = [{"id":r["fixture"]["id"],"seed":r["seed"],"room":r["room"],"seconds":round(r["seconds"],2),"arrivals":[e["room"] for e in r["events"] if e["type"]=="encounter"],"choices":r["trace"]["choices"],"ally_damage_by_room":[round(d["hunter_damage"],2) for d in r["doors"] if d["owner"]>0]}
                for r in vals if r["fixture"]["policy"]=="passive" and r["outcome"]=="victory"]
            pairs = []
            for r in vals:
                if r["fixture"]["policy"] != "item_assisted":
                    continue
                other_id = r["fixture"]["id"].rsplit("-",1)
                other = rows[f"{other_id[0]}-{int(other_id[1])-1}"]
                if other["fixture"]["policy"] != "skilled" or r["seed"]!=other["seed"] or r["room"]!=other["room"] or len(r["items_used"])!=1:
                    raise ValueError(f"Unpaired item trial {r['fixture']}")
                pairs.append({"id":r["fixture"]["id"],"no_item":other["outcome"],"crate":r["outcome"],"delta_player_damage":round(r["player_damage"]-other["player_damage"],2),"delta_elapsed_seconds":round(r["seconds"]-other["seconds"],2)})
            data["matched_gold_crate"] = pairs
            quiet = []
            for r in vals:
                if r["outcome"] != "victory" or r["player_damage"]>0 or r["player_door_damage"]>0:
                    continue
                group, i = r["fixture"]["id"].rsplit("-",1)
                passive = rows[f"{group}-{int(i)-int(i)%7}"]
                quiet.append({"id":r["fixture"]["id"],"policy":r["fixture"]["policy"],
                    "own_gold_spent":round(r["ledger"]["spent_g"],2),"passive_twin_result":passive["outcome"],
                    "passive_twin_contact":round(passive["player_door_damage"],2),
                    "own_room_chosen":any(x[1]==r["room"] for x in r["trace"]["choices"])})
            data["untouched_zero_damage_victories"] = quiet
            summary[name] = data
        flips = []
        for k, b in arms["baseline"].items():
            a = arms["candidate"][k]
            if b["outcome"] != a["outcome"]:
                flips.append({"id":k,"seed":b["seed"],"room":b["room"],"before":b["outcome"],"after":a["outcome"],"first_tactical_trace_difference":first_divergence(b,a),"terminal_seconds":[round(r["seconds"],2) for r in (b,a)],"player_damage":[round(r["player_damage"],2) for r in (b,a)],"retargets":[r["hunter_retargets"] for r in (b,a)]})
        summary["flips"] = flips
        output[split] = summary
    dest.mkdir(parents=True,exist_ok=True)
    (dest/"cohort-summary.json").write_text(json.dumps(output,indent=1)+"\n")
    raw = "".join(json.dumps(r,separators=(",",":"),ensure_ascii=False)+"\n" for r in allrows)
    (dest/"cohort-matches.jsonl.gz").write_bytes(gzip.compress(raw.encode(),compresslevel=9,mtime=0))
    fine = []
    fine_receipts = []
    for arm in ["baseline","candidate"]:
        fast = load_rows(shards.glob(f"{arm}-development-*.jsonl"))
        refined = load_rows(shards.glob(f"fine-{arm}-*.jsonl"))
        for key,r in refined.items():
            ref = fast[key]
            fine_receipts.append({"arm":arm,**r})
            if r["invalid"] or r["map_hash"]!=ref["map_hash"] or r["seed"]!=ref["seed"] or r["room"]!=ref["room"]:
                raise ValueError(f"Fine-step mismatch: {arm}, {key}, {r['invalid']}")
            fine.append({"fixture":r["fixture"],"arm":arm,"seed":r["seed"],"room":r["room"],
                "outcome_150ms":ref["outcome"],"outcome_50ms":r["outcome"],
                "s_150ms":round(ref["seconds"],2),"s_50ms":round(r["seconds"],2),
                "player_damage_150ms":round(ref["player_damage"],2),"player_damage_50ms":round(r["player_damage"],2),
                "physical_arrivals_50ms":[e["room"] for e in r["events"] if e["type"]=="encounter"]})
    opening = list(load_rows(shards.glob("opening.jsonl")).values())
    if len(fine)!=12 or len(opening)!=16:
        raise ValueError("Missing fixed timestep sensitivity or early Normal pairs")
    for i in range(0,len(opening),2):
        b,a=opening[i:i+2]
        if a["fixture"]["id"]!=f"opening-{i+1}" or a["fixture"]["policy"]!="beginner_second" or b["fixture"]["id"]!=f"opening-{i}" or a["room"]!=b["room"] or a["map_hash"]!=b["map_hash"] or a["invalid"] or b["invalid"]:
            raise ValueError(f"Unpaired early Normal test: {i}")
    diagnostics={"model_step_s":0.05,"timestep_sensitivity":fine,"fine_match_receipts":fine_receipts,"early_normal":opening}
    (dest/"cohort-diagnostics.json.gz").write_bytes(gzip.compress(json.dumps(diagnostics,separators=(",",":")).encode(),mtime=0))
    for split, s in output.items():
        for arm in ("baseline","candidate"):
            print(split,arm,s[arm]["overall"])
        print(split,len(s["flips"]),"outcome changes")


if __name__ == "__main__":
    main(*map(Path,sys.argv[1:]))
