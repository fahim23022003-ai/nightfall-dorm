extends "res://tools/phase21/capture_ui.gd"
## Measures two windows of one fresh, reproducible Story attempt. The model clock
## is fixed, while frame times include the actual Godot/OpenGL rendering loop.

const ATTEMPT_SEED := 1527205665
const WINDOW_FRAMES := 100
const CLOCK_STEP := .05

class TimedModel extends MatchModel:
 var last_tick_us := 0
 func tick(delta: float):
  var started := Time.get_ticks_usec()
  super.tick(delta)
  last_tick_us += Time.get_ticks_usec() - started

func distribution(samples: Array) -> Dictionary:
 var ordered := samples.duplicate()
 ordered.sort()
 return {"median":(ordered[(ordered.size()-1)/2]+ordered[ordered.size()/2])*.5,
  "p95":ordered[ceili(ordered.size()*.95)-1], "p99":ordered[ceili(ordered.size()*.99)-1]}

func capture_window(model: TimedModel) -> Dictionary:
 var frame_ms := []
 var model_ms := []
 var update_ms := []
 var draws := []
 var decisions := []
 var start_time: float = model.time
 var start_shots: int = model.shots
 var start_attacks: int = model.hunter.attacks
 var initial_target: int = model.hunter.target
 var cpu_before := cpu_counters()
 var machines: Array = model.rooms.map(func(room): return room.buildings.size())
 for index in range(WINDOW_FRAMES):
  var previous: int = model.hunter.decision_count
  model.last_tick_us = 0
  var started := Time.get_ticks_usec()
  game._process(CLOCK_STEP)
  var updated := Time.get_ticks_usec()
  await RenderingServer.frame_post_draw
  frame_ms.append((Time.get_ticks_usec()-started)/1000.0)
  model_ms.append(model.last_tick_us/1000.0)
  update_ms.append((updated-started)/1000.0)
  draws.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
  if model.hunter.decision_count!=previous:
   decisions.append({"frame":index, "tick_ms":model_ms.back(), "target":model.hunter.target, "time":model.time})
 var cpu_delta := cpu_counters()
 for key in cpu_delta:cpu_delta[key] -= cpu_before.get(key,0)
 return {"cpu_window":cpu_delta, "frame_ms":distribution(frame_ms), "model_ms":distribution(model_ms), "update_ms":distribution(update_ms),
  "draws":distribution(draws), "start_time":start_time, "end_time":model.time, "initial_target":initial_target,
  "end_target":model.hunter.target, "active_allies":model.rooms.filter(func(room):return room.owner>0 and room.alive).size(),
  "buildings_by_room_at_start":machines, "shots":model.shots-start_shots, "attacks":model.hunter.attacks-start_attacks,
  "decisions":decisions, "raw_frame_ms":frame_ms, "raw_model_ms":model_ms, "raw_update_ms":update_ms}

# Linux-only context for separating main-thread scheduling stalls from work.
# CPU times cover the process including llvmpipe. Shared cgroup throttling is
# host context and cannot attribute all throttled time to this game process.
func cpu_counters() -> Dictionary:
 var counters: Dictionary = {}
 if OS.get_name()!="Linux":return counters
 var cpu := FileAccess.open("/proc/self/stat",FileAccess.READ)
 if cpu!=null:
  var tokens := cpu.get_line().rsplit(") ",true,1)
  if tokens.size()==2:
   var fields := tokens[1].split(" ")
   if fields.size()>12:counters.process_ticks=int(fields[11])+int(fields[12])
 var sched := FileAccess.open("/proc/thread-self/schedstat",FileAccess.READ)
 if sched!=null:
  var fields := sched.get_line().split(" ")
  if fields.size()>1:counters.main_runqueue_wait_ns=int(fields[1])
 var control := FileAccess.open("/sys/fs/cgroup/cpu.stat",FileAccess.READ)
 if control!=null:
  while not control.eof_reached():
   var fields := control.get_line().split(" ")
   if fields.size()==2 and fields[0] in ["throttled_usec","nr_periods","nr_throttled"]:
    counters["shared_cgroup_"+fields[0]]=int(fields[1])
 return counters

func prepare_until(model: TimedModel, stop_at_contact: bool) -> void:
 var decision: float = model.time
 while model.running and model.result.is_empty() and model.time<model.preparation+180:
  if stop_at_contact:
   if model.hunter.state == HunterState.State.ATTACK:break
  elif model.time>=model.preparation-.25:break
  if model.time>=decision:
   decision+=2
   var room:=model.player()
   if room==null:return
   if room.door_level<1:model.upgrade_door()
   if room.bed_level<2:model.upgrade_bed()
   if room.buildings.size()<4:
    var point:=needle_cell(room)
    if point.is_finite():model.place_building("turret",point,0)
  model.tick(CLOCK_STEP)

func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=2 or not args[0].is_absolute_path() or args[1] not in ["low","medium"] or DisplayServer.get_name()=="headless":
  push_error("Pass absolute output JSON path and low or medium on a real display.")
  quit(2)
  return
 root.size=Vector2i(960,540) if args[1]=="low" else Vector2i(1280,720)
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 Engine.max_fps=0
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://phase23-bench-%d.json" % Time.get_ticks_usec())
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 await process_frame
 game.onboarding.skip()
 game.onboarding.close_welcome()
 game.profile.complete_tutorial()
 game.profile.story=StoryProgress.fresh(ATTEMPT_SEED)
 game.change_setting("graphics_quality",args[1])
 game.change_setting("adaptive_performance",false)
 var model:=TimedModel.new()
 for connection in game.model.feedback.get_connections():
  model.feedback.connect(connection.callable)
 game.model=model
 check(game.start_story("hard"),"Actual level 1 Long Night Story started")
 var ai_active: bool=model.has_method("uses_story_intelligence") and model.call("uses_story_intelligence")
 check(ai_active==(OS.get_environment("NIGHTFALL_HUNTER_INTELLIGENCE")=="1"),"Configured candidate AI gate agrees with active Story session")
 await walk_probe()
 if failures or model.player()==null:
  quit(1)
  return
 game.focus_camera(true)
 prepare_until(model,false)
 # Warm the viewport and profile resources without changing the simulated clock.
 for index in range(25):
  game.queue_redraw()
  await RenderingServer.frame_post_draw
 var opening:=await capture_window(model)
 check(not opening.decisions.is_empty(),"Opening recorded a real target decision")
 prepare_until(model,true)
 check(model.hunter.state==HunterState.State.ATTACK,"Hunter walked to first genuine siege")
 if model.hunter.target!=model.player_room:
  game.spectate_room(model.hunter.target)
 game.focus_camera(true)
 for index in range(10):
  game.queue_redraw()
  await RenderingServer.frame_post_draw
 var combat:=await capture_window(model)
 check(combat.shots>0 and combat.attacks>0,"Measured window includes shots and door damage")
 check(combat.active_allies>=2 and combat.buildings_by_room_at_start.reduce(func(a,b):return a+b,0)>=4,"Multiple live allies and defenses")
 check(is_equal_approx(combat.end_time-combat.start_time,CLOCK_STEP*WINDOW_FRAMES),"No background suspension or premature outcome")
 var file:=FileAccess.open(args[0],FileAccess.WRITE)
 check(file!=null,"Opened output JSON")
 if file!=null:
  file.store_string(JSON.stringify({"story_intelligence":ai_active,"graphics":args[1],"size":[root.size.x,root.size.y],
   "adapter":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info().string,
   "seed":model.map_seed,"story":model.story_level,"difficulty":model.difficulty,
   "archetype":model.hunter.archetype,"family":model.map_data.family,"player_room":model.player_room,
   "opening":opening,"combat":combat,"dt":CLOCK_STEP,"sample_count_per_window":WINDOW_FRAMES,
   "checks":checks,"failures":failures,"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),
   "gpu_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)},"  ")+"\n")
  file.close()
 game.audio_system.shutdown()
 game.queue_free()
 await process_frame
 print("PHASE23_BENCH checks=",checks," failures=",failures)
 quit(int(failures>0))
