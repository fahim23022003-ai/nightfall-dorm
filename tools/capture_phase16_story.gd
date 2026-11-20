extends "res://tools/capture_living_story.gd"
## Native Story briefing and real result UI on an isolated prepared profile.

func run() -> void:
 var args:=OS.get_cmdline_user_args()
 if args.size()!=1 or not args[0].is_absolute_path():
  push_error("Pass an absolute capture directory after --.")
  quit(2)
  return
 directory=args[0]
 DirAccess.make_dir_recursive_absolute(directory)
 root.size=Vector2i(1280,720)
 for flag: String in ["NIGHTFALL_PHASE16","NIGHTFALL_LIVING_NIGHTMARE","NIGHTFALL_SURVIVOR_REBIRTH","NIGHTFALL_PROCEDURAL_MAPS_V2","NIGHTFALL_FULL_ROOM_GRID","NIGHTFALL_VISUAL_REBIRTH"]:
  OS.set_environment(flag,"1")
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://phase16-story-visual-%d.json" % OS.get_process_id())
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 await process_frame
 preload("res://tests/onboarding_test_support.gd").skip(game)
 game.onboarding.set_process(false)
 for level: int in [4,36,29]:
  game.return_menu()
  verify(stage_track(level-1),"Prepare valid isolated Story history through level "+str(level-1))
  game.ui.menu_start.pressed.emit()
  verify(game.ui.current_screen=="story_prepare","Real Story button reaches preparation")
  var timing: Label=game.ui.panel.find_child("StoryEncounterTiming",true,false)
  var route: Label=game.ui.panel.find_child("StoryRoutePreview",true,false)
  var briefing: Label=game.ui.panel.find_child("StoryBriefing",true,false)
  var mission:=StoryCatalog.mission(level)
  verify(timing!=null and timing.text.begins_with("%ds" % mission.preparation),"The displayed preparation time matches rules")
  verify(route!=null and route.text.contains(mission.topology.replace("_"," ").capitalize()),"Actual route family preview")
  if mission.chapter_start:
   verify(briefing!=null and briefing.text.begins_with(mission.chapter_opening),"First mission establishes its chapter premise")
  await image("story-level-%02d-briefing" % level)
 press("StartStoryMission")
 verify(game.ui.current_screen=="story_lobby","Preview uses the real Ready lobby")
 await create_timer(.35).timeout
 press("LobbyReady")
 var deadline:=Time.get_ticks_msec()+12000
 while game.mode=="story_lobby" and Time.get_ticks_msec()<deadline:
  await create_timer(.1).timeout
 if game.mode=="match" and game.model.story_level==29:
  await settle_record()
 else:
  verify(false,"Lobby Ready did not start the requested match")
 game.audio_system.shutdown()
 game.queue_free()
 await create_timer(.4).timeout
 print("PHASE16_STORY_CAPTURE_FAILURES=",failures)
 quit(int(failures>0))


func settle_record() -> void:
 var model: MatchModel=game.model
 var mission:=StoryCatalog.mission(model.story_level)
 verify(model.preparation==mission.preparation,"Game applies live chapter preparation")
 verify(model.haunt_recovery.available_at==model.preparation+mission.encounter.hall,"Game applies live Hall availability")
 verify(model.map_data.family==mission.topology,"Real match matches briefing topology")
 var room: RoomState=model.rooms[0]
 model.player_position=room.door_position()-room.door_normal()*35.0
 game.interact_survivor()
 verify(model.player_room==0,"Real claimant owns the legal room")
 model.player_position=room.bed_position()
 game.interact_survivor()
 verify(room.sleeping,"Real bed interaction prepares defense")
 model.time=model.preparation+46.0
 room.occupied_seconds=46.0
 # A prepared final-hit fixture isolates the result screen without inventing
 # a clear or a reward. The production damage and settlement paths make both.
 model.hunter.hp=1.0
 model.hunter.state=HunterState.State.SEEK
 model.apply_target_damage(1,50.0,room.index)
 model.tick(0.05)
 game._process(0)
 verify(game.ui.current_screen=="story_result" and model.result=="victory","Production Story settlement advances the captured mission")
 var result: Dictionary=game.last_progression.get("story",{})
 verify(result.get("position")==30 and result.get("checkpoint")==25 and result.get("reward_xp",0)>0,"Real receipt supplies next level, checkpoint and first-clear XP")
 var discovery: Label=game.ui.panel.find_child("StoryResultDiscovery",true,false)
 verify(discovery!=null and discovery.text==mission.discovery,"Clear reveals the authored mission lore")
 await image("story-level-29-result")
 game.ui.campaign.story_ui.show_archive()
 press("StoryArchiveChapter_06")
 var archived: Label=game.ui.panel.find_child("StoryArchiveDiscovery_29",true,false)
 verify(archived!=null and archived.text.contains(mission.discovery),"Lore remains in its archive after returning to the menu")
 verify(game.ui.panel.find_child("StoryArchiveDiscovery_30",true,false)==null,"Archive withholds lore for the next uncleared level")
 await image("story-chapter-06-archive")
