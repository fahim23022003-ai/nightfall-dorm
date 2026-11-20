extends "res://tools/nightmare_maps/measure_hell_tactics.gd"
## Measures the live Story lobby renderer over the staggered AI readiness.

func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=2 or not args[0].is_absolute_path() or args[1] not in ["low","medium"]:
  push_error("Pass an absolute output folder and low or medium after --.")
  quit(2)
  return
 var destination: String=args[0]
 output=destination.get_base_dir()+"/"
 phase=destination.get_file()
 DirAccess.make_dir_recursive_absolute(destination)
 root.size=Vector2i(1280,720)
 await setup_game()
 game.set_process(false)
 game.onboarding.skip()
 game.onboarding.close_welcome()
 check(game.profile.complete_tutorial(),"isolated benchmark profile")
 game.change_setting("graphics_quality",args[1])
 game.enter_game()
 check(game.open_story_lobby(game.profile.selected_difficulty),"open the actual Story lobby")
 var lobby=game.story_lobby
 if not is_instance_valid(lobby):
  await _finish()
  return
 lobby.set_process(false)
 for i in range(12):await _render_frame()
 check(lobby.armed,"lobby is initialized and has draw confirmation")
 # The X11 dummy display has no window manager. Focus handling has
 # a separate integration test, so enable the clock for this workload.
 lobby.window_focused=true
 var starting_time: float=game.model.time
 var draw_calls: Array=[]
 var elapsed: Array=[]
 var warmup:=24
 for frame in range(warmup+ACTIVE_SAMPLES):
  var started:=Time.get_ticks_usec()
  lobby.advance(COMBAT_STEP)
  game._process(COMBAT_STEP)
  await _render_frame()
  if frame>=warmup:
   elapsed.append((Time.get_ticks_usec()-started)/1000.0)
   draw_calls.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
 check(game.model.time==starting_time,"match clock stays frozen throughout measurement")
 check(lobby.ready_ai_count()==5 and not lobby.loading,"all AI ready without launching the unready human")
 check(root.get_texture().get_image().get_size()==Vector2i(1280,720),"native 720p render")
 var receipt:=FileAccess.open(destination.path_join("benchmark.json"),FileAccess.WRITE)
 receipt.store_string(JSON.stringify({
  "renderer":RenderingServer.get_video_adapter_name(),"quality":args[1],"viewport":[1280,720],
  "frames":ACTIVE_SAMPLES,"frame_ms":summarized(elapsed),"draw_calls":summarized(draw_calls),
  "wall_samples_ms":elapsed,"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
  "checks":checks,"failures":failures,
 },"  ")+"\n")
 receipt.close()
 game.return_menu()
 await _finish()
