extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("SUPPORT ROLE QA: "+label)
func fixture(kind,branch):
 var m=MatchModel.new();m.configure_stage("stage_1");m.configure_strategy(0,"crusher","");m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 var r=m.player();r.bed_level=4;r.door_level=4;r.gold=100000;r.electricity=100000
 check(m.buy(kind,0),"actual testedweaponpurchased")
 for n in range(3):check(m.upgrade_building(0),"actual testedweaponupgraded")
 check(m.specialize_building(0,branch),"actual testedweaponbranchpurchased")
 check(m.buy("turret",1),"neutral secondweaponpurchased")
 m.hunter.state=HunterState.State.MOVE;m.hunter.hp=100000;m.hunter.max_hp=100000
 return m
func relay(m,tile,branch):
 check(m.buy("enhancer",tile),"actualsupportrelaypurchased")
 for n in range(3):check(m.upgrade_building(tile),"actualsupportrelayupgraded")
 check(m.specialize_building(tile,branch),"actualsupportbranchpurchased")
func sample(m,kind,branch,coolants,ballistics):
 var r=m.player();var data=StrategyCatalog.BRANCHES[branch]
 var interval_factor=maxf(.8,1-.1*coolants);var range_factor=maxf(.8,1-.1*ballistics)
 check(is_equal_approx(r.special_factor("interval",.8,1),interval_factor),"onlyCoolingRelayschangegloballyboundedrate")
 check(is_equal_approx(r.special_factor("range",.8,1),range_factor),"onlyBallisticRelayschangegloballyboundedrange")
 var multiplier=1+.35*4.5*(.75*coolants+1.2*ballistics)
 m.hunter.position=r.tile_position(0)+Vector2(20,0);m.projectiles.clear()
 for b in r.buildings.values():b.cooldown=0
 m._turrets(0)
 var ours=m.projectiles.filter(func(s):return s.from==r.tile_position(0))
 var neutral=m.projectiles.filter(func(s):return s.from==r.tile_position(1))
 check(ours.size()==1 and neutral.size()==1,"bothactualweaponslaunchwithoutforeignroleinterference")
 if ours.size()!=1 or neutral.size()!=1:return
 var own_damage=Catalog.BUILDINGS[kind].damage*5*data.damage*multiplier
 var neutral_damage=9*multiplier
 check(is_equal_approx(ours[0].damage,own_damage) and is_equal_approx(neutral[0].damage,neutral_damage),"actualprojectiledamagereceiveseachrolefactoronce")
 check(is_equal_approx(r.buildings[0].cooldown,Catalog.turret_interval(kind,5)*data.interval*interval_factor),"specializedweaponsrateisbranchonceplussoleCoolingfactor")
 check(is_equal_approx(r.buildings[1].cooldown,.9*interval_factor),"neutralgunneverinheritsotherweaponsbranchrate")
 var hp=m.hunter.hp;m._advance_projectiles(1)
 # Arc is Electric magic; the explicit Crusher fixture has Earth affinity.
 # Its impact is resisted10%, while Needle remains neutral Physical.
 var affinity_factor=.9 if kind=="heavy" else 1.0
 check(m.projectiles.is_empty() and is_equal_approx(hp-m.hunter.hp,own_damage*affinity_factor+neutral_damage),"actualimpactcreditsexactexpectedcombineddamage")
 # Own branch range is applied once. Relay effects are the only global factor.
 var range_limit=Catalog.BUILDINGS[kind].range*data.range*range_factor
 for delta in [-1,1]:
  m.projectiles.clear();m.hunter.position=r.tile_position(0)+Vector2(range_limit+delta,0)
  for b in r.buildings.values():b.cooldown=0
  m._turrets(0)
  var fired=m.projectiles.any(func(s):return s.from==r.tile_position(0))
  check(fired==(delta<0),"actualrangeboundaryownbranchonceandsupportonly")
func run():
 for kind in ["turret","heavy"]:
  for branch in StrategyCatalog.branches(kind):
   var m=fixture(kind,branch);var r=m.player()
   check(StrategyCatalog.support(r.buildings[0]).is_empty(),"offensivebranchisnotaglobalsupportdefinition "+branch)
   sample(m,kind,branch,0,0)
   for count in range(1,4):
    relay(m,count+1,"coolant");sample(m,kind,branch,count,0)
   for count in range(1,4):
    relay(m,count+4,"ballistic");sample(m,kind,branch,3,count)
 print("PHASE5D3_SUPPORT_ROLE_QA_CHECKS=",checks," WEAPON_BRANCHES=4 FAILURES=",failures)
 quit(1 if failures else 0)
