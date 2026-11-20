extends "res://tools/capture_visual_rebirth.gd"
## Match two rendering builds using the same dense room and repeatable Hunter path.

const ROUTE := [
 Vector2(95, 305), Vector2(173, 305), Vector2(173, 343), Vector2(105, 343),
 Vector2(105, 300), Vector2(173, 300), Vector2(113, 342),
]
const PRE_ROUTE_FRAMES := 30
const TURN_WINDOW_FRAMES := 3
const ROUTE_PASSES := 3

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 2 or not args[0].is_absolute_path() or args[1] not in ["medium", "low"]:
  push_error("Pass an absolute evidence directory and medium or low after --.")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 phase = destination.get_file()
 output = destination.get_base_dir() + "/"
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()
 var quality := args[1]
 game.change_setting("graphics_quality", quality)
 check(game.profile.settings.get("graphics_quality") == quality, "profile has the requested preview preset")
 check(CinematicQuality.detail(game) == (0 if quality == "low" else 1), "renderer uses the requested detail")
 check(OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1", "visual preview on")
 var model = _dense_fixture()
 check(model.player().buildings.size() == 16, "all 16 building slots occupied")
 model.running = true
 model.hunter.position = ROUTE[0]
 model.hunter.state = HunterState.State.MOVE
 model.evolution.evolution_level = 10
 model.evolution.final_revealed = true
 model.evolution.rebirth_remaining = 0.0
 game.presentation.identity.reset()
 game.presentation.nightmare_visual.reset()
 game.ui.update_match()
 for index in range(PRE_ROUTE_FRAMES):
  game.presentation.update(STEP, model)
  await _render_frame()
 check(root.get_texture().get_image().get_size() == Vector2i(1280, 720), "actual 1280x720 game render")
 var starting_model := _state_digest(model)
 var samples: Array[Dictionary] = []
 var route_digests: Array[String] = []
 var textures := {}
 var previous_texture := ""
 var mesh_ids := {}
 for route_pass in range(ROUTE_PASSES):
  for route_index in range(ROUTE.size()):
   var start: Vector2 = ROUTE[route_index]
   var goal: Vector2 = ROUTE[(route_index + 1) % ROUTE.size()]
   check(model.hunter.position.is_equal_approx(start) and model._visible(start, goal), "route leg %d is walkable" % route_index)
   var step := 0
   while not model.hunter.position.is_equal_approx(goal) and step < 60:
    var beginning := Time.get_ticks_usec()
    model.hunter.navigate(goal, STEP)
    game.presentation.update(STEP, model)
    await _render_frame()
    var elapsed := (Time.get_ticks_usec() - beginning) / 1000.0
    var renderer = game.presentation.nightmare_visual.stalker_preview
    var texture: String = "" if renderer.texture == null else renderer.texture.resource_path
    # Inspect the live draw resource after recording the frame interval.
    var mesh_id: int = 0 if renderer.current_mesh == null else renderer.current_mesh.get_instance_id()
    mesh_ids[mesh_id] = true
    textures[texture] = true
    samples.append({
     "pass": route_pass, "leg": route_index, "step": step,
     "is_turn": step < TURN_WINDOW_FRAMES, "frame_ms": elapsed,
     "heading": game.presentation.identity.heading,
     "texture": texture, "texture_changed": texture != previous_texture, "mesh_instance_id": mesh_id,
    })
    previous_texture = texture
    step += 1
   check(model.hunter.position.is_equal_approx(goal), "Hunter reaches route waypoint")
  route_digests.append(_state_digest(model))
 check(starting_model == _state_digest(model), "loop returns the sampled model to its starting state")
 check(samples.size() > 200, "enough complete rendered frames retained")
 check(textures.size() >= 4 and not textures.has(""), "at least four production direction textures rendered")
 check(not mesh_ids.has(0), "every timed frame bound an actual mesh")
 var result := FileAccess.open(destination.path_join("frame-times.json"), FileAccess.WRITE)
 check(result != null, "output writable")
 if result != null:
  result.store_string(JSON.stringify({
   "renderer": RenderingServer.get_video_adapter_name(),
   "quality": quality, "hunter": "stalker", "hunter_level": 10, "seed": SEED,
   "viewport": [1280, 720], "stage_delta_seconds": STEP,
   "pre_route_frames": PRE_ROUTE_FRAMES, "turn_window_frames": TURN_WINDOW_FRAMES,
   "pass_model_hashes": route_digests, "frame_times": samples, "observed_mesh_instances": mesh_ids.size(),
   "estimated_render_memory_bytes": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
   "checks": checks, "failures": failures,
  }, "  ") + "\n")
 await capture("dense-route-end-720")
 await _finish()
