extends Node2D

var model: MatchModel
var ui: GameInterface
var mode = "menu"
var watched_room=-1
var selected_tile = 0
var profile: PlayerProfile
var audio_system
var match_id=0
var last_progression: Dictionary={}
var selected_difficulty="standard"
var campaign_mode=false
var _stage_request=""
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
var horror = preload("res://scripts/horror_feedback.gd").new()
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
var tutorial_active=false
var onboarding
var onboarding_layer
var temporary_loadout
func item_wallet():return temporary_loadout if temporary_loadout!=null and model.run_kind in ["practice","challenge"] else profile
func start_endless(map: String="abandoned_dorm",difficulty: String="standard",seed_value: int=17) -> bool:
 var entry=profile.begin_endless(map,difficulty,seed_value)
 if entry.is_empty():return false
 var next=MatchModel.new()
 if not next.configure_endless(map,difficulty,seed_value,int(entry.id),RankCatalog.bonuses(entry.equipped)):return false
 match_id=int(entry.id);_adopt_session(next)
 return true
func resume_endless() -> bool:
 var next=profile.resume_endless()
 if next==null:return false
 match_id=int(profile.active_match.id);_adopt_session(next)
 ui.replay_ui.intermission_saved=true;ui.replay_ui.show_intermission()
 return true
func continue_endless(choice: String) -> bool:
 if model.run_kind!="endless" or model.endless==null:return false
 if not profile.checkpoint_endless(model):ui.replay_ui.intermission_saved=false;ui.replay_ui.show_intermission();return false
 if not model.continue_wave(choice):return false
 watched_room=-1
 presentation.new_encounter(model);horror.reset();audio_system.new_encounter(model)
 for room in model.rooms:
  if not room.alive:audio_system.death_rooms[room.index]=true
  if room.door_hp<=0:audio_system.laughed_rooms[room.index]=true
 last_hunter_level=1;level_warning_time=0;danger_time=0;last_attacks=0;last_shots=model.shots;income_clock=0;floating.clear();last_income.clear()
 for room in model.rooms:last_income[room.index]=room.income_total
 ui.replay_ui.intermission_saved=false;ui.show_match();focus_camera(true);audio_event("match_start")
 return true
func end_endless_here() -> bool:
 last_progression=profile.end_endless_here(model)
 if last_progression.is_empty():ui.replay_ui.intermission_saved=false;ui.replay_ui.show_intermission();return false
 model.endless.phase="finished";model.result="retired";mode="result";ui.replay_ui.show_session_result();audio_event("reward")
 return true
func start_challenge(code: String) -> bool:
 var parsed=ChallengeCode.decode(code)
 if not parsed.ok:ui.replay_ui.notice=parsed.error;return false
 var next=MatchModel.new()
 if not ChallengeCode.configure(next,parsed.config):return false
 var selected=["shield","repair"] if int(parsed.config.gear)==0 else ["overdrive","frost"]
 var wallet=TemporaryLoadout.new("challenge",selected);wallet.inventory={}
 for id in selected:wallet.inventory[id]=2
 match_id=1;_adopt_session(next,wallet)
 return true
func start_practice(archetype="crusher",boss=false,selected: Array=["shield","repair"],map="abandoned_dorm") -> bool:
 var next=MatchModel.new();var wallet=PracticeRoom.configure(next,archetype,boss,selected,map)
 match_id=1;_adopt_session(next,wallet);selected_tile=model.practice_tile
 return true
func reset_practice():
 if model.run_kind!="practice":return
 start_practice(ui.replay_ui.practice_archetype,ui.replay_ui.practice_boss,ui.replay_ui.practice_items,ui.replay_ui.practice_map)
func _adopt_session(next,wallet=null):
 watched_room=-1
 model=next;temporary_loadout=wallet;tutorial_active=false;campaign_mode=false;last_progression={};pending_build="";selected_tile=0
 ui.replay_ui.preparing=false
 model.feedback.connect(func(value):ui.feedback_text=value;ui.feedback_until=presentation.clock+2)
 last_hunter_level=1;level_warning_time=0;danger_time=0;last_attacks=0;last_shots=0;income_clock=0;ui_clock=0
 floating.clear();last_income.clear();full_map=false;zoom_factor=1
 for room in model.rooms:last_income[room.index]=room.income_total
 audio_system.reset_match(model);presentation.reset();horror.reset();mode="match"
 if model.run_kind=="endless" and model.endless.phase=="intermission":
  for room in model.rooms:
   presentation.previous_life[room.index]=room.alive;presentation.previous_sleep[room.index]=room.sleeping
   if not room.alive:presentation.death_ages[room.index]=10;presentation.seen_deaths[room.index]=true
 item_wallet().bind_items(model,match_id)
 ui.show_match();focus_camera(true);audio_event("match_start")

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
 if not mobile_mode:
  onboarding_layer=CanvasLayer.new();onboarding_layer.layer=90;add_child(onboarding_layer)
  onboarding=preload("res://scripts/onboarding.gd").new(self);onboarding_layer.add_child(onboarding)

func start_tutorial(replay=false):
 watched_room=-1
 if mobile_mode:return false
 tutorial_active=true
 temporary_loadout=null
 model=MatchModel.new();model.tutorial_mode=true;model.reset(17);model.tutorial_mode=true;model.configure_stage("stage_1");model.preparation=10000;model.bot_claimed=5
 model.feedback.connect(func(value):ui.feedback_text=value;ui.feedback_until=presentation.clock+2)
 match_id=0;campaign_mode=false;last_progression={};pending_build="";tutorial_enabled=false
 last_hunter_level=1;level_warning_time=0;danger_time=0;last_attacks=0;last_shots=0
 floating.clear();last_income.clear();income_clock=0;ui_clock=0
 audio_system.reset_match(model);presentation.reset();horror.reset();mode="match";full_map=false;zoom_factor=1
 ui.show_match();focus_camera(true);onboarding.begin_tutorial()
 return true

func enter_game():
 if not profile.tutorial_completed:start_tutorial();return
 ui.campaign.show_stages()

func start_stage(id: String, difficulty: String="standard") -> bool:
 if not RankCatalog.DIFFICULTIES.has(difficulty) or not profile.stage_unlocked(id): return false
 if not profile.select_stage(id) or not profile.select_difficulty(difficulty): return false
 campaign_mode=true
 _stage_request=id
 return start_match(difficulty)

func start_match(difficulty: String="") -> bool:
 watched_room=-1
 if not mobile_mode and not profile.tutorial_completed:
  start_tutorial();return false
 if tutorial_active:return false
 if profile.active_match.get("run_kind","")=="endless":
  mode="menu";camera.position=Vector2(640,360);camera.zoom=Vector2.ONE;camera.force_update_scroll()
  ui.replay_ui.notice="Your Endless run is still active. Resume its saved checkpoint, start an explicitly NEW run, or Forfeit it before starting a campaign match."
  ui.replay_ui.show_endless()
  return false
 temporary_loadout=null
 model.tutorial_mode=false
 if not profile.pending_spins.is_empty():
  ui.items_ui.spin()
  return false
 if difficulty!="": selected_difficulty=difficulty
 var requested=_stage_request
 _stage_request=""
 campaign_mode=requested!=""
 var entry=profile.begin_match(selected_difficulty,requested,true)
 if entry.is_empty(): return false
 match_id=int(entry.get("id",0))
 model.reset(int(Time.get_ticks_msec()))
 model.configure_match(selected_difficulty,RankCatalog.bonuses(entry.get("equipped",[])))
 if requested!="": model.configure_stage(requested)
 model.configure_strategy(int(profile.statistics.matches),entry.archetype,entry.contract,match_id)
 profile.apply_stage_bonus(model,entry)
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
 horror.reset()
 last_attacks = 0
 last_shots = 0
 mode = "match"
 profile.bind_items(model,match_id)
 ui.show_match()
 focus_camera(true)
 queue_redraw()
 return true

func activate_item(slot: int,target: int=-1) -> bool:
 if mode!="match" or in_background or tutorial_active: return false
 var wallet=item_wallet()
 var selected=wallet.active_match.get("items",[])
 if slot>=0 and slot<selected.size() and selected[slot]=="rescue" and target<0:
  ui.items_ui.choose_teammate(slot)
  return false
 var ok=wallet.activate_item(slot,model,match_id,target)
 if ok:
  ui.feedback_text=""
  ui.feedback_until=0
 if not ok:
  audio_event("failure")
  ui.feedback_text=wallet.item_error if wallet.item_error!="" else "Item unavailable for this match."
  ui.feedback_until=presentation.clock+2.0
 return ok

func return_menu():
 watched_room=-1
 if not mobile_mode and not profile.tutorial_completed:
  if onboarding!=null and onboarding.phase not in ["cinematic","title","tutorial"]:start_tutorial()
  return
 tutorial_active=false
 temporary_loadout=null
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
 if ui.shop!=null:ui.shop.update()
 level_warning_time=maxf(0,level_warning_time-delta)
 danger_time=maxf(0,danger_time-delta)
 if mode == "match":
  var direction = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
  if mobile_mode: direction=touch.movement(delta)
  if model.running:
   model.move_player(direction if watched_room<0 else Vector2.ZERO,delta)
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
  horror.update(delta,model)
  if model.run_kind=="endless" and model.endless!=null and model.endless.phase=="intermission" and ui.current_screen!="intermission" and not ui.replay_ui.preparing:
   ui.replay_ui.intermission_saved=profile.checkpoint_endless(model)
   ui.replay_ui.show_intermission();audio_event("reward")
  if model.result != "" and not tutorial_active:
   if model.run_kind=="campaign":last_progression=profile.settle_match(match_id,model)
   elif model.run_kind=="endless":last_progression=profile.settle_endless(model)
   elif model.run_kind=="challenge":profile.record_challenge(model)
   return_to_my_room()
   mode = "result"
   cancel_placement()
   if not last_progression.is_empty():
    if not last_progression.get("achievements",[]).is_empty():audio_event("achievement_unlocked")
    if last_progression.get("campaign",{}).get("cleared",false) and selected_difficulty in ["hard","hell"]:audio_event("difficult_stage")
   if not last_progression.is_empty() and last_progression.get("promoted",false):
    audio_event("mythic_promotion" if last_progression.new_rank==6 else "rank")
    if last_progression.new_rank==6:audio_event("mythic_perk")
    audio_event("reward")
   if model.run_kind=="campaign":ui.show_result()
   else:ui.replay_ui.show_session_result()
 if mode not in ["match","result"] or tutorial_active:audio_system.set_tension("quiet",0)
 audio_system.update_state(delta,model,mode)
 if ui.items_ui!=null: ui.items_ui.update(delta)
 presentation.update(delta,model)
 if mode in ["match","result"] and not tutorial_active:audio_system.set_tension(presentation.identity.tension,presentation.identity.intensity)
 if mode=="match" and not tutorial_active:audio_system.update_environment(presentation.environment)
 if is_instance_valid(ui.horror_layer): ui.horror_layer.queue_redraw()
 queue_redraw()

# A double-click is one intent. Consume its second press AND release before
# Controls see it, so a newly opened panel cannot receive the trailing click.
var suppress_double_click_release=false

func _input(event):
 if (mode!="match" and ui.current_screen!="shop") or not event is InputEventMouseButton: return
 if event.button_index!=MOUSE_BUTTON_LEFT: return
 if event.pressed:
  suppress_double_click_release=event.double_click
  if event.double_click: get_viewport().set_input_as_handled()
 elif suppress_double_click_release:
  suppress_double_click_release=false
  get_viewport().set_input_as_handled()

func _unhandled_input(event):
 if mode!="match" or in_background: return
 if model.run_kind=="endless" and model.endless!=null and model.endless.phase=="intermission" and not ui.replay_ui.preparing:return
 if mobile_mode and event is InputEventMouse: return
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_HOME:return_to_my_room()
  elif event.keycode==KEY_T and not tutorial_active:ui.teammates.toggle_panel()
  elif event.keycode in [KEY_PAGEUP,KEY_PAGEDOWN] and not tutorial_active:cycle_spectator(-1 if event.keycode==KEY_PAGEUP else 1)
  elif event.keycode in [KEY_1,KEY_2] and model.running: activate_item(0 if event.keycode==KEY_1 else 1)
  elif event.keycode==KEY_E and model.running and watched_room<0: model.interact()
  elif event.keycode==KEY_M: toggle_map()
  elif event.keycode==KEY_G: toggle_guide()
  elif event.keycode==KEY_R and model.running: ui.purchase(model.repair_door())
  elif event.keycode==KEY_ESCAPE:
   if pending_build!="": cancel_placement()
   elif watched_room>=0:return_to_my_room()
   elif ui.context_open: ui.close_context()
   elif ui.replay_ui.preparing:ui.replay_ui.show_intermission()
   else: toggle_pause()
 if event is InputEventMouseButton and event.pressed:
  if watched_room>=0:return
  if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
   zoom_factor=clampf(zoom_factor+(0.1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -0.1),0.75,1.2)
  elif event.button_index==MOUSE_BUTTON_LEFT and model.player()!=null:
   var point=get_viewport().get_canvas_transform().affine_inverse()*event.position-MAP_OFFSET
   var found=false
   for tile in range(model.player().tile_count()):
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
 # Placement is selected by floor-pad clicks, not mouse motion. Keep the
 # preview anchored while the pointer travels to Confirm or Cancel.

func begin_placement(kind: String):
 if watched_room>=0:return
 if mode!="match" or in_background or not model._can_purchase(): return
 if not Catalog.BUILDINGS.has(kind) or selected_tile<0 or selected_tile>=model.player().tile_count(): return
 if model.player().buildings.has(selected_tile) or not model.player().sleeping: return
 pending_build=kind
 placement_on_tile=true
 preview_position=model.player().tile_position(selected_tile)
 ui.open_confirmation()

func placement_reason() -> String:
 if not placement_on_tile: return "Choose a floor pad inside your room."
 if not Catalog.BUILDINGS.has(pending_build): return "Choose a building."
 return ui.action_reason("build:"+pending_build)

func confirm_placement():
 if watched_room>=0:return
 if pending_build=="" or placement_reason()!="": return false
 var success=model.buy(pending_build,selected_tile)
 if success:
  pending_build=""
  ui.close_context()
 ui.purchase(success)
 return success

func cancel_placement():
 pending_build=""
 placement_on_tile=false
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
 elif model.player()!=null or watched_room>=0:
  var room=model.rooms[watched_room] if watched_room>=0 else model.player()
  goal=room.center()+MAP_OFFSET+Vector2(0,45 if room.index<3 else -45)
  zoom=1.8*zoom_factor
  if model.hunter.target==room.index and model.hunter.state==HunterState.State.ATTACK:
   goal=(room.center().lerp(model.hunter.position,0.38))+MAP_OFFSET
   zoom=1.65*zoom_factor
 if model.map_id!="legacy":
  if full_map:
   var extent=model.map_bounds().grow(35)
   zoom=minf(1220.0/extent.size.x,500.0/extent.size.y)
   goal=extent.get_center()+MAP_OFFSET+Vector2(0,10)/zoom
  elif model.player()!=null or watched_room>=0:
   var observed=model.rooms[watched_room] if watched_room>=0 else model.player()
   var extent=observed.bounds().grow(35)
   var available=Vector2(820,490) if ui.context_open else Vector2(1160,490)
   zoom=minf(available.x/extent.size.x,available.y/extent.size.y)*zoom_factor
   var desired=Vector2(452,348) if ui.context_open else Vector2(640,348)
   goal=extent.get_center()+MAP_OFFSET+(get_viewport_rect().size/2-desired)/zoom
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
 if model.run_kind=="endless" and model.endless!=null and model.endless.phase=="intermission" and not profile.checkpoint_endless(model):
  closing=false;ui.replay_ui.intermission_saved=false;ui.replay_ui.show_intermission();return
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
  for tile in range(model.player().tile_count()):
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

func retry_settlement():
 if model.run_kind=="endless":last_progression=profile.settle_endless(model);ui.replay_ui.show_session_result()
 else:last_progression=profile.settle_match(match_id,model);ui.show_result()

func spectate_room(index: int) -> bool:
 if mode!="match" or tutorial_active or model.result!="" or index<0 or index>=model.rooms.size() or model.rooms[index].owner<=0:return false
 cancel_placement();ui.close_context();watched_room=index;full_map=false;zoom_factor=1
 focus_camera();ui.teammates.update()
 return true
func return_to_my_room():
 watched_room=-1;full_map=false;zoom_factor=1
 if mode=="match":focus_camera(true)
 if ui!=null and ui.teammates!=null:ui.teammates.update()
func cycle_spectator(direction: int):
 var valid=[]
 for r in model.rooms:
  if r.owner>0:valid.append(r.index)
 if valid.is_empty():return
 var current=valid.find(watched_room)
 spectate_room(valid[posmod(current+direction,valid.size())])
