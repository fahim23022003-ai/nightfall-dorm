extends Node2D

var model: MatchModel
var ui: GameInterface
var mode = "menu"
var selected_tile = 0
var profile: PlayerProfile
var audio_system
var match_id=0
var last_progression: Dictionary={}
var selected_difficulty="standard"
var last_hunter_level=1
var level_warning_time=0.0
var sound_volume: float:
 get: return float(profile.settings.effects) if profile!=null else 0.65
 set(value):
  if profile!=null:
   profile.settings.effects=clampf(value,0,1)
   if is_instance_valid(audio_system): audio_system.set_mix(profile.settings)
var income_clock = 0.0
var floating: Array = []
var last_attacks = 0
var last_shots = 0
var camera: Camera2D
var presentation = preload("res://scripts/dorm_presentation.gd").new()
const MAP_OFFSET = Vector2(145,40)
var full_map=false
var zoom_factor=1.0
var pending_build=""
var preview_position=Vector2.ZERO
var placement_on_tile=true
var tutorial_enabled=true
var danger_time=0.0
var last_income: Dictionary={}
var camera_target=Vector2.ZERO
var closing=false
var mobile_mode=OS.get_name()=="Android" or "--mobile-test" in OS.get_cmdline_user_args()
var mobile_layout
var mobile_ui
var touch
var in_background=false
var ui_clock=0.0

func _ready():
 var window = get_window()
 window.content_scale_size = Vector2i(1280,720)
 window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND if mobile_mode else Window.CONTENT_SCALE_ASPECT_KEEP
 if not mobile_mode: window.min_size = Vector2i(960,540)
 get_tree().auto_accept_quit=false
 var save_path=OS.get_environment("NIGHTFALL_PROFILE_PATH")
 profile=PlayerProfile.new(save_path if save_path!="" else "user://profile.json")
 profile.load_profile()
 tutorial_enabled=profile.settings.tutorial
 if not mobile_mode and profile.settings.fullscreen: window.mode=Window.MODE_FULLSCREEN
 if mobile_mode:
  Engine.max_fps=30 if profile.settings.get("battery_saver",false) else 60
  get_tree().quit_on_go_back=false
 audio_system=preload("res://scripts/audio_director.gd").new()
 audio_system.mobile_profile=mobile_mode
 add_child(audio_system)
 audio_system.set_mix(profile.settings)
 model = MatchModel.new()
 model.feedback.connect(func(text):
  if is_instance_valid(ui.message): ui.message.text = text)
 mobile_layout=preload("res://scripts/mobile_layout.gd").new(self)
 mobile_ui=preload("res://scripts/mobile_interface.gd").new(self)
 touch=preload("res://scripts/touch_controls.gd").new(self)
 add_child(touch)
 ui = GameInterface.new(self)
 add_child(ui)
 camera = Camera2D.new()
 camera.position = Vector2(640,360)
 camera.position_smoothing_enabled = false
 add_child(camera)
 get_viewport().size_changed.connect(func(): mobile_layout.apply())
 mobile_layout.apply()

func start_match(difficulty: String=""):
 if difficulty!="": selected_difficulty=difficulty
 var entry=profile.begin_match(selected_difficulty)
 match_id=int(entry.get("id",0))
 model.reset(int(Time.get_ticks_msec()))
 model.configure_match(selected_difficulty,RankCatalog.bonuses(entry.get("equipped",[])))
 audio_system.reset_match(model)
 audio_event("match_start")
 last_progression={}
 last_hunter_level=1
 level_warning_time=0
 if is_instance_valid(touch): touch.reset()
 selected_tile = 0
 full_map=false
 zoom_factor=1
 pending_build=""
 danger_time=0
 last_income.clear()
 floating.clear()
 income_clock = 0
 presentation.reset()
 last_attacks = 0
 last_shots = 0
 mode = "match"
 ui.show_match()
 focus_camera(true)
 queue_redraw()

func return_menu():
 mode = "menu"
 pending_build=""
 if is_instance_valid(touch): touch.reset()
 camera.position=get_viewport_rect().size/2 if mobile_mode else Vector2(640,360)
 camera.zoom=Vector2.ONE
 camera.force_update_scroll()
 ui.show_menu()
 queue_redraw()

func toggle_pause():
 if in_background: return
 if is_instance_valid(touch): touch.reset()
 model.running = not model.running
 if not model.running: pending_build=""
 ui.show_pause(not model.running)

func _process(delta: float):
 if in_background: return
 level_warning_time=maxf(0,level_warning_time-delta)
 danger_time=maxf(0,danger_time-delta)
 if mode == "match":
  var direction = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
  if mobile_mode: direction=touch.movement(delta)
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
     var earned=room.income_total-last_income.get(room.index,0.0)
     if earned>0:
      floating.append({"position":room.bed_position(),"life":1.0,"text":"+%.0f" % earned,"kind":"coin"})
     last_income[room.index]=room.income_total
  for f in floating:
   f.position.y -= delta*24
   f.life -= delta
  floating = floating.filter(func(f): return f.life>0)
  if model.hunter.attacks > last_attacks:
   last_attacks = model.hunter.attacks
   if model.hunter.target==model.player_room: danger_time=0.65
  if model.hunter.level>last_hunter_level:
   last_hunter_level=model.hunter.level
   level_warning_time=3.0
  focus_camera(false,delta)
  ui_clock+=delta
  if not mobile_mode or ui_clock>=0.05:
   ui_clock=0
   ui.update_match()
  if model.result != "":
   last_progression=profile.settle_match(match_id,model)
   mode = "result"
   if not last_progression.is_empty() and last_progression.promoted:
    audio_event("rank")
    audio_event("reward")
   ui.show_result()
 audio_system.update_state(delta,model,mode)
 presentation.update(delta,model)
 queue_redraw()

func _unhandled_input(event):
 if mode!="match" or in_background: return
 if mobile_mode and event is InputEventMouse: return
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_E and model.running: model.interact()
  elif event.keycode==KEY_M: toggle_map()
  elif event.keycode==KEY_G: toggle_guide()
  elif event.keycode==KEY_R and model.running: ui.purchase(model.repair_door())
  elif event.keycode==KEY_ESCAPE:
   if pending_build!="": cancel_placement()
   elif ui.context_open: ui.close_context()
   else: toggle_pause()
 if event is InputEventMouseButton and event.pressed:
  if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
   zoom_factor=clampf(zoom_factor+(0.1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -0.1),0.75,1.2)
  elif event.button_index==MOUSE_BUTTON_LEFT and model.player()!=null:
   var point=get_global_mouse_position()-MAP_OFFSET
   var found=false
   for tile in range(6):
    if Rect2(model.player().tile_position(tile)-Vector2(27,27),Vector2(54,54)).has_point(point):
     selected_tile=tile
     placement_on_tile=true
     preview_position=model.player().tile_position(tile)
     found=true
     if pending_build!="": ui.open_confirmation()
     else: ui.open_context()
     break
   if not found and pending_build!="":
    placement_on_tile=false
    preview_position=point
    ui.open_confirmation()
 if event is InputEventMouseMotion and pending_build!="" and model.player()!=null:
  var point=get_global_mouse_position()-MAP_OFFSET
  placement_on_tile=false
  preview_position=point
  for tile in range(6):
   if Rect2(model.player().tile_position(tile)-Vector2(27,27),Vector2(54,54)).has_point(point):
    selected_tile=tile
    placement_on_tile=true
    preview_position=model.player().tile_position(tile)
    break

func begin_placement(kind: String):
 if model.player()==null: return
 pending_build=kind
 placement_on_tile=true
 preview_position=model.player().tile_position(selected_tile)
 ui.open_confirmation()

func placement_reason() -> String:
 if not placement_on_tile: return "Choose a floor pad inside your room."
 return ui.action_reason("build:"+pending_build) if pending_build!="" else "Choose a building."

func confirm_placement():
 if pending_build=="" or placement_reason()!="": return false
 var success=model.buy(pending_build,selected_tile)
 if success:
  pending_build=""
  ui.close_context()
 ui.purchase(success)
 return success

func cancel_placement():
 pending_build=""
 ui.close_context()

func toggle_map():
 cancel_placement()
 full_map=not full_map

func focus_camera(snap: bool=false,delta: float=0.016):
 if mode!="match": return
 var goal=model.player_position+MAP_OFFSET
 var zoom=1.45
 if full_map:
  goal=Vector2(640,450)
  zoom=0.8
 elif model.player()!=null:
  var room=model.player()
  goal=room.center()+MAP_OFFSET+Vector2(0,45 if room.index<3 else -45)
  zoom=1.8*zoom_factor
  if model.hunter.target==room.index and model.hunter.state==HunterState.State.ATTACK:
   goal=(room.center().lerp(model.hunter.position,0.38))+MAP_OFFSET
   zoom=1.65*zoom_factor
 if mobile_mode and not full_map:
  var desired=Vector2(470 if ui.context_open and model.player()!=null and model.player().sleeping else 640,340)
  goal+=(get_viewport_rect().size/2-mobile_layout.screen_point(desired))/zoom
 camera_target=goal
 var weight=1.0 if snap else 1.0-exp(-delta*7)
 camera.position=camera.position.lerp(goal,weight)
 camera.zoom=camera.zoom.lerp(Vector2(zoom,zoom),weight)
 camera.offset=Vector2(sin(presentation.clock*63),cos(presentation.clock*51))*danger_time*1.5
 camera.force_update_scroll()

func world_to_screen(point: Vector2) -> Vector2:
 return get_viewport().get_canvas_transform()*(point+MAP_OFFSET)

func _draw():
 presentation.render(self)

func audio_event(name: String):
 if is_instance_valid(audio_system): audio_system.event(name)

func change_setting(key: String,value):
 profile.update_setting(key,value)
 audio_system.set_mix(profile.settings)
 if key=="battery_saver" and mobile_mode: Engine.max_fps=30 if value else 60
 if key=="fullscreen" and not mobile_mode: get_window().mode=Window.MODE_FULLSCREEN if value else Window.MODE_WINDOWED
 if key=="tutorial": tutorial_enabled=value

func toggle_guide():
 change_setting("tutorial",not tutorial_enabled)

func request_quit():
 if closing: return
 closing=true
 profile.save_profile()
 audio_system.shutdown()
 # Let the audio thread release looping playback before normal window/menu exit.
 await get_tree().create_timer(0.5).timeout
 get_tree().quit()

func _notification(what):
 if mobile_mode and is_instance_valid(audio_system):
  if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]: suspend_mobile()
  elif what in [NOTIFICATION_APPLICATION_RESUMED,NOTIFICATION_APPLICATION_FOCUS_IN]: resume_mobile()
  elif what==NOTIFICATION_WM_GO_BACK_REQUEST: mobile_back()
 if what==NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(audio_system): request_quit()

func suspend_mobile():
 if in_background: return
 in_background=true
 profile.save_profile()
 if is_instance_valid(touch): touch.reset()
 pending_build=""
 if mode=="match":
  model.running=false
  ui.show_pause(true)
 audio_system.set_suspended(true)

func resume_mobile():
 if not in_background: return
 in_background=false
 audio_system.set_suspended(false)
 # Keep an interrupted match paused until the user explicitly presses Resume.

func mobile_back():
 if mode=="match":
  if pending_build!="": cancel_placement()
  elif ui.context_open: ui.close_context()
  else: toggle_pause()
 else: return_menu()

func handle_touch_tap(screen: Vector2):
 if mode!="match" or not model.running or in_background: return
 var point=get_viewport().get_canvas_transform().affine_inverse()*screen-MAP_OFFSET
 var room=model.player()
 if room!=null and room.sleeping:
  var found=false
  for tile in range(6):
   if Rect2(room.tile_position(tile)-Vector2(27,27),Vector2(54,54)).has_point(point):
    selected_tile=tile
    preview_position=room.tile_position(tile)
    placement_on_tile=true
    found=true
    if pending_build!="": ui.open_confirmation()
    else: ui.open_context()
    break
  if found: return
  if pending_build!="":
   placement_on_tile=false
   preview_position=point
   ui.open_confirmation()
  elif point.distance_to(room.door_position())<45: ui.open_room_panel("door")
  elif point.distance_to(room.bed_position())<45: ui.open_room_panel("bed")
 elif room!=null and point.distance_to(room.bed_position())<65:
  touch.navigate_bed()
 elif room!=null and point.distance_to(room.door_position())<40:
  ui.open_room_panel("door")
 else:
  for candidate in model.rooms:
   if candidate.owner<0 and (candidate.bounds().has_point(point) or point.distance_to(candidate.door_position())<40):
    touch.navigate_room(candidate)
    ui.touch_notice("Walking to the room. Then tap its bed to sleep.")
    return
