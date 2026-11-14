class_name BotAI
extends RefCounted
# Autonomous budgets retain original L4 machines/L5 structures; player late tiers are optional investments.

static func tick(room: RoomState, delta: float,model=null):
 if room.balance_version==2:
  earned_tick(room,delta,model);return
 if not room.alive or not room.sleeping:
  return
 room.bot_timer = maxf(-delta,room.bot_timer-delta)
 if room.bot_timer > 0:
  return
 var profile = Catalog.AI_PROFILES.get(room.profile,Catalog.AI_PROFILES.balanced)
 room.bot_timer += profile.interval
 # Preserve income for upgrades unless the door is close to breaking.
 if room.door_hp < room.max_hp()*0.25:
  if upgrade_structure(room,"door") or room.repair_door():
   return
 if room.bed_level < 1:
  upgrade_structure(room,"bed")
  return
 if room.door_level < 1:
  upgrade_structure(room,"door")
  return
 # A damage source and power supply are prerequisites for every strategy.
 for essential in ["turret","generator"]:
  if not has_kind(room,essential):
   build_first_empty(room,essential)
   return
 # Save deliberately; buying every cheaper utility would starve these goals.
 if room.bed_level < 2:
  upgrade_structure(room,"bed")
  return
 if room.door_level < 2:
  upgrade_structure(room,"door")
  return
 # A repair station reduces manual gold drain before long-term investments.
 if not has_kind(room,"repair"):
  build_first_empty(room,"repair")
  return
 if room.profile == "guard" and room.door_level < profile.door_goal:
  upgrade_structure(room,"door")
  return
 if room.bed_level < profile.bed_goal:
  if room.door_level < maxi(0,room.bed_level-1):
   upgrade_structure(room,"door")
  else:
   upgrade_structure(room,"bed")
  return
 if room.door_level < profile.door_goal:
  if room.bed_level < maxi(0,room.door_level-1):
   upgrade_structure(room,"bed")
  else:
   upgrade_structure(room,"door")
  return
 for kind in profile.priorities:
  if not has_kind(room,kind):
   build_first_empty(room,kind)
   return
 if room.profile == "gunner":
  for tile in room.buildings:
   if room.buildings[tile].kind in ["turret","heavy"] and room.buildings[tile].level < mini(4,Catalog.BUILDING_MAX_LEVEL):
    room.upgrade_building(tile)
    return
 if room.bed_level < mini(4,Catalog.BED_INCOME.size()-1):
  if room.door_level < maxi(0,room.bed_level-1):
   upgrade_structure(room,"door")
  else:
   upgrade_structure(room,"bed")
  return
 if room.door_level < mini(4,Catalog.DOOR_HP.size()-1):
  upgrade_structure(room,"door")
  return
 for tile in room.buildings:
  if room.buildings[tile].level < mini(4,Catalog.BUILDING_MAX_LEVEL):
   room.upgrade_building(tile)
   return

static func has_kind(room: RoomState, kind: String) -> bool:
 for building in room.buildings.values():
  if building.kind == kind:
   return true
 return false

static func build_first_empty(room: RoomState, kind: String) -> bool:
 for tile in range(room.tile_count()):
  if not room.buildings.has(tile):
   return room.build(kind,tile)
 return false

static func upgrade_structure(room,kind: String) -> bool:
 var level=room.bed_level if kind=="bed" else room.door_level
 var branch=room.bed_branch if kind=="bed" else room.door_branch
 if room.strategy_enabled and level==4 and branch=="":return room.specialize_structure(kind,"lucid" if kind=="bed" else "bulwark")
 return room.upgrade_bed() if kind=="bed" else room.upgrade_door()

static func earned_tick(r,delta,model=null):
 if not r.alive or not r.sleeping:return
 r.bot_timer-=delta
 if r.bot_timer>0:return
 r.bot_timer=1.2
 if model!=null and model.difficulty!="standard" and model.run_kind in ["campaign","endless"]:
  tactical_earned(r,model);return
 if r.door_hp<r.max_hp()*.35:
  if upgrade_structure(r,"door") or r.repair_door():return
 if not has_kind(r,"turret") and build_first_empty(r,"turret"):return
 if r.bed_level<1 and upgrade_structure(r,"bed"):return
 if r.door_level<1 and upgrade_structure(r,"door"):return
 if not has_kind(r,"generator"):
  build_first_empty(r,"generator");return
 var cap=mini(8,2+int(r.occupied_seconds/180))
 if r.bed_level<cap and r.bed_level<=r.door_level+1 and upgrade_structure(r,"bed"):return
 if r.door_level<cap and upgrade_structure(r,"door"):return
 for kind in ["repair","heavy","economy","enhancer"]:
  if not has_kind(r,kind) and build_first_empty(r,kind):return
 for id in r.buildings:
  var b=r.buildings[id]
  if b.level>=mini(8,r.bed_level+2) or BalanceRules.requirement(b.kind,b.level,r.bed_level,r.door_level,2)!="":continue
  if b.level==4:r.specialize_building(id,StrategyCatalog.branches(b.kind)[0])
  else:r.upgrade_building(id)
  return

# Hard-mode allies use the same funds/prerequisites; react to visible siege rather
# than buying all four support types before upgrading their only weapon.
static func tactical_earned(r,m):
 var threatened=m.hunter.target==r.index and m.hunter.state==HunterState.State.ATTACK
 if threatened and r.door_hp<r.max_hp()*.70 and upgrade_structure(r,"door"):return
 if threatened and r.door_hp<r.max_hp()*.60 and r.max_hp()-r.door_hp>=Catalog.REPAIR_HEAL*r.repair_factor and r.repair_door():return
 if not has_kind(r,"turret") and tactical_build(r,"turret"):return
 if r.bed_level<1 and upgrade_structure(r,"bed"):return
 if r.door_level<1 and upgrade_structure(r,"door"):return
 if r.bed_level<2 and upgrade_structure(r,"bed"):return
 if r.door_level<2 and upgrade_structure(r,"door"):return
 if not has_kind(r,"generator"):
  tactical_build(r,"generator");return
 for id in r.buildings:
  if r.buildings[id].kind=="turret" and r.buildings[id].level<2 and r.upgrade_building(id):return
 if not has_kind(r,"repair") and tactical_build(r,"repair"):return
 var counter="frost" if r.profile in ["guard","engineer"] else "flame" if r.profile=="gunner" else "heavy"
 if not has_kind(r,counter) and tactical_build(r,counter):return
 var cap=mini(8,3+int(r.occupied_seconds/180))
 if r.bed_level<cap and upgrade_structure(r,"bed"):return
 if r.door_level<cap and upgrade_structure(r,"door"):return
 for id in r.buildings:
  var b=r.buildings[id]
  if b.level>=mini(8,r.bed_level+2) or BalanceRules.requirement(b.kind,b.level,r.bed_level,r.door_level,2)!="":continue
  if b.level==4:
   if r.specialize_building(id,StrategyCatalog.branches(b.kind)[0]):return
  elif r.upgrade_building(id):return

static func tactical_build(r,kind: String) -> bool:
 if kind not in DefenseEffects.WEAPONS:return build_first_empty(r,kind)
 var tiles=[]
 for id in range(r.tile_count()):
  if not r.buildings.has(id):tiles.append(id)
 tiles.sort_custom(func(a,b):return r.tile_position(a).distance_to(r.door_approach())<r.tile_position(b).distance_to(r.door_approach()))
 for id in tiles:
  if r.build(kind,id):return true
 return false
