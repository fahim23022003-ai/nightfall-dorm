extends SceneTree
var checks=0
var failures=0
func ck(value,label):
 checks+=1
 if not value:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func fixture(endless=false):
 var m=MatchModel.new()
 if endless:m.configure_endless("abandoned_dorm","standard",3,991)
 else:m.configure_map("abandoned_dorm");m.configure_match("standard");m.configure_strategy(1,"witch")
 m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();m.bot_claimed=5;m.time=m.preparation+1
 for r in m.rooms:
  r.door_level=4;r.door_hp=r.max_hp();r.bot_timer=1000
  if r.index>0:r.owner=r.index;r.profile=Catalog.BOT_PROFILES[r.index-1];r.sleeping=true;r.closed=true;r.resident_position=r.bed_position()
 m.hunter.boss_policy.enabled=false
 return m
func launch(m,target=0):
 var h=m.hunter;var r=m.rooms[target]
 h.target=target;h.position=r.door_approach()+r.door_normal()*100;h.state=HunterState.State.MOVE;h.arcane.cooldown=0
 for i in range(26):
  m.tick(.05)
  if not h.arcane.bolt.is_empty():break
 ck(not h.arcane.bolt.is_empty() and h.arcane.casts.get("cursed_projectile",0)==1,"actual warned Witch projectile launched before terminal")
 return h
func cleared(h,label):
 ck(h.arcane.bolt.is_empty() and h.arcane.action=="" and h.arcane.target==-1 and h.arcane.warning==0 and h.arcane.dash==0 and h.arcane.defensive_flash==0,label+" clears every transient ability presentation/state")
 ck(h.arcane.casts.get("cursed_projectile",0)==1,label+" retains actual cast telemetry")
func run():
 var m=fixture();var h=launch(m);var hp=m.player().door_hp;var cooldown=h.arcane.cooldown
 m.apply_target_damage(1,1e9,0)
 cleared(h,"actual lethal damage immediate")
 ck(h.hp==0 and h.state==HunterState.State.DEAD,"actual caster defeated")
 ck(h.arcane.cooldown==cooldown,"cleanup cannot reset cooldown as a side effect")
 m.tick(.05);ck(m.result=="victory","actual terminal victory")
 for i in range(20):m.tick(.1)
 cleared(h,"twenty terminal ticks");ck(m.player().door_hp==hp,"dead projectile cannot damage after terminal")
 m=fixture(true);h=launch(m);hp=m.player().door_hp;m.apply_target_damage(1,1e9,0);m.tick(.05)
 ck(m.endless.phase=="intermission" and m.result=="","actual Endless defeated wave becomes intermission")
 cleared(h,"actual between-wave pause")
 var data=ReplaySnapshot.encode(m);ck(not data.is_empty(),"safe checkpoint remains valid after real wave cleanup")
 ck(m.continue_wave("supply"),"real next wave continues")
 ck(m.hunter!=h and m.hunter.arcane.bolt.is_empty() and m.hunter.arcane.action=="","fresh encounter never inherits old bolt or warning")
 m=fixture();h=launch(m,1);m.spawn_undead(1);ck(m.minions.size()==1,"actual subordinate exists for valid independent-room elimination")
 if m.minions.size()==1:
  var u=m.minions[0];var r=m.player();r.door_hp=0;u.target=0;u.position=r.bed_position();u.cooldown=0
  m.tick(.01)
  ck(not r.alive and m.result=="defeat" and m.eliminations==1,"real legal undead bed contact defeats human while Hunter targets another room")
  cleared(h,"actual player defeat with unrelated projectile in flight")
 m=fixture();h=launch(m);h.boss_policy={"enabled":true,"opening":0.0,"hp_fraction":.55,"deadline":210.0}
 m.apply_target_damage(1,h.max_hp,0)
 ck(h.transformed and h.state==HunterState.State.TRANSFORM and h.hp>0,"actual eligible guarded transformation uses same living actor")
 cleared(h,"actual transformation cancels stale prior-form projectile")
 m=fixture();h=launch(m);m.player().gold=1000;m.player().electricity=1000;ck(m.buy("barrier",0),"actual reflection machine purchased")
 h.hp=1;var r=m.player();h.position=r.door_approach();h.target=0;h.state=HunterState.State.ATTACK
 m.apply_room_damage(0,100,"curse",1,true,{"type":"magic","element":"neutral"})
 ck(h.hp==0 and h.state==HunterState.State.DEAD,"real reflected Magic can defeat caster")
 cleared(h,"reflection-caused death cancels in-flight bolt without recursion")
 print("OVERHAUL_QA_CLEANUP_CHECKS=",checks," FAILURES=",failures);quit(1 if failures else 0)
