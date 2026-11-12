extends SceneTree
var checks=0
var failures=0
func check(ok: bool,label: String):
 checks+=1
 if not ok:
  failures+=1
  push_error("MAP CORE: "+label)
func _initialize(): call_deferred("run")
func run():
 for id in MapCatalog.IDS:
  var m=MatchModel.new()
  check(m.configure_map(id),"map config "+id)
  for room in m.rooms:
   check(room.tile_count()>=10 and room.tile_count()<=16,"capacity "+id)
   for i in range(room.tile_count()):
    check(room.bounds().grow(-27).has_point(room.tile_position(i)),"tile bounds "+id)
    check(not room.furniture_blocks(room.tile_position(i)),"tile furniture "+id)
    for j in range(i): check(room.tile_position(i).distance_to(room.tile_position(j))>=54,"spacing")
   var wall=room.bounds().position+Vector2(2,room.bounds().size.y/2)
   if room.door_position().distance_to(wall)>60: check(not m.navigation_walkable(wall),"solid wall rejects wide corridor overlap")
   var player_route=m.player_navigation_path(m.player_position,room.bed_position()+Vector2(40,40))
   check(not player_route.is_empty(),"furniture safe player bed approach "+id+str(room.index))
   var previous=m.player_position
   for goal in player_route:
    var samples=maxi(1,ceili(previous.distance_to(goal)/2))
    for sample in range(samples+1):
     check(m.can_walk(previous.lerp(goal,float(sample)/samples)),"player route collision safe")
    previous=goal
   var route=m.navigation_path(m.player_position,room.door_approach())
   check(not route.is_empty(),"corridor route "+id+str(room.index))
   route=m.navigation_path(room.door_approach(),room.bed_position())
   check(not route.is_empty(),"bed route "+id+str(room.index))
   var pos=m.player_position
   for step in range(1000):
    pos=m.step_navigation(pos,room.bed_position(),12,"probe")
    if pos.distance_to(room.bed_position())<1: break
   check(pos.distance_to(room.bed_position())<1,"incremental path reaches bed "+id+str(room.index))
  m.claim_room(1)
  m.player_position=m.player().bed_position()
  m.sleep_player()
  m.preparation=1000
  for tick in range(600): m.tick(0.1)
  check(m.bot_claimed==5,"five bots claimed "+id)
  for room in m.rooms:
   if room.owner>0: check(room.sleeping and room.income_total>0 and room.buildings.size()>0,"bots arrived/economy "+id+str(room.index))
 print("MAP_CORE_CHECKS=%d FAILURES=%d" % [checks,failures])
 quit(0 if failures==0 else 1)
