extends "res://tools/nightmare_maps/measure_hell_tactics.gd"
## Matched native active rendering and independently staged prepared combat.
##
## Run with visual, Living Nightmare, Survivor Rebirth, Full Room Grid and V2
## enabled on actual desktop OpenGL. Use an isolated XDG data directory.

const WARM_FRAMES := 24
const TIMED_SAMPLES := 120
const DENSE_STAGE := "stage_5"
const STANDARD_VIEW_SIZE := Vector2i(1280, 720)

func _construction_points(room: RoomState, kind: String) -> Array[Vector2]:
 var bounds := room.bounds()
 var candidates: Array[Vector2] = []
 var seen := {}
 for y in range(floori(bounds.position.y), ceili(bounds.end.y), 16):
  for x in range(floori(bounds.position.x), ceili(bounds.end.x), 16):
   var point: Vector2 = room.spatial.aligned(Vector2(x, y), kind, 0)
   if point.is_finite() and not seen.has(point):
    candidates.append(point)
    seen[point] = true
 candidates.sort_custom(func(a, b):
  var a_distance: float = a.distance_squared_to(room.door_approach())
  var b_distance: float = b.distance_squared_to(room.door_approach())
  if a_distance != b_distance:
   return a_distance < b_distance
  if a.y != b.y:
   return a.y < b.y
  return a.x < b.x)
 return candidates

func _dense_room(model: MatchModel, count: int) -> RoomState:
 var room := make_room_fixture(model)
 if room == null:
  return null
 for point in _construction_points(room, "decoy"):
  if room.buildings.size() >= count:
   break
  if room.spatial.purchase_reason("decoy", point, 0) == "":
   check(model.place_building("decoy", point, 0), "paid extra legal stress building")
 return room

func _prepare_encounter(model: MatchModel, room: RoomState, reaper: bool):
 model.time = model.preparation + 24.0
 model.bot_claimed = 5
 for ally: RoomState in model.rooms:
  if ally != room:
   ally.owner = ally.index + 1
   ally.closed = true
   ally.sleeping = true
   ally.resident_position = ally.bed_position()
   ally.bot_timer = 9999.0
 var hunter := model.hunter
 hunter.target = room.index
 hunter.position = room.door_approach()
 hunter.state = HunterState.State.ATTACK
 hunter.cooldown = .50
 hunter.siege_start_hp = room.door_hp
 if reaper:
  hunter.hp = hunter.max_hp * .53
  model.tick(.016)
  check(hunter.transformed, "existing Reaper threshold triggers transformation")
  for index in range(160):
   model.tick(.016)
  check(hunter.state != HunterState.State.TRANSFORM, "actual transformation timer elapses")
  # The real transformation exits into SEEK and can route toward another room.
  # Start the timed phase in a prepared siege at the same physical doorway.
  # From this contact onward the normal boss state machine owns every strike.
  hunter.state = HunterState.State.ATTACK
  hunter.position = room.door_approach()
  hunter.target = room.index
  hunter.cooldown = .55
  hunter.target_time = 0.0
  hunter.reassess_seconds = 0.0
  hunter.siege_start_hp = room.door_hp
  model.wrath.interrupt(model, "benchmark setup")
  model.wrath.phase = 2
  model.wrath.recovery = 20.0
  hunter.boss_cooldowns.siege = 20.0
  hunter.boss_cooldowns.surge = 20.0
  hunter.boss_cooldowns.scythe = 0.0
 else:
  hunter.boss_policy.enabled = false
 game.focus_camera(true)

func _gameplay_digest(model: MatchModel) -> String:
 return JSON.stringify({
  "base": _state_digest(model),
  "combat": model.combat_events,
  "presentation": model.presentation_events,
  "evolution": model.evolution.evolution_level,
  "model_time": model.time,
  "player": model.player_position,
 }, "", true, true).sha256_text()

func _image_hash(image: Image) -> String:
 var hash := HashingContext.new()
 hash.start(HashingContext.HASH_SHA256)
 hash.update(image.get_data())
 return hash.finish().hex_encode()

func _visible_building_centers(room: RoomState) -> int:
 var bounds := root.get_visible_rect()
 var transform := root.get_canvas_transform()
 var visible := 0
 for id in room.buildings:
  if bounds.has_point(transform * (room.tile_position(id) + game.MAP_OFFSET)):
   visible += 1
 return visible

func _timing(values: Array) -> Dictionary:
 var ordered := values.duplicate()
 ordered.sort()
 var count := ordered.size()
 if count == 0:
  return {}
 var middle := count >> 1
 var median: float = ordered[middle] if count % 2 else (ordered[middle - 1] + ordered[middle]) * .5
 return {"median":median, "p95":ordered[ceili(count*.95)-1], "max":ordered.back()}

func _measure_native(model: MatchModel) -> Dictionary:
 var rows := {}
 var event_kinds := {}
 var start_round := {}
 var draw_samples := []
 var object_samples := []
 var projectile_samples := []
 var span_samples := {}
 var update_samples := []
 var frame_samples := []
 for index in range(WARM_FRAMES + TIMED_SAMPLES):
  if index == WARM_FRAMES:
   start_round = {
    "gameplay_sha256":_gameplay_digest(model), "strikes":model.hunter.attacks,
    "shots":model.shots, "door_hp":model.player().door_hp, "hunter_hp":model.hunter.hp,
   }
  var start := Time.get_ticks_usec()
  game._process(COMBAT_STEP)
  var updated := Time.get_ticks_usec()
  await RenderingServer.frame_post_draw
  var finished := Time.get_ticks_usec()
  if index >= WARM_FRAMES:
   frame_samples.append((finished - start) / 1000.0)
   update_samples.append((updated - start) / 1000.0)
   draw_samples.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
   object_samples.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))
   projectile_samples.append(model.projectiles.size())
   for event in model.presentation_events:
    if not rows.has(event.id):
     rows[event.id] = true
     event_kinds[event.type] = int(event_kinds.get(event.type,0)) + 1
   var spans: Dictionary = get_meta("phase16_span_us", {})
   for kind in spans:
    if not span_samples.has(kind):
     span_samples[kind] = []
    span_samples[kind].append(spans[kind] / 1000.0)
  if has_meta("phase16_span_us"):
   set_meta("phase16_span_us", {})
 var span_summary := {}
 for kind in span_samples:
  span_summary[kind] = _timing(span_samples[kind])
 return {
  "frame_ms":_timing(frame_samples), "update_ms":_timing(update_samples),
  "draw_calls":_timing(draw_samples), "objects":_timing(object_samples),
  "projectiles":_timing(projectile_samples), "spans_ms":span_summary, "raw_spans_ms":span_samples,
  "raw_frame_ms":frame_samples, "raw_update_ms":update_samples,
  "warmup_frames":WARM_FRAMES, "sample_frames":TIMED_SAMPLES, "model_step":COMBAT_STEP,
  "warmup":start_round, "events":event_kinds, "gameplay_sha256":_gameplay_digest(model),
  "strikes":model.hunter.attacks-int(start_round.strikes), "shots":model.shots-int(start_round.shots),
  "door_hp_delta":model.player().door_hp-float(start_round.door_hp),
  "hunter_hp_delta":model.hunter.hp-float(start_round.hunter_hp),
 }

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 4 or not args[0].is_absolute_path() or args[1] not in ["medium","low"] or args[2] not in ["24","40","60"] or args[3] not in ["stalker","reaper"]:
  push_error("Pass absolute output directory, medium or low, 24/40/60 density and stalker or reaper after --.")
  quit(2)
  return
 if DisplayServer.get_name() == "headless":
  push_error("A real Godot viewport is required.")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 var density := int(args[2])
 var quality := args[1]
 var reaper := args[3] == "reaper"
 phase = destination.get_file()
 output = destination.get_base_dir() + "/"
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = STANDARD_VIEW_SIZE
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 Engine.max_fps = 0
 await setup_game()
 game.onboarding.close_welcome()
 game.change_setting("graphics_quality",quality)
 var model := MatchModel.new()
 model.reset(MATCH_SEED)
 check(model.configure_match("hell") and model.configure_stage(DENSE_STAGE) and model.configure_balance(), "configured prepared Campaign benchmark")
 check(model.configure_strategy(MATCH_SEED, "stalker"), "selected same Hunter")
 check(model.map_data.get("version",0) == NightmareMap.MACRO_VERSION, "using full V2 map")
 game._adopt_session(model)
 game.set_process(false)
 var room := _dense_room(model,density)
 if room == null:
  await _finish()
  return
 print("PHASE16_PLAYER_LAYOUT=",room.buildings.size()," TARGET=",density," BOUNDS=",room.bounds())
 check(room.buildings.size() == density, "exact density uses legal paid structures in one room")
 _prepare_encounter(model,room,reaper)
 await _render_frame()
 var image := root.get_texture().get_image()
 check(image.get_size() == STANDARD_VIEW_SIZE,"actual native 720p viewport")
 var initial_visible := _visible_building_centers(room)
 check(initial_visible == density, "all fixture building centers start on-screen")
 var initial := _gameplay_digest(model)
 var visual_initial := _image_hash(image)
 var samples := await _measure_native(model)
 check(model.result.is_empty(),"combat stays active during timed interval")
 check(samples.shots > 0 and samples.strikes > 0 and samples.hunter_hp_delta < 0, "sample includes real launches, strikes and damage")
 if reaper:
  check(samples.events.get("boss_impact",0) > 0, "sample includes actual Reaper scythe contact")
 var final_image := root.get_texture().get_image()
 var final_visible := _visible_building_centers(room)
 check(final_visible == density, "all fixture building centers finish on-screen")
 var art = game.presentation.boss_presentation.articulated if reaper else game.presentation.nightmare_visual.articulated
 check(not art.last_asset.is_empty(), "active sample used articulated hunter")
 check(final_image.save_png(destination.path_join("final-720.png")) == OK, "write actual viewport image")
 var receipt := FileAccess.open(destination.path_join("benchmark.json"),FileAccess.WRITE)
 check(receipt != null, "open timing report")
 if receipt != null:
  receipt.store_string(JSON.stringify({
   "quality":quality, "encounter":args[3], "renderer":RenderingServer.get_video_adapter_name(),
   "window_system":DisplayServer.get_name(), "engine":Engine.get_version_info(), "seed":MATCH_SEED,
   "viewport":[1280,720], "requested_buildings":density, "actual_buildings":room.buildings.size(),
   "visible_building_centers_at_start":initial_visible, "visible_building_centers_at_end":final_visible,
   "room":room.index, "geometry_sha256":JSON.stringify(NightmareMap.pack(model.map_data),"",true,true).sha256_text(),
   "gameplay_initial_sha256":initial, "visual_initial_sha256":visual_initial, "visual_final_sha256":_image_hash(final_image),
   "timing":samples, "atlas_used":art.last_asset, "static_memory_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),
   "video_memory_bytes":int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)), "checks":checks, "failures":failures,
  },"  ",true,true)+"\n")
 await _finish()
