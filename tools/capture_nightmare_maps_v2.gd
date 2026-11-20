extends SceneTree
## Screenshots use Game's real viewport. Route clips advance normal MatchModel ticks.
const THEMES := ["abandoned_dorm", "haunted_hospital", "forgotten_hotel", "underground_lab", "cursed_mansion"]
const FAMILIES := ["ring", "branching", "scattered", "spine", "zigzag", "radial", "twin_wings", "labyrinth", "courtyards", "hybrid"]
const ROUTE_FAMILIES := ["ring", "branching", "scattered", "zigzag", "labyrinth"]
const STEP := .05
const STEPS_PER_SHOT := 5
var game
var directory: String
var errors: Array[String] = []
var receipt: Dictionary = {}
var stills := false

func _initialize():
 call_deferred("run")

func verify(ok: bool, message: String):
 if not ok:
  errors.append(message)
  push_error(message)

func run():
 var arguments := OS.get_cmdline_user_args()
 if arguments.is_empty() or not arguments[0].is_absolute_path():
  push_error("Pass an absolute directory, with optional --stills after it.")
  quit(2)
  return
 directory = arguments[0]
 stills = "--stills" in arguments
 DirAccess.make_dir_recursive_absolute(directory)
 root.size = Vector2i(1280, 720)
 OS.set_environment("NIGHTFALL_PROFILE_PATH", "user://nightmare-v2-visual-evidence.json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 await process_frame
 if is_instance_valid(game.onboarding):
  preload("res://tests/onboarding_test_support.gd").skip(game)
  game.onboarding.set_process(false)
 game.profile.settings.graphics_quality = "medium"
 var gallery := gallery_seeds()
 verify(gallery.size() == 12, "found 12 representative native generated layouts")
 if gallery.is_empty():
  quit(1)
  return
 await gallery_images(gallery)
 await camera_inputs(gallery[0])
 await seed_inputs()
 if not stills:
  await route_images(gallery)
 receipt.errors = errors
 var file := FileAccess.open(directory.path_join("capture.json"), FileAccess.WRITE)
 file.store_string(JSON.stringify(receipt, "  ") + "\n")
 file.close()
 game.audio_system.shutdown()
 game.queue_free()
 await process_frame
 print("NIGHTMARE_V2_VISUAL_FAILURES=", errors.size())
 quit(1 if not errors.is_empty() else 0)

func gallery_seeds() -> Array:
 var results: Array = []
 var used_seeds: Dictionary = {}
 var by_family: Dictionary = {}
 for index in range(FAMILIES.size()+2):
  var family: String = FAMILIES[index] if index < FAMILIES.size() else ["ring", "hybrid"][index-FAMILIES.size()]
  var theme: String = THEMES[index % THEMES.size()]
  var model := MatchModel.new()
  model.procedural_v2_requested = true
  for seed in range(19+index*33, 1519+index*33):
   if used_seeds.has(seed):
    continue
   model.reset(seed)
   if not model.configure_map(theme) or model.map_data.get("family") != family:
    continue
   var bounds: Rect2 = model.map_bounds()
   if by_family.has(family) and bounds.size.distance_to(by_family[family]) < 80.0:
    continue
   used_seeds[seed] = true
   by_family[family] = bounds.size
   results.append({"family":family, "theme":theme, "seed":seed, "extent":arr(bounds.size)})
   break
 return results

func fixture(spec: Dictionary, room_index := 0) -> MatchModel:
 var model := MatchModel.new()
 model.procedural_v2_requested = true
 verify(model.configure_endless(spec.theme, "standard", int(spec.seed), int(spec.seed)), "Endless configured: "+str(spec.family))
 verify(model.map_data.get("family", "") == spec.family, "natural opt-in seed selected intended family")
 verify(model.configure_balance(), "current balance enabled")
 verify(model.claim_room(room_index), "claimed a generated room")
 model.player_position = model.player().bed_position()
 verify(model.sleep_player(), "occupied generated bed via production command")
 model.bot_claimed = 5
 game._adopt_session(model)
 game.set_process(false)
 game.full_map = true
 game.reset_overview()
 game.focus_camera(true)
 game.ui.update_match()
 return model

func gallery_images(gallery: Array):
 var common := INF
 for spec in gallery:
  var extent := Vector2(spec.extent[0], spec.extent[1])
  var available: Vector2 = game.overview_frame().size
  common = minf(common, minf(available.x/extent.x, available.y/extent.y))
 common *= .98
 var rows: Array = []
 for i in range(gallery.size()):
  var spec: Dictionary = gallery[i]
  var model := fixture(spec)
  game.overview_zoom = common/game.overview_fit()
  game.focus_camera(true)
  verify(is_equal_approx(game.camera.zoom.x, common), "native camera applies shared gallery scale")
  var frame_rect: Rect2 = game.overview_frame().grow(1)
  var bounds: Rect2 = model.map_bounds()
  verify(frame_rect.has_point(game.world_to_screen(bounds.position)) and frame_rect.has_point(game.world_to_screen(bounds.end)), "whole generated map fits")
  var file: String = "%02d-%s-%d" % [i+1, spec.family, spec.seed]
  await image(file)
  var row := spec.duplicate()
  row.file = file+".png"
  row.map_sha256 = JSON.stringify(NightmareMap.pack(model.map_data), "", true, true).sha256_text()
  rows.append(row)
 receipt.gallery = {"screen_px_per_world_unit":common, "viewport":[1280,720], "layouts":rows}

func camera_inputs(spec: Dictionary):
 var model := fixture(spec)
 await render()
 var before: float = game.camera.zoom.x
 var wallet: float = model.player().gold
 var screen: Vector2 = game.world_to_screen(model.player().bed_position())
 await mouse_event(MOUSE_BUTTON_LEFT,screen)
 verify(game.overview_room == model.player_room, "native overview click inspects room")
 verify(model.player().gold == wallet and model.player().buildings.is_empty(), "map selection never buys a building")
 await mouse_event(MOUSE_BUTTON_WHEEL_UP,game.overview_frame().get_center())
 verify(game.camera.zoom.x > before,"native overview wheel zoom")
 var old_pan: Vector2 = game.overview_pan
 var motion := InputEventMouseMotion.new()
 motion.position = game.overview_frame().get_center()
 motion.global_position = motion.position
 motion.relative = Vector2(95, 95)
 motion.button_mask = MOUSE_BUTTON_MASK_MIDDLE
 Input.parse_input_event(motion)
 await process_frame
 verify(game.overview_pan.distance_squared_to(old_pan) > 1.0,"native middle drag pans current map")
 await key_event(KEY_0)
 verify(is_equal_approx(game.camera.zoom.x,before) and game.overview_pan.is_zero_approx(),"native reset restores adaptive fit")
 await image("overview-input-reset")
 receipt.camera = {"zoomed":true, "panned":true, "fit_reset":true, "room_inspection":true, "unchanged_wallet":true}

func key_event(code: Key):
 for pressed in [true, false]:
  var event := InputEventKey.new()
  event.keycode = code
  event.physical_keycode = code
  if code>=KEY_0 and code<=KEY_9:event.unicode=code
  event.pressed = pressed
  Input.parse_input_event(event)
  await process_frame

func mouse_event(button: MouseButton, position: Vector2):
 for pressed in [true, false]:
  var event := InputEventMouseButton.new()
  event.position = position
  event.global_position = position
  event.button_index = button
  event.pressed = pressed
  Input.parse_input_event(event)
  await process_frame

func seed_inputs():
 var screen = game.ui.replay_ui
 screen.selected_map = "abandoned_dorm"
 var random_families: Array[String] = []
 var random_seeds: Array[int] = []
 var fixed_signature := ""
 var typed_seed := 21
 for index in range(5):
  game.return_menu()
  screen.show_endless()
  await process_frame
  var field: LineEdit
  var start_button: Button
  for child in game.ui.panel.get_children():
   if child is LineEdit and child.placeholder_text == "Random seed":
    field = child
   if child is Button and child.text == "New Endless run":
    start_button = child
  verify(is_instance_valid(field) and is_instance_valid(start_button),"native setup has optional seed field and New Run")
  if not is_instance_valid(field) or not is_instance_valid(start_button):
   return
  if index>=3 and field.text.is_empty():
   field.grab_focus()
   await key_event(KEY_2)
   await key_event(KEY_1)
  if index>=3:
   verify(field.text==str(typed_seed),"explicit seed entered through native LineEdit")
  var click: Vector2=root.get_final_transform()*start_button.get_global_rect().get_center()
  await mouse_event(MOUSE_BUTTON_LEFT,click)
  var model: MatchModel = game.model
  verify(game.mode=="match" and model.is_procedural() and model.run_kind=="endless","native New Run adopts a procedural match")
  if index<3:
   verify(model.map_data.family not in random_families,"blank seed avoided the recent macro families")
   random_families.append(model.map_data.family)
   random_seeds.append(model.map_seed)
  else:
   verify(model.map_seed==typed_seed,"explicit seed bypasses recent history")
   var signature:=JSON.stringify(NightmareMap.pack(model.map_data),"",true,true).sha256_text()
   verify(fixed_signature.is_empty() or fixed_signature==signature,"explicit seed repeats original geometry")
   fixed_signature=signature
 receipt.seed_input={"random_seeds":random_seeds,"random_families":random_families,"explicit_seed":typed_seed,"explicit_geometry_sha256":fixed_signature}

func route_images(gallery: Array):
 var evidence: Array = []
 for family in ROUTE_FAMILIES:
  for spec in gallery:
   if spec.family != family:
    continue
   var model := fixture(spec)
   var target := choose_route(model)
   verify(not target.is_empty(),"walkable exterior approach for "+family)
   if not target.is_empty():
    evidence.append(await record_route(model,target,family))
   break
 receipt.routes = evidence

func choose_route(model: MatchModel) -> Dictionary:
 var best := -INF
 var selected: Dictionary = {}
 var finish := model.player().door_approach()
 for at: Vector2 in model.map_data.nodes:
  if at.distance_to(finish) < 220:
   continue
  for variant in [0,1]:
   var route: Array = model.navigation_path(at,finish,false,variant)
   if route.size() < 3 or not Vector2(route.back()).is_equal_approx(finish):
    continue
   var length: float = path_length(at,route)
   if length > 1800 or length < at.distance_to(finish)*1.08:
    continue
   var score := 120.0*route.size()-absf(950.0-length)*.43
   if score <= best:
    continue
   best = score
   selected = {"start":at, "end":finish, "variant":variant, "planned":route, "length":length}
 return selected

func record_route(model: MatchModel, target: Dictionary, family: String) -> Dictionary:
 var start: Vector2 = target.start
 var finish: Vector2 = target.end
 model.time = model.endless.wave_started_at + 1.0
 model.hunter.state = HunterState.State.MOVE
 model.hunter.target = model.player_room
 model.hunter.position = start
 model.hunter.decision_count = posmod(int(target.variant)-model.player_room,2)
 model.hunter.tactical_cooldown = 1000
 model.hunter.arcane.cooldown = 1000
 model.hunter.nightmare.cooldown = 1000
 model.hunter.boss_policy.enabled = false
 model.hunter.cooldown = 1.0
 var trail := Line2D.new()
 trail.default_color = Color("E7C886")
 trail.width = 2.4/game.camera.zoom.x
 trail.antialiased = true
 trail.z_index = 3
 game.add_child(trail)
 trail.add_point(start+game.MAP_OFFSET)
 var folder := directory.path_join("route-"+family)
 DirAccess.make_dir_recursive_absolute(folder)
 var trace := [arr(start)]
 var step_max := 0.0
 var distance := 0.0
 var frames := 0
 var steps := 0
 for frame_index in range(165):
  for sample in range(STEPS_PER_SHOT):
   var prior: Vector2 = model.hunter.position
   game._process(STEP)
   steps += 1
   var current: Vector2 = model.hunter.position
   var step_distance := current.distance_to(prior)
   distance += step_distance
   step_max = maxf(step_max,step_distance)
   verify(model.navigation_walkable(current), "actual Hunter stays on legal terrain for "+family)
   verify(step_distance <= model.hunter.speed*STEP+.03,"actual Hunter keeps its movement budget for "+family)
   if step_distance > .01:
    trail.add_point(current+game.MAP_OFFSET)
    trace.append(arr(current))
   if current.distance_to(finish)<3:
    break
  await render()
  var shot := root.get_texture().get_image()
  verify(shot.save_jpg(folder.path_join("%04d.jpg" % frame_index),.90)==OK,"frame saved")
  frames += 1
  if model.hunter.position.distance_to(finish)<3:
   break
 verify(model.hunter.position.distance_to(finish)<3,"Hunter arrives at real door approach for "+family)
 verify(distance > start.distance_to(finish)*1.05,"sampled movement took a legal turn around the topology")
 await image("hunter-route-"+family)
 trail.queue_free()
 await process_frame
 return {"family":family, "seed":model.map_seed,"theme":model.map_id, "room":model.player_room+1, "route_variant":target.variant,
  "planned":target.planned.map(arr), "actual":trace,"total_world_distance":distance,"straight_world_distance":start.distance_to(finish),
  "max_step_distance":step_max,"normal_game_ticks":steps,"frames":frames,"arrived":model.hunter.position.distance_to(finish)<3}

func path_length(from: Vector2, route: Array) -> float:
 var length := 0.0
 for to: Vector2 in route:
  length += from.distance_to(to)
  from = to
 return length

func arr(point: Vector2) -> Array:
 return [point.x,point.y]

func render():
 game.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw

func image(name: String):
 await render()
 var shot := root.get_texture().get_image()
 verify(shot.get_size()==Vector2i(1280,720),"native 1280×720 capture")
 verify(shot.save_png(directory.path_join(name+".png"))==OK,"saved "+name)
