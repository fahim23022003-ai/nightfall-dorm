extends "res://tools/capture_visual_rebirth.gd"

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 1 or not args[0].is_absolute_path():
  fail("Pass an absolute evidence directory after --")
  return
 var destination := args[0].trim_suffix("/")
 output = destination.get_base_dir() + "/"
 phase = destination.get_file()
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()
 game.change_setting("graphics_quality", "low")
 game.change_setting("reduced_motion", true)
 game.change_setting("reduced_flashes", true)
 game.change_setting("reduced_effects", true)
 check(CinematicQuality.detail(game) == 0 and CinematicQuality.reduced_motion(game) and CinematicQuality.reduced_flash(game), "low and reduced options reached renderer")
 var model = _dense_fixture()
 var room = model.player()
 for index in range(8):
  game.presentation.update(.125, model)
  await _render_frame()
 check(room.buildings.size() == 16, "all sixteen slots rendered")
 await capture("full16-low-reduced-720")
 var checksum := _state_digest(model)
 var tested := []
 model.running = true
 for id in room.buildings.keys():
  game.ui.close_context()
  await advance(.23)
  await world_click(room.tile_position(id) + Vector2(0, -12))
  await advance(.23)
  check(game.ui.context_open and game.selected_tile == id, "actual rendered slot %d opens matching inspector" % id)
  tested.append(game.selected_tile)
 model.running = false
 await capture("full16-low-inspected-720")
 check(checksum == _state_digest(model), "selection does not mutate gameplay state")
 print("DENSE_SELECTS=", tested)
 await _finish()

func fail(message: String):
 push_error(message)
 quit(2)
