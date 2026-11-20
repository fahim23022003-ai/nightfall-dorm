extends SceneTree
## Godot Movie Maker records the live game render and Master audio together.

const STEP:=1.0/24.0
const Support=preload("res://tests/onboarding_test_support.gd")
var game
var match_model: MatchModel
var score_transitions: Array[Dictionary]=[]
var seconds:=0.0
var label: Label

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var args:=OS.get_cmdline_user_args()
 if args.is_empty() or not args[0].is_absolute_path():
  push_error("Pass an absolute receipt path after --.")
  quit(2)
  return
 root.size=Vector2i(1280,720)
 Support.prepare()
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 await process_frame
 Support.skip(game)
 game.onboarding.set_process(false)
 game.audio_system.set_mix({"music_mode":"classic","music":.8,"effects":.7,"ambient":.3})

 var overlay:=CanvasLayer.new()
 overlay.layer=40
 root.add_child(overlay)
 label=Label.new()
 label.position=Vector2(24,108)
 label.add_theme_color_override("font_color",Color("#ddc6a8"))
 label.add_theme_color_override("font_outline_color",Color("#101317"))
 label.add_theme_constant_override("outline_size",6)
 label.add_theme_font_size_override("font_size",19)
 overlay.add_child(label)
 await segment("Main menu",4.0)

 match_model=MatchModel.new()
 match_model.reset(10358)
 match_model.configure_match("hell")
 match_model.configure_stage("stage_2")
 match_model.configure_balance()
 match_model.configure_strategy(10358,"stalker")
 game._adopt_session(match_model)
 var room: RoomState=match_model.rooms[1]
 match_model.claim_room(1)
 match_model.player_position=room.bed_position()
 match_model.sleep_player()
 game.focus_camera(true)
 await segment("Quiet preparation",4.0)

 var hunter:=match_model.hunter
 match_model.time=match_model.preparation+5.0
 hunter.target=room.index
 hunter.state=HunterState.State.MOVE
 hunter.position=room.door_approach()+room.door_normal()*210.0
 await segment("Hunter approach",4.5)

 hunter.position=room.door_approach()
 hunter.tick(STEP,match_model)
 await segment("Door siege · five-second heartbeat",6.0,true,hunter.attacks+1)
 room.door_hp=room.max_hp()*.29
 await segment("Desperate defense",4.5,true,hunter.attacks)

 var hall: Dictionary=match_model.map_data.halls.north
 hunter.position=hall.center
 hunter.state=HunterState.State.RECOVER
 hunter.hp=hunter.max_hp*.6
 match_model.haunt_recovery.phase="recover"
 match_model.haunt_recovery.hall_id="north"
 match_model.haunt_recovery.budget=hunter.max_hp*.18
 match_model.record_event("hunter_recovering",hunter.target,{"hall":"north","position":hall.center})
 game.hunter_spectating=true
 game.focus_camera(true)
 await segment("Haunted Hall",4.5)

 game.hunter_spectating=false
 hunter.position=room.door_approach()
 hunter._begin_transformation(match_model)
 game.focus_camera(true)
 await segment("Reaper transformation",4.5,true)
 match_model.wrath.domain_room=room.index
 match_model.wrath.domain_remaining=20.0
 await segment("Crimson Domain",4.5)

 match_model.result="victory"
 game.mode="result"
 game.ui.show_result()
 await segment("Victory",4.0)
 var report:=FileAccess.open(args[0],FileAccess.WRITE)
 report.store_string(JSON.stringify({"transitions":score_transitions,"heartbeat_starts":game.audio_system.event_counts.get("siege_heartbeat",0),"staged":true,"fps":24},"  ")+"\n")
 report.close()
 game.queue_free()
 game=null
 match_model=null
 await process_frame
 quit()

func segment(title: String, length: float, drive_hunter: bool=false, attack_limit: int=-1) -> void:
 label.text="Audio verification · "+title
 var start:=seconds
 for _index in range(roundi(length/STEP)):
  await process_frame
  if game.mode=="match":
   if drive_hunter:
    match_model.time+=STEP
    if attack_limit>=0 and match_model.hunter.attacks>=attack_limit:
     # Hold the staged siege after the verified first strike so the clip
     # includes the heartbeat tail before moving to low door health.
     match_model.hunter.cooldown=maxf(12.0,match_model.hunter.cooldown)
    match_model.hunter.tick(STEP,match_model)
   game.focus_camera(false,STEP)
   game.presentation.update(STEP,match_model)
   game.horror.update(STEP,match_model)
   game.ui.update_match()
  game.audio_system.update_state(STEP,game.model,game.mode,game.hunter_spectating)
  game.queue_redraw()
  seconds+=STEP
 score_transitions.append({
  "start":start,"end":seconds,"scene":title,
  "score":game.audio_system.soundtrack.current,
  "heartbeat_starts":game.audio_system.event_counts.get("siege_heartbeat",0),
 })
