extends "res://tools/capture_visual_rebirth.gd"
## Same frozen paid room and measurement for checkpoint/current visual presets.

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 2 or not args[0].is_absolute_path() or args[1] not in ["medium","low"]:
  push_error("Pass an absolute evidence directory and medium or low after --")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 var quality: String = args[1]
 phase = destination.get_file()
 output = destination.get_base_dir() + "/"
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280,720)
 await setup_game()
 game.onboarding.close_welcome()
 game.change_setting("graphics_quality",quality)
 check(OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1", "opt-in visual catalog enabled")
 check(game.profile.settings.get("graphics_quality") == quality, "real visual quality setting reached the profile")
 check(CinematicQuality.detail(game) == (0 if quality == "low" else 1), "renderer receives expected quality tier")
 var model = _dense_fixture()
 var room = model.player()
 var level_ten := []
 var other := []
 for building in room.buildings.values():
  if building.level == 10:
   level_ten.append(building.kind)
  else:
   other.append({"kind":building.kind,"level":building.level})
 level_ten.sort()
 var expected := Catalog.BUILDINGS.keys()
 expected.sort()
 check(room.tile_count() == 16 and room.buildings.size() == 16, "actual room has 16 occupied slots")
 check(level_ten == expected and level_ten.size() == 15, "all 15 unique placeable families are Level 10")
 check(other == [{"kind":"turret","level":1}], "extra slot retains actual Level 1 Needle")
 for index in range(8):
  game.presentation.update(.125,model)
  await _render_frame()
 check(root.get_texture().get_image().get_size() == Vector2i(1280,720), "actual gameplay viewport is 1280x720")
 var timing := await _measure(model)
 await capture("dense-720")
 root.size = Vector2i(1920,1080)
 await _render_frame()
 await _render_frame()
 await capture("dense-1080")
 check(root.get_texture().get_image().get_size() == Vector2i(1920,1080), "actual gameplay viewport is 1920x1080")
 var result := {
  "quality": quality, "seed": SEED, "frame_time": timing,
  "sample_resolution": [1280,720], "captured_resolutions": [[1280,720],[1920,1080]],
  "level_10_families":level_ten, "extra_buildings":other,
  "model_sha256":_state_digest(model), "checks":checks, "failures":failures
 }
 var file := FileAccess.open(destination.path_join("measurement.json"),FileAccess.WRITE)
 if file == null:
  check(false,"benchmark output writable")
 else:
  file.store_string(JSON.stringify(result,"  ")+"\n")
 await _finish()
