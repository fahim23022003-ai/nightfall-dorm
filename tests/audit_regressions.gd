extends SceneTree
var failures = 0
var assertions = 0

func check(condition: bool, label: String):
 assertions += 1
 if not condition:
  failures += 1
  push_error("AUDIT FAIL: " + label)

func fresh(seed_value = 1):
 var game = MatchModel.new()
 game.reset(seed_value)
 return game

func occupy(game, index = 0):
 game.claim_room(index)
 game.player_position = game.rooms[index].bed_position()
 game.sleep_player()
 return game.rooms[index]

func advance(game, seconds):
 for i in range(int(seconds*10)):
  game.tick(0.1)

func wait_for_impacts(game):
 # Advance real projectile travel without moving the stationary test target.
 for i in range(600):
  if game.projectiles.is_empty():
   break
  game._advance_projectiles(0.01)

func _initialize():
 call_deferred("run")

func run():
 print("AUDIT regression: eliminated-room transactions")
 var room = RoomState.new()
 room.sleeping = true
 room.gold = 10000
 room.electricity = 1000
 room.door_hp = 50
 room.alive = false
 check(not room.upgrade_bed(), "eliminated room cannot upgrade bed")
 check(not room.upgrade_door(), "eliminated room cannot upgrade door")
 check(not room.repair_door(), "eliminated room cannot repair")
 check(room.gold == 10000 and room.electricity == 1000, "eliminated-room resources unchanged")
 print("AUDIT regression: invalid costs cannot create currency")
 var ledger = RoomState.new()
 for invalid_cost in [Vector2(-1,0),Vector2(0,-1),Vector2(INF,0),Vector2(NAN,0)]:
  check(not ledger.pay(invalid_cost.x,invalid_cost.y) and ledger.gold == 25 and ledger.electricity == 0, "invalid cost rejected without currency mutation")
 print("AUDIT regression: paused and terminal purchase guards")
 var g = fresh()
 room = occupy(g)
 room.gold = 10000
 room.electricity = 1000
 g.running = false
 check(not g.buy("turret",0) and not g.upgrade_bed() and not g.upgrade_door(), "paused purchases rejected")
 check(room.gold == 10000 and room.buildings.is_empty(), "paused resources unchanged")
 g.running = true
 g.result = "victory"
 check(not g.buy("turret",0) and not g.upgrade_bed() and not g.upgrade_door(), "terminal purchases rejected")
 check(room.gold == 10000 and room.buildings.is_empty(), "terminal resources unchanged")
 print("AUDIT regression: stalled frames do not tunnel walls")
 g = fresh()
 g.player_position = g.rooms[0].center()
 g.move_player(Vector2.RIGHT,310.0/180.0)
 check(g.player_position.x < 320, "large movement delta cannot teleport between adjacent rooms through wall")
 print("AUDIT regression: fifth bot uses last nonreserved room")
 g = fresh(11)
 g.player_position = g.rooms[0].center()
 advance(g,25)
 var bots = 0
 for r in g.rooms:
  if r.owner > 0:
   bots += 1
 check(bots == 5 and g.rooms[0].owner == -1, "all five bots claim while player occupies reserved vacant room")
 print("AUDIT regression: cannot sleep after hunter entered room")
 g = fresh()
 g.claim_room(0)
 room = g.player()
 g.player_position = room.bed_position()
 g.time = g.preparation+26
 g.hunter.position = room.center()
 g.hunter.state = HunterState.State.MOVE
 check(not g.sleep_player() and not room.closed and not room.sleeping, "sleep rejected with active intruder inside room")
 var messages = []
 g.feedback.connect(func(message): messages.append(message))
 g.interact()
 check(not messages.is_empty() and "already inside" in messages.back(), "specific intruder feedback survives interaction wrapper")
 print("AUDIT regression: going to sleep reroutes hunter out of a different room")
 g = fresh()
 g.claim_room(0)
 room = g.player()
 g.player_position = room.bed_position()
 g.time = g.preparation+26
 g.hunter.position = g.rooms[1].bed_position()
 g.hunter.target = 1
 g.hunter.state = HunterState.State.MOVE
 check(g.sleep_player() and g.hunter.state == HunterState.State.EXIT and g.hunter.target == 1, "sleep transition preserves hunter exit-room routing")
 var passed_exit_door = false
 for i in range(100):
  g.hunter.tick(0.05,g)
  if g.hunter.position.distance_to(g.rooms[1].door_position()) < 5:
   passed_exit_door = true
  if g.hunter.state == HunterState.State.SEEK:
   break
 check(passed_exit_door and absf(g.hunter.position.y-410)<3, "exposed pursuit resumes via original room doorway before retargeting")
 print("AUDIT regression: eliminated resident dominates simultaneous terminal events")
 g = fresh()
 room = occupy(g,1)
 g.preparation = 0
 room.door_hp = 0
 g.hunter.target = 1
 g.hunter.state = HunterState.State.BREACH
 g.hunter.position = room.bed_position()
 g.hunter.hp = 1
 var ally = g.rooms[0]
 ally.owner = 1
 ally.sleeping = true
 ally.gold = 1000
 ally.build("turret",2)
 room.gold = 1000
 room.build("turret",0)
 # Both residents have real shots in flight; BREACH resolves before impact.
 g._turrets(0.1)
 var launched = g.shots
 check(launched == 2 and g.projectiles.size() == 2, "player and ally shots are pending before breach")
 g.tick(0.1)
 check(not room.alive and g.hunter.hp == 1 and g.result == "defeat", "player elimination has defeat priority over pending lethal teammate impact")
 check(g.shots == launched and g.projectiles.is_empty(), "terminal breach cancels pending shots and prevents further firing")
 print("AUDIT regression: all registered building upgrade ceilings and effects")
 room = RoomState.new()
 room.layout=MapCatalog.map("cursed_mansion").rooms[0] # Authored16-pad room fits all15 registered machines.
 check(room.tile_count()>=Catalog.BUILDINGS.size(),"all-machine cap fixture has enough real map pads")
 room.sleeping = true
 room.bed_level = 4
 room.door_level = 4
 room.gold = 100000
 room.electricity = 100000
 for kind in Catalog.BUILDINGS.keys():
  var tile = room.buildings.size()
  check(room.build(kind,tile), "construct " + kind)
  for level in range(1,Catalog.building_max_level(kind)):
   check(room.upgrade_building(tile), "upgrade " + kind + " to " + str(level+1))
  var before_gold = room.gold
  var before_power = room.electricity
  check(not room.upgrade_building(tile) and room.gold == before_gold and room.electricity == before_power, "cap is atomic for " + kind)
 print("AUDIT regression: capped-level utility effects apply to actual resources and HP")
 room.door_hp = 20
 var income_before = room.gold
 var power_before = room.electricity
 room.tick_economy(1.0)
 check(is_equal_approx(room.gold-income_before,Catalog.BED_INCOME[room.bed_level]*(1+Catalog.BUILDINGS.economy.rate*(4.0+(Catalog.BUILDING_MAX_LEVEL-4)*.5))), "maximum-tier amplifier increases real gold")
 check(is_equal_approx(room.electricity-power_before,Catalog.BUILDINGS.generator.rate*Catalog.BUILDING_MAX_LEVEL), "maximum-tier generator produces real electricity")
 check(is_equal_approx(room.door_hp,20+Catalog.BUILDINGS.repair.rate*Catalog.BUILDING_MAX_LEVEL), "maximum-tier repair facility restores real HP")
 print("AUDIT regression: heavy turret and maximum-tier relay combat effects")
 g = fresh()
 room = occupy(g)
 room.gold = 100000
 room.electricity = 100000
 room.bed_level = 3
 room.door_level = 3
 room.build("heavy",5)
 room.build("enhancer",4)
 for level in range(1,Catalog.BUILDING_MAX_LEVEL):
  check(room.upgrade_building(5),"paid weapon upgrade meets late-tier prerequisites")
  check(room.upgrade_building(4),"paid support upgrade reaches new cap")
 g.hunter.state = HunterState.State.MOVE
 g.hunter.position = room.tile_position(5)+Vector2(Catalog.BUILDINGS.heavy.range-1,0)
 var hunter_hp = g.hunter.hp
 g._turrets(0.1)
 wait_for_impacts(g)
 var expected_damage = Catalog.BUILDINGS.heavy.damage*Catalog.BUILDING_MAX_LEVEL*(1+Catalog.BUILDINGS.enhancer.rate*(4.0+(Catalog.BUILDING_MAX_LEVEL-4)*.5))
 check(is_equal_approx(hunter_hp-g.hunter.hp,expected_damage), "maximum-tier heavy damage and relay multiplier affect real hunter HP")
 check(room.buildings[5].cooldown < Catalog.BUILDINGS.heavy.interval, "maximum-tier heavy fires faster than base")
 check(room.shots == 1 and room.damage_dealt > 0, "player combat statistics recorded separately")
 print("AUDIT regression: hunter growth and active retargeting")
 g = fresh()
 room = occupy(g)
 g.time = g.preparation+Catalog.HUNTER.growth_seconds+Catalog.HUNTER_ESCALATION.ramp_seconds+0.01
 g.hunter.hp -= 50
 var old_max = g.hunter.max_hp
 g.hunter.tick(0.01,g)
 check(g.hunter.level == 2 and is_equal_approx(g.hunter.max_hp,old_max+Catalog.HUNTER.hp_growth), "hunter growth expands maximum HP")
 check(is_equal_approx(g.hunter.hp,g.hunter.max_hp-50), "hunter growth preserves damage taken")
 check(is_equal_approx(g.hunter.damage,Catalog.HUNTER.damage+Catalog.HUNTER.damage_growth), "hunter growth increases actual damage")
 check(g.hunter.interval < Catalog.HUNTER.interval, "hunter growth accelerates attacks")
 var other = g.rooms[1]
 other.owner = 1
 other.sleeping = true
 other.closed = true
 room.door_level = 4
 room.door_hp = room.max_hp()
 g.hunter.target = 0
 g.hunter.state = HunterState.State.ATTACK
 g.hunter.position = room.door_approach()
 g.hunter.target_time = Catalog.HUNTER.retarget_seconds+1
 g.hunter.tick(0.01,g)
 check(g.hunter.target==0,"travel time alone does not exhaust actual siege commitment")
 g.hunter.reassess_seconds=RankCatalog.pressure(g.difficulty).commit+1
 g.hunter.siege_start_hp=room.door_hp
 g.hunter.tick(0.01,g)
 g.hunter.tick(0.01,g)
 check(g.hunter.target == 1, "stalled hunter switches to another valid room")
 print("AUDIT regression: idle turret cooldown cannot bank a burst")
 g = fresh()
 room = occupy(g)
 room.gold = 1000
 room.build("turret",0)
 g.hunter.state = HunterState.State.MOVE
 g.hunter.position = Vector2(2000,2000)
 for i in range(1000):
  g._turrets(0.1)
 g.hunter.position = room.tile_position(0)
 for i in range(5):
  g._turrets(0.02)
 check(g.shots == 1, "out-of-range time does not bank repeated turret shots")
 print("AUDIT regression: idle hunter cannot bank door attacks")
 g = fresh()
 g.time = g.preparation+1
 for i in range(1000):
  g.hunter.tick(0.1,g)
 room = occupy(g)
 g.hunter.target = 0
 g.hunter.state = HunterState.State.ATTACK
 g.hunter.position = room.door_approach()
 for i in range(5):
  g.hunter.tick(0.02,g)
 check(g.hunter.attacks == 1, "idle time does not bank repeated hunter attacks")
 print("AUDIT regression: exposed-player capture commits elimination exactly once")
 for assigned in [true,false]:
  g = fresh()
  if assigned:
   g.claim_room(0)
   g.player_position = g.player().bed_position()
  g.time = g.preparation+26
  g.hunter.position = g.player_position
  g.hunter.state = HunterState.State.MOVE
  g.tick(0.01)
  check(g.result == "defeat" and g.eliminations == 1, "awake capture records one elimination with assigned="+str(assigned))
  if assigned:
   check(not g.player().alive and not g.player().sleeping, "awake capture marks claimed survivor dead")
  check(not g.claim_room(1) and not g.sleep_player(), "terminal capture cannot be reversed by claiming or sleeping")
  var terminal_time = g.time
  g.tick(5)
  check(g.eliminations == 1 and g.time == terminal_time and g.result == "defeat", "terminal tick cannot double-count capture")
 print("AUDIT regression: overkill statistics use actual applied damage")
 g = fresh()
 room = occupy(g)
 room.gold = 1000
 room.build("turret",0)
 g.hunter.state = HunterState.State.MOVE
 g.hunter.position = room.tile_position(0)
 g.hunter.hp = 1
 g._turrets(0.1)
 wait_for_impacts(g)
 check(g.hunter.hp == 0 and is_equal_approx(g.damage_dealt,1.0) and is_equal_approx(room.damage_dealt,1.0), "HP1 target records1 damage rather than full configured9")
 print("AUDIT_ASSERTIONS=",assertions," FAILURES=",failures)
 quit(1 if failures else 0)
