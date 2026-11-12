extends SceneTree
# Independent state-aware movement checks. The graph allows room interiors for
# legitimate breaches; public Hunter states must still respect intact doors.
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("VISUAL NAV: "+label)
func fixture(stage,mode):
 var m=MatchModel.new();m.reset(503)
 m.configure_match(mode);m.configure_stage(stage)
 for r in m.rooms:r.owner=r.index;r.sleeping=true;r.closed=true;r.alive=true
 m.time=m.preparation+.1;m.bot_claimed=5
 return m
func run():
 var approaches=0
 for stage in StageCatalog.STAGES:
  for mode in ["standard","hard","hell"]:
   for index in range(6):
    var m=fixture(stage.id,mode);var h=m.hunter;var room=m.rooms[index]
    h.state=HunterState.State.MOVE;h.target=index
    var hp=room.door_hp
    for step in range(1600):
     var before=h.position
     m.time+=.05;h.tick(.05,m)
     check(m.navigation_walkable(h.position),"real path remains on floor "+stage.id)
     check(h.position.distance_to(before)<=h.speed*.05+.001,"no teleport")
     check(not room.bounds().grow(-12).has_point(h.position),"closed target room not entered")
     check(room.door_hp==hp,"approach does not damage door")
     if h.state==HunterState.State.ATTACK:break
    check(h.state==HunterState.State.ATTACK and h.position.distance_to(room.door_approach())<3,"all rooms reached at valid contact")
    approaches+=1
    # Out of range ATTACK state must recover its route without dealing damage.
    h.position=room.corridor_anchor();h.state=HunterState.State.ATTACK;h.cooldown=0
    h.tick(.05,m)
    check(h.state==HunterState.State.MOVE and room.door_hp==hp,"out of contact strike rejected")
    h.position=room.door_approach();h.state=HunterState.State.ATTACK;h.cooldown=0
    h.tick(.05,m)
    check(room.door_hp<hp and room.door_hp>0,"valid contact strike changes actual HP")
    # A real destroyed-door state permits the same physical graph to enter.
    room.door_hp=0;h.state=HunterState.State.ATTACK
    h.tick(.05,m)
    check(h.state==HunterState.State.BREACH,"destroyed door starts breach")
    for step in range(800):
     var before=h.position
     h.tick(.05,m)
     check(m.navigation_walkable(h.position),"breach stays on floor")
     check(h.position.distance_to(before)<=h.speed*.05+.001,"breach does not teleport")
     if not room.alive:break
    check(not room.alive and h.state==HunterState.State.EXIT,"actual bed contact kills then exits")
    check(h.position.distance_to(room.bed_position())<12,"death occurs at real attack position")
 print("VISUAL_NAV_CHECKS=",checks," APPROACHES=",approaches," FAILURES=",failures)
 quit(0 if failures==0 else 1)
