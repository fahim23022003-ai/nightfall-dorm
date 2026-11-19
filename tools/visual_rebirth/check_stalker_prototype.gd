extends SceneTree
## Verify orientation of all triangles in the Stalker prototype pose cache.

const StalkerPreview = preload("res://scripts/stalker_visual_prototype.gd")

func _initialize() -> void:
 var preview = StalkerPreview.new()
 var minimum_area := INF
 var checked := 0
 for pose in StalkerPreview.POSES:
  for frame in range(StalkerPreview.STEPS + 1):
   var mesh := preview._mesh(pose, float(frame) / StalkerPreview.STEPS)
   var arrays := mesh.surface_get_arrays(0)
   var vertices: PackedVector2Array = arrays[Mesh.ARRAY_VERTEX]
   var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
   for triangle in range(0, indices.size(), 3):
    var a := vertices[indices[triangle]]
    var b := vertices[indices[triangle + 1]]
    var c := vertices[indices[triangle + 2]]
    minimum_area = minf(minimum_area, (b - a).cross(c - a) * .5)
    checked += 1
 print("Stalker prototype: %d triangles checked, minimum signed area %.3f px²." % [checked, minimum_area])
 if checked == 0 or minimum_area <= 0:
  push_error("The Stalker prototype mesh is empty or has a folded triangle.")
  quit(1)
  return
 quit(0)
