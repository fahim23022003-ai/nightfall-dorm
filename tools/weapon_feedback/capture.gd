extends "res://tools/phase16/measure_dense_active.gd"
## Native render evidence. A prepared siege makes overlapping weapon fire reproducible.

const BRANCHES := {"turret":"precision","heavy":"storm","flame":"wildfire","frost":"deep_chill","shock":"rapid_discharge"}
var trace: Array = []
var traces_by_id: Dictionary = {}
var flight_frames: Dictionary = {}
var notes: Dictionary = {}

func run() -> void:
 var args := OS.get_cmdline_user_args()
 if args.size()!=5 or not args[0].is_absolute_path() or not args[1] in ["medium","low"] or not int(args[2]) in [1,10,24,40,60] or not args[3] in ["needle","mixed","reaper","shield","cancel","ally"] or not args[4] in ["film","bench"]:
  push_error("Pass an absolute output path, medium/low, 1/10/24/40/60, needle/mixed/reaper/shield/cancel/ally, film/bench.")
  quit(2)
  return
 if DisplayServer.get_name()=="headless":
  push_error("This evidence requires a real viewport.")
  quit(2)
  return
 var destination:=args[0]
 var density:=int(args[2])
 var fixture:=args[3]
 var film:=args[4]=="film"
 phase=destination.get_file()
 output=destination.get_base_dir()+"/"
 DirAccess.make_dir_recursive_absolute(destination)
 root.size=STANDARD_VIEW_SIZE
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 Engine.max_fps=0
 await setup_game()
 game.onboarding.close_welcome()
 game.change_setting("graphics_quality",args[1])
 var model:=MatchModel.new()
 model.reset(MATCH_SEED)
 check(model.configure_match("hell") and model.configure_stage(DENSE_STAGE) and model.configure_balance(),"Real authored V2 campaign")
 check(model.configure_strategy(MATCH_SEED,"stalker"),"Selected existing Stalker")
 game._adopt_session(model)
 game.set_process(false)
 var room:=_weapons_room(model,density,fixture,film)
 if room==null or failures>0:
  await _finish()
  return
 _prepare_encounter(model,room,fixture=="reaper")
 model._cancel_projectiles("fixture_start")
 model.combat_events.clear()
 if fixture=="ally":
  var ally: RoomState=model.rooms[(room.index+1)%model.rooms.size()]
  ally.gold=1000.0
  ally.door_level=5;ally.door_hp=ally.max_hp()
  var slots: Array=range(ally.tile_count())
  slots.sort_custom(func(a,b):return ally.tile_position(a).distance_squared_to(ally.door_approach())<ally.tile_position(b).distance_squared_to(ally.door_approach()))
  check(ally.build("turret",slots[0]),"NPC room buys a real doorway turret")
  model.hunter.position=ally.door_approach();model.hunter.target=ally.index
  model.hunter.siege_start_hp=ally.door_hp
  check(game.spectate_room(ally.index),"Open real teammate view")
  game.focus_camera(true)
 if fixture=="shield":
  model.evolution.shield=35.0
  model.evolution.shield_remaining=5.0
 if fixture=="cancel":
  model.spawn_undead(1)
  var undead: UndeadAgent=model.minions[0]
  undead.position=room.door_approach()-room.door_normal()*8.0
  undead.hp=1.0
  undead.speed=0.0
  model.hunter.position+=room.door_normal()*50.0
  model.hunter.state=HunterState.State.MOVE
 if film and model.weapon_feedback.enabled:
  model.weapon_feedback.received.connect(_trace_event)
 _save_view(destination,"start")
 await _render_frame()
 check(root.get_texture().get_image().get_size()==STANDARD_VIEW_SIZE,"Rendered native viewport")
 if fixture!="ally":check(_visible_building_centers(room)==density,"All paid machine centers on-screen")
 var initial:=_gameplay_digest(model)
 var samples: Dictionary
 if film:samples=await _film(model,destination,fixture)
 else:samples=await _measure_native(model)
 check(samples.shots>0 and samples.hunter_hp_delta<0,"Actual weapons hit enemy during active sample")
 check(model.result.is_empty(),"Active combat survived the test window")
 if film and model.weapon_feedback.enabled:
  check(trace.any(func(event):return event.type=="impact" and event.damage>0),"Weapon hit reached presentation")
  check(flight_frames.values().any(func(data):return data.size()>=2),"A single projectile appeared across multiple real rendered frames")
  if fixture=="shield":check(trace.any(func(event):return event.type=="impact" and event.reason=="blocked" and event.damage==0),"Real shield stops a projectile")
  if fixture=="cancel":check(trace.any(func(event):return event.type=="cancel"),"A target dies while another shot is in flight")
  if fixture=="ally":check(trace.any(func(event):return event.type=="impact" and event.room!=model.player_room and event.damage>0),"Allied machine owns its real visible contribution")
  if fixture=="mixed":
   for kind in DefenseEffects.WEAPONS:
    check(trace.any(func(event):return event.type=="impact" and event.kind==kind and event.damage>0),"Visible actual impact of "+kind)
   check(trace.any(func(event):return event.type=="burn" and event.damage>0),"Live burn is separately reported")
 _save_view(destination,"final")
 var receipt:=FileAccess.open(destination.path_join("receipt.json"),FileAccess.WRITE)
 if receipt!=null:
  receipt.store_string(JSON.stringify({"quality":args[1],"fixture":fixture,"density":density,"weapon_feedback":model.weapon_feedback.enabled,"renderer":RenderingServer.get_video_adapter_name(),"geometry_sha256":JSON.stringify(NightmareMap.pack(model.map_data),"",true,true).sha256_text(),"gameplay_initial_sha256":initial,"timing":samples,"static_memory_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),"video_memory_bytes":int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),"notes":notes,"trace":trace,"flight_frames":flight_frames,"checks":checks,"failures":failures},"  ",true,true)+"\n")
 await _finish()

func _weapons_room(model: MatchModel, density: int, fixture: String, film: bool) -> RoomState:
 var greatest:=0.0
 var index:=0
 for candidate: RoomState in model.rooms:
  var area:=0.0
  for strip: Rect2 in candidate.layout.floor:area+=strip.get_area()
  if not candidate.layout.voids.is_empty() and area>greatest:
   index=candidate.index
   greatest=area
 if film and fixture=="mixed":index=4 # Door reach permits all five distinct weapons in this layout.
 check(model.claim_room(index),"Claim real irregular room")
 var room:=model.player()
 if room==null:return null
 model.player_position=room.bed_position()
 check(model.sleep_player() and room.spatial.grid,"Sleep and use real Full Room Grid")
 room.gold=500000.0;room.electricity=500000.0;room.bed_level=6;room.door_level=6;room.door_hp=room.max_hp()
 var first := room.door_approach()-room.door_normal()*106.0
 var kinds: Array=["turret"] if fixture in ["needle","shield","ally"] else ["shock","flame","frost","heavy","turret"]
 for kind: String in kinds:
  var placement: Vector2=room.door_approach() if kind in ["shock","flame","frost"] else first
  var placed:=_grid_placement(model,kind,placement)
  check(placed>=0,"Legal paid layout includes "+kind)
  if fixture in ["mixed","reaper"] and placed>=0 and kind in ["heavy","turret"]:
   for level in range(2,5):check(model.upgrade_building(placed),"Pay for specialized weapon prerequisite")
   check(model.specialize_building(placed,BRANCHES[kind]),"Paid existing specialization")
 while room.buildings.size()<density:
  var kind := "decoy" if room.buildings.size()>40 else "frost" if room.buildings.size()%3==0 else "turret"
  if _grid_placement(model,kind,room.door_approach())<0:break
 check(room.buildings.size()==density,"Reach exact legal density")
 if film:
  notes.mounts=[]
  for tile in room.buildings:
   var mount: Dictionary=room.buildings[tile]
   notes.mounts.append({"id":tile,"kind":mount.kind,"point":room.tile_position(tile),"door_distance":room.tile_position(tile).distance_to(room.door_approach())})
 return room

func _gameplay_digest(model: MatchModel) -> String:
 var rooms:=[]
 for room: RoomState in model.rooms:
  rooms.append([room.owner,room.alive,room.door_hp,room.gold,room.electricity,room.buildings,room.damage_dealt])
 var projectiles:=[]
 for shot: Dictionary in model.projectiles:
  projectiles.append([shot.id,shot.position,shot.damage,shot.target_id,shot.age])
 var history:=[]
 for e: Dictionary in model.combat_events:history.append([e.id,e.type,e.projectile_id,e.target_id,e.position,e.damage,e.time])
 return JSON.stringify([model.time,model.random.state,model.shots,model.hunter.hp,model.hunter.state,model.hunter.position,model.hunter.cooldown,rooms,projectiles,history],"",true,true).sha256_text()

func _save_view(destination: String, title: String) -> void:
 var frame:=root.get_texture().get_image()
 if not frame.is_empty():check(frame.save_png(destination.path_join(title+"-720.png"))==OK,"Saved real "+title+" frame")

func _trace_event(event: Dictionary) -> void:
 if event.type!="launch" and event.type!="cancel":
  check(is_equal_approx(event.damage,event.hp_before-event.hp_after),"Damage receipt equals before minus after")
 var entry := event.duplicate()
 if event.type=="launch":
  entry.visual_muzzle=game.presentation.weapons.muzzle(game,game.presentation.building_visual,event)
  traces_by_id[event.projectile_id]=event
 elif event.type=="impact" or event.type=="cancel":
  var launch: Dictionary=traces_by_id.get(event.projectile_id,{})
  check(not launch.is_empty() and event.building_id==launch.building_id and event.building_instance_id==launch.building_instance_id and event.target_id==launch.target_id and event.origin==launch.origin,"Resolve exact launched projectile and paid machine")
 trace.append(entry)

func _film(model: MatchModel,destination: String,fixture: String) -> Dictionary:
 var old_hp: float=model.hunter.hp
 var start_shots: int=model.shots
 var damage_frame:=false
 var flight_frame:=false
 var shield_frame:=false
 var inspector:=fixture=="needle"
 for frame: int in range(192):
  if frame==112 and inspector:
   game.selected_tile=model.player().buildings.keys()[0]
   game.ui.open_context()
  if frame==125 and fixture=="mixed":
   game.zoom_factor=.73
   game.focus_camera(true)
  game._process(COMBAT_STEP)
  await RenderingServer.frame_post_draw
  for shot: Dictionary in model.projectiles:
   if not game.presentation.weapons.flight_seen.has(shot.id):continue
   if not flight_frames.has(shot.id):flight_frames[shot.id]=[]
   flight_frames[shot.id].append({"frame":frame,"model":shot.position,"visual":game.presentation.weapons.projectile_point(game,game.presentation.building_visual,shot,model.target_by_id(shot.target_id).position)})
   if not flight_frame:
    _save_view(destination,"flight")
    flight_frame=true
  for number: Dictionary in game.presentation.weapons.numbers:
   if not damage_frame and number.amount>0 and number.has("label"):
    notes.damage_label={"frame":frame,"label":number.label,"raw_total":number.amount,"hunter_hp":model.hunter.hp,"hud":game.ui.hunter_label.text}
    _save_view(destination,"hit")
    damage_frame=true
   if fixture=="shield" and not shield_frame and number.marker=="blocked" and number.has("label"):
    notes.block_label=number.label
    _save_view(destination,"blocked")
    shield_frame=true
 if inspector:
  notes.inspector=game.ui.selected_details.text
  check(notes.inspector.contains("Total") and notes.inspector.contains("hits") and not notes.inspector.contains("0 HP · 0 hits"),"Real live inspector reports actual contribution")
 notes.audio=game.audio_system.get_diagnostics().event_counts
 if model.weapon_feedback.enabled:check(damage_frame,"Read the same visible damage label that was drawn on screen")
 return {"shots":model.shots-start_shots,"hunter_hp_delta":model.hunter.hp-old_hp,"gameplay_sha256":_gameplay_digest(model)}
