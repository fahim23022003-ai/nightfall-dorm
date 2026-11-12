extends SceneTree
var checks=0
var failures=0
func check(value,message=""):
 checks+=1
 if not value:failures+=1;push_error("Huntercheck%d %s" % [checks,message])
func fixture(kind):
 var m=MatchModel.new();m.configure_map("abandoned_dorm");m.configure_match("standard",{});m.configure_strategy(7,kind);m.running=true;m.player_room=0;m.time=40
 var r=m.rooms[0];r.owner=0;r.sleeping=true;r.closed=true;r.gold=1000;r.electricity=1000;r.door_level=4;r.door_hp=r.max_hp()
 m.hunter.position=r.door_approach();m.hunter.target=0;m.hunter.state=HunterState.State.ATTACK;m.hunter.arcane.cooldown=0
 return m
func _initialize():call_deferred("run")
func run():
 for kind in StrategyCatalog.ARCHETYPE_IDS:
  var m=fixture(kind);check(m.hunter.archetype==kind,"configure")
  for pose in ["idle","walk","attack","hurt","defend","special","death"]:check(ResourceLoader.exists("res://assets/hunters/"+kind+"_"+pose+".svg"),"art")
 for kind in ["witch","electric","storm"]:
  var m=fixture(kind);var r=m.rooms[0];var hp=r.door_hp
  check(m.hunter.arcane.tick(m.hunter,m,.1),"startwarning")
  check(r.door_hp==hp,"warningnofakedamage")
  for i in range(40):m.hunter.arcane.tick(m.hunter,m,.05)
  check(r.door_hp<hp,"realabilitydamage")
  check(m.hunter.arcane.casts.size()==1,"onecast")
  check(m.hunter.arcane.cooldown>10,"finitecooldown")
  if kind=="electric":
   check(r.magic_state.disrupt==3,"realdisruption")
   MagicDefense.tick(m,3.1);check(r.magic_state.disrupt==0,"restored")
 var boss=fixture("crusher");boss.hunter.transformed=true;boss.hunter.hp=1000;boss.hunter.arcane.cooldown=0
 var hp=boss.rooms[0].door_hp
 boss.hunter.arcane.tick(boss.hunter,boss,.1)
 for i in range(25):boss.hunter.arcane.tick(boss.hunter,boss,.05)
 check(boss.rooms[0].door_hp<hp,"souldraindamage");check(boss.hunter.hp>1000,"boundedheal")
 check(boss.hunter.hp<=1000+boss.hunter.max_hp*.015,"healcap")
 boss.hunter.arcane.cooldown=0;boss.hunter.state=HunterState.State.MOVE
 boss.hunter.arcane.tick(boss.hunter,boss,.1)
 for i in range(15):boss.hunter.arcane.tick(boss.hunter,boss,.05)
 check(boss.hunter.arcane.dash>0,"shadowdash")
 for kind in StrategyCatalog.ARCHETYPE_IDS:
  var code=ChallengeCode.encode({"map":"abandoned_dorm","seed":17,"archetype":kind,"difficulty":"standard","preset":0,"gear":0});check(ChallengeCode.decode(code).ok,"challenge")
 print("OVERHAUL_HUNTER_CHECKS=%d FAILURES=%d" % [checks,failures]);quit(1 if failures else 0)
