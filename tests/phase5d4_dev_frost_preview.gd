extends SceneTree
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize():
 for branch in ["deep_chill","rime_field"]:
  var m=MatchModel.new();m.configure_strategy(17,"crusher");m.player_room=0;m.preparation=0;m.time=1
  var r=m.player();r.owner=0;r.sleeping=true;r.closed=true;r.gold=1e6;r.electricity=1e6;r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp()
  check(r.build("frost",0),"paid Frost purchase")
  for level in range(1,4):check(r.upgrade_building(0),"paid Frost early upgrade")
  var rng=m.random.state;var gold=r.gold;var power=r.electricity
  var preview=BuildingStats.branch_preview(m,r,r.buildings[0],branch)
  check(preview.contains("Hunter move -15% → -15%") and preview.contains("interval +22%") and preview.contains("Reaper half"),"branch preview separates capped main movement from attack interval")
  check(preview.contains("undead move -22%% → -%d%%" % (30 if branch=="deep_chill" else 16)),"branch preview states actual undead movement")
  check(m.random.state==rng and r.gold==gold and r.electricity==power,"truthful preview remains read-only")
  check(r.specialize_building(0,branch),"real exclusive Frost specialization")
  m.hunter.boss_policy.enabled=false;m.hunter.state=HunterState.State.MOVE;m.hunter.target=0;m.hunter.position=r.tile_position(0)+Vector2(10,0);m.hunter.tick(0,m)
  m._turrets(0);m._advance_projectiles(.3)
  var strength=.3 if branch=="deep_chill" else .16
  check(is_equal_approx(m.hunter.suppression_strength,.15) and is_equal_approx(m.hunter.attack_slow_strength,strength),"actual homing hit applies capped movement and separate uncapped attack interval")
  var slow=BuildingStats.frost_status(strength)
  check(is_equal_approx(slow.hunter_move,m.hunter.suppression_strength) and is_equal_approx(slow.hunter_interval,m.hunter.attack_slow_strength),"computed description matches actual status fields")
  var undead=UndeadAgent.new();undead.suppress(strength)
  check(is_equal_approx(1-undead.slow_factor,slow.undead_move),"computed undead movement matches actual separate actor method")
  var text=BuildingStats.format_machine(m,r,r.buildings[0])
  check(text.contains("Hunter move -15%% / attack interval +%d%%" % int(strength*100)),"inspector labels attack interval rather than overstating movement")
  check(text.contains("Reaper move -7.5%% / interval +%d%%" % int(strength*50)),"inspector shows actual half-strength Reaper resistance after movement cap")
  check(text.contains("Undead move -%d%%" % int(strength*100)),"inspector shows separate undead movement effect")
  check(not text.contains("Movement/attack slow"),"ambiguous shared slow claim removed")
 print("PHASE5D4_FROST_PREVIEW_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
