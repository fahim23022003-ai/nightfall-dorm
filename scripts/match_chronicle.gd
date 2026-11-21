class_name MatchChronicle
extends RefCounted
## Bounded, match-local view of authoritative events.
const LABELS := {
 "claim":"Room claimed", "bed_income":"First Bed Gold", "build":"Defense placed",
 "encounter":"Hunter arrived", "door_damage":"First player-door hit",
 "repair":"Manual repair", "repair_started":"Continuous repair started",
 "repair_finished":"Continuous repair ended", "elimination":"Resident fallen",
 "nightmare_level":"Hunter evolved", "boss_transform":"Reaper awakens",
 "victory":"Victory", "defeat":"Defeat",
}
var entries: Array[Dictionary]=[]
var remembered: Dictionary={}
var recent_attacks: Dictionary={}

func record(kind: String,room_index: int,player_index: int,at: float,data: Dictionary={}) -> void:
 if kind=="door_damage" and data.get("attacker_id",0)==1 and data.get("damage",0.0)>0.0:
  recent_attacks[room_index]=at
 if not LABELS.has(kind):return
 if kind in ["claim","bed_income","build","repair","repair_started","repair_finished","door_damage"] and room_index!=player_index:return
 if kind=="build" and data.get("kind","") not in DefenseEffects.WEAPONS:return
 var key: String=kind+str(room_index) if kind in ["encounter","elimination"] else kind
 if remembered.has(key) and kind not in ["nightmare_level","repair_started","repair_finished"]:return
 remembered[key]=true
 if entries.size()>=32:entries.pop_front()
 entries.append({"name":LABELS[kind],"room":room_index,"at":at})

func last_attack(room_index: int) -> float:
 return recent_attacks.get(room_index,-INF)
