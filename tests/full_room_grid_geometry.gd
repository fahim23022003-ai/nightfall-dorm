extends SceneTree
## Prepared wallets exercise paid construction; this is a geometry and
## transaction-preservation fixture, not an affordability simulation.

var checks:=0
var failures:=0
var dense_counts:={}
var expanded_cases:=0
func _initialize():
 call_deferred("run")

func check(accepted:bool, description:String):
 checks+=1
 if not accepted:
  failures+=1
  push_error(description)

func room_fixture(index:int,layout:Dictionary={}) -> RoomState:
 var room:=RoomState.new(index)
 room.layout=layout
 room.owner=0
 room.sleeping=true
 room.gold=1000000.0
 room.electricity=1000000.0
 room.bed_level=4
 room.door_level=4
 room.spatial=SpatialConstruction.new(room)
 return room

func candidates(room:RoomState,kind:String,rotation:int) -> Array[Vector2]:
 var grid:Rect2=room.spatial.grid_bounds()
 var centers:Array[Vector2]=[]
 var size:=Vector2(SpatialConstruction.grid_cells(kind,rotation))*SpatialConstruction.CELL_SIZE
 var first:=grid.position+size*.5
 var last:=grid.end-size*.5
 for y in range(roundi((last.y-first.y)/SpatialConstruction.CELL_SIZE)+1):
  for x in range(roundi((last.x-first.x)/SpatialConstruction.CELL_SIZE)+1):
   centers.append(first+Vector2(x,y)*SpatialConstruction.CELL_SIZE)
 return centers

func shape_and_validity(room:RoomState, name:String):
 check(room.spatial.enable_grid(),name+" grid enable")
 check(room.spatial.grid_origin()==room.bounds().position+Vector2(8,8),name+" stable seeded origin")
 check(room.spatial.snapshot().get("grid")==true,name+" metadata gate")
 var grid_area:Rect2=room.spatial.grid_bounds()
 var available:=ROOM_TYPES.size()
 for kind in ROOM_TYPES:
  var previous:=Vector2.ZERO
  for rotation in range(4):
   var found:=false
   for point in candidates(room,kind,rotation):
    var rect: Rect2=room.spatial.footprint_for(point,kind,rotation)
    if room.spatial.geometry_reason(point,-1,{},kind,rotation)!="":continue
    check(grid_area.encloses(rect),name+" "+kind+" fit within usable lattice")
    check(room.spatial.aligned(point,kind,rotation)==point,name+" "+kind+" exact center parity")
    check(room.spatial.geometry_reason(point+Vector2(1,0),-1,{},kind,rotation)=="Align the footprint to the grid",name+" "+kind+" reject off grid")
    if rotation==0:previous=rect.size
    else:check(rect.size == (Vector2(previous.y,previous.x) if rotation%2 else previous),name+" "+kind+" quarter footprint orientation")
    found=true
    break
   if not found:available-=1
 check(available==ROOM_TYPES.size(),name+" all 15 typed shapes have all rotations")
 var blocked: Array=room.spatial.blocks()
 for i in range(4,blocked.size()):
  check(not blocked[i].rect.intersects(blocked[1].rect) and not blocked[i].rect.intersects(blocked[2].rect),name+" routed obstacle corridor")
 for anchor in [room.bed_position(),room.cabinet_position()+Vector2(0,13),room.plant_position()+Vector2(0,13),room.door_position()-room.door_normal()*37]:
  var aligned:Vector2=room.spatial.aligned(anchor,"turret",0)
  check(room.spatial.geometry_reason(aligned,-1,{},"turret",0)!="",name+" block fixture/door")
 for point in candidates(room,"turret",0):
  if room.spatial.geometry_reason(point,-1,{},"turret",0)=="":
   check(room.spatial.place("turret",point,0),name+" real grid placement")
 dense_counts[name]=room.buildings.size()
 check(room.buildings.size()<=SpatialConstruction.max_grid_buildings(room.bounds()),name+" geometric bound only")
 if name.begins_with("legacy"):
  check(room.buildings.size()>room.tile_count(),name+" no numbering cap")
 else:
  check(room.buildings.size()>16,name+" dense beyond old max capacity")

const ROOM_TYPES: Array[String] = ["turret","heavy","generator","repair","economy","enhancer","flame","frost","shock","auto_repair","shield","decoy","barrier","plasma","antenna"]

func movement():
 var model:=MatchModel.new()
 model.configure_endless("cursed_mansion","standard",61,1)
 model.claim_room(2)
 var room:RoomState=model.player()
 model.player_position=room.bed_position()
 model.sleep_player()
 var before_id: int=room.spatial.next_id
 check(model.enable_player_grid(),"canonical MatchModel grid activation")
 room.gold=1000000
 room.electricity=1000000
 room.bed_level=4
 room.door_level=4
 var before:=Vector2.INF
 for point in candidates(room,"heavy",0):
  if room.spatial.geometry_reason(point,-1,{},"heavy",0)=="":
   before=point
   break
 check(before.is_finite() and model.place_building("heavy",before,0),"legal model placement with rotation zero")
 var state:Dictionary=room.buildings[before_id].duplicate(true)
 var balances:Vector2=Vector2(room.gold,room.electricity)
 check(model.begin_building_move(before_id),"move begins with preserved building")
 var after:=Vector2.INF
 for point in candidates(room,"heavy",1):
  if point.distance_to(before)>64 and room.spatial.geometry_reason(point,before_id,{},"heavy",1)=="":
   after=point
   break
 check(after.is_finite(),"find legal rotated destination")
 if not after.is_finite():return
 room.spatial.actor_points_provider=func():return PackedVector2Array([after])
 check(not model.move_building(after,1) and room.buildings[before_id]==state,"live actor overlap is transactional")
 room.spatial.actor_points_provider=Callable()
 check(model.move_building(after,1),"rotation and move transaction")
 check(room.tile_position(before_id)==after and room.buildings[before_id].rotation==1 and balances==Vector2(room.gold,room.electricity),"moves preserve wallets")
 check(room.spatial.hit_test(after)==before_id,"typed footprint selects retained ID")
 check(room.spatial.undo(model) and room.buildings[before_id]==state and balances==Vector2(room.gold,room.electricity),"undo restores exact position and orientation")
 check(not room.spatial.undo(model),"same action cannot be undone twice")

func migration():
 var a:=room_fixture(0)
 var b:=room_fixture(0)
 for room in [a,b]:
  for i in range(4):
   room.buildings[i]={"instance_id":50+i,"level":3,"kind":"heavy" if i%2==0 else "barrier","invested_gold":123.01,"invested_power":17.83,"cooldown":0.42}
  check(room.spatial.enable_grid(),"fixed pad migration fits")
  check(room.spatial.used_legacy.size()==4,"register preserved numbered ids")
  for id in room.buildings:
   var building:Dictionary=room.buildings[id]
   check(building.invested_gold==123.01 and building.invested_power==17.83 and building.cooldown==.42 and building.instance_id==50+id,"migration preserves paid investment and original identity")
   check(room.spatial.geometry_reason(building.position,id)=="" and room.spatial.aligned(building.position,building.kind,building.rotation)==building.position,"migrated legal position")
 check(a.buildings==b.buildings and a.spatial.relocations==b.spatial.relocations,"same source migrates identically")
 var failed:=room_fixture(0)
 for i in range(22):
  failed.buildings[16+i]={"instance_id":80+i,"level":7,"kind":"shock","position":failed.bounds().get_center()+Vector2(i*.1,0),"invested_gold":99,"cooldown":.52}
 var original:=failed.buildings.duplicate(true)
 var metadata:Dictionary=failed.spatial.snapshot()
 check(not failed.spatial.enable_grid(),"geometrically impossible dense migration rejected")
 check(failed.buildings==original and failed.spatial.snapshot()==metadata and failed.spatial.relocations.is_empty(),"unsuccessful plan leaves all state untouched")

func expanded_routes():
 for legacy in [false,true]:
  for map_id in MapCatalog.IDS:
   for index in range(6):
    for prior in range(8):
     if legacy and prior<RoomExpansion.legacy_tier(MapCatalog.map(map_id).rooms[index].tiles.size()):continue
     var initial:=RoomExpansion.geometry(map_id,index,prior,legacy)
     var layout:=RoomExpansion.geometry(map_id,index,7,legacy)
     for name in ["bed","cabinet","plant"]:layout[name]=initial[name]
     var blocked:=SpatialConstruction.grid_blocks_for(layout)
     var doorway:Rect2=blocked[3].rect
     var bed:Rect2=blocked[0].rect
     var prior_rect:=doorway
     var valid:=true
     for step in range(4,blocked.size()):
      var route:Rect2=blocked[step].rect
      if not prior_rect.intersects(route) or route.intersects(blocked[1].rect) or route.intersects(blocked[2].rect):valid=false
      prior_rect=route
     expanded_cases+=1
     check(valid and prior_rect.intersects(bed),"Connected corridor %s room%d old tier%d legacy%s" % [map_id,index,prior,legacy])

func run():
 for map_id in MapCatalog.IDS:
  var rooms:Array=MapCatalog.map(map_id).rooms
  for i in range(6):shape_and_validity(room_fixture(i,rooms[i]),map_id+"-"+str(i))
 for i in range(6):shape_and_validity(room_fixture(i),"legacy-"+str(i))
 expanded_routes()
 movement()
 migration()
 print("FULL_ROOM_GRID_CORE checks=",checks," failures=",failures,", expanded routes=",expanded_cases,", dense counts ",JSON.stringify(dense_counts))
 quit(1 if failures else 0)
