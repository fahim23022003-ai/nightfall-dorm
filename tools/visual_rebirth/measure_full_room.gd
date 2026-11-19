extends "res://tools/capture_visual_rebirth.gd"
## Repeat the frozen 16-slot view with the established 30/240-frame sample.

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 1 or not args[0].is_absolute_path():
  push_error("Pass an absolute evidence directory")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 phase = destination.get_file()
 output = destination.get_base_dir() + "/"
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()
 var model = _dense_fixture()
 for index in range(8):
  game.presentation.update(.125,model)
  await _render_frame()
 check(root.get_texture().get_image().get_size() == Vector2i(1280,720), "actual 720p viewport")
 check(OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1", "visual mode enabled")
 check(game.profile.settings.get("graphics_quality") == "medium", "identical graphics tier")
 var summary := {
  "frame_time": await _measure(model),
  "model_sha256": _state_digest(model),
  "checks": checks,
  "failures": failures
 }
 await capture("full16-720")
 var file := FileAccess.open(destination.path_join("measurement.json"),FileAccess.WRITE)
 if file == null:
  check(false,"benchmark output writable")
 else:
  file.store_string(JSON.stringify(summary,"  ")+"\n")
 await _finish()
