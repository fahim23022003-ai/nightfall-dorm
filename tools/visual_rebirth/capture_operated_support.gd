extends "res://tools/capture_visual_rebirth.gd"
## Prepared door damage and funds, then genuine branch purchases and effects.

const OPERATED := ["auto_repair", "shield", "decoy"]

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 2 or not args[0].is_absolute_path() or args[1] not in OPERATED:
  push_error("Pass an absolute evidence directory and an operated support ID")
  quit(2)
  return
 var kind: String = args[1]
 var destination := args[0].trim_suffix("/")
 phase = destination.get_file()
 output = destination.get_base_dir() + "/"
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()
 for branch in StrategyCatalog.branches(kind):
  await _operation(kind, branch)
 await _finish()

func _operation(kind: String, branch: String):
 var model = _fresh_room(3)
 var room = model.player()
 room.gold = 500000
 room.electricity = 500000
 check(model.place_building(kind, candidate(room,true)), "paid operated support " + kind)
 var id: int = room.buildings.keys()[0]
 for level in range(2, 11):
  var prior: float = room.gold
  var succeeded: bool = model.specialize_building(id, branch) if level == 5 else model.upgrade_building(id)
  check(succeeded and room.gold < prior and room.buildings[id].level == level, "actual %s upgrade L%d" % [branch, level])
 check(room.buildings[id].specialization == branch, "actual branch preserved")
 _pose_stalker(model)
 room.door_hp = room.max_hp() * .25
 model.hunter.state = HunterState.State.MOVE
 for index in range(8):
  game.presentation.update(.125, model)
  await _render_frame()
 var visual = game.presentation.building_visual
 var pilot := OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"
 var building: Dictionary = room.buildings[id]
 check(visual.support_rebirth_active(kind) == pilot, "exact atlas path follows launch switch")
 if pilot:
  check(visual.support_activity(room, building, model) == 0.0, "mechanism idle before actual activation")
 var stats: Dictionary = model.defenses.stats(room, building)
 var previous_gold: float = room.gold
 var previous_electricity: float = room.electricity
 var prior_hp: float = room.door_hp
 model.defenses.tick(.01, model)
 check(absf(previous_gold - room.gold - stats.get("gold", 0.0)) < .001 and absf(previous_electricity - room.electricity - stats.power) < .001, "actual operation spends exactly recipe resources")
 if pilot:
  check(visual.support_activity(room, building, model) > 0.0, "real activation drives mechanism")
 await capture(kind + "-" + branch + "-active-720")
 var active := 0.0
 var stop_after := .75
 if kind == "auto_repair":
  active = room.door_hp - prior_hp
  check(is_equal_approx(active, float(stats.heal)), "operation heals the actual damaged door")
 elif kind == "shield":
  active = room.barrier_hp
  stop_after = stats.duration + .04
  check(is_equal_approx(active, float(stats.capacity)) and is_equal_approx(room.barrier_remaining, float(stats.duration)), "actual finite barrier is present")
  check(model.apply_room_damage(room.index, active * .5, "fixture absorbed strike", 1, true) == 0.0 and room.door_hp == prior_hp, "actual shield intercepts a strike")
 else:
  active = model.defenses.lure_remaining
  stop_after = stats.duration + .04
  check(model.defenses.lure_tile == id and model.defenses.lure_room == room.index and active > 0.0, "actual timed lure links to the paid device")
 var gold: float = room.gold
 var electricity: float = room.electricity
 model.defenses.tick(stop_after, model)
 check(gold == room.gold and electricity == room.electricity, "expiry does not repeat the purchase")
 if pilot:
  check(visual.support_activity(room, building, model) == 0.0, "mechanism rests when the real activation ends")
 await capture(kind + "-" + branch + "-expired-720")
 print("OPERATED_ROLE ", kind, " ", branch, " output=", active, " gold_cost=", previous_gold - gold, " power_cost=", previous_electricity - electricity)
