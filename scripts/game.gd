extends Node2D

var model: MatchModel
var ui: GameInterface
var mode = "menu"
var selected_tile = 0
var sound_volume = 0.25
var audio: AudioStreamPlayer
var income_clock = 0.0
var floating: Array = []
var last_attacks = 0
var last_shots = 0
var camera: Camera2D
var presentation = preload("res://scripts/dorm_presentation.gd").new()
const MAP_OFFSET = Vector2(145,40)

func _ready():
 var window = get_window()
 window.content_scale_size = Vector2i(1280,900)
 window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
 window.min_size = Vector2i(960,675)
 model = MatchModel.new()
 model.feedback.connect(func(text):
  if is_instance_valid(ui.message): ui.message.text = text)
 ui = GameInterface.new(self)
 add_child(ui)
 audio = AudioStreamPlayer.new()
 add_child(audio)
 camera = Camera2D.new()
 camera.position = Vector2(640,450)
 camera.position_smoothing_enabled = true
 add_child(camera)

func start_match():
 model.reset(int(Time.get_ticks_msec()))
 selected_tile = 0
 floating.clear()
 income_clock = 0
 presentation.previous.clear()
 presentation.death_age = 0
 last_attacks = 0
 last_shots = 0
 mode = "match"
 ui.show_match()
 queue_redraw()

func return_menu():
 mode = "menu"
 ui.show_menu()
 queue_redraw()

func toggle_pause():
 model.running = not model.running
 ui.show_pause(not model.running)

func _process(delta: float):
 presentation.update(delta,model)
 if mode == "match":
  var direction = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
  if model.running:
   model.move_player(direction,delta)
  # Fixed simulation substeps avoid attack tunneling during slow rendered frames.
  var remaining = minf(delta,0.25)
  while remaining > 0:
   var step = minf(remaining,0.05)
   model.tick(step)
   remaining -= step
  if model.running:
   income_clock += delta
  if income_clock >= 1:
   income_clock = 0
   for room in model.rooms:
    if room.income_rate()>0:
     floating.append({"position":room.bed_position(),"life":1.0,"text":"+%.0f" % room.income_rate()})
  for f in floating:
   f.position.y -= delta*24
   f.life -= delta
  floating = floating.filter(func(f): return f.life>0)
  if model.hunter.attacks > last_attacks:
   play_tone(85)
   last_attacks = model.hunter.attacks
  if model.shots > last_shots:
   play_tone(440)
   last_shots = model.shots
  ui.update_match()
  if model.result != "":
   mode = "result"
   ui.show_result()
 queue_redraw()

func _unhandled_input(event):
 if mode != "match":
  return
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_E and model.running:
   model.interact()
  elif event.keycode == KEY_ESCAPE:
   if ui.context_open: ui.close_context()
   else: toggle_pause()
 if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and model.player()!=null:
  var pos = get_global_mouse_position()-MAP_OFFSET
  for tile in range(6):
   if Rect2(model.player().tile_position(tile)-Vector2(27,27),Vector2(54,54)).has_point(pos):
    selected_tile = tile
    ui.open_context()

func world_to_screen(point: Vector2) -> Vector2:
 return point+MAP_OFFSET

func _draw():
 presentation.render(self)

func play_tone(frequency: float):
 if sound_volume <= 0:
  return
 var stream = AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 var bytes = PackedByteArray()
 bytes.resize(2205*2)
 for i in range(2205):
  var sample = int(sin(float(i)*frequency*TAU/22050.0)*(1.0-float(i)/2205.0)*3500*sound_volume)
  bytes.encode_s16(i*2,sample)
 stream.data = bytes
 audio.stream = stream
 audio.play()
