class_name DamageRules
extends RefCounted
const PHYSICAL="physical"
const MAGIC="magic"
const ELEMENTS=["neutral","fire","ice","electric","earth"]
const COUNTERS={"fire":"ice","ice":"earth","earth":"electric","electric":"fire"}
static func weapon(kind: String) -> Dictionary:
 return {"type":PHYSICAL if kind=="turret" or kind=="trap" else MAGIC,"element":{"flame":"fire","inferno":"fire","frost":"ice","shock":"electric","heavy":"electric","trap":"earth"}.get(kind,"neutral")}
const SOURCE_PACKETS={
 "door strike":{"type":"physical","element":"neutral"},"charged heavy strike":{"type":"physical","element":"earth"},"undead strike":{"type":"physical","element":"earth"},
 "Scythe Slash":{"type":"physical","element":"neutral"},"Embedded Scythe":{"type":"physical","element":"neutral"},"scythe":{"type":"physical","element":"neutral"},
 "siege":{"type":"magic","element":"neutral"},"surge":{"type":"magic","element":"neutral"},"Phantom Scream":{"type":"magic","element":"ice"},
 "Shadow Surge":{"type":"magic","element":"neutral"},"Dread Aura":{"type":"magic","element":"neutral"},"curse":{"type":"magic","element":"neutral"},
 "cursed_projectile":{"type":"magic","element":"ice"},"interference":{"type":"magic","element":"electric"},"chain_lightning":{"type":"magic","element":"electric"},"soul_drain":{"type":"magic","element":"neutral"}}
static func source(name: String) -> Dictionary:return SOURCE_PACKETS.get(name,{"type":PHYSICAL,"element":"neutral"}).duplicate()
static func affinity(archetype: String) -> String:return {"crusher":"earth","ravager":"fire","witch":"ice","electric":"electric","storm":"electric"}.get(archetype,"neutral")
static func multiplier(element: String,defender: String) -> float:
 if element=="neutral" or defender=="neutral":return 1.0
 if COUNTERS.get(element,"")==defender:return 1.15
 if COUNTERS.get(defender,"")==element:return .9
 return 1.0
static func valid(packet: Dictionary) -> bool:return packet.get("type","") in [PHYSICAL,MAGIC] and packet.get("element","") in ELEMENTS
static func describe(packet: Dictionary) -> String:return ("Physical" if packet.type==PHYSICAL else "Magic")+" · "+str(packet.element).capitalize()
