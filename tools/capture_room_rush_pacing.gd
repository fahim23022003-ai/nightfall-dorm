extends "res://tools/capture_nightmare_maps_v2.gd"
## Replay the matched Spine opening at normal speed in the actual game viewport.

const PACE_STEP:=1.0/24.0
const CLIP_FRAMES:=216

func run() -> void:
 var args:=OS.get_cmdline_user_args()
 if args.size()!=1 or not args[0].is_absolute_path():
  push_error("Pass an absolute capture directory after --")
  quit(2)
  return
 directory=args[0]
 DirAccess.make_dir_recursive_absolute(directory.path_join("frames"))
 root.size=Vector2i(1280,720)
 OS.set_environment("NIGHTFALL_SURVIVOR_REBIRTH","1")
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://phase16-rush-native.json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 await process_frame
 preload("res://tests/onboarding_test_support.gd").skip(game)
 game.onboarding.set_process(false)
 var model:=MatchModel.new()
 model.procedural_v2_requested=true
 model.reset(8649)
 verify(model.configure_map("abandoned_dorm"),"Spine fixture configures with its original map seed")
 verify(model.begin_room_rush(41),"original shared spawn configures with the same attempt id")
 game._adopt_session(model)
 game.set_process(false)
 verify(model.room_rush_spawn()==Vector2(2416,2136),"native run keeps the matched shared spawn")
 verify(model.rooms.all(func(room):return room.owner<0),"initial intentions do not reserve rooms")
 await image("shared-spawn")
 var paths:=model.room_rush.routes_to_vacant_rooms(model,model.player_position)
 var distance:=INF
 var closest:=-1
 for index: int in paths:
  var length:=model.room_rush.route_length(model.player_position,paths[index])
  if length<distance:
   distance=length
   closest=index
 if closest<0:
  quit(1)
  return
 var initial:=model.room_rush_runners().map(func(runner):return runner.target)
 var walk:Array=paths[closest].duplicate()
 var claimed_at:=-1.0
 for frame in range(CLIP_FRAMES):
  if not walk.is_empty():travel_player(model,walk)
  if walk.is_empty() and model.player_room<0:
   game.interact_survivor()
   if model.player_room>=0:claimed_at=model.time
  game._process(PACE_STEP)
  await render()
  if root.get_texture().get_image().save_jpg(directory.path_join("frames/%04d.jpg" % frame),.90)!=OK:
   verify(false,"save normal-speed frame")
   break
 await image("human-claimed")
 verify(model.player_room==closest and claimed_at>=0.0,"human wins a legitimate uncoupled arrival along the same route")
 if game.macro_overview()==false:game.toggle_map()
 game.focus_camera(true)
 await image("map-after-claim")
 var report:=FileAccess.open(directory.path_join("capture.json"),FileAccess.WRITE)
 report.store_string(JSON.stringify({"fps":24,"frames":CLIP_FRAMES,"preparation":model.preparation,"initial":initial,"human_room":model.player_room,"human_claim_seconds":claimed_at,"headless_spine_idle_fixture_has_same_seed_and_nonce":true,"errors":errors},"  ")+"\n")
 report.close()
 game.audio_system.shutdown()
 game.queue_free()
 await process_frame
 print("PHASE16_RUSH_NATIVE_FAILURES=",errors.size())
 quit(int(not errors.is_empty()))

func travel_player(model: MatchModel, path: Array) -> void:
 var remaining:=PACE_STEP
 while not path.is_empty() and remaining>.00001:
  var point: Vector2=path.front()
  var start: Vector2=model.player_position
  var distance:=start.distance_to(point)
  if distance<=.10:
   path.pop_front()
   continue
  var delta:=minf(remaining,distance/model.SURVIVOR_SPEED)
  model.move_player(start.direction_to(point),delta)
  remaining-=delta
  if model.player_position.distance_to(point)>.10:break
