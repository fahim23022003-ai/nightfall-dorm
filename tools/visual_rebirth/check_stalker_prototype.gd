extends SceneTree
## Check the sampled Stalker poses and all linear blends between them.

const StalkerPreview = preload("res://scripts/stalker_visual_prototype.gd")

func _initialize() -> void:
 var preview = StalkerPreview.new()
 var poses: Array[PackedVector2Array] = []
 var indices := PackedInt32Array()
 for pose in StalkerPreview.POSES:
  for frame in range(StalkerPreview.STEPS + 1):
   var mesh := preview._mesh(pose, float(frame) / StalkerPreview.STEPS)
   var arrays := mesh.surface_get_arrays(0)
   poses.append(arrays[Mesh.ARRAY_VERTEX])
   indices = arrays[Mesh.ARRAY_INDEX]

 var pose_minimum := INF
 var blend_minimum := INF
 var pose_triangles := 0
 var blend_triangles := 0
 for from_index in range(poses.size()):
  var from_pose := poses[from_index]
  for index in range(0, indices.size(), 3):
   var a := indices[index]
   var b := indices[index + 1]
   var c := indices[index + 2]
   var from_edge_b := from_pose[b] - from_pose[a]
   var from_edge_c := from_pose[c] - from_pose[a]
   var initial_area := from_edge_b.cross(from_edge_c)
   pose_minimum = minf(pose_minimum, initial_area * .5)
   pose_triangles += 1
   for to_index in range(from_index + 1, poses.size()):
    var to_pose := poses[to_index]
    var delta_b := to_pose[b] - to_pose[a] - from_edge_b
    var delta_c := to_pose[c] - to_pose[a] - from_edge_c
    var curvature := delta_b.cross(delta_c)
    if curvature > 0.0:
     var derivative := delta_b.cross(from_edge_c) + from_edge_b.cross(delta_c)
     var weight := -derivative / (2.0 * curvature)
     if weight > 0.0 and weight < 1.0:
      var interior_area := initial_area + weight * (derivative + weight * curvature)
      blend_minimum = minf(blend_minimum, interior_area * .5)
    blend_triangles += 1

 blend_minimum = minf(blend_minimum, pose_minimum)
 print("Stalker prototype: %d pose triangles and %d blend ranges checked." % [pose_triangles, blend_triangles])
 print("Minimum signed areas: %.3f px² across poses and %.3f px² through blends." % [pose_minimum, blend_minimum])
 if pose_triangles == 0 or blend_triangles == 0 or minf(pose_minimum, blend_minimum) <= 0.0:
  push_error("The Stalker prototype mesh is empty or has a folded triangle.")
  quit(1)
  return
 quit(0)
