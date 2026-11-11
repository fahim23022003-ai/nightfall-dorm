extends SceneTree
var checks=0
var failures=0

func check(value: bool,label: String):
 checks+=1
 if not value:
  failures+=1
  push_error("FURNITURE: "+label)

func _initialize(): call_deferred("run")

func run():
 for index in range(6):
  var m=MatchModel.new()
  var room=m.rooms[index]
  check(not m.can_walk(room.bed_position()),"bed has physical footprint")
  check(not m.can_walk(room.cabinet_position()+Vector2(0,12)),"cabinet base blocks player feet")
  check(not m.can_walk(room.plant_position()+Vector2(0,12)),"plant pot blocks player feet")
  m.claim_room(index)
  m.player_position=room.door_position()+Vector2(0,22 if index<3 else -22)
  for step in range(150):
   if m.player_position.distance_to(room.bed_position())<=55: break
   m.move_player((room.bed_position()-m.player_position).normalized(),0.02)
  check(m.player_position.distance_to(room.bed_position())<=55,"door-to-bed approach remains reachable in room %d" % index)
  check(m.sleep_player() and room.sleeping,"sleep interaction succeeds outside mattress collision")
 print("FURNITURE_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
