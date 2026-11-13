class_name DefenseEffects
extends RefCounted
const WEAPONS=["turret","heavy","flame","frost","shock"]
const SPECIAL=["flame","frost","shock","auto_repair","shield","decoy"]
# Status pools contain only currently-live target IDs; no permanent growth.
var burns: Dictionary={}
var shield_cooldowns: Dictionary={}
var repair_cooldowns: Dictionary={}
var lure_cooldown=0.0
var lure_remaining=0.0
var lure_room=-1
var lure_tile=-1
var lure_instance=-1
func stats(room,b: Dictionary) -> Dictionary:
 var l=float(b.level);var id=b.get("specialization","")
 match b.kind:
  "flame":return {"damage":8*l*(1.35 if id=="searing" else .72 if id=="wildfire" else 1.0),"interval":1.35/(1+(l-1)*.08),"range":190.0,"burn":12*l*(1.45 if id=="searing" else .65 if id=="wildfire" else 1.0),"duration":3.0,"targets":3 if id=="wildfire" else 1}
  "frost":return {"damage":5*l*(1.15 if id=="deep_chill" else .65 if id=="rime_field" else 1.0),"interval":1.4/(1+(l-1)*.07),"range":220.0,"slow":.3 if id=="deep_chill" else .16 if id=="rime_field" else .22,"targets":3 if id=="rime_field" else 1}
  "shock":return {"damage":24*l*(1.5 if id=="capacitor_burst" else .65 if id=="rapid_discharge" else 1.0),"interval":(4.5 if id=="capacitor_burst" else 2.4 if id=="rapid_discharge" else 3.6)/(1+(l-1)*.06),"range":155.0,"slow":.15,"targets":1}
  "auto_repair":return {"heal":(20+20*l)*(1.8 if id=="emergency_protocol" else 1.0),"interval":5.0 if id=="emergency_protocol" else 3.0,"gold":(2+l*.5)*(.7 if id=="efficient_mending" else 1.6 if id=="emergency_protocol" else 1.0),"power":(1+l*.2)*(1.5 if id=="emergency_protocol" else 1.0),"threshold":.45 if id=="emergency_protocol" else .9}
  "shield":return {"capacity":(25+14*l)*(1.5 if id=="aegis_burst" else .65 if id=="steady_veil" else 1.0),"duration":2.0 if id=="aegis_burst" else 4.0 if id=="steady_veil" else 3.0,"interval":12.0,"power":(3+l*.8)*(1.25 if id=="aegis_burst" else .8 if id=="steady_veil" else 1.0)}
  "decoy":return {"duration":(3.0 if id=="force_lure" else 4.0 if id=="faint_echo" else 2.5)*(1+(l-1)*.025),"interval":24.0-(l-1)*.5,"power":5+l*.6,"range":(240.0 if id=="force_lure" else 160.0 if id=="faint_echo" else 190.0)+(l-1)*4}
 return {}
func tick(delta: float,model):
 var active=model.attackable_targets()
 for key in burns.keys():
  var burn=burns[key];var target=model.target_by_id(int(key))
  if target==null:burns.erase(key);continue
  var applied=model.apply_target_damage(int(key),burn.dps*minf(delta,burn.remaining),burn.room,DamageRules.weapon("flame"))
  if model.run_kind=="endless":model.wave_metrics.hit(burn.room,model.player_room,int(burn.get("building_id",-1)),burn.get("kind","flame"),int(burn.get("level",1)),applied,int(key),false)
  model.credit_damage(burn.room,applied,int(key));burn.remaining=maxf(0,burn.remaining-delta)
  if burn.remaining<=0:burns.erase(key)
 for key in repair_cooldowns:repair_cooldowns[key]=maxf(0,repair_cooldowns[key]-delta)
 for key in shield_cooldowns:shield_cooldowns[key]=maxf(0,shield_cooldowns[key]-delta)
 lure_cooldown=maxf(0,lure_cooldown-delta);lure_remaining=maxf(0,lure_remaining-delta)
 for room in model.rooms:
  room.barrier_remaining=maxf(0,room.barrier_remaining-delta)
  if room.barrier_remaining<=0:room.barrier_hp=0
  if not room.alive or not room.sleeping:continue
  for tile in room.buildings:
   var b=room.buildings[tile]
   if b.kind not in ["auto_repair","shield","decoy"]:continue
   b.cooldown=maxf(0,b.cooldown-delta)
   if b.cooldown>0:continue
   var s=stats(room,b);var activated=false
   if b.kind=="auto_repair" and room.door_hp>0 and room.door_hp<room.max_hp()*s.threshold and float(repair_cooldowns.get(str(room.index),0))<=0 and room.pay(s.gold,s.power):
    var heal=minf(room.max_hp()-room.door_hp,s.heal*maxf(.65,room.repair_factor));room.door_hp+=heal;activated=heal>0;repair_cooldowns[str(room.index)]=s.interval
    model.record_event("defense_heal",room.index,{"damage":heal,"kind":b.kind})
   elif b.kind=="shield" and room.door_hp>0 and room.door_hp<room.max_hp() and model.hunter.target==room.index and float(shield_cooldowns.get(str(room.index),0))<=0 and room.pay(0,s.power):
    room.barrier_hp=s.capacity;room.barrier_remaining=s.duration;shield_cooldowns[str(room.index)]=s.interval;activated=true
   elif b.kind=="decoy" and lure_cooldown<=0 and not model.wrath.domain_active() and model.hunter.state==HunterState.State.MOVE and room.door_hp>0 and model.hunter.position.distance_to(room.door_approach())<s.range and model.navigation_walkable(room.door_approach()) and room.pay(0,s.power):
    lure_room=room.index;lure_tile=tile;lure_instance=int(b.get("instance_id",0));lure_remaining=s.duration*(.5 if model.hunter.transformed else 1.0);lure_cooldown=s.interval;activated=true
   if activated:
    b.cooldown=s.interval;model.record_event("defense_activate",room.index,{"kind":b.kind,"level":b.level,"specialization":b.get("specialization",""),"duration":s.get("duration",0.0)})
func lure_tick(delta: float,model) -> bool:
 if lure_remaining<=0 or lure_room<0 or lure_room>=model.rooms.size() or model.wrath.domain_active():return false
 var room=model.rooms[lure_room];var h=model.hunter
 if not room.alive or not room.buildings.has(lure_tile) or room.buildings[lure_tile].kind!="decoy" or int(room.buildings[lure_tile].get("instance_id",0))!=lure_instance or h.state not in [HunterState.State.MOVE,HunterState.State.ATTACK]:lure_remaining=0;return false
 # A real finite diversion to a valid doorway; never move through closed walls.
 h.cancel_boss_attack();h.state=HunterState.State.MOVE
 h.position=model.step_navigation(h.position,room.door_approach(),h.speed*delta,"building_decoy")
 return true
func ignite(id: int,dps: float,seconds: float,room: int,building_id: int=-1,kind="flame",level=1):
 var key=str(id)
 if burns.has(key):
  if dps>burns[key].dps:burns[key].dps=dps;burns[key].room=room;burns[key].building_id=building_id;burns[key].kind=kind;burns[key].level=level
  burns[key].remaining=maxf(burns[key].remaining,seconds);return
 burns[key]={"building_id":building_id,"kind":kind,"level":level,"dps":dps,"remaining":seconds,"room":room}
func removed(room: int,tile: int):
 if lure_room==room and lure_tile==tile:lure_remaining=0;lure_instance=-1
func burn_dps(id: int) -> float:return float(burns.get(str(id),{}).get("dps",0.0))
func clear(model):
 burns.clear();lure_remaining=0;lure_room=-1;lure_tile=-1;lure_instance=-1
 for r in model.rooms:r.barrier_hp=0;r.barrier_remaining=0
 model._navigation_routes.erase("building_decoy")
