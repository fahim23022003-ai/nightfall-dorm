extends SceneTree

const LEVELS := [2, 3, 5, 6, 8, 9]
const HEADINGS := [Vector2(-0.707, 0.707), Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2.RIGHT]
const VIEWS := ["Oblique", "Front", "Left", "Rear", "Right"]

class Plate extends Node2D:
 var rigs: Array[RefCounted] = []

 func _draw() -> void:
  rigs.clear()
  var font := ThemeDB.fallback_font
  draw_rect(Rect2(0, 0, 1280, 720), Color("151b25"))
  draw_string(font, Vector2(30, 29), "RAVAGER  /  INTERMEDIATE LEVELS", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("e6e4ef"))
  for column in VIEWS.size():
   var x := float(257 + column * 217)
   draw_string(font, Vector2(x - 22, 53), VIEWS[column], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("b9b4ca"))
  for row in LEVELS.size():
   var y := float(160 + row * 104)
   draw_string(font, Vector2(61, y - 37), "Level %d" % LEVELS[row], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("e6e4ef"))
   for column in VIEWS.size():
    var floor := Vector2(float(257 + column * 217), y)
    var fitted := preload("res://scripts/ravager_visual.gd").new()
    rigs.append(fitted)
    fitted.draw(self, floor, Color.WHITE, "idle", 0.0, 0.0, 0.0, true, LEVELS[row], HEADINGS[column], true)

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var arguments := OS.get_cmdline_user_args()
 if arguments.size() != 1 or OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") != "1":
  push_error("Set NIGHTFALL_VISUAL_REBIRTH=1 and pass one screenshot path after --")
  quit(2)
  return
 root.size = Vector2i(1280, 720)
 root.add_child(Plate.new())
 await process_frame
 await RenderingServer.frame_post_draw
 var result := root.get_texture().get_image().save_png(arguments[0])
 quit(0 if result == OK else 1)
