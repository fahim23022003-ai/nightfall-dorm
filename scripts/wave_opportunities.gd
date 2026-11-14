class_name WaveOpportunities
extends RefCounted
# Read-only integration observations; never calls RNG/pay, modifies cooldowns or picks targets.
static func observe(model,delta: float):
 var room=model.player()
 if room==null or not room.alive or not room.sleeping:return
 var data=model.wave_metrics.data
 if not data.has("observations"):data.observations={}
 var main=model.attackable_targets().any(func(entry):return entry.id==1)
 for id in room.buildings:
  var b=room.buildings[id]
  if b.kind not in DefenseEffects.WEAPONS and b.kind not in ["auto_repair","shield"]:continue
  var key=str(id)
  if not data.observations.has(key) and data.observations.size()>=256:continue
  if not data.observations.has(key):data.observations[key]={"id":id,"kind":b.kind,"level":b.level,"seen":0.0,"no_target":0.0,"out":0.0,"door_out":0.0,"disabled":0.0,"ready":0.0,"cooldown":0.0,"power_low":0.0}
  var row=data.observations[key];row.seen+=delta;row.level=b.level
  if b.kind not in DefenseEffects.WEAPONS:
   var stats=model.defenses.stats(room,b)
   if room.door_hp>0 and room.door_hp<room.max_hp() and room.electricity<stats.power:row.power_low+=delta
   continue
  var state="no_target"
  if main:
   if model.wrath.rules_remaining>0 or room.magic_state.disrupt>0 or model.hunter.shadow_active(room.index) or model.wrath.domain_active() and room.index!=model.wrath.domain_room:state="disabled"
   elif room.tile_position(id).distance_to(model.hunter.position)>BuildingStats.weapon_stats(model,room,b).range*model.hunter.nightmare.range_factor(room.index):state="out"
   elif b.cooldown>0:state="cooldown"
   else:state="ready"
  row[state]+=delta
  if state=="out" and model.hunter.target==room.index and model.hunter.state==HunterState.State.ATTACK:row.door_out+=delta
static func valid(value) -> bool:
 if not value is Dictionary or value.size()>256:return false
 for key in value:
  var row=value[key]
  if not row is Dictionary or not ReplaySnapshot.whole(row.get("id"),0,SpatialConstruction.MAX_ID) or str(int(row.id))!=str(key) or row.get("kind") not in DefenseEffects.WEAPONS+["auto_repair","shield"] or not ReplaySnapshot.whole(row.get("level"),1,10):return false
  for field in ["seen","no_target","out","door_out","disabled","ready","cooldown","power_low"]:
   if not ReplaySnapshot.number(row.get(field)):return false
  if row.power_low>row.seen+.001:return false
  if row.kind in DefenseEffects.WEAPONS and absf(row.seen-row.no_target-row.out-row.disabled-row.ready-row.cooldown)>.01:return false
 return true
static func insights(data) -> Array:
 var rows=[]
 if not data.available:return ["Historical observations unavailable. No cause inferred."]
 var observations=data.get("observations",{})
 for key in observations:
  var row=observations[key];var damage=data.buildings.get(key,{}).get("damage",0)
  var name=Catalog.BUILDINGS[row.kind].name+" #%d" % row.id
  if row.power_low>1:rows.append(name+": below its Electricity activation cost for %.1fs while the door was damaged. Other activation conditions may also apply." % row.power_low)
  if row.kind not in DefenseEffects.WEAPONS or damage>0 or row.seen<1:continue
  if row.door_out>1:rows.append(name+": out of range during %.1fs of siege at your door. Inspect [O] and reposition [V] in preparation." % row.door_out)
  elif row.out>1 and row.ready==0 and row.cooldown==0:rows.append(name+": Hunter remained outside range; no in-range opportunity observed. This does not establish poor placement.")
  elif row.disabled>=row.seen*.9:rows.append(name+": targeting/fire disabled for %.1fs. Wait for the curse to clear; moving does not remove it." % row.disabled)
  elif row.no_target>=row.seen*.9:rows.append(name+": no eligible Hunter opportunity for %.1fs. Zero damage does not prove a poor placement." % row.no_target)
  else:rows.append(name+": mixed opportunities; zero recorded Hunter damage. Cause unknown—cooldown, flight time and target changes may matter.")
 if data.get("magic_blocked",0)>0:rows.push_front("Magic defense absorbed %.1f actual damage before it reached your door." % data.magic_blocked)
 if data.get("affordable_damage",0)>0 and data.repair<data.door*.75:rows.append("At intact-door damage events totaling %.1f HP, you held enough Gold for manual repair. Consider repair [R] while defending." % data.affordable_damage)
 if rows.is_empty() and data.repair>0:rows.append("Repairs restored %.1f actual door HP during this wave. Compare this support with incoming damage before changing your build." % data.repair)
 if rows.is_empty() and not data.top.is_empty() and data.total>0:
  rows.append("%s supplied %.0f%% of your room's recorded Hunter damage. Other weapons may have had fewer opportunities." % [Catalog.BUILDINGS[data.top[0].kind].name,data.top[0].damage/data.total*100])
 if rows.is_empty():rows.append("No supported strategic conclusion from this wave. No cause invented.")
 return rows.slice(0,3)
