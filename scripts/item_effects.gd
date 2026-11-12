class_name ItemEffects
extends RefCounted
var timers: Dictionary={}
var shield_hp=0.0
var trap: Dictionary={}
var cooldown=0.0
var events: Array=[]
var serial=0
func emit_item(id: String,model,value=0.0,phase="activate"):
 serial+=1
 events.append({"id":serial,"item":id,"phase":phase,"value":value,"age":0.0,"position":model.player().door_position() if model.player()!=null else model.hunter.position})
 if events.size()>24: events.pop_front()
func can_activate(id: String,model) -> String:
 if not ItemCatalog.ITEMS.has(id): return "Unknown item."
 if not model.running or model.result!="": return "Items require an active, unpaused match."
 var room=model.player()
 if room==null or not room.alive or not room.sleeping: return "Occupy your bed first."
 if cooldown>0: return "Wait for the item cooldown."
 if float(timers.get(id,0))>0: return "That effect is already active."
 if id=="repair" and (room.door_hp<=0 or room.door_hp>=room.max_hp()): return "An intact damaged door is required."
 if id=="shield" and (room.door_hp<=0 or not room.closed): return "Shield requires an intact closed door."
 if id in ["frost","trap","radar"] and (model.hunter.hp<=0 or model.hunter.state==HunterState.State.DORMANT): return "Wait until the Hunter arrives."
 if id=="overdrive":
  var found=false
  for b in room.buildings.values():
   if b.kind in ["turret","heavy"]: found=true
  if not found: return "Build a turret first."
 if id=="trap":
  if not trap.is_empty(): return "A trap is already deployed."
  if not model.navigation_walkable(room.door_approach()): return "No safe doorway trap position."
 return ""
func apply(id: String,model):
 var room=model.player()
 var value=0.0
 cooldown=ItemCatalog.TUNING.global_cooldown
 match id:
  "repair":
   value=minf(room.max_hp()-room.door_hp,room.max_hp()*ItemCatalog.TUNING.repair_fraction)
   room.door_hp+=value
  "gold": room.gold+=ItemCatalog.TUNING.gold; value=ItemCatalog.TUNING.gold
  "battery": room.electricity+=ItemCatalog.TUNING.battery; value=ItemCatalog.TUNING.battery
  "radar": timers[id]=ItemCatalog.TUNING.radar_seconds
  "shield": timers[id]=ItemCatalog.TUNING.shield_seconds; shield_hp=room.max_hp()*ItemCatalog.TUNING.shield_fraction; value=shield_hp
  "overdrive": timers[id]=ItemCatalog.TUNING.overdrive_seconds
  "frost": timers[id]=ItemCatalog.TUNING.frost_seconds
  "trap": trap={"position":room.door_approach(),"remaining":ItemCatalog.TUNING.trap_seconds}
 emit_item(id,model,value)
func absorb(amount: float,model) -> float:
 if shield_hp<=0 or float(timers.get("shield",0))<=0 or model.hunter.target!=model.player_room: return amount
 var absorbed=minf(shield_hp,amount)
 shield_hp-=absorbed
 emit_item("shield",model,absorbed,"absorb")
 if shield_hp<=0: timers.erase("shield"); emit_item("shield",model,0,"end")
 return amount-absorbed
func speed_factor(hunter) -> float:
 return (ItemCatalog.TUNING.reaper_frost_factor if hunter.transformed else ItemCatalog.TUNING.frost_factor) if float(timers.get("frost",0))>0 else 1.0
func tick(delta: float,model):
 cooldown=maxf(0,cooldown-delta)
 for event in events: event.age+=delta
 events=events.filter(func(e):return e.age<2.0)
 for id in timers.keys():
  timers[id]=maxf(0,timers[id]-delta)
  if timers[id]<=0:
   timers.erase(id)
   if id=="shield": shield_hp=0
   emit_item(id,model,0,"end")
 if not trap.is_empty():
  trap.remaining-=delta
  if trap.remaining<=0:
   trap.clear(); emit_item("trap",model,0,"end")
  else: trigger_segment(model.hunter.position,model.hunter.position,model)
func trigger_segment(from: Vector2,to: Vector2,model):
 if trap.is_empty() or model.hunter.hp<=0 or model.hunter.state in [HunterState.State.DORMANT,HunterState.State.DEAD]: return
 var closest=Geometry2D.get_closest_point_to_segment(trap.position,from,to)
 if closest.distance_to(trap.position)>ItemCatalog.TUNING.trap_radius: return
 var point=trap.position
 trap.clear() # Remove before damage, so repeated ticks cannot retrigger.
 var hp=model.hunter.hp
 model.hunter.hurt(ItemCatalog.TUNING.trap_damage)
 var applied=hp-model.hunter.hp
 if model.player()!=null: model.player().damage_dealt+=applied
 model.damage_dealt+=applied
 emit_item("trap",model,applied,"explode")
 events[-1].position=point
func clear(model):
 for id in timers.keys(): emit_item(id,model,0,"end")
 if not trap.is_empty(): emit_item("trap",model,0,"end")
 timers.clear(); trap.clear(); shield_hp=0; cooldown=0
