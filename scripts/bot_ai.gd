class_name BotAI
extends RefCounted
# Autonomous budgets retain original L4 machines/L5 structures; player late tiers are optional investments.

static func tick(room: RoomState, delta: float):
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
