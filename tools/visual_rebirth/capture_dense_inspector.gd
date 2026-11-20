extends "res://tools/capture_visual_rebirth.gd"
## Open the same real L10 inspector in each prepared 16-slot room.

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
 root.size = Vector2i(1280,720)
 await setup_game()
 game.onboarding.close_welcome()
 var model = _dense_fixture()
 for index in range(8):
  game.presentation.update(.125,model)
  await _render_frame()
 var room = model.player()
 var requested: int = room.buildings.keys().back()
 var recorded_camera: Vector2 = game.camera.position
 var digest := _state_digest(model)
 model.running = true
 await world_click(room.tile_position(requested)+Vector2(0,-12))
 await advance(.38)
 check(game.ui.context_open and game.selected_tile == requested, "actual paid L10 building opens inspector")
 check(game.camera.position.distance_to(recorded_camera) < 0.01, "opening the inspector does not recenter the room")
 check(_state_digest(model) == digest, "selecting the building leaves model state unchanged")
 var bounds: Rect2 = room.bounds()
 var screen_start: Vector2 = game.world_to_screen(bounds.position)
 var screen_end: Vector2 = game.world_to_screen(bounds.end)
 var room_rect := Rect2(screen_start,screen_end-screen_start).abs()
 var inspector: Rect2 = game.ui.context_box.get_global_rect()
 print("INSPECTOR_RECT=",inspector," ROOM_RECT=",room_rect," OVERLAP=",inspector.intersects(room_rect)," SELECTED=",game.selected_tile)
 await capture("inspector-720")
 await _finish()
