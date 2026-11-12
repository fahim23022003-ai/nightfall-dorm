extends RefCounted
# Shared independent fixture/observation helpers. No production behavior is mocked.
const LEGACY="res://docs/evidence/replay/qa-legacy-profile.json"
static func profile(path):
 DirAccess.copy_absolute(LEGACY,path)
 var p=PlayerProfile.new(path)
 if not p.load_profile():return null
 return p
static func numeric_same(a,b):
 if a is Dictionary and b is Dictionary:
  if a.size()!=b.size():return false
  for key in a:
   if not b.has(key) or not numeric_same(a[key],b[key]):return false
  return true
 if a is Array and b is Array:
  if a.size()!=b.size():return false
  for i in range(a.size()):
   if not numeric_same(a[i],b[i]):return false
  return true
 return a==b
static func profile_signature(p):
 # New fields cannot silently escape Practice's permanent-state regression check.
 var out={}
 for prop in p.get_script().get_script_property_list():
  var value=p.get(prop.name)
  if value is RandomNumberGenerator:out[prop.name]={"seed":str(value.seed),"state":str(value.state)}
  elif value is Dictionary or value is Array:out[prop.name]=value.duplicate(true)
  elif not value is Object:out[prop.name]=value
 return out
static func cleanup(prefix):
 var dir=DirAccess.open("user://")
 if dir==null:return
 for file in dir.get_files():
  if file.begins_with(prefix.trim_prefix("user://")):DirAccess.remove_absolute("user://"+file)
static func nearest_pad(room,position):
 var index=-1
 for tile in range(room.tile_count()):
  if room.buildings.has(tile):continue
  if index<0 or room.tile_position(tile).distance_to(position)<room.tile_position(index).distance_to(position):index=tile
 return index
static func model_signature(m):
 var rooms=[]
 for r in m.rooms:
  rooms.append([r.owner,r.alive,r.sleeping,r.closed,r.bed_level,r.door_level,r.door_hp,r.gold,r.electricity,r.buildings.duplicate(true),r.income_total,r.damage_dealt,r.shots])
 return {"map":m.map_id,"difficulty":m.difficulty,"time":m.time,"result":m.result,"running":m.running,"random":str(m.random.state),"player":m.player_room,"position":m.player_position,"hunter":[m.hunter.state,m.hunter.archetype,m.hunter.position,m.hunter.hp,m.hunter.max_hp,m.hunter.target,m.hunter.attacks,m.hunter.transformed],"rooms":rooms,"projectiles":m.projectiles.duplicate(true),"items":m.items.timers.duplicate(true)}
