class_name AudioDirector
extends Node

const ROOT = "res://assets/audio/"
const WrathAudio = preload("res://scripts/wrath_audio_catalog.gd")
const LOOP_NAMES = ["music_crimson","music_intro","music_approach","music_endless","music_menu","music_calm","music_danger","ambient_dorm","proximity_loop","generator_loop","music_reaper","reaper_ambience"]
const LEGACY_EFFECT_NAMES = ["nightmare_defeat","nightmare_rebirth","death_scream_1","death_scream_2","hunter_laugh","reaper_laugh","weather_thunder","weather_wind","weather_rain","prestige_upgrade","survivor_notice","intro_running","intro_breath","intro_lightning","intro_impact","intro_shriek","intro_whisper","tutorial_step","tutorial_complete","shop_purchase","perk_unlocked","achievement_unlocked","achievement_claim","difficult_stage","stage_bonus_selected","mythic_perk","button","menu","match_start","purchase","failure","rank","reward","victory","defeat","shot_needle","shot_arc","impact","ghost_hurt","ghost_defeat","door_hit","door_crack","door_break","build","turret_upgrade","bed_upgrade","door_upgrade","repair","upgrade","income","electricity","footstep","danger","breach","hunter_spawn","hunter_level","elimination","scream_1","scream_2","scream_3","door_reaction","sale","refund","insufficient_gold","insufficient_power","eerie","reaper_transform","reaper_scythe","reaper_charge","reaper_surge","reaper_impact","reaper_hurt","reaper_death","mythic_promotion","item_time_freeze","item_reaper_seal","item_guardian_heart","item_cursed_fortune","item_legendary_reveal","item_barricade","item_feather","item_inferno","item_pillow","item_coupon","item_decoy","item_rescue","item_smoke","item_repair","item_gold","item_battery","item_radar","item_shield","item_overdrive","item_frost","item_trap","item_reveal","item_end","item_explosion","item_shield_hit"]
const LEGACY_CRITICAL_EVENTS = ["nightmare_defeat","nightmare_rebirth","death_scream_1","death_scream_2","survivor_notice","prestige_upgrade","intro_running","intro_breath","intro_lightning","intro_impact","intro_shriek","intro_whisper","tutorial_step","tutorial_complete","shop_purchase","perk_unlocked","achievement_unlocked","achievement_claim","difficult_stage","stage_bonus_selected","mythic_perk","victory","defeat","ghost_defeat","rank","reward","hunter_level","breach","door_break","match_start","door_reaction","sale","refund","reaper_transform","reaper_charge","reaper_surge","reaper_death","mythic_promotion","item_time_freeze","item_reaper_seal","item_guardian_heart","item_cursed_fortune","item_legendary_reveal","item_barricade","item_feather","item_inferno","item_pillow","item_coupon","item_decoy","item_rescue","item_smoke","item_repair","item_gold","item_battery","item_radar","item_shield","item_overdrive","item_frost","item_trap","item_reveal","item_explosion"]
const EFFECT_NAMES = LEGACY_EFFECT_NAMES + WrathAudio.NAMES
const CRITICAL_EVENTS = LEGACY_CRITICAL_EVENTS + WrathAudio.CRITICAL_NAMES
const VOICE_LIMIT = 16
const MAX_PENDING_CRITICAL = 24
const FRAME_VOICE_LIMIT = 6
const EFFECT_COOLDOWNS = {"reaper_transform":4.0,"reaper_scythe":0.7,"reaper_charge":1.8,"reaper_surge":1.5,"reaper_impact":0.5,"reaper_hurt":0.35,"reaper_death":4.0,"scream_1":2.0,"scream_2":2.0,"scream_3":2.0,"door_reaction":2.0,"sale":0.15,"refund":0.15,"insufficient_gold":0.4,"insufficient_power":0.4,"eerie":12.0,"shot_needle":0.07,"shot_arc":0.11,"impact":0.09,"ghost_hurt":0.22,"door_hit":0.12,"door_crack":0.8,"door_break":1.0,"income":1.1,"electricity":1.0,"repair":1.0,"footstep":0.38,"danger":3.0,"build":0.15,"upgrade":0.18,"hunter_level":0.5,"hunter_spawn":1.0,"match_start":0.8,"victory":2.0,"defeat":2.0,"rank":0.8,"reward":0.4,"menu":0.2}
var mobile_profile=false
var suspended=false
var event_counts: Dictionary = {}
var preview_music=""
var preview_effect_until=0.0
var preview_effect_name=""
var cinematic_music=false
var music_start_count = 0
var intensity = 0.0
var proximity = 0.0
var loop_weights: Dictionary = {}
var mix = {"music":0.65,"effects":0.75,"ambient":0.65,"muted":false}
var missing_assets: Array = []
var dropped_events = 0
var voices: Array = []
var loops: Dictionary = {}
var streams: Dictionary = {}
var hearing_radius=850.0
var listener_position = Vector2(500,410)
var _initialized = false
var _clock = 0.0
var _frame_voices = 0
var _cooldowns: Dictionary = {}
var _observed_model
var _previous: Dictionary = {}
var _last_combat_event = 0
var _last_mode = ""
var _previous_time = 0.0
var _previous_hunter_position = Vector2.ZERO
var _mode = "menu"
var _pending_critical: Array = []
var _voice_names: Dictionary = {}
var _voice_priority: Dictionary = {}
var _family_cooldowns: Dictionary = {}
var expired_events=0
var crimson_music_starts=0
var _domain_music_active=false
var _last_presentation_event=0
var _encounter_cooldowns: Dictionary={}
var music_duck=1.0
var tension_state="quiet"
var tension_weight=0.0
var pacing_gain=1.0
var ambience_gain=1.0
var death_rooms: Dictionary={}
var laughed_rooms: Dictionary={}
var pending_laughs: Array=[]
var environment_serial=0
var environment_ref
var death_sequence=0
var pending_deaths: Array=[]
var pending_evolutions: Array=[]
var _evolved_rooms: Dictionary={}
var _last_death_room=-1
var _evolution_busy_until=0.0
var evolution_cues_played=0
var _scream_voice
var _scream_next=0.0
var _scream_variation=0
var _next_eerie=12.0
var _seen_presentation: Dictionary={}


func _ready():
 setup()

func setup():
 if _initialized:
  return
 _initialized = true
 for bus_name in ["Music","Effects","Ambient"]:
  if AudioServer.get_bus_index(bus_name) < 0:
   AudioServer.add_bus()
   AudioServer.set_bus_name(AudioServer.bus_count-1,bus_name)
  # Keep substantial headroom across up to sixteen simultaneous sound voices.
 for name in LOOP_NAMES+EFFECT_NAMES:
  var path = ROOT+name+".wav"
  if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
   missing_assets.append(path)
   push_error("Nightfall audio missing: "+path)
   continue
  var stream: AudioStreamWAV
  if ResourceLoader.exists(path):
   var imported = load(path) as AudioStreamWAV
   if imported != null:
    stream = imported.duplicate() as AudioStreamWAV
  elif FileAccess.file_exists(path):
   stream = AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(path))
  if stream == null:
   missing_assets.append(path)
   push_error("Nightfall audio could not decode: "+path)
   continue
  if name in LOOP_NAMES and name!="music_intro":
   stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
   stream.loop_begin = 0
   stream.loop_end = roundi(stream.get_length()*stream.mix_rate)
  streams[name] = stream
 for name in LOOP_NAMES:
  if not streams.has(name):
   continue
  var player = AudioStreamPlayer.new()
  player.name = name
  player.stream = streams[name]
  player.bus = "Music" if name.begins_with("music") else "Ambient"
  player.volume_db = -80
  add_child(player)
  loops[name] = player
  loop_weights[name] = 0.0
  player.play()
  if name.begins_with("music"):
   music_start_count += 1
 for i in range(10 if mobile_profile else VOICE_LIMIT):
  var voice = AudioStreamPlayer2D.new()
  voice.max_distance=2000
  voice.attenuation=0.0
  voice.panning_strength=0.35
  voice.name = "EffectVoice%d" % i
  voice.bus = "Effects"
  add_child(voice)
  voices.append(voice)
 set_mix(mix)

func begin_cinematic():
 setup();cinematic_music=true
 if loops.has("music_intro"):loops.music_intro.play(0)
func end_cinematic():cinematic_music=false
func preview_track(name: String):
 preview_music=name if name in LOOP_NAMES and name.begins_with("music") else ""
 if preview_music!="":loops[preview_music].play(0)
func preview_effect(name: String):
 stop_preview()
 if not streams.has(name) or name not in EFFECT_NAMES:return
 preview_effect_name=name;preview_effect_until=_clock+streams[name].get_length()+.2
 event(name)
func stop_preview():
 preview_music=""
 if preview_effect_name!="":stop_events([preview_effect_name])
 preview_effect_name="";preview_effect_until=0.0

func set_mix(settings: Dictionary):
 for key in ["music","effects","ambient"]:
  if settings.has(key):
   var value = float(settings[key])
   mix[key] = clampf(value,0,1) if is_finite(value) else 0.0
 if settings.has("muted"):
  mix.muted = bool(settings.muted)
 if not _initialized:
  return
 for key in ["music","effects","ambient"]:
  var bus_name = {"music":"Music","effects":"Effects","ambient":"Ambient"}[key]
  var index = AudioServer.get_bus_index(bus_name)
  AudioServer.set_bus_volume_db(index,linear_to_db(maxf(0.0001,mix[key]))-5.0)
  AudioServer.set_bus_mute(index,mix.muted or mix[key]<=0)

func event(name: String, position: Vector2 = Vector2.INF, details: Dictionary = {}) -> bool:
 setup()
 var aliases = {"menu_open":"menu","menu_navigation":"menu","button_click":"button","rank_promotion":"rank","reward_unlock":"reward","insufficient":"failure","outcome":"victory","generator":"electricity"}
 name = aliases.get(name,name)
 if not streams.has(name) or name in LOOP_NAMES:
  if not EFFECT_NAMES.has(name):
   push_warning("Unknown Nightfall audio event: "+name)
  return false
 var critical = name in CRITICAL_EVENTS and bool(details.get("important",true))
 var family=WrathAudio.family(name)
 if family!="" and _clock<float(_family_cooldowns.get(family,-1.0)):return false
 if _clock < float(_cooldowns.get(name,-1.0)):
  return false
 if _frame_voices >= (FRAME_VOICE_LIMIT if critical else FRAME_VOICE_LIMIT-2):
  if critical:
   _queue_critical(name,position,details)
  else:
   dropped_events += 1
  return false
 var distance_gain = 1.0
 var prominent=name in ["death_scream_1","death_scream_2","survivor_notice","hunter_laugh","reaper_laugh","hunter_evolve","reaper_phase_2","wrath_activate_crimson_execution"]
 if position.is_finite():
  var distance = listener_position.distance_to(position)
  if distance > hearing_radius and not prominent:
   return false
  distance_gain = clampf(1.0-distance/(hearing_radius/0.85),0.3 if prominent else 0.15,1.0)
  if prominent:position=listener_position+listener_position.direction_to(position)*minf(distance,600)
 var free_voice = null
 for voice in voices:
  if not voice.playing:
   free_voice = voice
   break
 if free_voice == null and critical:
  for voice in voices:
   if not bool(_voice_priority.get(voice.get_instance_id(),_voice_names.get(voice.get_instance_id(),"") in CRITICAL_EVENTS)):
    voice.stop()
    free_voice = voice
    break
 if free_voice == null:
  if critical:
   _queue_critical(name,position,details)
  else:
   dropped_events += 1
  return false
 _voice_names[free_voice.get_instance_id()] = name
 _voice_priority[free_voice.get_instance_id()] = critical
 var offset=position-listener_position if position.is_finite() else Vector2.ZERO
 # Put positional voices around the actual listener's viewport, not the world origin.
 var canvas_center=get_viewport().get_visible_rect().get_center()
 var canvas=get_viewport().get_canvas_transform()
 var canvas_scale=maxf(.1,canvas.get_scale().x)
 free_voice.max_distance=maxf(2000,1800/canvas_scale)
 free_voice.global_position=canvas.affine_inverse()*canvas_center+Vector2(clampf(offset.x/2,-500,500),clampf(offset.y/2,-220,220))/canvas_scale
 free_voice.panning_strength=.65 if name in ["footstep","door_hit","reaper_charge","reaper_scythe","death_scream_1","death_scream_2"] else .35
 free_voice.stream = streams[name]
 free_voice.bus="Ambient" if name.begins_with("weather_") else "Effects"
 free_voice.volume_db = linear_to_db(distance_gain*(ambience_gain if name.begins_with("weather_") else 1.0))+WrathAudio.gain_db(name)
 free_voice.pitch_scale = 1.0
 free_voice.play()
 _cooldowns[name] = _clock+float(WrathAudio.cooldown(name,EFFECT_COOLDOWNS.get(name,0.08)))
 if family!="":_family_cooldowns[family]=_cooldowns[name]
 event_counts[name] = int(event_counts.get(name,0))+1
 _frame_voices += 1
 return true

func sfx_preview_groups() -> Dictionary:return WrathAudio.PREVIEW_GROUPS.duplicate(true)

func reset_match(model):
 _domain_music_active=false
 tension_state="quiet";tension_weight=0;pacing_gain=1;ambience_gain=1
 setup()
 _observed_model = model
 _last_combat_event = 0
 _last_presentation_event=0
 _encounter_cooldowns.clear()
 death_rooms.clear();laughed_rooms.clear();pending_laughs.clear();environment_serial=0;environment_ref=null;death_sequence=0;pending_deaths.clear();pending_evolutions.clear();_evolved_rooms.clear();_last_death_room=-1;_evolution_busy_until=0;evolution_cues_played=0
 _scream_next=0
 _scream_voice=null
 _next_eerie=_clock+12
 _previous_time = model.time
 _previous_hunter_position = model.hunter.position
 _previous = _snapshot(model)
 # Match-specific throttles must not suppress cues after a restart.
 _cooldowns.clear();_family_cooldowns.clear()
 _pending_critical.clear()
 _frame_voices = 0
 for voice in voices:
  voice.stop()

func stop_events(names: Array):
 _pending_critical=_pending_critical.filter(func(cue):return cue.name not in names)
 for voice in voices:
  if _voice_names.get(voice.get_instance_id(),"") in names:voice.stop()

func _stop_battle_cues():
 # Terminal defeat still owns its recorded death/evolution sequence. Combat
 # warnings and attacks have no valid target after the encounter has ended.
 var names=[]
 for name in EFFECT_NAMES:
  if name.begins_with("shot_") or name.begins_with("impact_") or name.begins_with("wrath_") or name.begins_with("undead_") or name.begins_with("scythe_") or name.begins_with("item_") or (name.begins_with("hunter_") and name not in ["hunter_evolve","hunter_laugh"]) or name in ["impact","ghost_hurt","door_hit","door_crack","door_break","danger","breach","footstep","eerie","reaper_transform","reaper_charge","reaper_surge","reaper_scythe","reaper_impact","reaper_hurt","shield_activate","shield_absorb","auto_repair_activate","decoy_activate","scream_1","scream_2","scream_3","door_reaction"]:
   if name!=preview_effect_name or _clock>=preview_effect_until:names.append(name)
 stop_events(names)

func new_encounter(model):
 # Same run and rooms, intentionally fresh Hunter. Valid screams/laughs and
 # their serialized queues continue; only the defeated Hunter's warnings stop.
 stop_events(["reaper_transform","reaper_charge","reaper_surge","reaper_scythe"]+WrathAudio.COMBAT_WARNINGS)
 _domain_music_active=false
 _observed_model=model;_previous_time=model.time
 _previous_hunter_position=model.hunter.position;_previous=_snapshot(model)
 _last_combat_event=model.next_combat_event_id-1
 _last_presentation_event=model.next_presentation_event_id-1
 set_tension("quiet",0)

func update_state(delta: float, model, mode: String):
 if suspended: return
 setup()
 if not is_finite(delta) or delta < 0:
  return
 _clock += delta
 _frame_voices = 0
 _mode = mode
 if mode in ["menu","intro"] and mode!=_last_mode:
  # A menu can retain the previous model for its result summary. It must not
  # retain combat players or delayed cues; listening-room previews remain valid.
  var cancelled=EFFECT_NAMES.filter(func(name):return name!=preview_effect_name or _clock>=preview_effect_until)
  stop_events(cancelled)
 if mode in ["menu","intro"] or (model!=null and model.tutorial_mode):
  set_tension("quiet",0)
  pending_laughs.clear();pending_deaths.clear();pending_evolutions.clear();_last_death_room=-1;_evolution_busy_until=0
  if _clock>=preview_effect_until:stop_events(["hunter_laugh","reaper_laugh","death_scream_1","death_scream_2","weather_thunder","weather_wind","weather_rain","hunter_evolve","buff_offense","buff_armor","buff_speed","buff_resource","buff_command"])
 for cue in pending_laughs.duplicate():
  if _clock-cue.time>60:pending_laughs.erase(cue);continue
  var death_playing=voices.any(func(v):return v.playing and _voice_names.get(v.get_instance_id(),"").begins_with("death_scream"))
  var laugh_playing=voices.any(func(v):return v.playing and _voice_names.get(v.get_instance_id(),"") in ["hunter_laugh","reaper_laugh"])
  if _clock>=cue.time+.25 and not death_playing and pending_deaths.is_empty() and pending_evolutions.is_empty() and _clock>=_evolution_busy_until and not laugh_playing and event(cue.name,cue.position):pending_laughs.erase(cue)
 var pending = _pending_critical.duplicate()
 _pending_critical.clear()
 for cue in pending:
  if _clock<=float(cue.get("deadline",_clock)):
   event(cue.name,cue.position,cue.get("details",{}))
  else:expired_events+=1
 if model != null and (model != _observed_model or model.time < _previous_time):
  reset_match(model)
 if mode != _last_mode:
  if mode == "menu":
   event("menu")
  elif mode == "match":
   event("match_start")
  _last_mode = mode
 var target_intensity = 0.0
 var target_proximity = 0.0
 var generator_weight = 0.0
 var active = model != null and mode == "match" and model.result == ""
 if model != null:
  if not _previous.is_empty() and _previous.state!=HunterState.State.DEAD and model.hunter.state==HunterState.State.DEAD and _previous.hp>0:
   event("reaper_death" if model.hunter.transformed else "nightmare_defeat" if model.evolution.evolution_level==10 else "ghost_defeat")
   _previous.state = HunterState.State.DEAD
   _previous.hp = model.hunter.hp
  var room = model.player()
  listener_position = room.bed_position() if room != null else model.player_position
  hearing_radius=maxf(850.0,model.map_bounds().size.length()) if model.map_id!="legacy" else 850.0
  if mode in ["match","result"]:
   _observe_presentation(model)
   _play_death_queue()
  if active:
   _observe(model)
   if model.running and tension_state in ["quiet","distant"] and _clock>=_next_eerie:
    event("eerie",listener_position)
    _next_eerie=_clock+17+int(model.time)%9
   if model.hunter.state not in [HunterState.State.DORMANT,HunterState.State.DEAD] and model.hunter.hp > 0:
    var distance = model.hunter.position.distance_to(room.door_position() if room != null else listener_position)
    target_proximity = clampf(1-distance/480.0,0,1)
    var vulnerability = 1.0-room.door_hp/room.max_hp() if room != null else 0.8
    var attacking_player = room != null and model.hunter.target==room.index and model.hunter.state in [HunterState.State.ATTACK,HunterState.State.BREACH]
    target_intensity = clampf(target_proximity*0.6+vulnerability*target_proximity*0.3+minf(0.15,(model.hunter.level-1)*0.03)+(0.25*target_proximity if attacking_player else 0),0,1)
    if target_proximity>0.45 and model.hunter.position.distance_to(_previous_hunter_position)>0.25:
     event("footstep",model.hunter.position)
    if target_intensity>0.75 and intensity<=0.75:
     event("danger",listener_position)
   if room != null and room.alive:
    for building in room.buildings.values():
     if building.kind=="generator":
      generator_weight = minf(0.45,0.15+building.level*0.05)
  _previous_hunter_position = model.hunter.position
  _previous_time = model.time
 intensity = move_toward(intensity,target_intensity,delta*1.6)
 proximity = move_toward(proximity,target_proximity,delta*1.8)
 var music_active = mode=="match" and (model==null or model.result=="")
 var boss_active=active and model.hunter.transformed and model.hunter.hp>0
 var domain=active and model.has_method("domain_music_active") and model.domain_music_active()
 if domain and not _domain_music_active:
  loops.music_crimson.play(0);crimson_music_starts+=1
 _domain_music_active=domain
 var targets = {"music_menu":1.0 if mode=="menu" else 0.0,"music_calm":(1.0-intensity)*0.85 if music_active and not boss_active else 0.0,"music_danger":intensity*0.85 if music_active and not boss_active else 0.0,"ambient_dorm":0.35+proximity*0.30 if active else 0.15 if mode=="menu" else 0.0,"proximity_loop":proximity*intensity*0.65 if active else 0.0,"generator_loop":generator_weight if active else 0.0}
 targets["music_reaper"]=0.95 if boss_active and not domain else 0.0
 targets.music_crimson=.95 if music_active and domain else 0.0
 if domain:
  targets.music_calm=0;targets.music_danger=0
 targets.music_intro=1.0 if mode=="intro" and cinematic_music else 0.0
 targets.music_approach=.75 if music_active and not boss_active and proximity>.12 and intensity<.65 else 0.0
 targets.music_endless=.85 if music_active and model!=null and model.run_kind=="endless" and not boss_active and int(model.endless.wave)%2==0 else 0.0
 if targets.music_approach>0:targets.music_calm*=.35
 if targets.music_endless>0:targets.music_calm*=.25;targets.music_danger*=.5
 if preview_music!="":
  for key in targets:targets[key]=1.0 if key==preview_music else 0.0
 var critical_active=voices.any(func(v):return v.playing and bool(_voice_priority.get(v.get_instance_id(),false)) and _voice_names.get(v.get_instance_id(),"") not in ["intro_running","intro_breath"])
 music_duck=move_toward(music_duck,.48 if critical_active else 1.0,delta*3.0)
 targets["reaper_ambience"]=proximity*0.55 if boss_active else 0.0
 pacing_gain=move_toward(pacing_gain,1.0-.35*tension_weight,delta*.7)
 ambience_gain=move_toward(ambience_gain,1.0-.4*tension_weight,delta*.6)
 for name in loops:
  loop_weights[name] = move_toward(float(loop_weights[name]),float(targets[name]),delta*1.1)
  var music_gain=(.95 if mode=="match" else 1.0)*music_duck*maxf(.8,pacing_gain) if name.begins_with("music") else ambience_gain if name in ["ambient_dorm","reaper_ambience"] else 1.0
  loops[name].volume_db = linear_to_db(maxf(0.0001,loop_weights[name]*music_gain))+(-3.0 if name.begins_with("music") else -15.0)
 # Outcomes may be supplied explicitly by the host, too; cooldown prevents repeats.
 if model != null and model.result != "" and _previous.get("result","") != model.result:
  stop_events(WrathAudio.COMBAT_WARNINGS)
  _pending_critical=_pending_critical.filter(func(cue): return cue.name not in ["reaper_transform","reaper_charge","reaper_surge"])
  for voice in voices:
   if _voice_names.get(voice.get_instance_id(),"") in ["reaper_transform","reaper_charge","reaper_surge","reaper_scythe"]: voice.stop()
  event("reward" if model.result=="retired" else "victory" if model.result=="victory" else "defeat")
  _previous.result = model.result
 if mode=="result" or (model!=null and model.result!=""):_stop_battle_cues()

func _snapshot(model) -> Dictionary:
 var rooms: Dictionary = {}
 for room in model.rooms:
  var buildings: Dictionary = {}
  for tile in room.buildings:
   var building = room.buildings[tile]
   buildings[tile] = {"kind":building.kind,"level":building.level}
  rooms[room.index] = {"alive":room.alive,"bed":room.bed_level,"door":room.door_level,"hp":room.door_hp,"max_hp":room.max_hp(),"income":room.income_total,"power":room.electricity,"buildings":buildings}
 return {"rooms":rooms,"level":model.hunter.level,"hp":model.hunter.hp,"state":model.hunter.state,"attacks":model.hunter.attacks,"result":model.result}

func _observe(model):
 if _previous.is_empty():
  _previous = _snapshot(model)
  return
 if _previous.state==HunterState.State.DORMANT and model.hunter.state!=HunterState.State.DORMANT:
  event("hunter_spawn")
 if model.hunter.level>_previous.level:
  event("hunter_level")
 if model.hunter.attacks>_previous.attacks and model.hunter.target>=0 and model.hunter.target<model.rooms.size() and not _seen(model.hunter.target,"door_damage"):
  event("door_hit",model.rooms[model.hunter.target].door_position())
 var order: Array = []
 if model.player_room>=0:
  order.append(model.player_room)
 for i in range(model.rooms.size()):
  if i != model.player_room:
   order.append(i)
 for index in order:
  var room = model.rooms[index]
  var old = _previous.rooms[index]
  var position = room.center()
  if old.alive and not room.alive and not _seen(index,"elimination"):
   event("elimination",position)
  if room.bed_level>old.bed and not _seen(index,"bed_upgrade"):
   event("bed_upgrade",room.bed_position())
   event("upgrade",position)
  if room.door_level>old.door and not _seen(index,"door_upgrade"):
   event("door_upgrade",room.door_position())
  if room.door_hp<old.hp and not _seen(index,"door_damage"):
   event("door_hit",room.door_position())
   for fraction in [0.66,0.33]:
    if old.hp/old.max_hp>fraction and room.door_hp/room.max_hp()<=fraction:
     event("door_crack",room.door_position())
  elif room.door_hp>old.hp and room.door_level==old.door and not _seen(index,"repair"):
   event("repair",room.door_position())
  if old.hp>0 and room.door_hp<=0 and not _seen(index,"door_break"):
   event("door_break",room.door_position())
   event("breach",room.door_position())
  for tile in room.buildings:
   var b = room.buildings[tile]
   if not old.buildings.has(tile) and not _seen(index,"build"):
    event("build",room.tile_position(tile))
   elif old.buildings.has(tile) and b.level>old.buildings[tile].level and not _seen(index,"building_upgrade"):
    event("turret_upgrade" if b.kind in ["turret","heavy"] else "upgrade",room.tile_position(tile))
  if room.owner==0:
   if int(room.income_total/5)>int(old.income/5):
    event("income",room.bed_position())
   if int(room.electricity/5)>int(old.power/5) or room.electricity<old.power:
    event("electricity",position)
 for combat in model.combat_events:
  if combat.id<=_last_combat_event:
   continue
  _last_combat_event = combat.id
  if combat.type=="launch":
   var shot_cue=WrathAudio.shot_event(str(combat.kind),int(combat.get("level",1)),str(combat.get("specialization","")))
   if shot_cue!="":event(shot_cue,combat.position)
  elif combat.type=="impact":
   event(WrathAudio.impact_event(str(combat.kind)),combat.position)
   if combat.damage>0:
    event("undead_hurt" if int(combat.get("target_id",1))>1 else "reaper_hurt" if model.hunter.transformed else "ghost_hurt",combat.position)
 _previous = _snapshot(model)

func get_diagnostics() -> Dictionary:
 var count = 0
 for voice in voices:
  if voice.playing:
   count += 1
 return {"pacing_gain":pacing_gain,"ambience_gain":ambience_gain,"tension_state":tension_state,"tension_weight":tension_weight,"music_duck":music_duck,"event_counts":event_counts.duplicate(),"music_start_count":music_start_count,"intensity":intensity,"proximity":proximity,"loop_weights":loop_weights.duplicate(),"voices":count,"voice_limit":voices.size(),"frame_voice_limit":FRAME_VOICE_LIMIT,"dropped_events":dropped_events,"mix":mix.duplicate(),"missing_assets":missing_assets.duplicate(),"stream_count":streams.size(),"pending_critical":_pending_critical.size(),"expired_events":expired_events,"crimson_music_starts":crimson_music_starts,"domain_music":_domain_music_active,"pending_evolutions":pending_evolutions.size(),"evolution_cues_played":evolution_cues_played}

func shutdown():
 for player in loops.values()+voices:
  if is_instance_valid(player):
   player.stop()
   player.stream = null
 streams.clear()
 _observed_model = null
 _previous.clear()

func _exit_tree():
 shutdown()

func _queue_critical(name: String, position: Vector2, details: Dictionary = {}):
 var ttl=float(details.get("expires_in",1.0))
 if not is_finite(ttl):ttl=1.0
 var deadline=minf(float(details.get("_audio_deadline",_clock+clampf(ttl,.03,3.0))),_clock+3.0)
 var saved=details.duplicate();saved._audio_deadline=deadline
 for cue in _pending_critical:
  if cue.name==name:
   if bool(details.get("important",false)):
    cue.position=position;cue.details=saved;cue.deadline=deadline
   return
 if _pending_critical.size()<MAX_PENDING_CRITICAL:
  _pending_critical.append({"name":name,"position":position,"deadline":deadline,"details":saved})
 else:dropped_events+=1

func set_suspended(value: bool):
 suspended=value
 for player in loops.values()+voices:
  if is_instance_valid(player): player.stream_paused=value

func _seen(room: int,type: String) -> bool:
 return _seen_presentation.has(str(room)+":"+type)

func _observe_presentation(model):
 _seen_presentation.clear()
 if not "presentation_events" in model: return
 for record in model.presentation_events:
  if int(record.id)<=_last_presentation_event: continue
  _last_presentation_event=int(record.id)
  var room=int(record.room)
  var type=str(record.type)
  var position: Vector2=record.position
  _seen_presentation[str(room)+":"+type]=true
  # Terminal frames keep death/outcome cues but discard obsolete attack warnings.
  if model.result!="" and type in ["boss_transform","boss_warning","boss_surge","boss_ability_warning","boss_ability_activate","boss_phase"]: continue
  if _wrath_presentation(type,record,model,position):continue
  match type:
   "boss_transform": event("reaper_transform")
   "boss_death":
    stop_events(WrathAudio.COMBAT_WARNINGS);event("reaper_death")
   "boss_warning":
    event({"scythe":"reaper_scythe","siege":"reaper_charge","surge":"reaper_surge"}.get(record.get("attack",""),"danger"),position)
   "boss_impact": event("reaper_impact",position)
   "encounter":
    if _clock>=float(_encounter_cooldowns.get(room,-1)) and _clock>=_scream_next and pending_deaths.is_empty() and pending_evolutions.is_empty() and _clock>=_evolution_busy_until and not voices.any(func(v):return v.playing and _voice_names.get(v.get_instance_id(),"") in ["scream_1","scream_2","scream_3","death_scream_1","death_scream_2"]):
     if event("scream_"+str(1+_scream_variation%3),position):
      _scream_variation+=1
      _encounter_cooldowns[room]=_clock+10
      _scream_next=_clock+2.0
      for voice in voices:
       if voice.playing and voice.stream==streams["scream_"+str(1+(_scream_variation-1)%3)]: _scream_voice=voice
   "hunter_ability_warning": event("ghost_hurt",position);event("danger",position)
   "hunter_ability": event("eerie",position)
   "charged_attack": event("ghost_hurt",position);event("danger",position)
   "archetype_warning": event("ghost_hurt",position);event("danger",position)
   "door_damage":
    event("door_hit",position)
    var hp=float(record.get("hp",0))
    var max_hp=maxf(1,float(record.get("max_hp",1)))
    var before=hp+float(record.get("damage",0))
    for fraction in [0.66,0.33]:
     if before/max_hp>fraction and hp/max_hp<=fraction: event("door_crack",position)
   "door_break":
    if model.rooms[room].door_hp>0:continue
    if model.rooms[room].door_hp<=0 and not laughed_rooms.has(room):
     laughed_rooms[room]=true
     pending_laughs.append({"name":"reaper_laugh" if record.get("transformed",model.hunter.transformed) else "hunter_laugh","position":position,"time":_clock})
    event("door_break",position)
    event("breach",position)
    # Door destruction gets its own reaction, but never stacks survivor screams.
    if is_instance_valid(_scream_voice) and _voice_names.get(_scream_voice.get_instance_id(),"") in ["scream_1","scream_2","scream_3"]:_scream_voice.stop()
    event("door_reaction",position)
    _scream_next=_clock+2
   "elimination":
    if model.rooms[room].alive or death_rooms.has(room):continue
    if not model.rooms[room].alive and not death_rooms.has(room):
     death_rooms[room]=true;death_sequence+=1
     stop_events(["hunter_laugh","reaper_laugh"])
     pending_deaths.append({"name":"death_scream_%d" % (1+(death_sequence-1)%2),"position":record.get("survivor_position",model.rooms[room].bed_position()),"room":room})
     event("survivor_notice")
    event("elimination",position)
   "repair": event("repair",position)
   "build": event("build",position)
   "building_upgrade": event("prestige_upgrade" if record.get("level",0)==10 else "turret_upgrade" if record.get("kind","") in ["turret","heavy"] else "upgrade",position)
   "bed_upgrade": event("bed_upgrade",position)
   "door_upgrade": event("door_upgrade",position)
   "sale":
    event("sale",position)
    event("refund",position)

func set_tension(state: String,weight: float):
 tension_state=state
 tension_weight=clampf(weight,0,1) if is_finite(weight) else 0.0

func update_environment(environment):
 if environment!=environment_ref:
  environment_ref=environment;environment_serial=0
 for cue in environment.weather_events:
  if cue.id<=environment_serial:continue
  environment_serial=cue.id
  var critical_playing=voices.any(func(v):return v.playing and _voice_names.get(v.get_instance_id(),"") in CRITICAL_EVENTS and _voice_names.get(v.get_instance_id(),"") not in ["intro_running","intro_breath"])
  if not critical_playing and tension_state not in ["danger","elimination"]:event(cue.cue,listener_position)

func _play_death_queue():
 # Real death vocals finish before their evolution sting; no expiring generic
 # warning queue is used for these bounded, once-per-victim reactions.
 if voices.any(func(v):return v.playing and _voice_names.get(v.get_instance_id(),"").begins_with("death_scream")):return
 if _clock<_evolution_busy_until:return
 if _last_death_room>=0:
  for i in range(pending_evolutions.size()):
   if int(pending_evolutions[i].room)==_last_death_room:
    if _start_evolution(i):_last_death_room=-1
    return
  _last_death_room=-1
 if pending_deaths.is_empty():
  if not pending_evolutions.is_empty():_start_evolution(0)
  return
 var cue=pending_deaths[0]
 if _frame_voices>=FRAME_VOICE_LIMIT or _clock<float(_cooldowns.get(cue.name,-1)):return
 if not voices.any(func(v):return not v.playing or not bool(_voice_priority.get(v.get_instance_id(),_voice_names.get(v.get_instance_id(),"") in CRITICAL_EVENTS))):return
 stop_events(["scream_1","scream_2","scream_3"])
 if event(cue.name,cue.position):
  pending_deaths.pop_front();_last_death_room=int(cue.get("room",-1))

func _start_evolution(index: int) -> bool:
 if index<0 or index>=pending_evolutions.size() or _frame_voices>FRAME_VOICE_LIMIT-2:return false
 var cue=pending_evolutions[index];var category="buff_"+str(cue.category)
 if _clock<float(_cooldowns.get("hunter_evolve",-1)) or _clock<float(_cooldowns.get(category,-1)):return false
 var available=voices.filter(func(v):return not v.playing or not bool(_voice_priority.get(v.get_instance_id(),false))).size()
 if available<2:return false
 if not event("hunter_evolve",cue.position):return false
 event(category,cue.position)
 pending_evolutions.remove_at(index);evolution_cues_played+=1
 _evolution_busy_until=_clock+maxf(streams.hunter_evolve.get_length(),streams[category].get_length())+.05
 return true

func _wrath_presentation(type: String, record: Dictionary, model, position: Vector2) -> bool:
 var important=int(record.get("room",-1))==model.player_room
 var context={"important":important,"expires_in":1.0}
 match type:
  "hunter_evolved":
   var victim=int(record.get("victim_room",record.get("room",-1)))
   if victim<0 or victim>=Catalog.SURVIVOR_NAMES.size() or _evolved_rooms.has(victim):return true
   _evolved_rooms[victim]=true
   var category=WrathAudio.BUFF_CATEGORY.get(str(record.get("buff_id","")),"offense")
   if pending_evolutions.size()<Catalog.SURVIVOR_NAMES.size():pending_evolutions.append({"room":victim,"category":category,"position":position})
  "boss_phase":
   if int(record.get("phase",1))==2 and model.hunter.hp>0:event("reaper_phase_2",position)
  "boss_ability_warning":
   if model.hunter.hp<=0:return true
   context={"expires_in":maxf(.03,float(record.get("delay",1.0)))}
   var cue="wrath_warning_"+str(record.get("ability",""))
   if cue in EFFECT_NAMES:event(cue,position,context)
  "boss_ability_activate":
   var ability=str(record.get("ability",""));stop_events(["wrath_warning_"+ability])
   var cue="wrath_activate_"+ability
   if model.hunter.hp>0 and cue in EFFECT_NAMES:event(cue,position)
  "boss_ability_end":
   var ability=str(record.get("ability",""));stop_events(["wrath_warning_"+ability,"wrath_activate_"+ability])
   if ability in ["rules_judgement","final_judgement"]:event("lock_release",position)
  "undead_spawn","undead_attack","undead_death":
   event(type+"_enhanced" if type=="undead_spawn" and bool(record.get("enhanced",false)) else type,record.get("entity_position",position),{"important":false})
  "scythe_throw","scythe_embed","scythe_tick","scythe_end":event(type,position)
  "magic_shield","magic_absorb":event("shield_absorb",position,{"important":false})
  "magic_reflect":event("impact_shock",position,{"important":false})
  "plasma_release":event("auto_repair_activate",position,{"important":false})
  "nightmare_level":
   if int(record.get("level",1)) in [4,7]:event("hunter_evolve",position)
  "nightmare_rebirth":event("nightmare_rebirth",Vector2.INF,{"important":true})
  "nightmare_warning":
   var cue={"crusher":"hunter_charged_warning","stalker":"hunter_stalker_warning","ravager":"hunter_ravager_warning","witch":"reaper_charge","electric":"hunter_charged_warning","storm":"reaper_charge"}.get(model.hunter.archetype,"danger")
   event(cue,position,{"expires_in":float(record.get("delay",2.0))})
  "nightmare_release":
   var cue={"crusher":"reaper_impact","stalker":"hunter_stalker_feint","ravager":"hunter_ravager_dash","witch":"shot_frost","electric":"shot_shock","storm":"weather_thunder"}.get(model.hunter.archetype,"impact")
   event(cue,position)
  "nightmare_impact":event("impact_shock" if record.get("element","")=="electric" else "impact_frost" if record.get("element","")=="ice" else "door_crack",position,{"important":false})
  "nightmare_cancel":event("lock_release",position)
  "arcane_impact":event("impact_frost" if record.get("element","")=="ice" else "impact_shock",position,{"important":false})
  "shield_absorb":event("shield_absorb",position,{"important":false})
  "defense_activate":
   var cue={"shield":"shield_activate","auto_repair":"auto_repair_activate","decoy":"decoy_activate","generator":"generator_activate"}.get(str(record.get("kind","")),"")
   if cue!="":event(cue,position,context)
  "hunter_ability_warning":
   var cue={"pressure":"hunter_crusher_warning","conceal":"hunter_stalker_warning","dash":"hunter_ravager_warning","cursed_projectile":"hunter_stalker_warning","interference":"hunter_ravager_warning","chain_lightning":"hunter_crusher_warning","soul_drain":"reaper_charge","shadow_dash":"hunter_ravager_warning"}.get(str(record.get("ability","")),"danger")
   event(cue,position,{"expires_in":maxf(.03,float(record.get("delay",1.0)))})
  "hunter_ability":
   var cue={"pressure":"hunter_crusher_pressure","conceal":"hunter_stalker_conceal","feint":"hunter_stalker_feint","dash":"hunter_ravager_dash","cursed_projectile":"shot_frost","interference":"shot_shock","chain_lightning":"shot_arc","soul_drain":"reaper_surge","shadow_dash":"hunter_ravager_dash"}.get(str(record.get("ability","")),"danger")
   event(cue,position)
  "archetype_warning":
   var identity=str(record.get("archetype",model.hunter.archetype))
   var cue="hunter_"+str({"witch":"stalker","electric":"ravager","storm":"crusher"}.get(identity,identity))+"_warning"
   if cue in EFFECT_NAMES:event(cue,position,{"expires_in":maxf(.03,float(record.get("delay",1.0)))})
  "charged_attack":event("hunter_charged_warning",position,{"expires_in":maxf(.03,float(record.get("delay",1.0)))})
  "build":
   var cue="build_"+str(record.get("kind",""))
   if cue not in EFFECT_NAMES:return false
   event(cue,position,context)
  "building_upgrade":
   if int(record.get("level",0))==5 and str(record.get("specialization",""))!="":event("branch_select",position,context)
   else:return false
  _:return false
 return true
