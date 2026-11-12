extends SceneTree
var checks=0
var failures=0
func ck(value,label):
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 for mode in ["standard","hard","hell"]:
  for kind in StrategyCatalog.ARCHETYPE_IDS:
   var m=MatchModel.new();m.configure_map("abandoned_dorm");m.configure_match(mode);m.configure_strategy(41,kind)
   m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();m.time=m.preparation+.1;m.bot_claimed=5
   var r=m.player();r.door_level=4;r.door_hp=r.max_hp()
   var h=m.hunter;h.boss_policy.enabled=false;h.position=r.door_approach();h.target=0;h.state=HunterState.State.ATTACK;h.cooldown=0;h.arcane.cooldown=6
   var hp=r.door_hp;m.tick(.01)
   ck(h.attacks==0 and r.door_hp==hp,"first real model contact is harmless "+kind+mode)
   ck(h.windup_remaining>0,"first basic strike has explicit real windup "+kind+mode)
   var events=m.presentation_events.filter(func(e):return e.type=="archetype_warning" and e.get("archetype","")==kind)
   ck(events.size()==1 and events[0].delay>0,"correct archetype warning event exactly once "+kind+mode)
   var warning=h.windup_remaining;m.tick(warning*.49)
   ck(h.attacks==0 and r.door_hp==hp,"actual partial windup cannot cause premature basic damage "+kind+mode)
   m.tick(warning*.51+.02)
   ck(h.attacks==1 and r.door_hp<hp,"actual post-warning strike works once "+kind+mode)
   var after=r.door_hp;h.position=r.corridor_anchor();h.state=HunterState.State.ATTACK;h.cooldown=0;m.tick(.01)
   ck(r.door_hp==after and h.state==HunterState.State.MOVE,"invalid remote basic strike corrects to legal movement "+kind+mode)
 print("OVERHAUL_QA_CONTACT_CHECKS=",checks," FAILURES=",failures);quit(1 if failures else 0)
