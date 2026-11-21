class_name HunterSiegeStrategy
extends RefCounted
## Compare attainable doors using the same costs at first approach and on reassessment.
const ATTACK_WINDOW := 10.0
const MAX_BREACH_ESTIMATE := 55.0
const MIN_SWITCH_GAIN := 5.0
const MAX_EXPOSURE_COST := 38.0

## A defender must erase at least half the landed damage, including one
## ordinary strike's worth, before a productive siege is reconsidered.
static func defended_breach_estimate(door_hp: float, net_loss: float, landed_damage: float, strike: float, elapsed: float) -> float:
 if elapsed<=0.0 or net_loss<=0.0 or landed_damage-net_loss<maxf(strike,landed_damage*.5):
  return 0.0
 return minf(MAX_BREACH_ESTIMATE,door_hp*elapsed/net_loss)

# Expected unimpeded time inside a single firing circle along the same
# graph route used for the distance estimate. This predicts exposure only.
static func covered_distance(route: PackedVector2Array, origin: Vector2, radius_squared: float) -> float:
 var covered:=0.0
 for i in range(1,route.size()):
  var segment:=route[i]-route[i-1]
  var length:=segment.length()
  if length<=0.001:continue
  var direction:=segment/length
  var offset:=origin-route[i-1]
  var along:=offset.dot(direction)
  var perpendicular:=offset.cross(direction)
  var half_chord_sq:=radius_squared-perpendicular*perpendicular
  if half_chord_sq<=0.0:continue
  var half_chord:=sqrt(half_chord_sq)
  covered+=maxf(0.0,minf(length,along+half_chord)-maxf(0.0,along-half_chord))
 return covered

static func assess(model, hunter, defended_door: int=-1, defended_breach: float=0.0) -> Dictionary:
 var story: bool=model.uses_story_intelligence()
 var paths: Dictionary={}
 var travel: Dictionary=model.hunter_route_costs(hunter.position,paths if story else null)
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
 var speed: float=maxf(1.0,hunter.speed)
 var attack_rate: float = hunter.damage/maxf(.1,hunter.interval)
 for room in model.rooms:
  if room.owner<0 or not room.alive or not room.sleeping:
   continue
  var distance: float=travel.get(room.index,INF)
  if not is_finite(distance):
   continue
  var door: Vector2=room.door_approach()
  var dps := 0.0
  var transit_damage:=0.0
  for weapon in fire:
   var effective_dps: float=weapon[2]*DamageRules.multiplier(weapon[3],affinity)
   if story:
    transit_damage+=effective_dps*covered_distance(paths[room.index],weapon[0],weapon[1])/speed
   if door.distance_squared_to(weapon[0])<=weapon[1]:
    dps+=effective_dps
  var repairs := 0.0
  for building in room.buildings.values():
   if building.kind=="repair":
    var station: Dictionary=room.repair_status(building)
    if story and station.reason=="door full" and (station.upkeep==0.0 or room.electricity-station.reserve>=station.upkeep):
     repairs+=station.nominal
    else:
     repairs+=station.actual
  var door_rate:=attack_rate
  if story:
   door_rate*=model.pressure.factor(model)*model.evolution.damage_factor()*StrategyCatalog.BRANCHES.get(room.door_branch,{}).get("mitigation",1.0)
   if model.uses_player_door_survival() and room.index==model.player_room:
    door_rate*=1.0-PlayerDoorSurvival.armor(room.door_level)
  var breach := minf(MAX_BREACH_ESTIMATE,room.door_hp/maxf(.01,maxf(door_rate*.24,door_rate-repairs)))
  if room.index==defended_door:
   breach=maxf(breach,defended_breach)
  var exposure := transit_damage+dps*minf(breach,ATTACK_WINDOW)
  var risk := minf(MAX_EXPOSURE_COST,exposure*32.0/maxf(hunter.hp,1.0))
  var smoke := 5000.0 if room.index==model.player_room and float(model.items.timers.get("smoke",0.0))>0.0 else 0.0
  result[room.index]=distance/speed+breach+risk+smoke
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
