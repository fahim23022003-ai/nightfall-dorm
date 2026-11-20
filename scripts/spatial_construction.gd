class_name SpatialConstruction
extends RefCounted
# Opaque building IDs are independent of both legacy pads and physical grid cells.
const VERSION=1
const FOOT_SIZE=Vector2(44,40)
const CELL_SIZE=16
const WALL_MARGIN=8.0
const ACTOR_CLEARANCE=10.0
const MIGRATION_BUDGET=60000
const GRID_FOOTPRINTS={
 "turret":Vector2i(2,2), "heavy":Vector2i(3,2), "generator":Vector2i(2,3),
 "repair":Vector2i(3,2), "economy":Vector2i(2,2), "enhancer":Vector2i(2,2),
 "flame":Vector2i(3,2), "frost":Vector2i(2,2), "shock":Vector2i(3,3),
 "auto_repair":Vector2i(3,2), "shield":Vector2i(3,2), "decoy":Vector2i(2,2),
 "barrier":Vector2i(3,1), "plasma":Vector2i(2,2), "antenna":Vector2i(2,3)}
var grid=false
var actor_points_provider: Callable
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
var cached_grid=false
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
func effective_layout(layout: Dictionary={}) -> Dictionary:
 if not layout.is_empty():return layout
 var r=room()
 if not r.layout.is_empty():return r.layout
 return {"bounds":r.bounds(),"door":r.door_position(),"door_normal":r.door_normal(),"bed":r.bed_position(),"cabinet":r.cabinet_position(),"plant":r.plant_position()}

static func grid_area(bounds: Rect2) -> Rect2:
 var inner:=bounds.grow(-WALL_MARGIN)
 var size:=Vector2(maxf(0.0,floorf(inner.size.x/CELL_SIZE)),maxf(0.0,floorf(inner.size.y/CELL_SIZE)))*CELL_SIZE
 return Rect2(inner.position,size)

func grid_bounds() -> Rect2:return grid_area(room().bounds())
func grid_origin() -> Vector2:return grid_bounds().position

static func max_grid_buildings(bounds: Rect2) -> int:
 # The smallest typed footprint covers three cells. Real fixtures further reduce room.
 var cells:=Vector2i(grid_area(bounds).size/CELL_SIZE)
 return floori(float(cells.x*cells.y)/3.0)

static func grid_cells(kind: String,rotation: int) -> Vector2i:
 var size: Vector2i=GRID_FOOTPRINTS.get(kind,Vector2i(2,2))
 return Vector2i(size.y,size.x) if posmod(rotation,2)==1 else size

func aligned(point: Vector2,kind: String="",rotation: int=0) -> Vector2:
 if not grid or not bounded(point):return point
 return aligned_in(point,grid_origin(),kind,rotation)

static func aligned_in(point: Vector2,origin: Vector2,kind: String,rotation: int) -> Vector2:
 var center_origin:=origin+Vector2(grid_cells(kind,rotation))*CELL_SIZE*0.5
 return center_origin+((point-center_origin)/CELL_SIZE).round()*CELL_SIZE

func footprint_for(point: Vector2,kind: String="",rotation: int=0) -> Rect2:
 return grid_footprint(point,kind,rotation) if grid else footprint(point)

static func grid_footprint(point: Vector2,kind: String,rotation: int) -> Rect2:
 var size:=Vector2(grid_cells(kind,rotation))*CELL_SIZE
 return Rect2(point-size*0.5,size)

static func grid_blocks_for(layout: Dictionary) -> Array:
 var obstacles:=blocked_for(layout)
 obstacles.pop_back()
 var door: Vector2=layout.door
 var normal: Vector2=layout.door_normal
 var bed: Vector2=layout.bed
 # Begin inside the reserved doorway approach, beyond any adjacent cabinet.
 var begin:=door-normal*64
 var vertical:=normal.y!=0.0
 var normal_reach:=56.0 if vertical else 38.0
 var tangent_reach:=38.0 if vertical else 56.0
 var side:=normal.orthogonal()
 var bounds: Rect2=layout.bounds
 var route: Array=[]
 var finishes: Array[Vector2]=[
  bed+normal*normal_reach,bed+side*tangent_reach,
  bed-side*tangent_reach,bed-normal*normal_reach]
 for finish in finishes:
  if not bounds.grow(-14).has_point(finish):continue
  route=route_to_bed(begin,finish,vertical,bounds,obstacles)
  if not route.is_empty():break
 if route.is_empty():
  # Keep additional structures out of the historical approach if fixtures
  # supplied by an unknown layout admit no wider orthogonal corridor.
  route=[segment_box(begin,finishes[0],14)]
 for rect in route:obstacles.append({"rect":rect,"reason":"Door-to-bed route must remain clear"})
 return obstacles

static func route_to_bed(begin: Vector2,finish: Vector2,vertical: bool,bounds: Rect2,obstacles: Array) -> Array:
 var first:=Vector2(begin.x,finish.y) if vertical else Vector2(finish.x,begin.y)
 var second:=begin+finish-first
 var route:=fixture_clear_route([begin,first,finish],obstacles)
 if route.is_empty():route=fixture_clear_route([begin,second,finish],obstacles)
 if not route.is_empty():return route
 # Try a short orthogonal detour around cabinets or plants before changing the
 # side of the bed the route serves.
 var interior:=bounds.grow(-26)
 var midpoint:=(begin+finish)*0.5
 for delta in [0,16,-16,32,-32,48,-48,64,-64,80,-80,96,-96,112,-112,128,-128]:
  var x:=clampf(midpoint.x+delta,interior.position.x,interior.end.x)
  var y:=clampf(midpoint.y+delta,interior.position.y,interior.end.y)
  route=fixture_clear_route([begin,Vector2(x,begin.y),Vector2(x,finish.y),finish],obstacles)
  if route.is_empty():route=fixture_clear_route([begin,Vector2(begin.x,y),Vector2(finish.x,y),finish],obstacles)
  if not route.is_empty():return route
 return []

static func fixture_clear_route(points: Array,obstacles: Array) -> Array:
 var route: Array=[]
 var bed_collision: Rect2=obstacles[0].rect.grow(-4)
 for index in range(points.size()-1):
  if segment_box(points[index],points[index+1],1).intersects(bed_collision):return []
  var rect:=segment_box(points[index],points[index+1],14)
  if rect.intersects(obstacles[1].rect) or rect.intersects(obstacles[2].rect):return []
  route.append(rect)
 return route

func blocks() -> Array:
 var layout:=effective_layout()
 if cached_layout!=layout or cached_grid!=grid:
  cached_layout=layout.duplicate(true)
  cached_grid=grid
  cached_blocks=grid_blocks_for(layout) if grid else blocked_for(layout)
 return cached_blocks

static func blocked_reason(rect: Rect2,bounds: Rect2,obstacles: Array) -> String:
 if not bounds.encloses(rect):return "Outside unlocked room"
 for obstacle in obstacles:
  if rect.intersects(obstacle.rect):return obstacle.reason
 return ""

func geometry_reason(point: Vector2,ignore_id: int=-1,layout: Dictionary={},kind: String="",rotation: int=0) -> String:
 var r=room()
 if not bounded(point):return "Invalid coordinates"
 if grid and kind.is_empty() and r.buildings.has(ignore_id):
  kind=r.buildings[ignore_id].kind
  rotation=int(r.buildings[ignore_id].get("rotation",0))
 if grid and (rotation<0 or rotation>3):return "Invalid rotation"
 var room_layout:=effective_layout(layout)
 var bounds: Rect2=room_layout.bounds
 if grid:
  bounds=grid_area(bounds)
  if point.distance_squared_to(aligned_in(point,bounds.position,kind,rotation))>0.000001:return "Align the footprint to the grid"
 else:bounds=bounds.grow(-WALL_MARGIN)
 var rect:=footprint_for(point,kind,rotation)
 var obstacles:=blocks() if layout.is_empty() else (grid_blocks_for(room_layout) if grid else blocked_for(room_layout))
 var error:=blocked_reason(rect,bounds,obstacles)
 if not error.is_empty():return error
 var clearance:=rect if grid else rect.grow(2)
 # All grid footprints fit in three cells on either axis. Exclude distant
 # centers before resolving the neighbor's exact shape and orientation.
 var nearby:=rect.grow(1.5*CELL_SIZE)
 for id in r.buildings:
  if id==ignore_id:continue
  var building: Dictionary=r.buildings[id]
  var center: Vector2=r.tile_position(id)
  if grid and not nearby.has_point(center):continue
  if clearance.intersects(footprint_for(center,building.get("kind",""),int(building.get("rotation",0)))):return "Building overlaps another structure"
 if grid and actor_points_provider.is_valid():
  var actor_zone:=rect.grow(ACTOR_CLEARANCE)
  for actor in actor_points_provider.call():
   if actor is Vector2 and actor_zone.has_point(actor):return "Building overlaps an active character"
 return ""

func purchase_reason(kind: String,point: Vector2,rotation: int=0) -> String:
 var r=room()
 if not r.alive:return "Resident eliminated"
 if not r.sleeping:return "Sleep in your bed before building"
 if kind not in Catalog.BUILDINGS:return "Choose a building"
 if moving_id>=0:return "Finish or cancel moving first"
 if not grid and r.buildings.size()>=r.tile_count():return "Capacity reached"
 if next_id>=MAX_ID:return "Construction identity limit reached"
 var error=geometry_reason(point,-1,{},kind,rotation)
 if error!="":return error
 if kind=="heavy" and r.bed_level<1:return "Arc turret requires bed level 2"
 var need=BalanceRules.build_requirement(kind,r)
 if need!="":return need
 var price=r.quote_build(kind)
 if r.gold+.00001<price.x:return "Insufficient Gold"
 if r.electricity+.00001<price.y:return "Insufficient Electricity"
 return ""
func place(kind: String,point: Vector2,rotation: int=0) -> bool:
 var r=room();var error=purchase_reason(kind,point,rotation)
 if error!="":return r.reject(error)
 var id=next_id
 if not r._purchase_building(kind,id,point):return false
 r.buildings[id].position=point
 if grid:r.buildings[id].rotation=rotation
 next_id+=1
 return true
func legacy_build(kind: String,tile: int) -> bool:
 # Compatibility for older model clients: a pad is only a requested coordinate.
 # Desktop free construction never calls this adapter or requires a numbered pad.
 var r=room()
 if tile<0 or tile>=r.tile_count():return r.reject("Outside unlocked room")
 if r.buildings.has(tile):return r.reject("Building overlaps another structure")
 var point=aligned(r.fixed_tile_position(tile),kind);var error=purchase_reason(kind,point)
 if error!="":return r.reject(error)
 var id=tile if tile not in used_legacy else next_id
 if not r._purchase_building(kind,id,point):return false
 r.buildings[id].position=point
 if grid:r.buildings[id].rotation=0
 if tile not in used_legacy:used_legacy.append(tile)
 else:next_id+=1
 return true
func move_reason(model,id: int) -> String:
 var r=room()
 if model.player()!=r or r.owner!=0 or (not grid and model.run_kind!="endless"):
  return "Only your room can be rearranged" if grid else "Only your Endless room can be rearranged"
 if not model.running or model.result!="" or not r.alive or not r.sleeping:return "An active occupied room is required"
 if not r.buildings.has(id):return "Select an existing building"
 if model.time>=model.preparation and (model.run_kind!="endless" or model.endless.phase!="intermission"):
  return "Move during preparation or intermission only" if model.run_kind=="endless" else "Move during preparation only"
 if moving_id>=0 and moving_id!=id:return "Finish or cancel moving first"
 return ""
func begin_move(model,id: int) -> bool:
 var r=room();var error=move_reason(model,id)
 if error!="":return r.reject(error)
 moving_id=id;moving_instance=int(r.buildings[id].instance_id)
 return true
func cancel_move():moving_id=-1;moving_instance=-1

func move_phase(model) -> String:
 return model.endless.phase if model.run_kind=="endless" else "preparation"

func move_wave(model) -> int:
 return model.endless.wave if model.run_kind=="endless" else 0

func move(model,point: Vector2,rotation: int=-1) -> bool:
 var r=room();var id=moving_id;var error=move_reason(model,id)
 if error=="" and (not r.buildings.has(id) or int(r.buildings[id].instance_id)!=moving_instance):error="Building identity changed; cancel and select again"
 if error!="":return r.reject(error)
 var building: Dictionary=r.buildings[id]
 var old_rotation:=int(building.get("rotation",0))
 if rotation==-1:rotation=old_rotation
 if not grid:rotation=0
 error=geometry_reason(point,id,{},building.kind,rotation)
 if error!="":return r.reject(error)
 var previous: Vector2=building.position
 undo_entry={"id":id,"uid":moving_instance,"from":previous,"to":point,"wave":move_wave(model),"phase":move_phase(model),"before_wave":model.time<model.preparation,"prep":model.preparation,"level":building.level,"branch":building.get("specialization","")}
 building.position=point
 if grid:
  undo_entry.from_rotation=old_rotation
  undo_entry.to_rotation=rotation
  building.rotation=rotation
 cancel_move()
 var event={"tile":id,"from":previous,"to":point,"position":point,"instance_id":building.instance_id}
 if grid:event.rotation=rotation
 model.record_event("building_moved",r.index,event)
 return true
func undo_reason(model) -> String:
 var r=room()
 if undo_entry.is_empty():return "No safe move to undo"
 var d=undo_entry;var error=move_reason(model,int(d.id))
 if error!="" or d.wave!=move_wave(model) or d.phase!=move_phase(model) or d.before_wave!=(model.time<model.preparation) or d.prep!=model.preparation or moving_id>=0:
  return "Undo is limited to the same preparation/intermission" if model.run_kind=="endless" else "Undo is limited to preparation"
 if not r.buildings.has(d.id):return "Building no longer exists"
 var b=r.buildings[d.id]
 if b.instance_id!=d.uid or b.level!=d.level or b.get("specialization","")!=d.branch or b.position!=d.to or (grid and int(d.get("to_rotation",0))!=int(b.get("rotation",0))):return "Building state changed"
 return geometry_reason(d.from,int(d.id),{},b.kind,int(d.get("from_rotation",0)))
func undo(model) -> bool:
 var error=undo_reason(model)
 if error!="":undo_entry.clear();return room().reject(error)
 var d=undo_entry.duplicate(true)
 if not begin_move(model,int(d.id)):return false
 var ok=move(model,d.from,int(d.get("from_rotation",-1)));undo_entry.clear();return ok
func hit_test(point: Vector2) -> int:
 var r=room()
 var selected: int=-1
 var distance:=INF
 var footprint_candidate: int=-1
 for id in r.buildings:
  var at: Vector2=r.tile_position(id)
  if grid and absf(at.x-point.x)<=1.5*CELL_SIZE and absf(at.y-point.y)<=1.5*CELL_SIZE:
   var b: Dictionary=r.buildings[id]
   if grid_footprint(at,b.kind,int(b.get("rotation",0))).has_point(point):
    if footprint_candidate<0 or id<footprint_candidate:footprint_candidate=id
  if Rect2(at-Vector2(22,38),Vector2(44,52)).has_point(point):
   var next_distance: float=(at-Vector2(0,12)).distance_squared_to(point)
   if next_distance<distance or next_distance==distance and id<selected:
    selected=id
    distance=next_distance
 return footprint_candidate if footprint_candidate>=0 else selected

func snapshot() -> Dictionary:
 var data={"version":VERSION,"next_id":next_id,"used_legacy":used_legacy.duplicate()}
 if grid:data.grid=true
 return data

func restore_metadata(data: Dictionary):
 grid=data.get("grid",false)
 next_id=int(data.next_id)
 used_legacy=data.used_legacy.map(func(id):return int(id))

func enable_grid() -> bool:
 if grid:return true
 var r=room()
 var layout:=effective_layout()
 var bounds: Rect2=layout.bounds
 if r.buildings.size()>max_grid_buildings(bounds):return false
 var area:=grid_area(bounds)
 var cells:=Vector2i(area.size/CELL_SIZE)
 var obstacles:=grid_blocks_for(layout)
 var structures: Array=[]
 for id in r.buildings:
  if id<0 or id>=MAX_ID:return false
  var building: Dictionary=r.buildings[id]
  var before: Vector2=r.tile_position(id)
  var options:=migration_options(before,building.kind,int(building.get("rotation",0)),area,cells,obstacles)
  if options.is_empty():return false
  structures.append({"id":id,"before":before,"options":options})
 structures.sort_custom(func(a,b):return int(a.id)<int(b.id) if a.options.size()==b.options.size() else a.options.size()<b.options.size())
 var occupied: Array[bool]=[]
 occupied.resize(cells.x*cells.y)
 occupied.fill(false)
 var solution: Dictionary={}
 var budget: Array[int]=[MIGRATION_BUDGET]
 if not allocate_layout(structures,0,cells.x,occupied,solution,budget):return false
 # Do not mutate any investment until the complete candidate layout fits.
 for entry in structures:
  var placed: Dictionary=solution[entry.id]
  var building: Dictionary=r.buildings[entry.id]
  var old_rotation:=int(building.get("rotation",0))
  building.position=placed.point
  building.rotation=placed.rotation
  if entry.id<16 and entry.id not in used_legacy:used_legacy.append(entry.id)
  next_id=maxi(next_id,int(entry.id)+1)
  if entry.before!=placed.point or old_rotation!=placed.rotation:
   relocations.append({"id":entry.id,"from":entry.before,"to":placed.point,"rotation":placed.rotation,"reason":"Aligned to the full-room grid"})
 grid=true
 cancel_move()
 undo_entry.clear()
 return true

static func migration_options(before: Vector2,kind: String,old_rotation: int,area: Rect2,cells: Vector2i,obstacles: Array) -> Array:
 var first:=posmod(old_rotation,4)
 var rotations: Array[int]=[first]
 var original_size:=grid_cells(kind,first)
 if original_size.x!=original_size.y:rotations.append(posmod(first+1,4))
 var options: Array=[]
 for turn in rotations:
  var size:=grid_cells(kind,turn)
  for y in range(cells.y-size.y+1):
   for x in range(cells.x-size.x+1):
    var top_left:=Vector2i(x,y)
    var point:=area.position+(Vector2(top_left)+Vector2(size)*0.5)*CELL_SIZE
    if blocked_reason(grid_footprint(point,kind,turn),area,obstacles)!="":continue
    options.append({"point":point,"rotation":turn,"cells":Rect2i(top_left,size),"distance":point.distance_squared_to(before)})
 options.sort_custom(func(a,b):
  if a.distance!=b.distance:return a.distance<b.distance
  if a.rotation!=b.rotation:return a.rotation==first
  if a.point.y!=b.point.y:return a.point.y<b.point.y
  return a.point.x<b.point.x)
 return options

static func allocate_layout(structures: Array,index: int,stride: int,occupied: Array[bool],solution: Dictionary,budget: Array[int]) -> bool:
 if index==structures.size():return true
 var structure: Dictionary=structures[index]
 for option in structure.options:
  if budget[0]<=0:return false
  budget[0]-=1
  var area: Rect2i=option.cells
  if not cells_free(area,stride,occupied):continue
  write_cells(area,stride,occupied,true)
  solution[structure.id]=option
  if allocate_layout(structures,index+1,stride,occupied,solution,budget):return true
  solution.erase(structure.id)
  write_cells(area,stride,occupied,false)
 return false

static func cells_free(area: Rect2i,stride: int,occupied: Array[bool]) -> bool:
 for y in range(area.position.y,area.end.y):
  for x in range(area.position.x,area.end.x):
   if occupied[y*stride+x]:return false
 return true

static func write_cells(area: Rect2i,stride: int,occupied: Array[bool],value: bool):
 for y in range(area.position.y,area.end.y):
  for x in range(area.position.x,area.end.x):
   occupied[y*stride+x]=value
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
 if not data is Dictionary or data.get("version")!=VERSION or not data.get("grid",false) is bool or not ReplaySnapshot.whole(data.get("next_id"),16,MAX_ID) or not data.get("used_legacy") is Array or data.used_legacy.size()>16:return false
 var seen=[]
 for id in data.used_legacy:
  if not ReplaySnapshot.whole(id,0,15) or int(id) in seen:return false
  seen.append(int(id))
 return true

static func valid_room(saved: Dictionary,layout: Dictionary,index: int=0) -> bool:
 var meta=saved.get("construction")
 if not valid_metadata(meta) or not saved.get("buildings") is Array:return false
 var r=RoomState.new(index);r.layout=layout;r.owner=0;r.spatial=SpatialConstruction.new(r)
 r.spatial.restore_metadata(meta)
 if r.spatial.grid and saved.buildings.size()>max_grid_buildings(r.bounds()):return false
 var instances={}
 for b in saved.buildings:
  if not b is Dictionary or not ReplaySnapshot.whole(b.get("tile"),0,MAX_ID-1):return false
  if not ReplaySnapshot.point(b.get("position")) or not ReplaySnapshot.whole(b.get("instance_id"),1,1e12) or int(b.instance_id) in instances:return false
  instances[int(b.instance_id)]=true
  if r.spatial.grid and (not ReplaySnapshot.whole(b.get("rotation"),0,3) or not Catalog.BUILDINGS.has(b.get("kind",""))):return false
  var id=int(b.tile)
  if r.buildings.has(id) or id>=r.spatial.next_id or (id<16 and id not in r.spatial.used_legacy):return false
  r.buildings[id]={"position":ReplaySnapshot.vec(b.position),"kind":b.get("kind",""),"rotation":int(b.get("rotation",0)) if r.spatial.grid else 0}
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
