extends "res://tools/capture_visual_rebirth.gd"
## Actual production draw path, inspection view at native display scale.

const FONT := preload("res://assets/fonts/Interface.ttf")

class Gallery extends Node2D:
 var profile

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() < 2 or not args[0].is_absolute_path():
  push_error("Pass an absolute evidence directory followed by visual IDs after --")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 output = destination.get_base_dir() + "/"
 phase = destination.get_file()
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()
 var view := CanvasLayer.new()
 view.layer = 100
 root.add_child(view)
 var sheet := Gallery.new()
 sheet.profile = game.profile
 view.add_child(sheet)
 for kind in args.slice(1):
  check(kind in game.presentation.building_visual.KINDS, "registered visual ID " + kind)
  var painter := _draw_sheet.bind(sheet, kind)
  sheet.draw.connect(painter)
  sheet.queue_redraw()
  await capture(kind + "-adjacent-levels-720")
  sheet.draw.disconnect(painter)
 view.queue_free()
 await _finish()

func _draw_sheet(sheet: Gallery, kind: String):
 sheet.draw_rect(Rect2(0, 0, 1280, 720), Color("17212b"))
 var title: String = Catalog.BUILDINGS[kind].name if Catalog.BUILDINGS.has(kind) else kind.capitalize()
 sheet.draw_string(FONT, Vector2(26, 42), title + " · Godot production renderer", HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("f0debc"))
 sheet.draw_string(FONT, Vector2(26, 68), "Identical scale and bearing • production art inspection", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("beccd3"))
 var branches := [""]
 branches.append_array(StrategyCatalog.branches(kind))
 var visual = game.presentation.building_visual
 for level in range(1, 11):
  var x := 249 + (level - 1) * 105
  sheet.draw_string(FONT, Vector2(x - 15, 117), "L%d" % level, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e9d5af"))
  for row in range(branches.size()):
   var branch: String = branches[row]
   var y := 236 + row * 170
   if level == 1:
    var label: String = StrategyCatalog.BRANCHES[branch].name if not branch.is_empty() else "Unbranched"
    sheet.draw_string(FONT, Vector2(24, y - 31), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e9d5af"))
   var origin := Vector2(x, y)
   sheet.draw_rect(Rect2(origin - Vector2(48, 98), Vector2(96, 133)), Color("283542"))
   if row > 0 and level < 5:
    sheet.draw_string(FONT, origin + Vector2(-4, -11), "–", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("b2b7bc"))
   else:
    visual.draw(sheet, game.presentation, kind, level, origin, branch, 0.0, Vector2(1, -.35), 0.0)
