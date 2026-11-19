extends "res://tools/capture_visual_rebirth.gd"
## Prepared funds with real core upgrades and existing occupied-room behavior.

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 2 or not args[0].is_absolute_path() or args[1] not in ["bed", "door"]:
  push_error("Pass an absolute evidence directory and bed or door after --")
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
 for branch in StrategyCatalog.branches(kind):
  await _paid_core(kind, branch)
 await _finish()

func _paid_core(kind: String, branch: String):
 var model = _fresh_room(0)
 var room = model.player()
 room.bed_level = 0
 room.door_level = 0
 room.door_hp = room.max_hp()
 var initial_bed: Vector2 = room.bed_position()
 var initial_door: Vector2 = room.door_position()
 var base_income: float = room.income_rate()
 var base_hp: float = room.door_hp
 for level in range(2, 11):
  var prior: float = room.gold
  var upgraded: bool
  if level == 6:
   var bed_branch: String = branch if kind == "bed" else StrategyCatalog.branches("bed")[0]
   var door_branch: String = branch if kind == "door" else StrategyCatalog.branches("door")[0]
   upgraded = room.specialize_structure("bed", bed_branch)
   upgraded = room.specialize_structure("door", door_branch) and upgraded
   check(room.bed_branch == bed_branch and room.door_branch == door_branch, "existing paid structures acquire branches at displayed L6")
  else:
   upgraded = model.upgrade_bed()
   upgraded = model.upgrade_door() and upgraded
  check(upgraded and room.gold < prior and room.bed_level + 1 == level and room.door_level + 1 == level, "real paired core purchases through displayed L%d" % level)
  if level in [4, 7, 10]:
   _pose_stalker(model)
   model.running = false
   game.presentation.identity.heading = Vector2.LEFT
   for tick in range(8):
    game.presentation.update(.125, model)
    await _render_frame()
   await capture(kind + "-" + branch + "-paid-level-%02d-720" % level)
   model.running = true
 var visual = game.presentation.building_visual
 check((visual.CORE_BRANCHES.has(kind) and visual.load_rebirth_atlas(kind, "")) == (OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"), "core renderer follows launch switch")
 check(room.bed_position() == initial_bed and room.door_position() == initial_door, "existing gameplay anchors unchanged")
 check(room.sleeping and room.alive and room.income_rate() > base_income and room.door_hp > base_hp, "actual core upgrades retain benefits and occupied behavior")
 print("ROOM_CORE ", kind, " ", branch, " level=", room.bed_level + 1 if kind == "bed" else room.door_level + 1, " income=", room.income_rate(), " door_hp=", room.door_hp)
