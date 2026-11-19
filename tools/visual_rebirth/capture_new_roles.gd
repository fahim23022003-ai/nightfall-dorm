extends "res://tools/capture_visual_rebirth.gd"
## Prepared room, paid branch ladders and the actual game model's role effects.

const WEAPONS := ["flame", "frost", "shock"]
const SUPPORTS := ["economy", "enhancer"]

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 2 or not args[0].is_absolute_path() or args[1] not in WEAPONS + SUPPORTS:
  push_error("Pass an absolute evidence directory and a supported runtime building ID")
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
  var model = _fresh_room(3)
  var room = model.player()
  room.gold = 500000
  room.electricity = 500000
  var neutral_income: float = room.income_rate()
  if kind == "enhancer":
   check(model.place_building("turret", candidate(room)), "paid Needle for Relay proof")
  var neutral_hit := 0.0
  if kind == "enhancer":
   neutral_hit = BuildingStats.weapon_stats(model, room, room.buildings.values()[0]).hit
  check(model.place_building(kind, candidate(room, true)), "paid " + kind + " construction")
  var id: int = room.buildings.keys().back()
  for level in range(2, 11):
   var prior_gold: float = room.gold
   var upgraded: bool
   if level == 5:
    upgraded = model.specialize_building(id, branch)
    check(room.buildings[id].specialization == branch, "exact branch saved " + branch)
   else:
    upgraded = model.upgrade_building(id)
   check(upgraded and room.gold < prior_gold and room.buildings[id].level == level, "paid %s L%d" % [branch, level])
  _pose_stalker(model)
  var visual = game.presentation.building_visual
  var bound: bool = visual.weapon_rebirth_active(kind) if kind in ["flame", "frost"] else visual.support_rebirth_active(kind)
  check(bound == (OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"), "correct art path binds for " + kind)
  if kind in WEAPONS:
   await _weapon_proof(model, id, kind, branch)
  elif kind == "economy":
   await _income_proof(model, id, branch, neutral_income)
  else:
   await _relay_proof(model, id, branch, neutral_hit)
 await _finish()

func _weapon_proof(model, id: int, kind: String, branch: String):
 var room = model.player()
 var building: Dictionary = room.buildings[id]
 var origin: Vector2 = room.tile_position(id)
 model.hunter.position = model.map_data.hunter_spawn
 model.hunter.state = HunterState.State.MOVE
 model.spawn_undead(3)
 check(model.minions.size() == 3, "actual minion identities initialized")
 var target_hp := {}
 for index in range(model.minions.size()):
  var minion = model.minions[index]
  minion.position = origin + Vector2(-26 - 16 * index, 10 + 10 * index)
  minion.hp = 2000.0
  minion.max_hp = 2000.0
  target_hp[minion.id] = minion.hp
 game.focus_camera(true)
 await _settle(model)
 var stats := BuildingStats.weapon_stats(model, room, building)
 model._turrets(.01)
 var expected: int = stats.targets
 check(model.projectiles.size() == expected, "authoritative projectile target count " + branch)
 for shot in model.projectiles:
  check(shot.from == origin and shot.building_id == id and target_hp.has(shot.target_id), "launch came from the paid weapon, targets an actual minion")
 var visual = game.presentation.building_visual
 if kind == "shock" and visual.support_rebirth_active("shock"):
  check(visual.support_activity(room, building) > 0.0, "a real Shock volley drives the discharge layer")
 await capture(kind + "-" + branch + "-launch-720")
 var impacts := 0
 for step in range(16):
  model._advance_projectiles(.04)
  game.presentation.update(.04, model)
  await _render_frame()
  if model.projectiles.is_empty():
   break
 for event in model.combat_events:
  if event.type == "impact":
   impacts += 1
   check(event.kind == kind and event.specialization == branch and event.damage > 0 and target_hp.has(event.target_id), "real impact preserves target/branch and positive damage")
 check(impacts == expected and model.projectiles.is_empty(), "all original shots land")
 await capture(kind + "-" + branch + "-impact-720")
 if kind == "flame":
  check(model.defenses.burns.size() == expected, "original Flame burn binds each impacted target")
  var prior: float = room.minion_damage_dealt
  model.defenses.tick(.5, model)
  check(room.minion_damage_dealt > prior, "existing Flame burn credits actual damage over time")
  print("BURN_DELTA ", branch, " ", room.minion_damage_dealt - prior)
 elif kind == "frost":
  check(model.minions[0].slow_remaining > 0.0 and model.minions[0].slow_factor < 1.0, "existing Frost impact slows its target")
 elif kind == "shock":
  check(model.minions[0].slow_remaining > 0.0 and model.minions[0].slow_factor < 1.0, "existing Shock impact slows its target")
  room.tick_economy(.2)
  if visual.support_rebirth_active("shock"):
   check(visual.support_activity(room, building) == 0.0, "Shock discharge ends when the actual flash expires")
  await capture("shock-" + branch + "-idle-720")
 print("WEAPON_ROLE ", kind, " ", branch, " launches=", expected, " impacts=", impacts, " damage=", room.minion_damage_dealt)

func _income_proof(model, id: int, branch: String, neutral_rate: float):
 var room = model.player()
 var building: Dictionary = room.buildings[id]
 var visual = game.presentation.building_visual
 var active_income: float = room.income_rate()
 var prior: float = room.gold
 room.tick_economy(.5)
 var gained: float = room.gold - prior
 check(active_income > neutral_rate and is_equal_approx(gained, active_income * .5), "existing Amplifier boosts actual paid income")
 await _settle(model)
 if visual.support_rebirth_active("economy"):
  check(visual.support_activity(room, building) == 1.0, "production animates the Amplifier")
 await capture("economy-" + branch + "-active-720")
 room.production_paused = true
 prior = room.gold
 room.tick_economy(.5)
 check(room.gold == prior, "existing production pause blocks new income")
 if visual.support_rebirth_active("economy"):
  check(visual.support_activity(room, building) == 0.0, "paused production holds the Amplifier animation")
 await capture("economy-" + branch + "-paused-720")
 print("AMPLIFIER_ROLE ", branch, " base=", neutral_rate, " active=", active_income, " actual_gold_delta=", gained)

func _relay_proof(model, id: int, branch: String, neutral_hit: float):
 var room = model.player()
 var weapon_id: int = room.buildings.keys()[0]
 var origin: Vector2 = room.tile_position(weapon_id)
 model.hunter.position = origin + Vector2(36, -18)
 model.hunter.state = HunterState.State.MOVE
 await _settle(model)
 var stats := BuildingStats.weapon_stats(model, room, room.buildings[weapon_id])
 var visual = game.presentation.building_visual
 if visual.support_rebirth_active("enhancer"):
  check(visual.support_activity(room, room.buildings[id]) == 0.0, "Relay awaits actual firing")
 model._turrets(.01)
 if visual.support_rebirth_active("enhancer"):
  check(visual.support_activity(room, room.buildings[id]) == 1.0, "Relay glows only after Needle fires")
 check(model.projectiles.size() == 1, "Relay supports exactly one original Needle launch")
 if model.projectiles.size() == 1:
  var shot: Dictionary = model.projectiles[0]
  check(shot.kind == "turret" and shot.building_id == weapon_id and shot.building_id != id, "Relay emits no projectile")
  check(shot.damage > neutral_hit and is_equal_approx(shot.damage, stats.damage), "original Relay amount boosts actual Needle projectile")
  print("RELAY_ROLE ", branch, " base=", neutral_hit, " active=", shot.damage, " interval=", stats.interval, " range=", stats.range)
 await capture("enhancer-" + branch + "-supported-shot-720")
 var hp: float = model.hunter.hp
 model._advance_projectiles(.25)
 check(model.hunter.hp < hp, "boosted Needle damages the real Hunter")
 await capture("enhancer-" + branch + "-impact-720")

func _settle(model):
 for index in range(8):
  game.presentation.update(.125, model)
  await _render_frame()
