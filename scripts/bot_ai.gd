class_name BotAI
extends RefCounted

static func tick(room: RoomState, delta: float):
 if not room.alive or not room.sleeping:
  return
 room.bot_timer -= delta
 if room.bot_timer > 0:
  return
 var profile = Catalog.AI_PROFILES.get(room.profile,Catalog.AI_PROFILES.balanced)
 room.bot_timer = profile.interval
 if room.door_hp < room.max_hp()*0.55:
  if room.upgrade_door() or room.repair_door():
   return
 if room.bed_level < 1 and room.upgrade_bed():
  return
 if room.door_level < 1 and room.upgrade_door():
  return
 # Each profile invests differently after establishing two utility tiles.
 if room.buildings.size() >= 2:
  if room.profile == "guard" and room.door_level < profile.door_goal and room.upgrade_door():
   return
  if room.bed_level < profile.bed_goal and room.upgrade_bed():
   return
  if room.door_level < profile.door_goal and room.upgrade_door():
   return
 for kind in profile.priorities:
  var exists = false
  for b in room.buildings.values():
   if b.kind == kind:
    exists = true
  if not exists:
   for tile in range(6):
    if not room.buildings.has(tile) and room.build(kind,tile):
     return
 if room.profile == "gunner":
  for tile in room.buildings:
   if room.buildings[tile].kind in ["turret","heavy"] and room.upgrade_building(tile):
    return
 if room.upgrade_bed():
  return
 if room.upgrade_door():
  return
 for tile in room.buildings:
  if room.upgrade_building(tile):
   return
