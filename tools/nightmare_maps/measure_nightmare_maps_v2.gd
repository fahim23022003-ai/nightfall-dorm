extends "res://tools/nightmare_maps/measure_nightmare_maps.gd"
## Paired real 720p rendering, elapsed navigation queries, and fixed-step combat.

const ROOM_POPULATION := 24
const COMBAT_STEP := 1.0 / 24.0

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 3 or not args[0].is_absolute_path() or args[1] not in ["medium", "low"] or not args[2].is_valid_int() or int(args[2]) <= 0:
  push_error("Pass absolute output directory, medium or low, and a positive seed after --")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 var quality := args[1]
 var seed := int(args[2])
 phase = destination.get_file()
 output = destination.get_base_dir() + "/"
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()
 game.change_setting("graphics_quality", quality)
 game.new_balance_version = BalanceRules.CURRENT
 game.return_menu()
 # The prepared wallet keeps benchmark geometry and combat identical across presets.
 check(game.start_endless(THEME, "standard", seed), "start the normal Endless flow")
 game.set_process(false)
 var model: MatchModel = game.model
 check(model.map_data.has("halls"), "procedural map selected")
 if OS.get_environment("NIGHTFALL_PROCEDURAL_MAPS_V2") == "1":
  check(model.map_data.get("version", 0) == 2, "V2 procedural fixture selected")
 check(CinematicQuality.detail(game) == (0 if quality == "low" else 1), "requested preset is active")
 if failures > 0:
  await _finish()
  return
 var room := make_room_fixture(model)
 if room == null or failures > 0:
  await _finish()
  return
 var hunter := model.hunter
 hunter.state = HunterState.State.MOVE
 hunter.target = room.index
 hunter.position = room.door_approach()
 model.running = false
 game.construction.planning = true
 game.construction.refresh()
 game.focus_camera(true)
 await _render_frame()
 check(root.get_texture().get_image().get_size() == Vector2i(1280, 720), "real 1280×720 frame")
 var crowded := await sample_scene(model)
 await capture("crowded-room-720")
 game.construction.planning = false
 game.construction.refresh()
 game.full_map = true
 game.focus_camera(true)
 var overview := await sample_scene(model)
 await capture("overview-720")
 var navigation := measure_paths(model)
 game.full_map = false
 var active := await sample_combat(model)
 await capture("active-combat-720")

 var receipt := FileAccess.open(destination.path_join("benchmark.json"), FileAccess.WRITE)
 check(receipt != null, "write benchmark receipt")
 if receipt != null:
  var data := {
   "engine": Engine.get_version_info(), "adapter": RenderingServer.get_video_adapter_name(),
   "quality": quality, "seed": seed, "theme": THEME, "viewport": [1280, 720],
   "map_version": model.map_data.get("version"), "family": model.map_data.get("family", "v1"),
   "geometry_sha256": JSON.stringify(NightmareMap.pack(model.map_data), "", true, true).sha256_text(),
   "room": room.index, "shape": room.layout.shape, "buildings": room.buildings.size(),
   "scenes": {"crowded_room": crowded, "overview": overview, "active_combat": active},
   "navigation": navigation, "checks": checks, "failures": failures
  }
  receipt.store_string(JSON.stringify(data, "  ", true, true) + "\n")
 await _finish()

func make_room_fixture(model: MatchModel) -> RoomState:
 var index := 0
 var greatest_area := 0.0
 for candidate: RoomState in model.rooms:
  var area := 0.0
  for strip: Rect2 in candidate.layout.floor:
   area += strip.get_area()
  if not candidate.layout.voids.is_empty() and area > greatest_area:
   index = candidate.index
   greatest_area = area
 check(model.claim_room(index), "claim the largest actual floor")
 var room := model.player()
 if room == null:
  return null
 model.player_position = room.bed_position()
 check(model.sleep_player(), "sleep in the occupied bed")
 check(room.spatial != null and room.spatial.grid, "use Full Room Grid")
 if failures > 0:
  return null
 room.gold = 500000.0
 room.electricity = 500000.0
 room.bed_level = 6
 room.door_level = 6
 room.door_hp = room.max_hp()
 for kind in ["shield", "generator", "repair", "economy", "auto_repair", "antenna", "plasma", "barrier", "enhancer", "heavy", "flame", "turret", "frost", "shock", "decoy"]:
  var id := _grid_placement(model, kind, room.door_approach())
  check(id >= 0, "legal paid placement of " + kind)
  if id >= 0:
   # Keep the active sample long enough for both sides to attack.
   var max_level := 3 if kind in DefenseEffects.WEAPONS else 7
   for next in range(2, max_level + 1):
    var okay := model.specialize_building(id, StrategyCatalog.branches(kind)[0]) if next == 5 else model.upgrade_building(id)
    check(okay, "legal paid upgrade %s L%d" % [kind, next])
 while room.buildings.size() < ROOM_POPULATION and _grid_placement(model, "decoy") >= 0:
  pass
 check(room.buildings.size() == ROOM_POPULATION, "filled at least 24 legal building footprints")
 return room

func measure_paths(model: MatchModel) -> Dictionary:
 var sites: Array[Vector2] = [model.map_data.spawn, model.map_data.hunter_spawn]
 for room: RoomState in model.rooms:
  sites.append(room.door_approach())
 for id in ["north", "south", "west", "east"]:
  sites.append(model.map_data.halls[id].center)
 var times := []
 var alternate_times := []
 var cost_times := []
 var segments := 0
 var alternate_paths := 0
 var reachable := true
 for origin in sites:
  var started := Time.get_ticks_usec()
  var costs := model.hunter_route_costs(origin)
  cost_times.append((Time.get_ticks_usec() - started) / 1000.0)
  for index in range(model.rooms.size()):
   reachable = reachable and is_finite(float(costs.get(index, INF)))
  for destination in sites:
   if origin.is_equal_approx(destination):
    continue
   started = Time.get_ticks_usec()
   var path := model.navigation_path(origin, destination)
   times.append((Time.get_ticks_usec() - started) / 1000.0)
   started = Time.get_ticks_usec()
   var alternate := model.navigation_path(origin, destination, false, 1)
   alternate_times.append((Time.get_ticks_usec() - started) / 1000.0)
   if path.is_empty() or alternate.is_empty() or path.back() != destination or alternate.back() != destination:
    reachable = false
    continue
   alternate_paths += int(alternate != path)
   segments += path.size()
 check(reachable, "each measured route reaches its real door or Hall endpoint")
 check(alternate_paths > 0, "fixture includes genuine alternative paths")
 return {
  "point_count": model.map_data.nodes.size(), "lane_count": model.map_data.lane_links.size(),
  "queries_each": times.size(), "alternative_paths": alternate_paths, "primary_path_segments": segments,
  "primary_path_ms": summarized(times), "primary_path_samples_ms": times,
  "alternate_path_ms": summarized(alternate_times), "alternate_path_samples_ms": alternate_times,
  "target_cost_queries": cost_times.size(), "target_cost_ms": summarized(cost_times), "target_cost_samples_ms": cost_times
 }

func sample_combat(model: MatchModel) -> Dictionary:
 var room := model.player()
 var hunter := model.hunter
 # Script the first contact only. Standard and Low then run the same six seconds
 # of production gameplay, including projectiles, damage, AI, and timers.
 model.running = true
 model.time = model.preparation + 1.0
 model.bot_claimed = 5
 for ally: RoomState in model.rooms:
  if ally == room:
   continue
  ally.owner = ally.index + 1
  ally.resident_position = ally.bed_position()
  ally.sleeping = true
  ally.closed = true
  ally.profile = Catalog.BOT_PROFILES[ally.index % Catalog.BOT_PROFILES.size()]
 hunter.state = HunterState.State.ATTACK
 hunter.position = room.door_approach()
 hunter.target = room.index
 hunter.cooldown = .5
 var before := _state_digest(model)
 var start_hp: float
 var start_shots: int
 var start_attacks: int
 var frames := []
 var update_times := []
 var draw_calls := []
 for index in range(TIMING_WARMUP + TIMING_SAMPLES):
  if index == TIMING_WARMUP:
   start_hp = hunter.hp
   start_shots = model.shots
   start_attacks = hunter.attacks
  var started := Time.get_ticks_usec()
  game._process(COMBAT_STEP)
  var updated := Time.get_ticks_usec()
  await _render_frame()
  if index >= TIMING_WARMUP:
   frames.append((Time.get_ticks_usec() - started) / 1000.0)
   update_times.append((updated - started) / 1000.0)
   draw_calls.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
 check(model.result.is_empty() and model.endless.phase == "combat", "active combat lasts through the timed sample")
 check(hunter.attacks > start_attacks and model.shots > start_shots and hunter.hp < start_hp, "real Hunter strikes and machine damage")
 return {
  "frame_ms": summarized(frames), "update_ms": summarized(update_times), "draw_calls": summarized(draw_calls),
  "samples": frames, "update_samples_ms": update_times, "warmup_frames": TIMING_WARMUP, "sample_frames": TIMING_SAMPLES,
  "before_sha256": before, "after_sha256": _state_digest(model), "elapsed_model_s": COMBAT_STEP * TIMING_SAMPLES,
  "hunter_strikes": hunter.attacks - start_attacks, "weapon_shots": model.shots - start_shots,
  "hunter_hp_lost": start_hp - hunter.hp
 }
