extends "res://tools/capture_visual_rebirth.gd"

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
 game.ui.show_settings()
 await _render_frame()
 var picker := root.find_child("graphics_quality",true,false) as OptionButton
 check(picker != null and picker.item_count == 3,"actual Settings quality picker renders three choices")
 if picker != null:
  for index in [1,0]:
   var quality: String = "medium" if index == 1 else "low"
   picker.select(index)
   picker.item_selected.emit(index)
   await _render_frame()
   var chosen := picker.get_item_text(picker.selected)
   check(game.profile.settings.get("graphics_quality") == quality,"real option callback persists selected preset")
   check(chosen.begins_with("STANDARD") if index == 1 else chosen.begins_with("LOW"),"actual Settings selection uses correct preview label")
   print("SETTINGS_PICKER ",quality," ",chosen)
   await capture("settings-" + ("standard" if index == 1 else "low") + "-720")
 await _finish()
