class_name SpatialConstruction
extends RefCounted
# One authoritative player-Endless layout. Opaque IDs and coordinates are separate.
const VERSION=1
const FOOT_SIZE=Vector2(44,40)
const MAX_ID=1000000000
var room_ref: WeakRef
var next_id=16
var used_legacy: Array=[]
var undo_entry: Dictionary={}
var moving_id=-1
var moving_instance=-1
var relocations: Array=[]
var cached_layout: Dictionary={}
var cached_blocks: Array=[]
func _init(room=null):
 if room!=null:room_ref=weakref(room)
func room():return room_ref.get_ref() if room_ref!=null else null
static func footprint(point: Vector2) -> Rect2:return Rect2(point-FOOT_SIZE/2,FOOT_SIZE)
static func bounded(point: Vector2) -> bool:return point.is_finite() and absf(point.x)<=10000 and absf(point.y)<=10000
static func segment_box(a: Vector2,b: Vector2,margin: float) -> Rect2:return Rect2(a.min(b)-Vector2.ONE*margin,(a-b).abs()+Vector2.ONE*margin*2)
static func blocked_for(layout: Dictionary) -> Array:
 var door: Vector2=layout.door;var normal: Vector2=layout.door_normal;var bed: Vector2=layout.bed
 return [
  {"rect":Rect2(bed-Vector2(31,49),Vector2(62,98)),"reason":"Bed access must remain clear"},
  {"rect":Rect2(layout.cabinet+Vector2(-22,1),Vector2(44,28)),"reason":"Building overlaps cabinet"},
  {"rect":Rect2(layout.plant+Vector2(-14,3),Vector2(28,22)),"reason":"Building overlaps plant"},
  {"rect":segment_box(door-normal*10,door-normal*48,26),"reason":"Door access must remain clear"},
  {"rect":segment_box(door-normal*48,bed+normal*48,14),"reason":"Door-to-bed route must remain clear"}]
func blocks() -> Array:
 var r=room()
 if cached_layout!=r.layout:cached_layout=r.layout.duplicate(true);cached_blocks=blocked_for(r.layout)
 return cached_blocks
func geometry_reason(point: Vector2,ignore_id: int=-1,layout: Dictionary={}) -> String:
 var r=room()
 if not bounded(point):return "Invalid coordinates"
 var rect=footprint(point);var bounds: Rect2=r.bounds() if layout.is_empty() else layout.bounds
 if not bounds.grow(-8).encloses(rect):return "Outside unlocked room"
 var forbidden=blocks() if layout.is_empty() else blocked_for(layout)
 for obstacle in forbidden:
  if rect.intersects(obstacle.rect):return obstacle.reason
 for id in r.buildings:
  if id!=ignore_id and rect.grow(2).intersects(footprint(r.tile_position(id))):return "Building overlaps another structure"
 return ""
func purchase_reason(kind: String,point: Vector2) -> String:
 var r=room()
 if not r.alive:return "Resident eliminated"
 if not r.sleeping:return "Sleep in your bed before building"
 if kind not in Catalog.BUILDINGS:return "Choose a building"
 if moving_id>=0:return "Finish or cancel moving first"
 if r.buildings.size()>=r.tile_count():return "Capacity reached"
 if next_id>=MAX_ID:return "Construction identity limit reached"
 var error=geometry_reason(point)
 if error!="":return error
 if kind=="heavy" and r.bed_level<1:return "Arc turret requires bed level 2"
 var need=BalanceRules.build_requirement(kind,r)
 if need!="":return need
 var price=r.quote_build(kind)
 if r.gold+.00001<price.x:return "Insufficient Gold"
 if r.electricity+.00001<price.y:return "Insufficient Electricity"
 return ""
func place(kind: String,point: Vector2) -> bool:
 var r=room();var error=purchase_reason(kind,point)
 if error!="":return r.reject(error)
 var id=next_id
 if not r._purchase_building(kind,id,point):return false
 r.buildings[id].position=point;next_id+=1
 return true
func legacy_build(kind: String,tile: int) -> bool:
 # Compatibility for older model clients: a pad is only a requested coordinate.
 # Desktop free construction never calls this adapter or requires a numbered pad.
 var r=room()
 if tile<0 or tile>=r.tile_count():return r.reject("Outside unlocked room")
 if r.buildings.has(tile):return r.reject("Building overlaps another structure")
 var point=r.fixed_tile_position(tile);var error=purchase_reason(kind,point)
 if error!="":return r.reject(error)
 var id=tile if tile not in used_legacy else next_id
 if not r._purchase_building(kind,id,point):return false
 r.buildings[id].position=point
 if tile not in used_legacy:used_legacy.append(tile)
 else:next_id+=1
 return true
func move_reason(model,id: int) -> String:
 var r=room()
 if model.run_kind!="endless" or model.player()!=r or r.owner!=0:return "Only your Endless room can be rearranged"
 if not model.running or model.result!="" or not r.alive or not r.sleeping:return "An active occupied room is required"
 if not r.buildings.has(id):return "Select an existing building"
 if model.time>=model.preparation and model.endless.phase!="intermission":return "Move during preparation or intermission only"
 if moving_id>=0 and moving_id!=id:return "Finish or cancel moving first"
 return ""
func begin_move(model,id: int) -> bool:
 var r=room();var error=move_reason(model,id)
 if error!="":return r.reject(error)
 moving_id=id;moving_instance=int(r.buildings[id].instance_id)
 return true
func cancel_move():moving_id=-1;moving_instance=-1
func move(model,point: Vector2) -> bool:
 var r=room();var id=moving_id;var error=move_reason(model,id)
 if error=="" and (not r.buildings.has(id) or int(r.buildings[id].instance_id)!=moving_instance):error="Building identity changed; cancel and select again"
 if error=="":error=geometry_reason(point,id)
 if error!="":return r.reject(error)
 var previous: Vector2=r.buildings[id].position
 undo_entry={"id":id,"uid":moving_instance,"from":previous,"to":point,"wave":model.endless.wave,"phase":model.endless.phase,"before_wave":model.time<model.preparation,"prep":model.preparation,"level":r.buildings[id].level,"branch":r.buildings[id].get("specialization","")}
 r.buildings[id].position=point;cancel_move()
 model.record_event("building_moved",r.index,{"tile":id,"from":previous,"to":point,"position":point,"instance_id":r.buildings[id].instance_id})
 return true
func undo_reason(model) -> String:
 var r=room()
 if undo_entry.is_empty():return "No safe move to undo"
 var d=undo_entry;var error=move_reason(model,int(d.id))
 if error!="" or d.wave!=model.endless.wave or d.phase!=model.endless.phase or d.before_wave!=(model.time<model.preparation) or d.prep!=model.preparation or moving_id>=0:return "Undo is limited to the same preparation/intermission"
 if not r.buildings.has(d.id):return "Building no longer exists"
 var b=r.buildings[d.id]
 if b.instance_id!=d.uid or b.level!=d.level or b.get("specialization","")!=d.branch or b.position!=d.to:return "Building state changed"
 return geometry_reason(d.from,int(d.id))
func undo(model) -> bool:
 var error=undo_reason(model)
 if error!="":undo_entry.clear();return room().reject(error)
 var d=undo_entry.duplicate(true)
 if not begin_move(model,int(d.id)):return false
 var ok=move(model,d.from);undo_entry.clear();return ok
func hit_test(point: Vector2) -> int:
 var r=room();var selected=-1;var distance=INF
 var ids=r.buildings.keys();ids.sort()
 for id in ids:
  var at=r.tile_position(id);var core=at-Vector2(0,12)
  if Rect2(at-Vector2(22,38),Vector2(44,52)).has_point(point) and core.distance_squared_to(point)<distance:selected=id;distance=core.distance_squared_to(point)
 return selected
func snapshot() -> Dictionary:return {"version":VERSION,"next_id":next_id,"used_legacy":used_legacy.duplicate()}
func migrate() -> bool:
 var r=room();var ids=r.buildings.keys();ids.sort()
 for id in ids:
  r.buildings[id].position=r.fixed_tile_position(id)
  if id not in used_legacy:used_legacy.append(id)
 for id in ids:
  var before: Vector2=r.buildings[id].position;var why=geometry_reason(before,id)
  if why=="":continue
  var found=false
  # Bounded nearest-first search is migration-only, never a placement lattice.
  for radius in range(8,1025,8):
   for y in range(-radius,radius+1,8):
    for x in range(-radius,radius+1,8):
     if maxi(absi(x),absi(y))!=radius:continue
     var point=before+Vector2(x,y)
     if geometry_reason(point,id)=="":
      r.buildings[id].position=point;relocations.append({"id":id,"from":before,"to":point,"reason":why});found=true;break
    if found:break
   if found:break
  if not found:return false
 return true
static func valid_metadata(data) -> bool:
 if not data is Dictionary or data.get("version")!=VERSION or not ReplaySnapshot.whole(data.get("next_id"),16,MAX_ID) or not data.get("used_legacy") is Array or data.used_legacy.size()>16:return false
 var seen=[]
 for id in data.used_legacy:
  if not ReplaySnapshot.whole(id,0,15) or int(id) in seen:return false
  seen.append(int(id))
 return true

static func valid_room(saved: Dictionary,layout: Dictionary) -> bool:
 var meta=saved.get("construction")
 if not valid_metadata(meta):return false
 var r=RoomState.new();r.layout=layout;r.owner=0;r.spatial=SpatialConstruction.new(r)
 var instances=[]
 for b in saved.buildings:
  if not ReplaySnapshot.point(b.get("position")) or not ReplaySnapshot.whole(b.get("instance_id"),1,1e12) or int(b.instance_id) in instances:return false
  instances.append(int(b.instance_id))
  var id=int(b.tile)
  if id>=meta.next_id or (id<16 and not meta.used_legacy.any(func(old_id):return int(old_id)==id)):return false
  r.buildings[id]={"position":ReplaySnapshot.vec(b.position)}
 for id in r.buildings:
  if r.spatial.geometry_reason(r.tile_position(id),id)!="":return false
 return true
func adopt_legacy() -> bool:
 var r=room();var taken=[];var ids=r.buildings.keys();ids.sort()
 for id in ids:
  if r.buildings[id].has("instance_id"):taken.append(int(r.buildings[id].instance_id))
 var serial=1
 for id in ids:
  if not r.buildings[id].has("instance_id"):
   while serial in taken:serial+=1
   r.buildings[id].instance_id=serial;taken.append(serial)
 return migrate()
