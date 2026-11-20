extends "res://tools/capture_visual_rebirth.gd"
## Real Story menu input, native lobby timer and game Master audio.

func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=2 or not args[0].is_absolute_path() or args[1] not in ["early","auto","rush"]:
  push_error("Pass an absolute output directory and early, auto, or rush.")
  quit(2)
  return
 var destination:=args[0].trim_suffix("/")
 var early:=args[1]!="auto"
 output=destination.get_base_dir()+"/"
 phase=destination.get_file()
 DirAccess.make_dir_recursive_absolute(destination)
 root.size=Vector2i(1280,720)
 await setup_game()
 game.onboarding.close_welcome()
 game.audio_system.set_mix({"music_mode":"classic","music":.50,"effects":.82,"ambient":.50})
 game.enter_game()
 for frame in range(21):
  await film_frame()
 check(game.ui.current_screen=="story_prepare" and game.audio_system._active_score=="music_calm","real Story preparation and its calm score")
 var start: Button=game.ui.panel.find_child("StartStoryMission",true,false)
 check(is_instance_valid(start),"real Story Start Mission control")
 if not is_instance_valid(start):
  await _finish()
  return
 var prior_model: MatchModel=game.model
 var prior_time: float=prior_model.time
 var prior_story: Dictionary=game.profile.story.duplicate(true)
 var prior_session: Dictionary=game.profile.active_match.duplicate(true)
 var next_id: int=game.profile.next_match_id
 var prior_wallet: Dictionary=game.profile.inventory.duplicate(true)
 await click(start)
 var lobby=game.story_lobby
 check(is_instance_valid(lobby) and game.mode=="story_lobby","Start Mission opens the production lobby")
 if not is_instance_valid(lobby):
  await _finish()
  return
 DisplayServer.window_move_to_foreground()
 for frame in range(6):
  await film_frame()
 var staged_focus: bool=not lobby.window_focused
 if staged_focus:
  lobby._focus_entered() # Dummy X display can launch without a window manager.
 check(lobby.armed and lobby.seconds_left()==15,"visible initialized countdown begins at 15 seconds")
 var initial_roster: Array=lobby.roster()
 var joins: Array=[]
 var ready_at:=-1.0
 var loading_at:=-1.0
 var waiting_frames:=0
 var ready_clicked:=false
 var early_phase_preserved:=false
 var cue_set:={}
 var prep_frozen:=true
 var countdown_seen:={}
 for frame in range(436):
  if early and not ready_clicked and lobby.elapsed>=1.7:
   var before: Array=lobby.roster().slice(1)
   await click(lobby.find_child("LobbyReady",true,false))
   ready_clicked=true
   early_phase_preserved=lobby.human_ready and not lobby.loading and before==lobby.roster().slice(1)
  if game.mode!="story_lobby":
   break
  waiting_frames+=1
  await film_frame()
  if game.mode!="story_lobby":
   break
  prep_frozen=prep_frozen and game.model==prior_model and prior_model.time==prior_time and game.profile.story==prior_story and game.profile.active_match==prior_session and game.profile.inventory==prior_wallet
  countdown_seen[lobby.seconds_left()]=true
  var bots: int=lobby.ready_ai_count()
  if bots>joins.size():
   joins.append(lobby.elapsed)
  if lobby.human_ready and ready_at<0.0:
   ready_at=lobby.elapsed
  if lobby.loading and loading_at<0.0:
   loading_at=lobby.elapsed
  cue_set[game.audio_system._active_score]=true
 check(prep_frozen,"nothing touches the model clock, player inventory or story save in the lobby")
 check(game.mode=="match" and game.model.run_kind=="campaign" and game.profile.next_match_id==next_id+1 and game.profile.active_match.get("id",0)==next_id,"handoff starts exactly one real Story match")
 check(game.model.story_level>0,"the launched match retains the selected Story mission")
 check(joins.size()==5 and joins[0]<joins[4],"AI joined in five real staggered steps")
 check(cue_set.has("music_intro") and int(game.audio_system.lobby_cue_counts.get("join",0))==5,"lobby score and individual audio cues went through the real director")
 if early:
  check(early_phase_preserved and ready_at>0.0 and loading_at>ready_at and loading_at<15.0 and loading_at>=float(joins[4]),"early human readiness waits for the last independent AI")
 else:
  check(is_equal_approx(ready_at,15.0) and is_equal_approx(loading_at,15.0) and countdown_seen.has(1),"auto-ready starts loading only at 15 seconds")
 var claimed_room: int=-1
 if args[1]=="rush" and game.mode=="match":
  claimed_room=await race_to_a_room()
 else:
  for frame in range(34):
   await film_frame()
 check(game.audio_system._active_score!="music_intro","lobby opening score hands off to real gameplay")
 var file:=FileAccess.open(destination.path_join("lobby.json"),FileAccess.WRITE)
 check(file!=null,"lobby evidence receipt writable")
 if file!=null:
  file.store_string(JSON.stringify({"branch":args[1],"fps":24,"viewport":[1280,720],"staged_focus":staged_focus,"initial_roster":initial_roster,
   "waiting_frames":waiting_frames,"ai_ready_times":joins,"human_ready_time":ready_at,"loading_started_at":loading_at,"unchanged_while_waiting":prep_frozen,
   "audio_cues":game.audio_system.lobby_cue_counts,"gameplay_score":game.audio_system._active_score,"launched_story_level":game.model.story_level,
   "announced_match_id":next_id,"settled_active_match_id":game.profile.active_match.get("id",0),"next_match_id":game.profile.next_match_id,"claimed_room":claimed_room,
   "checks":checks,"failures":failures},"  ")+"\n")
  file.close()
 await _finish()

func race_to_a_room() -> int:
 var model: MatchModel=game.model
 var origin:=model.room_rush_spawn()
 check(model.room_rush_active() and model.room_rush_runners().size()==5 and model.rooms.all(func(room):return room.owner<0),"new gameplay starts with five unclaimed AI runners")
 var paths: Dictionary=model.room_rush.routes_to_vacant_rooms(model,model.player_position)
 var chosen: Array=[]
 var best:=INF
 for route: Array in paths.values():
  var previous: Vector2=model.player_position
  var length:=0.0
  for point: Vector2 in route:
   length+=previous.distance_to(point)
   previous=point
  if length<best:
   best=length
   chosen=route
 for frame in range(7):await film_frame()
 for point: Vector2 in chosen:
  for frame in range(280):
   var gap: Vector2=point-model.player_position
   if gap.length()<.3:break
   model.move_player(gap/(MatchModel.SURVIVOR_SPEED*STEP),STEP)
   await film_frame()
 var key:=InputEventKey.new()
 key.keycode=KEY_E
 key.physical_keycode=KEY_E
 key.pressed=true
 Input.parse_input_event(key)
 await film_frame()
 key=key.duplicate() as InputEventKey
 key.pressed=false
 Input.parse_input_event(key)
 check(model.player_room>=0 and model.player_position.distance_to(origin)>1,"a physical walk and E claim a real room")
 for frame in range(27):await film_frame()
 return model.player_room

func film_frame():
 game._process(STEP)
 game.queue_redraw()
 await RenderingServer.frame_post_draw
 await process_frame
