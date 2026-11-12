extends SceneTree
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok: failures+=1; push_error(label)
func _initialize():
 for difficulty in ["standard","hard","hell"]:
  var m=MatchModel.new()
  m.configure_match(difficulty)
  m.configure_stage("stage_5")
  m.claim_room(0)
  m.player_position=m.player().bed_position()
  m.sleep_player()
  var h=m.hunter
  check(not h.transformed,"normal at start")
  m.time=m.preparation+100
  h.target=0
  h.state=HunterState.State.ATTACK
  h.position=m.player().door_approach()
  h.hp=h.max_hp*0.5
  var hp=h.hp
  var maximum=h.max_hp
  var id=h.get_instance_id()
  h.tick(0.1,m)
  check(h.state==HunterState.State.TRANSFORM,"transform begins")
  check(h.hp==hp and h.max_hp==maximum,"no health grant")
  for i in range(23): h.tick(0.1,m)
  check(h.state==HunterState.State.TRANSFORM,"animation lasts")
  h.tick(0.11,m)
  check(h.transformed and h.state==HunterState.State.SEEK,"transform exits")
  check(h.get_instance_id()==id,"entity identity preserved")
  h.hurt(1e9)
  h.tick(1,m)
  check(h.state==HunterState.State.DEAD,"no resurrection")
  m.reset()
  check(not m.hunter.transformed,"reset")
 var m=MatchModel.new()
 m.configure_stage("stage_5")
 m.time=300
 m.hunter.state=HunterState.State.SEEK
 m.hunter.tick(0.1,m)
 check(m.presentation_events.size()==1 and m.presentation_events[0].type=="boss_transform","targetless global warning")
 print("BOSS_ARCHITECTURE_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
