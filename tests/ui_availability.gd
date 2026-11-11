extends SceneTree

var checks = 0
var failures = 0

func check(value: bool, label: String):
 checks += 1
 if not value:
  failures += 1
  push_error("UI AVAILABILITY: " + label)

func _initialize():
 call_deferred("run")

func run():
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_match()
 game.sound_volume = 0
 game.ui.update_match()
 check(game.ui.actions.bed.disabled,"unclaimed room disables purchases")
 for frame in range(3): game.ui.update_match()
 check(game.ui.actions.bed.tooltip_text.count("Claim a room first.") == 1,"unclaimed tooltip does not accumulate repeated explanations")
 game.model.claim_room(0)
 var rng = RandomNumberGenerator.new()
 rng.seed = 20261111
 var kinds = Catalog.BUILDINGS.keys()
 var actions = ["bed","door","repair","upgrade"]
 for kind in kinds:
  actions.append("build:"+kind)
 for sample in range(160):
  var source = RoomState.new(0)
  source.owner = 0
  source.gold = [0,20,25,100,1000][rng.randi_range(0,4)]
  source.electricity = [0,5,30,100][rng.randi_range(0,3)]
  source.bed_level = rng.randi_range(0,4)
  source.door_level = rng.randi_range(0,4)
  source.door_hp = [0.0,source.max_hp()*0.5,source.max_hp()][rng.randi_range(0,2)]
  source.sleeping = sample%3 != 0
  source.alive = sample%11 != 0
  source.last_error = "unchanged sentinel"
  if sample%2 == 0:
   source.buildings[0] = {"kind":kinds[sample%kinds.size()],"level":rng.randi_range(1,4),"cooldown":0.0,"flash":0.0}
  game.model.running = sample%7 != 0
  game.model.result = "victory" if sample%13 == 0 else ""
  for action in actions:
   var probe = RoomState.new(0)
   for field in ["owner","gold","electricity","bed_level","door_level","door_hp","sleeping","alive","last_error"]:
    probe.set(field,source.get(field))
   probe.buildings = source.buildings.duplicate(true)
   game.model.rooms[0] = probe
   var reason = game.ui.action_reason(action)
   check(probe.last_error == "unchanged sentinel" and probe.gold == source.gold and probe.electricity == source.electricity,"availability query is read-only")
   var purchased = false
   match action:
    "bed": purchased = game.model.upgrade_bed()
    "door": purchased = game.model.upgrade_door()
    "repair": purchased = game.model.repair_door()
    "upgrade": purchased = game.model.upgrade_building(0)
    _: purchased = game.model.buy(action.trim_prefix("build:"),0)
   check(reason.is_empty() == purchased,"availability agrees with actual transaction: "+action)
 game.model.result = ""
 game.model.running = true
 var room = RoomState.new(0)
 room.owner = 0
 room.sleeping = true
 room.gold = 25
 game.model.rooms[0] = room
 game.ui.update_match()
 check(not game.ui.actions["build:turret"].disabled,"affordable turret enabled")
 check(game.ui.actions["build:generator"].disabled,"unaffordable generator disabled")
 check("5 more gold" in game.ui.actions["build:generator"].tooltip_text,"shortage visible in tooltip")
 room.gold = 1000
 room.electricity = 100
 room.build("turret",0)
 game.ui.update_match()
 check(game.ui.actions["build:generator"].disabled and not game.ui.actions.upgrade.disabled,"occupied tile changes available actions")
 check("20G / 3E" in game.ui.actions.upgrade.text,"selected upgrade price visible")
 game.model.running = false
 game.ui.update_match()
 check(game.ui.actions.upgrade.disabled and "Paused" in game.ui.actions.upgrade.tooltip_text,"pause availability explained")
 game.model.running = true
 game.selected_tile = 99
 game.ui.update_match()
 check(game.ui.actions["build:turret"].disabled,"invalid floor selection cannot advertise a valid purchase")
 print("UI_AVAILABILITY_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown()
 await create_timer(0.5).timeout
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)
