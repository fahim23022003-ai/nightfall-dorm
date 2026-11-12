extends SceneTree
var assertions=0
var failures=0

func check(ok: bool,label: String):
 assertions+=1
 if not ok:
  failures+=1
  push_error("PHASE2_HUNTER_FAIL: "+label)

func fixture(mode="standard",perk=""):
 var game=MatchModel.new()
 game.configure_match(mode,RankCatalog.bonuses([] if perk=="" else [perk]))
 game.claim_room(0)
 game.player_position=game.player().bed_position()
 game.sleep_player()
 game.time=game.preparation+1
 return game

func _initialize(): call_deferred("run")
func run():
 print("PHASE2_HUNTER difficulty and continuous escalation")
 for mode in ["standard","hard"]:
  var game=fixture(mode)
  var h=game.hunter
  var tuning=RankCatalog.DIFFICULTIES[mode]
  check(is_equal_approx(h.hp,Catalog.HUNTER.hp*tuning.hp),"initial difficulty HP "+mode)
  h.hp-=50
  for active in [0.0,20.0,44.99,45.0]:
   game.time=game.preparation+active
   h.tick(0.01,game)
   check(is_equal_approx(h.damage,Catalog.HUNTER.damage*tuning.damage) and is_equal_approx(h.speed,Catalog.HUNTER.speed*tuning.speed),"opening threat remains baseline through first45s "+mode)
  var before_max=h.max_hp
  game.time=game.preparation+45.01
  h.tick(0.01,game)
  check(h.max_hp-before_max<0.01 and h.damage-Catalog.HUNTER.damage*tuning.damage<0.01,"level boundary begins gradual ramp rather than stat jump")
  game.time=game.preparation+49
  h.tick(0.01,game)
  check(h.damage>Catalog.HUNTER.damage*tuning.damage and h.damage<(Catalog.HUNTER.damage+RankCatalog.pressure(mode).damage_growth)*tuning.damage,"mid-ramp damage is between adjacent levels")
  game.time=game.preparation+53
  h.tick(0.01,game)
  check(is_equal_approx(h.max_hp,(Catalog.HUNTER.hp+Catalog.HUNTER.hp_growth)*tuning.hp) and is_equal_approx(h.max_hp-h.hp,50),"completed ramp applies correct HP while preserving damage taken")
  check(is_equal_approx(h.damage,(Catalog.HUNTER.damage+RankCatalog.pressure(mode).damage_growth)*tuning.damage),"completed ramp applies correct damage")
  var late_interval=h.interval
  game.time=game.preparation+10000
  h.tick(0.01,game)
  check(h.interval>=Catalog.HUNTER.min_interval and h.interval<=late_interval,"late attack rate is bounded")
  check(h.speed<=(Catalog.HUNTER.speed+Catalog.HUNTER_ESCALATION.speed_bonus_cap)*tuning.speed,"late movement speed growth is capped")
 print("PHASE2_HUNTER real strike counters and automatic single-use rescue")
 var game=fixture("standard","first_aid")
 var room=game.player()
 var h=game.hunter
 h.state=HunterState.State.ATTACK
 h.target=0
 h.position=room.door_position()+Vector2(0,22)
 room.door_hp=room.max_hp()*0.25+Catalog.HUNTER.damage-1
 var old_hp=room.door_hp
 h.tick(0.01,game)
 check(room.rescue_used and is_equal_approx(room.door_hp,old_hp-h.damage+room.max_hp()*0.1),"real nonlethal door strike automatically triggers rescue")
 check(is_equal_approx(room.door_damage_taken,h.damage),"damage taken records actual strike before healing")
 room.door_hp=room.max_hp()*0.2
 h.cooldown=0
 old_hp=room.door_hp
 h.tick(0.01,game)
 check(is_equal_approx(room.door_hp,maxf(0,old_hp-h.damage)),"later attack cannot reuse one-shot rescue")
 game=fixture("standard","first_aid")
 room=game.player()
 h=game.hunter
 h.state=HunterState.State.ATTACK
 h.target=0
 h.position=room.door_position()+Vector2(0,22)
 room.door_hp=1
 h.tick(0.01,game)
 check(room.door_hp==0 and not room.rescue_used and room.door_damage_taken==1,"lethal door strike never resurrects and clamps actual damage counter")
 h.tick(0.01,game)
 check(h.state==HunterState.State.BREACH,"destroyed door still advances into breach")
 print("PHASE2_HUNTER target intelligence and fair retarget constraints")
 game=fixture()
 room=game.player()
 h=game.hunter
 var other=game.rooms[1]
 other.owner=1
 other.sleeping=true
 other.closed=true
 h.position=Vector2(340,410)
 var plain_score=h.target_score(room)
 room.gold=10000
 room.electricity=1000
 room.build("turret",0)
 room.build("repair",1)
 check(h.target_score(room)>plain_score,"target selection accounts for actual defenses and repair")
 for tile in range(2,6): room.build("heavy",tile)
 var penalty=h.target_score(room)-h.position.distance_to(room.door_position())-room.door_hp*Catalog.HUNTER.door_weight
 check(penalty<=Catalog.HUNTER_ESCALATION.dps_penalty_cap+Catalog.HUNTER_ESCALATION.repair_penalty_cap,"defense-aware target penalty remains bounded")
 room.door_level=4
 room.door_hp=room.max_hp()
 h.state=HunterState.State.ATTACK
 h.target=0
 h.position=room.door_position()+Vector2(0,22)
 h.target_time=1
 h.tick(0.01,game)
 check(h.target==0 and h.state==HunterState.State.ATTACK,"hunter commits instead of instantly switching away")
 h.target_time=Catalog.HUNTER.retarget_seconds+1
 h.tick(0.01,game)
 h.tick(0.01,game)
 check(h.target==1 and h.retargets==1,"clearly weaker alternative attracts a committed hunter after timeout")
 print("PHASE2_HUNTER progress-based siege escape refreshes every retained assessment")
 game=fixture()
 h=game.hunter
 room=game.player()
 other=game.rooms[1]
 other.owner=1
 other.sleeping=true
 other.closed=true
 other.door_level=4
 other.door_hp=other.max_hp()
 room.door_level=2
 room.door_hp=200
 h.state=HunterState.State.ATTACK
 h.target=0
 h.position=room.door_position()+Vector2(0,22)
 h.siege_start_hp=600
 h.cooldown=1000
 h.target_time=Catalog.HUNTER.retarget_seconds+1
 h.tick(0.01,game)
 check(h.state==HunterState.State.ATTACK and h.target==0,"first siege window retains target after meaningful600to200damage")
 check(h.siege_start_hp==200 and h.target_time==0,"retained assessment refreshes its HP and time baseline")
 h.target_time=Catalog.HUNTER.retarget_seconds+1
 h.tick(0.01,game)
 h.tick(0.01,game)
 check(h.target==1 and h.retargets==1,"second stalled200HPwindow escapes even when alternative has stronger door")
 game=fixture()
 h=game.hunter
 room=game.player()
 h.state=HunterState.State.ATTACK
 h.target=0
 h.position=room.door_position()+Vector2(0,22)
 h.siege_start_hp=room.door_hp
 h.cooldown=1000
 h.target_time=Catalog.HUNTER.retarget_seconds+1
 h.tick(0.01,game)
 check(h.state==HunterState.State.ATTACK and h.target==0 and h.retargets==0,"sole valid target is retained without pointless seek loop")
 other=game.rooms[1]
 other.owner=1
 other.sleeping=true
 other.closed=true
 other.door_hp=1
 room.door_hp=h.damage*1.5
 h.siege_start_hp=room.door_hp
 h.target_time=Catalog.HUNTER.retarget_seconds+1
 h.tick(0.01,game)
 check(h.state==HunterState.State.ATTACK and h.target==0,"nearly broken door within two strikes retains commitment")
 print("PHASE2_HUNTER corridor route and no-teleport recovery")
 game=fixture()
 h=game.hunter
 h.position=Vector2(960,410)
 var max_step=0.0
 for i in range(1000):
  var before=h.position
  h.tick(0.05,game)
  max_step=maxf(max_step,before.distance_to(h.position))
  if h.state==HunterState.State.ATTACK: break
 check(h.state==HunterState.State.ATTACK and h.position.distance_to(game.player().door_position())<25,"normal route reaches occupied door")
 check(max_step<=h.speed*0.05+0.001,"navigation never exceeds legal movement speed per tick")
 h.state=HunterState.State.MOVE
 h.speed=0
 var stopped=h.position
 for i in range(50): h.navigate(stopped+Vector2(100,0),0.1)
 check(h.navigation_recoveries==1 and h.state==HunterState.State.SEEK and h.position==stopped,"stuck recovery retargets once without teleporting")
 print("PHASE2_HUNTER_ASSERTIONS=",assertions," FAILURES=",failures)
 quit(1 if failures else 0)
