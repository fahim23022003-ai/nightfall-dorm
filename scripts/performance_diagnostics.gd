extends CanvasLayer
## Local diagnostics only. F10 enables the overlay and records until toggled off.
var game
var display: Label
var frames: Array[float] = []
var stage_frames: Dictionary = {}
var last_frame := 0
var refresh := 0.0
var running := false

func _ready() -> void:
 layer = 100
 set_process(false)
 if "--performance-diagnostic" in OS.get_cmdline_user_args():
  start.call_deferred()

func _input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F10:
  if running:
   stop()
  else:
   start()
  get_viewport().set_input_as_handled()

func start() -> void:
 if not is_instance_valid(display):
  display = Label.new()
  display.position = Vector2(12, 94)
  display.add_theme_color_override("font_outline_color", Color.BLACK)
  display.add_theme_constant_override("outline_size", 7)
  display.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(display)
 display.show()
 frames.clear()
 stage_frames.clear()
 last_frame = Time.get_ticks_usec()
 refresh = 0.0
 running = true
 set_process(true)

func _process(delta: float) -> void:
 var now := Time.get_ticks_usec()
 var duration := (now-last_frame)/1000.0
 frames.append(duration)
 var stage: String = game.mode if game.mode != "menu" else game.ui.current_screen
 if game.mode == "match":
  var room = game.model.player()
  stage = "map" if game.full_map else "room_rush" if room == null else "room_%d_machines" % room.buildings.size()
 if not stage_frames.has(stage): stage_frames[stage] = []
 stage_frames[stage].append(duration)
 last_frame = now
 refresh += delta
 if refresh >= .25:
  refresh = 0.0
  var snapshot := metrics()
  display.text = "%d FPS | %.1f ms | %d draws\n%s | %s | %d machines | %d shots\n%.1f MiB render memory | F10 saves local report" % [
   snapshot.fps, frames.back(), snapshot.draw_calls, snapshot.preset, snapshot.map_family,
   snapshot.visible_buildings, snapshot.projectiles, snapshot.video_bytes/1048576.0]
 if frames.size() >= 36000:
  stop()

func metrics() -> Dictionary:
 var visible := 0
 if game.mode == "match":
  var area: Rect2 = game.presentation.visible_world_rect(game, 0)
  for room in game.model.rooms:
   for id in room.buildings:
    if area.has_point(game.MAP_OFFSET + room.tile_position(id)):
     visible += 1
 return {
  "adaptive_trim":game.phase20_trim,
  "adaptive_changes":game.phase20_trim_transitions,
  "fps": Engine.get_frames_per_second(),
  "draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
  "process_ms": Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,
  "video_bytes": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
  "static_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
  "nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
  "resolution": [get_viewport().size.x, get_viewport().size.y],
  "preset": game.profile.settings.get("graphics_quality", "medium"),
  "map_family": game.model.map_data.get("family", game.model.map_id),
  "visible_buildings": visible,
  "projectiles": game.model.projectiles.size()
 }

func stop() -> void:
 running = false
 set_process(false)
 display.hide()
 if frames.is_empty():
  return
 var report := metrics()
 report.merge(timing(frames))
 report["stages"] = {}
 for stage in stage_frames:
  report.stages[stage] = timing(stage_frames[stage])
 report["os"] = OS.get_name()
 report["cpu"] = OS.get_processor_name()
 report["gpu"] = RenderingServer.get_video_adapter_name()
 report["driver"] = RenderingServer.get_video_adapter_api_version()
 var path := "user://nightfall-performance-%d.json" % int(Time.get_unix_time_from_system())
 var file := FileAccess.open(path, FileAccess.WRITE)
 if file != null:
  file.store_string(JSON.stringify(report, "  ")+"\n")
  file.close()
  OS.shell_show_in_file_manager(ProjectSettings.globalize_path(path))

func timing(samples: Array) -> Dictionary:
 samples.sort()
 return {"frame_samples": samples.size(), "median_ms": samples[samples.size()/2],
  "p95_ms": samples[ceili(samples.size()*.95)-1], "p99_ms": samples[ceili(samples.size()*.99)-1]}
