class_name AudioDirector
extends Node

const ROOT = "res://assets/audio/"
const LOOP_NAMES = ["music_menu","music_calm","music_danger","ambient_dorm","proximity_loop","generator_loop","music_reaper","reaper_ambience"]
const EFFECT_NAMES = ["intro_running","intro_breath","intro_lightning","intro_impact","intro_shriek","intro_whisper","tutorial_step","tutorial_complete","shop_purchase","perk_unlocked","achievement_unlocked","achievement_claim","difficult_stage","stage_bonus_selected","mythic_perk","button","menu","match_start","purchase","failure","rank","reward","victory","defeat","shot_needle","shot_arc","impact","ghost_hurt","ghost_defeat","door_hit","door_crack","door_break","build","turret_upgrade","bed_upgrade","door_upgrade","repair","upgrade","income","electricity","footstep","danger","breach","hunter_spawn","hunter_level","elimination","scream_1","scream_2","scream_3","door_reaction","sale","refund","insufficient_gold","insufficient_power","eerie","reaper_transform","reaper_scythe","reaper_charge","reaper_surge","reaper_impact","reaper_hurt","reaper_death","mythic_promotion","item_time_freeze","item_reaper_seal","item_guardian_heart","item_cursed_fortune","item_legendary_reveal","item_barricade","item_feather","item_inferno","item_pillow","item_coupon","item_decoy","item_rescue","item_smoke","item_repair","item_gold","item_battery","item_radar","item_shield","item_overdrive","item_frost","item_trap","item_reveal","item_end","item_explosion","item_shield_hit"]
const CRITICAL_EVENTS = ["intro_running","intro_breath","intro_lightning","intro_impact","intro_shriek","intro_whisper","tutorial_step","tutorial_complete","shop_purchase","perk_unlocked","achievement_unlocked","achievement_claim","difficult_stage","stage_bonus_selected","mythic_perk","victory","defeat","ghost_defeat","rank","reward","hunter_level","breach","door_break","match_start","door_reaction","sale","refund","reaper_transform","reaper_charge","reaper_surge","reaper_death","mythic_promotion","item_time_freeze","item_reaper_seal","item_guardian_heart","item_cursed_fortune","item_legendary_reveal","item_barricade","item_feather","item_inferno","item_pillow","item_coupon","item_decoy","item_rescue","item_smoke","item_repair","item_gold","item_battery","item_radar","item_shield","item_overdrive","item_frost","item_trap","item_reveal","item_explosion"]
const VOICE_LIMIT = 16
const FRAME_VOICE_LIMIT = 6
const EFFECT_COOLDOWNS = {"reaper_transform":4.0,"reaper_scythe":0.7,"reaper_charge":1.8,"reaper_surge":1.5,"reaper_impact":0.5,"reaper_hurt":0.35,"reaper_death":4.0,"scream_1":2.0,"scream_2":2.0,"scream_3":2.0,"door_reaction":2.0,"sale":0.15,"refund":0.15,"insufficient_gold":0.4,"insufficient_power":0.4,"eerie":12.0,"shot_needle":0.07,"shot_arc":0.11,"impact":0.09,"ghost_hurt":0.22,"door_hit":0.12,"door_crack":0.8,"door_break":1.0,"income":1.1,"electricity":1.0,"repair":1.0,"footstep":0.38,"danger":3.0,"build":0.15,"upgrade":0.18,"hunter_level":0.5,"hunter_spawn":1.0,"match_start":0.8,"victory":2.0,"defeat":2.0,"rank":0.8,"reward":0.4,"menu":0.2}
var mobile_profile=false
var suspended=false
var event_counts: Dictionary = {}
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
var _last_presentation_event=0
var _encounter_cooldowns: Dictionary={}
var music_duck=1.0
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
  if name in LOOP_NAMES:
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

func event(name: String, position: Vector2 = Vector2.INF) -> bool:
 setup()
 var aliases = {"menu_open":"menu","menu_navigation":"menu","button_click":"button","rank_promotion":"rank","reward_unlock":"reward","insufficient":"failure","outcome":"victory","generator":"electricity"}
 name = aliases.get(name,name)
 if not streams.has(name) or name in LOOP_NAMES:
  if not EFFECT_NAMES.has(name):
   push_warning("Unknown Nightfall audio event: "+name)
  return false
 var critical = name in CRITICAL_EVENTS
 if _clock < float(_cooldowns.get(name,-1.0)):
  return false
 if _frame_voices >= (FRAME_VOICE_LIMIT if critical else FRAME_VOICE_LIMIT-2):
  if critical:
   _queue_critical(name,position)
  else:
   dropped_events += 1
  return false
 var distance_gain = 1.0
 if position.is_finite():
  var distance = listener_position.distance_to(position)
  if distance > hearing_radius:
   return false
  distance_gain = clampf(1.0-distance/(hearing_radius/0.85),0.15,1.0)
 var free_voice = null
 for voice in voices:
  if not voice.playing:
   free_voice = voice
   break
 if free_voice == null and critical:
  for voice in voices:
   if not _voice_names.get(voice.get_instance_id(),"") in CRITICAL_EVENTS:
    voice.stop()
    free_voice = voice
    break
 if free_voice == null:
  if critical:
   _queue_critical(name,position)
  else:
   dropped_events += 1
  return false
 _voice_names[free_voice.get_instance_id()] = name
 free_voice.global_position=(position if position.is_finite() else listener_position)+Vector2(145,40)
 free_voice.stream = streams[name]
 free_voice.volume_db = linear_to_db(distance_gain)-20.0
 free_voice.pitch_scale = 1.0
 free_voice.play()
 _cooldowns[name] = _clock+float(EFFECT_COOLDOWNS.get(name,0.08))
 event_counts[name] = int(event_counts.get(name,0))+1
 _frame_voices += 1
 return true

func reset_match(model):
 setup()
 _observed_model = model
 _last_combat_event = 0
 _last_presentation_event=0
 _encounter_cooldowns.clear()
 _scream_next=0
 _scream_voice=null
 _next_eerie=_clock+12
 _previous_time = model.time
 _previous_hunter_position = model.hunter.position
 _previous = _snapshot(model)
 # Match-specific throttles must not suppress cues after a restart.
 _cooldowns.clear()
 _pending_critical.clear()
 _frame_voices = 0
 for voice in voices:
  voice.stop()

func stop_events(names: Array):
 _pending_critical=_pending_critical.filter(func(cue):return cue.name not in names)
 for voice in voices:
  if _voice_names.get(voice.get_instance_id(),"") in names:voice.stop()

func update_state(delta: float, model, mode: String):
 if suspended: return
 setup()
 if not is_finite(delta) or delta < 0:
  return
 _clock += delta
 _frame_voices = 0
 _mode = mode
 var pending = _pending_critical.duplicate()
 _pending_critical.clear()
 for cue in pending:
  event(cue.name,cue.position)
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
   event("reaper_death" if model.hunter.transformed else "ghost_defeat")
   _previous.state = HunterState.State.DEAD
   _previous.hp = model.hunter.hp
  var room = model.player()
  listener_position = room.bed_position() if room != null else model.player_position
  hearing_radius=maxf(850.0,model.map_bounds().size.length()) if model.map_id!="legacy" else 850.0
  if mode in ["match","result"]:
   _observe_presentation(model)
  if active:
   _observe(model)
   if model.running and _clock>=_next_eerie:
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
 var targets = {"music_menu":1.0 if mode=="menu" else 0.0,"music_calm":(1.0-intensity)*0.85 if music_active and not boss_active else 0.0,"music_danger":intensity*0.85 if music_active and not boss_active else 0.0,"ambient_dorm":0.35+proximity*0.30 if active else 0.15 if mode=="menu" else 0.0,"proximity_loop":proximity*intensity*0.65 if active else 0.0,"generator_loop":generator_weight if active else 0.0}
 targets["music_reaper"]=0.85 if boss_active else 0.0
 var critical_active=voices.any(func(v):return v.playing and _voice_names.get(v.get_instance_id(),"") in CRITICAL_EVENTS)
 music_duck=move_toward(music_duck,.48 if critical_active else 1.0,delta*3.0)
 targets["reaper_ambience"]=proximity*0.55 if boss_active else 0.0
 for name in loops:
  loop_weights[name] = move_toward(float(loop_weights[name]),float(targets[name]),delta*1.1)
  var music_gain=(.55 if mode=="match" else .85)*music_duck if name.begins_with("music") else 1.0
  loops[name].volume_db = linear_to_db(maxf(0.0001,loop_weights[name]*music_gain))-12.0
 # Outcomes may be supplied explicitly by the host, too; cooldown prevents repeats.
 if model != null and model.result != "" and _previous.get("result","") != model.result:
  _pending_critical=_pending_critical.filter(func(cue): return cue.name not in ["reaper_transform","reaper_charge","reaper_surge"])
  for voice in voices:
   if _voice_names.get(voice.get_instance_id(),"") in ["reaper_transform","reaper_charge","reaper_surge","reaper_scythe"]: voice.stop()
  event("victory" if model.result=="victory" else "defeat")
  _previous.result = model.result

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
   event("shot_arc" if combat.kind=="heavy" else "shot_needle",combat.position)
  elif combat.type=="impact":
   event("impact",combat.position)
   if combat.damage>0:
    event("reaper_hurt" if model.hunter.transformed else "ghost_hurt",combat.position)
 _previous = _snapshot(model)

func get_diagnostics() -> Dictionary:
 var count = 0
 for voice in voices:
  if voice.playing:
   count += 1
 return {"event_counts":event_counts.duplicate(),"music_start_count":music_start_count,"intensity":intensity,"proximity":proximity,"loop_weights":loop_weights.duplicate(),"voices":count,"voice_limit":voices.size(),"frame_voice_limit":FRAME_VOICE_LIMIT,"dropped_events":dropped_events,"mix":mix.duplicate(),"missing_assets":missing_assets.duplicate(),"stream_count":streams.size(),"pending_critical":_pending_critical.size()}

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

func _queue_critical(name: String, position: Vector2):
 for cue in _pending_critical:
  if cue.name==name:
   return
 if _pending_critical.size()<CRITICAL_EVENTS.size():
  _pending_critical.append({"name":name,"position":position})

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
  if model.result!="" and type in ["boss_transform","boss_warning","boss_surge"]: continue
  match type:
   "boss_transform": event("reaper_transform")
   "boss_death": event("reaper_death")
   "boss_warning":
    event({"scythe":"reaper_scythe","siege":"reaper_charge","surge":"reaper_surge"}.get(record.get("attack",""),"danger"),position)
   "boss_impact": event("reaper_impact",position)
   "encounter":
    if _clock>=float(_encounter_cooldowns.get(room,-1)) and _clock>=_scream_next and (not is_instance_valid(_scream_voice) or not _scream_voice.playing):
     if event("scream_"+str(1+_scream_variation%3),position):
      _scream_variation+=1
      _encounter_cooldowns[room]=_clock+10
      _scream_next=_clock+2.0
      for voice in voices:
       if voice.playing and voice.stream==streams["scream_"+str(1+(_scream_variation-1)%3)]: _scream_voice=voice
   "charged_attack": event("danger",position)
   "door_damage":
    event("door_hit",position)
    var hp=float(record.get("hp",0))
    var max_hp=maxf(1,float(record.get("max_hp",1)))
    var before=hp+float(record.get("damage",0))
    for fraction in [0.66,0.33]:
     if before/max_hp>fraction and hp/max_hp<=fraction: event("door_crack",position)
   "door_break":
    event("door_break",position)
    event("breach",position)
    # Door destruction gets its own reaction, but never stacks survivor screams.
    if is_instance_valid(_scream_voice): _scream_voice.stop()
    event("door_reaction",position)
    _scream_next=_clock+2
   "elimination": event("elimination",position)
   "repair": event("repair",position)
   "build": event("build",position)
   "building_upgrade": event("turret_upgrade" if record.get("kind","") in ["turret","heavy"] else "upgrade",position)
   "bed_upgrade": event("bed_upgrade",position)
   "door_upgrade": event("door_upgrade",position)
   "sale":
    event("sale",position)
    event("refund",position)
