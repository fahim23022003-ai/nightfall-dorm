extends SceneTree
## Validate imported intermediate textures. With a destination, draw a Godot plate.

const LEVELS := [2, 3, 5, 6, 8, 9]
const HEADINGS := [Vector2(-0.707, 0.707), Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2.RIGHT]
const VIEWS := ["oblique", "front", "left", "back", "right"]
const RENDERER := preload("res://scripts/phantom_witch_visual.gd")

class Plate extends Node2D:
 var visual = RENDERER.new()

 func _draw() -> void:
  var font := ThemeDB.fallback_font
  draw_rect(Rect2(0, 0, 1280, 720), Color("151b25"))
  draw_string(font, Vector2(30, 29), "PHANTOM WITCH  /  INTERMEDIATE LEVELS", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("e6e4ef"))
  for column in VIEWS.size():
   var x := float(257 + column * 217)
   draw_string(font, Vector2(x - 22, 56), VIEWS[column].capitalize(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("b9b4ca"))
   for row in LEVELS.size():
    var floor := Vector2(x, float(168 + row * 108))
    if column == 0:
     draw_string(font, Vector2(61, floor.y - 40), "Level %d" % LEVELS[row], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("e6e4ef"))
    visual.draw(self, floor, Color.WHITE, LEVELS[row], HEADINGS[column], "hover", 0.0, true)

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var visual = RENDERER.new()
 var errors := 0
 var verified := 0
 for level in LEVELS:
  var mirrored := Image.new()
  var observed_hashes: Dictionary = {}
  for index in VIEWS.size():
   var expected: String = VIEWS[index]
   var actual: String = visual.facing(HEADINGS[index])
   var texture: Texture2D = visual.texture_for(level, actual)
   if actual != expected or texture == null or texture.get_size() != Vector2(328, 264):
    push_error("Level %d failed texture routing for %s" % [level, expected])
    errors += 1
    continue
   var raster := texture.get_image()
   if raster.is_compressed():
    raster.decompress()
   var raster_hash := hash(raster.get_data())
   if observed_hashes.has(raster_hash):
    push_error("Level %d contains a repeated %s raster" % [level, expected])
    errors += 1
   observed_hashes[raster_hash] = true
   if expected == "left":
    mirrored = raster.duplicate()
    mirrored.flip_x()
   elif expected == "right" and not mirrored.is_empty() and raster.get_data() == mirrored.get_data():
    push_error("Level %d right profile duplicates its mirrored left" % level)
    errors += 1
   verified += 1
 var arguments := OS.get_cmdline_user_args()
 if errors == 0 and not arguments.is_empty():
  root.size = Vector2i(1280, 720)
  root.add_child(Plate.new())
  await process_frame
  await RenderingServer.frame_post_draw
  if root.get_texture().get_image().save_png(arguments[0]) != OK:
   errors += 1
 print("WITCH_INTERMEDIATE_TEXTURES=%d LEVELS=%d FAILURES=%d" % [verified, LEVELS.size(), errors])
 quit(0 if errors == 0 else 1)
