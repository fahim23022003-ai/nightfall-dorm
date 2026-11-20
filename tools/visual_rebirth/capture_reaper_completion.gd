extends "res://tools/capture_visual_rebirth.gd"
## Four legal door orientations, both forms, real ability releases, and death.

const VIEW_HEADINGS := {"front": Vector2.DOWN, "back": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT}
const FIXTURE_SEEDS := [67, 10358, 44, 88, 129, 12336, 91, 317]
const ArticulatedHunterScript=preload("res://scripts/articulated_hunter.gd")
const ACTIVE_ABILITIES := [
 "summon", "scythe_slash", "soul_steal", "rules_judgement", "assault",
 "enhanced_undead", "soul_reaper", "phantom_scream", "final_judgement", "crimson_execution",
]

var destination: String
var save_frames := true
var movie_capture := false
var selected_quality: String
var receipt := {}
var reaper_visual

func run():
 var args := OS.get_cmdline_user_args()
 if args.size()<2 or not args[0].is_absolute_path() or args[1] not in ["medium","low"]:
  push_error("Pass an absolute output directory, medium or low, then optional verification flags.")
  quit(2)
  return
 destination=args[0].trim_suffix("/")
 selected_quality=args[1]
 movie_capture="--movie" in args
 save_frames="--verify-only" not in args and not movie_capture
 output=destination.get_base_dir()+"/"
 phase=destination.get_file()
 DirAccess.make_dir_recursive_absolute(destination)
 root.size=Vector2i(1280,720)
 await setup_game()
 game.onboarding.close_welcome()
 game.change_setting("graphics_quality",selected_quality)
 game.audio_system.set_mix({"music_mode":"classic","music":.4,"effects":.86,"ambient":.32})
 game.set_process(false)
 reaper_visual=game.presentation.boss_presentation
 check(reaper_visual.articulated.enabled and reaper_visual.preview_enabled,"native articulated Reaper preview")
 for view: String in VIEW_HEADINGS:
  if "--abilities-only" not in args and "--supplemental-only" not in args:
   receipt[view]=await direction_run(view)
 if "--abilities-only" not in args and "--supplemental-only" not in args:
  for form in ["approach","transformed"]:
   receipt["turn_"+form]=await turning_run(form)
 if "--directions-only" not in args and "--supplemental-only" not in args:
  for ability: String in ACTIVE_ABILITIES:
   receipt[ability]=await ability_run(ability)
 if "--supplemental-only" in args:
  for action in ["siege","surge","shadow_dash","soul_drain"]:
   receipt[action]=await supplemental_run(action)
  receipt.approach_death=await approach_death_run()
 var file:=FileAccess.open(destination.path_join("reaper-completion.json"),FileAccess.WRITE)
 check(file!=null,"write native Reaper receipt")
 if file!=null:
  file.store_string(JSON.stringify({"quality":selected_quality,"fps":24,"viewport":[1280,720],"fixture":receipt,"checks":checks,"failures":failures},"  ")+"\n")
  file.close()
 await _finish()

func find_room(view: String) -> Dictionary:
 for seed: int in FIXTURE_SEEDS:
  var model:=MatchModel.new()
  model.procedural_v2_requested=true
  model.reset(seed)
  if not model.configure_match("hell") or not model.configure_stage("stage_5") or not model.configure_strategy(seed,"crusher") or not model.configure_balance():
   continue
  for room: RoomState in model.rooms:
   if room.door_normal()!=-Vector2(VIEW_HEADINGS[view]):
    continue
   var approach:=room.door_approach()
   var start:=approach+room.door_normal()*80.0
   if model._visible(start,approach):
    return {"model":model, "room":room, "origin":start, "seed":seed}
 return {}

func adopt(fixture: Dictionary):
 var model: MatchModel=fixture.model
 var room: RoomState=fixture.room
 check(model.claim_room(room.index),"claim seeded Reaper fixture room")
 model.player_position=room.bed_position()
 check(model.sleep_player(),"ordinary bed lock for the fixture")
 room.door_level=5
 room.door_hp=room.max_hp()
 model.time=model.preparation+16.0
 model.bot_claimed=5
 var h:=model.hunter
 h.position=fixture.origin
 h.target=room.index
 h.state=HunterState.State.MOVE
 h.cooldown=1.0
 h.arcane.cooldown=999.0
 h.nightmare.cooldown=999.0
 h.boss_cooldowns.siege=999.0
 h.boss_cooldowns.surge=999.0
 model.wrath.recovery=999.0
 game._adopt_session(model)
 game.full_map=false
 game.focus_camera(true)

func grab(name: String, frame: int):
 if movie_capture:
  game.queue_redraw()
  if is_instance_valid(game.ui.horror_layer):
   game.ui.horror_layer.queue_redraw()
  await RenderingServer.frame_post_draw
  await process_frame
  return
 await _render_frame()
 if not save_frames:
  return
 var folder:=destination.path_join(name)
 DirAccess.make_dir_recursive_absolute(folder)
 var rendered:=root.get_texture().get_image()
 check(rendered.get_size()==Vector2i(1280,720) and rendered.save_jpg(folder.path_join("%04d.jpg"%frame),.92)==OK,"save native Reaper frame")

func pose_record() -> Dictionary:
 var rig=reaper_visual.articulated
 return {"pose":rig.pose_name,"art":rig.last_asset,"view":rig.view_name,"weapon":rig.weapon_grip.is_finite()}

func live_event(model: MatchModel, type: String, source: String="") -> Dictionary:
 for index in range(model.presentation_events.size()-1,-1,-1):
  var event: Dictionary=model.presentation_events[index]
  if event.type==type and (source.is_empty() or event.get("source",event.get("ability",event.get("attack","")))==source):
   return event
 return {}

func render_death(model: MatchModel, family: String, first_frame: int) -> Dictionary:
 var h:=model.hunter
 # Prior phase guards have elapsed in this death fixture. The ordinary
 # incoming damage service delivers the finishing hit and records death.
 h.phase2_guard_used=true
 h.final_guard_used=true
 h.phase_guard_remaining=0.0
 var damage:=model.apply_target_damage(1,h.hp,model.player_room,DamageRules.weapon("turret"))
 var death:=live_event(model,"boss_death")
 check(damage>0.0 and h.state==HunterState.State.DEAD and not death.is_empty(),"existing boss lethal hit recorded")
 var witness:=[]
 for index in range(39):
  # Keep the gameplay viewport exposed long enough to inspect the fade.
  # The real result panel would otherwise cover the same world draw.
  game.presentation.update(STEP,model)
  game.audio_system.update_state(STEP,model,game.mode)
  await grab(family,first_frame+index)
  if index in [0,18,37]:
   witness.append({"frame":first_frame+index,"pose":pose_record()})
 check(witness[0].pose.pose=="vanish" and witness[1].pose.pose=="vanish" and witness[2].pose.art=="","real death holds a joint pose before fading out")
 return {"event_id":death.get("id",-1),"sequence":witness,"frames":39}

func direction_run(view: String) -> Dictionary:
 var fixture:=find_room(view)
 check(not fixture.is_empty(),"legal world door route for "+view)
 if fixture.is_empty():
  return {}
 adopt(fixture)
 var model: MatchModel=fixture.model
 var room: RoomState=fixture.room
 var h:=model.hunter
 var before_hp: float=h.hp
 var last_position: Vector2=h.position
 var moved:=0
 var pose_keys:={}
 var first_form_frames:=0
 var transform_frames:=0
 var overlap_frames:=0
 var second_form_pose:={}
 var measured:={}
 var grip_visible:=false
 var grip_hidden_on_rear:=true
 var frames:=0
 var contact_reached:=-1
 var release_frame:=-1
 var recovery_frame:=-1
 var staged_damage:=false
 for frame in range(226):
  if h.state==HunterState.State.ATTACK and not staged_damage and first_form_frames>=6:
   var dealt:=model.apply_target_damage(1,h.max_hp*.46,room.index,DamageRules.weapon("turret"))
   check(dealt>0.0 and h.state==HunterState.State.TRANSFORM,"legitimate incoming hit crosses the boss transform threshold")
   staged_damage=true
  var impact_audio_before:=int(game.audio_system.event_counts.get("reaper_impact",0))
  game._process(STEP)
  if h.position.distance_squared_to(last_position)>.01:
   moved+=1
   check(model.navigation_walkable(h.position),"Reaper stays on model walkable floor")
  last_position=h.position
  await grab(view,frame)
  frames=frame+1
  var sample:=pose_record()
  pose_keys[sample.pose]=true
  if not h.transformed and sample.art.ends_with("approach_"+view+".png"):
   first_form_frames+=1
  if h.state==HunterState.State.TRANSFORM:
   transform_frames+=1
   if reaper_visual.transition_previous_texture.ends_with("approach_"+view+".png") and sample.art.ends_with("transformed_"+view+".png"):
    overlap_frames+=1
  if h.transformed and h.state!=HunterState.State.TRANSFORM:
   if view=="back" and sample.pose in ["idle","move","recover"]:
    grip_hidden_on_rear=grip_hidden_on_rear and not sample.weapon
   elif sample.art.ends_with("transformed_"+view+".png"):
    grip_visible=grip_visible or sample.weapon
   if sample.pose in ["windup","contact","follow","recover"]:
    second_form_pose[sample.pose]=true
  var hit:=live_event(model,"door_damage","scythe")
  if not hit.is_empty() and contact_reached<0 and absf(float(hit.time)-float(model.time))<.0001:
   var blade: Vector2=reaper_visual.articulated_contact()
   var target:=HunterCombatVisual.door_socket(room)+Vector2(145,40)
   var aligned:=blade.distance_to(target)
   info_contact(view,frame)
   var impact_audio_delta:=int(game.audio_system.event_counts.get("reaper_impact",0))-impact_audio_before
   measured={"frame":frame,"art":sample.art,"blade_error":aligned,"damage":hit.damage,"grip":sample.weapon,"event_id":hit.id,"audio_event_delta":impact_audio_delta}
   check(impact_audio_delta==1,"the impact voice starts once on the damage frame")
   check(sample.art.ends_with("transformed_"+view+".png") and sample.weapon,"the expected visible scythe is held at the actual strike")
   check(aligned<=2.0,"the scythe edge meets the real door socket")
   contact_reached=frame
  if contact_reached>=0 and sample.pose=="follow" and release_frame<0:
   release_frame=frame
  if contact_reached>=0 and sample.pose=="recover" and recovery_frame<0:
   recovery_frame=frame
  if recovery_frame>=0 and frame>recovery_frame+4:
   break
 check(first_form_frames>=6 and moved>0,view+" first form truly moved with atlas")
 check(transform_frames>=45 and overlap_frames>0 and h.hp<before_hp and not live_event(model,"boss_awakened").is_empty(),view+" transformation cross-dissolves and adds no HP")
 check(all_required(second_form_pose,["windup","contact","follow","recover"]) and contact_reached>=0,view+" transformed attack sequence")
 check(grip_hidden_on_rear if view=="back" else grip_visible,view+" handheld weapon occlusion")
 var death:=await render_death(model,view,frames)
 return {"seed":fixture.seed,"room":room.index,"move_frames":moved,"first_form_frames":first_form_frames,"transform_frames":transform_frames,"layer_overlap_frames":overlap_frames,
  "strike":measured,"follow_frame":release_frame,"recover_frame":recovery_frame,"poses":pose_keys.keys(),"death":death,"frame_count":frames+death.frames}

func all_required(seen: Dictionary, required: Array) -> bool:
 for label in required:
  if not seen.has(label):
   return false
 return true

func info_contact(view: String, frame: int):
 if not save_frames:
  return
 var image:=root.get_texture().get_image()
 check(image.save_png(destination.path_join(view+"-scythe-contact.png"))==OK,"save actual strike still")
 print("Reaper contact ",view," frame ",frame)

func turning_run(form: String) -> Dictionary:
 var fixture:=find_room("front")
 if fixture.is_empty():
  check(false,"turn fixture has a legal room")
  return {}
 var model: MatchModel=fixture.model
 var room: RoomState=fixture.room
 var door:=room.door_approach()
 var path: Array=[]
 for point: Vector2 in model.map_data.nodes:
  if point.distance_to(door)<96.0 or point.distance_to(door)>280.0:
   continue
  var route:=model.navigation_path(point,door)
  if route.size()<2:
   continue
  var legs:={}
  var previous:=point
  var length:=0.0
  for waypoint: Vector2 in route:
   var distance:=previous.distance_to(waypoint)
   if distance>=28.0:
    legs[ArticulatedHunterScript.cardinal((waypoint-previous).normalized(),"")]=true
   length+=distance
   previous=waypoint
  if legs.size()>1 and length<420.0:
   fixture.origin=point
   path=route
   break
 check(not path.is_empty(),form+" route includes two traversable headings")
 if path.is_empty():
  return {}
 adopt(fixture)
 var h:=model.hunter
 if form=="transformed":
  h.hp=h.max_hp*.54
  for step in range(62):
   game._process(STEP)
  check(h.transformed and h.state!=HunterState.State.TRANSFORM,"second form is ready for its turn route")
  h.position=fixture.origin
  h.state=HunterState.State.MOVE
  h.target=room.index
  h.cooldown=1.0
 game.hunter_spectating=true
 game.focus_camera(true)
 var turns:=[]
 var heading_seen:={}
 var before: Vector2=h.position
 var frames:=0
 for frame in range(124):
  game._process(STEP)
  var moving: bool=h.position.distance_squared_to(before)>.01
  before=h.position
  await grab("turn_"+form,frame)
  frames=frame+1
  var pose:=pose_record()
  if moving and pose.pose=="move" and pose.art.get_file().begins_with("reaper_"+form):
   check(model.navigation_walkable(h.position),"turn remains on legal floor")
   if turns.is_empty() or turns.back().view!=pose.view:
    turns.append({"frame":frame,"view":pose.view,"path":[h.position.x,h.position.y],"atlas":pose.art})
    heading_seen[pose.view]=true
  if h.state==HunterState.State.ATTACK:
   break
 check(heading_seen.size()>=2 and h.state==HunterState.State.ATTACK,form+" body moves through a real turn and enters door siege")
 return {"turns":turns,"frame_count":frames,"path_points":path.size(),"seed":fixture.seed,"room":room.index}

func ability_run(ability: String) -> Dictionary:
 var fixture:=find_room("front")
 check(not fixture.is_empty(),"ability has a legal room")
 if fixture.is_empty():
  return {}
 adopt(fixture)
 var model: MatchModel=fixture.model
 var room: RoomState=fixture.room
 var h:=model.hunter
 h.position=room.door_approach()
 h.state=HunterState.State.ATTACK
 check(model.apply_target_damage(1,h.max_hp*.46,room.index,DamageRules.weapon("turret"))>0.0,"stage real boss activation before an ability")
 for tick in range(62):
  game._process(STEP)
 check(h.transformed and h.state!=HunterState.State.TRANSFORM,"waited through the authoritative transform timer")
 h.boss_cooldowns.scythe=999.0
 h.boss_cooldowns.siege=999.0
 h.boss_cooldowns.surge=999.0
 if ability=="crimson_execution":
  h.hp=h.max_hp*.09
 elif ability in ["enhanced_undead","soul_reaper","phantom_scream","final_judgement"]:
  h.hp=h.max_hp*.30
  model.wrath.tick(STEP,model)
 var began:=true
 if ability!="crimson_execution":
  began=model.wrath.begin(ability,model,room.index)
 check(began,"existing ability begins: "+ability)
 var phase:=0
 var warning_frame:=-1
 var release_frame:=-1
 var frames:=0
 var thrown:=-1
 var embedded:=-1
 var no_duplicate_grip:=true
 var slash:={}
 var poses:={}
 var healthy: float=room.door_hp
 var warning_cue:=-1
 var release_cue:=-1
 var warning_voice: String="wrath_warning_"+ability
 var release_voice: String="wrath_activate_"+ability
 var initial_warning_cues:=int(game.audio_system.event_counts.get(warning_voice,0))
 var initial_release_cues:=int(game.audio_system.event_counts.get(release_voice,0))
 for frame in range(130):
  game._process(STEP)
  await grab(ability,frame)
  frames=frame+1
  phase=model.wrath.phase
  var pose:=pose_record()
  poses[pose.pose]=true
  if warning_cue<0 and int(game.audio_system.event_counts.get(warning_voice,0))>initial_warning_cues:
   warning_cue=frame
  if release_cue<0 and int(game.audio_system.event_counts.get(release_voice,0))>initial_release_cues:
   release_cue=frame
  if model.wrath.ability==ability and warning_frame<0 and pose.pose==("windup" if ability=="scythe_slash" else "cast"):
   warning_frame=frame
  var release:=live_event(model,"boss_ability_activate",ability)
  if not release.is_empty() and release_frame<0:
   release_frame=frame
   var hit:=live_event(model,"door_damage","Scythe Slash")
   if ability=="scythe_slash" and not hit.is_empty():
    var target:=HunterCombatVisual.door_socket(room)+Vector2(145,40)
    var error: float=reaper_visual.articulated_contact().distance_to(target)
    slash={"error":error,"damage":hit.damage,"grip":pose.weapon}
  if thrown<0 and not live_event(model,"scythe_throw").is_empty():
   thrown=frame
  if embedded<0 and not live_event(model,"scythe_embed").is_empty():
   embedded=frame
  if not model.wrath.scythe.is_empty():
   no_duplicate_grip=no_duplicate_grip and not pose.weapon
  if ability=="crimson_execution" and embedded>=0 and frame>embedded+9:
   break
  if ability!="crimson_execution" and release_frame>=0 and frame>release_frame+12:
   break
 check(warning_frame>=0 and release_frame>warning_frame,ability+" real warning drives articulated gesture before release")
 check(poses.has("cast_release") or ability=="scythe_slash" and poses.has("contact"),ability+" actual release reaches body renderer")
 if ability=="scythe_slash":
  check(not slash.is_empty() and slash.error<=2.0 and slash.grip and room.door_hp<healthy,"special scythe strike carries the blade to actual door damage")
 if ability=="crimson_execution":
  check(thrown==release_frame and embedded>thrown and no_duplicate_grip and model.wrath.domain_active(),"one visible thrown scythe embeds while the real Domain is active")
 return {"boss_phase":phase,"warning_frame":warning_frame,"release_frame":release_frame,"throw_frame":thrown,"embed_frame":embedded,
  "empty_hand_during_throw":no_duplicate_grip,"slash":slash,"poses":poses.keys(),"frame_count":frames,"warning_cue_frame":warning_cue,"release_cue_frame":release_cue}

func supplemental_run(action: String) -> Dictionary:
 var fixture:=find_room("front")
 if fixture.is_empty():
  check(false,"supplemental attack has a legal room")
  return {}
 adopt(fixture)
 var model: MatchModel=fixture.model
 var room: RoomState=fixture.room
 var h:=model.hunter
 h.position=room.door_approach()
 h.state=HunterState.State.ATTACK
 check(model.apply_target_damage(1,h.max_hp*.46,room.index,DamageRules.weapon("turret"))>0.0,"stage real boss activation for "+action)
 for tick in range(62):
  game._process(STEP)
 check(h.transformed and h.state==HunterState.State.ATTACK,"boss has completed transformation at a real door")
 if action=="surge":
  check(place_surge_targets(model,room),"two bought weapons make Shadow Surge eligible")
 h.boss_cooldowns.scythe=999.0
 h.boss_cooldowns.siege=0.0 if action=="siege" else 999.0
 h.boss_cooldowns.surge=0.0 if action=="surge" else 999.0
 if action in ["shadow_dash","soul_drain"]:
  h.arcane.cooldown=0.0
 if action=="shadow_dash":
  h.position=fixture.origin
  h.state=HunterState.State.MOVE
 h.cooldown=0.0
 var is_arcane: bool=action in ["shadow_dash","soul_drain"]
 var warning:=-1
 var released:=-1
 var poses:={}
 var blade_error:=-1.0
 var frame_count:=0
 var origin: Vector2=h.position
 var expected_release: String="hunter_ability" if is_arcane else "boss_surge" if action=="surge" else "boss_impact"
 var damage_type: String="soul_drain" if action=="soul_drain" else "siege" if action=="siege" else ""
 var fx_pressure:=false
 for frame in range(112):
  game._process(STEP)
  await grab(action,frame)
  frame_count=frame+1
  var pose:=pose_record()
  poses[pose.pose]=true
  if warning<0 and not live_event(model,"hunter_ability_warning" if is_arcane else "boss_warning",action).is_empty():
   warning=frame
   check(pose.pose==("windup" if action=="siege" else "cast"),action+" warning uses the correct body gesture")
  var release:=live_event(model,expected_release,action if action!="surge" else "")
  if released<0 and not release.is_empty():
   released=frame
   if not damage_type.is_empty():
    check(not live_event(model,"door_damage",damage_type).is_empty(),action+" actual damage reached the door")
   if action=="siege":
    blade_error=reaper_visual.articulated_contact().distance_to(HunterCombatVisual.door_socket(room)+Vector2(145,40))
   if action=="surge":
    fx_pressure=h.shadow_active(room.index)
  if released>=0 and frame>released+14:
   break
 check(warning>=0 and released>warning,action+" actual model warning and release reached the renderer")
 if action=="siege":
  check(poses.has("contact") and blade_error>=0.0 and blade_error<=2.0,action+" actual Soul Siege blade contact")
 else:
  check(poses.has("cast_release"),action+" actual release has articulated momentum")
 if action=="shadow_dash":
  check(h.position.distance_to(origin)>12.0,"active Shadow Dash moves through model navigation")
 if action=="surge":
  check(fx_pressure,"actual Shadow Surge produced its defense suppression")
 return {"warning_frame":warning,"release_frame":released,"poses":poses.keys(),"blade_error":blade_error,"frame_count":frame_count,"shadow_suppression":fx_pressure}

func place_surge_targets(model: MatchModel, room: RoomState) -> bool:
 # Fixture wallet funds real legal purchases, without changing combat rules.
 room.gold=300.0
 var positions: Array[Vector2]=[]
 var bounds:=room.bounds().grow(-8)
 for y in range(floori(bounds.position.y),ceili(bounds.end.y),16):
  for x in range(floori(bounds.position.x),ceili(bounds.end.x),16):
   var point:=room.spatial.aligned(Vector2(x,y),"turret",0)
   if point.is_finite() and point.distance_to(room.door_approach())<140.0:
    positions.append(point)
 for point in positions:
  if room.spatial.purchase_reason("turret",point,0)=="" and model.place_building("turret",point,0) and room.buildings.size()==2:
   return true
 return false

func approach_death_run() -> Dictionary:
 var fixture:=find_room("front")
 if fixture.is_empty():
  check(false,"first form death has a legal room")
  return {}
 adopt(fixture)
 var model: MatchModel=fixture.model
 var room: RoomState=fixture.room
 var h:=model.hunter
 h.position=room.door_approach()
 h.state=HunterState.State.ATTACK
 model.time=model.preparation+1.0
 for step in range(12):
  game._process(STEP)
 var dealt:=model.apply_target_damage(1,h.hp,room.index,DamageRules.weapon("turret"))
 check(dealt>0.0 and h.state==HunterState.State.DEAD and not h.transformed,"real lethal input during the opening grace leaves the first form")
 var samples:=[]
 for frame in range(39):
  game.presentation.update(STEP,model)
  game.audio_system.update_state(STEP,model,game.mode)
  await grab("approach_death",frame)
  if frame in [0,18,37]:
   samples.append({"frame":frame,"pose":pose_record()})
 check(samples[0].pose.art.ends_with("approach_front.png") and samples[1].pose.pose=="vanish" and samples[2].pose.art=="","first form collapses and stops drawing after the fade")
 return {"lethal_damage":dealt,"frame_count":39,"samples":samples}
