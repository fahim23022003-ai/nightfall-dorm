extends "res://tools/capture_nightmare_maps_v2.gd"
## Controlled siege setup. Tells, repairs, strikes and movement use production code.
const MATCH_SEED := 21
const STAGE := "stage_1"
const MAX_APPROACH_TICKS := 650

func run():
 var args := OS.get_cmdline_user_args()
 if args.is_empty() or not args[0].is_absolute_path():
  push_error("Pass an absolute evidence directory after --.")
  quit(2)
  return
 directory = args[0]
 DirAccess.make_dir_recursive_absolute(directory)
 root.size = Vector2i(1280,720)
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://hell-siege-capture-only.json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 await process_frame
 if is_instance_valid(game.onboarding):
  preload("res://tests/onboarding_test_support.gd").skip(game)
  game.onboarding.set_process(false)
 game.profile.settings.graphics_quality="medium"
 await commit_episode()
 await reassess_episode()
 receipt.errors=errors
 var file := FileAccess.open(directory.path_join("capture.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(receipt,"  ")+"\n")
 file.close()
 game.audio_system.shutdown()
 game.queue_free()
 await process_frame
 print("HELL_TACTICS_CAPTURE_FAILURES=",errors.size())
 quit(1 if not errors.is_empty() else 0)

func siege_fixture(productive: bool) -> MatchModel:
 var model := MatchModel.new()
 model.procedural_v2_requested=true
 model.reset(MATCH_SEED)
 verify(model.configure_match("hell") and model.configure_stage(STAGE),"native Hell Campaign fixture")
 verify(model.configure_strategy(MATCH_SEED,"stalker") and model.configure_balance(),"normal first-form Hunter and current balance")
 verify(model.is_procedural() and model.claim_room(0),"V2 room claimed via production command")
 var player_room := model.player()
 model.player_position=player_room.bed_position()
 verify(model.sleep_player(),"normal bed interaction")
 model.bot_claimed=5
 player_room.bed_level=2
 player_room.gold=900
 player_room.electricity=60
 player_room.door_level=4 if productive else 1
 player_room.door_hp=player_room.max_hp()*.63 if productive else 30
 var preset: Array=["turret","generator","repair","heavy"] if productive else ["turret","generator"]
 for kind in preset:
  verify(pay_for_machine(model,kind),"paid fixture purchase: "+kind)
 # Supply the nearest reachable sleeping teammate. Both cases assess two
 # real doors, using the same seeded layout and their generated approaches.
 var travel := model.hunter_route_costs(player_room.door_approach())
 var closest := INF
 var teammate: RoomState
 for room: RoomState in model.rooms:
  var steps: float=travel.get(room.index,INF)
  if room.index==player_room.index or steps>=closest:
   continue
  closest=steps
  teammate=room
 verify(teammate!=null,"fixture has a legally reachable alternate door")
 if teammate!=null:
  teammate.owner=1
  teammate.profile=Catalog.BOT_PROFILES[0]
  teammate.resident_position=teammate.bed_position()
  teammate.sleeping=true
  teammate.closed=true
  teammate.door_level=8
  teammate.door_hp=teammate.max_hp()
 game._adopt_session(model)
 game.set_process(false)
 model.time=model.preparation+35.0
 var hunter:=model.hunter
 hunter.state=HunterState.State.ATTACK
 var active_room: RoomState=player_room if productive or teammate==null else teammate
 hunter.position=active_room.door_approach()
 hunter.target=active_room.index
 hunter.siege_seconds=20
 hunter.target_time=20
 hunter.reassess_seconds=20
 hunter.siege_start_hp=active_room.max_hp() if productive else active_room.door_hp
 hunter.tactical_cooldown=1000
 hunter.arcane.cooldown=1000
 hunter.nightmare.cooldown=1000
 hunter.boss_policy.enabled=false
 hunter.cooldown=2.4
 game.focus_camera(true)
 game.ui.update_match()
 return model

func pay_for_machine(model: MatchModel, kind: String) -> bool:
 var room := model.player()
 var grid: Rect2=room.spatial.grid_bounds()
 var points: Array[Vector2]=[]
 for y in range(24,int(grid.size.y),32):
  for x in range(24,int(grid.size.x),32):
   points.append(room.spatial.aligned(grid.position+Vector2(x,y),kind,0))
 var approach: Vector2=room.door_approach()
 var nearest:=kind in DefenseEffects.WEAPONS
 points.sort_custom(func(a: Vector2,b: Vector2):
  return a.distance_squared_to(approach)<b.distance_squared_to(approach) if nearest else a.distance_squared_to(approach)>b.distance_squared_to(approach))
 for point in points:
  if room.spatial.purchase_reason(kind,point,0)=="" and model.place_building(kind,point):return true
 return false

func get_event(model: MatchModel, name: String, owner: int) -> Dictionary:
 for event: Dictionary in model.presentation_events:
  if event.type==name and event.room==owner:
   return event
 return {}

func record_frame(chapter: String, frame: int):
 var folder:=directory.path_join(chapter)
 DirAccess.make_dir_recursive_absolute(folder)
 await render()
 var frame_image:=root.get_texture().get_image()
 verify(frame_image.get_size()==Vector2i(1280,720),"native 720p frame")
 verify(frame_image.save_jpg(folder.path_join("%04d.jpg"%frame),.90)==OK,"recorded a Godot frame")

func warning_visible() -> String:
 if game.ui.warning_label.visible:
  return game.ui.warning_label.text
 return ""

func commit_episode():
 var model:=siege_fixture(true)
 var room:=model.player()
 var record:=get_event(model,"hunter_commit",room.index)
 var warning:=""
 var repaired:=false
 var repair_gold:=0.0
 var restoration:=0.0
 var strikes_at_repair:=0
 var frames:=0
 for frame in range(132):
  game._process(STEP)
  if record.is_empty():
   record=get_event(model,"hunter_commit",room.index)
  if warning.is_empty() and not record.is_empty() and "HUNTER COMMITS" in warning_visible():
   warning=warning_visible()
   await image("hell-commit-warning")
  if not repaired and not warning.is_empty() and frame>=22:
   var gold: float=room.gold
   var hp: float=room.door_hp
   await key_event(KEY_R)
   repaired=true
   strikes_at_repair=model.hunter.attacks
   repair_gold=gold-room.gold
   restoration=room.door_hp-hp
   await image("hell-paid-repair")
  await record_frame("commit",frame)
  frames+=1
 verify(record.get("reason","")=="breach_progress","productive Hell siege emits its commit reason")
 verify(record.get("room",-1)==room.index and not warning.is_empty(),"player sees the real commit tell")
 verify(repaired and repair_gold>0 and restoration>0,"native R pays normal gold and raises door HP")
 verify(model.hunter.attacks>strikes_at_repair and model.hunter.target==room.index,"Hunter strikes after the repair and retains the productive siege")
 receipt.commit={"seed":MATCH_SEED,"stage":STAGE,"difficulty":model.difficulty,"family":model.map_data.get("family",""),"event":record,"warning":warning,"manual_repair_gold":repair_gold,"manual_repair_hp":restoration,"paid_buildings":room.buildings.size(),"actual_strikes_after_repair":model.hunter.attacks-strikes_at_repair,"frames":frames}

func reassess_episode():
 var model:=siege_fixture(false)
 var room:=model.player()
 var original_room: int=model.hunter.target
 var tell: Dictionary={}
 var warning:=""
 var steps:=0
 var initial: Vector2=model.rooms[original_room].door_approach()
 var first_samples: Array[Vector2]=[initial]
 var actual_distance:=0.0
 for frame in range(36):
  var before: Vector2=model.hunter.position
  game._process(STEP)
  steps+=1
  var at: Vector2=model.hunter.position
  var length:=before.distance_to(at)
  verify(model.navigation_walkable(at) and length<=model.hunter.speed*STEP+.03,"early change of approach follows legal movement")
  if length>.01:
   first_samples.append(at)
   actual_distance+=length
  if tell.is_empty():
   tell=get_event(model,"hunter_reassess",original_room)
  if warning.is_empty() and not tell.is_empty() and "HUNTER CHANGES APPROACH" in warning_visible():
   warning=warning_visible()
   await image("hell-switch-warning")
  await record_frame("reassess",frame)
 verify(tell.get("reason","")=="better_breach_route","stalled siege emits better route reason")
 verify(not warning.is_empty(),"player sees real target-change tell")
 var next:=int(tell.get("next_room",-1))
 if next!=room.index or next==original_room:
  verify(false,"switch chooses the real player room from the teammate's door")
  return
 var finish:=model.rooms[next].door_approach() as Vector2
 await key_event(KEY_M)
 verify(game.full_map and game.macro_overview(),"native map action shows tactical route")
 game.focus_camera(true)
 var trail:=Line2D.new()
 trail.default_color=Color("E7C886")
 trail.width=2.4/game.camera.zoom.x
 trail.antialiased=true
 trail.z_index=3
 game.add_child(trail)
 var samples: Array=first_samples.map(arr)
 for point in first_samples:
  trail.add_point(point+game.MAP_OFFSET)
 var frames:=0
 for frame in range(ceili(float(MAX_APPROACH_TICKS)/5.0)):
  for step in range(5):
   var before: Vector2=model.hunter.position
   game._process(STEP)
   steps+=1
   var at: Vector2=model.hunter.position
   var length:=before.distance_to(at)
   actual_distance+=length
   verify(model.navigation_walkable(at) and length<=model.hunter.speed*STEP+.03,"switch to the player room follows legal movement")
   if length>.01:
    samples.append(arr(at))
    trail.add_point(at+game.MAP_OFFSET)
   if at.distance_to(finish)<3:
    break
  await record_frame("route",frame)
  frames+=1
  if model.hunter.position.distance_to(finish)<3:
   break
 verify(model.hunter.target==next and model.hunter.position.distance_to(finish)<3 and model.hunter.state==HunterState.State.ATTACK,"other room becomes actual siege target")
 await image("hell-switch-arrival")
 trail.queue_free()
 await process_frame
 receipt.reassess={"seed":MATCH_SEED,"stage":STAGE,"difficulty":model.difficulty,"family":model.map_data.get("family",""),"event":tell,"warning":warning,"initial_door":arr(initial),"alternate_door":arr(finish),"actual_travel_distance_after_tell":actual_distance,"actual_positions":samples,"arrival_state":model.hunter.state,"frames":36,"route_frames":frames,"elapsed_ticks":steps}
