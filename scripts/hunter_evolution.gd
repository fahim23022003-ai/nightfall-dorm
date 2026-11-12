class_name HunterEvolution
extends RefCounted
# One award per actual survivor identity. JSON-safe canonical owner keys.
const BUFFS={
 "blood_frenzy":{"name":"Blood Frenzy","effect":"Attacks recover 10% faster.","category":"offense"},
 "iron_skin":{"name":"Iron Skin","effect":"Incoming damage reduced by 10%.","category":"armor"},
 "predator_rush":{"name":"Predator Rush","effect":"Movement speed increased by 12%.","category":"movement"},
 "door_crusher":{"name":"Door Crusher","effect":"Door strikes deal 15% more damage.","category":"offense"},
 "soul_hunger":{"name":"Soul Hunger","effect":"Recover 4% maximum HP on this and future genuine kills, capped at current maximum.","category":"armor"},
 "rapid_recovery":{"name":"Rapid Recovery","effect":"Archetype and Reaper ability cooldowns recover 12% faster.","category":"offense"},
 "shadow_step":{"name":"Shadow Step","effect":"Approach conceals the Hunter for 1.5s every 12s.","category":"movement"},
 "ruthless_pursuit":{"name":"Ruthless Pursuit","effect":"After 8s of pursuit, move 10% faster until contact.","category":"movement"},
 "cursed_armor":{"name":"Cursed Armor","effect":"After each kill gain a finite 5% maximum-HP shield for 8s.","category":"armor"},
 "savage_strike":{"name":"Savage Strike","effect":"Telegraphed special attacks deal 12% more damage.","category":"offense"},
 "dread_aura":{"name":"Dread Aura","effect":"The currently besieged room produces 12% less income and power.","category":"resource"},
 "undead_commander":{"name":"Undead Commander","effect":"Reaper undead gain 15% HP and damage; dormant until transformation.","category":"command"},
 "soul_drain":{"name":"Soul Drain","effect":"Every 20s of door contact drains at most 8 Gold and 2 Electricity.","category":"resource"},
 "relentless_siege":{"name":"Relentless Siege","effect":"After 8s at a door, attacks recover a further 8% faster.","category":"offense"},
 "deaths_momentum":{"name":"Death's Momentum","effect":"For 8s after a genuine kill gain 15% movement and 10% attack recovery.","category":"movement"}}
var credited: Dictionary={}
var acquired: Array=[]
var shield=0.0
var shield_remaining=0.0
var momentum=0.0
var shadow_cooldown=0.0
var drain_clock=0.0
func has(id: String) -> bool:return id in acquired
func award(model,room_index: int,source: String) -> String:
 if room_index<0 or room_index>=model.rooms.size() or model._kill_credit_room!=room_index or source not in ["Hunter","Undead"]:return ""
 var room=model.rooms[room_index]
 if room.alive:return ""
 var key="owner:%d" % room.owner
 if room.owner<0 or credited.has(key) or credited.size()>=6 or model.tutorial_mode:return ""
 credited[key]=room_index
 var pool=[]
 for id in BUFFS:
  if not has(id) and (id!="undead_commander" or model.hunter.boss_policy.get("enabled",false)) and (id!="shadow_step" or not model.hunter.transformed):pool.append(id)
 if pool.is_empty():return ""
 var id=pool[model.random.randi_range(0,pool.size()-1)];acquired.append(id)
 if has("soul_hunger") and model.hunter.hp>0:model.hunter.hp=minf(model.hunter.max_hp,model.hunter.hp+model.hunter.max_hp*.04)
 if has("cursed_armor"):shield=model.hunter.max_hp*.05;shield_remaining=8
 if has("deaths_momentum"):momentum=8
 var data=BUFFS[id].duplicate(true);data.merge({"buff_id":id,"buff_name":data.name,"source":source,"victim_room":room_index,"power":acquired.size()})
 model.record_event("hunter_evolved",room_index,data)
 return id
func tick(delta: float,model):
 shield_remaining=maxf(0,shield_remaining-delta);momentum=maxf(0,momentum-delta);shadow_cooldown=maxf(0,shadow_cooldown-delta)
 if shield_remaining<=0:shield=0
 for r in model.rooms:r.threat_income_factor=1.0;r.threat_power_factor=1.0
 var h=model.hunter
 if h.hp<=0:return
 if has("shadow_step") and h.state==HunterState.State.MOVE and shadow_cooldown<=0 and not h.transformed:
  h.conceal_remaining=maxf(h.conceal_remaining,1.5);shadow_cooldown=12
  model.record_event("hunter_ability",h.target,{"ability":"conceal","duration":1.5})
 if h.target>=0 and h.state==HunterState.State.ATTACK and h.position.distance_to(model.rooms[h.target].door_approach())<=3:
  if has("dread_aura"):model.rooms[h.target].threat_income_factor=.88;model.rooms[h.target].threat_power_factor=.88
  if has("soul_drain"):
   drain_clock+=delta
   if drain_clock>=20:
    drain_clock=fmod(drain_clock,20);var r=model.rooms[h.target];var g=minf(8,r.gold);var e=minf(2,r.electricity);r.gold-=g;r.electricity-=e
    model.record_event("soul_drain",h.target,{"gold":g,"power":e})
func absorb(amount: float) -> float:
 amount*=.9 if has("iron_skin") else 1.0
 var block=minf(amount,shield);shield-=block
 return amount-block
func move_factor(h) -> float:
 return (1.12 if has("predator_rush") else 1.0)*(1.1 if has("ruthless_pursuit") and h.state==HunterState.State.MOVE and h.target_time>=8 else 1.0)*(1.15 if momentum>0 else 1.0)
func interval_factor(h) -> float:
 return (.9 if has("blood_frenzy") else 1.0)*(.92 if has("relentless_siege") and h.siege_seconds>=8 else 1.0)*(.9 if momentum>0 else 1.0)
func damage_factor(special: bool=false) -> float:return (1.15 if has("door_crusher") else 1.0)*(1.12 if special and has("savage_strike") else 1.0)
func cooldown_factor() -> float:return 1.0/.88 if has("rapid_recovery") else 1.0
func snapshot() -> Dictionary:return {"credited":credited.duplicate(true),"acquired":acquired.duplicate(),"shield":shield,"shield_remaining":shield_remaining,"momentum":momentum,"shadow_cooldown":shadow_cooldown,"drain_clock":drain_clock}
static func valid(data,rooms: Array) -> bool:
 if not data is Dictionary or not data.get("credited") is Dictionary or not data.get("acquired") is Array or data.credited.size()>6 or data.acquired.size()!=data.credited.size():return false
 var ids=[]
 for id in data.acquired:
  if id not in BUFFS or id in ids:return false
  ids.append(id)
 var victims=[]
 for key in data.credited:
  if key not in ["owner:0","owner:1","owner:2","owner:3","owner:4","owner:5"] or not ReplaySnapshot.whole(data.credited[key],0,5):return false
  var i=int(data.credited[key]);var r=rooms[i]
  if i in victims or r.alive or key!="owner:%d" % int(r.owner):return false
  victims.append(i)
 for key in ["shield","shield_remaining","momentum","shadow_cooldown","drain_clock"]:
  if not ReplaySnapshot.number(data.get(key),0,1e12):return false
 return data.shield_remaining<=8 and data.momentum<=8 and data.shadow_cooldown<=12 and data.drain_clock<=20
func restore(data: Dictionary):
 credited=data.credited.duplicate(true);acquired=data.acquired.duplicate()
 for key in ["shield","shield_remaining","momentum","shadow_cooldown","drain_clock"]:set(key,float(data[key]))
