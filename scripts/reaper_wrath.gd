class_name ReaperWrath
extends RefCounted
# One finite cast at a time; old boss attacks remain the contact fallback.
const ABILITIES={
 "summon":{"name":"Spawn Undead","warning":1.5,"cooldown":24.0},
 "assault":{"name":"Undead Assault","warning":2.6,"cooldown":60.0},
 "soul_steal":{"name":"Soul Steal","warning":3.0,"cooldown":32.0},
 "scythe_slash":{"name":"Scythe Slash","warning":1.8,"cooldown":18.0},
 "rules_judgement":{"name":"Rules Judgement","warning":2.0,"cooldown":36.0},
 "eternal_sacrifices":{"name":"Eternal Sacrifices","warning":2.5,"cooldown":58.0},
 "enhanced_undead":{"name":"Enhanced Undead","warning":2.0,"cooldown":30.0},
 "soul_reaper":{"name":"Soul Reaper","warning":3.5,"cooldown":65.0},
 "phantom_scream":{"name":"Phantom Scream","warning":2.2,"cooldown":34.0},
 "final_judgement":{"name":"Final Judgement","warning":2.5,"cooldown":48.0},
 "crimson_execution":{"name":"Crimson Execution","warning":3.0,"cooldown":999.0}}
var phase=1
var phase_announced=false
var final_used=false
var ability=""
var warning=0.0
var cast_target=-1
var cast_origin=Vector2.ZERO
var recovery=5.0
var cooldowns: Dictionary={}
var rules_remaining=0.0
var production_remaining=0.0
var domain_remaining=0.0
var domain_room=-1
var scythe: Dictionary={}
var counts: Dictionary={}
var last_end=""
var channel_damage=0.0
func domain_active() -> bool:return domain_remaining>0 and domain_room>=0
func active() -> bool:return ability!=""
func choose_room(model) -> int:
 var valid=[]
 for room in model.rooms:
  if room.owner>=0 and room.alive and room.sleeping and room.closed and room.door_hp>0:valid.append(room.index)
 return valid[model.random.randi_range(0,valid.size()-1)] if not valid.is_empty() else -1
func begin(id: String,model,target: int=-1) -> bool:
 if float(model.items.timers.get("reaper_seal",0))>0:return false
 if id not in ABILITIES or ability!="" or model.hunter.hp<=0 or not model.hunter.transformed or model.hunter.state==HunterState.State.TRANSFORM:return false
 if float(cooldowns.get(id,0))>0:return false
 if target<0:target=choose_room(model)
 if target<0 or target>=model.rooms.size() or not model.rooms[target].alive or model.rooms[target].door_hp<=0:return false
 if id=="final_judgement" and rules_remaining>0:return false
 if id=="rules_judgement" and production_remaining>0:return false
 if id=="crimson_execution" and final_used:return false
 if id=="eternal_sacrifices":return false
 if id=="scythe_slash":
  target=model.hunter.target
  if target<0 or model.hunter.position.distance_to(model.rooms[target].door_approach())>3:return false
 channel_damage=0;ability=id;cast_target=target;warning=ABILITIES[id].warning;cast_origin=model.hunter.position
 model.hunter.cancel_boss_attack();model.hunter.cooldown=maxf(model.hunter.cooldown,warning)
 if id=="crimson_execution":final_used=true
 model.record_event("boss_ability_warning",target,{"ability":id,"delay":warning,"name":ABILITIES[id].name})
 return true
func interrupt(model,reason: String="interrupted"):
 if ability=="":return
 var old=ability;cooldowns[old]=ABILITIES[old].cooldown;ability="";warning=0;recovery=2.0;last_end=reason
 model.record_event("boss_ability_end",cast_target,{"ability":old,"reason":reason})
func tick(delta: float,model):
 rules_remaining=maxf(0,rules_remaining-delta);production_remaining=maxf(0,production_remaining-delta);recovery=maxf(0,recovery-delta)
 for key in cooldowns:cooldowns[key]=maxf(0,cooldowns[key]-delta*model.evolution.cooldown_factor())
 if domain_active():
  domain_remaining=maxf(0,domain_remaining-delta)
  if domain_remaining<=0 or not model.rooms[domain_room].alive or model.hunter.hp<=0:end_domain(model)
  else:
   var h=model.hunter
   if h.target!=domain_room:
    h.target=domain_room;h.cancel_boss_attack();h.state=HunterState.State.MOVE
 if not scythe.is_empty():tick_scythe(delta,model)
 var h=model.hunter
 if h.hp<=0 or model.result!="":clear(model);return
 if not h.transformed or h.state==HunterState.State.TRANSFORM:return
 if not phase_announced:phase_announced=true;model.record_event("boss_phase",h.target,{"phase":1})
 if phase==1 and h.hp<=h.max_hp*.35:
  phase=2;interrupt(model,"phase change");recovery=2.0
  for u in model.minions:
   if not u.enhanced:
    u.enhanced=true;u.max_hp*=1.3;u.damage*=1.25;u.speed*=1.1
  model.record_event("boss_phase",h.target,{"phase":2})
 if not final_used and h.hp<=h.max_hp*.1:
  interrupt(model,"final threshold")
  begin("crimson_execution",model);return
 if ability!="":
  if cast_target<0 or not model.rooms[cast_target].alive or model.rooms[cast_target].door_hp<=0:interrupt(model,"target lost");return
  # Resource channels are vulnerable to real damage; no fake save/RNG checks.
  if ability in ["soul_steal","soul_reaper"] and (channel_damage>=h.max_hp*.02 or float(model.items.timers.get("time_freeze",0))>0 or h.position.distance_to(cast_origin)>55):interrupt(model,"channel disrupted");return
  warning=maxf(0,warning-maxf(0,delta-float(model.items.timers.get("time_freeze",0))))
  if warning<=0:complete(model)
  return
 if domain_active():
  if recovery<=0 and not active():begin("scythe_slash",model,domain_room)
  return
 if recovery>0 or h.state in [HunterState.State.BREACH,HunterState.State.EXIT]:return
 var choices=[]
 if phase==1:choices=["summon","scythe_slash","soul_steal","rules_judgement","assault"]
 else:choices=["enhanced_undead","soul_reaper","phantom_scream","final_judgement"]
 # Seeded rotating order, with bounded cooldowns and a recovery gap.
 var offset=model.random.randi_range(0,choices.size()-1)
 for i in range(choices.size()):
  var id=choices[(i+offset)%choices.size()]
  if id=="assault" and model.minions.size()>=8:continue
  if id in ["summon","enhanced_undead"] and model.minions.size()>=6:continue
  if id=="eternal_sacrifices" and not scythe.is_empty():continue
  if begin(id,model):break
func complete(model):
 var id=ability;ability="";warning=0;recovery=5.5;cooldowns[id]=ABILITIES[id].cooldown;counts[id]=int(counts.get(id,0))+1
 var room=model.rooms[cast_target]
 model.record_event("boss_ability_activate",cast_target,{"ability":id,"duration":30.0 if id in ["eternal_sacrifices","crimson_execution"] else 6.0})
 match id:
  "summon":model.spawn_undead(3,false)
  "assault":model.spawn_undead(10,false)
  "enhanced_undead":model.spawn_undead(4,true)
  "soul_steal":
   var g=minf(room.gold,18.0);var e=minf(room.electricity,5.0);room.gold-=g;room.electricity-=e
   room.ledger.note("loss",[g,e],"Reaper channel: "+id)
   model.record_event("boss_resource_drain",cast_target,{"gold":g,"power":e,"ability":id})
  "soul_reaper":
   var g=room.gold*.5;var e=room.electricity*.5;room.gold-=g;room.electricity-=e
   room.ledger.note("loss",[g,e],"Reaper channel: "+id)
   model.record_event("boss_resource_drain",cast_target,{"gold":g,"power":e,"ability":id})
  "scythe_slash":
   if model.hunter.target==cast_target and model.hunter.position.distance_to(room.door_approach())<=3:model.apply_room_damage(cast_target,room.max_hp()*.25,"Scythe Slash",1,true)
  "rules_judgement":rules_remaining=5
  "final_judgement":production_remaining=6
  "phantom_scream":
   for r in model.rooms:
    if r.owner>=0 and r.alive and r.sleeping and r.closed and r.door_hp>0:model.apply_room_damage(r.index,minf(r.max_hp()*.08,180),"Phantom Scream",1,true)
  "eternal_sacrifices":start_scythe(model,cast_target,false)
  "crimson_execution":
   rules_remaining=0;production_remaining=0;domain_room=cast_target;domain_remaining=30
   model.clear_minions();model._cancel_projectiles("domain begins")
   model.hunter.target=cast_target;model.hunter.state=HunterState.State.MOVE
   model.hunter._clear_tactics();start_scythe(model,cast_target,true)
func start_scythe(model,target: int,crimson: bool):
 scythe={"room":target,"remaining":30.0,"clock":0.0,"attempts":0,"crimson":crimson,"flight":.8,"from":model.hunter.position,"position":model.hunter.position}
 model.record_event("scythe_throw",target,{"position":model.hunter.position,"duration":.8,"crimson":crimson})
func tick_scythe(delta: float,model):
 var room=model.rooms[scythe.room]
 if not room.alive:end_scythe(model);return
 if scythe.flight>0:
  scythe.flight=maxf(0,scythe.flight-delta);scythe.position=scythe.from.lerp(room.door_position(),1-scythe.flight/.8)
  if scythe.flight<=0:model.record_event("scythe_embed",room.index,{"duration":30.0,"position":room.door_position(),"crimson":scythe.crimson})
  return
 scythe.remaining=maxf(0,scythe.remaining-delta);scythe.clock+=delta
 if scythe.clock>=3:
  var ward_before=room.barrier_hp>0 or room.index==model.player_room and (model.items.shield_hp>0 or model.items.guardian_shield_hp>0 or float(model.items.timers.get("reaper_seal",0))>0)
  scythe.clock=fmod(scythe.clock,3);model.apply_room_damage(room.index,minf(room.max_hp()*.035,120),"Embedded Scythe",1,true)
  model.record_event("scythe_tick",room.index,{"duration":scythe.remaining,"crimson":scythe.crimson})
  # At most three independently rolled destruction attempts; no refunds.
  if scythe.attempts<3:
   scythe.attempts+=1
   var protected=ward_before
   if protected:model.record_event("scythe_warded",room.index,{"source":"active barrier or Seal"})
   elif model.random.randf()<.12 and not room.buildings.is_empty():
    var tiles=room.buildings.keys();var tile=tiles[model.random.randi_range(0,tiles.size()-1)];room.buildings.erase(tile)
    model.record_event("building_destroyed",room.index,{"tile":tile,"source":"Embedded Scythe"})
 if scythe.remaining<=0:end_scythe(model)
func counter_scythe(model):
 if not scythe.is_empty() and scythe.room==model.player_room:end_scythe(model)
func end_scythe(model):
 if scythe.is_empty():return
 model.record_event("scythe_end",scythe.room,{});scythe.clear()
func end_domain(model):
 if domain_room>=0:model.record_event("boss_ability_end",domain_room,{"ability":"crimson_execution","reason":"domain ended"})
 domain_remaining=0;domain_room=-1;rules_remaining=0;production_remaining=0;end_scythe(model)
func clear(model):
 interrupt(model,"combat ended");end_domain(model);rules_remaining=0;production_remaining=0;model.clear_minions()
