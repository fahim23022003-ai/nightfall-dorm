extends SceneTree

var passed = 0
var failed = 0
var assertions = 0

func check(condition: bool, message: String):
 assertions += 1
 if not condition:
  failed += 1
  push_error("ASSERTION FAILED: " + message)

func section(label: String):
 print("TEST " + label)

func fresh(seed_value = 1):
 var game = MatchModel.new()
 game.reset(seed_value)
 return game

func occupy(game, index = 0):
 check(game.claim_room(index), "claim available room")
 game.player_position = game.rooms[index].bed_position()
 check(game.sleep_player(), "sleep in claimed bed")
 return game.rooms[index]

func advance(game, seconds: float, step = 0.1):
 for i in range(int(ceil(seconds / step))):
  game.tick(step)

func _initialize():
 call_deferred("run")

func run():
 section("03 movement collision room interaction and delayed selection")
 var walker = fresh()
 check(not walker.can_walk(Vector2(10,10)), "outside world blocks movement")
 var initial_position = walker.player_position
 walker.move_player(Vector2.RIGHT,0.1)
 check(walker.player_position.x > initial_position.x, "player movement changes position")
 # Walk continuous legal steps from the common corridor through room 1 doorway.
 walker.player_position = Vector2(495,410)
 for i in range(30):
  walker.move_player(Vector2.UP,0.02)
 check(walker.rooms[1].bounds().has_point(walker.player_position), "player walks through doorway into room")
 walker.interact()
 check(walker.player_room == 1, "interaction claims entered room")
 var bed = walker.rooms[1].bed_position()
 for i in range(100):
  walker.move_player((bed-walker.player_position).normalized(),0.02)
  if walker.player_position.distance_to(bed)<10:
   break
 walker.interact()
 check(walker.rooms[1].sleeping and walker.rooms[1].closed, "walking to bed and interaction sleeps and locks door")
 initial_position = walker.player_position
 walker.move_player(Vector2.RIGHT,1)
 check(walker.player_position == initial_position, "sleeping survivor stays in bed")
 var late = fresh(11)
 late.player_position = late.rooms[0].center()
 advance(late,20)
 check(late.rooms[0].owner == -1 and not late.rooms[0].closed, "bots do not claim and trap a player standing inside room")
 section("03 valid room selection")
 var g = fresh()
 check(g.player_room == -1, "new player unassigned")
 check(not g.claim_room(-1), "invalid room rejected")
 var r = occupy(g)
 check(g.player_room == 0 and r.owner == 0, "room ownership assigned")
 check(not g.claim_room(1), "second room claim rejected")
 section("08 build grid separates beds from usable tiles")
 for candidate in g.rooms:
  var bed_rect = Rect2(candidate.bed_position()-Vector2(21,30),Vector2(42,60))
  for tile in range(6):
   var tile_rect = Rect2(candidate.tile_position(tile)-Vector2(26,26),Vector2(52,52))
   check(not tile_rect.intersects(bed_rect) and candidate.bounds().encloses(tile_rect), "tile is inside room and clear of bed")
 section("04 income only while sleeping")
 var room = RoomState.new(0)
 var initial = room.gold
 room.tick_economy(3.0)
 check(is_equal_approx(room.gold, initial), "empty bed earns nothing")
 room.sleeping = true
 room.tick_economy(3.0)
 check(is_equal_approx(room.gold, initial + Catalog.BED_INCOME[0] * 3), "occupied bed earns specified rate")
 room.alive = false
 initial = room.gold
 room.tick_economy(3.0)
 check(is_equal_approx(room.gold, initial), "dead resident earns nothing")
 section("05 bed upgrade and prerequisites")
 room = RoomState.new(0)
 room.sleeping = true
 room.gold = 1000
 initial = room.gold
 check(room.upgrade_bed(), "affordable bed upgrade")
 check(room.bed_level == 1 and is_equal_approx(room.gold, initial-Catalog.BED_COST[0]), "bed cost deducted once")
 check(is_equal_approx(room.income_rate(), Catalog.BED_INCOME[1]), "upgraded bed rate")
 room.bed_level = 2
 room.door_level = 0
 initial = room.gold
 check(not room.upgrade_bed() and room.gold == initial, "bed prerequisite rejects atomically")
 section("06 door durability upgrade")
 room = RoomState.new(0)
 room.gold = 1000
 room.door_hp -= 20
 var old_max = room.max_hp()
 check(room.upgrade_door(), "door upgrade accepted")
 check(room.max_hp() > old_max, "door maximum increases")
 check(is_equal_approx(room.door_hp, room.max_hp()-20), "door upgrade preserves existing damage")
 section("07 rejected transactions")
 room = RoomState.new(0)
 room.gold = 0
 room.electricity = 0
 check(not room.upgrade_bed() and not room.upgrade_door(), "insufficient gold rejects upgrades")
 check(room.gold == 0 and room.electricity == 0, "rejection changes no resource")
 room.gold = 1000
 room.sleeping = true
 room.bed_level = 1
 check(not room.build("heavy", 0), "electricity required separately")
 check(room.gold == 1000 and room.buildings.is_empty(), "missing electricity purchase atomic")
 section("08 valid build tiles and upgrades")
 room.electricity = 100
 check(not room.build("unknown",0) and not room.build("turret",-1) and not room.build("turret",6), "unknown building and outside tiles rejected")
 check(room.build("turret",0), "valid empty tile builds")
 initial = room.gold
 check(not room.build("generator",0), "occupied tile rejected")
 check(room.gold == initial and room.buildings.size() == 1, "occupied tile rejects atomically")
 check(room.upgrade_building(0) and room.buildings[0].level == 2, "building upgrade applies")
 check(not room.upgrade_building(5), "missing building cannot upgrade")
 section("12 repair bounds and destroyed doors")
 room = RoomState.new(0)
 room.gold = 100
 room.door_hp = room.max_hp()-10
 check(room.repair_door() and room.door_hp == room.max_hp(), "repair clamps max HP")
 initial = room.gold
 check(not room.repair_door() and room.gold == initial, "full HP repair rejected without spending")
 room.door_hp = 0
 check(not room.repair_door() and not room.upgrade_door(), "destroyed door cannot resurrect")
 room.door_hp = 50
 room.sleeping = true
 room.gold = 1000
 room.electricity = 100
 check(room.build("repair",0), "repair facility builds")
 room.tick_economy(1.0)
 check(is_equal_approx(room.door_hp,57), "repair facility heals actual HP")
 section("14 electricity generation and spending; all six building effects")
 room = RoomState.new(0)
 room.sleeping = true
 room.gold = 10000
 room.electricity = 1000
 for kind in Catalog.BUILDINGS.keys():
  room.bed_level = 1
  check(room.build(kind,room.buildings.size()), "build " + kind)
 var old_power = room.electricity
 room.tick_economy(2)
 check(is_equal_approx(room.electricity,old_power+Catalog.BUILDINGS.generator.rate*2), "generator electricity rate")
 check(room.income_rate() > Catalog.BED_INCOME[1], "economy building increases income")
 old_power = room.electricity
 check(room.upgrade_building(0) and room.electricity < old_power, "upgrade spends electricity")
 section("09 turret range cooldown damage and enhancement")
 g = fresh()
 r = occupy(g)
 r.gold = 1000
 r.electricity = 100
 check(r.build("turret",0), "turret builds")
 g.hunter.state = HunterState.State.MOVE
 g.hunter.position = r.tile_position(0)+Vector2(1000,0)
 var hp = g.hunter.hp
 g._turrets(0.1)
 check(g.hunter.hp == hp, "out-of-range enemy unharmed")
 g.hunter.position = r.tile_position(0)
 g._turrets(0.1)
 check(is_equal_approx(g.hunter.hp,hp-Catalog.BUILDINGS.turret.damage), "turret deals configured damage")
 hp = g.hunter.hp
 g._turrets(0.1)
 check(g.hunter.hp == hp, "turret respects attack interval")
 check(r.build("enhancer",1), "enhancer builds")
 r.buildings[0].cooldown = 0
 g._turrets(0.1)
 check(is_equal_approx(hp-g.hunter.hp,Catalog.BUILDINGS.turret.damage*(1+Catalog.BUILDINGS.enhancer.rate)), "enhancer increases actual turret damage")
 var boosted_damage = hp-g.hunter.hp
 check(r.upgrade_building(0), "turret upgrade purchase")
 r.buildings[0].cooldown = 0
 hp = g.hunter.hp
 g._turrets(0.1)
 check(hp-g.hunter.hp > boosted_damage, "turret upgrade increases actual damage")
 check(r.buildings[0].cooldown < Catalog.BUILDINGS.turret.interval, "turret upgrade reduces attack cooldown")
 g.hunter.state = HunterState.State.DEAD
 r.buildings[0].cooldown = 0
 hp = g.hunter.hp
 g._turrets(2)
 check(g.hunter.hp == hp, "dead target ignored")
 section("10 hunter target selection and corridor navigation")
 g = fresh()
 r = occupy(g)
 g.preparation = 0
 g.hunter.position = Vector2(960,410)
 check(g.hunter.choose_target(g.rooms) == 0, "only occupied room targeted")
 var start = g.hunter.position
 g.tick(0.1)
 check(g.hunter.position != start, "hunter moves toward room")
 section("11 intact door protects resident and hunter attacks")
 g.hunter.target = 0
 g.hunter.state = HunterState.State.ATTACK
 g.hunter.position = r.door_position()
 g.hunter.cooldown = 0
 hp = r.door_hp
 g.tick(0.1)
 check(r.door_hp < hp and r.alive, "attack damages door but not resident")
 var after_attack = r.door_hp
 g.tick(0.1)
 check(r.door_hp == after_attack, "attack respects cooldown")
 section("10 hunter exits breached room through its doorway")
 g = fresh()
 occupy(g)
 var victim = g.rooms[2]
 victim.owner = 1
 victim.sleeping = true
 victim.closed = true
 victim.door_hp = 0
 g.preparation = 0
 g.hunter.target = 2
 g.hunter.state = HunterState.State.BREACH
 g.hunter.position = victim.bed_position()
 g.hunter.tick(0.1,g)
 check(not victim.alive and g.hunter.state == HunterState.State.EXIT, "breached resident dies and hunter enters exit state")
 var through_door = false
 for i in range(100):
  g.hunter.tick(0.05,g)
  if g.hunter.position.distance_to(victim.door_position()) < 5:
   through_door = true
  if g.hunter.state == HunterState.State.SEEK:
   break
 check(through_door and absf(g.hunter.position.y-410)<3, "hunter returns through door to shared corridor before retargeting")
 section("13 autonomous bots")
 g = fresh(17)
 occupy(g)
 advance(g,25)
 var sleeping_bots = 0
 for candidate in g.rooms:
  if candidate.owner > 0 and candidate.sleeping:
   sleeping_bots += 1
 check(sleeping_bots == 5, "all five bots claim distinct rooms and sleep")
 advance(g,20)
 var spending_bots = 0
 for candidate in g.rooms:
  if candidate.owner > 0 and candidate.spent > 0:
   spending_bots += 1
 check(spending_bots == 5, "all five bots spend autonomously")
 section("15 hunter death triggers victory")
 g = fresh()
 occupy(g)
 g.preparation = 0
 g.tick(0.1)
 g.hunter.hurt(100000)
 g.tick(0.1)
 check(g.result == "victory", "hunter death resolves victory")
 section("16 breach eliminates player and triggers defeat")
 g = fresh()
 r = occupy(g)
 g.preparation = 0
 r.door_hp = 0
 g.hunter.target = 0
 g.hunter.state = HunterState.State.BREACH
 g.hunter.position = r.bed_position()
 g.tick(0.1)
 check(not r.alive and g.result == "defeat", "breach resolves defeat")
 section("18 exposed awake player cannot softlock match")
 var exposed = fresh(23)
 exposed.preparation = 0
 exposed.player_position = exposed.rooms[0].center()
 advance(exposed,120)
 check(exposed.result == "defeat", "hunter pursues and eliminates awake player within bounded simulation")
 check(exposed.time < 120, "exposed-player match terminates rather than stalling")
 section("17 reset clears match")
 g.reset(42)
 check(g.result == "" and g.player_room == -1 and g.time == 0, "reset restores match metadata")
 check(g.hunter.hp == g.hunter.max_hp and g.hunter.state == HunterState.State.DORMANT, "reset restores hunter")
 for candidate in g.rooms:
  check(candidate.owner == -1 and candidate.buildings.is_empty() and candidate.alive, "reset clears room " + str(candidate.index))
 print("ASSERTIONS=",assertions," FAILURES=",failed)
 quit(1 if failed else 0)
