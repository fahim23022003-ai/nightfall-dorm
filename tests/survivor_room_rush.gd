extends SceneTree

var checks:=0
var failures:=0

func _initialize() -> void:
 call_deferred("run")

func check(condition: bool, note: String) -> void:
 checks+=1
 if not condition:
  failures+=1
  push_error(note)

func fresh(theme: String, rules: int, seed: int) -> MatchModel:
 var model:=MatchModel.new()
 model.reset(seed)
 model.procedural_requested=rules==1
 model.procedural_v2_requested=rules==2
 if theme!="legacy":check(model.configure_map(theme),"configured "+theme)
 return model

func run() -> void:
 var previous:=OS.get_environment("NIGHTFALL_SURVIVOR_REBIRTH")
 OS.set_environment("NIGHTFALL_SURVIVOR_REBIRTH","1")
 for rules in range(3):
  for theme: String in MapCatalog.IDS:
   verify_race(theme,rules,147)
 verify_race("legacy",0,147)
 verify_tie_and_egress()
 verify_snapshot()
 if OS.get_environment("NIGHTFALL_PHASE16")=="1":verify_eta_planning()
 var original:=fresh("forgotten_hotel",2,52)
 var retry:=fresh("forgotten_hotel",2,52)
 var reproduced:=fresh("forgotten_hotel",2,52)
 check(original.begin_room_rush(25) and retry.begin_room_rush(26) and reproduced.begin_room_rush(25),"same geometry initializes successive distinct attempts")
 check(original.room_rush_spawn()==reproduced.room_rush_spawn() and original.room_rush_spawn()!=retry.room_rush_spawn(),"attempt identity reproduces and varies the exterior starting point")
 check(NightmareMap.pack(original.map_data)==NightmareMap.pack(retry.map_data),"retry spawn varies with identical procedural layout")
 check(original.random.state==retry.random.state,"race initialization leaves gameplay RNG untouched")
 OS.set_environment("NIGHTFALL_SURVIVOR_REBIRTH","0")
 var fallback:=fresh("abandoned_dorm",0,147)
 check(not fallback.begin_room_rush(11) and not fallback.room_rush_active(),"explicit fallback disables the race even in the preview")
 fallback.tick(6.2)
 check(fallback.bot_claimed==1 and fallback.room_rush_runners().is_empty(),"historic fallback population remains available")
 OS.set_environment("NIGHTFALL_SURVIVOR_REBIRTH","1")
 for kind in ["practice","challenge"]:
  var exception:=fresh("abandoned_dorm",0,147)
  exception.run_kind=kind
  check(not exception.begin_room_rush(11),"special mode retains its existing entrance")
 OS.set_environment("NIGHTFALL_SURVIVOR_REBIRTH",previous)
 print("SURVIVOR_RUSH_CHECKS=",checks," FAILURES=",failures)
 quit(int(failures>0))

func verify_race(theme: String,rules: int,seed: int) -> void:
 var model:=fresh(theme,rules,seed)
 var label:="%s V%d" % [theme,rules]
 var started:=model.begin_room_rush(11)
 check(started,label+" starts from navigable shared exterior")
 if not started:return
 var origin:=model.room_rush_spawn()
 check(model.can_walk(origin) and model.room_rush.exterior(model,origin),label+" starts off all room floors and Halls")
 check(model.player_position==origin and model.room_rush_runners().size()==5,label+" has one human and five NPCs")
 check(model.room_rush_runners().all(func(runner):return runner.position==origin),label+" all bodies share the exact gameplay origin")
 check(model.rooms.all(func(room):return room.owner==-1),label+" no target selected by race becomes reserved")
 var paths:=model.room_rush.routes_to_vacant_rooms(model,origin)
 check(paths.size()==model.rooms.size(),label+" spawn has legal paths to all floors")
 check(model.room_rush.nearest_room_distance(origin,paths)<=model.SURVIVOR_SPEED*12.0,label+" at least one legal room is reachable within 12 walking seconds")
 for i in range(model.rooms.size()):
  check(model.room_rush_status(i) in ["vacant","approaching"],label+" opening status is claimable")
 check(not model.claim_room(0),label+" distant human cannot claim")
 var positions: Dictionary={}
 for runner in model.room_rush_runners():positions[runner.owner]=runner.position
 model.time+=.1
 model.room_rush.tick(model,.1)
 var exact_step:=false
 for runner in model.room_rush_runners():
  var traveled: float=runner.position.distance_to(positions[runner.owner])
  check(traveled<=9.002,label+" NPC displacement is bounded at 90 units/s")
  if absf(traveled-9.0)<.002:exact_step=true
 check(exact_step,label+" unobstructed NPC horizontal distance is exactly half human speed")
 var goal: Vector2=paths.values()[0][0]
 var before: Vector2=model.player_position
 var forward: Vector2=model.player_position.direction_to(goal)
 if before.distance_to(goal)>18.2 and model._visible(before,before+forward*18.0,true):
  model.move_player(forward,.1)
  check(absf(model.player_position.distance_to(before)-18.0)<.002,label+" human speed stays 180 units/s")
 # Let the actors compete without player input. Five claims leave one legal
 # candidate and all the selected occupants subsequently reach their beds.
 while model.time<170.0 and (model.bot_claimed<5 or model.rooms.any(func(room):return room.owner>0 and not room.sleeping)):
  model.time+=.25
  model.room_rush.tick(model,.25)
 var owners:=model.rooms.map(func(room):return room.owner)
 for owner in range(1,6):
  check(owners.count(owner)==1,label+" each NPC owns exactly one room")
 check(owners.count(-1)==1 and model.room_rush_runners().is_empty(),label+" leaves one vacant room without teleport")
 check(model.rooms.filter(func(room):return room.owner>0 and room.sleeping).size()==5,label+" all NPC bed paths finish")
 print("SURVIVOR_RUSH_MAP ",label," spawn=",origin," completed=",model.time," claimed=",model.bot_claimed)

func verify_tie_and_egress() -> void:
 for rules in [0,2]:
  var model:=fresh("abandoned_dorm",rules,147)
  check(model.begin_room_rush(11),"tie fixture starts")
  var room: RoomState=model.rooms[0]
  var inside: Vector2=model.room_rush.claim_path(model,room,model.room_rush_spawn(),-1).back()
  var pursuer: Dictionary=model.room_rush_runners()[0]
  pursuer.target=room.index
  pursuer.position=inside
  pursuer.route=[inside]
  check(model.room_rush_status(room.index)=="approaching" and room.owner<0,"NPC approach confers no reservation")
  check(not model.try_claim_survivor(room.index,2,inside),"spoofed NPC cannot claim from another physical position")
  model.player_position=inside
  model.interact()
  check(room.owner==0 and model.room_rush_status(room.index)=="player","human action wins before same simulation-step NPC claim")
  model.player_position=room.bed_position()
  check(model.sleep_player(),"player locks the room while rival is already inside")
  model.room_rush.tick(model,.25)
  check(pursuer.target!=room.index and pursuer.position.distance_to(inside)>1.0,"NPC reroutes and moves out of the now-closed rival room")
  for i in range(20):
   model.room_rush.tick(model,.25)
   if not room.floor_has_point(pursuer.position):break
  check(not room.floor_has_point(pursuer.position),"physical egress reaches the corridor")
  check(room.owner==0,"reroute leaves player occupancy untouched")
  check(not model.try_claim_survivor(room.index,1,pursuer.position),"same claim transaction rejects a rival owner")

func verify_snapshot() -> void:
 var source:=MatchModel.new()
 source.procedural_v2_requested=true
 check(source.configure_endless("abandoned_dorm","standard",147,29),"Endless fixture configured")
 check(source.begin_room_rush(29),"Endless race starts before placement")
 var room: RoomState=source.rooms[0]
 source.player_position=source.room_rush.claim_path(source,room,source.room_rush_spawn(),-1).back()
 check(source.claim_room(0),"player claims physically for checkpoint")
 source.player_position=source.player().bed_position()
 check(source.sleep_player(),"player sleeps for checkpoint")
 source.time+=.1
 source.room_rush.tick(source,.1)
 source.hunter.hp=0
 source.endless.finish_wave(source)
 var snapshot:=ReplaySnapshot.encode(source)
 check(not snapshot.is_empty() and snapshot.has("room_rush"),"new checkpoint persists pending physical positions")
 if snapshot.is_empty():return
 var resumed:=ReplaySnapshot.restore(JSON.parse_string(JSON.stringify(snapshot)))
 check(resumed!=null and resumed.room_rush.snapshot()==source.room_rush.snapshot(),"saved nonce, spawn, current actors, and destinations restore exactly")
 if resumed!=null:
  check(resumed.continue_wave(),"resumed match continues from intermission")
  check(resumed.room_rush_spawn()==source.room_rush_spawn() and resumed.room_rush_runners()[0].position==source.room_rush_runners()[0].position,"next wave does not reroll or move pending occupants")
 var past:=snapshot.duplicate(true)
 past.erase("room_rush")
 var compatible:=ReplaySnapshot.restore(JSON.parse_string(JSON.stringify(past)))
 check(compatible!=null and not compatible.room_rush_active() and compatible.player_position==source.player_position,"older checkpoint stays compatible and resumes at its saved bed")
 var malformed:=snapshot.duplicate(true)
 malformed.room_rush.runners[0].owner=malformed.room_rush.runners[1].owner
 check(not ReplaySnapshot.valid(malformed),"duplicate pending NPC identities rejected")


func verify_eta_planning() -> void:
 var model:=fresh("abandoned_dorm",2,8649)
 var replay:=fresh("abandoned_dorm",2,8649)
 check(model.begin_room_rush(41) and replay.begin_room_rush(41),"deterministic Spine starts")
 if not model.room_rush_active() or not replay.room_rush_active():return
 var origin:=model.room_rush_spawn()
 var targets:=model.room_rush_runners().map(func(runner):return runner.target)
 check(targets==replay.room_rush_runners().map(func(runner):return runner.target),"same seed and nonce repeat advised destinations")
 var unique: Dictionary={}
 for target: int in targets:unique[target]=true
 check(unique.size()==5 and model.rooms.all(func(room):return room.owner<0),"separate intents create no room ownership")
 var runner: Dictionary=model.room_rush_runners()[0]
 var lost_target: int=runner.target
 var before: Vector2=runner.position
 # A corrupted or newly blocked path cannot make an actor move through a wall.
 runner.route=[before+Vector2(0.0,-200000.0)]
 for i in range(20):
  if runner.has("failed_room"):break
  model.time+=.25
  model.room_rush.tick(model,.25)
 check(runner.has("failed_room") and runner.failed_room==lost_target,"invalid route is detected as a failed approach")
 if runner.has("failed_room"):
  var stalled: Vector2=runner.position
  model.time+=.25
  model.room_rush.tick(model,.25)
  check(not runner.has("failed_room") and runner.target>=0 and runner.target!=lost_target,"failed approach offers another reachable route")
  check(runner.position.distance_to(stalled)<=22.502,"replan does not reset or boost the actor")
 check(model.can_walk(origin) and model.rooms.all(func(room):return room.owner<0),"an advisory plan cannot create a distant claim")
