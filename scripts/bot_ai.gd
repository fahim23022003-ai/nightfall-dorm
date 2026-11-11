class_name BotAI
extends RefCounted

static func tick(room: RoomState, delta: float):
 if not room.alive or not room.sleeping:
  return
 room.bot_timer -= delta
 if room.bot_timer > 0:
  return
 room.bot_timer = 1.1
 if room.door_hp < room.max_hp()*0.55 and room.repair_door():
  return
 var priorities = ["turret","generator","economy","repair","heavy","enhancer"]
 if room.profile == "economist":
  priorities = ["economy","generator","turret","repair","heavy","enhancer"]
 elif room.profile == "gunner":
  priorities = ["turret","generator","heavy","enhancer","economy","repair"]
 elif room.profile == "engineer":
  priorities = ["generator","repair","turret","economy","heavy","enhancer"]
 if room.bed_level < 1 and room.upgrade_bed():
  return
 if room.door_level < 1 and room.upgrade_door():
  return
 for kind in priorities:
  var exists = false
  for b in room.buildings.values():
   if b.kind == kind:
    exists = true
  if not exists:
   for tile in range(6):
    if not room.buildings.has(tile) and room.build(kind,tile):
     return
 if room.profile == "guard" and room.upgrade_door():
  return
 if room.upgrade_bed():
  return
 if room.upgrade_door():
  return
 for tile in room.buildings:
  if room.upgrade_building(tile):
   return
