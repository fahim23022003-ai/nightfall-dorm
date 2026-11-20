extends "res://tools/nightmare_tactics/check_starting_rooms.gd"
## Complete Story matches from physical Room Rush through paid profile settlement.

const STORY_LIMIT := 900.0
const OPENING_LIMIT := 32.0
const PROFILE_ATTEMPT := 100
const ReplaySupport = preload("res://tests/replay_test_support.gd")

func start_flags() -> void:
 OS.set_environment(V2_FLAG, "1")
 OS.set_environment("NIGHTFALL_PROCEDURAL_MAPS", "0")
 OS.set_environment("NIGHTFALL_FULL_ROOM_GRID", "1")
 OS.set_environment("NIGHTFALL_LIVING_NIGHTMARE", "1")
 OS.set_environment("NIGHTFALL_SURVIVOR_REBIRTH", "1")
 grid = true

func new_trial_profile(fixture: Dictionary, stock: String) -> PlayerProfile:
 var path := "user://phase16-" + str(fixture.id) + ".json"
 if DirAccess.copy_absolute(stock, ProjectSettings.globalize_path(path)) != OK:
  return null
 var profile := PlayerProfile.new(path)
 if not profile.load_profile():
  return null
 while not profile.pending_spins.is_empty():
  if profile.claim_spin(int(profile.pending_spins[0].match_id)).is_empty():
   return null
 if fixture.policy != "item_assisted":
  for item: String in profile.item_loadout.duplicate():
   if not profile.equip_item(item):
    return null
 profile.story = StoryProgress.fresh(int(fixture.seed_base))
 for level in range(1, int(fixture.level)):
  if StoryProgress.settle(profile.story, fixture.difficulty, level, true, level).is_empty():
   return null
 # The first five legitimately cleared Story levels also write legacy
 # Campaign records. Stage those prerequisites alongside Story position.
 for legacy_level in range(1, mini(6, int(fixture.level))):
  var stage := "stage_%d" % legacy_level
  if not profile.campaign_records.has(stage):
   profile.campaign_records[stage] = {"clears":1, "best_time":0.0, "best_damage":0.0,
     "best_xp":0, "difficulty":fixture.difficulty, "first_match_id":legacy_level}
 profile.reward_rng.seed = 1729
 # An identical, disclosed attempt nonce keeps Room Rush spawn reproducible.
 profile.next_match_id = PROFILE_ATTEMPT
 return profile

func initial_claim(model: MatchModel, preference: int) -> bool:
 var attempts := 0
 while model.player_room < 0 and model.time < OPENING_LIMIT and attempts < 12:
  var paths: Dictionary = model.room_rush.routes_to_vacant_rooms(model, model.player_position)
  if paths.is_empty():
   model.tick(MODEL_STEP)
   continue
  var ids := paths.keys()
  var position: Vector2 = model.player_position
  ids.sort_custom(func(a, b):
   var left := RoomRush.route_length(position,paths[a])
   var right := RoomRush.route_length(position,paths[b])
   return a < b if left == right else left < right)
  var id: int = ids[mini(preference, ids.size() - 1)] if attempts == 0 else ids[0]
  for waypoint: Vector2 in paths[id]:
   var ticks := 0
   while model.player_position.distance_to(waypoint) > .6 and ticks < 100:
    if model.rooms[id].owner >= 0 or model.time >= OPENING_LIMIT:
     break
    model.move_player((waypoint - model.player_position) / (model.SURVIVOR_SPEED * MODEL_STEP), MODEL_STEP)
    model.tick(MODEL_STEP)
    ticks += 1
   if model.rooms[id].owner >= 0 or model.player_position.distance_to(waypoint) > .6:
    break
  model.interact()
  attempts += 1
 if model.player_room < 0:
  return false
 var room := model.player()
 model.interact()
 if not room.sleeping:
  var best := INF
  var goal := Vector2.INF
  for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]:
   var option := room.bed_position() + direction * 54.0
   if not room.floor_has_point(option) or not model.can_walk(option, room.index):
    continue
   var path: Array = model.room_rush.safe_path(model, model.player_position, option, room.index)
   var distance := RoomRush.route_length(model.player_position, path)
   if not path.is_empty() and distance < best:
    best = distance
    goal = option
  if not goal.is_finite() or not walk_to(model, goal):
   return false
 model.interact()
 return room.sleeping and model.time < model.preparation

func use_plan(model: MatchModel, profile: PlayerProfile, policy: String, items_used: Array, match_number: int) -> void:
 if policy == "item_assisted" and items_used.is_empty():
  var slot := profile.item_loadout.find("gold")
  if slot >= 0 and profile.activate_item(slot, model, match_number):
   items_used.append({"item":"gold", "time":model.time, "remaining":profile.inventory.get("gold",0)})
 if policy in ["balanced", "item_assisted", "assisted_without_items"]:
  act(model)
 elif policy == "early_turret":
  defend_with_needles(model)
 elif policy == "economics":
  apply_plan(model, "economic_rush")
 elif policy == "repair_heavy":
  var room := model.player()
  if room.door_hp < room.max_hp() * .75 and model.repair_door():
   return
  apply_plan(model, "door_reserve")
 else:
  apply_plan(model, "frost_arc")

func play_story(fixture: Dictionary, stock: String) -> Dictionary:
 var invalid: Array[String] = []
 var row := {"fixture":fixture, "invalid":invalid}
 var profile := new_trial_profile(fixture, stock)
 if profile == null:
  invalid.append("could not prepare disposable Story profile")
  return row
 var level: int = int(fixture.level)
 var mission := StoryCatalog.mission(level)
 var mode: String = fixture.difficulty
 var entry := profile.begin_match(mode, mission.stage_id, true, level)
 if entry.is_empty() or entry.archetype != fixture.archetype:
  invalid.append("production begin_match rejected intended Story mission")
  return row
 var model := MatchModel.new()
 var match_number: int = entry.id
 var seed: int = entry.story.seed
 model.reset(seed)
 if not model.configure_match(mode, RankCatalog.bonuses(entry.equipped)) or not model.configure_stage(mission.stage_id) or not model.configure_balance():
  invalid.append("production model configuration failed")
  return row
 model.story_level = level
 model.preparation = maxf(model.preparation, mission.preparation)
 if not model.configure_strategy(seed, entry.archetype, entry.contract, match_number) or model.map_data.get("family") != fixture.family:
  invalid.append("configured strategy or map family differs from fixture")
  return row
 var story_script: GDScript = load("res://scripts/story_catalog.gd")
 if story_script.has_method("apply_encounter"):
  story_script.call("apply_encounter", model)
 row["initial_boss_policy"] = model.hunter.boss_policy.duplicate()
 profile.apply_stage_bonus(model, entry)
 profile.bind_items(model, match_number)
 if not model.begin_room_rush(match_number):
  invalid.append("production shared-room-rush spawn failed")
  return row
 var packed := JSON.stringify(NightmareMap.pack(model.map_data), "", true, true)
 var spawn: Vector2 = model.player_position
 if not initial_claim(model, int(fixture.room_preference)):
  invalid.append("legal traversal did not claim and sleep before the first Hunter movement")
  return row
 var room := model.player()
 var opening := Vector2(room.gold, room.electricity)
 var start_seconds: float = model.time
 if opening != Vector2(BalanceRules.START_GOLD, 0.0):
  invalid.append("opening wallet differs from normal balance")
 var initial_door: float = room.door_hp
 var initial_hunter: float = model.hunter.max_hp
 var stats := new_statistics()
 var used_items := []
 var steps := 0
 var last_touch := 0
 var heal_total := 0.0
 var max_evolution := 1
 var reaper := false
 var peak_hp := 0.0
 cached_candidates.clear()
 approach_samples.clear()
 tactical_breaks.clear()
 while model.result.is_empty() and model.time < STORY_LIMIT:
  if steps % 6 == 0:
   use_plan(model, profile, fixture.policy, used_items, match_number)
  var previous: Vector2 = model.hunter.position
  var old_evolution: int = model.evolution.evolution_level
  model.tick(MODEL_STEP)
  if not observe(model, stats, previous, opening, old_evolution):
   invalid.append("nonfinite positions, negative wallet or broken economic ledger")
   break
  for event in model.presentation_events:
   if int(event.id) <= last_touch:
    continue
   last_touch = int(event.id)
   if event.type in ["hunter_recovery_ended", "hunter_recovered"]:
    heal_total += float(event.get("healed", 0.0))
  max_evolution = maxi(max_evolution, model.evolution.evolution_level)
  reaper = reaper or model.hunter.transformed
  peak_hp = maxf(peak_hp, model.hunter.max_hp)
  steps += 1
 var outcome: String = model.result
 if outcome not in ["victory", "defeat"] or not model.terminal_recorded:
  invalid.append("ordinary terminal combat result not reached within 900 model seconds")
 if steps == 0 or stats.peak_player_buildings == 0 or model.hunter.attacks == 0:
  invalid.append("missing paid player construction or Hunter combat")
 if stats.npc_sleep_mask != 31:
  invalid.append("all five NPCs did not reach beds")
 if fixture.policy == "item_assisted" and used_items.is_empty():
  invalid.append("declared item-assisted case did not consume an earned item")
 if fixture.policy != "item_assisted" and not used_items.is_empty():
  invalid.append("item-free case consumed an item")
 var cash_before: int = profile.rm_cash
 var terminal := profile.settle_match(match_number, model)
 var expected_track := StoryProgress.summary(profile.story, mode)
 var position_expected := mini(level+1, StoryCatalog.FINAL_LEVEL) if outcome == "victory" else maxi(level-1, StoryProgress.checkpoint_for(level-1))
 var highest_expected := level if outcome == "victory" else level-1
 if not terminal.is_empty() and (expected_track.position != position_expected or expected_track.highest != highest_expected):
  invalid.append("Story track failed to apply the completed match outcome")
 var reopened := PlayerProfile.new(profile.path)
 var saved := reopened.load_profile()
 if terminal.is_empty() or not saved or not ReplaySupport.numeric_same(reopened.story, profile.story) or reopened.rm_cash != profile.rm_cash or reopened.xp != profile.xp or not ReplaySupport.numeric_same(reopened.inventory,profile.inventory) or not profile.settle_match(match_number, model).is_empty():
  invalid.append("settlement, duplicate reward guard, or disk re-open failed")
  print("PHASE16_SAVE_DIAGNOSTIC ", fixture.id, " saved=", saved, " terminal=", not terminal.is_empty(), " story_equal=", ReplaySupport.numeric_same(reopened.story,profile.story))
 var doors := []
 for other: RoomState in model.rooms:
  doors.append({"index": other.index+1, "owner":other.owner, "alive":other.alive, "strikes":stats.door_strikes[other.index],
   "seconds_targeted":stats.target_seconds[other.index], "seconds_under_attack":stats.attack_seconds[other.index],
   "door_damage":other.door_damage_taken,"hunter_damage":other.main_damage_dealt,"shots":other.shots})
 row.merge({
  "seed":seed,"map_hash":packed.sha256_text(),"map":model.map_id,"chapter":mission.chapter,"title":mission.title,
  "preparation":model.preparation,"spawn":[spawn.x,spawn.y],"room":model.player_room+1,"seconds_to_bed":start_seconds,
  "opening_gold":opening.x,"opening_power":opening.y,"opening_door_hp":initial_door,"opening_hunter_max_hp":initial_hunter,
  "outcome":outcome,"seconds":model.time,"steps":steps,"terminal_recorded":model.terminal_recorded,
  "peak_buildings":stats.peak_player_buildings,"player_shots":room.shots,"player_damage":room.main_damage_dealt,
  "player_door_damage":room.door_damage_taken,"player_repairs":room.repair_actions,"contribution":model.contribution,
  "hunter_attacks":model.hunter.attacks,"hunter_retargets":model.hunter.retargets,"hunter_hp":model.hunter.hp,"hunter_peak_max_hp":peak_hp,
  "max_evolution":max_evolution,"reaper":reaper,"hall_visits":model.haunt_recovery.visits,"hall_attempts":model.haunt_recovery.attempts,
  "hall_heal_observed":heal_total,"navigation_recoveries":model.hunter.navigation_recoveries,
  "movement_diagnostics":{"blocked_steps":stats.blocked_motion_steps,"over_speed_steps":stats.speed_budget_violations},
  "events":stats.events,"event_counts":stats.event_counts,"doors":doors,"items_used":used_items,"opening_race_npcs":model.bot_claimed,
  "wallet":[room.gold,room.electricity],"ledger":room.ledger.totals,"max_ledger_error":stats.max_ledger_error,
  "settlement":{"position":expected_track.position,"highest":expected_track.highest,"checkpoint":expected_track.checkpoint,"saved":saved,"rm_cash":profile.rm_cash,"rm_cash_award":profile.rm_cash-cash_before},
 })
 return row

func run():
 var args := OS.get_cmdline_user_args()
 start_flags()
 variant = "v22"
 review_arm = "v23"
 if args.size() == 2 and args[0] == "earn":
  if not earn_inventory(true):
   push_error("Legitimate finite item stock could not be earned on checkpoint.")
   quit(1)
   return
  var result := DirAccess.copy_absolute(earned_profile_file, args[1])
  print("PHASE16_EARNED_INVENTORY ", JSON.stringify(warmup_receipt), " COPIED=", result == OK)
  quit(int(result != OK))
  return
 if args.size() not in [4, 5]:
  push_error("Pass output JSON, fixture JSON, baseline stock path, array slice start and optional count.")
  quit(2)
  return
 var fixtures = JSON.parse_string(FileAccess.get_file_as_string(args[1]))
 if fixtures is not Array:
  quit(2)
  return
 var first := int(args[3])
 var finish: int = mini(fixtures.size(), first + int(args[4])) if args.size() == 5 else fixtures.size()
 var rows := []
 for index in range(first, finish):
  var row := play_story(fixtures[index], args[2])
  rows.append(row)
  failures += int(not row.invalid.is_empty())
  print("PHASE16_MATCH ", row.fixture.id, " ", row.get("outcome", "-"), " ", row.get("seconds", -1), " ", row.invalid)
 var file := FileAccess.open(args[0], FileAccess.WRITE)
 if file == null:
  quit(2)
  return
 file.store_string(JSON.stringify({"cases":rows,"failures":failures,"step_seconds":MODEL_STEP,"limit_seconds":STORY_LIMIT}, " ") + "\n")
 print("PHASE16_COMPLETE_CASES=", rows.size(), " FAILURES=", failures)
 quit(int(failures > 0))
