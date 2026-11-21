extends "res://tools/phase18/measure_close_quarters.gd"
## Equal workload on the original construction rules and the same V3 map.

var _first_frame_ms := 0.0

func _render_frame():
 var started := Time.get_ticks_usec()
 await super._render_frame()
 if _first_frame_ms == 0.0:
  _first_frame_ms = (Time.get_ticks_usec()-started)/1000.0

func _finish():
 var path := OS.get_cmdline_user_args()[0].path_join("measure.json")
 if FileAccess.file_exists(path):
  var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
  var native_map = game.presentation.map_presentation
  var cached_bytes := 0
  if "close_passages" in native_map:
   cached_bytes = int(native_map.close_passages.texture_bytes())
  data["memory"] = {
   "godot_static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),
   "godot_video_monitor_bytes":int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
   "corridor_texture_payload_bytes":cached_bytes,
  }
  data["first_view_frame_ms"] = _first_frame_ms
  data["camera_scale_end"] = game.camera.zoom.x
  var receipt := FileAccess.open(path,FileAccess.WRITE)
  if receipt != null:
   receipt.store_string(JSON.stringify(data,"  ",true,true)+"\n")
   receipt.close()
 await super._finish()
