extends "res://tools/capture_visual_rebirth.gd"
## Native Godot views of a prepared grid room and its actual desktop controls.

const BUILD_KIND := "generator"
const TARGET_COUNT := 24
const ROOM_ID := 0

var grid_recording := false
var frame_number := 0
var capture_directory := ""
var grid_observations := {}
var dense_receipt: Array[Dictionary] = []

func run():
 var args := OS.get_cmdline_user_args()
 if args.size()!=1 or not args[0].is_absolute_path():
  push_error("Pass an absolute capture directory after --.")
  quit(2)
  return
 if OS.get_environment("NIGHTFALL_FULL_ROOM_GRID")!="1" or OS.get_environment("NIGHTFALL_VISUAL_REBIRTH")!="1":
  push_error("Enable the room grid and visual preview for the capture.")
  quit(2)
  return
 capture_directory=args[0].trim_suffix("/")
 output=capture_directory.get_base_dir()+"/"
 phase=capture_directory.get_file()
 DirAccess.make_dir_recursive_absolute(capture_directory.path_join("frames"))
 root.size=Vector2i(1280,720)
 await setup_game()
 game.onboarding.close_welcome()
 var model=_fresh_room(ROOM_ID)
 var room=model.player()
 check(room!=null and room.spatial!=null and room.spatial.grid,"claim and sleep activated the ordinary Endless grid")
 if failures>0:
  await _finish()
  return
 check(room.buildings.is_empty(),"input proof starts with an empty grid")
 check(root.get_texture().get_size()==Vector2(1280,720),"native game viewport is 1280 by 720")

 grid_recording=true
 await advance(.4)
 await _capture_input_journey(model,room)
 grid_recording=false
 if failures>0:
  _write_receipt()
  await _finish()
  return

 _populate_dense(model,room)
 check(room.buildings.size()>16,"real purchases fit beyond the old capacity")
 if failures>0:
  _write_receipt()
  await _finish()
  return
 game.ui.close_context()
 game.selected_tile=-1
 grid_recording=true
 grid_observations["dense_segment_first_frame"]=frame_number
 await key(KEY_P)
 await advance(.55)
 check(game.construction.planning,"actual P opens dense planning view")
 check(game.construction.status.text=="16 px grid","real planning controls show grid size without a capacity label")
 await _mark("07-dense-grid-720",{"building_count":room.buildings.size()})
 await advance(.5)
 await key(KEY_P)
 await advance(.35)

 _prepare_live_combat(model,room)
 var hunter=model.hunter
 var before_shots: int=model.shots
 var before_hp: float=room.door_hp
 var before_attacks: int=hunter.attacks
 var preview=game.presentation.nightmare_visual.stalker_preview
 var motion_seen := {}
 var seen_door_hits := {}
 var dealt_to_door := 0.0
 for frame in range(92):
  game._process(STEP)
  await _draw_recorded_frame()
  if not preview.pose_name.is_empty():motion_seen[preview.pose_name]=true
  for event in model.presentation_events:
   if event.type=="door_damage" and event.room==room.index and not seen_door_hits.has(event.id):
    seen_door_hits[event.id]=true
    dealt_to_door+=float(event.damage)
  if model.shots>before_shots and dealt_to_door>0.0 and frame>=36:
   await _mark("08-dense-phase14f-combat-720",{"shot_delta":model.shots-before_shots,"attacks":hunter.attacks-before_attacks})
   break
 check(model.shots>before_shots,"paid dense grid defenses fire in a live match")
 check(hunter.attacks>before_attacks and dealt_to_door>0.0,"Hunter lands a real door strike")
 check(preview.texture!=null and preview.active_level==10,"active combat uses the Phase 14F Stalker art")
 grid_observations["combat"]={"shot_delta":model.shots-before_shots,"attacks":hunter.attacks-before_attacks,
  "total_door_damage":dealt_to_door,"net_door_hp_loss":before_hp-room.door_hp,"poses":motion_seen.keys(),
  "texture":preview.texture.resource_path if preview.texture!=null else ""}
 grid_recording=false
 _write_receipt()
 await _finish()

func _capture_input_journey(model,room) -> void:
 var grid=room.spatial
 var center: Vector2=_pick_center(room,BUILD_KIND,1,room.bounds().get_center())
 var door: Vector2=_pick_rejected_door(room,BUILD_KIND,1)
 check(center.is_finite() and door.is_finite(),"located a legal rotated location and a door rejection")
 if not center.is_finite() or not door.is_finite():return
 var start := Vector2(room.gold,room.electricity)
 var cost: Vector2=room.quote_build(BUILD_KIND)
 var normal: Rect2=grid.footprint_for(center,BUILD_KIND,0)
 var turned: Rect2=grid.footprint_for(center,BUILD_KIND,1)
 check(normal.size.x!=normal.size.y and turned.size==Vector2(normal.size.y,normal.size.x),"quarter-turn exchanges the rectangular footprint dimensions")

 await _start_build(BUILD_KIND)
 if failures>0:return
 await key(KEY_Q)
 await point_mouse(center)
 check(game.construction.reason()=="","actual rotated cursor preview accepts a legal floor location")
 await _mark("01-rotated-preview-720",{"footprint_width":turned.size.x,"footprint_height":turned.size.y})
 await advance(.6)
 await point_mouse(door)
 var door_reason: String=game.construction.reason()
 check("door" in door_reason.to_lower(),"actual cursor shows door-access rejection")
 await _mark("02-blocked-door-720",{"reason":door_reason})
 await world_click(door)
 await advance(.5)
 check(room.buildings.is_empty() and Vector2(room.gold,room.electricity).is_equal_approx(start),"door rejection spends nothing and creates no building")

 await point_mouse(center)
 await world_click(center)
 await advance(.45)
 check(room.buildings.size()==1,"actual mouse click places the valid rectangular structure")
 if room.buildings.size()!=1:return
 var id: int=room.buildings.keys()[0]
 var building: Dictionary=room.buildings[id]
 var placed: Vector2=room.tile_position(id)
 var rotation: int=int(building.get("rotation",-1))
 var serial:int=int(building.instance_id)
 var original_instance:=_without_transform(building)
 check(placed.is_equal_approx(center) and rotation==1,"real Q and click commit exact snapped center and rotation")
 check((start-Vector2(room.gold,room.electricity)).is_equal_approx(cost),"one valid placement pays the quoted cost")
 await _mark("03-rotated-placement-720",{"rotation":rotation,"center":[placed.x,placed.y],"instance_id":serial})

 await _start_build(BUILD_KIND)
 if failures>0:return
 await key(KEY_Q)
 await point_mouse(placed)
 var overlap_reason: String=game.construction.reason()
 check("overlap" in overlap_reason.to_lower() or "occupied" in overlap_reason.to_lower(),"actual cursor shows an overlap rejection")
 await _mark("04-blocked-overlap-720",{"reason":overlap_reason})
 var paid := Vector2(room.gold,room.electricity)
 await world_click(placed)
 await advance(.5)
 check(room.buildings.size()==1 and Vector2(room.gold,room.electricity).is_equal_approx(paid),"overlap rejection keeps original structure and wallet")
 await key(KEY_ESCAPE)
 await advance(.3)

 var move_to: Vector2=_pick_center(room,BUILD_KIND,2,placed+Vector2(68,-55),id)
 check(move_to.is_finite() and not move_to.is_equal_approx(placed),"located a legal distinct move target")
 if not move_to.is_finite():return
 await world_click(placed)
 await advance(.3)
 check(game.selected_tile==id,"actual mouse click selects the rotated structure")
 await key(KEY_V)
 await advance(.25)
 check(game.construction.moving==id and grid.moving_id==id,"actual V moves the already purchased instance")
 await key(KEY_Q)
 await point_mouse(move_to)
 check(game.construction.reason()=="","rotated move preview is legal")
 await _mark("05a-safe-move-preview-720",{"rotation":game.construction.rotation,"from":[placed.x,placed.y],"to":[move_to.x,move_to.y],"instance_id":serial})
 await advance(.4)
 await world_click(move_to)
 await advance(.5)
 check(room.tile_position(id).is_equal_approx(move_to) and int(room.buildings[id].rotation)==2,"actual click moves and rotates the same structure")
 check(_without_transform(room.buildings[id])==original_instance and Vector2(room.gold,room.electricity).is_equal_approx(paid),"move preserves the exact instance and investment")
 await _mark("05-safe-move-720",{"rotation":int(room.buildings[id].rotation),"center":[move_to.x,move_to.y],"instance_id":serial})
 await key(KEY_Z)
 await advance(.6)
 check(room.tile_position(id).is_equal_approx(placed) and int(room.buildings[id].rotation)==rotation,"actual Z restores original center and rotation")
 check(_without_transform(room.buildings[id])==original_instance and Vector2(room.gold,room.electricity).is_equal_approx(paid),"undo keeps the exact instance and balances")
 await _mark("06-undo-720",{"rotation":int(room.buildings[id].rotation),"center":[placed.x,placed.y],"instance_id":serial})
 grid_observations["purchase"]={"wallet_before":[start.x,start.y],"cost":[cost.x,cost.y],"instance_id":serial}

func _without_transform(building: Dictionary) -> Dictionary:
 var state:=building.duplicate(true)
 state.erase("position")
 state.erase("rotation")
 return state

func _start_build(kind: String) -> void:
 await key(KEY_B)
 await advance(.3)
 check(game.ui.actions.has("build:"+kind),"actual B palette contains "+kind)
 if not game.ui.actions.has("build:"+kind):return
 await click(game.ui.actions["build:"+kind])
 await advance(.32)
 check(game.construction.kind==kind,"actual palette click selects "+kind)

func _pick_center(room,kind: String,rotation: int,near: Vector2,ignore: int=-1) -> Vector2:
 var best:=Vector2.INF
 var distance:=INF
 for point in _points(room,kind,rotation):
  var separation: float=point.distance_squared_to(near)
  if separation<distance and _geometry(room,point,kind,rotation,ignore)=="":
   best=point
   distance=separation
 return best

func _pick_rejected_door(room,kind: String,rotation: int) -> Vector2:
 var desired: Vector2=room.door_position()-room.door_normal()*35.0
 var best:=Vector2.INF
 var distance:=INF
 for point in _points(room,kind,rotation):
  var separation: float=point.distance_squared_to(desired)
  if separation<distance and "door" in _geometry(room,point,kind,rotation,-1).to_lower():
   best=point
   distance=separation
 return best

func _points(room,kind: String,rotation: int) -> Array[Vector2]:
 var rect: Rect2=room.spatial.grid_bounds()
 var start:=Vector2i(rect.position)
 var end:=Vector2i(rect.end)
 var grid: Array[Vector2]=[]
 for y in range(start.y+16,end.y,16):
  for x in range(start.x+16,end.x,16):
   var point: Vector2=room.spatial.aligned(Vector2(x,y),kind,rotation)
   grid.append(point)
 return grid

func _geometry(room,point: Vector2,kind: String,rotation: int,ignore: int) -> String:
 return room.spatial.geometry_reason(point,ignore,{},kind,rotation)

func _populate_dense(model,room) -> void:
 var order := ["shock","heavy","repair","auto_repair","frost","flame","shield",
  "plasma","economy","enhancer","decoy","antenna","barrier"]
 var doorward: Vector2=room.door_position()-room.door_normal()*54+Vector2(50,0)
 var near_door := _pick_center(room,"turret",0,doorward)
 check(near_door.is_finite() and model.place_building("turret",near_door,0),"real paid Needle in reach of the room entrance")
 var targets: Array[Vector2]=[]
 var floor: Rect2=room.spatial.grid_bounds()
 for row in range(6):
  for column in range(5):
   targets.append(floor.position+floor.size*Vector2(float(column+1)/6.0,float(row+1)/7.0))
 var next_target := 0
 for index in range(order.size()):
  var kind: String=order[index]
  var rotation:=index%2
  var point:=_pick_center(room,kind,rotation,targets[next_target])
  next_target+=1
  if point.is_finite():
   check(model.place_building(kind,point,rotation),"real paid grid placement "+kind)
 while room.buildings.size()<TARGET_COUNT:
  var point:=_pick_center(room,"turret",0,targets[next_target])
  next_target+=1
  if not point.is_finite():break
  if not model.place_building("turret",point,0):
   check(false,"real paid compact placement failed")
   break
 for id in room.buildings:
  var building: Dictionary=room.buildings[id]
  var level_target:=10 if building.kind in ["turret","generator","heavy","frost"] else 4
  while int(building.level)<level_target:
   var succeeded: bool
   if int(building.level)==4:
    succeeded=model.specialize_building(id,StrategyCatalog.branches(building.kind)[0])
   else:
    succeeded=model.upgrade_building(id)
   check(succeeded,"real paid upgrade of "+building.kind)
   if not succeeded:break
  var position: Vector2=room.tile_position(id)
  dense_receipt.append({"id":id,"kind":building.kind,"level":building.level,"rotation":building.rotation,"center":[position.x,position.y]})
 game.focus_camera(true)
 game.ui.update_match()

func _prepare_live_combat(model,room) -> void:
 var hunter=model.hunter
 hunter.boss_policy.enabled=false
 hunter.position=room.door_approach()
 hunter.target=room.index
 hunter.state=HunterState.State.ATTACK
 hunter.cooldown=.35
 hunter.arcane.cooldown=999
 hunter.nightmare.cooldown=999
 hunter.tactical_cooldown=999
 model.time=model.preparation+.1
 model.evolution.evolution_level=10
 model.evolution.final_revealed=true
 model.running=true
 game.presentation.identity.heading=Vector2.DOWN
 game.ui.update_match()

func point_mouse(world: Vector2):
 # Keep the native cursor in sync with the synthetic motion event. The
 # production controller also re-reads the viewport pointer on each tick.
 var screen: Vector2=root.get_final_transform()*game.world_to_screen(world)
 Input.warp_mouse(screen)
 await process_frame
 await super.point_mouse(world)

func advance(seconds):
 for frame in range(maxi(1,ceili(float(seconds)/STEP))):
  game.construction.update(STEP)
  if game.mode=="match":
   game.focus_camera(false,STEP)
   game.presentation.update(STEP,game.model)
   game.ui.items_ui.update(STEP)
   game.ui.update_match()
  await _draw_recorded_frame()

func _draw_recorded_frame() -> void:
 await _render_frame()
 if grid_recording:
  var viewport:=root.get_texture().get_image()
  if viewport.get_size()!=Vector2i(1280,720) or viewport.save_png(capture_directory.path_join("frames/%04d.png" % frame_number))!=OK:
   check(false,"native recording frame could not be saved")
  frame_number+=1

func _mark(name: String,details: Dictionary) -> void:
 details["frame"]=frame_number-1
 grid_observations[name]=details
 await capture(name)

func _write_receipt() -> void:
 var report:=FileAccess.open(capture_directory.path_join("grid-capture.json"),FileAccess.WRITE)
 if report!=null:
  report.store_string(JSON.stringify({
   "viewport":[1280,720],"fps":24,"frame_count":frame_number,"checks":checks,"failures":failures,
   "fixture":"Prepared seeded Endless match with staged credits and door/bed levels. Placement, rotation, rejections, movement and undo use native scripted InputEvents. The dense board is purchased and upgraded through the model between the two segments. The later sequence is live model combat.",
   "observations":grid_observations,"dense_buildings":dense_receipt,
  },"  ")+"\n")
 print("GRID_CAPTURE_FRAMES=",frame_number," DENSE_BUILDINGS=",dense_receipt.size())
