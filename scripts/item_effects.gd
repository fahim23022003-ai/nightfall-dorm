class_name ItemEffects
extends RefCounted
var timers: Dictionary={}
var shield_hp=0.0
var trap: Dictionary={}
var cooldown=0.0
var events: Array=[]
var serial=0
var profile_ref: WeakRef
var match_id=0
var feather_used=false
var rescue_target=-1
var burn_remaining=0.0
var pillow_display_total=0.0
var pillow_display_clock=0.0
var control_recovery=0.0
var decoy_point=Vector2.ZERO
var legendary_used=0
var guardian_shield_hp=0.0
var frozen_delta=0.0
var curse_frame_fraction=0.0
func guardian_intercept(amount: float,model,victim: int=-1) -> bool:
 var r=model.player()
 if victim>=0 and victim!=model.player_room:return false
 if r==null or not model.running or model.result!="" or not r.alive or not r.sleeping or not r.closed or r.door_hp<=0 or amount<r.door_hp: return false
 if legendary_used>=ItemCatalog.TUNING.legendary_limit: return false
 if not consume("guardian_heart",model): return false
 legendary_used+=1
 r.door_hp=r.max_hp()*ItemCatalog.TUNING.heart_fraction
 guardian_shield_hp=r.max_hp()*ItemCatalog.TUNING.heart_shield_fraction
 timers["guardian_heart"]=ItemCatalog.TUNING.heart_shield_seconds
 emit_item("guardian_heart",model,r.door_hp)
 return true
func seal_valid(model) -> bool:
 var h=model.hunter
 if not model.wrath.scythe.is_empty() and model.wrath.scythe.room==model.player_room:return true
 if model.wrath.active() and h.transformed and (model.wrath.cast_target==model.player_room or model.wrath.ability in ["phantom_scream","rules_judgement","final_judgement"]):return true
 if h.hp<=0 or not h.transformed or h.state!=HunterState.State.ATTACK or not BossCatalog.ATTACKS.has(h.boss_attack) or h.cooldown<=0 or h.boss_attack_target!=h.target: return false
 if h.target<0 or h.target>=model.rooms.size(): return false
 var r=model.rooms[h.target]
 return r.alive and r.sleeping and r.closed and r.door_hp>0 and h.position.distance_to(r.door_approach() if model.map_id!="legacy" else r.door_position()+Vector2(0,22 if h.target<3 else -22))<3

func consume(id: String,model) -> bool:
 return profile_ref!=null and profile_ref.get_ref()!=null and profile_ref.get_ref().consume_item(id,model,match_id)
func feather_cross(old_hp: float,model):
 var r=model.player()
 if r==null or feather_used or not r.alive or r.door_hp<=0: return
 if old_hp<=r.max_hp()*ItemCatalog.TUNING.feather_threshold or r.door_hp>r.max_hp()*ItemCatalog.TUNING.feather_threshold: return
 if not consume("feather",model): return
 feather_used=true
 var healed=minf(r.max_hp()-r.door_hp,r.max_hp()*ItemCatalog.TUNING.feather_fraction)
 r.door_hp+=healed
 emit_item("feather",model,healed)
func ignite(model,room_index: int):
 if room_index==model.player_room and float(timers.get("inferno",0))>0 and model.hunter.hp>0: burn_remaining=ItemCatalog.TUNING.burn_seconds
func decoy_tick(delta: float,model) -> bool:
 var h=model.hunter
 if float(timers.get("decoy",0))<=0 or h.state in [HunterState.State.TRANSFORM,HunterState.State.DEAD,HunterState.State.DORMANT,HunterState.State.BREACH,HunterState.State.EXIT]: return false
 h.cancel_boss_attack()
 var previous=h.position
 h.position=model.step_navigation(h.position,decoy_point,h.speed*delta,"item_decoy") if model.map_id!="legacy" else h.position.move_toward(decoy_point,h.speed*delta)
 trigger_segment(previous,h.position,model)
 if h.hp>0: h.state=HunterState.State.MOVE
 return true

func emit_item(id: String,model,value=0.0,phase="activate"):
 serial+=1
 events.append({"id":serial,"item":id,"phase":phase,"value":value,"age":0.0,"position":model.player().door_position() if model.player()!=null else model.hunter.position})
 if events.size()>24: events.pop_front()
func can_activate(id: String,model) -> String:
 if not ItemCatalog.ITEMS.has(id): return "Unknown item."
 if not model.running or model.result!="": return "Items require an active, unpaused match."
 if model.run_kind=="endless" and model.endless!=null and model.endless.phase=="intermission":return "Continue the next wave before activating items."
 var room=model.player()
 if room==null or not room.alive or not room.sleeping: return "Occupy your bed first."
 if ItemCatalog.legendary(id) and legendary_used>=ItemCatalog.TUNING.legendary_limit: return "Legendary power already used this match."
 if model.wrath.rules_remaining>0:return "Rules Judgement: manual items locked for %.1fs." % model.wrath.rules_remaining
 if model.wrath.domain_active() and model.wrath.domain_room!=model.player_room and id in ["time_freeze","frost","trap","decoy","smoke","reaper_seal"]:return "Crimson Domain: only the duelling room may disrupt the Reaper."
 if id=="guardian_heart": return "Automatic: equipped Heart intercepts one lethal door hit."
 if id=="reaper_seal" and not seal_valid(model): return "Wait for a telegraphed Reaper special attack."
 if id in ["time_freeze","cursed_fortune"] and (model.hunter.hp<=0 or model.hunter.state in [HunterState.State.DORMANT,HunterState.State.DEAD]): return "Wait until the Hunter arrives."
 if id=="time_freeze" and control_recovery>0: return "Hunter control recovery is still active."
 if cooldown>0: return "Wait for the item cooldown."
 if float(timers.get(id,0))>0: return "That effect is already active."
 if id=="feather": return "Automatic: equip it; an intact door crossing 25% HP triggers once per match."
 if id=="coupon" and room.coupon_armed: return "Coupon already armed; complete one building purchase or upgrade."
 if id=="barricade" and (room.door_hp<=0 or not room.closed): return "An intact closed door is required."
 if id=="inferno" and not room.buildings.values().any(func(b):return b.kind in DefenseEffects.WEAPONS): return "Build a turret first."
 if id in ["decoy","smoke"] and (control_recovery>0 or model.hunter.state in [HunterState.State.DORMANT,HunterState.State.DEAD,HunterState.State.TRANSFORM,HunterState.State.BREACH,HunterState.State.EXIT]): return "Target disruption unavailable during this state or recovery."
 if id=="decoy" and not model.navigation_walkable(room.door_approach()): return "No reachable decoy position."
 if id=="rescue":
  if rescue_target<0 or rescue_target>=model.rooms.size(): return "Select a valid teammate."
  var other=model.rooms[rescue_target]
  if other.owner<=0 or not other.alive or not other.closed or other.door_hp<=0 or other.door_hp>=other.max_hp(): return "Select a living teammate with an intact damaged door."
 if id=="repair" and (room.door_hp<=0 or room.door_hp>=room.max_hp()): return "An intact damaged door is required."
 if id=="shield" and (room.door_hp<=0 or not room.closed): return "Shield requires an intact closed door."
 if id in ["frost","trap","radar"] and (model.hunter.hp<=0 or model.hunter.state==HunterState.State.DORMANT): return "Wait until the Hunter arrives."
 if id=="overdrive":
  var found=false
  for b in room.buildings.values():
   if b.kind in DefenseEffects.WEAPONS: found=true
  if not found: return "Build a turret first."
 if id=="trap":
  if not trap.is_empty(): return "A trap is already deployed."
  if not model.navigation_walkable(room.door_approach()): return "No safe doorway trap position."
 return ""
func apply(id: String,model):
 var room=model.player()
 var value=0.0
 cooldown=ItemCatalog.TUNING.global_cooldown
 if ItemCatalog.legendary(id): legendary_used+=1
 match id:
  "time_freeze":
   timers[id]=ItemCatalog.TUNING.boss_freeze_seconds if model.hunter.transformed else ItemCatalog.TUNING.freeze_seconds
   control_recovery=ItemCatalog.TUNING.control_refractory
  "reaper_seal":
   model.wrath.interrupt(model,"Reaper Seal")
   model.wrath.counter_scythe(model)
   model.hunter.cancel_boss_attack()
   model.hunter.cooldown=maxf(model.hunter.cooldown,ItemCatalog.TUNING.seal_recovery)
   timers[id]=model.hunter.cooldown
  "cursed_fortune":
   room.gold+=ItemCatalog.TUNING.fortune_gold
   value=ItemCatalog.TUNING.fortune_gold
   timers[id]=ItemCatalog.TUNING.curse_seconds
  "barricade": timers[id]=ItemCatalog.TUNING.barricade_seconds
  "inferno": timers[id]=ItemCatalog.TUNING.inferno_seconds
  "pillow": timers[id]=ItemCatalog.TUNING.pillow_seconds; room.temporary_income=ItemCatalog.TUNING.pillow_factor
  "coupon": room.coupon_armed=true; cooldown=0
  "decoy":
   timers[id]=ItemCatalog.TUNING.boss_decoy_seconds if model.hunter.transformed else ItemCatalog.TUNING.decoy_seconds
   control_recovery=ItemCatalog.TUNING.control_refractory
   decoy_point=room.door_approach()
  "smoke":
   timers[id]=ItemCatalog.TUNING.boss_smoke_seconds if model.hunter.transformed else ItemCatalog.TUNING.smoke_seconds
   control_recovery=ItemCatalog.TUNING.control_refractory
   if model.hunter.target==model.player_room:
    var alternative=model.hunter.choose_target(model.rooms,model.player_room)
    if alternative>=0 and alternative!=model.player_room:
     model.hunter.cancel_boss_attack()
     model.hunter.target=alternative
     model.hunter.state=HunterState.State.MOVE
  "rescue":
   var teammate=model.rooms[rescue_target]
   value=minf(teammate.max_hp()-teammate.door_hp,teammate.max_hp()*ItemCatalog.TUNING.rescue_fraction)
   teammate.door_hp+=value
   model.record_event("item_rescue",rescue_target,{"damage":value})
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
 if id=="rescue": events[-1].position=model.rooms[rescue_target].door_position()
func absorb(amount: float,model,victim: int=-1) -> float:
 if victim<0:victim=model.hunter.target
 if victim==model.player_room and float(timers.get("barricade",0))>0:
  var prevented=amount*(1-ItemCatalog.TUNING.barricade_factor)
  amount-=prevented
  emit_item("barricade",model,prevented,"absorb")
 if guardian_shield_hp>0 and float(timers.get("guardian_heart",0))>0 and victim==model.player_room:
  var blocked=minf(guardian_shield_hp,amount)
  guardian_shield_hp-=blocked
  amount-=blocked
  if blocked>0: emit_item("guardian_heart",model,blocked,"absorb")
 if shield_hp<=0 or float(timers.get("shield",0))<=0 or victim!=model.player_room: return amount
 var absorbed=minf(shield_hp,amount)
 shield_hp-=absorbed
 emit_item("shield",model,absorbed,"absorb")
 if shield_hp<=0: timers.erase("shield"); emit_item("shield",model,0,"end")
 return amount-absorbed
func speed_factor(hunter) -> float:
 return (ItemCatalog.TUNING.reaper_frost_factor if hunter.transformed else ItemCatalog.TUNING.frost_factor) if float(timers.get("frost",0))>0 else 1.0
func tick(delta: float,model):
 frozen_delta=minf(delta,float(timers.get("time_freeze",0)))
 curse_frame_fraction=minf(delta,float(timers.get("cursed_fortune",0)))/delta if delta>0 else 0.0
 if model.player()!=null:
  var r=model.player()
  r.item_bonus_income=r.income_rate()/r.temporary_income*(ItemCatalog.TUNING.pillow_factor-1)*minf(delta,float(timers.get("pillow",0)))
  if r.item_bonus_income>0:
   pillow_display_total+=r.item_bonus_income
   pillow_display_clock+=delta
   if pillow_display_clock>=1 or delta>=float(timers.get("pillow",0)):
    emit_item("pillow",model,pillow_display_total,"income")
    pillow_display_total=0; pillow_display_clock=0
 control_recovery=maxf(0,control_recovery-delta)
 if burn_remaining>0 and model.hunter.hp>0:
  var dps=ItemCatalog.TUNING.burn_dps*(ItemCatalog.TUNING.burn_boss_factor if model.hunter.transformed else 1.0)
  var damage=minf(delta,burn_remaining)*maxf(0,dps-model.defenses.burn_dps(1))
  if model.wrath.domain_active() and model.wrath.domain_room!=model.player_room:damage=0
  var old=model.hunter.hp
  model.apply_target_damage(1,damage,model.player_room,DamageRules.weapon("inferno"))
  var dealt=old-model.hunter.hp
  if model.player()!=null: model.player().damage_dealt+=dealt
  model.damage_dealt+=dealt
  burn_remaining=maxf(0,burn_remaining-delta)
 cooldown=maxf(0,cooldown-delta)
 for event in events: event.age+=delta
 events=events.filter(func(e):return e.age<2.0)
 for id in timers.keys():
  timers[id]=maxf(0,timers[id]-delta)
  if timers[id]<=0:
   timers.erase(id)
   if id=="shield": shield_hp=0
   if id=="guardian_heart": guardian_shield_hp=0
   if id=="pillow" and model.player()!=null: model.player().temporary_income=1.0
   emit_item(id,model,0,"end")
 if not trap.is_empty():
  trap.remaining-=delta
  if trap.remaining<=0:
   trap.clear(); emit_item("trap",model,0,"end")
  else: trigger_segment(model.hunter.position,model.hunter.position,model)
func trigger_segment(from: Vector2,to: Vector2,model):
 if model.wrath.domain_active() and model.wrath.domain_room!=model.player_room:return
 if trap.is_empty() or model.hunter.hp<=0 or model.hunter.state in [HunterState.State.DORMANT,HunterState.State.DEAD]: return
 var closest=Geometry2D.get_closest_point_to_segment(trap.position,from,to)
 if closest.distance_to(trap.position)>ItemCatalog.TUNING.trap_radius: return
 var point=trap.position
 trap.clear() # Remove before damage, so repeated ticks cannot retrigger.
 var hp=model.hunter.hp
 model.apply_target_damage(1,ItemCatalog.TUNING.trap_damage,model.player_room,DamageRules.weapon("trap"))
 var applied=hp-model.hunter.hp
 if model.player()!=null: model.player().damage_dealt+=applied
 model.damage_dealt+=applied
 emit_item("trap",model,applied,"explode")
 events[-1].position=point
func clear(model):
 for id in timers.keys(): emit_item(id,model,0,"end")
 if not trap.is_empty(): emit_item("trap",model,0,"end")
 if model.player()!=null:
  model.player().temporary_income=1.0
  model.player().coupon_armed=false
 guardian_shield_hp=0; frozen_delta=0; curse_frame_fraction=0
 timers.clear(); trap.clear(); shield_hp=0; cooldown=0; burn_remaining=0; control_recovery=0; pillow_display_total=0; pillow_display_clock=0
