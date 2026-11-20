extends "res://tools/capture_visual_rebirth.gd"
## Match the previous 16-building render and separately load more legal grid cells.

func _grid_placement(model, kind: String, prefer: Vector2 = Vector2.INF) -> int:
 var room = model.player()
 var bounds: Rect2 = room.bounds()
 var candidates: Array[Vector2] = []
 var visited := {}
 for y in range(floori(bounds.position.y), ceili(bounds.end.y), 16):
  for x in range(floori(bounds.position.x), ceili(bounds.end.x), 16):
   var point: Vector2 = room.spatial.aligned(Vector2(x, y), kind, 0)
   if point.is_finite() and not visited.has(point):
    candidates.append(point)
    visited[point] = true
 if prefer.is_finite():
  candidates.sort_custom(func(a, b): return a.distance_squared_to(prefer) < b.distance_squared_to(prefer))
 for point in candidates:
  if room.spatial.purchase_reason(kind, point, 0) == "":
   var id: int = room.spatial.next_id
   if model.call("place_building", kind, point, 0):
    return id
 return -1

func _grid_fixture(stress: bool):
 var model = _fresh_room(0)
 var room = model.player()
 check(room.spatial.get("grid"), "grid layout active in player room")
 var placed := []
 var kinds: Array = Catalog.BUILDINGS.keys()
 # Place larger projected roles first before tighter support fillers.
 var order := ["heavy", "flame", "plasma", "barrier", "generator", "repair", "auto_repair", "economy", "turret", "frost", "shield", "enhancer", "shock", "antenna", "decoy"]
 check(order.size() == kinds.size() and order.all(func(kind): return kind in kinds), "all 15 building roles in fixture")
 for index in range(order.size()):
  var kind: String = order[index]
  var id := _grid_placement(model, kind, room.fixed_tile_position(index))
  check(id >= 0, "paid geometry-valid grid placement of " + kind)
  if id >= 0:
   placed.append(id)
   for level in range(2, 11):
    var building: Dictionary = room.buildings[id]
    var ok: bool = model.specialize_building(id, StrategyCatalog.branches(kind)[0]) if building.level == 4 else model.upgrade_building(id)
    check(ok, "paid %s to L%d" % [kind, level])
 var duplicate := _grid_placement(model, "turret", room.fixed_tile_position(15))
 check(duplicate >= 0, "paid sixteenth duplicate Needle")
 if stress:
  # Greedily fill remaining physical space with 2×2 decoys.
  var extra := _grid_placement(model, "decoy")
  while extra >= 0 and room.buildings.size() < 96:
   extra = _grid_placement(model, "decoy")
  check(room.buildings.size() > 16, "actual physical layout exceeds the old cap")
 else:
  check(room.buildings.size() == 16, "matched physically legal 16-building layout")
 _pose_stalker(model)
 model.running = false
 game.presentation.identity.heading = Vector2.LEFT
 return model

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 3 or not args[0].is_absolute_path() or args[1] not in ["medium", "low"] or args[2] not in ["matched", "stress"]:
  push_error("Pass absolute output directory, medium or low, and matched or stress after --.")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 var quality := args[1]
 var stress := args[2] == "stress"
 var grid := OS.get_environment("NIGHTFALL_FULL_ROOM_GRID") == "1"
 if stress and not grid:
  push_error("The greater-than-sixteen fixture requires the grid opt-in.")
  quit(2)
  return
 phase = destination.get_file()
 output = destination.get_base_dir() + "/"
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()
 game.change_setting("graphics_quality", quality)
 check(OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1", "visual catalog enabled")
 check(CinematicQuality.detail(game) == (0 if quality == "low" else 1), "visual quality applied")
 var model = _grid_fixture(stress) if grid else _dense_fixture()
 var room = model.player()
 var counts := {}
 var masterworks := []
 for id in room.buildings:
  var building: Dictionary = room.buildings[id]
  var summary: String = "%s L%d" % [building.kind, building.level]
  counts[summary] = int(counts.get(summary, 0)) + 1
  if building.level == 10:
   masterworks.append(building.kind)
 masterworks.sort()
 var all_roles := Catalog.BUILDINGS.keys()
 all_roles.sort()
 check(masterworks == all_roles and counts.get("turret L1") == 1, "fifteen L10 families and one L1 Needle")
 for index in range(8):
  game.presentation.update(.125, model)
  await _render_frame()
 check(root.get_texture().get_image().get_size() == Vector2i(1280, 720), "rendered actual 720p viewport")
 if stress:
  game.construction.planning = true
  game.construction.refresh()
  await _render_frame()
 var measurements := await _measure(model)
 await capture("dense-720")
 var file := FileAccess.open(destination.path_join("sample.json"), FileAccess.WRITE)
 check(file != null, "timing receipt writable")
 if file != null:
  file.store_string(JSON.stringify({
   "quality": quality, "grid": grid, "stress": stress, "planning_overlay": stress, "seed": SEED,
   "size": [1280, 720], "buildings": room.buildings.size(), "counts": counts,
   "floor_bounds": str(room.bounds()), "frame_time": measurements,
   "sampled_state_sha256": _state_digest(model), "checks": checks, "failures": failures,
  }, "  ") + "\n")
 await _finish()
