extends SceneTree
## Native gameplay and synchronous Master-bus recording of staged door encounters.
const FPS := 20
const SEED_VALUE := 67
var game
var directory := ""
var stills := false
var began := 0
var last_update := 0
var frame_index := 0
var recorder: AudioEffectRecord
var errors: Array[String]=[]
var timeline: Array[Dictionary]=[]

func _initialize():
 call_deferred("run")

func verify(ok: bool,label: String):
 if ok:return
 errors.append(label)
 push_error(label)

func run():
 var args:=OS.get_cmdline_user_args()
 if args.is_empty() or not args[0].is_absolute_path():
  quit(2)
  return
 directory=args[0]
 stills="--stills" in args
 DirAccess.make_dir_recursive_absolute(directory.path_join("frames"))
 root.size=Vector2i(1280,720)
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://phase16-horror-capture.json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 preload("res://tests/onboarding_test_support.gd").skip(game)
 await process_frame

 var model:=MatchModel.new()
 verify(model.configure_endless("underground_lab","hell",SEED_VALUE,1),"seeded Hell fixture configured")
 verify(model.configure_balance(),"current economy configured")
 var own: RoomState=model.rooms[0]
 for room in model.rooms:
  if absf(room.door_normal().x)>.5:
   own=room
   break
 verify(model.claim_room(own.index),"real room claim")
 model.player_position=own.bed_position()
 verify(model.sleep_player(),"bed lock through model")
 model.bot_claimed=5
 own.bed_level=4
 own.door_level=4
 own.door_hp=own.max_hp()
 own.gold=2400
 own.electricity=350
 place_fixture_machines(model,own)
 game._adopt_session(model)
 game.set_process(false)
 game.selected_tile=own.buildings.keys().front()
 game.ui.open_context()
 game.construction.machines_open=true
 game.construction.refresh()
 game.focus_camera(true)
 game.audio_system.set_mix({"music_mode":"classic","music":.7,"effects":.85,"ambient":.30,"muted":false})

 var ally: RoomState=model.rooms[(own.index+4)%model.rooms.size()]
 ally.owner=2
 ally.sleeping=true
 ally.closed=true
 ally.door_hp=ally.max_hp()
 ally.resident_position=ally.bed_position()
 ally.bot_timer=1000

 recorder=AudioEffectRecord.new()
 AudioServer.add_bus_effect(0,recorder)
 recorder.set_recording_active(true)
 began=Time.get_ticks_usec()
 last_update=began

 stage_approach(model,ally)
 await drive(.65)
 verify(model.hunter.state==HunterState.State.ATTACK and model.hunter.target==ally.index,"actual remote door encounter")
 verify(game.horror.observed_counts.get("encounter",0)==1,"remote encounter observed once")
 verify(game.ui.context_open and game.construction.machine_list.visible,"inspector and machine list visible during ally warning")
 verify(game.audio_system.event_counts.get("siege_heartbeat",0)==0,"remote door never triggers player heartbeat")
 if OS.get_environment("NIGHTFALL_PHASE16")=="1":
  var placements: Array=game.horror.notification_placements(game.ui)
  verify(not placements.is_empty(),"remote encounter has a visible reserved HUD lane")
  for card in placements:
   for reserved in game.horror.visible_hud(game.ui):
    verify(not card.box.intersects(reserved),"alert leaves live HUD controls unobstructed")
 await still("ally-warning-720")
 await drive(1.55)
 game.ui.close_context()
 game.construction.machines_open=false

 stage_approach(model,own)
 own.door_hp=own.max_hp()*.33
 await drive(.35)
 verify(model.hunter.state==HunterState.State.ATTACK and model.hunter.target==own.index,"actual direct player siege")
 verify(game.audio_system.event_counts.get("siege_heartbeat",0)==1,"one heartbeat at direct siege")
 verify(game.audio_system.heartbeat.remaining>4.5,"opening heartbeat starts on contact with five-second sample")
 await still("first-heartbeat-720")
 var initial_attacks: int=model.hunter.attacks
 await drive(2.0)
 verify(model.hunter.attacks>initial_attacks,"normal Hunter strike applies actual damage")
 await still("door-contact-720")
 await drive(3.50)
 verify(game.audio_system.event_counts.get("siege_heartbeat",0)==1 and game.audio_system.heartbeat.remaining<=.01,"opening heartbeat ends and never repeats under sustained pressure")
 timeline.append({"event":"heartbeat stopped","wall_seconds":wall_time(),"hunter_attacks":model.hunter.attacks})
 own.door_hp=1
 var breach_deadline:=wall_time()+3.0
 while own.door_hp>0.0 and wall_time()<breach_deadline:
  await drive(.055)
 verify(own.door_hp<=0.0 and game.horror.breaks.size()==1,"Hunter's real blow breaks the door and emits one draft")
 await still("door-breach-720")
 await drive(1.3)
 verify(game.horror.breaks.is_empty(),"breach draft expires")
 timeline.append({"event":"breach draft expired","wall_seconds":wall_time(),"door_hp":own.door_hp})
 var capture_duration:=wall_time()

 recorder.set_recording_active(false)
 var wave:=recorder.get_recording()
 verify(wave!=null and wave.data.size()>10000,"Godot's actual Master bus contains an audio recording")
 if wave!=null:
  verify(wave.save_to_wav(directory.path_join("master.wav"))==OK,"Godot Master WAV written")
 AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
 var receipt:=FileAccess.open(directory.path_join("capture.json"),FileAccess.WRITE)
 receipt.store_string(JSON.stringify({"phase16":OS.get_environment("NIGHTFALL_PHASE16")=="1","driver":AudioServer.get_driver_name(),
  "timeline":timeline,"wall_duration":capture_duration,"frames":frame_index,"fps":FPS,"errors":errors,
  "event_counts":game.audio_system.event_counts,"audio_bytes":wave.data.size() if wave!=null else 0},"  ")+"\n")
 receipt.close()
 if is_instance_valid(game.audio_system):
  game.audio_system.shutdown()
 game.queue_free()
 await create_timer(.25).timeout
 print("PHASE16_PRESSURE_CAPTURE_FAILURES=",errors.size()," FRAMES=",frame_index)
 quit(int(not errors.is_empty()))

func place_fixture_machines(model: MatchModel,room: RoomState):
 for kind in ["turret","generator","enhancer"]:
  var area:=room.spatial.grid_bounds()
  var installed:=false
  for y in range(8,int(area.size.y),16):
   for x in range(8,int(area.size.x),16):
    var candidate:=room.spatial.aligned(area.position+Vector2(x,y),kind,0)
    if not room.spatial.purchase_reason(kind,candidate).is_empty():continue
    installed=model.place_building(kind,candidate)
    if installed:break
   if installed:break
  verify(installed,"installed paid "+kind)

func stage_approach(model: MatchModel,room: RoomState):
 model.time=maxf(model.time,model.preparation+1)
 model.hunter.position=room.door_approach()
 model.hunter.state=HunterState.State.MOVE
 model.hunter.target=room.index
 model.hunter.tactical_cooldown=1000.0
 model.hunter.arcane.cooldown=1000.0
 model.hunter.nightmare.cooldown=1000.0
 model.hunter.cooldown=1.1
 model.hunter.boss_policy.enabled=false
 model.hunter.target_time=0.0
 model.hunter.reassess_seconds=0.0
 game.focus_camera(true)
 timeline.append({"event":"approach staged at legal threshold","wall_seconds":wall_time(),
  "room":room.index+1,"door_normal":[room.door_normal().x,room.door_normal().y]})

func wall_time() -> float:
 return (Time.get_ticks_usec()-began)/1000000.0

func drive(seconds: float):
 var until:=wall_time()+seconds
 while wall_time()<until:
  await process_frame
  var now:=Time.get_ticks_usec()
  var delta:=minf(.2,(now-last_update)/1000000.0)
  last_update=now
  game._process(delta)
  if stills or frame_index>floori(wall_time()*FPS):continue
  await RenderingServer.frame_post_draw
  var picture:=root.get_texture().get_image()
  # Keep real-time audio and video aligned if llvmpipe misses a frame.
  var target_frame:=floori(wall_time()*FPS)
  while frame_index<=target_frame:
   var code:=picture.save_jpg(directory.path_join("frames/%04d.jpg"%frame_index),.91)
   verify(code==OK,"saved synchronized capture frame")
   frame_index+=1

func still(name: String):
 game.queue_redraw()
 await RenderingServer.frame_post_draw
 var picture:=root.get_texture().get_image()
 verify(picture.get_size()==Vector2i(1280,720),"actual 1280×720 viewport")
 verify(picture.save_png(directory.path_join(name+".png"))==OK,"saved lossless still "+name)
 timeline.append({"event":name,"wall_seconds":wall_time(),"frame":frame_index,
  "own_door_hp":game.model.player().door_hp,"heart_seconds":game.audio_system.heartbeat.remaining})
