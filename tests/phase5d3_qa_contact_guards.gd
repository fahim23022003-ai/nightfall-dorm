extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("CONTACT QA: "+label)
func fixture(map,archetype):
 var m=MatchModel.new();m.configure_stage("stage_1");m.configure_map(map);m.configure_match("hell");m.configure_strategy(73,archetype,"");m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();m.preparation=0;m.bot_claimed=5
 var r=m.player();var h=m.hunter;h.boss_policy.enabled=false;h.target=r.index;h.position=r.door_approach();h.state=HunterState.State.ATTACK;h.tactical_action="pressure" if archetype=="crusher" else "conceal" if archetype=="stalker" else "dash";h.tactical_windup=.9;h.tactical_cooldown=20;h.tactical_recovery=.7;h.pressure_remaining=3;h.dash_remaining=1;h.conceal_remaining=2;h.charged_ready=true;h.cooldown=1;r.repair_factor=.4
 return m
func run():
 for map in MapCatalog.IDS:
  for archetype in StrategyCatalog.ARCHETYPE_IDS:
   for kind in ["lost_contact","door_broken","door_open"]:
    var m=fixture(map,archetype);var h=m.hunter;var r=m.player()
    if kind=="lost_contact":h.position=m.step_navigation(r.door_approach(),r.corridor_anchor(),20,"qa_contact")
    elif kind=="door_broken":r.door_hp=0
    else:r.closed=false
    check(m.navigation_walkable(h.position),"controlledcontactfixtureisonactualvalidmaproute")
    var hp=r.door_hp;var attacks=h.attacks;var counts=h.ability_counts.duplicate();var position=h.position
    m.tick(.05)
    check(h.state==(HunterState.State.MOVE if kind=="lost_contact" else HunterState.State.BREACH),"actualcontact/doortransitionpreemptswindup/recovery "+map+archetype+kind)
    check(h.attacks==attacks and r.door_hp==hp and h.position==position,"transitiondoesnotremotelyattackoradvanceonstalecontact")
    check(h.tactical_action=="" and h.tactical_windup==0 and h.tactical_recovery==0 and h.pressure_remaining==0 and h.dash_remaining==0 and h.conceal_remaining==0 and not h.charged_ready,"allnormaltacticstateclearsbeforeinvalidcontactcanexecute")
    check(r.repair_factor==1.0 and h.ability_counts==counts,"invalidsiegerestoresrepairfactorwithoutfakeabilityactivation")
  var m=fixture(map,"crusher");var h=m.hunter;var r=m.player();h.transformed=true;h.boss_attack="scythe";h.boss_attack_target=0;h.surge_remaining=3;r.closed=false;var hp=h.hp
  m.tick(.05)
  check(h.state==HunterState.State.BREACH and h.boss_attack=="" and h.boss_attack_target==-1 and h.surge_remaining==0,"Reaperopen-doortransitioncancelsoldspecialandshadow")
  check(h.transformed and h.hp==hp and h.transform_remaining==0,"guardneverretransformsorrefillsReaper")
 print("PHASE5D3_CONTACT_QA_CHECKS=",checks," CASES=50 MAPS=5 FAILURES=",failures)
 quit(1 if failures else 0)
