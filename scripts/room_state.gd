class_name RoomState
extends RefCounted

var index: int
var owner = -1
var alive = true
var sleeping = false
var closed = false
var gold = 25.0
var electricity = 0.0
var bed_level = 0
var door_level = 0
var door_hp = Catalog.DOOR_HP[0]
var buildings: Dictionary = {}
var income_total = 0.0
var shots = 0
var damage_dealt = 0.0
var spent = 0.0
var profile = "player"
var last_error = ""
var bot_timer = 0.0
var damage_flash = 0.0
var resident_position = Vector2.ZERO

func _init(number: int = 0):
 index = number

func center() -> Vector2:
 return Vector2(185 + (index % 3) * 310, 210 if index < 3 else 610)

func bounds() -> Rect2:
 return Rect2(center() - Vector2(135,110), Vector2(270,220))

func door_position() -> Vector2:
 return center() + Vector2(0,110 if index < 3 else -110)

func bed_position() -> Vector2:
 return center() + Vector2(-80,-45 if index < 3 else 45)

func tile_position(tile: int) -> Vector2:
 return center() + Vector2(-20 + (tile % 3) * 55, -20 + (tile / 3) * 65)

func max_hp() -> float:
 return Catalog.DOOR_HP[door_level]

func income_rate() -> float:
 var factor = 1.0
 for building in buildings.values():
  if building.kind == "economy":
   factor += Catalog.BUILDINGS.economy.rate * building.level
 return Catalog.BED_INCOME[bed_level] * factor if sleeping and alive else 0.0

func pay(g: float, e: float = 0.0) -> bool:
 if not is_finite(g) or not is_finite(e) or g < 0 or e < 0:
  return false
 if gold + 0.00001 < g or electricity + 0.00001 < e:
  return false
 gold -= g
 electricity -= e
 spent += g
 return true

func reject(reason: String) -> bool:
 last_error = reason
 return false

func upgrade_bed() -> bool:
 if not alive:
  return reject("Resident eliminated.")
 if bed_level >= Catalog.BED_COST.size():
  return reject("Bed is at maximum level.")
 if door_level < maxi(0,bed_level-1):
  return reject("Requires door level %d." % maxi(1,bed_level))
 if not afford(Catalog.BED_COST[bed_level],Catalog.BED_POWER[bed_level]):
  return false
 pay(Catalog.BED_COST[bed_level],Catalog.BED_POWER[bed_level])
 bed_level += 1
 return true

func upgrade_door() -> bool:
 if not alive:
  return reject("Resident eliminated.")
 if door_hp <= 0:
  return reject("Destroyed doors cannot be restored.")
 if door_level >= Catalog.DOOR_COST.size():
  return reject("Door is at maximum level.")
 if bed_level < maxi(0,door_level-1):
  return reject("Requires bed level %d." % maxi(1,door_level))
 if not afford(Catalog.DOOR_COST[door_level],Catalog.DOOR_POWER[door_level]):
  return false
 pay(Catalog.DOOR_COST[door_level],Catalog.DOOR_POWER[door_level])
 var old_max = max_hp()
 door_level += 1
 door_hp += max_hp()-old_max
 return true

func repair_door() -> bool:
 if not alive:
  return reject("Resident eliminated.")
 if door_hp <= 0:
  return reject("Destroyed doors cannot be repaired.")
 if door_hp >= max_hp():
  return reject("Door already has full health.")
 if not afford(Catalog.REPAIR_COST):
  return false
 pay(Catalog.REPAIR_COST)
 door_hp = minf(max_hp(),door_hp+Catalog.REPAIR_HEAL)
 return true

func afford(g: float, e: float = 0) -> bool:
 if not is_finite(g) or not is_finite(e) or g < 0 or e < 0:
  return reject("Invalid purchase price.")
 if gold+0.00001 < g:
  return reject("Need %d more gold." % ceili(g-gold))
 if electricity+0.00001 < e:
  return reject("Need %d more electricity. Build a Dynamo." % ceili(e-electricity))
 return true

func build(kind: String, tile: int) -> bool:
 if not alive:
  return reject("Resident eliminated.")
 if not sleeping:
  return reject("Sleep in your bed before building.")
 if not Catalog.BUILDINGS.has(kind):
  return reject("Unknown building.")
 if tile < 0 or tile > 5:
  return reject("Select a numbered floor tile in your room.")
 if buildings.has(tile):
  return reject("Tile occupied. Select an empty tile or upgrade this building.")
 var data = Catalog.BUILDINGS[kind]
 if kind == "heavy" and bed_level < 1:
  return reject("Arc turret requires bed level 2.")
 if not afford(data.gold,data.power):
  return false
 pay(data.gold,data.power)
 buildings[tile] = {"kind":kind,"level":1,"cooldown":0.0,"flash":0.0}
 return true

func upgrade_building(tile: int) -> bool:
 if not alive:
  return reject("Resident eliminated.")
 if not buildings.has(tile):
  return reject("Select an existing building to upgrade.")
 var b = buildings[tile]
 if b.level >= Catalog.BUILDING_MAX_LEVEL:
  return reject("Building is at maximum level.")
 var data = Catalog.BUILDINGS[b.kind]
 if not afford(data.gold*b.level, (data.power+3)*b.level):
  return false
 pay(data.gold*b.level, (data.power+3)*b.level)
 b.level += 1
 return true

func tick_economy(delta: float):
 var income = income_rate()*delta
 gold += income
 income_total += income
 damage_flash = maxf(0,damage_flash-delta)
 if not alive or not sleeping:
  return
 for b in buildings.values():
  b.flash = maxf(0,b.flash-delta)
  if b.kind == "generator":
   electricity += Catalog.BUILDINGS.generator.rate*b.level*delta
  elif b.kind == "repair" and door_hp > 0:
   door_hp = minf(max_hp(),door_hp+Catalog.BUILDINGS.repair.rate*b.level*delta)
