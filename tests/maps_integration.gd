extends SceneTree
var checks=0
var failures=0
var game
func check(ok: bool,label: String):
 checks+=1
 if not ok:
  failures+=1
  push_error("MAP INTEGRATION: "+label)
func _initialize(): call_deferred("run")
func click(point: Vector2,double_click=false):
 point=root.get_final_transform()*point
 var motion=InputEventMouseMotion.new()
 motion.position=point
 motion.global_position=point
 Input.parse_input_event(motion)
 await process_frame
 for pressed in [true,false]:
  var event=InputEventMouseButton.new()
  event.position=point
  event.global_position=point
  event.button_index=MOUSE_BUTTON_LEFT
  event.pressed=pressed
  event.double_click=double_click and pressed
  Input.parse_input_event(event)
  await process_frame
func verify_navigation(definition):
 for index in range(6):
  var model=MatchModel.new()
  model.configure_stage(definition.id)
  var room=model.rooms[index]
  var goal=room.bed_position()+Vector2(40,40)
  var path=model.player_navigation_path(model.player_position,goal)
  check(not path.is_empty(),"player route exists "+definition.id+" room"+str(index))
  var previous=model.player_position
  for point in path:
   var samples=maxi(1,ceili(previous.distance_to(point)/5))
   var clear=true
   for sample in range(samples+1):
    if not model.navigation_walkable(previous.lerp(point,float(sample)/samples)): clear=false; break
   check(clear,"planned segment stays in traversable geometry "+definition.id+" room"+str(index)+" segment"+str(previous)+"→"+str(point))
   var steps=0
   while model.player_position.distance_to(point)>2 and steps<1000:
    model.move_player((point-model.player_position).normalized(),minf(0.02,model.player_position.distance_to(point)/180))
    steps+=1
   if model.player_position.distance_to(point)>3: print("NAV_STALL map=",model.map_id," room=",index," position=",model.player_position," goal=",point," route=",path)
   check(model.player_position.distance_to(point)<=3,"real player follows room route without walls "+definition.id+" room"+str(index))
   previous=point
  # Generic valid point below the bed must also route around its solid footprint.
  var bottom=room.bed_position()+Vector2(0,50)
  var bottom_path=model.player_navigation_path(model.player_position,bottom)
  check(not bottom_path.is_empty(),"generic bed-bottom goal has furniture-safe route")
  for point in bottom_path:
   var steps=0
   while model.player_position.distance_to(point)>2 and steps<1000:
    model.move_player((point-model.player_position).normalized(),minf(0.02,model.player_position.distance_to(point)/180))
    steps+=1
   check(model.player_position.distance_to(point)<=3,"player can route around solid bed to generic valid goal")
  check(model.player_position.distance_to(room.bed_position())<60,"bed reachable within sleep radius")
  check(model.claim_room(index) and model.sleep_player(),"real arrival can claim and sleep")
  if not room.sleeping:
   model.player_position=room.bed_position()
   model.sleep_player() # Isolate hunter checks even if preceding player route failed.
  var old_gold=room.gold
  room.tick_economy(1)
  check(room.gold>old_gold,"bed earns after arrival")
  model.time=model.preparation
  var h=model.hunter
  var attacked=false
  var crossed_wall=false
  var teleported=false
  for step in range(3000):
   var before=h.position
   h.tick(0.05,model)
   if before.distance_to(h.position)>h.speed*0.05+0.1: teleported=true
   if not model.navigation_walkable(h.position): crossed_wall=true
   if room.door_hp<room.max_hp(): attacked=true; break
  check(attacked,"hunter reaches and attacks occupied room "+definition.id+" room"+str(index))
  check(not crossed_wall and not teleported,"hunter approaches through geometry without teleport")
  check(h.position.distance_to(room.door_approach())<5,"hunter attacks at actual door")
  check(model.presentation_events.any(func(e):return e.type=="encounter" and e.room==index),"real map encounter alert source")
  # Force only remaining door HP, then exercise genuine breach and exit movement.
  room.door_hp=1
  h.cooldown=0
  for step in range(2500):
   h.tick(0.05,model)
   if not room.alive and h.state==HunterState.State.SEEK: break
  if room.alive: print("BREACH_STALL map=",model.map_id," room=",index," hunter=",h.position," state=",h.state," target=",h.target," hp=",room.door_hp)
  check(not room.alive,"hunter breaches and eliminates correct room "+definition.id+" room"+str(index))
  check(h.state==HunterState.State.SEEK,"hunter exits breached room and resumes navigation")
  check(model.presentation_events.any(func(e):return e.type=="door_break" and e.room==index),"door break event on every map")
  check(model.presentation_events.any(func(e):return e.type=="elimination" and e.room==index),"elimination event on every map")
func verify_bots(definition):
 var model=MatchModel.new()
 model.configure_stage(definition.id)
 model.claim_room(0)
 model.player_position=model.player().bed_position()
 model.sleep_player()
 model.preparation=200 # Isolate earned-resource bot arrival before hunter combat.
 var previous={}
 var jumped=false
 var crossed_wall=false
 for step in range(650):
  model.tick(0.1)
  for room in model.rooms:
   if room.owner<=0: continue
   if previous.has(room.index) and previous[room.index].distance_to(room.resident_position)>12.1: jumped=true
   if not model.navigation_walkable(room.resident_position): crossed_wall=true
   previous[room.index]=room.resident_position
 var owners=[]
 var arrived=0
 var builders=0
 for room in model.rooms:
  if room.owner<=0: continue
  owners.append(room.owner)
  if room.sleeping and room.income_total>0: arrived+=1
  if room.buildings.size()>0: builders+=1
 check(model.bot_claimed==5 and owners.size()==5,"five bots claim valid separate rooms "+definition.id)
 check(arrived==5,"five bots reach beds and earn gold "+definition.id)
 check(builders==5,"five bots build using earned resources "+definition.id)
 check(not crossed_wall and not jumped,"bot routes respect geometry without teleport "+definition.id)
func run():
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://maps-independent-ui-"+str(OS.get_process_id())+".json")
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 var ids=[]
 for definition in StageCatalog.STAGES:
  print("MAP_INTEGRATION_STAGE_START=",definition.id)
  verify_navigation(definition)
  verify_bots(definition)
  var model=MatchModel.new()
  check(model.configure_stage(definition.id),"stage config "+definition.id)
  check(model.map_id==definition.map,"stage loads declared map "+definition.id)
  check(not model.map_id in ids,"each current stage has distinct map")
  ids.append(model.map_id)
  check(model.rooms.size()==6,"six valid rooms for player and five bots")
  for room in model.rooms:
   check(room.tile_count()>=10 and room.tile_count()<=16,"expanded room capacity "+definition.id+" room"+str(room.index))
   var tangent=Vector2(-room.door_normal().y,room.door_normal().x)
   var frame=room.door_position()+tangent*35-room.door_normal()
   check(not model.navigation_walkable(frame) and not model.can_walk(frame),"wide corridor cannot bypass wall beside door")
   room.closed=true
   check(not model.can_walk(room.door_position()-room.door_normal()*20),"closed room rejects player access")
   room.closed=false
   for i in range(room.tile_count()):
    var pad=Rect2(room.tile_position(i)-Vector2(26,26),Vector2(52,52))
    check(room.bounds().grow(-3).encloses(pad),"build pad inside room")
    check(not room.furniture_blocks(room.tile_position(i)),"build pad clear of furniture")
    check(room.tile_position(i).distance_to(room.bed_position())>=46,"bed remains accessible")
    check(room.tile_position(i).distance_to(room.door_position())>=43,"door remains accessible")
    for j in range(i):
     check(not pad.intersects(Rect2(room.tile_position(j)-Vector2(26,26),Vector2(52,52))),"build pads cannot overlap")
   room.owner=0
   room.sleeping=true
   room.bed_level=4
   room.gold=100000
   room.electricity=100000
   var high=room.tile_count()-1
   var funds=Vector2(room.gold,room.electricity)
   check(room.build("heavy",high),"upper slot builds")
   check(not room.build("heavy",high),"upper slot duplicate purchase rejected")
   check(room.upgrade_building(high),"upper slot upgrade")
   var paid=funds-Vector2(room.gold,room.electricity)
   check(room.building_refund(high).is_equal_approx(paid*0.5),"upper slot paid investment quote")
   var before=Vector2(room.gold,room.electricity)
   check(room.sell_building(high),"upper slot sale")
   check(Vector2(room.gold,room.electricity).is_equal_approx(before+paid*0.5),"upper slot exact separate refund")
   check(not room.sell_building(high),"upper slot repeated sale rejected")
   check(room.build("turret",high),"sold upper slot reusable")
  # Every room's tiles must remain visible and selectable through actual input.
  for index in range(6):
   game.start_match()
   game.model.reset(19)
   game.model.configure_stage(definition.id)
   game.model.claim_room(index)
   var resident=game.model.player()
   game.model.player_position=resident.bed_position()
   game.model.sleep_player()
   resident.gold=10000
   resident.electricity=10000
   game.focus_camera(true)
   game.ui.update_match()
   await process_frame
   for tile in range(resident.tile_count()):
    var screen=game.world_to_screen(resident.tile_position(tile))
    check(Rect2(0,76,900,562).has_point(screen),"all pads project into map area "+definition.id+" room"+str(index)+" tile"+str(tile))
    await click(screen)
    game.ui.update_match()
    check(game.selected_tile==tile and game.ui.context_mode=="build","real mouse selects expanded pad")
   var high=resident.tile_count()-1
   game.begin_placement("turret")
   game.ui.update_match()
   await click(game.ui.confirm_button.get_global_rect().get_center())
   await click(game.ui.confirm_button.get_global_rect().get_center(),true)
   check(resident.buildings.size()==1 and resident.buildings.has(high),"upper pad real confirmation/doubleclick creates once")
  print("MAP_INTEGRATION_STAGE_DONE=",definition.id," CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown()
 await create_timer(0.5).timeout
 game.queue_free()
 await process_frame
 print("MAP_INTEGRATION_CHECKS=%d FAILURES=%d" % [checks,failures])
 quit(0 if failures==0 else 1)
