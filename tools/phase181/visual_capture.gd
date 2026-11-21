extends "res://tools/phase18/capture_close_quarters.gd"
## Paired captures use identical procedural geometry and camera scales.
## Every displayed machine is legally placed and paid for in an isolated fixture.

const VISUAL_SEED := 10358
const THEME := "haunted_hospital"
const KINDS := ["turret","heavy","generator","repair","economy","enhancer","flame","frost","shock","auto_repair","shield","decoy","barrier","plasma","antenna"]
const BRANCHES := {"turret":"precision","heavy":"storm","generator":"overcharge","repair":"sustain"}
const DETAIL_ZOOM := 1.65
const ROOM_ZOOM := .88
var result: Dictionary={}
var launch: Dictionary={}
var impact: Dictionary={}
var target_id: int=-1

func make_room(index: int) -> MatchModel:
 var model:=_prepared_model(VISUAL_SEED,THEME,"standard")
 var room:=_settle_room(model,index)
 check(room!=null and room.spatial.grid,"Actual construction grid")
 if room==null:
  return model
 check(room.spatial.rules_version==(2 if OS.get_environment("NIGHTFALL_BUILDING_SCALE")=="1" else 1),"Requested rule version")
 room.gold=100000.0
 room.electricity=100000.0
 room.bed_level=9
 room.door_level=9
 room.door_hp=room.max_hp()
 model.bot_claimed=5
 return model

func _available_slot(room: RoomState, kind: String, toward: Vector2, turn: int=0) -> Vector2:
 var bounds:=room.spatial.grid_bounds()
 var choices: Array[Vector2]=[]
 for x in range(int(bounds.size.x/SpatialConstruction.CELL_SIZE)+1):
  for y in range(int(bounds.size.y/SpatialConstruction.CELL_SIZE)+1):
   var position:=room.spatial.aligned(bounds.position+Vector2(x,y)*SpatialConstruction.CELL_SIZE,kind,turn)
   if room.spatial.purchase_reason(kind,position,turn)=="":
    choices.append(position)
 if choices.is_empty():
  return Vector2.INF
 choices.sort_custom(func(a: Vector2,b: Vector2):return a.distance_squared_to(toward)<b.distance_squared_to(toward))
 return choices[0]

func _pay_place(model: MatchModel, kind: String, toward: Vector2, turn: int=0) -> int:
 var room: RoomState=model.player()
 var at:=_available_slot(room,kind,toward,turn)
 var id: int=room.spatial.next_id
 return id if at.is_finite() and model.place_building(kind,at,turn) else -1

func _camera(at: Vector2, zoom: float):
 game.camera.position=at+game.MAP_OFFSET
 game.camera.zoom=Vector2.ONE*zoom
 game.camera.offset=Vector2.ZERO
 game.camera.force_update_scroll()

func plate(kind: String, tier: int):
 var model:=make_room(1)
 var room: RoomState=model.player()
 if kind in ["economy","enhancer"]:
  check(_pay_place(model,"generator",room.bounds().position+Vector2(50,50))>=0,"Paid Dynamo prerequisite")
 var id:=_pay_place(model,kind,room.bounds().get_center())
 check(id>=0,"legal paid "+kind)
 if id<0:
  return
 for level in range(2,tier+1):
  if level==5:
   check(model.specialize_building(id,BRANCHES[kind]),"paid "+kind+" specialization")
  else:
   check(model.upgrade_building(id),"paid "+kind+" upgrade "+str(level))
 var position: Vector2=room.tile_position(id)
 var rect:=room.spatial.footprint_for(position,kind,0)
 var name: String=kind+"-l%02d" % tier
 _camera(position+Vector2(0,-28),DETAIL_ZOOM)
 game.ui.update_match()
 if DisplayServer.get_name()!="headless":
  await _render_frame()
  _save_frame(name)
 result[name]={"center":[position.x,position.y],"footprint":[rect.size.x,rect.size.y],"scale":SpatialConstruction.art_scale(kind,rect,room.spatial.rules_version),"camera_zoom":DETAIL_ZOOM,"level":room.buildings[id].level,"branch":room.buildings[id].get("specialization","")}

func layout(name: String, index: int, kinds: Array, crowd: bool = false) -> MatchModel:
 var model:=make_room(index)
 var room: RoomState=model.player()
 var bounds: Rect2=room.bounds()
 var markers: Array[Vector2]=[Vector2(.20,.16),Vector2(.76,.72),Vector2(.72,.16),Vector2(.19,.70),Vector2(.48,.18),Vector2(.65,.45),Vector2(.35,.45)]
 for i in range(kinds.size()):
  var id:=_pay_place(model,kinds[i],bounds.position+bounds.size*markers[i],1 if i%3==1 else 0)
  check(id>=0,name+" fits a paid "+str(kinds[i]))
 if crowd:
  for i in range(48):
   var row: float=float(i%12)/12.0
   var grid: float=float(i/12)/4.0
   var nearest: Vector2=bounds.position+bounds.size*Vector2(row,grid)
   if _pay_place(model,"turret",nearest)<0:
    break
 game.ui.update_match()
 _camera(bounds.get_center()+Vector2(-18,-18),ROOM_ZOOM)
 if DisplayServer.get_name()!="headless":
  await _render_frame()
  _save_frame(name)
 var mounts: Array=[]
 for id: int in room.buildings:
  var building: Dictionary=room.buildings[id]
  var rect:=room.spatial.footprint_for(room.tile_position(id),building.kind,building.rotation)
  mounts.append({"kind":building.kind,"rect":str(rect),"rotation":building.rotation})
 var floor_area:=0.0
 for segment: Rect2 in room.layout.floor:
  floor_area+=segment.get_area()
 result[name]={"room":index+1,"area":floor_area,"shape":room.layout.shape,"camera_zoom":ROOM_ZOOM,"count":mounts.size(),"mounts":mounts}
 return model

func placement() -> void:
 var model:=make_room(1)
 var room: RoomState=model.player()
 check(game.construction.begin("barrier"),"Open real Mirror Barrier placement")
 var at:=_available_slot(room,"barrier",room.bounds().get_center(),1)
 check(at.is_finite(),"Find legal rotated barrier footprint")
 if not at.is_finite():
  return
 game.construction.cursor_world=at
 game.construction.rotate()
 var footprint: Rect2=room.spatial.footprint_for(game.construction.point,"barrier",game.construction.rotation)
 var valid_reason: String=game.construction.reason()
 check(valid_reason.is_empty() and game.construction.rotation==1,"Rotated preview agrees with a legal purchase")
 _camera(room.bounds().get_center()+Vector2(-18,-18),ROOM_ZOOM)
 if DisplayServer.get_name()!="headless":
  await _render_frame()
  _save_frame("placement-valid")
 game.construction.cursor_world=room.door_position()
 game.construction.point=game.construction.aligned(game.construction.cursor_world)
 game.construction.refresh()
 var blocked: String=game.construction.reason()
 check(not blocked.is_empty(),"Invalid preview reports real door or floor obstruction")
 if DisplayServer.get_name()!="headless":
  await _render_frame()
  _save_frame("placement-blocked")
 result.placement={"green_footprint":str(footprint),"rotation":game.construction.rotation,"red_reason":blocked}
 game.cancel_placement(true)

func _practical_benchmark(preset: String) -> void:
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 Engine.max_fps=0
 game.change_setting("graphics_quality",preset)
 var model:=await layout("practical-defense",0,["turret","generator","repair","heavy","frost","antenna","economy"])
 var room: RoomState=model.player()
 model.time=model.preparation+7.0
 model.haunt_recovery.available_at=INF
 model.hunter.position=room.door_approach()
 model.hunter.target=room.index
 model.hunter.state=HunterState.State.ATTACK
 model.hunter.cooldown=.5
 var initial_hp: float=model.hunter.hp
 var frames: Array[float]=[]
 var calls: Array[int]=[]
 for i in range(150):
  var started:=Time.get_ticks_usec()
  game._process(FRAME_STEP)
  _camera(room.bounds().get_center()+Vector2(-18,-18),ROOM_ZOOM)
  await RenderingServer.frame_post_draw
  if i>=30:
   frames.append((Time.get_ticks_usec()-started)/1000.0)
   calls.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
 frames.sort()
 calls.sort()
 check(model.shots>0 and model.hunter.hp<initial_hp,"Genuine practical layout fires and damages Hunter")
 result.benchmark={"preset":preset,"samples":frames.size(),"median_ms":frames[frames.size()/2],"p95_ms":frames[ceili(frames.size()*.95)-1],"draw_calls_median":calls[calls.size()/2],"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"video_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"renderer":RenderingServer.get_video_adapter_name(),"count":room.buildings.size(),"shots":model.shots,"hunter_hp_lost":initial_hp-model.hunter.hp}

func capture_event(event: Dictionary) -> void:
 if event.type=="launch" and launch.is_empty():
  launch=event.duplicate()
  var muzzle: Vector2=game.presentation.weapons.muzzle(game,game.presentation.building_visual,event)
  launch.visual_muzzle=[muzzle.x,muzzle.y]
  target_id=event.projectile_id
 elif event.type=="impact" and event.projectile_id==target_id and impact.is_empty():
  impact=event.duplicate()

func firing() -> void:
 var model:=make_room(1)
 var room: RoomState=model.player()
 var id:=_pay_place(model,"turret",room.door_approach()-room.door_normal()*95)
 check(id>=0,"Paid enlarged Needle")
 if id<0:
  return
 var seed_point:=room.tile_position(id)
 _camera((seed_point+room.door_approach())*.5+Vector2(0,6),1.30)
 var start:=_approach_start(model,room)
 check(not start.is_empty(),"Validated production Hunter corridor route")
 if start.is_empty():
  return
 model.time=model.preparation+1.0
 model.haunt_recovery.available_at=INF
 model.hunter.position=start.point
 model.hunter.target=room.index
 model.hunter.state=HunterState.State.MOVE
 model.hunter.cooldown=.15
 model.weapon_feedback.received.connect(capture_event)
 check(model.weapon_feedback.enabled,"Production Weapon Feedback enabled")
 DirAccess.make_dir_recursive_absolute(destination.path_join("needle-frames"))
 var flight_frames:=0
 var hit_frame:=-1
 var damage_label: Dictionary={}
 for frame in range(240):
  game._process(FRAME_STEP)
  _camera((seed_point+room.door_approach())*.5+Vector2(0,6),1.30)
  await RenderingServer.frame_post_draw
  var image:=root.get_texture().get_image()
  check(image.save_png(destination.path_join("needle-frames/%04d.png" % frame))==OK,"Actual clip frame %d" % frame)
  if frame==5:
   _save_frame("needle-corridor-approach")
  if not launch.is_empty() and game.presentation.weapons.flight_seen.has(target_id) and model.projectiles.any(func(shot):return shot.id==target_id):
   flight_frames+=1
   if flight_frames==1:
    _save_frame("needle-flight")
  if hit_frame<0 and not impact.is_empty():
   hit_frame=frame
   _save_frame("needle-impact")
  if damage_label.is_empty():
   for number: Dictionary in game.presentation.weapons.numbers:
    if number.get("amount",0.0)>0.0 and number.has("label"):
     damage_label={"text":number.label,"amount":number.amount,"frame":frame,"hud":game.ui.hunter_label.text}
     _save_frame("needle-damage-label")
     break
 check(not launch.is_empty() and not impact.is_empty() and impact.damage>0 and is_equal_approx(impact.damage,impact.hp_before-impact.hp_after),"Exact launch reaches target and reflects real effective HP loss")
 check(flight_frames>=2,"Same projectile visibly rendered in several frames")
 check(not damage_label.is_empty() and is_equal_approx(damage_label.get("amount",0.0),impact.get("damage",-1.0)),"Native number equals the actual first-impact damage")
 check(model.shots>1 and model.hunter.hp<impact.get("hp_after",0),"The longer continuous sequence includes further shots and loss of HP")
 result.firing={"launch":launch,"impact":impact,"flight_frames":flight_frames,"hit_frame":hit_frame,"damage_label":damage_label,"fps":24,"frames":240,"shots":model.shots,"final_hp":model.hunter.hp,"camera_zoom":1.30,"approach":str(start.point)}

func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=2 or not args[0].is_absolute_path() or args[1] not in ["photos","film","validate","bench-standard","bench-low"]:
  push_error("Pass absolute output and photos, film, validate, bench-standard or bench-low.")
  quit(2)
  return
 destination=args[0]
 DirAccess.make_dir_recursive_absolute(destination)
 root.size=Vector2i(1280,720)
 await setup_game()
 game.onboarding.close_welcome()
 game.change_setting("graphics_quality","medium")
 if args[1]=="film":
  await firing()
 elif args[1].begins_with("bench-"):
  await _practical_benchmark("low" if args[1]=="bench-low" else "medium")
 else:
  for kind: String in KINDS:
   await plate(kind,1)
  for kind: String in BRANCHES:
   await plate(kind,10)
  await layout("small-defense",2,["turret","generator","repair"])
  await layout("large-defense",0,["turret","generator","repair","heavy","frost","antenna","economy"])
  await layout("crowded-comparison",4,["generator","repair","heavy","frost","antenna","economy"],true)
  await placement()
 var receipt:=FileAccess.open(destination.path_join("receipt.json"),FileAccess.WRITE)
 if receipt!=null:
  receipt.store_string(JSON.stringify({"rules":OS.get_environment("NIGHTFALL_BUILDING_SCALE"),"seed":VISUAL_SEED,"theme":THEME,"scenes":result,"checks":checks,"failures":failures},"  ",true,true)+"\n")
  receipt.close()
 await _finish()
