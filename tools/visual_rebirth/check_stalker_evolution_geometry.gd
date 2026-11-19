extends SceneTree
## Validate the evolved oblique assets at their actual texture and grid sizes.

const Preview := preload("res://scripts/stalker_visual_prototype.gd")

func _initialize() -> void:
 var preview := Preview.new()
 var checked := 0
 var minimum := INF
 var failures := 0
 var texture_digests := {}
 for level in range(2, 11):
  preview._set_geometry_level(level)
  var texture := preview.texture_for(level)
  if texture == null or texture.get_size() != Preview.EVOLVED_SIZE:
   push_error("Stalker L%d has no texture at the agreed canvas size." % level)
   failures += 1
   continue
  var image := texture.get_image()
  if image.is_compressed() and image.decompress() != OK:
   push_error("Could not decompress Stalker L%d." % level)
   failures += 1
   continue
  var hash := HashingContext.new()
  hash.start(HashingContext.HASH_SHA256)
  hash.update(image.get_data())
  texture_digests[hash.finish().hex_encode()] = true
  for name in Preview.SOCKET_LAYOUT:
   var location := Vector2i((preview._evolved_socket(name) * Preview.EVOLVED_SIZE).round())
   if not _near_visible_pixel(image, location):
    push_error("Stalker L%d %s misses the visible cutout." % [level, name])
    failures += 1
  for pose in Preview.POSES + ["evolve"]:
   for frame in range(Preview.STEPS + 1):
    var mesh := preview._mesh(pose, float(frame) / Preview.STEPS)
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
  push_error("Evolved Stalker geometry is missing or contains a folded triangle.")
  failures += 1
 if texture_digests.size() != 9:
  push_error("Expected nine distinct evolved Stalker textures.")
  failures += 1
 print("Stalker L2–L10: %d unique textures, %d pose triangles, %.3f px² minimum area, %d failures." % [
  texture_digests.size(), checked, minimum, failures])
 quit(1 if failures else 0)

func _near_visible_pixel(image: Image, location: Vector2i) -> bool:
 var area := Rect2i(Vector2i.ZERO, image.get_size())
 for y in range(location.y - 6, location.y + 7):
  for x in range(location.x - 6, location.x + 7):
   if area.has_point(Vector2i(x, y)) and image.get_pixel(x, y).a >= .35:
    return true
 return false
