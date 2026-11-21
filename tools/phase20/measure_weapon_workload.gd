extends "res://tools/phase181/visual_capture.gd"
## Match frame timings from real Godot presentation with deterministic combat.

func percentile(values: Array[float], p: float) -> float:
 if values.is_empty():return -1.0
 values.sort()
 return values[ceili(values.size()*p)-1]

func _practical_benchmark(preset: String) -> void:
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 Engine.max_fps=0
 game.change_setting("graphics_quality",preset)
 for count: int in [0,1,5,10,24,40,60]:
  var model:=make_room(0)
  var room:=model.player()
  var origin:=room.door_approach()
  for i in range(count):
   if _pay_place(model,"turret",origin)<0:break
  var placed: int=room.buildings.size()
  if count>0 and placed==0:continue
  if count>24 and placed==int(result.get("24",{}).get("placed",0)):continue
  model.time=model.preparation+7.0
  model.haunt_recovery.available_at=INF
  model.hunter.position=origin
  model.hunter.target=room.index
  model.hunter.state=HunterState.State.ATTACK
  model.hunter.cooldown=.5
  var initial_hp: float=model.hunter.hp
  var frames: Array[float]=[]
  var processing: Array[float]=[]
  var shooting: Array[float]=[]
  var calls: Array[int]=[]
  for i in range(140):
   var prior: int=model.shots
   var started:=Time.get_ticks_usec()
   game._process(FRAME_STEP)
   var cpu: float=(Time.get_ticks_usec()-started)/1000.0
   _camera(room.bounds().get_center()+Vector2(-18,-18),ROOM_ZOOM)
   await RenderingServer.frame_post_draw
   if i>=20:
    var frame: float=(Time.get_ticks_usec()-started)/1000.0
    frames.append(frame)
    processing.append(cpu)
    if model.shots>prior:shooting.append(frame)
    calls.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
  calls.sort()
  check(count==0 or model.shots>0 and model.hunter.hp<initial_hp,"Verified a weapon fired and dealt damage")
  result[str(count)]={"preset":preset,"placed":placed,"samples":frames.size(),"median_ms":percentile(frames,.50),"p95_ms":percentile(frames,.95),"p99_ms":percentile(frames,.99),"shot_frames":shooting.size(),"shot_frame_median_ms":percentile(shooting,.50),"shot_frame_p95_ms":percentile(shooting,.95),"game_process_median_ms":percentile(processing,.50),"game_process_p95_ms":percentile(processing,.95),"draw_calls_median":calls[calls.size()/2],"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"video_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"renderer":RenderingServer.get_video_adapter_name(),"shots":model.shots,"hunter_hp_lost":initial_hp-model.hunter.hp}
  print("VOLLEY ", count," ",JSON.stringify(result[str(count)]))


func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=3 or not args[0].is_absolute_path() or args[1] not in ["low","medium"] or args[2] not in ["volley","mixed"]:
  push_error("Pass an absolute receipt path, low or medium, and volley or mixed.")
  quit(2)
  return
 root.size=Vector2i(960,540) if args[1]=="low" else Vector2i(1280,720)
 await setup_game()
 game.onboarding.close_welcome()
 # The deterministic 24 Hz model step is independent of measured wall frames.
 # Keep adaptive effects off so it cannot mistake that step for measured lag.
 if game.profile.settings.has("adaptive_performance"):game.profile.settings.adaptive_performance=false
 destination=args[0].get_base_dir()
 DirAccess.make_dir_recursive_absolute(destination)
 if args[2]=="mixed":
  await super._practical_benchmark(args[1])
 else:
  await _practical_benchmark(args[1])
 var receipt:=FileAccess.open(args[0],FileAccess.WRITE)
 receipt.store_string(JSON.stringify({"scenes":result,"checks":checks,"failures":failures,"quality_fixed":true},"  ")+"\n")
 receipt.close()
 await _finish()
