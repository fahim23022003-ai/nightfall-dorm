extends "res://tools/capture_visual_rebirth.gd"
## Prepared legacy Endless fixture with real purchases and economy work.

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 2 or not args[0].is_absolute_path() or args[1] not in ["generator", "repair"]:
  push_error("Pass an absolute evidence directory and generator or repair after --")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 var kind: String = args[1]
 phase = destination.get_file()
 output = destination.get_base_dir() + "/"
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()
 var model = _fresh_room(0)
 var room = model.player()
 var branches := StrategyCatalog.branches(kind)
 for branch in branches:
  check(model.place_building(kind, candidate(room)), "paid support construction " + branch)
 var ids: Array = room.buildings.keys()
 for level in range(2, 11):
  for index in range(ids.size()):
   var id: int = ids[index]
   var branch: String = branches[index]
   var old_gold: float = room.gold
   var upgraded: bool
   if level == 5:
    upgraded = model.specialize_building(id, branch)
    check(room.buildings[id].get("specialization") == branch, branch + " saved in the paid fixture")
   else:
    upgraded = model.upgrade_building(id)
   check(upgraded and room.gold < old_gold and room.buildings[id].level == level, "paid %s L%d" % [branch, level])
 _pose_stalker(model)
 model.running = false
 game.presentation.identity.heading = Vector2.LEFT
 for index in range(8):
  game.presentation.update(.125, model)
  await _render_frame()
 var visual = game.presentation.building_visual
 check(visual.support_rebirth_active(kind), "support atlases reached the actual draw path")
 if kind == "generator":
  var prior: float = room.generated_power
  room.tick_economy(.5)
  var delta: float = room.generated_power - prior
  check(delta > 0 and visual.support_activity(room, room.buildings[ids[0]]) == 1.0, "actual electricity work enables animation")
  await _capture_active(kind)
  room.production_paused = true
  prior = room.generated_power
  room.tick_economy(.5)
  check(room.generated_power == prior and visual.support_activity(room, room.buildings[ids[0]]) == 0.0, "production pause stops work and animation")
  print("DYNAMO_PRODUCTION_PER_HALF_SECOND=", delta, " PAUSED_DELTA=", room.generated_power - prior)
 else:
  room.door_hp = room.max_hp() - 240.0
  var prior: float = room.door_hp
  room.tick_economy(.5)
  var delta: float = room.door_hp - prior
  check(delta > 0 and visual.support_activity(room, room.buildings[ids[0]]) == 1.0, "actual repair enables animation")
  await _capture_active(kind)
  room.door_hp = room.max_hp()
  room.tick_economy(.5)
  check(room.door_hp == room.max_hp() and visual.support_activity(room, room.buildings[ids[0]]) == 0.0, "full door stops work and animation")
  print("DOOR_REPAIRED_PER_HALF_SECOND=", delta, " FULL_DOOR_HP=", room.door_hp)
 await capture(kind + "-inactive-720")
 await _finish()

func _capture_active(kind: String):
 for index in range(2):
  game.presentation.clock = 9.0 + index * .2
  await capture("%s-active-phase-%d-720" % [kind, index])
