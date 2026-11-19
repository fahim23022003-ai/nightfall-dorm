extends SceneTree
## Validate the oblique asset sequence at its actual texture and grid sizes.

const Preview := preload("res://scripts/stalker_visual_prototype.gd")
const CrusherPreview := preload("res://scripts/crusher_visual.gd")
const ElectricPreview := preload("res://scripts/electric_ghost_visual.gd")
const RavagerPreview := preload("res://scripts/ravager_visual.gd")
const StormPreview := preload("res://scripts/storm_wraith_visual.gd")
const RENDERERS = {
 "stalker": Preview,
 "crusher": CrusherPreview,
 "electric": ElectricPreview,
 "ravager": RavagerPreview,
 "storm": StormPreview,
}

func _initialize() -> void:
 var args := OS.get_cmdline_user_args()
 var key := args[0] if not args.is_empty() else "stalker"
 var renderer: Script = RENDERERS[key]
 var label: String = StrategyCatalog.ARCHETYPES[key].name
 var first := 2 if key == "stalker" else 1
 var preview = renderer.new()
 var poses: Array = Preview.POSES + ["evolve"]
 if key != "stalker":poses.append("guard")
 if key == "ravager":poses.append("dash")
 var checked := 0
 var minimum := INF
 var failures := 0
 var texture_digests := {}
 for level in range(first, 11):
  preview._set_geometry_level(level)
  var texture: Texture2D = preview.texture_for(level)
  var size: Vector2 = preview._draw_size()
  if texture == null or texture.get_size() != size:
   push_error("%s L%d has no texture at the agreed canvas size." % [label, level])
   failures += 1
   continue
  var image := texture.get_image()
  if image.is_compressed() and image.decompress() != OK:
   push_error("Could not decompress %s L%d." % [label, level])
   failures += 1
   continue
  var hash := HashingContext.new()
  hash.start(HashingContext.HASH_SHA256)
  hash.update(image.get_data())
  texture_digests[hash.finish().hex_encode()] = true
  for name in Preview.SOCKET_LAYOUT:
   var location := Vector2i((preview._socket_uv(name) * size).round())
   if not _near_visible_pixel(image, location):
    push_error("%s L%d %s misses the visible cutout." % [label, level, name])
    failures += 1
  for pose in poses:
   for frame in range(Preview.STEPS + 1):
    var mesh: ArrayMesh = preview._mesh(pose, float(frame) / Preview.STEPS)
    var arrays := mesh.surface_get_arrays(0)
    var vertices: PackedVector2Array = arrays[Mesh.ARRAY_VERTEX]
    var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
    for i in range(0, indices.size(), 3):
     var a := vertices[indices[i]]
     var b := vertices[indices[i + 1]]
     var c := vertices[indices[i + 2]]
     minimum = minf(minimum, (b - a).cross(c - a) * .5)
     checked += 1
 if checked == 0 or minimum <= 0.0:
  push_error("%s geometry is missing or contains a folded triangle." % label)
  failures += 1
 if texture_digests.size() != 11 - first:
  push_error("Expected %d distinct %s textures." % [11 - first, label])
  failures += 1
 print("%s L%d–L10: %d unique textures, %d pose triangles, %.3f px² minimum area, %d failures." % [
  label, first, texture_digests.size(), checked, minimum, failures])
 quit(1 if failures else 0)

func _near_visible_pixel(image: Image, location: Vector2i) -> bool:
 var area := Rect2i(Vector2i.ZERO, image.get_size())
 for y in range(location.y - 6, location.y + 7):
  for x in range(location.x - 6, location.x + 7):
   if area.has_point(Vector2i(x, y)) and image.get_pixel(x, y).a >= .35:
    return true
 return false
