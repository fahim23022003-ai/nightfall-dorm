extends SceneTree
## Compare the retained dynamic surface with a rebuilt reference in real Godot.

const StalkerPreview := preload("res://scripts/stalker_visual_prototype.gd")
const VIEW_SIZE := Vector2i(168, 168)
const FLOOR := Vector2(86, 139)
const SAMPLES := [
 ["idle", .12, 0.0, false],
 ["idle", .19, .017, false],
 ["tell", .37, .033, false],
 ["tell", .56, .087, false],
 ["strike", .97, .091, false],
 ["strike", .92, .118, false],
 ["strike", .92, .118, false],
 ["strike", .89, .135, false],
 ["strike", .81, .157, false],
 ["hit", .43, .173, true],
 ["recover", .76, .190, true],
 ["vanish", .6, .329, true],
]

class Subject extends Node2D:
 var mesh: ArrayMesh
 var texture: Texture2D

 func _draw() -> void:
  draw_mesh(mesh, texture, Transform2D(.031, StalkerPreview.DISPLAY_SCALE, 0.0, FLOOR))

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var optimized := StalkerPreview.new()
 var texture: Texture2D = load(StalkerPreview.TEXTURE_PATH)
 var optimized_view := _viewport()
 var reference_view := _viewport()
 var optimized_subject := Subject.new()
 var reference_subject := Subject.new()
 optimized_subject.texture = texture
 reference_subject.texture = texture
 optimized_view.add_child(optimized_subject)
 reference_view.add_child(reference_subject)

 var failures := 0
 var actual_rid := RID()
 var last_state := ""
 var started := 0.0
 var outgoing := PackedVector2Array()
 var reference_vertices := PackedVector2Array()
 for sample in SAMPLES:
  var state: String = sample[0]
  var progress: float = sample[1]
  var clock: float = sample[2]
  var reduced: bool = sample[3]
  var frame := roundi(progress * StalkerPreview.STEPS)
  if last_state != state:
   outgoing = PackedVector2Array() if reduced else reference_vertices
   started = clock
   last_state = state
  var duration := StalkerPreview.STRIKE_TRANSITION_TIME if state == "strike" else StalkerPreview.TRANSITION_TIME
  var weight := smoothstep(0.0, duration, clampf(clock - started, 0.0, duration))
  reference_vertices = optimized._pose_vertices(state, float(frame) / StalkerPreview.STEPS)
  if outgoing.is_empty() or weight >= 1.0:
   outgoing = PackedVector2Array()
  else:
   for i in range(reference_vertices.size()):
    reference_vertices[i] = outgoing[i].lerp(reference_vertices[i], weight)

  optimized._update_pose(state, progress, clock, reduced)
  optimized.transform = Transform2D(.031, StalkerPreview.DISPLAY_SCALE, 0.0, FLOOR)
  if not actual_rid.is_valid():
   actual_rid = optimized.current_mesh.get_rid()
  if actual_rid != optimized.current_mesh.get_rid() or optimized.current_vertices != reference_vertices:
   push_error("Vertex stream or retained mesh changed unexpectedly in %s at %s." % [state, clock])
   failures += 1
  for name in StalkerPreview.SOCKETS:
   var expected_socket := _socket(reference_vertices, StalkerPreview.SOCKETS[name], optimized.transform)
   if not optimized.socket_position(name).is_equal_approx(expected_socket):
    push_error("Socket %s drifted in %s at %s." % [name, state, clock])
    failures += 1
  optimized_subject.mesh = optimized.current_mesh
  reference_subject.mesh = optimized._surface(optimized._surface_arrays(reference_vertices))
  optimized_subject.queue_redraw()
  reference_subject.queue_redraw()
  await process_frame
  await RenderingServer.frame_post_draw
  var observed := optimized_view.get_texture().get_image()
  var reference := reference_view.get_texture().get_image()
  if observed.is_empty() or reference.get_used_rect().size.x < 30 or observed.get_data() != reference.get_data():
   push_error("Retained and rebuilt meshes differ in %s at %s." % [state, clock])
   failures += 1

 optimized.reset_pose()
 optimized._update_pose("idle", 0.0, 0.0, false)
 if optimized.current_mesh.get_rid() != actual_rid or optimized.current_vertices != optimized._pose_vertices("idle", 0.0):
  push_error("Reset changed the mesh identity or retained obsolete positions.")
  failures += 1
 print("Stalker stream: %d rendered comparisons, %d socket checks, %d failures." % [SAMPLES.size(), SAMPLES.size() * StalkerPreview.SOCKETS.size(), failures])
 quit(1 if failures else 0)

func _viewport() -> SubViewport:
 var view := SubViewport.new()
 view.size = VIEW_SIZE
 view.transparent_bg = true
 view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(view)
 return view

func _socket(vertices: PackedVector2Array, uv: Vector2, transform: Transform2D) -> Vector2:
 var grid := StalkerPreview.GRID
 var coords := uv * Vector2(grid)
 var origin := coords.floor()
 var blend := coords - origin
 var top_left := int(origin.y) * (grid.x + 1) + int(origin.x)
 var top_right := top_left + 1
 var bottom_left := top_left + grid.x + 1
 var bottom_right := bottom_left + 1
 var point := Vector2.ZERO
 if blend.x + blend.y <= 1.0:
  point = vertices[top_left] * (1.0 - blend.x - blend.y) + vertices[top_right] * blend.x + vertices[bottom_left] * blend.y
 else:
  point = vertices[bottom_right] * (blend.x + blend.y - 1.0) + vertices[top_right] * (1.0 - blend.y) + vertices[bottom_left] * (1.0 - blend.x)
 return transform * point
