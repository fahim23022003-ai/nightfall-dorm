extends SceneTree
var failures = 0
var checks = 0

func check(condition: bool, label: String):
 checks += 1
 if not condition:
  failures += 1
  if failures < 20:
   push_error("PROPERTY FAIL: " + label)

func snapshot(room):
 return [room.gold,room.electricity,room.bed_level,room.door_level,room.door_hp,room.buildings.duplicate(true),room.spent]

func _initialize():
 call_deferred("run")

func run():
 var transactions = 0
 var rejected = 0
 for seed_value in range(1,41):
  var rng = RandomNumberGenerator.new()
  rng.seed = seed_value
  var room = RoomState.new(seed_value%6)
  room.owner = 0
  room.sleeping = true
  for step in range(500):
   if step == 490:
    room.alive = false
   var delta = rng.randf_range(0.05,1.0)
   room.tick_economy(delta)
   if step%17 == 0 and room.alive:
    room.door_hp = maxf(1,room.door_hp-rng.randf_range(0,40))
   var before = snapshot(room)
   var accepted = false
   var choice = rng.randi_range(0,4)
   match choice:
    0: accepted = room.build(Catalog.BUILDINGS.keys()[rng.randi_range(0,5)],rng.randi_range(-1,6))
    1: accepted = room.upgrade_bed()
    2: accepted = room.upgrade_door()
    3: accepted = room.repair_door()
    4: accepted = room.upgrade_building(rng.randi_range(-1,6))
   transactions += 1
   if not accepted:
    rejected += 1
    check(before == snapshot(room), "rejected transaction is atomic seed="+str(seed_value)+" step="+str(step))
   check(room.gold >= -0.00001 and room.electricity >= -0.00001, "resources remain nonnegative")
   check(is_equal_approx(room.gold+room.spent,25.0+room.income_total), "earned/spent gold ledger conserves currency")
   check(room.door_hp >= 0 and room.door_hp <= room.max_hp()+0.0001, "door HP remains bounded")
   check(room.bed_level >= 0 and room.bed_level < Catalog.BED_INCOME.size() and room.door_level >= 0 and room.door_level < Catalog.DOOR_HP.size(), "upgrade levels remain within catalog")
   for tile in room.buildings:
    check(tile >= 0 and tile < 6 and room.buildings[tile].level >= 1 and room.buildings[tile].level <= Catalog.building_max_level(room.buildings[tile].kind), "building tiles and levels remain valid")
   if not room.alive:
    check(not accepted and room.income_rate() == 0,"dead resident cannot spend or earn")
 print("PROPERTY_TRANSACTIONS=",transactions," REJECTED=",rejected," CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
