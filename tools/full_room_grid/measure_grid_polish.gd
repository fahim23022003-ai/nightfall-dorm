extends "res://tools/full_room_grid/measure_grid_density.gd"
## Compare the same paid building layouts with the planning grid visible.

const DENSITIES := [24, 40, 60, 82]
const TRIAL_FRAMES := 180
const SETTLE_FRAMES := 30

func _layout(room) -> Array:
 var rows := []
 for id in room.buildings:
  var b: Dictionary = room.buildings[id]
  var p: Vector2 = room.tile_position(id)
  rows.append({"id": id, "kind": b.kind, "level": b.level, "branch": b.get("specialization", ""), "rotation": b.get("rotation", 0), "point": [p.x, p.y]})
 return rows

func _normalize_layout(rows: Array) -> Array:
 var normalized := []
 for row in rows:
  normalized.append({"id": int(row.id), "kind": str(row.kind), "level": int(row.level),
   "branch": str(row.branch), "rotation": int(row.rotation),
   "point": [float(row.point[0]), float(row.point[1])]})
 return normalized

func _validate_layout(model, density: int) -> void:
 var room = model.player()
 check(room.spatial.grid and room.buildings.size() == density, "real grid populated to %d" % density)
 var masterworks := 0
 for id in room.buildings:
  var b: Dictionary = room.buildings[id]
  var point: Vector2 = room.tile_position(id)
  check(room.spatial.geometry_reason(point, id, {}, b.kind, b.rotation) == "", "legal typed footprint at building %d" % id)
  masterworks += int(b.level == 10)
 check(masterworks == Catalog.BUILDINGS.size(), "one masterwork per building role")

func _create_fixture(density: int, layout_path: String):
 var model = _grid_fixture(false) if layout_path.is_empty() else _fresh_room(0)
 if layout_path.is_empty():
  model.running = true
  while model.player().buildings.size() < density:
   if _grid_placement(model, "decoy") < 0:
    break
  model.running = false
 else:
  var replay = JSON.parse_string(FileAccess.get_file_as_string(layout_path))
  check(replay is Array and replay.size() == density, "read exact checkpoint layout")
  if replay is not Array:
   return model
  for row in replay:
   var point := Vector2(row.point[0], row.point[1])
   var kind: String = row.kind
   var id: int = model.player().spatial.next_id
   var paid: bool = model.place_building(kind, point, int(row.rotation))
   check(paid and id == int(row.id), "pay same checkpoint footprint %d" % int(row.id))
   if not paid:
    continue
   for level in range(2, int(row.level) + 1):
    var upgraded: bool = model.specialize_building(id, row.branch) if level == 5 and row.branch != "" else model.upgrade_building(id)
    check(upgraded, "pay same checkpoint upgrade %d→L%d" % [id, level])
  check(JSON.stringify(_layout(model.player())) == JSON.stringify(_normalize_layout(replay)), "same building IDs, kinds, levels, branches, rotations and coordinates")
  _pose_stalker(model)
  model.running = false
  game.presentation.identity.heading = Vector2.LEFT
 _validate_layout(model, density)
 return model

func _summary(values: Array) -> Dictionary:
 var sorted := values.duplicate()
 sorted.sort()
 var middle := int(sorted.size() / 2.0)
 var median: float = sorted[middle] if sorted.size() % 2 else (sorted[middle - 1] + sorted[middle]) * .5
 return {"median": median, "p95": sorted[ceili(sorted.size() * .95) - 1], "max": sorted.back()}

func _trace(model) -> Dictionary:
 var before := _state_digest(model)
 var frame_ms := []
 var update_ms := []
 var draw_calls := []
 var objects := []
 var primitives := []
 for frame in range(SETTLE_FRAMES + TRIAL_FRAMES):
  var begin := Time.get_ticks_usec()
  game.presentation.update(STEP, model)
  var updated := Time.get_ticks_usec()
  await _render_frame()
  var elapsed := (Time.get_ticks_usec() - begin) / 1000.0
  if frame >= SETTLE_FRAMES:
   frame_ms.append(elapsed)
   update_ms.append((updated - begin) / 1000.0)
   draw_calls.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
   objects.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))
   primitives.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
 check(_state_digest(model) == before, "profiling leaves sampled gameplay state untouched")
 return {
  "frame_ms": _summary(frame_ms), "presentation_update_ms": _summary(update_ms),
  "draw_calls": _summary(draw_calls), "rendered_objects": _summary(objects), "rendered_primitives": _summary(primitives),
  "render_memory_bytes": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
  "static_memory_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
  "frames": frame_ms, "presentation_update_frames": update_ms, "draw_calls_frames": draw_calls,
  "warmup_frames": SETTLE_FRAMES, "sample_frames": TRIAL_FRAMES, "model_sha256": before,
 }

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() not in [2,3] or not args[0].is_absolute_path() or args[1] not in ["medium", "low"]:
  push_error("Pass absolute result directory, medium or low, and optional checkpoint layout directory after --.")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 var quality := args[1]
 var layouts := args[2].trim_suffix("/") if args.size() == 3 else ""
 output = destination + "/"
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()
 game.change_setting("graphics_quality", quality)
 check(OS.get_environment("NIGHTFALL_FULL_ROOM_GRID") == "1" and OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1", "both previews enabled")
 check(CinematicQuality.detail(game) == (0 if quality == "low" else 1), "requested renderer quality delivered")
 for density in DENSITIES:
  phase = str(density)
  var subdir := destination.path_join(phase)
  DirAccess.make_dir_recursive_absolute(subdir)
  var layout_path := "" if layouts.is_empty() else layouts.path_join(phase).path_join("layout.json")
  var model = _create_fixture(density, layout_path)
  game.construction.planning = true
  game.construction.refresh()
  for frame in range(8):
   game.presentation.update(.125, model)
   await _render_frame()
  check(root.get_texture().get_image().get_size() == Vector2i(1280, 720), "real gameplay viewport is 1280×720")
  var trace := await _trace(model)
  var room = model.player()
  var rows := _layout(room)
  var result := {"density": density, "quality": quality, "seed": SEED, "viewport": [1280, 720],
    "room_bounds": str(room.bounds()), "planning_overlay": true, "layout_sha256": JSON.stringify(rows).sha256_text(),
    "trace": trace, "checks": checks, "failures": failures}
  FileAccess.open(subdir.path_join("layout.json"), FileAccess.WRITE).store_string(JSON.stringify(rows, " ") + "\n")
  FileAccess.open(subdir.path_join("sample.json"), FileAccess.WRITE).store_string(JSON.stringify(result, " ") + "\n")
  await capture("dense-720")
  print("GRID_POLISH ", density, " ", quality, " ", trace.frame_ms)
 await _finish()
