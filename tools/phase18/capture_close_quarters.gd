extends "res://tools/capture_visual_rebirth.gd"
## Native rendered evidence. Fixture wallet, placement and clocks are prepared;
## physical navigation, door damage and Hall recovery use real simulation.

const FRAME_STEP := 1.0 / 24.0
const PAIRED_ZOOM := 0.88
const GAP_CUTOFF := 256
var destination := ""
var egress_error := 0

func geometry_digest(data: Dictionary) -> String:
 return JSON.stringify(NightmareMap.pack(data), "", true, true).sha256_text()

func _prepared_model(seed_value: int, theme: String, difficulty: String) -> MatchModel:
 var model := MatchModel.new()
 model.reset(seed_value)
 var stage := "stage_5"
 for entry in StageCatalog.STAGES:
  if entry.map == theme:
   stage = entry.id
   break
 check(model.configure_match(difficulty) and model.configure_stage(stage), "prepared Campaign rules")
 check(model.configure_map(theme) and model.configure_balance(), "requested procedural theme and current balance")
 check(model.configure_strategy(seed_value, "stalker"), "same Stalker selected")
 game._adopt_session(model)
 game.set_process(false)
 return model

func _settle_room(model: MatchModel, index: int) -> RoomState:
 check(model.claim_room(index), "prepared player room assignment")
 var room := model.player()
 if room == null:
  return null
 model.player_position = room.bed_position()
 check(model.sleep_player(), "occupy bed through the model")
 game.ui.update_match()
 model.hunter.boss_policy.enabled = false
 return room

func _surface_at(rectangles: Array, point: Vector2) -> bool:
 for rectangle: Rect2 in rectangles:
  if rectangle.has_point(point):
   return true
 return false

func _wall_gaps(model: MatchModel, room: RoomState) -> Dictionary:
 var gap_samples: Array[int] = []
 for wall: Array in room.layout.walls:
  var a: Vector2 = wall[0]
  var b: Vector2 = wall[1]
  var subdivisions := maxi(1, ceili(a.distance_to(b) / 16.0))
  var perpendicular := (b - a).normalized().orthogonal()
  for index in range(subdivisions):
   var point := a.lerp(b,(index + .5) / subdivisions)
   var positive := _surface_at(room.layout.floor, point + perpendicular * 2.0)
   var negative := _surface_at(room.layout.floor, point - perpendicular * 2.0)
   if positive == negative:
    continue
   var outward := -perpendicular if positive else perpendicular
   var gap := GAP_CUTOFF
   for distance in range(2, GAP_CUTOFF + 1, 2):
    if _surface_at(model.map_data.corridors, point + outward * distance):
     gap = distance
     break
   gap_samples.append(gap)
 gap_samples.sort()
 var count := gap_samples.size()
 if count == 0:
  return {"samples":0}
 return {
  "samples":count, "step_world_units":2, "capped_world_units":GAP_CUTOFF,
  "median":gap_samples[count >> 1], "p95":gap_samples[ceili(count*.95)-1],
  "within_16":gap_samples.filter(func(value):return value<=16).size(),
  "within_48":gap_samples.filter(func(value):return value<=48).size(),
  "no_road_before_cap":gap_samples.filter(func(value):return value==GAP_CUTOFF).size(),
 }

func _surface_coverage(model: MatchModel) -> Dictionary:
 var transform := root.get_canvas_transform().affine_inverse()
 var samples := 0
 var floor_count := 0
 var corridor_count := 0
 # Clear native content region, avoiding the main HUD, left sidebar and dock.
 var region := Rect2(360, 146, 790, 477)
 for y in range(int(region.position.y), int(region.end.y), 6):
  for x in range(int(region.position.x), int(region.end.x), 6):
   var point: Vector2 = transform * Vector2(x,y) - game.MAP_OFFSET
   samples += 1
   var covered := false
   for room: RoomState in model.rooms:
    if _surface_at(room.layout.floor,point):
     floor_count += 1
     covered = true
     break
   if not covered and _surface_at(model.map_data.corridors,point):
    corridor_count += 1
 return {
  "canvas_rect": [region.position.x,region.position.y,region.size.x,region.size.y],
  "sample_step_screen_units":6, "samples":samples, "room_floor_samples":floor_count,
  "corridor_samples":corridor_count, "uncovered_samples":samples-floor_count-corridor_count,
 }

func _save_frame(name: String):
 var image := root.get_texture().get_image()
 check(image.save_png(destination.path_join(name + ".png")) == OK, "native " + name)

func _paired_views(model: MatchModel, room: RoomState) -> Dictionary:
 game.focus_camera(true)
 var normal_zoom: float = game.camera.zoom.x
 await _render_frame()
 _save_frame("normal-focus")
 game.camera.zoom = Vector2.ONE * PAIRED_ZOOM
 game.camera.position = room.bounds().get_center() + game.MAP_OFFSET + Vector2(-2,-20)
 game.camera.offset = Vector2.ZERO
 game.camera.force_update_scroll()
 await _render_frame()
 _save_frame("matched-focus")
 var coverage := _surface_coverage(model)
 game.full_map = true
 game.focus_camera(true)
 await _render_frame()
 _save_frame("overview")
 game.full_map = false
 game.focus_camera(true)
 return {
  "normal_zoom":normal_zoom, "matched_zoom":PAIRED_ZOOM, "coverage":coverage,
  "wall_gaps":_wall_gaps(model, room), "room_bounds":str(room.bounds()),
 }

func _route_distance(origin: Vector2, points: Array) -> float:
 var result := 0.0
 for point: Vector2 in points:
  result += origin.distance_to(point)
  origin = point
 return result

func _near_wall(point: Vector2, room: RoomState) -> float:
 var nearest := INF
 for wall: Array in room.layout.walls:
  var boundary := Geometry2D.get_closest_point_to_segment(point,wall[0],wall[1])
  nearest = minf(nearest, point.distance_to(boundary))
 return nearest

func _approach_start(model: MatchModel, room: RoomState) -> Dictionary:
 var candidates: Array[Vector2] = [room.layout.anchor]
 for lane: Rect2 in model.map_data.corridors:
  if lane.intersects(room.bounds().grow(96)):
   candidates.append(lane.get_center())
 for node: Vector2 in model.map_data.nodes:
  if room.bounds().grow(125).has_point(node):
   candidates.append(node)
 var best := {}
 var best_score := INF
 for point in candidates:
  if not model.navigation_walkable(point) or room.floor_has_point(point):
   continue
  var route := model.navigation_path(point,room.door_approach())
  if route.is_empty() or not Vector2(route.back()).is_equal_approx(room.door_approach()):
   continue
  if not root.get_visible_rect().grow(-22).has_point(game.world_to_screen(point)):
   continue
  var length := _route_distance(point,route)
  if length < 118.0 or length > 520.0:
   continue
  # Prefer a legal, wall-adjacent approach and enough travel to see the turn.
  var score := absf(length-270.0) * .2 + _near_wall(point,room)
  if score < best_score:
   best_score = score
   best = {"point":point,"length":length,"route":route}
 return best

func _occupation(model: MatchModel, room: RoomState, allies: bool):
 model.bot_claimed = 5
 if allies:
  for ally: RoomState in model.rooms:
   if ally != room:
    ally.owner = ally.index + 1
    ally.sleeping = true
    ally.closed = true
    ally.resident_position = ally.bed_position()
    ally.bot_timer = 9999.0

func _check_motion(model: MatchModel, before: Vector2, after: Vector2) -> bool:
 if before.is_equal_approx(after):
  return true
 return model.navigation_walkable(after) and NightmareNavigation.visible(model,before,after)

func _approach(model: MatchModel, room: RoomState) -> Dictionary:
 var start := _approach_start(model, room)
 check(not start.is_empty(), "authentic approach from nearby connected corridor")
 if start.is_empty():
  return {}
 _occupation(model,room,false)
 model.time = model.preparation + 3.0
 model.haunt_recovery.available_at = INF
 var hunter := model.hunter
 hunter.position = start.point
 hunter.target = room.index
 hunter.state = HunterState.State.MOVE
 hunter.cooldown = .15
 var original_door: float = room.door_hp
 var traveled := 0.0
 var closest := INF
 var near_wall_visible := 0
 var step_limit_errors := 0
 var contact_stamp := -1.0
 var encounter_stamp := -1.0
 var strike_pose_saved := false
 var samples := 0
 var original_time: float = model.time
 game.focus_camera(true)
 await _render_frame()
 _save_frame("approach-start")
 for frame in range(24*12):
  var before: Vector2 = hunter.position
  var state: int = hunter.state
  game._process(FRAME_STEP)
  await RenderingServer.frame_post_draw
  samples += 1
  if state == HunterState.State.MOVE:
   var travel: float = before.distance_to(hunter.position)
   traveled += travel
   if travel > hunter.speed * FRAME_STEP + 1.0:
    step_limit_errors += 1
   if not _check_motion(model,before,hunter.position):
    egress_error += 1
   var distance := _near_wall(hunter.position,room)
   closest = minf(closest,distance)
   if travel > .2 and distance <= 60.0 and root.get_visible_rect().has_point(game.world_to_screen(hunter.position)):
    near_wall_visible += 1
    if near_wall_visible == 6:
     _save_frame("adjacent-walk")
  if encounter_stamp < 0.0 and hunter.state == HunterState.State.ATTACK:
   encounter_stamp = model.time - original_time
   _save_frame("real-door-approach")
  if contact_stamp < 0.0 and hunter.attacks > 0:
   contact_stamp = model.time - original_time
   _save_frame("real-door-contact")
  if contact_stamp >= 0.0 and model.time-original_time>contact_stamp+.70:
   strike_pose_saved = true
   break
 check(strike_pose_saved and room.door_hp < original_door, "production movement ends in actual door damage")
 check(room.bounds().get_area() > 0 and egress_error == 0 and step_limit_errors == 0, "approach segments stay on legal geometry without jumps")
 return {
  "start":str(start.point), "expected_graph_route":str(start.route),
  "expected_graph_route_length":start.length, "model_travel_length":traveled,
  "first_door_contact_seconds":contact_stamp, "first_attack_state_seconds":encounter_stamp,
  "door_hp_before":original_door, "door_hp_after":room.door_hp, "near_wall_visible_frames":near_wall_visible,
  "closest_wall_world_units":closest, "sample_frames":samples,
  "geometry_errors":egress_error,"speed_bound_errors":step_limit_errors,
 }

func _race(model: MatchModel) -> Dictionary:
 check(model.begin_room_rush(13), "actual shared-spawn race starts")
 var shared := model.room_rush_spawn()
 check(model.room_rush_runners().size() == 5 and model.room_rush_runners().all(func(runner):return runner.position == shared), "all five NPCs start in same place as human")
 var route: Array = []
 var target := -1
 var own_claim := -1.0
 var npc_claims: Array[float] = []
 var previous_count := 0
 await _render_frame()
 _save_frame("shared-spawn")
 for frame in range(24*15):
  if model.player_room < 0:
   if route.is_empty() or (target >= 0 and model.rooms[target].owner >= 0):
    var choices: Dictionary = model.room_rush.routes_to_vacant_rooms(model,model.player_position)
    var best := INF
    for id in choices:
     var distance := _route_distance(model.player_position, choices[id])
     if distance < best:
      target = id
      route = choices[id].duplicate()
      best = distance
   if not route.is_empty():
    var movement: Vector2 = Vector2(route.front()) - model.player_position
    model.move_player(movement / (model.SURVIVOR_SPEED*FRAME_STEP), FRAME_STEP)
    if model.player_position.distance_to(route.front()) < 1.0:
     route.pop_front()
    if target >= 0 and model.room_rush.can_claim(model,target,model.player_position):
     model.interact()
     if model.player_room >= 0:
      own_claim = model.time
  game._process(FRAME_STEP)
  await RenderingServer.frame_post_draw
  if model.bot_claimed > previous_count:
   for index in range(previous_count,model.bot_claimed):
    npc_claims.append(model.time)
   previous_count = model.bot_claimed
  if frame == 22:
   _save_frame("physical-race")
 check(own_claim >= 0 and npc_claims.size() > 0, "human and NPC claim through real physical entry")
 _save_frame("race-end")
 return {"spawn":str(shared), "human_claim":own_claim, "npc_claims_within_clip":npc_claims, "time":model.time}

func _hall(model: MatchModel, room: RoomState) -> Dictionary:
 _occupation(model,room,true)
 model.time = model.preparation + 40.0
 var hunter := model.hunter
 hunter.target = room.index
 hunter.state = HunterState.State.ATTACK
 hunter.position = room.door_approach()
 hunter.hp = hunter.max_hp * .36
 var started := model.haunt_recovery.try_retreat(hunter,model)
 check(started,"actual low-HP retreat through the normal policy")
 if not started:
  return {}
 var hall := model.haunt_recovery.hall_id
 var before_hp: float = hunter.hp
 var recovery_time := -1.0
 var finished := -1.0
 var returned := -1.0
 var hall_center: Vector2 = model.map_data.halls[hall].center
 var before_time: float = model.time
 game.hunter_spectating = true
 game.focus_camera(true)
 await _render_frame()
 _save_frame("retreat-start")
 for frame in range(24*26):
  var prior: Vector2 = hunter.position
  var prior_phase := model.haunt_recovery.phase
  game._process(FRAME_STEP)
  await RenderingServer.frame_post_draw
  if prior_phase == "retreat" and not _check_motion(model,prior,hunter.position):
   egress_error += 1
  if recovery_time < 0.0 and model.haunt_recovery.phase == "recover":
   recovery_time = model.time-before_time
   _save_frame("hall-recovery")
  if recovery_time >= 0.0 and finished < 0.0 and model.haunt_recovery.visits > 0:
   finished = model.time-before_time
  if finished >= 0.0 and hunter.position.distance_to(hall_center) >= 140.0 and hunter.state in [HunterState.State.MOVE,HunterState.State.ATTACK]:
   returned = model.time-before_time
   _save_frame("hall-return")
   break
 check(recovery_time >= 0.0 and finished >= 0.0 and returned >= 0.0 and hunter.hp > before_hp and egress_error == 0,"full retreat, heal and physical exit to a renewed attack route")
 return {
  "hall":hall,"hp_before":before_hp,"hp_after":hunter.hp,
  "recovery_start":recovery_time,"recovery_ended":finished,"returned_to_hallway":returned,"geometry_errors":egress_error,
 }

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 7 or not args[0].is_absolute_path() or args[1] not in ["views","approach","rush","hall"] or args[2] not in ["standard","hard","hell"] or args[6] not in ["720","540"]:
  push_error("Pass absolute output, views/approach/rush/hall, difficulty, theme, seed, room index and 720/540.")
  quit(2)
  return
 destination = args[0]
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280,720) if args[6] == "720" else Vector2i(960,540)
 await setup_game()
 game.onboarding.close_welcome()
 game.change_setting("graphics_quality","medium")
 var model := _prepared_model(int(args[4]),args[3],args[2])
 check(model.is_procedural(), "uses real procedural navigation")
 check(root.size == (Vector2i(1280,720) if args[6]=="720" else Vector2i(960,540)), "actual target viewport size")
 var scene := {}
 if args[1] == "rush":
  scene = await _race(model)
 else:
  var room := _settle_room(model,int(args[5]))
  if room != null:
   match args[1]:
    "views":scene = await _paired_views(model,room)
    "approach":scene = await _approach(model,room)
    "hall":scene = await _hall(model,room)
 var receipt := FileAccess.open(destination.path_join("capture.json"),FileAccess.WRITE)
 check(receipt != null,"write trajectory and scene receipt")
 if receipt != null:
  receipt.store_string(JSON.stringify({
   "scenario":args[1],"difficulty":args[2],"theme":model.map_id,"seed":model.map_seed,
   "room_requested":int(args[5]),"version":model.map_data.get("version"),"family":model.map_data.get("family"),
   "geometry_sha256":geometry_digest(model.map_data),"viewport":[root.size.x,root.size.y],
   "renderer":RenderingServer.get_video_adapter_name(), "phase18_enabled":OS.get_environment("NIGHTFALL_CLOSE_QUARTERS")=="1",
   "visibility_and_motion":scene,"checks":checks,"failures":failures,
  },"  ",true,true)+"\n")
 await _finish()
