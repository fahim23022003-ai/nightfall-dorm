extends SceneTree
## Controlled CPU stress test, separate from real Story outcomes and rendered timings.
## Frozen occupancy and fixture wallets let the same code evaluate progressively more
## real purchased weapon instances. No measurements from this fixture imply win rates.

func _initialize():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=1 or not args[0].is_absolute_path():
  quit(2)
  return
 var model:=MatchModel.new()
 model.reset(1527566656)
 model.configure_match("hard")
 model.configure_stage("stage_1")
 model.configure_balance()
 model.story_level=1
 model.configure_strategy(model.map_seed,"crusher")
 if not model.living_dorm_tactics():
  push_error("Expected Living Dorm procedural preview")
  quit(1)
  return
 for room: RoomState in model.rooms:
  room.owner=room.index
  room.sleeping=true
  room.closed=true
  room.gold=100000
  room.electricity=100000
 model.player_room=0
 if not model.enable_player_grid():
  quit(1)
  return
 var total:=0
 var runs: Array=[]
 for requested: int in [0,12,24,40,60]:
  while total<requested:
   var before:=total
   for room: RoomState in model.rooms:
    if room.spatial!=null:
     if add_to_grid(room):total+=1
    else:
     var tile:=room.buildings.size()
     if tile<room.tile_count() and room.build("turret",tile):total+=1
    if total==requested:break
   if total==before:break
  if not runs.is_empty() and runs.back().placed==total:continue
  var samples: Array[int]=[]
  for i in range(105):
   var start:=Time.get_ticks_usec()
   var scores:=HunterSiegeStrategy.assess(model,model.hunter)
   var elapsed:=Time.get_ticks_usec()-start
   if scores.size()!=6:
    push_error("Expected valid scores for six reachable occupied doors")
    quit(1)
    return
   if i>=5:samples.append(elapsed)
  var sorted:=samples.duplicate()
  sorted.sort()
  runs.append({"requested":requested,"placed":total,"placed_by_room":model.rooms.map(func(r):return r.buildings.size()),
   "samples_us":samples,"median_us":(sorted[49]+sorted[50])*.5,"p95_us":sorted[94],"p99_us":sorted[98]})
 var file:=FileAccess.open(args[0],FileAccess.WRITE)
 if file==null:
  quit(2)
  return
 file.store_string(JSON.stringify(runs,"  ")+"\n")
 file.close()
 print("PHASE23_DECISION_STRESS max=",total)
 quit(0)

func add_to_grid(room: RoomState) -> bool:
 var bounds:=room.spatial.grid_bounds()
 for x in range(0,ceili(bounds.size.x),SpatialConstruction.CELL_SIZE):
  for y in range(0,ceili(bounds.size.y),SpatialConstruction.CELL_SIZE):
   var point:=room.spatial.aligned(bounds.position+Vector2(x,y),"turret",0)
   if room.spatial.purchase_reason("turret",point,0).is_empty():
    return room.spatial.place("turret",point)
 return false
