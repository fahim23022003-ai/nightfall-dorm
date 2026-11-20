extends SceneTree
## Integration of the seeded floor, real navigation, retreat and replay.

const GRID_ENV := "NIGHTFALL_FULL_ROOM_GRID"
const LEGACY_EARNED := "res://docs/evidence/gameplay-overhaul/balance/earned-cursed_mansion.json"
const TEST_SEEDS := [11, 41, 97]
var checks := 0
var failures := 0
var generator: GDScript

func _initialize() -> void:
 call_deferred("run")

func check(condition: bool, description: String) -> void:
 checks += 1
 if not condition:
  failures += 1
  push_error(description)

func canonical_equal(left, right) -> bool:
 if left is Dictionary and right is Dictionary:
  if left.size() != right.size():
   return false
  for key in left:
   if not right.has(key) or not canonical_equal(left[key], right[key]):
    return false
  return true
 if left is Array and right is Array:
  if left.size() != right.size():
   return false
  for index in range(left.size()):
   if not canonical_equal(left[index], right[index]):
    return false
  return true
 if (left is float or left is int) and (right is float or right is int):
  return absf(float(left) - float(right)) < 1e-7
 return left == right

func new_endless(theme: String, seed: int, run_id := 1, boosts := {}) -> MatchModel:
 var model := MatchModel.new()
 if not model.configure_endless(theme, "standard", seed, run_id, boosts):
  return null
 if not model.configure_balance():
  return null
 return model

func legal_path(model: MatchModel, start: Vector2, target: Vector2, route: Array, player := false) -> bool:
 if route.is_empty() or route.back().distance_to(target) > 1.0:
  return false
 var at := start
 for next in route:
  var count := maxi(1, ceili(at.distance_to(next) / 4.0))
  for step in range(count + 1):
   var point := at.lerp(next, float(step) / count)
   if not (model.can_walk(point) if player else model.navigation_walkable(point)):
    return false
  at = next
 return true

func route_length(start: Vector2, route: Array) -> float:
 var total := 0.0
 var at := start
 for next in route:
  total += at.distance_to(next)
  at = next
 return total

func navigation_checks(model: MatchModel, label: String) -> bool:
 if not model.map_data.has("halls"):
  check(false, label + " procedural map system was opted in")
  return false
 var spawn: Vector2 = model.map_data.hunter_spawn
 var player_spawn: Vector2 = model.map_data.spawn
 check(model.navigation_walkable(spawn) and model.can_walk(player_spawn), label + " spawns are navigable")
 for hall in model.map_data.halls.values():
  var finish: Vector2 = hall.center
  var path := model.navigation_path(spawn, finish)
  check(legal_path(model, spawn, finish, path), label + " Hunter can navigate all the way to " + hall.id)
 for room in model.rooms:
  var door: Vector2 = room.door_approach()
  check(legal_path(model, spawn, door, model.navigation_path(spawn, door)), label + " Hunter reaches room " + str(room.index))
  var bed: Vector2 = room.bed_position()
  var access := model.navigation_path(player_spawn, bed, true)
  if access.is_empty():
   # The exact bed sprite may be nonwalkable, but a real door-to-bed
   # interaction point must lie within its existing 60-unit sleep radius.
   for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
    var near: Vector2 = bed + direction * 54.0
    if not generator.contains_point(room.layout, near) or not model.can_walk(near):
     continue
    access = model.navigation_path(player_spawn, near, true)
    if not access.is_empty():
     bed = near
     break
  check(legal_path(model, player_spawn, bed, access, true), label + " resident can approach bed in room " + str(room.index))
  for strip in room.layout.floor:
   var far: Vector2 = strip.get_center()
   if far.distance_to(room.door_position()) > 70.0 and model.can_walk(far):
    room.closed = true
    check(not model.can_walk(far) and model.navigation_path(player_spawn, far, true).is_empty(), label + " shut door forbids player path around wall")
    room.closed = false
    break
 return true

func alternate_route_checks(model: MatchModel) -> bool:
 var halls: Dictionary = model.map_data.halls
 var found := false
 for pair in [["north", "south"], ["west", "east"], ["north", "east"], ["south", "west"]]:
  var start: Vector2 = halls[pair[0]].center
  var end: Vector2 = halls[pair[1]].center
  var shortest := model.navigation_path(start, end)
  for variant in range(1, 9):
   var alternate: Array = model.call("navigation_path", start, end, false, variant)
   if alternate == shortest or alternate.is_empty():
    continue
   check(legal_path(model, start, end, alternate), "alternate route follows real surfaces")
   check(alternate == model.call("navigation_path", start, end, false, variant), "repeat of route variant is deterministic")
   check(route_length(start, alternate) <= route_length(start, shortest) * 1.7 + 4.0, "alternative avoids unreasonable detours")
   found = true
   break
  if found:
   break
 return found

func claim_and_sleep(model: MatchModel, index: int) -> bool:
 if not model.claim_room(index):
  return false
 model.player_position = model.player().bed_position()
 return model.sleep_player()

func buy_fixture_building(model: MatchModel) -> bool:
 var room: RoomState = model.player()
 var bounds := room.spatial.grid_bounds()
 for y in range(int(bounds.position.y), ceili(bounds.end.y), 16):
  for x in range(int(bounds.position.x), ceili(bounds.end.x), 16):
   var at := room.spatial.aligned(Vector2(x, y), "turret", 1)
   if room.spatial.purchase_reason("turret", at, 1) == "":
    return model.place_building("turret", at, 1)
 return false

func grid_checks(model: MatchModel, label: String) -> void:
 var index := -1
 for room in model.rooms:
  if not room.layout.voids.is_empty():
   index = room.index
   break
 check(index >= 0 and claim_and_sleep(model, index), label + " claim irregular player room and sleep")
 var room: RoomState = model.player()
 if room == null:
  return
 check(room.spatial != null and room.spatial.grid, label + " Full Room Grid available")
 if room.spatial == null or not room.spatial.grid:
  return
 var price := room.quote_build("turret")
 room.gold = price.x + 100.0
 var starting: float = room.gold
 for rect in room.layout.voids:
  var point := room.spatial.aligned(rect.get_center(), "turret", 1)
  check(not model.place_building("turret", point, 1), label + " cannot buy a machine in cutout")
  check(room.gold == starting and room.buildings.size() == 0, label + " cutout rejection is transactional")
 check(buy_fixture_building(model), label + " paid machine fits genuine floor")
 if room.buildings.is_empty():
  return
 var id: int = room.buildings.keys()[0]
 var footprint := SpatialConstruction.grid_footprint(room.tile_position(id), "turret", 1)
 check(generator.contains_rect(room.layout, footprint), label + " paid footprint stays entirely in floor")
 check(absf(room.gold - (starting - price.x)) < .0001, label + " purchase debits existing price exactly")

func recovery_checks(model: MatchModel) -> void:
 var recovery = model.get("haunt_recovery")
 check(recovery != null, "procedural match owns Haunted Hall recovery state")
 if recovery == null:
  return
 var hall: Dictionary = model.map_data.halls.west
 var approach: Vector2 = hall.entrance + (hall.entrance - hall.center).normalized() * 84.0
 var nearest_room := 0
 var closest := INF
 for candidate in model.rooms:
  var route := model.navigation_path(approach, candidate.door_approach())
  var distance := route_length(approach, route) if not route.is_empty() else INF
  if distance < closest:
   nearest_room = candidate.index
   closest = distance
 check(claim_and_sleep(model, nearest_room), "recovery fixture claims and sleeps normally")
 if model.player() == null:
  return
 var room: RoomState = model.player()
 model.time = model.preparation + 33.0
 model.bot_claimed = 5
 model.hunter.position = approach
 model.hunter.state = HunterState.State.MOVE
 model.hunter.target = room.index
 model.hunter.boss_policy.enabled = false
 model.hunter.tactical_cooldown = 120.0
 # Establish the ordinary growth at the wounded approach before measuring.
 model.hunter.tick(0.0, model)
 model.hunter.hp = model.hunter.max_hp * .36
 var starting_hp: float = model.hunter.hp
 var previous: Vector2 = model.hunter.position
 var max_tick_gain := 0.0
 var phase_frames := {}
 var entered := false
 var selected_hall := ""
 var resumed_combat := false
 var finish_hp := starting_hp
 var heal_budget := 0.0
 var healing_amount := 0.0
 var legal_motion := true
 var no_early_heal := true
 for i in range(700):
  var before: float = model.hunter.hp
  var previous_phase: String = recovery.phase
  model.tick(.1)
  var phase: String = recovery.phase
  phase_frames[phase] = phase_frames.get(phase, 0) + 1
  if phase == "retreat":
   selected_hall = recovery.hall_id
   no_early_heal = no_early_heal and recovery.healed == 0.0
   legal_motion = legal_motion and model.navigation_walkable(model.hunter.position)
   legal_motion = legal_motion and model.hunter.position.distance_to(previous) <= model.hunter.speed * .1 + .12
  if phase == "recover":
   entered = true
   var destination: Dictionary = model.map_data.halls.get(recovery.hall_id, {})
   if not destination.is_empty():
    legal_motion = legal_motion and destination.bounds.has_point(model.hunter.position)
   max_tick_gain = maxf(max_tick_gain, model.hunter.hp - before)
   heal_budget = recovery.budget
   healing_amount = recovery.healed
  if previous_phase == "recover" and phase == "idle":
   finish_hp = model.hunter.hp
   for event in model.presentation_events:
    if event.type == "hunter_recovery_ended":
     healing_amount = event.healed
  if entered and phase == "idle" and model.hunter.attacks > 0:
   resumed_combat = true
   break
  previous = model.hunter.position
 check(phase_frames.get("retreat", 0) > 1 and model.map_data.halls.has(selected_hall), "Hunter really traveled to a named Hall")
 check(entered and phase_frames.get("recover", 0) > 5, "Hunter held legal recovery animation over multiple ticks inside Hall")
 check(no_early_heal and legal_motion, "retreat neither healed in transit nor crossed a wall or teleported")
 var recovered: float = healing_amount / model.hunter.max_hp
 check(finish_hp > starting_hp and recovered >= .15 and recovered <= .201 and absf(healing_amount - heal_budget) < .01, "successful recovery heals 15–20 percent in current tuning")
 check(max_tick_gain > 0.0 and max_tick_gain < model.hunter.max_hp * .05, "healing is gradual")
 check(resumed_combat, "Hunter naturally returns to actual attack")
 check(recovery.attempts == 1 and recovery.visits == 1, "one visit consumes one budget slot")
 print("NIGHTMARE_RECOVERY hall=", selected_hall, " phases=", phase_frames, " healed_fraction=", recovered, " combat_resumed=", resumed_combat)

func recovery_counterplay(model: MatchModel) -> void:
 var recovery = model.get("haunt_recovery")
 if recovery == null or recovery.visits != 1:
  return
 var hunter: HunterState = model.hunter
 var room: RoomState = model.player()
 var hall: Dictionary = model.map_data.halls.west
 # Stage a wounded exterior approach on the same earned visit ledger. Advance
 # actual ticks for the second route and apply the ordinary incoming-hit API.
 hunter.position = hall.entrance
 hunter.state = HunterState.State.MOVE
 hunter.target = room.index
 hunter.hp = hunter.max_hp * .20
 hunter.recovery_remaining = 0.0
 hunter.archetype_primed = false
 hunter.charged_ready = false
 hunter.tactical_action = ""
 hunter.arcane.clear_transients()
 hunter.nightmare.clear()
 var gate: float = recovery.available_at
 model.time = maxf(model.time, gate + .1)
 for i in range(120):
  model.tick(.1)
  if recovery.phase == "recover":
   break
 check(recovery.phase == "recover" and recovery.attempts == 2, "second approach consumes the final attempt")
 if recovery.phase != "recover":
  return
 var active_state: Dictionary = recovery.snapshot()
 var clone := HauntedRecovery.new()
 check(HauntedRecovery.valid(active_state) and clone.restore(JSON.parse_string(JSON.stringify(active_state, "", true, true))) and canonical_equal(clone.snapshot(), active_state), "a live Hall channel has a validated, lossless recovery record")
 var hp: float = hunter.hp
 hunter.hurt(hunter.max_hp * .12)
 check(hunter.hp < hp, "ordinary hits still damage the Hunter in the Hall")
 check(recovery.phase == "idle" and recovery.attempts == 2 and recovery.visits == 1, "sufficient damage interrupts channel without awarding a successful visit")
 var saw_interrupt := false
 for event in model.presentation_events:
  if event.type == "hunter_recovery_ended" and event.get("reason", "") == "channel disrupted":
   saw_interrupt = true
 check(saw_interrupt, "counterplay interruption is visible to presentation events")
 model.time = recovery.available_at + .1
 hunter.state = HunterState.State.MOVE
 hunter.target = room.index
 hunter.position = hall.entrance
 hunter.hp = hunter.max_hp * .16
 model.tick(.1)
 check(recovery.attempts == 2 and recovery.phase == "idle", "subsequent eligible low HP cannot begin an infinite retreat loop")

func roundtrip_checks(model: MatchModel, profile: PlayerProfile = null) -> void:
 if model.player() == null:
  return
 # Replay only saves sealed intermissions. Stage the terminal HP and tick
 # the ordinary model to seal this artificial award-free save fixture.
 model.bot_claimed = model.rooms.filter(func(room): return room.owner > 0).size()
 model.hunter.hp = 0.0
 model.hunter.state = HunterState.State.DEAD
 model.tick(.1)
 check(model.endless.phase == "intermission", "existing wave state machine sealed checkpoint")
 var encoded := ReplaySnapshot.encode(model)
 check(not encoded.is_empty() and ReplaySnapshot.valid(encoded), "procedural checkpoint is accepted by replay validator")
 if encoded.is_empty():
  return
 check(encoded.version == 4 and encoded.ruleset == 7, "new snapshot explicitly identifies procedural rules")
 var broken := encoded.duplicate(true)
 broken.generated_map.seed = str(int(broken.seed) + 1)
 check(not ReplaySnapshot.valid(broken), "save rejects procedural geometry with mismatched seed")
 broken = encoded.duplicate(true)
 broken.generated_map.halls.erase("east")
 check(not ReplaySnapshot.valid(broken), "save rejects missing Haunted Hall")
 broken = encoded.duplicate(true)
 broken.haunted_recovery.attempts = 3
 check(not ReplaySnapshot.valid(broken), "save rejects excessive retreat attempts")
 var packed: Dictionary = generator.pack(model.map_data)
 var recovery = model.get("haunt_recovery")
 var recovery_state: Dictionary = recovery.snapshot() if recovery != null else {}
 var toggle := OS.get_environment("NIGHTFALL_PROCEDURAL_MAPS")
 OS.set_environment("NIGHTFALL_PROCEDURAL_MAPS", "0")
 var resumed := ReplaySnapshot.restore(JSON.parse_string(JSON.stringify(encoded, "", true, true)))
 OS.set_environment("NIGHTFALL_PROCEDURAL_MAPS", toggle)
 check(resumed != null, "normal replay can reload new save with preview off")
 if resumed == null:
  return
 check(generator.pack(resumed.map_data) == packed, "resume uses exact saved seed, geometry and four Halls")
 check(canonical_equal(encoded, ReplaySnapshot.encode(resumed)), "encoded save roundtrip preserves checkpoints and investments")
 var restored_recovery = resumed.get("haunt_recovery")
 check(restored_recovery != null and canonical_equal(restored_recovery.snapshot(), recovery_state), "recovery budget persists exactly through checkpoint")
 check(resumed.continue_wave("repair") and generator.pack(resumed.map_data) == packed, "next wave does not reroll the map")
 if profile != null:
  check(profile.checkpoint_endless(model), "existing profile API writes the procedural checkpoint to disk")
  var disk := PlayerProfile.new(profile.path)
  check(disk.load_profile() and not disk.read_only, "profile reloads procedural checkpoint from disk")
  OS.set_environment("NIGHTFALL_PROCEDURAL_MAPS", "0")
  var disk_model: MatchModel = disk.resume_endless()
  OS.set_environment("NIGHTFALL_PROCEDURAL_MAPS", toggle)
  check(disk_model != null, "ordinary disk Resume restores procedural checkpoint with preview off")
  if disk_model != null:
   check(generator.pack(disk_model.map_data) == packed and canonical_equal(disk_model.haunt_recovery.snapshot(), recovery_state), "disk Resume retains seed, map geometry and Hall budget")

func boss_checks() -> void:
 var model := MatchModel.new()
 model.reset(199)
 check(model.configure_match("standard") and model.configure_stage("stage_3") and model.is_procedural(), "boss starts on procedural Campaign")
 check(claim_and_sleep(model, 1), "boss fixture claims and sleeps normally")
 var room: RoomState = model.player()
 if room == null:
  return
 room.bed_level = 6
 room.door_level = 6
 room.door_hp = room.max_hp()
 var hunter: HunterState = model.hunter
 model.time = model.preparation + 12.0
 hunter.position = room.door_approach()
 hunter.target = room.index
 hunter.state = HunterState.State.ATTACK
 hunter.cooldown = 100.0
 hunter.tick(0.0, model)
 hunter.hurt(hunter.max_hp)
 check(hunter.transformed and hunter.state == HunterState.State.TRANSFORM and is_equal_approx(hunter.hp, .55 * hunter.max_hp), "ordinary first lethal damage crosses exact awakening guard on new geometry")
 for i in range(40):
  model.tick(.1)
  if hunter.state != HunterState.State.TRANSFORM:
   break
 check(hunter.transformed and hunter.state != HunterState.State.TRANSFORM and model.presentation_events.filter(func(e): return e.type == "boss_transform").size() == 1, "awakening completes once at normal timing")
 hunter.phase_guard_remaining = 0.0
 hunter.hurt(hunter.max_hp)
 model.wrath.tick(.01, model)
 check(is_equal_approx(hunter.hp, .35 * hunter.max_hp) and model.wrath.phase == 2, "Reaper reaches existing phase-two damage and event guard")
 hunter.phase_guard_remaining = 0.0
 hunter.hurt(hunter.max_hp)
 model.wrath.tick(.01, model)
 check(is_equal_approx(hunter.hp, .1 * hunter.max_hp) and model.wrath.ability == "crimson_execution", "existing final threshold starts Crimson Execution warning")
 for i in range(32):
  model.wrath.tick(.1, model)
 check(model.wrath.domain_active() and model.wrath.counts.get("crimson_execution", 0) == 1 and model.haunt_recovery.attempts == 0, "Crimson Domain activates once with no Hall intervention")
 model.wrath.end_domain(model)
 check(not model.wrath.begin("crimson_execution", model, room.index), "Crimson cannot rearm after one legal execution")

func run() -> void:
 generator = load("res://scripts/nightmare_map.gd")
 OS.set_environment(GRID_ENV, "1")
 if generator == null or not generator.can_instantiate():
  push_error("Cannot load procedural generator")
  quit(2)
  return
 var visited := 0
 var alternatives := 0
 for theme in MapCatalog.IDS:
  for seed in TEST_SEEDS:
   var label := "%s/%d" % [theme, seed]
   var model := new_endless(theme, seed)
   check(model != null, label + " normal Endless configuration")
   if model == null or not navigation_checks(model, label):
    continue
   visited += 1
   alternatives += int(alternate_route_checks(model))
   if seed == TEST_SEEDS[0]:
    grid_checks(model, label)
    if theme == MapCatalog.IDS[0]:
     roundtrip_checks(model)
 var original_hash := FileAccess.get_sha256(LEGACY_EARNED)
 var old := ReplaySnapshot.restore(JSON.parse_string(FileAccess.get_file_as_string(LEGACY_EARNED)))
 check(old != null and not old.map_data.has("halls"), "active opt-in does not reroll an earned legacy save")
 check(FileAccess.get_sha256(LEGACY_EARNED) == original_hash, "legacy checkpoint source bytes unchanged")
 check(visited == MapCatalog.IDS.size() * TEST_SEEDS.size() and alternatives >= 5, "reachable alternative routes exist across procgen sample")
 var temp_path := "user://nightmare-disk-%s.json" % Time.get_ticks_usec()
 var test_profile := PlayerProfile.new(temp_path)
 var entry := test_profile.begin_endless("abandoned_dorm", "standard", 72)
 check(not entry.is_empty(), "normal profile starts an isolated procedural run")
 if not entry.is_empty():
  var match_state := new_endless("abandoned_dorm", 72, int(entry.run_id), RankCatalog.bonuses(entry.equipped))
  if match_state != null and match_state.map_data.has("halls"):
   recovery_checks(match_state)
   recovery_counterplay(match_state)
   roundtrip_checks(match_state, test_profile)
 for path in [temp_path, temp_path + ".bak"]:
  if FileAccess.file_exists(path):
   DirAccess.remove_absolute(path)
 boss_checks()
 print("NIGHTMARE_RUNTIME maps=", visited, " alternate_route_maps=", alternatives, " checks=", checks, " failures=", failures)
 quit(1 if failures else 0)
