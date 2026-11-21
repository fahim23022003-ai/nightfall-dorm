extends SceneTree

const SCALE := SpatialConstruction.SUBSTANTIAL_VERSION
var checks := 0
var failures := 0

func _initialize() -> void:
 call_deferred("run")

func check(ok: bool, label: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  if failures<20:push_error(label)

func fixture(layout: Dictionary, version: int) -> RoomState:
 var room:=RoomState.new(0)
 room.layout=layout
 room.owner=0;room.sleeping=true;room.closed=true
 room.gold=200000;room.electricity=200000
 room.bed_level=5;room.door_level=5
 room.spatial=SpatialConstruction.new(room)
 room.spatial.rules_version=version
 room.spatial.grid=true
 return room

func positions(room: RoomState, kind: String, rotation: int=0) -> Array[Vector2]:
 var result: Array[Vector2]=[]
 var bounds:=room.spatial.grid_bounds()
 for y in range(int(bounds.size.y)/16):
  for x in range(int(bounds.size.x)/16):
   result.append(room.spatial.aligned(bounds.position+Vector2(x,y)*16,kind,rotation))
 return result

func place_any(room: RoomState,kind: String) -> int:
 for rotation in [0,1]:
  for point in positions(room,kind,rotation):
   if room.spatial.purchase_reason(kind,point,rotation)!="":continue
   var id: int=room.spatial.next_id
   if room.spatial.place(kind,point,rotation):return id
 return -1

func fill_needles(layout: Dictionary,version: int) -> int:
 var room:=fixture(layout,version)
 for point in positions(room,"turret"):
  if room.spatial.purchase_reason("turret",point)=="":room.spatial.place("turret",point)
 return room.buildings.size()

func check_transactions() -> void:
 var model:=MatchModel.new()
 model.full_grid_requested=true
 model.substantial_grid_requested=true
 model.procedural_v2_requested=true
 check(model.configure_map("abandoned_dorm") and model.claim_room(0),"Normal model claim enables preview")
 var room:=model.player()
 if room==null:return
 model.player_position=room.bed_position()
 check(model.sleep_player() and room.spatial.rules_version==SCALE,"New grid uses opted-in footprint rules")
 room.gold=20000;room.electricity=20000;room.bed_level=5;room.door_level=5
 var id:=place_any(room,"heavy")
 if id<0:
  check(false,"Buy the 5×4 Arc")
  return
 check(model.begin_building_move(id),"Enter Move through production model")
 var original: Vector2=room.tile_position(id)
 var original_turn: int=room.buildings[id].rotation
 var original_identity: int=room.buildings[id].instance_id
 var wallet:=Vector2(room.gold,room.electricity)
 var turn:=posmod(original_turn+1,4)
 var moved:=false
 for point in positions(room,"heavy",turn):
  if point==original or room.spatial.geometry_reason(point,id,{},"heavy",turn)!="":continue
  moved=model.move_building(point,turn)
  if moved:break
 check(moved and room.buildings[id].rotation==turn,"Commit rotated move")
 check(room.spatial.undo(model) and room.tile_position(id)==original and room.buildings[id].rotation==original_turn,"Undo restores original anchor and rotation")
 check(room.buildings[id].instance_id==original_identity and Vector2(room.gold,room.electricity)==wallet,"Move and undo preserve identity and wallet")
 var refund:=room.building_refund(id)
 check(model.sell_building(id) and Vector2(room.gold,room.electricity).is_equal_approx(wallet+refund),"Refund reflects paid investment")

func run() -> void:
 check_transactions()
 var room_layout:=NightmareMacroLayout.generate("abandoned_dorm",73,"ring").rooms[0] as Dictionary
 for kind: String in Catalog.BUILDINGS:
  var old:=SpatialConstruction.grid_cells(kind,0)
  var size:=SpatialConstruction.grid_cells(kind,0,SCALE)
  check(size.x*size.y>old.x*old.y,"Physical increase for "+kind)
  check(SpatialConstruction.grid_cells(kind,1,SCALE)==Vector2i(size.y,size.x),"Rotate width and depth for "+kind)
  var old_rect:=SpatialConstruction.grid_footprint(Vector2.ZERO,kind,0)
  var new_rect:=SpatialConstruction.grid_footprint(Vector2.ZERO,kind,0,SCALE)
  check(SpatialConstruction.art_scale(kind,new_rect,SCALE)>SpatialConstruction.art_scale(kind,old_rect),"Visible growth for "+kind)
  var room:=fixture(room_layout,SCALE)
  var id:=place_any(room,kind)
  check(id>=0,"Paid placement of "+kind)
  if id>=0:
   var position:=room.tile_position(id)
   check(room.spatial.hit_test(position)==id,"Select the placed "+kind)
   check(room.spatial.geometry_reason(position,-1,{},kind,int(room.buildings[id].rotation))=="Building overlaps another structure","Reject same-anchor overlap for "+kind)

 var ranges: Dictionary={}
 var candidate_rooms:=0
 var room_count:=0
 for theme: String in MapCatalog.IDS:
  for family: String in NightmareMacroLayout.FAMILY_IDS:
   for layout: Dictionary in NightmareMacroLayout.generate(theme,73,family,true).rooms:
    var room:=fixture(layout,SCALE)
    var repair:=place_any(room,"repair")
    var generator:=place_any(room,"generator")
    var needle:=place_any(room,"turret")
    candidate_rooms+=int(repair>=0 and generator>=0 and needle>=0)
    room_count+=1
    if theme=="abandoned_dorm":
     if not ranges.has(layout.shape):ranges[layout.shape]=[[],[]]
     ranges[layout.shape][0].append(fill_needles(layout,SpatialConstruction.VERSION))
     ranges[layout.shape][1].append(fill_needles(layout,SCALE))
 check(candidate_rooms==room_count,"Every sampled room fits repair, Dynamo and Needle")
 print("STRATEGIC_TRIOS ",candidate_rooms,"/",room_count)
 for shape: String in ranges:
  var old: Array=ranges[shape][0]
  var next: Array=ranges[shape][1]
  old.sort();next.sort()
  print("CAPACITY ",shape," n=",old.size()," old=",[old.front(),old[old.size()/2],old.back()]," preview=",[next.front(),next[next.size()/2],next.back()])
 print("BUILDING_SCALE_CHECKS=",checks," FAILURES=",failures)
 quit(int(failures>0))
