extends "res://tools/full_room_grid/check_full_room_match.gd"
## Render Story screens using an isolated profile and real terminal combat.

const FIXTURE_SEED := 32157
var game
var directory: String
var receipts := {}

func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=1 or not args[0].is_absolute_path():
  push_error("Pass the absolute capture directory after --.")
  quit(2)
  return
 directory=args[0]
 DirAccess.make_dir_recursive_absolute(directory)
 root.size=Vector2i(1280,720)
 OS.set_environment("NIGHTFALL_LIVING_NIGHTMARE","1")
 OS.set_environment("NIGHTFALL_PROCEDURAL_MAPS_V2","1")
 OS.set_environment("NIGHTFALL_FULL_ROOM_GRID","1")
 OS.set_environment("NIGHTFALL_VISUAL_REBIRTH","1")
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://living-story-visual-%d.json" % OS.get_process_id())
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 await process_frame
 preload("res://tests/onboarding_test_support.gd").skip(game)
 game.onboarding.set_process(false)
 game.profile.story=StoryProgress.fresh(FIXTURE_SEED)
 game.profile.save_profile()
 game.return_menu()
 verify(game.ui.menu_start.text=="CONTINUE STORY","single main menu Story action")
 await image("main-menu")
 game.ui.menu_start.pressed.emit()
 verify(game.ui.current_screen=="story_prepare","main menu opens Story preparation")
 await image("level-01-preparation")
 press("StoryDifficulty_hard")
 verify(game.profile.selected_difficulty=="hard","difficulty track selection persisted")
 await image("hard-track")
 press("StoryDifficulty_standard")
 press("StartStoryMission")
 verify(game.mode=="match" and game.model.story_level==1,"native preparation launches Level 01")
 await play_to_terminal("level-01",true)
 verify(game.last_progression.get("story",{}).get("position",-1)==2,"Level 01 victory advances through the normal UI settlement")
 if game.last_progression.get("story",{}).get("position",-1)==2:
  await sequence("advance")
  await image("level-01-victory")
 clear_spin()

 game.return_menu()
 verify(stage_track(5),"seed a temporary Chapter 2 history")
 game.ui.menu_start.pressed.emit()
 await sequence("chapter")
 await image("chapter-02-opening")

 game.return_menu()
 verify(stage_track(16),"seed a temporary snapshot at Level 17")
 game.ui.menu_start.pressed.emit()
 press("StartStoryMission")
 await play_to_terminal("level-17",false)
 verify(game.last_progression.get("story",{}).get("position",-1)==16,"real exposed-player loss drops Level 17 to 16")
 if game.last_progression.get("story",{}).get("position",-1)==16:
  await sequence("setback")
  await image("level-17-defeat")
 clear_spin()

 game.return_menu()
 verify(stage_track(49),"seed a temporary snapshot at Level 50")
 game.ui.menu_start.pressed.emit()
 await image("level-50-preparation")
 press("StartStoryMission")
 await play_to_terminal("level-50",true)
 verify(game.last_progression.get("story",{}).get("finished",false),"real final victory settles at 50")
 if game.last_progression.get("story",{}).get("finished",false):
  await image("level-50-victory")
  clear_spin()
  press("ContinueStoryResult")
  await image("story-archive")

 var file:=FileAccess.open(directory.path_join("capture.json"),FileAccess.WRITE)
 if file!=null:
  file.store_string(JSON.stringify({"failures":failures,"cases":receipts,"seed_base":FIXTURE_SEED},"  ")+"\n")
  file.close()
 game.audio_system.shutdown()
 game.queue_free()
 await process_frame
 print("LIVING_STORY_CAPTURE_FAILURES=",failures)
 quit(int(failures>0))

func press(name: String):
 var button: Button=game.ui.panel.find_child(name,true,false)
 verify(button!=null and not button.disabled,"usable button "+name)
 if button!=null and not button.disabled:button.pressed.emit()

func clear_spin():
 if not game.profile.pending_spins.is_empty():
  var id:=int(game.profile.pending_spins[0].match_id)
  verify(not game.profile.claim_spin(id).is_empty(),"earned spin receipt can be acknowledged")
 game.ui.show_result()

func stage_track(cleared: int) -> bool:
 var story:=StoryProgress.fresh(FIXTURE_SEED)
 for level in range(1,cleared+1):
  if StoryProgress.settle(story,"standard",level,true,level).is_empty():return false
 game.profile.story=story
 game.profile.selected_difficulty="standard"
 game.profile.next_match_id=maxi(game.profile.next_match_id,cleared+1)
 return game.profile.save_profile()

func play_to_terminal(label: String, defend: bool):
 if game.mode!="match" or game.model.story_level==0:
  verify(false,"Story match could not start")
  return
 var model: MatchModel=game.model
 var start_seed:=model.map_seed
 var mission:=StoryCatalog.mission(model.story_level)
 verify(model.map_data.get("family","")==mission.topology,"authored topology selected")
 var steps:=0
 if defend:
  cached_candidates.clear()
  grid=true
  verify(model.claim_room(int(mission.level)%6),"claim test room")
  model.player_position=model.player().bed_position()
  verify(model.sleep_player(),"sleep normally after placing test player at bed")
 while model.result.is_empty() and model.time<750.0:
  if defend and steps%6==0:act(model)
  model.tick(.05)
  steps+=1
 verify(not model.result.is_empty(),"simulation reached a real terminal result")
 game._process(0)
 verify(game.ui.current_screen=="story_result","terminal state renders Story result")
 receipts[label]={"result":model.result,"time":model.time,"steps":steps,"boss_transformed":model.hunter.transformed,"start_seed":start_seed,"family":model.map_data.family,"award":game.last_progression.get("story",{})}
 print("LIVING_STORY_CAPTURE ",label," ",model.result," match time=",model.time," award=",game.last_progression.get("story",{}))

func sequence(name: String):
 var folder:=directory.path_join(name)
 DirAccess.make_dir_recursive_absolute(folder)
 var before:=Engine.max_fps
 Engine.max_fps=24
 for index in range(49):
  game.queue_redraw()
  await process_frame
  await RenderingServer.frame_post_draw
  var frame:=root.get_texture().get_image()
  verify(frame.save_jpg(folder.path_join("%04d.jpg" % index),.9)==OK,"save Story motion frame")
 Engine.max_fps=before

func image(name: String):
 await create_timer(.72).timeout
 game.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 var frame:=root.get_texture().get_image()
 verify(frame.get_size()==Vector2i(1280,720),"native drawable for "+name)
 verify(frame.save_png(directory.path_join(name+".png"))==OK,"save "+name)

func verify(ok: bool, message: String):
 if not ok:
  failures+=1
  push_error(message)
