class_name HunterSiegeStrategy
extends RefCounted
## Compare attainable doors using the same costs at first approach and on reassessment.
const ATTACK_WINDOW := 10.0
const MAX_BREACH_ESTIMATE := 55.0
const MIN_SWITCH_GAIN := 5.0
const MAX_EXPOSURE_COST := 38.0

static func assess(model, hunter) -> Dictionary:
 var travel: Dictionary = model.hunter_route_costs(hunter.position)
 var fire := []
 for room in model.rooms:
  if not room.alive or room.magic_state.disrupt>0.0:
   continue
  for id in room.buildings:
   var building: Dictionary=room.buildings[id]
   if building.kind not in DefenseEffects.WEAPONS:
    continue
   var stats := BuildingStats.weapon_stats(model,room,building)
   var range_limit: float = stats.range*hunter.nightmare.range_factor(room.index)
   fire.append([room.tile_position(id),range_limit*range_limit,stats.dps,DamageRules.weapon(building.kind).element])
 var result := {}
 var affinity := DamageRules.affinity(hunter.archetype)
 var attack_rate: float = hunter.damage/maxf(.1,hunter.interval)
 for room in model.rooms:
  if room.owner<0 or not room.alive or not room.sleeping:
   continue
  var distance: float=travel.get(room.index,INF)
  if not is_finite(distance):
   continue
  var door: Vector2=room.door_approach()
  var dps := 0.0
  for weapon in fire:
   if door.distance_squared_to(weapon[0])<=weapon[1]:
    dps+=weapon[2]*DamageRules.multiplier(weapon[3],affinity)
  var repairs := 0.0
  for building in room.buildings.values():
   if building.kind=="repair":
    repairs+=room.repair_status(building).actual
  var breach := minf(MAX_BREACH_ESTIMATE,room.door_hp/maxf(attack_rate*.24,attack_rate-repairs))
  var exposure := dps*minf(breach,ATTACK_WINDOW)
  var risk := minf(MAX_EXPOSURE_COST,exposure*32.0/maxf(hunter.hp,1.0))
  var smoke := 5000.0 if room.index==model.player_room and float(model.items.timers.get("smoke",0.0))>0.0 else 0.0
  result[room.index]=distance/maxf(1.0,hunter.speed)+breach+risk+smoke
 return result

static func best_room(scores: Dictionary, excluded: int=-1) -> int:
 var best := -1
 var lowest := INF
 for index in scores:
  if index!=excluded and scores[index]<lowest:
   best=index
   lowest=scores[index]
 return best

static func productive_progress(start_hp: float, current_hp: float, damage: float) -> bool:
 return start_hp-current_hp>=maxf(1.0,damage)

static func worth_switching(current_cost: float, alternative_cost: float) -> bool:
 return is_finite(alternative_cost) and alternative_cost+maxf(MIN_SWITCH_GAIN,current_cost*.20)<current_cost
