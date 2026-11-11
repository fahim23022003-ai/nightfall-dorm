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

func _ready():
 var window = get_window()
 window.content_scale_size = Vector2i(1280,800)
 window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
 window.min_size = Vector2i(960,600)
 model = MatchModel.new()
 model.feedback.connect(func(text):
  if is_instance_valid(ui.message): ui.message.text = text)
 ui = GameInterface.new(self)
 add_child(ui)
 audio = AudioStreamPlayer.new()
 add_child(audio)
 camera = Camera2D.new()
 camera.position = Vector2(640,400)
 camera.position_smoothing_enabled = true
 add_child(camera)

func start_match():
 model.reset(int(Time.get_ticks_msec()))
 selected_tile = 0
 floating.clear()
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

func _process(delta: float):
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
   toggle_pause()
 if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and model.player()!=null:
  var pos = get_global_mouse_position()
  for tile in range(6):
   if Rect2(model.player().tile_position(tile)-Vector2(27,27),Vector2(54,54)).has_point(pos):
    selected_tile = tile

func text_at(text: String, pos: Vector2, color: Color = Color.WHITE, size: int = 16):
 draw_string(ThemeDB.fallback_font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _draw():
 draw_rect(Rect2(0,0,1280,800),Color("10151f"))
 if mode == "menu":
  for x in range(0,1280,80):
   draw_line(Vector2(x,0),Vector2(x,800),Color("182231"),1)
  draw_circle(Vector2(640,390),270,Color(0.15,0.25,0.3,0.2))
  return
 draw_rect(Rect2(30,330,910,160),Color("293142"))
 for x in range(45,940,38):
  draw_line(Vector2(x,335),Vector2(x,485),Color("333e50"),1)
 text_at("NORTH WING",Vector2(380,350),Color("8e9bad"),13)
 text_at("SOUTH WING",Vector2(380,478),Color("8e9bad"),13)
 for room in model.rooms:
  draw_room(room)
 if model.player()==null or not model.player().sleeping:
  draw_resident(model.player_position,Color("75dbea"))
 if model.hunter.state != HunterState.State.DORMANT:
  var p = model.hunter.position
  draw_circle(p+Vector2(0,8),23,Color(0.8,0.2,0.35,0.15))
  var color = Color.WHITE if model.hunter.hit_flash>0 else Color("e5687c")
  draw_colored_polygon(PackedVector2Array([p+Vector2(0,-23),p+Vector2(18,17),p+Vector2(4,10),p+Vector2(-5,20),p+Vector2(-18,14)]),color)
  draw_circle(p+Vector2(-5,-3),3,Color("10151f"))
  draw_circle(p+Vector2(5,-3),3,Color("10151f"))
  text_at(HunterState.State.keys()[model.hunter.state],Vector2(clampf(p.x+26,35,880),p.y-8),Color("f2a1ae"),12)
 for f in floating:
  text_at(f.text,f.position,Color(0.95,0.8,0.3,f.life),17)
 draw_line(Vector2(950,95),Vector2(950,780),Color("61718c"),2)
 text_at("WASD / arrows: move    E: interact    Click floor: select tile",Vector2(35,775),Color("a9b8ca"),16)

func draw_room(room: RoomState):
 var r = room.bounds()
 var col = Color("273a44") if room.index==model.player_room else Color("222b39")
 if not room.alive:
  col = Color("33232d")
 draw_rect(r,col)
 draw_rect(r,Color("6ba6ae") if room.index==model.player_room else Color("506078"),false,5)
 text_at("%02d  %s" % [room.index+1,"VACANT" if room.owner<0 else ("YOUR ROOM" if room.owner==0 else room.profile.to_upper())],r.position+Vector2(10,22),Color("b6c8d8"),14)
 var bed = room.bed_position()
 draw_rect(Rect2(bed-Vector2(21,30),Vector2(42,60)),Color("4c8a99"))
 draw_rect(Rect2(bed-Vector2(17,26),Vector2(34,15)),Color("d0e5dc"))
 text_at("BED %d" % (room.bed_level+1),bed+Vector2(-24,48),Color("91ccce"),12)
 if room.sleeping:
  draw_resident(bed,Color("75dbea") if room.owner==0 else Color("e2bd8d"))
 elif room.owner>0 and room.alive:
  draw_resident(room.resident_position,Color("e2bd8d"))
 elif not room.alive:
  text_at("LOST",bed+Vector2(-20,0),Color("e5687c"))
 for tile in range(6):
  var p = room.tile_position(tile)
  draw_rect(Rect2(p-Vector2(26,26),Vector2(52,52)),Color("354553"),false,1)
  if room.index==model.player_room and tile==selected_tile:
   draw_rect(Rect2(p-Vector2(28,28),Vector2(56,56)),Color("e8d784"),false,2)
  if room.buildings.has(tile):
   var b = room.buildings[tile]
   var data = Catalog.BUILDINGS[b.kind]
   draw_rect(Rect2(p-Vector2(17,17),Vector2(34,34)),data.color.darkened(0.45))
   if b.kind=="turret" or b.kind=="heavy":
    draw_circle(p,12,data.color)
    var aim = (model.hunter.position-p).normalized()
    draw_line(p,p+aim*23,data.color,6)
    if b.flash>0:
     draw_line(p,model.hunter.position,data.color,2)
    if room.index==model.player_room and tile==selected_tile:
     draw_arc(p,data.range,0,TAU,64,Color(data.color,0.13),1)
   else:
    text_at({"generator":"E","repair":"+","economy":"G","enhancer":"X"}[b.kind],p+Vector2(-7,6),data.color,22)
   text_at("L%d" % b.level,p+Vector2(10,22),Color.WHITE,11)
  else:
   text_at(str(tile+1),p+Vector2(-4,5),Color("677d8f"),13)
 var door = room.door_position()
 var door_color = Color("f29b79") if room.closed else Color("79a789")
 if room.door_hp<=0:
  door_color = Color("722f42")
 if room.damage_flash>0:
  door_color = Color.WHITE
 draw_rect(Rect2(door-Vector2(28,7),Vector2(56,14)),door_color)
 if room.owner>=0:
  draw_rect(Rect2(door+Vector2(-32,12),Vector2(64,5)),Color("16202b"))
  draw_rect(Rect2(door+Vector2(-32,12),Vector2(64*room.door_hp/room.max_hp(),5)),Color("82d99c"))
  text_at("DOOR %d" % (room.door_level+1),door+Vector2(-25,-13),Color("bcc8d3"),11)

func draw_resident(pos: Vector2, col: Color):
 draw_circle(pos+Vector2(0,5),12,col.darkened(0.35))
 draw_circle(pos+Vector2(0,-8),8,col)
 draw_line(pos+Vector2(-5,13),pos+Vector2(-5,19),col,4)
 draw_line(pos+Vector2(5,13),pos+Vector2(5,19),col,4)

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
