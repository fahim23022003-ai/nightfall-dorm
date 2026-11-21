extends "res://tools/phase181/visual_capture.gd"
## Render stress fixture. Actors are staged in legal corridor positions for a
## concurrent siege. The launch and navigation test covers unstaged creation.

func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=3 or args[1] not in ["0","1","2","5"] or args[2] not in ["low","medium"]:
  quit(2)
  return
 destination=args[0]
 DirAccess.make_dir_recursive_absolute(destination)
 root.size=Vector2i(960,540) if args[2]=="low" else Vector2i(1280,720)
 await setup_game()
 game.onboarding.close_welcome()
 game.change_setting("graphics_quality",args[2])
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 Engine.max_fps=0
 var model:=await layout("seven-machines",0,["turret","generator","repair","heavy","frost","antenna","economy"])
 var room: RoomState=model.player()
 model.time=model.preparation+15.0
 model.haunt_recovery.available_at=INF
 model.mini_hunters_requested=true
 var outside: Vector2=room.door_approach()
 var occupied: RoomState=model.rooms[1]
 occupied.owner=1
 occupied.sleeping=true
 occupied.closed=true
 occupied.door_level=9
 occupied.door_hp=occupied.max_hp()
 model.hunter.position=occupied.door_approach()
 model.hunter.target=occupied.index
 model.hunter.state=HunterState.State.ATTACK
 model.hunter.cooldown=.5
 for index in range(args[1].to_int()):
  var mini:=MiniHunter.new()
  mini.configure(model,model.next_entity_id,index,false)
  model.next_entity_id+=1
  mini.position=outside+room.door_normal()*(3.0+index*8.0)
  mini.target=room.index
  check(model.navigation_walkable(mini.position),"staged mini is on actual exterior corridor")
  model.mini_hunters.append(mini)
 var samples: Array[float]=[]
 var calls: Array[int]=[]
 var shots:=0
 var actor_count:=0
 var mini_hits:=0
 var room_hit:=0
 var nodes:=0
 var frame_cpu: Array[float]=[]
 for i in range(150):
  var started:=Time.get_ticks_usec()
  game._process(FRAME_STEP)
  var updated:=Time.get_ticks_usec()
  _camera(room.door_position().lerp(room.bounds().get_center(),.32),ROOM_ZOOM)
  await RenderingServer.frame_post_draw
  if i>=30:
   samples.append((Time.get_ticks_usec()-started)/1000.0)
   frame_cpu.append((updated-started)/1000.0)
   calls.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
   shots=maxi(shots,model.projectiles.size())
   actor_count=maxi(actor_count,model.mini_hunters.size())
  for event in model.combat_events:
   if event.type=="impact" and event.target_id>1:mini_hits=maxi(mini_hits,event.id)
  for event in model.presentation_events:
   if event.type=="mini_hunter_attack" and event.damage>0.0:room_hit=maxi(room_hit,event.id)
  if i==80:
   _save_frame("simultaneous-siege")
  nodes=int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
 if args[1]!="0":
  check(mini_hits>0 and room_hit>0,"real mini door damage and turret hit")
 var receipt:=FileAccess.open(destination.path_join("receipt.json"),FileAccess.WRITE)
 samples.sort()
 receipt.store_string(JSON.stringify({
  "width":root.size.x,"height":root.size.y,"preset":args[2],"staged_minis":args[1].to_int(),
  "median_ms":samples[samples.size()/2],"p95_ms":samples[ceili(samples.size()*.95)-1],
  "p99_ms":samples[ceili(samples.size()*.99)-1],"draw_calls":_timing(calls),
  "process_ms":_timing(frame_cpu),"peak_projectiles":shots,"timed_peak_minis":actor_count,
  "video_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
  "static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"nodes":nodes,
  "mini_hit_record":mini_hits,"door_hit_record":room_hit,"failures":failures
 },"  ")+"\n")
 receipt.close()
 await _finish()

func _timing(values: Array) -> Dictionary:
 values.sort()
 return {"median":values[values.size()/2],"p95":values[ceili(values.size()*.95)-1],
  "p99":values[ceili(values.size()*.99)-1]}
