class_name HauntedRecovery
extends RefCounted
## A reachable channel trades siege time for a small, interruptible heal.
const HALL_IDS := ["north", "south", "west", "east"]
const MAX_ATTEMPTS := 2
const HEAL_FRACTION := 0.18
const RECOVERY_SECONDS := 8.0
const MAX_TRAVEL_SECONDS := 12.0
const MIN_ACTIVE_SECONDS := 30.0
const RETREAT_GAP := 75.0
const INTERRUPT_FRACTION := 0.08
const MOVE_KEY := "hunter_haunted_hall"

var phase := "idle"
var hall_id := ""
var attempts := 0
var visits := 0
var available_at := 0.0
var travel_elapsed := 0.0
var recovery_elapsed := 0.0
var paused_active_time := 0.0
var budget := 0.0
var healed := 0.0
var channel_damage := 0.0
var passed_entrance := false
var _interrupted_story_approach := false
var stalled := 0.0

func is_active() -> bool:
 return phase != "idle"

func active_seconds(model) -> float:
 return maxf(0.0, model.hunter_active_seconds() - paused_active_time)

func begin_wave():
 paused_active_time = 0.0

func try_retreat(hunter, model) -> bool:
 if attempts >= MAX_ATTEMPTS or model.time < available_at or model.hunter_active_seconds() < MIN_ACTIVE_SECONDS:
  return false
 var halls: Dictionary = model.map_data.get("halls", {})
 var resident = model.player()
 if halls.size() != HALL_IDS.size() or hunter.transformed or hunter.hp <= 0 or resident == null or not resident.sleeping:
  return false
 if hunter.state not in [HunterState.State.MOVE, HunterState.State.ATTACK]:
  return false
 if hunter.recovery_remaining > 0 or hunter.charged_ready or hunter.archetype_primed or not hunter.tactical_action.is_empty():
  return false
 if not hunter.nightmare.action.is_empty() or hunter.nightmare.remaining > 0:
  return false
 if not hunter.arcane.action.is_empty() or not hunter.arcane.bolt.is_empty():
  return false
 # A boss-capable first form may retreat before its transformation threshold.
 # The Reaper's existing guard, channels and Crimson Domain own its later phases.
 var boss: bool = hunter.boss_policy.get("enabled", false)
 var threshold: float = (.67 if attempts == 0 else .59) if boss else (.42 if attempts == 0 else .24)
 if hunter.hp > hunter.max_hp * threshold:
  return false
 if boss:
  var transformation_hp: float = hunter.max_hp * hunter.boss_policy.hp_fraction
  var deadline_remaining: float = hunter.boss_policy.deadline - model.hunter_active_seconds()
  if hunter.hp <= transformation_hp or deadline_remaining < MAX_TRAVEL_SECONDS + RECOVERY_SECONDS:
   return false
 var desired := _pick_hall(model, hunter, halls)
 if desired.is_empty():
  available_at = model.time + 8.0
  return false
 attempts += 1
 _interrupted_story_approach = model.uses_story_intelligence() and hunter.state == HunterState.State.MOVE
 phase = "retreat"
 hall_id = desired
 hunter.state = HunterState.State.RETREAT
 hunter.cancel_boss_attack()
 hunter._clear_tactics()
 hunter.surge_remaining = 0.0
 if hunter.target >= 0 and hunter.target < model.rooms.size():
  model.rooms[hunter.target].repair_factor = 1.0
 _emit(model, "hunter_retreat")
 return true

func _pick_hall(model, hunter, halls: Dictionary) -> String:
 var best := ""
 var best_distance := INF
 for id in HALL_IDS:
  var hall: Dictionary = halls.get(id, {})
  if hall.is_empty():
   continue
  var distance := _path_length(model, hunter.position, hall.entrance)
  distance += _path_length(model, hall.entrance, hall.center)
  if distance < best_distance and distance <= hunter.speed * (MAX_TRAVEL_SECONDS - 1.0):
   best_distance = distance
   best = id
 return best

func _path_length(model, start: Vector2, finish: Vector2) -> float:
 if start.distance_squared_to(finish) < .01:
  return 0.0
 var route: Array = model.navigation_path(start, finish)
 if route.is_empty() or not Vector2(route.back()).is_equal_approx(finish):
  return INF
 var length := 0.0
 for waypoint: Vector2 in route:
  length += start.distance_to(waypoint)
  start = waypoint
 return length

func tick(delta: float, hunter, model):
 if not is_active() or delta <= 0:
  return
 var hall: Dictionary = model.map_data.get("halls", {}).get(hall_id, {})
 if hall.is_empty() or hunter.hp <= 0 or hunter.transformed or hunter.state not in [HunterState.State.RETREAT, HunterState.State.RECOVER]:
  cancel(model, "combat priority")
  return
 if float(model.items.timers.get("decoy", 0.0)) > 0.0:
  cancel(model, "diverted")
  return
 if phase == "retreat":
  var dt := minf(delta, MAX_TRAVEL_SECONDS - travel_elapsed)
  travel_elapsed += dt
  paused_active_time += dt
  var goal: Vector2 = hall.center if passed_entrance else hall.entrance
  var previous: Vector2 = hunter.position
  hunter.position = model.step_navigation(previous, goal, hunter.speed * dt, MOVE_KEY)
  model.items.trigger_segment(previous, hunter.position, model)
  if not is_active() or hunter.hp <= 0:
   return
  stalled = stalled + dt if previous.distance_squared_to(hunter.position) < .0001 and hunter.position.distance_squared_to(goal) > 4.0 else 0.0
  if hunter.position.distance_squared_to(goal) <= 4.0:
   if passed_entrance:
    phase = "recover"
    hunter.state = HunterState.State.RECOVER
    budget = minf(hunter.max_hp * HEAL_FRACTION, hunter.max_hp - hunter.hp)
    model._navigation_routes.erase(MOVE_KEY)
    _emit(model, "hunter_recovering")
    return
   passed_entrance = true
  if travel_elapsed >= MAX_TRAVEL_SECONDS or stalled >= 2.0:
   cancel(model, "route lost")
  return
 if not hall.bounds.has_point(hunter.position) or hunter.position.distance_squared_to(hall.center) > 16.0:
  cancel(model, "left the hall")
  return
 var dt := minf(delta, RECOVERY_SECONDS - recovery_elapsed)
 recovery_elapsed += dt
 paused_active_time += dt
 # Cap both cumulative recovery and current HP. Incoming hits remain live.
 var restored := maxf(0.0, minf(minf(budget - healed, budget * dt / RECOVERY_SECONDS), hunter.max_hp - hunter.hp))
 hunter.hp += restored
 healed += restored
 if recovery_elapsed >= RECOVERY_SECONDS or hunter.hp >= hunter.max_hp:
  if healed > 0.0:
   visits += 1
  cancel(model, "completed")

func note_damage(amount: float, model):
 if phase != "recover" or amount <= 0.0:
  return
 channel_damage += amount
 if channel_damage >= model.hunter.max_hp * INTERRUPT_FRACTION:
  cancel(model, "channel disrupted")

func cancel(model, reason: String):
 if not is_active():
  return
 _emit(model, "hunter_recovery_ended", reason)
 var hunter = model.hunter
 if hunter.state in [HunterState.State.RETREAT, HunterState.State.RECOVER] and hunter.hp > 0:
  hunter.state = HunterState.State.SEEK
  # A visit interrupted in transit says nothing about the door's strength.
  # After healing, score that room alongside the other reachable doors.
  hunter.avoid_target = -1 if _interrupted_story_approach and reason == "completed" else hunter.target
  hunter.target_time = 0.0
  hunter.siege_seconds = 0.0
  hunter.reassess_seconds = 0.0
  hunter.stalled_seconds = 0.0
  hunter.cooldown = maxf(hunter.cooldown, 1.0)
 model._navigation_routes.erase(MOVE_KEY)
 _interrupted_story_approach = false
 phase = "idle"
 hall_id = ""
 available_at = model.time + RETREAT_GAP
 travel_elapsed = 0.0
 recovery_elapsed = 0.0
 budget = 0.0
 healed = 0.0
 channel_damage = 0.0
 passed_entrance = false
 stalled = 0.0

func _emit(model, type: String, reason := ""):
 model.record_event(type, model.hunter.target, {"hall":hall_id, "position":model.hunter.position, "budget":budget, "healed":healed, "reason":reason})

func snapshot() -> Dictionary:
 return {
  "phase":phase, "hall":hall_id, "attempts":attempts, "visits":visits, "available_at":available_at,
  "travel_elapsed":travel_elapsed, "recovery_elapsed":recovery_elapsed, "paused_active_time":paused_active_time,
  "budget":budget, "healed":healed, "channel_damage":channel_damage, "passed_entrance":passed_entrance, "stalled":stalled
 }

static func valid(data) -> bool:
 if not data is Dictionary or data.size() != 13:
  return false
 if data.get("phase") not in ["idle", "retreat", "recover"] or not data.get("passed_entrance") is bool:
  return false
 if not _number(data.get("attempts"), MAX_ATTEMPTS) or not _number(data.get("visits"), MAX_ATTEMPTS):
  return false
 if floorf(float(data.attempts)) != data.attempts or floorf(float(data.visits)) != data.visits or data.visits > data.attempts:
  return false
 if not _number(data.get("available_at"), 1e12) or not _number(data.get("paused_active_time"), (MAX_TRAVEL_SECONDS + RECOVERY_SECONDS) * MAX_ATTEMPTS + .0001):
  return false
 if not _number(data.get("travel_elapsed"), MAX_TRAVEL_SECONDS) or not _number(data.get("recovery_elapsed"), RECOVERY_SECONDS) or not _number(data.get("stalled"), 2.0):
  return false
 if not _number(data.get("budget"), 1e12) or not _number(data.get("healed"), 1e12) or not _number(data.get("channel_damage"), 1e12) or data.healed > data.budget:
  return false
 if data.phase == "idle":
  return data.get("hall") == "" and not data.passed_entrance and data.travel_elapsed == 0 and data.recovery_elapsed == 0 and data.budget == 0 and data.healed == 0 and data.channel_damage == 0 and data.stalled == 0
 if data.get("hall") not in HALL_IDS or data.attempts <= data.visits:
  return false
 if data.phase == "retreat":
  return data.recovery_elapsed == 0 and data.budget == 0 and data.healed == 0 and data.channel_damage == 0
 return data.passed_entrance and data.budget > 0

static func _number(value, maximum: float) -> bool:
 return (value is float or value is int) and is_finite(float(value)) and value >= 0 and value <= maximum

func restore(data: Dictionary) -> bool:
 if not valid(data):
  return false
 phase = data.phase
 hall_id = data.hall
 attempts = int(data.attempts)
 visits = int(data.visits)
 available_at = data.available_at
 travel_elapsed = data.travel_elapsed
 recovery_elapsed = data.recovery_elapsed
 paused_active_time = data.paused_active_time
 budget = data.budget
 healed = data.healed
 channel_damage = data.channel_damage
 passed_entrance = data.passed_entrance
 stalled = data.stalled
 return true
