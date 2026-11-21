extends "res://tools/full_room_grid/check_full_room_match.gd"
## Reproduce an isolated Story profile and record selected intervals of full, legal matches.
## Usage: Godot --script res://tools/capture_phase23.gd -- OUTPUT SEED_BASE [SHOT_LIST_JSON]
const FRAME_STEP := 0.05
var game
var directory: String
var plan: Array = []
var cases: Array = []
var frame_count := 0
var rendered: Array = []
var receipt: Dictionary
var route: Array = []
var destination_room := -1
var last_event := 0

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() not in [2,3] or not args[0].is_absolute_path() or not args[1].is_valid_int() or int(args[1])<1:
  quit(2)
  return
 directory = args[0]
 DirAccess.make_dir_recursive_absolute(directory)
 if args.size()==3:
  var shots: Variant=JSON.parse_string(FileAccess.get_file_as_string(args[2]))
  if not shots is Array or shots.is_empty() or DisplayServer.get_name()=="headless":
   push_error("Recording requires a graphical Godot session and a nonempty JSON shot list.")
   quit(2)
   return
  plan=shots
  DirAccess.make_dir_recursive_absolute(directory.path_join("frames"))
 grid=true
 root.size=Vector2i(960,540)
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://hunter-film-%d.json" % Time.get_ticks_usec())
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.onboarding.skip()
 game.onboarding.close_welcome()
 game.profile.complete_tutorial()
 game.profile.story=StoryProgress.fresh(int(args[1]))
 game.profile.reward_rng.seed=int(args[1])
 game.change_setting("graphics_quality","low")
 for attempt in range(1,7):
  game.return_menu()
  if not game.profile.pending_spins.is_empty():
   game.profile.claim_spin(game.profile.pending_spins[0].match_id)
  var defend:=attempt>=2
  var bought:=false
  if defend and game.profile.rm_cash>=OnboardingCatalog.PRICES.repair:
   bought=game.profile.buy_common("repair",game.profile.purchase_serial+1)
  if defend and game.profile.inventory.get("repair",0)>0 and "repair" not in game.profile.item_loadout:
   game.profile.equip_item("repair")
  var difficulty:="hell" if attempt==1 else "standard"
  if not game.start_story(difficulty):
   failures+=1
   push_error("Story launch failed on attempt %d" % attempt)
   break
  var model: MatchModel=game.model
  if not model.uses_story_intelligence() or not model.room_rush_active():
   failures+=1
   push_error("The Story match must use the Phase 23 preview and physical room rush.")
   break
  receipt={"attempt":attempt,"seed":model.map_seed,"level":model.story_level,
   "archetype":model.hunter.archetype,"family":model.map_data.family,"difficulty":difficulty,
   "policy":"earned balanced defense" if defend else "passive","bought_repair":bought,
   "loadout":game.profile.item_loadout.duplicate(),"events":[],"item":[]}
  await play(attempt,defend)
  cases.append(receipt)
  print("FILM ",attempt," ",model.result," ",model.time," HP=",model.hunter.hp," room=",model.player_room+1," item=",receipt.item)
  if attempt>=3 and cases.any(func(c):return c.result=="victory") and cases.any(func(c):return c.result=="defeat") and cases.any(func(c):return not c.item.is_empty()):break
 var out:=FileAccess.open(directory.path_join("receipt.json"),FileAccess.WRITE)
 out.store_string(JSON.stringify({"seed_base":int(args[1]),"matches":cases,"frames":frame_count,"rendered":rendered,"failures":failures},"  ")+"\n")
 out.close()
 game.audio_system.shutdown()
 game.queue_free()
 await process_frame
 quit(int(failures>0))

func play(attempt: int,defend: bool):
 var model: MatchModel=game.model
 cached_candidates.clear()
 route.clear()
 destination_room=-1
 last_event=0
 var tick:=0
 var camera_mode: String=""
 while model.result=="" and model.time<900:
  if model.player()==null or not model.player().sleeping:
   approach_bed(model)
  elif tick%30==0 and defend:
   var room:=model.player()
   var slot: int=game.profile.item_loadout.find("repair")
   if slot>=0 and room.door_hp<=room.max_hp()*.80 and game.profile.inventory.get("repair",0)>0:
    var old: float=room.door_hp
    if game.activate_item(slot):
     receipt.item.append({"time":model.time,"hp_before":old,"hp_after":room.door_hp})
   act(model)
  var shot:=shot_for(attempt,model.time)
  if plan.is_empty():
   model.tick(FRAME_STEP)
  else:
   # Keep all event consumers current between edits. Otherwise the first frame
   # can replay an old evolution warning or stack an earlier siege's hit cues.
   var camera_shot:=shot if not shot.is_empty() else shot_for(attempt,model.time+2.0)
   var camera_target: String=camera_shot.get("camera","hunter") if not camera_shot.is_empty() else "player"
   if camera_target=="hunter":
    game.phase20_free_camera=true
    game.phase20_camera_anchor=model.hunter.position+game.MAP_OFFSET
    game.zoom_factor=1.35
   elif camera_mode!="player":
    game.return_to_my_room()
   camera_mode=camera_target
   if not shot.is_empty():track_shot(shot)
   game._process(FRAME_STEP)
   if not shot.is_empty():
    await save_frame()
   elif not camera_shot.is_empty():
    # Movie Maker advances real audio and the viewport for pre-roll, then the
    # editor cuts both tracks together at the first retained frame.
    await process_frame
    await RenderingServer.frame_post_draw
  observe(model)
  tick+=1
  if tick%60==0 and shot.is_empty() and shot_for(attempt,model.time+2.0).is_empty():await process_frame
 if model.result.is_empty() or not model.terminal_recorded:
  failures+=1
  push_error("No settled terminal outcome")
 if game.mode=="match":game._process(0)
 receipt.merge({"result":model.result,"terminal_time":model.time,"room":model.player_room+1,
  "player_damage":model.player().damage_dealt if model.player()!=null else 0.0,
  "hunter_hp":model.hunter.hp,"settled_rm":game.last_progression.get("rm_cash",0)})
 for shot: Dictionary in plan:
  if int(shot.attempt)!=attempt or not shot.has("ending"):continue
  await create_timer(.90).timeout
  track_shot(shot)
  for frame in range(roundi(float(shot.ending)/FRAME_STEP)):
   await save_frame()

func approach_bed(model: MatchModel):
 var room:=model.player()
 if room==null:
  if destination_room<0 or model.rooms[destination_room].owner>=0:
   var options:=model.room_rush.routes_to_vacant_rooms(model,model.player_position)
   var best:=INF
   for index: int in options:
    var cost:=RoomRush.route_length(model.player_position,options[index])
    if cost<best:
     destination_room=index
     best=cost
   if is_inf(best):return
   route=options[destination_room].duplicate()
  if model.room_rush.can_claim(model,destination_room,model.player_position):
   model.interact()
   route.clear()
   return
 else:
  if model.player_position.distance_to(room.bed_position())<=60.0:
   model.interact()
   return
  if route.is_empty():
   route=model.player_navigation_path(model.player_position,room.bed_position()+room.door_normal()*42.0)
 while not route.is_empty() and model.player_position.distance_to(route.front())<=1.0:
  route.pop_front()
 if not route.is_empty():
  model.move_player((Vector2(route[0])-model.player_position)/(model.SURVIVOR_SPEED*FRAME_STEP),FRAME_STEP)

func observe(model: MatchModel):
 for event: Dictionary in model.presentation_events:
  if event.id<=last_event:continue
  last_event=event.id
  if event.type not in ["hunter_target_choice","approach","encounter","hunter_commit","hunter_reassess","door_damage","repair_started","door_upgrade","resident_eliminated"]:continue
  var entry:={"time":snappedf(event.time,.001),"event":event.type,"room":event.room+1}
  for key: String in ["reason","damage","hp","current_cost","alternative_cost","stalled","progress","estimated_cost","best_cost","comparable_doors","reachable_options","recent_selections"]:
   if event.has(key):entry[key]=event[key]
  if event.has("next_room"):entry.next_room=event.next_room+1
  receipt.events.append(entry)

func shot_for(attempt: int, seconds: float) -> Dictionary:
 for shot: Dictionary in plan:
  if int(shot.attempt)==attempt and shot.has("start") and seconds+.00001>=float(shot.start) and seconds+.00001<float(shot.end):return shot
 return {}

func track_shot(shot: Dictionary):
 if rendered.is_empty() or rendered.back().label!=shot.label:
  rendered.append({"label":shot.label,"start_frame":frame_count,"engine_frame":Engine.get_frames_drawn(),"shot":shot.duplicate()})

func save_frame():
 game.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 var image:=root.get_texture().get_image()
 if image.get_size()!=Vector2i(960,540) or image.save_jpg(directory.path_join("frames/%05d.jpg" % frame_count),.93)!=OK:
  failures+=1
 frame_count+=1
