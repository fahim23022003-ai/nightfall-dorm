extends SceneTree
## Real screenshots and fixed-step production gameplay from isolated seeded fixtures.
const STEP := .05
const ROOM_SEED := 41
const THEMES := ["abandoned_dorm","haunted_hospital","forgotten_hotel","underground_lab","cursed_mansion"]
var game
var directory := ""
var sequence := ""
var frame_index := 0
var stills := false
var errors: Array[String]=[]
var receipt := {}

func _initialize():
 call_deferred("run")

func verify(ok: bool, message: String):
 if not ok:
  errors.append(message)
  push_error(message)

func run():
 var args := OS.get_cmdline_user_args()
 if args.is_empty() or not args[0].is_absolute_path():
  push_error("Pass an absolute directory and optional --stills after --.")
  quit(2)
  return
 directory=args[0]
 stills="--stills" in args
 DirAccess.make_dir_recursive_absolute(directory)
 root.size=Vector2i(1280,720)
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://procedural-capture.json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 await process_frame
 if is_instance_valid(game.onboarding):
  preload("res://tests/onboarding_test_support.gd").skip(game)
  game.onboarding.set_process(false)
 game.profile.settings.graphics_quality="medium"
 verify(OS.get_environment("NIGHTFALL_PROCEDURAL_MAPS")=="1","procedural opt-in is active")
 verify(OS.get_environment("NIGHTFALL_VISUAL_REBIRTH")=="1","Phase 14F is active")

 var layouts: Array=[]
 for i in range(THEMES.size()):
  var m := fixture(THEMES[i],ROOM_SEED+i*32)
  game.full_map=true
  game.focus_camera(true)
  game.ui.update_match()
  await image("map-"+THEMES[i])
  layouts.append({"theme":m.map_id,"seed":m.map_seed,"map_sha256":JSON.stringify(NightmareMap.pack(m.map_data)).sha256_text()})
 receipt.layouts=layouts

 var m := fixture("cursed_mansion",67,-1,"u")
 var room := m.player()
 game.construction.planning=true
 populate(m)
 game.focus_camera(true)
 game.ui.update_match()
 await image("irregular-u-floor-grid")
 receipt.grid={"shape":room.layout.shape,"paid_buildings":room.buildings.size(),"floor_pieces":room.layout.floor.size()}
 verify(room.layout.shape=="u" and room.spatial.grid and room.buildings.size()>=5,"U-shaped Full Room Grid has real paid buildings")

 if not stills:
  await capture_routes()
 await capture_recovery()

 receipt.errors=errors
 var output := FileAccess.open(directory.path_join("capture.json"),FileAccess.WRITE)
 output.store_string(JSON.stringify(receipt,"  ")+"\n")
 output.close()
 game.audio_system.shutdown()
 game.queue_free()
 await process_frame
 print("NIGHTMARE_MAP_CAPTURE_FAILURES=",errors.size())
 quit(1 if not errors.is_empty() else 0)

func fixture(theme: String, seed: int, room_index := -1, shape := "") -> MatchModel:
 var m := MatchModel.new()
 verify(m.configure_endless(theme,"standard",seed,seed),"Endless fixture configured")
 verify(m.configure_balance(),"current balance configured")
 if room_index<0:
  room_index=0
  for candidate in m.rooms:
   if candidate.layout.get("shape","")==shape:
    room_index=candidate.index
    break
 verify(m.claim_room(room_index),"claimed actual generated room")
 m.player_position=m.player().bed_position()
 verify(m.sleep_player(),"survivor sleeps through production command")
 m.bot_claimed=5
 game._adopt_session(m)
 game.set_process(false)
 return m

func populate(m: MatchModel):
 var room := m.player()
 room.gold=250000
 room.electricity=250000
 room.bed_level=4
 room.door_level=4
 room.door_hp=room.max_hp()
 for kind in ["generator","turret","heavy","repair","economy","enhancer","flame","frost","decoy","shock","shield"]:
  var area := room.spatial.grid_bounds()
  var installed := false
  for y in range(16,int(area.size.y),32):
   for x in range(16,int(area.size.x),32):
    var p := room.spatial.aligned(area.position+Vector2(x,y),kind,0)
    if not room.spatial.purchase_reason(kind,p).is_empty():continue
    installed=m.place_building(kind,p)
    if installed:break
   if installed:break

func present(steps := 0):
 for i in range(steps):
  game._process(STEP)
 game.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw

func image(name: String):
 await present()
 var shot := root.get_texture().get_image()
 verify(shot.get_size()==Vector2i(1280,720),"native 1280×720 capture "+name)
 verify(shot.save_png(directory.path_join(name+".png"))==OK,"saved "+name)

func begin_sequence(name: String):
 sequence=name
 frame_index=0
 if not stills:DirAccess.make_dir_recursive_absolute(directory.path_join(sequence))

func frame(steps := 1):
 if stills:
  for i in range(steps):game._process(STEP)
  return
 await present(steps)
 var shot := root.get_texture().get_image()
 verify(shot.save_jpg(directory.path_join("%s/%04d.jpg" % [sequence,frame_index]),.9)==OK,"frame saved")
 frame_index+=1

func rehearse(m: MatchModel, start: Vector2, active_seconds: float):
 m.time=m.endless.wave_started_at+active_seconds
 m.hunter.state=HunterState.State.MOVE
 m.hunter.target=m.player_room
 m.hunter.position=start
 m.hunter.tactical_cooldown=1000
 m.hunter.arcane.cooldown=1000
 m.hunter.nightmare.cooldown=1000
 m.hunter.boss_policy.enabled=false
 m.hunter.cooldown=1.0

func capture_routes():
 var samples: Array=[]
 for variant in [0,1]:
  var m := fixture("cursed_mansion",ROOM_SEED,0)
  var initial: Vector2=m.map_data.nodes[0]
  var goal: Vector2=m.player().door_approach()
  rehearse(m,initial,1)
  m.hunter.decision_count=variant
  game.full_map=true
  game.focus_camera(true)
  game.ui.update_match()
  var route := m.navigation_path(initial,goal,false,variant)
  verify(not route.is_empty(),"route reaches same exterior approach")
  var trail := Line2D.new()
  trail.default_color=Color("E5BB70") if variant==0 else Color("A1E8D9")
  trail.width=9
  trail.z_index=4
  game.add_child(trail)
  trail.add_point(initial+game.MAP_OFFSET)
  begin_sequence("route-%d" % variant)
  var trace: Array=[]
  for i in range(150):
   await frame(4)
   var at: Vector2=m.hunter.position
   trail.add_point(at+game.MAP_OFFSET)
   trace.append([at.x,at.y])
   verify(m.navigation_walkable(at),"real Hunter stays on navigable exterior")
   if at.distance_to(goal)<3:break
  verify(m.hunter.position.distance_to(goal)<3,"real Hunter arrives at the shared door approach")
  await image("hunter-route-%d" % variant)
  samples.append({"frames":frame_index,"planned":route,"actual":trace,"door":[goal.x,goal.y]})
  trail.queue_free()
  await process_frame
 verify(samples[0].planned!=samples[1].planned,"different AStar variants give different course")
 receipt.routes=samples

func click_watch(button: Button):
 var point := root.get_final_transform()*button.get_global_rect().get_center()
 Input.warp_mouse(point)
 await process_frame
 for pressed in [true,false]:
  var event:=InputEventMouseButton.new()
  event.position=point
  event.global_position=point
  event.button_index=MOUSE_BUTTON_LEFT
  event.pressed=pressed
  Input.parse_input_event(event)
  await process_frame

func capture_recovery():
 var m := fixture("cursed_mansion",ROOM_SEED,0)
 m.player().gold=1800
 var hall: Dictionary=m.map_data.halls.west
 var junction: Vector2=m.map_data.nodes[4]
 var start := junction+Vector2(0,-235)
 verify(m.navigation_walkable(start),"measured west-lane starting point is walkable")
 rehearse(m,start,31.0)
 m.hunter.applied_growth=m.hunter.growth_at(31.0)
 var damaged: float=m.apply_target_damage(1,m.hunter.max_hp*.64,m.player_room,{"type":"physical","element":"neutral"})
 verify(damaged>0,"real combat damage primes retreat")
 game.focus_camera(true)
 game._process(STEP)
 var ctl=m.haunt_recovery
 verify(ctl.phase=="retreat" and ctl.hall_id=="west","AI chooses West Haunted Hall")
 verify(not game.hunter_spectating,"retreat never forces the camera")
 if game.ui.haunted_hud==null or ctl.phase!="retreat":return
 var banner=game.ui.haunted_hud
 verify(banner.title.text=="HUNTER RETREAT DETECTED","actual retreat notification")
 # A live paid placement preview remains active while the player watches.
 verify(game.construction.begin("turret"),"room has an active placement preview")
 var original_point: Vector2=game.construction.point
 var original_wallet: float=m.player().gold
 await image("hunter-retreat-notification")
 begin_sequence("west-hall")
 for i in range(5):await frame(1)
 await click_watch(banner.watch)
 Input.warp_mouse(Vector2(350,182))
 verify(game.hunter_spectating and game.construction.active(),"native Watch Hunter button retains placement")
 var attack_count: int=m.hunter.attacks
 var entered := false
 var start_hp: float=m.hunter.hp
 var healed := 0.0
 var hall_end_at := 0.0
 var return_frame := -1
 var pose_samples: Array=[]
 for i in range(340):
  if entered and ctl.phase=="idle" and return_frame<0:
   return_frame=frame_index
   hall_end_at=m.time
  await frame(1 if ctl.phase=="recover" else 4)
  if not entered and ctl.phase=="recover":
   entered=true
   verify(m.hunter.position.distance_to(hall.center)<4,"Hunter entered center through real navigation")
   verify(banner.title.text=="HUNTER RECOVERING — WEST HAUNTED HALL","actual West recovery notification")
   start_hp=m.hunter.hp
   await image("west-hall-entry")
  if ctl.phase=="recover":
   healed=maxf(healed,ctl.healed)
   if pose_samples.size()<3 and ctl.recovery_elapsed>1+pose_samples.size()*2:
    pose_samples.append({"hp":m.hunter.hp,"healed":ctl.healed,"frame":frame_index})
    await image("west-hall-recovery-%d" % pose_samples.size())
  if return_frame>=0 and m.hunter.attacks>attack_count:break
 verify(entered and ctl.visits==1 and healed>0,"gradual real recovery completes")
 verify(m.hunter.attacks>attack_count,"Hunter returns to actual combat")
 await image("hunter-back-at-door")
 verify(game.audio_system.event_counts.get("haunted_hall_retreat",0)>0 and game.audio_system.event_counts.get("haunted_hall_west",0)>0,"production audio director plays retreat and West ritual cues")
 await click_watch(banner.watch)
 verify(not game.hunter_spectating and game.construction.active() and game.construction.point==original_point and m.player().gold>=original_wallet,"native Return preserves original preview and spends nothing")
 await image("hunter-return-to-room")
 receipt.recovery={"visit":ctl.visits,"hall":"west","starting_hp":start_hp,"observed_healed":healed,
  "samples":pose_samples,"recovery_ended_at":hall_end_at,"reactivation_attacks":m.hunter.attacks-attack_count,
  "return_frame":return_frame,"frames":frame_index,"audio_counts":game.audio_system.event_counts}
