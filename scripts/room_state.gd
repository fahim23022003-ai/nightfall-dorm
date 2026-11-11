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
var door_hp = 150.0
var buildings: Dictionary = {}
var income_total = 0.0
var spent = 0.0
var profile = "player"
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
 if gold + 0.00001 < g or electricity + 0.00001 < e:
  return false
 gold -= g
 electricity -= e
 spent += g
 return true

func upgrade_bed() -> bool:
 if bed_level >= Catalog.BED_COST.size() or door_level < maxi(0,bed_level-1):
  return false
 if not pay(Catalog.BED_COST[bed_level],Catalog.BED_POWER[bed_level]):
  return false
 bed_level += 1
 return true

func upgrade_door() -> bool:
 if door_hp <= 0 or door_level >= Catalog.DOOR_COST.size() or bed_level < maxi(0,door_level-1):
  return false
 if not pay(Catalog.DOOR_COST[door_level],Catalog.DOOR_POWER[door_level]):
  return false
 var old_max = max_hp()
 door_level += 1
 door_hp += max_hp()-old_max
 return true

func repair_door() -> bool:
 if door_hp <= 0 or door_hp >= max_hp() or not pay(Catalog.REPAIR_COST):
  return false
 door_hp = minf(max_hp(),door_hp+Catalog.REPAIR_HEAL)
 return true

func build(kind: String, tile: int) -> bool:
 if not Catalog.BUILDINGS.has(kind) or tile < 0 or tile > 5 or buildings.has(tile) or not sleeping or not alive:
  return false
 var data = Catalog.BUILDINGS[kind]
 if kind == "heavy" and bed_level < 1:
  return false
 if not pay(data.gold,data.power):
  return false
 buildings[tile] = {"kind":kind,"level":1,"cooldown":0.0,"flash":0.0}
 return true

func upgrade_building(tile: int) -> bool:
 if not buildings.has(tile) or not alive:
  return false
 var b = buildings[tile]
 if b.level >= Catalog.BUILDING_MAX_LEVEL:
  return false
 var data = Catalog.BUILDINGS[b.kind]
 if not pay(data.gold*b.level, (data.power+3)*b.level):
  return false
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
