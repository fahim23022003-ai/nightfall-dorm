extends "res://tools/full_room_grid/measure_grid_density.gd"
## Real viewport timings. Static game state permits exact Standard/Low pairing.

const TIMING_WARMUP := 24
const TIMING_SAMPLES := 120
const THEME := "cursed_mansion"

func summarized(samples: Array) -> Dictionary:
 var ordered := samples.duplicate()
 ordered.sort()
 var midpoint := int(ordered.size() / 2.0)
 var median: float = (ordered[midpoint-1] + ordered[midpoint]) / 2.0
 return {"median": median, "p95": ordered[ceili(ordered.size() * .95) - 1], "max": ordered.back()}

func sample_scene(model) -> Dictionary:
 var before := _state_digest(model)
 var frames := []
 var draw_calls := []
 var objects := []
 for index in range(TIMING_WARMUP + TIMING_SAMPLES):
  var started := Time.get_ticks_usec()
  game.presentation.update(STEP, model)
  await _render_frame()
  var millis := (Time.get_ticks_usec() - started) / 1000.0
  if index >= TIMING_WARMUP:
   frames.append(millis)
   draw_calls.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
   objects.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))
 check(before == _state_digest(model), "timed drawing leaves the gameplay fixture unchanged")
 return {
  "samples": frames, "frame_ms": summarized(frames), "draw_calls": summarized(draw_calls),
  "objects": summarized(objects), "warmup_frames": TIMING_WARMUP, "sample_frames": TIMING_SAMPLES,
  "state_sha256": before, "render_memory_bytes": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
 }

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 2 or not args[0].is_absolute_path() or args[1] not in ["medium", "low"]:
  push_error("Pass an absolute evidence directory and medium or low after --")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 var quality := args[1]
 output = destination.get_base_dir() + "/"
 phase = destination.get_file()
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()
 game.change_setting("graphics_quality", quality)
 game.new_balance_version = BalanceRules.CURRENT
 game.return_menu()
 check(game.start_endless(THEME, "standard", SEED), "normal Endless start path")
 game.set_process(false)
 var model: MatchModel = game.model
 if not model.map_data.has("halls"):
  check(false, "procedural preview was enabled")
  await _finish()
  return
 var index := 0
 for room in model.rooms:
  if room.layout.shape == "u":
   index = room.index
   break
 check(model.claim_room(index), "claim generated U-shaped room")
 var room: RoomState = model.player()
 model.player_position = room.bed_position()
 check(model.sleep_player(), "sleep in the actual room")
 check(room.spatial != null and room.spatial.grid, "Full Room Grid follows generated floor")
 if room.spatial == null or not room.spatial.grid:
  await _finish()
  return
 room.gold = 500000.0
 room.electricity = 500000.0
 room.bed_level = 6
 room.door_level = 6
 room.door_hp = room.max_hp()
 var roles := ["heavy", "flame", "generator", "repair", "turret", "frost", "shield", "shock", "antenna", "decoy"]
 for kind in roles:
  var machine := _grid_placement(model, kind)
  check(machine >= 0, "normal paid placement of " + kind)
  if machine < 0:
   continue
  for level in range(2, 8):
   var upgraded: bool = model.specialize_building(machine, StrategyCatalog.branches(kind)[0]) if level == 5 else model.upgrade_building(machine)
   check(upgraded, "normal paid upgrade %s L%d" % [kind, level])
 while room.buildings.size() < 16 and _grid_placement(model, "decoy") >= 0:
  pass
 check(room.buildings.size() >= 10, "generated room is physically populated")
 model.hunter.state = HunterState.State.MOVE
 model.hunter.target = index
 model.hunter.position = room.door_approach()
 model.running = false
 game.construction.planning = true
 game.construction.refresh()
 game.focus_camera(true)
 await _render_frame()
 check(root.get_texture().get_image().get_size() == Vector2i(1280, 720), "timing used real 1280×720 viewport")
 var planning := await sample_scene(model)
 await capture("irregular-room-grid-720")
 game.construction.planning = false
 game.construction.refresh()
 game.full_map = true
 game.focus_camera(true)
 var overview := await sample_scene(model)
 await capture("nightmare-overview-720")
 var receipt := FileAccess.open(destination.path_join("benchmark.json"), FileAccess.WRITE)
 check(receipt != null, "write benchmark receipt")
 if receipt != null:
  var geometry: GDScript = load("res://scripts/nightmare_map.gd")
  var data := {
   "engine": Engine.get_version_info(), "adapter": RenderingServer.get_video_adapter_name(),
   "quality": quality, "seed": SEED, "theme": THEME, "viewport": [1280,720],
   "geometry_sha256": JSON.stringify(geometry.pack(model.map_data), "", true, true).sha256_text(),
   "shape": room.layout.shape, "buildings": room.buildings.size(), "scenes": {"grid": planning, "overview": overview},
   "fixture": "Same prepared played-through purchases, fixed model state; presentation advances at 24 steps/s while sampling real rendered frame times.",
   "checks": checks, "failures": failures
  }
  receipt.store_string(JSON.stringify(data, "  ") + "\n")
 await _finish()
