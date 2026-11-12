extends SceneTree
# Focused production-model simultaneous-combination fixtures, not balance evidence.
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("ADVANCED COMBO: "+label)
func _initialize():call_deferred("run")
func fixture():
 var m=MatchModel.new()
 m.configure_match("hell")
 m.configure_stage("stage_5")
 m.claim_room(0)
 m.player_position=m.player().bed_position()
 m.sleep_player()
 m.bot_claimed=5;m.time=m.preparation+100
 m.player().gold=10000;m.player().electricity=10000
 m.player().door_level=4;m.player().door_hp=m.player().max_hp()
 m.hunter.target=0;m.hunter.position=m.player().door_approach();m.hunter.state=HunterState.State.ATTACK
 m.hunter.boss_policy.enabled=false;m.hunter.tick(.01,m);m.hunter.cooldown=100
 m.hunter.hp=100000;m.hunter.max_hp=100000
 return m
func run():
 var shot_counts=[]
 for boosted in [false,true]:
  var m=fixture()
  m.hunter.position=m.player().tile_position(0)
  check(m.player().build("turret",0),"real turret purchase")
  m.items.apply("inferno",m)
  if boosted:m.items.apply("overdrive",m)
  var initial=m.hunter.hp
  for i in range(80):
   m.items.tick(.1,m)
   m._turrets(.1)
   m._advance_projectiles(.1)
  shot_counts.append(m.shots)
  check(m.hunter.hp<initial and m.player().damage_dealt>0,"actual turret impacts damage boss")
  check(m.items.burn_remaining>0,"actual owned impacts keep one burn alive")
  var hp=m.hunter.hp
  # Stop all pending shots, so the next interval isolates DOT from direct damage.
  m.projectiles.clear()
  m.items.tick(1,m)
  check(is_equal_approx(hp-m.hunter.hp,ItemCatalog.TUNING.burn_dps),"simultaneous overdrive does not multiply burn DPS")
  m.items.tick(30,m)
  hp=m.hunter.hp;m.items.tick(1,m)
  check(m.hunter.hp==hp and not m.items.timers.has("inferno") and not m.items.timers.has("overdrive"),"both buffs expire and damage ends")
 check(shot_counts[1]>shot_counts[0]*1.2,"simultaneous Overdrive increases actual launches")
 for effect in ["decoy","smoke"]:
  var m=fixture()
  var h=m.hunter
  h.transformed=true
  h.position=m.map_data.hunter_spawn;h.state=HunterState.State.MOVE
  m.items.apply("frost",m)
  m.items.apply(effect,m)
  check(m.items.timers.has("frost") and m.items.timers.has(effect),"Frost and "+effect+" simultaneously active")
  var before=h.position
  h.tick(.1,m)
  check(before.distance_to(h.position)<=h.speed*.1+.01,"slow/control respects actual movement speed")
  check(is_equal_approx(m.items.speed_factor(h),.75),"Reaper keeps configurable Frost resistance")
  check(m.navigation_walkable(h.position),"combined control stays in valid geometry")
  m.items.tick(1.1,m)
  var alternate="smoke" if effect=="decoy" else "decoy"
  check(m.items.can_activate(alternate,m)!="","shared control recovery blocks chaining while slowed")
  m.items.tick(21,m)
  check(m.items.speed_factor(h)==1 and not m.items.timers.has(effect),"slow/control both expire")
  # At an actual doorway after recovery, the same Reaper must resume real specials.
  h.position=m.player().door_approach();h.state=HunterState.State.ATTACK;h.target=0;h.cooldown=0
  h.boss_cooldowns={"scythe":100.0,"siege":0.0,"surge":100.0}
  var hp=m.player().door_hp
  h.tick(.01,m)
  check(h.boss_attack=="siege" and m.player().door_hp==hp,"Reaper siege warning resumes after control expires")
  h.tick(BossCatalog.ATTACKS.siege.windup+.01,m)
  check(m.player().door_hp<hp and h.boss_attack=="","Reaper charged impact executes after warning")
 print("ADVANCED_COMBO_CHECKS=",checks," FAILURES=",failures," SHOTS=",shot_counts)
 quit(0 if failures==0 else 1)
