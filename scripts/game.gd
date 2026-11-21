extends Node2D

var model: MatchModel
var ui: GameInterface
var mode = "menu"
var watched_room=-1
var hunter_spectating := false
var selected_tile = 0
var profile: PlayerProfile
var audio_system
var match_id=0
var last_progression: Dictionary={}
var selected_difficulty="standard"
var campaign_mode=false
var story_preview_enabled:=OS.get_environment("NIGHTFALL_LIVING_NIGHTMARE")=="1"
var survivor_preview_enabled:=OS.get_environment("NIGHTFALL_SURVIVOR_REBIRTH")=="1" or (story_preview_enabled and OS.get_environment("NIGHTFALL_SURVIVOR_REBIRTH")=="")
var story_lobby: Control
var story_lobby_request: Dictionary={}
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
var overview_zoom := 1.0
var overview_pan := Vector2.ZERO
var overview_room := -1
var overview_opening: Dictionary={}
var pending_build=""
var preview_position=Vector2.ZERO
var placement_on_tile=true
var tutorial_enabled=true
var danger_time=0.0
var last_income: Dictionary={}
var camera_target=Vector2.ZERO
var rebirth_framing := CinematicQuality.rebirth_preview()
var closing=false
var mobile_mode=OS.get_name()=="Android" or "--mobile-test" in OS.get_cmdline_user_args()
var mobile_layout
var mobile_ui
var touch
var construction
var in_background=false
var ui_clock=0.0
var new_balance_version=BalanceRules.CURRENT
var guidance=PlayerGuidance.new()
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
 next.configure_balance(new_balance_version)
 if survivor_preview_enabled and not next.begin_room_rush(int(entry.id)):
  profile.forfeit_endless()
  ui.replay_ui.notice="This layout could not provide a shared route to all rooms. Choose another seed."
  return false
 match_id=int(entry.id);_adopt_session(next);bind_run_choices()
 ui.replay_ui.remember_macro_layout(model)
 return true
func resume_endless() -> bool:
 var next=profile.resume_endless()
 if next==null:return false
 match_id=int(profile.active_match.id);_adopt_session(next);bind_run_choices()
 ui.replay_ui.intermission_saved=true;ui.replay_ui.show_intermission()
 return true
func choose_night_omen(id: String) -> bool:
 if model.run_kind!="endless" or model.endless==null:return false
 var old=model.endless.omen.snapshot()
 if not model.endless.omen.select(model,id):return false
 var saved=profile.checkpoint_endless(model)
 if not saved:model.endless.omen.restore(old)
 ui.replay_ui.intermission_saved=saved;ui.replay_ui.show_intermission()
 audio_event("button_click" if saved else "failure")
 return saved
func continue_endless(choice: String) -> bool:
 if model.run_kind!="endless" or model.endless==null or model.endless.phase!="intermission":return false
 if not profile.checkpoint_endless(model):ui.replay_ui.intermission_saved=false;ui.replay_ui.show_intermission();return false
 if not model.continue_wave(choice):return false
 if model.endless.omen.active!="":audio_event("eerie")
 hunter_spectating=false
 watched_room=-1
 presentation.new_encounter(model);horror.reset();audio_system.new_encounter(model)
 for room in model.rooms:
  if not room.alive:audio_system.death_rooms[room.index]=true
  if room.door_hp<=0:audio_system.laughed_rooms[room.index]=true
 last_hunter_level=1;level_warning_time=0;danger_time=0;last_attacks=0;last_shots=model.shots;income_clock=0;floating.clear();last_income.clear()
 for room in model.rooms:last_income[room.index]=room.income_total
 ui.replay_ui.intermission_saved=false;ui.show_match();focus_camera(true);audio_event("match_start")
 return true
func bind_run_choices():
 model.choices.payment=func(id,value):
  var before=profile.active_match.get("temporary_used",{}).duplicate(true)
  var journal=before.duplicate(true);journal[id]=value;profile.active_match.temporary_used=journal
  if not profile.save_profile():profile.active_match.temporary_used=before;return false
  return true
 model.choices.apply_journal(profile.active_match.get("temporary_used",{}))
 model.choices.apply(model)
func run_transaction(kind: String,id: String) -> bool:
 if model.balance_version!=2 or model.run_kind!="endless" or model.endless.phase!="intermission":return false
 var c=model.choices;var before=c.snapshot();var r=model.player();var wallet=[r.gold,r.electricity];var flow=r.ledger.snapshot();var trace=r.ledger.records.duplicate(true)
 var ok=c.choose(model,id) if kind=="choose" else c.buy(model,id) if kind=="buy" else c.decline(model) if kind=="decline" else false
 if ok:ok=profile.checkpoint_endless(model)
 if not ok:
  c.restore(before);r.gold=wallet[0];r.electricity=wallet[1];r.ledger.restore(flow);r.ledger.records=trace;c.apply(model)
 audio_event("button_click" if ok else "failure");RunChoiceInterface.show(ui);return ok
func use_run_stock(id: String) -> bool:
 var ok=model.choices.activate(model,id);audio_event("button_click" if ok else "failure");return ok
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
 var next=MatchModel.new();var wallet=PracticeRoom.configure(next,archetype,boss,selected,map,new_balance_version)
 match_id=1;_adopt_session(next,wallet);selected_tile=model.practice_tile
 return true
func reset_practice():
 if model.run_kind!="practice":return
 start_practice(ui.replay_ui.practice_archetype,ui.replay_ui.practice_boss,ui.replay_ui.practice_items,ui.replay_ui.practice_map)
func _adopt_session(next,wallet=null):
 phase20_free_camera=false
 reset_phase20_adaptation()
 if construction!=null:construction.reset()
 hunter_spectating=false
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
 construction=ConstructionControls.new(self)
 var performance := preload("res://scripts/performance_diagnostics.gd").new()
 performance.game = self
 add_child(performance)
 var window = get_window()
 window.content_scale_size = Vector2i(1280,720)
 window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND if mobile_mode else Window.CONTENT_SCALE_ASPECT_KEEP
 if not mobile_mode: window.min_size = Vector2i(960,540)
 get_tree().auto_accept_quit=false
 var save_path=OS.get_environment("NIGHTFALL_PROFILE_PATH")
 profile=PlayerProfile.new(save_path if save_path!="" else "user://profile.json")
 var fresh_performance_profile := OS.get_environment("NIGHTFALL_PERFORMANCE_PREVIEW")=="1" and not FileAccess.file_exists(profile.path) and not FileAccess.file_exists(profile.path+".bak")
 profile.load_profile(story_preview_enabled)
 if fresh_performance_profile: profile.update_setting("graphics_quality","low")
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
 phase20_free_camera=false
 reset_phase20_adaptation()
 hunter_spectating=false
 watched_room=-1
 if mobile_mode:return false
 construction.reset()
 tutorial_active=true
 temporary_loadout=null
 model=MatchModel.new();model.tutorial_mode=true;model.reset(17);model.tutorial_mode=true;model.configure_stage("stage_1");model.configure_balance(new_balance_version);model.preparation=10000;model.bot_claimed=5
 model.feedback.connect(func(value):ui.feedback_text=value;ui.feedback_until=presentation.clock+2)
 match_id=0;campaign_mode=false;last_progression={};pending_build="";tutorial_enabled=false
 last_hunter_level=1;level_warning_time=0;danger_time=0;last_attacks=0;last_shots=0
 floating.clear();last_income.clear();income_clock=0;ui_clock=0
 audio_system.reset_match(model);presentation.reset();horror.reset();mode="match";full_map=false;zoom_factor=1
 ui.show_match();focus_camera(true);onboarding.begin_tutorial(replay)
 return true

func enter_game():
 if not profile.tutorial_completed:start_tutorial();return
 if story_preview_enabled:ui.campaign.show_story()
 else:ui.campaign.show_stages()

func start_story(difficulty: String) -> bool:
 if not story_preview_enabled or not difficulty in RankCatalog.DIFFICULTIES or not profile.enable_story():return false
 if profile.selected_difficulty!=difficulty and not profile.select_difficulty(difficulty):return false
 return start_match(difficulty,StoryProgress.position(profile.story,difficulty))

func open_story_lobby(difficulty: String) -> bool:
 if not survivor_preview_enabled or mobile_mode:
  return start_story(difficulty)
 if is_instance_valid(story_lobby) or mode!="menu" or ui.current_screen!="story_prepare":
  return false
 if not story_preview_enabled or profile.read_only or difficulty!=profile.selected_difficulty:
  return false
 if not profile.pending_spins.is_empty() or profile.active_match.get("run_kind","")=="endless":
  return start_story(difficulty)
 var track:=StoryProgress.summary(profile.story,difficulty)
 if track.finished:
  return false
 var mission:=StoryCatalog.mission(track.position)
 if mission.is_empty():
  return false
 var seed:=StoryProgress.seed_for(profile.story,track.position)
 var lobby_script:=load("res://scripts/nightmare_lobby.gd") as Script
 if lobby_script==null:
  return false
 var lobby=lobby_script.new()
 story_lobby=lobby
 story_lobby_request={"level":track.position,"difficulty":difficulty,
  "items":profile.item_loadout.duplicate(),"perks":profile.equipped.duplicate()}
 ui.clear()
 ui.current_screen="story_lobby"
 mode="story_lobby"
 lobby.start_requested.connect(func(): _launch_story_from_lobby.call_deferred(lobby))
 lobby.cancel_requested.connect(func(): _cancel_story_lobby(lobby))
 lobby.cue_requested.connect(func(cue: String): audio_system.lobby_cue(cue))
 ui.panel.add_child(lobby)
 lobby.configure(mission,difficulty,mission.archetype,seed)
 audio_system.set_lobby_active(true)
 return true

func _close_story_lobby():
 if not is_instance_valid(story_lobby):
  return
 var lobby=story_lobby
 story_lobby=null
 story_lobby_request.clear()
 lobby.close()
 lobby.queue_free()
 audio_system.set_lobby_active(false)

func _cancel_story_lobby(lobby: Control):
 if lobby!=story_lobby:
  return
 _close_story_lobby()
 mode="menu"
 ui.campaign.story_ui.show_prepare()

func _launch_story_from_lobby(lobby: Control):
 if lobby!=story_lobby:
  return
 var request:=story_lobby_request.duplicate(true)
 _close_story_lobby()
 mode="menu"
 var difficulty: String=request.difficulty
 if difficulty==profile.selected_difficulty and StoryProgress.position(profile.story,difficulty)==request.level and profile.item_loadout==request.items and profile.equipped==request.perks:
  if start_story(difficulty):
   return
 if ui.current_screen=="story_lobby":
  if ui.campaign.story_ui.notice=="":
   ui.campaign.story_ui.notice=profile.warning if profile.warning!="" else "This session could not start. Review your loadout and try again."
  ui.campaign.story_ui.show_prepare()

func start_stage(id: String, difficulty: String="standard") -> bool:
 if not RankCatalog.DIFFICULTIES.has(difficulty) or not profile.stage_unlocked(id): return false
 if not profile.select_stage(id) or not profile.select_difficulty(difficulty): return false
 campaign_mode=true
 _stage_request=id
 return start_match(difficulty)

func start_match(difficulty: String="",story_level: int=0) -> bool:
 if story_level>0 and not story_preview_enabled:return false
 hunter_spectating=false
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
 var mission:=StoryCatalog.mission(story_level) if story_level>0 else {}
 var requested: String=mission.get("stage_id",_stage_request)
 _stage_request=""
 campaign_mode=requested!=""
 var entry=profile.begin_match(selected_difficulty,requested,true,story_level)
 if entry.is_empty(): return false
 match_id=int(entry.get("id",0))
 var seed_value: int=int(entry.story.seed) if story_level>0 else int(Time.get_ticks_msec())
 if story_level==0 and model.procedural_v2_requested:seed_value=ui.replay_ui.fresh_macro_seed(StageCatalog.stage(requested).get("map",""))
 model.reset(seed_value)
 model.configure_match(selected_difficulty,RankCatalog.bonuses(entry.get("equipped",[])))
 if requested!="": model.configure_stage(requested)
 elif model.procedural_requested or model.procedural_v2_requested:model.configure_map(MapCatalog.IDS[posmod(model.map_seed,MapCatalog.IDS.size())])
 ui.replay_ui.remember_macro_layout(model)
 model.configure_balance(new_balance_version)
 if story_level>0:
  model.story_level=story_level
  model.preparation=maxf(model.preparation,float(mission.get("preparation",0.0)))
 model.configure_strategy(seed_value if story_level>0 else int(profile.statistics.matches),entry.archetype,entry.contract,match_id)
 if story_level>0:
  StoryCatalog.apply_encounter(model)
 profile.apply_stage_bonus(model,entry)
 if survivor_preview_enabled and not model.begin_room_rush(match_id):
  ui.campaign.story_ui.notice="This layout could not provide a shared route to all rooms."
  return false
 phase20_free_camera=false
 reset_phase20_adaptation()
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
 if phase20_help_open:close_pausing_help()
 phase20_free_camera=false
 _close_story_lobby()
 if construction!=null:construction.reset()
 hunter_spectating=false
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
 if ui.tactical_hud!=null:ui.tactical_hud.dismiss()
 if is_instance_valid(touch): touch.reset()
 model.running = not model.running
 if not model.running: pending_build=""
 ui.show_pause(not model.running)

var phase20_help_open:=false
var phase20_help
var phase20_was_running:=false
var phase20_free_camera:=false
var phase20_heatmap:=true
var phase20_camera_anchor:=Vector2.ZERO
var phase20_trim:=false
var phase20_trim_transitions:=0
var phase20_samples:=0
var phase20_slow_samples:=0
var phase20_window:=0.0
var phase20_bad_windows:=0

func reset_phase20_adaptation() -> void:
 phase20_trim=false
 phase20_samples=0;phase20_slow_samples=0;phase20_window=0.0;phase20_bad_windows=0

func phase20_adapt(delta: float) -> void:
 if not model.player_first_requested or not profile.settings.get("adaptive_performance",true):
  if phase20_samples>0 or phase20_trim:reset_phase20_adaptation()
  return
 if not model.running or phase20_trim:return
 phase20_samples+=1
 phase20_slow_samples+=int(delta>.037)
 phase20_window+=minf(delta,.10)
 if phase20_window<2.0:return
 if phase20_samples>=12 and float(phase20_slow_samples)/phase20_samples>.45:phase20_bad_windows+=1
 else:phase20_bad_windows=0
 phase20_samples=0;phase20_slow_samples=0;phase20_window=0.0
 if phase20_bad_windows>=2:
  phase20_trim=true
  phase20_trim_transitions+=1

func open_pausing_help() -> void:
 if phase20_help_open:return
 if ui.tactical_hud!=null:ui.tactical_hud.dismiss()
 if is_instance_valid(touch):touch.reset()
 phase20_was_running=model.running
 model.running=false
 phase20_help_open=true
 phase20_help=preload("res://scripts/pausing_help.gd").new(self)
 phase20_help.open()

func close_pausing_help() -> void:
 if not phase20_help_open:return
 phase20_help.close()
 phase20_help=null
 phase20_help_open=false
 model.running=phase20_was_running and model.result.is_empty()
 if ui.tactical_hud!=null and not tutorial_active:ui.tactical_hud.more.grab_focus()
 queue_redraw()

func _phase20_camera_input(event: InputEvent) -> bool:
 if tutorial_active or watched_room>=0 or hunter_spectating or full_map:return false
 if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
  if not phase20_free_camera:
   if event.relative.length_squared()<.5:return true
   phase20_free_camera=true
   phase20_camera_anchor=camera.position
   zoom_factor=camera.zoom.x
  phase20_camera_anchor-=event.relative/maxf(.1,camera.zoom.x)
  focus_camera(true)
  queue_redraw()
  return true
 if phase20_free_camera and event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
  zoom_factor=clampf(zoom_factor*(1.12 if event.button_index==MOUSE_BUTTON_WHEEL_UP else .89),.30,2.1)
  focus_camera(true)
  queue_redraw()
  return true
 return false

func _process(delta: float):
 if in_background or phase20_help_open or ui.tactical_settings!=null and mode=="match":return
 if mode=="story_lobby":
  audio_system.update_state(delta,model,"lobby")
  return
 if ui.shop!=null:ui.shop.update()
 level_warning_time=maxf(0,level_warning_time-delta)
 danger_time=maxf(0,danger_time-delta)
 if mode == "match":
  phase20_adapt(delta)
  presentation.weapons.begin_frame(self,model,delta)
  var direction = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
  if mobile_mode: direction=touch.movement(delta)
  if model.running:
   model.move_player(direction if watched_room<0 and not hunter_spectating else Vector2.ZERO,delta)
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
  var quick_practice: bool=model.player_first_requested and tutorial_active
  var tactical: bool=ui.tactical_hud!=null
  if (not tactical and not quick_practice and not mobile_mode and CinematicQuality.detail(self)>0) or ui_clock>=(.10 if quick_practice else .05):
   ui_clock=0
   ui.update_match()
  horror.update(delta,model)
  if model.run_kind=="endless" and model.endless!=null and model.endless.phase=="intermission" and ui.current_screen not in ["intermission","wave_report","run_choices"] and not ui.replay_ui.preparing:
   return_from_hunter()
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
   if model.run_kind=="campaign":
    if model.player_first_requested and model.result=="victory" and not CinematicQuality.reduced_motion(self):
     var finished_model: MatchModel=model
     get_tree().create_timer(.65).timeout.connect(func():
      if mode=="result" and model==finished_model:ui.show_result())
    else:ui.show_result()
   else:ui.replay_ui.show_session_result()
 if mode not in ["match","result"] or tutorial_active:audio_system.set_tension("quiet",0)
 if construction!=null:construction.update(delta)
 var score_context: String="story_prepare" if mode=="menu" and ui.current_screen=="story_prepare" and survivor_preview_enabled else mode
 audio_system.update_state(delta,model,score_context,hunter_spectating)
 SessionInterface.refresh(ui)
 if ui.tactical_hud==null:guidance.refresh(self)
 if ui.items_ui!=null: ui.items_ui.update(delta)
 presentation.notices_blocked=not model.running or ui.current_screen!="match" or is_instance_valid(ui.warning_box) and ui.warning_box.visible or construction.active() or construction.planning
 presentation.update(delta,model)
 if mode in ["match","result"] and not tutorial_active:audio_system.set_tension(presentation.identity.tension,presentation.identity.intensity)
 if mode=="match" and not tutorial_active:audio_system.update_environment(presentation.environment)
 if is_instance_valid(ui.horror_layer): ui.horror_layer.queue_redraw()
 queue_redraw()

# A double-click is one intent. Consume its second press AND release before
# Controls see it, so a newly opened panel cannot receive the trailing click.
var suppress_double_click_release=false
var cancelled_pointer=false

func _input(event):
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE and ui.close_tactical_page():
  cancelled_pointer=Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
  get_viewport().set_input_as_handled()
  return
 if mode=="match" and ui.tactical_settings!=null:return
 if phase20_help_open:
  if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE,KEY_G]:
   close_pausing_help()
   get_viewport().set_input_as_handled()
  return
 if mode=="story_lobby":
  return
 if hunter_spectating:
  if event is InputEventKey and event.pressed and not event.echo:
   if event.keycode in [KEY_HOME,KEY_ESCAPE]:return_from_hunter()
   get_viewport().set_input_as_handled()
  return
 if event is InputEventKey and event.keycode==KEY_ESCAPE and event.pressed and is_instance_valid(ui.run_panel) and ui.run_panel.visible:
  ui.run_panel.visible=false;get_viewport().set_input_as_handled();return
 if construction!=null and construction.handle_cancel(event):get_viewport().set_input_as_handled();return
 if mode=="match" and ui.tactical_hud!=null and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE and ui.tactical_hud.dismiss_escape():
  cancelled_pointer=Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
  get_viewport().set_input_as_handled()
  return
 # Cancel a held GUI press before BaseButton processes Escape/focus changes.
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and cancelled_pointer:
  cancelled_pointer=false;get_viewport().set_input_as_handled();return
 if mode=="match" and event is InputEventKey and event.keycode==KEY_ESCAPE and event.pressed and not event.echo and ui.context_open:
  cancelled_pointer=Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
  ui.close_context(true);get_viewport().set_input_as_handled();return
 if (mode!="match" and ui.current_screen!="shop") or not event is InputEventMouseButton: return
 if event.button_index!=MOUSE_BUTTON_LEFT: return
 if event.pressed:
  suppress_double_click_release=event.double_click
  if event.double_click: get_viewport().set_input_as_handled()
 elif suppress_double_click_release:
  suppress_double_click_release=false
  get_viewport().set_input_as_handled()

func _unhandled_input(event):
 if mode!="match" or in_background or hunter_spectating or phase20_help_open or ui.tactical_settings!=null:return
 if model.run_kind=="endless" and model.endless!=null and model.endless.phase=="intermission" and not ui.replay_ui.preparing:return
 if macro_overview() and not mobile_mode and _handle_macro_overview(event):
  get_viewport().set_input_as_handled()
  return
 if model.player_first_requested and _phase20_camera_input(event):get_viewport().set_input_as_handled();return
 if construction!=null and construction.handle(event):get_viewport().set_input_as_handled();return
 if mobile_mode and event is InputEventMouse: return
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_HOME:return_to_my_room()
  elif event.keycode==KEY_T and not tutorial_active:ui.teammates.toggle_panel()
  elif event.keycode in [KEY_PAGEUP,KEY_PAGEDOWN] and not tutorial_active:cycle_spectator(-1 if event.keycode==KEY_PAGEUP else 1)
  elif event.keycode in [KEY_1,KEY_2] and model.running:
   var slot:=0 if event.keycode==KEY_1 else 1
   if ui.use_living_dorm():ui.items_ui.select_slot(slot)
   else:activate_item(slot)
  elif event.keycode==KEY_K and model.balance_version==2 and model.run_kind=="endless":RunChoiceInterface.show(ui)
  elif event.keycode==KEY_F and not tutorial_active:command_ward()
  elif event.keycode==KEY_B and model.running and watched_room<0:
   if model.player()==null:ui.touch_notice("Claim an empty room first · E inside the room.")
   else:ui.open_build_menu()
  elif event.keycode==KEY_E and model.running and watched_room<0:
   interact_survivor()
  elif event.keycode==KEY_M: toggle_map()
  elif event.keycode==KEY_G: toggle_guide()
  elif event.keycode==KEY_I and not tutorial_active:ui.items_ui.toggle_expanded()
  elif event.keycode==KEY_R and model.running: ui.repair_player_door()
  elif event.keycode==KEY_ESCAPE:
   if pending_build!="": cancel_placement(true)
   elif watched_room>=0:return_to_my_room()
   elif ui.use_living_dorm() and ui.items_ui.expanded:ui.items_ui.toggle_expanded()
   elif ui.context_open: ui.close_context(true)
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

func command_ward():
 if mode!="match" or in_background or watched_room>=0 or pending_build!="":return
 if not model.route_defense_power():ui.touch_notice(model.ward_reason())

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

func cancel_placement(explicit: bool=false):
 var previous_kind: String=construction.kind if construction!=null and construction.kind!="" else pending_build
 if construction!=null:construction.cancel()
 pending_build=""
 placement_on_tile=false
 ui.close_context(explicit)
 if explicit and previous_kind!="" and tutorial_active and survivor_preview_enabled and is_instance_valid(onboarding) and onboarding.has_method("note_placement_cancelled"):
  onboarding.note_placement_cancelled(previous_kind)

func interact_survivor():
 if tutorial_active and survivor_preview_enabled and is_instance_valid(onboarding) and onboarding.has_method("permits_interact") and not onboarding.permits_interact():
  return
 var before: int=model.player_room
 model.interact()
 if tutorial_active and survivor_preview_enabled and before<0 and model.player_room>=0:
  model.enable_player_grid(true)
  ui.update_match()

func toggle_map():
 if ui.tactical_hud!=null:ui.tactical_hud.dismiss()
 if phase20_free_camera:phase20_free_camera=false;zoom_factor=1.0
 cancel_placement()
 full_map=not full_map
 if macro_overview():
  reset_overview()

func macro_overview() -> bool:
 return full_map and model.is_procedural() and model.map_data.has("family") and not hunter_spectating

func reset_overview():
 overview_zoom=1.0
 overview_pan=Vector2.ZERO
 overview_room=-1
 overview_opening.clear()

func overview_frame() -> Rect2:
 var size:=get_viewport_rect().size
 return Rect2(Vector2(size.x*.035,size.y*.196),Vector2(size.x*.93,size.y*.62))

func overview_fit() -> float:
 var world:=model.map_bounds().size
 var available:=overview_frame().size
 return minf(available.x/world.x,available.y/world.y)

func _select_overview_room(screen: Vector2):
 var at:=get_viewport().get_canvas_transform().affine_inverse()*screen-MAP_OFFSET
 overview_room=-1
 overview_opening.clear()
 for room in model.rooms:
  if room.floor_has_point(at):
   overview_room=room.index
   overview_opening=model.opening_room_forecast(room.index)
   break
 queue_redraw()

func _overview_zoom_at(screen: Vector2, multiplier: float):
 var before:=overview_fit()*overview_zoom
 overview_zoom=clampf(overview_zoom*multiplier,1.0,3.0)
 var after:=overview_fit()*overview_zoom
 overview_pan+=(screen-overview_frame().get_center())*(1.0/before-1.0/after)
 focus_camera(true)
 queue_redraw()

func _handle_macro_overview(event: InputEvent) -> bool:
 if event is InputEventMouseButton and event.pressed:
  match event.button_index:
   MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
    _overview_zoom_at(event.position,1.25 if event.button_index==MOUSE_BUTTON_WHEEL_UP else .8)
    return true
   MOUSE_BUTTON_LEFT:
    _select_overview_room(event.position)
    return true
 if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
  overview_pan-=event.relative/camera.zoom.x
  focus_camera(true)
  queue_redraw()
  return true
 if model.player_first_requested and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_H:
  phase20_heatmap=not phase20_heatmap
  queue_redraw()
  return true
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_0:
  reset_overview()
  focus_camera(true)
  queue_redraw()
  return true
 return false

func focus_camera(snap: bool=false,delta: float=0.016):
 if mode!="match": return
 if phase20_free_camera and not full_map and not hunter_spectating and watched_room<0:
  var bounds: Rect2=model.map_bounds()
  phase20_camera_anchor=phase20_camera_anchor.clamp(bounds.position+MAP_OFFSET,bounds.end+MAP_OFFSET)
  camera.position=phase20_camera_anchor
  camera.zoom=Vector2.ONE*zoom_factor
  camera.force_update_scroll()
  return
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
 # Legacy desktop rooms share the same panel-independent safe framing.
 if model.map_id!="legacy" or (not mobile_mode and not full_map):
  if full_map:
   if macro_overview():
    var extent:=model.map_bounds()
    var frame:=overview_frame()
    zoom=overview_fit()*overview_zoom
    var limit: Vector2=((extent.size-frame.size/zoom)*.5).max(Vector2.ZERO)
    overview_pan=overview_pan.clamp(-limit,limit)
    goal=extent.get_center()+MAP_OFFSET+overview_pan+(get_viewport_rect().get_center()-frame.get_center())/zoom
   else:
    var extent=model.map_bounds().grow(35)
    zoom=minf(1220.0/extent.size.x,500.0/extent.size.y)
    goal=extent.get_center()+MAP_OFFSET+Vector2(0,10)/zoom
  elif model.player()!=null or watched_room>=0:
   var observed=model.rooms[watched_room] if watched_room>=0 else model.player()
   var extent: Rect2
   var available=Vector2(1160,470)
   var desired=Vector2(640,385)
   if (rebirth_framing or observed.spatial!=null and observed.spatial.grid) and not mobile_mode and not model.tutorial_mode:
    extent=_preview_room_extent(observed)
    # One stable composition with space reserved for warnings, the dock and
    # the side inspector. Opening a panel never recenters the playing field.
    available=Vector2(486,464)
    desired=Vector2(642,388)
   else:
    extent=observed.bounds().grow(35)
    # Fixed room framing includes heads/scythe above upward-facing doors.
    extent=extent.expand(observed.door_approach()+Vector2(0,-100))
    extent=extent.expand(observed.door_approach()+Vector2(0,40))
    # Distant Hunters cannot zoom another room out.
    var local_hunter=model.hunter
    if local_hunter.hp>0 and local_hunter.target==observed.index and local_hunter.state in [HunterState.State.MOVE,HunterState.State.ATTACK,HunterState.State.BREACH,HunterState.State.TRANSFORM] and local_hunter.position.distance_to(observed.door_approach())<=150:
     extent=extent.expand(local_hunter.position+Vector2(-50,-105))
     extent=extent.expand(local_hunter.position+Vector2(50,45))
   zoom=minf(available.x/extent.size.x,available.y/extent.size.y)*zoom_factor
   goal=extent.get_center()+MAP_OFFSET+(get_viewport_rect().size/2-desired)/zoom
 if hunter_spectating:
  zoom=1.40
  var recovery=model.get("haunt_recovery")
  if recovery!=null and recovery.phase=="recover":
   var hall: Dictionary=model.map_data.get("halls",{}).get(recovery.hall_id,{})
   if not hall.is_empty():
    var extent: Rect2=hall.bounds.grow(32)
    zoom=clampf(minf(700/extent.size.x,418/extent.size.y),.70,1.65)
  # World-space follow uses the real actor. Map mode and construction are restored on return.
  goal=model.hunter.position+MAP_OFFSET-Vector2(0,30)
 if mobile_mode and not full_map and not hunter_spectating:
  var desired=Vector2(470 if ui.context_open and model.player()!=null and model.player().sleeping else 640,340)
  goal+=(get_viewport_rect().size/2-mobile_layout.screen_point(desired))/zoom
 camera_target=goal
 var weight=1.0 if snap else 1.0-exp(-delta*7)
 camera.position=camera.position.lerp(goal,weight)
 camera.zoom=camera.zoom.lerp(Vector2(zoom,zoom),weight)
 camera.offset=Vector2.ZERO if macro_overview() or CinematicQuality.reduced_motion(self) else Vector2(sin(presentation.clock*63),cos(presentation.clock*51))*danger_time*1.5+presentation.nightmare_visual.camera_impulse()
 camera.force_update_scroll()

func _preview_room_extent(room: RoomState) -> Rect2:
 var extent := room.bounds().grow_individual(13, 17, 13, 17)
 var door := room.door_position()
 var approach := room.door_approach()
 extent = extent.expand(door + Vector2(104, 20))
 extent = extent.expand(approach + Vector2(0, -109))
 extent = extent.expand(approach + Vector2(0, 25))
 var hunter := model.hunter
 if hunter.hp <= 0 or hunter.target != room.index or hunter.state not in [HunterState.State.MOVE, HunterState.State.ATTACK, HunterState.State.BREACH, HunterState.State.TRANSFORM]:
  return extent
 var distance := hunter.position.distance_to(approach)
 var weight := 1.0 - smoothstep(90.0, 150.0, distance)
 var with_hunter := extent.expand(hunter.position + Vector2(-103, -110)).expand(hunter.position + Vector2(103, 46))
 return Rect2(extent.position.lerp(with_hunter.position, weight), extent.size.lerp(with_hunter.size, weight))

func world_to_screen(point: Vector2) -> Vector2:
 return get_viewport().get_canvas_transform()*(point+MAP_OFFSET)

func room_ownership_label(room: RoomState) -> String:
 match model.room_rush_status(room.index):
  "player": return "YOUR ROOM"
  "npc": return "NPC CLAIMED"
  "approaching": return "NPC APPROACHING"
  _: return "VACANT"

func _draw():
 if mode!="story_lobby":
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
 if mode=="match" and model.player_first_requested and not mobile_mode:
  open_pausing_help()
  return
 ui.help_open=not ui.help_open
 if ui.help_open:ui.items_ui.expanded=false

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
  if hunter_spectating:return_from_hunter()
  elif pending_build!="": cancel_placement()
  elif ui.context_open: ui.close_context()
  else: toggle_pause()
 else: return_menu()

func handle_touch_tap(screen: Vector2):
 if mode!="match" or not model.running or in_background or hunter_spectating: return
 if macro_overview():
  _select_overview_room(screen)
  return
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
   if candidate.owner<0 and (candidate.floor_has_point(point) or point.distance_to(candidate.door_position())<40):
    touch.navigate_room(candidate)
    ui.touch_notice("Walking to the room. Then tap its bed to sleep.")
    return

func retry_settlement():
 if model.run_kind=="endless":last_progression=profile.settle_endless(model);ui.replay_ui.show_session_result()
 else:last_progression=profile.settle_match(match_id,model);ui.show_result()

func watch_hunter() -> bool:
 if mode!="match" or hunter_spectating or not model.running or model.result!="" or ui.current_screen!="match":return false
 var recovery=model.get("haunt_recovery")
 if recovery==null or recovery.phase not in ["retreat","recover"]:return false
 if is_instance_valid(touch):touch.reset()
 full_map=false
 hunter_spectating=true
 focus_camera(true)
 ui.update_match()
 return true

func return_from_hunter():
 if not hunter_spectating:return
 hunter_spectating=false
 full_map=false
 watched_room=-1
 if is_instance_valid(ui.context_box):ui.context_box.visible=ui.context_open
 focus_camera(true)
 ui.update_match()

func spectate_room(index: int) -> bool:
 if mode!="match" or hunter_spectating or tutorial_active or model.result!="" or index<0 or index>=model.rooms.size() or model.rooms[index].owner<=0:return false
 cancel_placement();ui.close_context();watched_room=index;full_map=false;zoom_factor=1
 focus_camera();ui.teammates.update()
 return true
func return_to_my_room():
 phase20_free_camera=false
 hunter_spectating=false
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

func build_selected(kind: String) -> bool:
 if construction!=null and construction.applicable():return construction.begin(kind)
 if mode!="match" or watched_room>=0:return false
 var ok=model.buy(kind,selected_tile)
 pending_build="";placement_on_tile=false
 if ok:ui.context_open=true;ui.context_mode="upgrade"
 ui.purchase(ok);ui.refresh_context()
 return ok
