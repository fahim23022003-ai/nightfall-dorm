extends SceneTree

var checks := 0
var failures := 0

func _initialize():
 call_deferred("run")

func check(value: bool, label: String):
 checks += 1
 if not value:
  failures += 1
  push_error(label)

func owned_endless(map_id: String, grid: bool, room_index: int) -> MatchModel:
 var model := MatchModel.new()
 model.full_grid_requested = grid
 check(model.configure_endless(map_id,"standard",71,1), "configure Endless " + map_id)
 check(model.claim_room(room_index), "claim room " + map_id)
 model.player_position = model.player().bed_position()
 check(model.sleep_player(), "enter bed " + map_id)
 return model

func next_cell(room: RoomState, kind: String, rotation: int = 0, ignore_id: int = -1) -> Vector2:
 var bounds := room.bounds()
 for y in range(int(bounds.position.y), int(bounds.end.y), 16):
  for x in range(int(bounds.position.x), int(bounds.end.x), 16):
   var point: Vector2 = room.spatial.aligned(Vector2(x, y),kind,rotation)
   if ignore_id >= 0 and point.distance_to(room.tile_position(ignore_id)) < 40:
    continue
   if room.spatial.geometry_reason(point,ignore_id,{},kind,rotation) == "":
    return point
 return Vector2.INF

func run():
 for map_id in MapCatalog.IDS:
  for room_index in [0,3]:
   var baseline := owned_endless(map_id,false,room_index)
   var model := owned_endless(map_id,true,room_index)
   var room := model.player()
   var old_room := baseline.player()
   check(old_room.tile_count() == 3 and not old_room.spatial.grid,"fallback uses existing foundation")
   check(room.spatial.grid and room.expansion_tier == 7,"grid starts on complete floor " + map_id)
   check(room.door_position() == old_room.door_position() and room.bed_position() == old_room.bed_position(),"access anchors preserved " + map_id)
   check(room.gold == old_room.gold and room.electricity == old_room.electricity,"full floor activates without charging either currency")
   var other_index := 1 if room_index == 0 else 0
   check(model.rooms[other_index].bounds() == baseline.rooms[other_index].bounds(),"NPC room layout preserved")
   check(model.navigation_walkable(room.door_approach()) and not model.navigation_path(model.hunter.position,room.door_approach()).is_empty(),"Hunter approach route remains walkable " + map_id)
   verify_room(model,room,map_id)

 var campaign := MatchModel.new()
 campaign.full_grid_requested = true
 check(campaign.claim_room(1) and campaign.player().spatial != null and campaign.player().spatial.grid,"legacy Campaign player grid uses actual room bounds")
 campaign.player_position = campaign.player().bed_position()
 check(campaign.sleep_player(),"legacy Campaign bed still works")
 var at := next_cell(campaign.player(),"turret")
 check(at.is_finite() and campaign.place_building("turret",at),"legacy Campaign uses the same paid grid command")
 if not campaign.player().buildings.is_empty():
  var campaign_id: int = campaign.player().buildings.keys()[0]
  var destination := next_cell(campaign.player(),"turret",1,campaign_id)
  check(destination.is_finite() and campaign.begin_building_move(campaign_id) and campaign.move_building(destination,1),"Campaign supports rotating a move in preparation")
  check(campaign.player().spatial.undo(campaign) and campaign.player().tile_position(campaign_id) == at,"Campaign undo restores the same building")
  campaign.time = campaign.preparation
  check(not campaign.begin_building_move(campaign_id),"Campaign combat prevents moving")

 var tutorial := MatchModel.new()
 tutorial.full_grid_requested = true
 tutorial.tutorial_mode = true
 check(tutorial.claim_room(0) and tutorial.player().spatial == null,"scripted tutorial retains fixed pads")
 print("FULL_ROOM_GRID_MODEL_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)

func verify_room(model: MatchModel, room: RoomState, map_id: String):
 var start_wallet: float = room.gold
 check(not model.place_building("turret",room.door_position()) and room.gold == start_wallet,"door placement rejected without charge")
 check(not model.place_building("turret",room.bed_position()) and room.gold == start_wallet,"bed placement rejected without charge")
 check(not model.place_building("turret",Vector2.INF) and room.gold == start_wallet,"non-finite placement rejected")
 check(not model.expansion.purchase(model) and room.gold == start_wallet,"the complete floor cannot be charged as expansion")
 # Prepared dense arrangement exercises physical capacity, while each
 # build still uses the real model's paid transaction.
 room.gold = 30000.0
 room.electricity = 30000.0
 room.ledger.reconcile(room,model.time)
 var point := next_cell(room,"generator",1)
 var before := Vector2(room.gold,room.electricity)
 var price := room.quote_build("generator")
 var old_position: Vector2 = model.player_position
 model.player_position = point
 check(not model.place_building("generator",point,1) and Vector2(room.gold,room.electricity) == before,"placement protects an active character without charging")
 model.player_position = old_position
 check(point.is_finite() and model.place_building("generator",point,1),"buy rotated infrastructure " + map_id)
 if room.buildings.is_empty():
  return
 var id: int = room.buildings.keys()[0]
 var building: Dictionary = room.buildings[id]
 check(int(building.get("rotation",-1)) == 1 and (before-Vector2(room.gold,room.electricity)).is_equal_approx(price),"exact charge and rotation stored")
 check(not model.place_building("turret",point),"rotated building blocks overlap")
 var moved := next_cell(room,"generator",2,id)
 before = Vector2(room.gold,room.electricity)
 var instance: int = building.instance_id
 check(moved.is_finite() and model.begin_building_move(id) and model.move_building(moved,2),"relocate and turn the same building")
 check(room.buildings[id].instance_id == instance and room.tile_position(id) == moved and room.buildings[id].rotation == 2,"move preserves identity")
 check(room.spatial.undo(model) and room.tile_position(id) == point and room.buildings[id].rotation == 1,"safe undo restores position and rotation")
 check(Vector2(room.gold,room.electricity) == before,"move and undo spend nothing")
 room.bed_level = 4
 room.door_level = 4
 for level in range(4):
  if level < 3:
   check(model.upgrade_building(id),"actual grid building upgrade")
  else:
   check(model.specialize_building(id,StrategyCatalog.branches("generator")[0]),"actual grid specialization purchase")
 check(room.buildings[id].level == 5 and room.tile_position(id) == point and room.buildings[id].rotation == 1,"upgrades preserve placement metadata")
 for attempt in range(20):
  var available := next_cell(room,"turret")
  if not available.is_finite():
   break
  check(model.place_building("turret",available),"legal crowded turret placement")
 check(room.buildings.size() > 16,"physical capacity exceeds historical cap " + map_id)
 for key in room.buildings:
  var b: Dictionary = room.buildings[key]
  check(room.spatial.geometry_reason(room.tile_position(key),int(key),{},b.kind,int(b.rotation)) == "","crowded footprint remains valid")
 var quote := room.building_refund(id)
 before = Vector2(room.gold,room.electricity)
 check(model.sell_building(id) and (Vector2(room.gold,room.electricity)-before).is_equal_approx(quote),"sale restores exact modeled refund")
