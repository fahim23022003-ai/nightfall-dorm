extends "res://tools/capture_visual_rebirth.gd"
## Prepared typed damage through existing absorb, reflection and release routes.

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 2 or not args[0].is_absolute_path() or args[1] not in MagicDefense.KINDS:
  push_error("Pass an absolute evidence directory and a magic defense ID")
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
  await _magic_proof(kind, branch)
 await _finish()

func _magic_proof(kind: String, branch: String):
 var model = _fresh_room(3)
 var room = model.player()
 room.gold = 500000
 room.electricity = 500000
 check(model.place_building(kind, candidate(room, true)), "paid exact magic defense type")
 var id: int = room.buildings.keys()[0]
 for level in range(2, 11):
  var gold_before: float = room.gold
  var upgraded: bool = model.specialize_building(id,branch) if level == 5 else model.upgrade_building(id)
  check(upgraded and room.gold < gold_before and room.buildings[id].level == level, "real display level reached under paid branch")
 var building: Dictionary = room.buildings[id]
 check(building.get("specialization") == branch, "actual branch persisted")
 _pose_stalker(model)
 var visual = game.presentation.building_visual
 var pilot := OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"
 var bound: bool = visual.support_rebirth_active(kind) if kind == "plasma" else visual.STATIC_BRANCHES.has(kind) and visual.load_rebirth_atlas(kind,"")
 check(bound == pilot, "actual art binding matches selected renderer")
 for step in range(8):
  game.presentation.update(.125, model)
  await _render_frame()
 var stats := MagicDefense.stats(building)
 if kind == "antenna":
  var electricity: float = room.electricity
  MagicDefense.tick(model,.01)
  check(is_equal_approx(room.magic_state.shield, float(stats.capacity)) and is_equal_approx(electricity-room.electricity,float(stats.power)), "existing Ward Antenna charges actual paid magic barrier")
 var hunter_hp: float = model.hunter.hp
 var door_hp: float = room.door_hp
 var incoming := 90.0 if kind == "antenna" else 180.0
 var damage: float = model.apply_room_damage(room.index,incoming,"fixture magic hit",1,true,{"type":DamageRules.MAGIC,"element":"neutral"})
 var reflection: float = hunter_hp - model.hunter.hp
 var stored: float = room.magic_state.stored
 var heal := 0.0
 if kind == "barrier":
  check(is_equal_approx(reflection,incoming*float(stats.reflect)) and is_equal_approx(damage,incoming), "real Mirror reflects the existing amount")
 elif kind == "plasma":
  check(is_equal_approx(stored,incoming*float(stats.absorb)) and is_equal_approx(damage,incoming-stored), "real Plasma absorbs and stores existing amount")
  if pilot:
   check(visual.support_activity(room,building,model) == 1.0, "live stored charge drives hardware animation")
 else:
  check(damage == 0.0 and room.door_hp == door_hp and is_equal_approx(room.magic_state.shield,float(stats.capacity)-incoming), "paid Antenna absorbs the existing magic packet")
 game.presentation.update(.04, model)
 await capture(kind + "-" + branch + "-magic-impact-720")
 if kind == "plasma":
  var prior_hp: float = room.door_hp
  MagicDefense.tick(model,.01)
  heal = room.door_hp - prior_hp
  check(is_equal_approx(heal,stored*float(stats.heal)) and room.magic_state.stored == 0.0, "stored charge releases into exact existing repair")
  if pilot:
   check(visual.support_activity(room,building,model) == 0.0, "empty capacitor no longer animates stored charge")
  game.presentation.update(.04, model)
  await capture(kind + "-" + branch + "-release-720")
 print("MAGIC_ROLE ", kind, " ", branch, " door_damage=", damage, " reflected=", reflection, " stored=", stored, " heal=", heal, " shield_left=", room.magic_state.shield)
