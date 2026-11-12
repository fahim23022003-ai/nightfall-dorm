class_name RoomState
extends RefCounted

signal presentation_action(type: String, data: Dictionary)

var layout: Dictionary={}
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
var occupied_seconds=0.0
var door_damage_taken=0.0
var income_multiplier=1.0
var power_multiplier=1.0
var door_multiplier=1.0
var turret_multiplier=1.0
var rescue_fraction=0.0
var rescue_used=false
var construction_actions=0
var repair_actions=0
var breach_reacted=false
var eliminated_position=Vector2.INF
var repair_factor=1.0
var temporary_income=1.0
var item_bonus_income=0.0
var coupon_armed=false
var coupon_payment: Callable
func building_price(g: float,e: float) -> Vector2:
 return Vector2(g,e)*(ItemCatalog.TUNING.coupon_factor if coupon_armed else 1.0)
func spend_coupon(saved: Vector2=Vector2.ZERO) -> bool:
 if not coupon_armed: return true
 if not coupon_payment.is_valid() or not coupon_payment.call(saved): return reject("Coupon could not be saved; purchase cancelled.")
 coupon_armed=false
 presentation_action.emit("coupon_used",{"gold":saved.x,"power":saved.y})
 return true

func apply_boosts(boosts: Dictionary):
 gold+=boosts.get("gold",0.0)
 var old_max=max_hp()
 door_multiplier=boosts.get("door",1.0)
 door_hp+=max_hp()-old_max
 income_multiplier=boosts.get("income",1.0)
 power_multiplier=boosts.get("power",1.0)
 turret_multiplier=boosts.get("damage",1.0)
 rescue_fraction=boosts.get("rescue",0.0)

func try_rescue() -> bool:
 if rescue_used or rescue_fraction<=0 or not alive or door_hp<=0 or door_hp>max_hp()*0.25: return false
 rescue_used=true
 door_hp=minf(max_hp(),door_hp+max_hp()*rescue_fraction)
 return true

func _init(number: int = 0):
 index = number

func survivor_name() -> String:
 return Catalog.SURVIVOR_NAMES[clampi(owner,0,Catalog.SURVIVOR_NAMES.size()-1)]

func center() -> Vector2:
 if not layout.is_empty(): return layout.bounds.get_center()
 return Vector2(185 + (index % 3) * 310, 210 if index < 3 else 610)

func bounds() -> Rect2:
 if not layout.is_empty(): return layout.bounds
 return Rect2(center() - Vector2(135,110), Vector2(270,220))

func door_position() -> Vector2:
 if not layout.is_empty(): return layout.door
 return center() + Vector2(0,110 if index < 3 else -110)

func bed_position() -> Vector2:
 if not layout.is_empty(): return layout.bed
 return center() + Vector2(-80,-45 if index < 3 else 45)

func cabinet_position() -> Vector2:
 if not layout.is_empty(): return layout.cabinet
 return bounds().position+Vector2(224,39)

func plant_position() -> Vector2:
 if not layout.is_empty(): return layout.plant
 return bounds().position+Vector2(23,179 if index<3 else 37)

func furniture_blocks(point: Vector2) -> bool:
 # Foot-point collision: illustrated furniture must not be walk-through scenery.
 return Rect2(bed_position()-Vector2(27,45),Vector2(54,89)).has_point(point) or Rect2(cabinet_position()+Vector2(-18,5),Vector2(36,20)).has_point(point) or Rect2(plant_position()+Vector2(-10,7),Vector2(20,14)).has_point(point)

func tile_position(tile: int) -> Vector2:
 if not layout.is_empty(): return layout.tiles[tile] if tile>=0 and tile<tile_count() else center()
 return center() + Vector2(-20 + (tile % 3) * 55, -20 + (tile / 3) * 65)

func tile_count() -> int:
 return layout.tiles.size() if not layout.is_empty() else 6
func door_normal() -> Vector2:
 return layout.door_normal if not layout.is_empty() else Vector2.DOWN if index<3 else Vector2.UP
func door_approach() -> Vector2:
 return door_position()+door_normal()*(24 if not layout.is_empty() else 22)
func corridor_anchor() -> Vector2:
 return layout.anchor if not layout.is_empty() else Vector2(door_position().x,410)

func max_hp() -> float:
 return Catalog.DOOR_HP[door_level]*door_multiplier

func income_rate() -> float:
 var factor = 1.0
 for building in buildings.values():
  if building.kind == "economy":
   factor += Catalog.BUILDINGS.economy.rate * building.level
 return Catalog.BED_INCOME[bed_level] * factor * income_multiplier * temporary_income if sleeping and alive else 0.0

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
 presentation_action.emit("bed_upgrade",{})
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
 presentation_action.emit("door_upgrade",{})
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
 repair_actions+=1
 door_hp = minf(max_hp(),door_hp+Catalog.REPAIR_HEAL*repair_factor)
 presentation_action.emit("repair",{})
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
 if tile < 0 or tile >= tile_count():
  return reject("Select a numbered floor tile in your room.")
 if buildings.has(tile):
  return reject("Tile occupied. Select an empty tile or upgrade this building.")
 var data = Catalog.BUILDINGS[kind]
 if kind == "heavy" and bed_level < 1:
  return reject("Arc turret requires bed level 2.")
 var price=building_price(data.gold,data.power)
 if not afford(price.x,price.y):
  return false
 if not spend_coupon(Vector2(data.gold,data.power)-price): return false
 if not pay(price.x,price.y): return reject("Purchase could not be paid.")
 buildings[tile] = {"kind":kind,"level":1,"cooldown":0.0,"flash":0.0,
  "invested_gold":price.x,"invested_power":price.y}
 construction_actions+=1
 presentation_action.emit("build",{"kind":kind,"tile":tile})
 return true

func upgrade_building(tile: int) -> bool:
 if not alive:
  return reject("Resident eliminated.")
 if not buildings.has(tile):
  return reject("Select an existing building to upgrade.")
 var b = buildings[tile]
 var requirement=Catalog.upgrade_requirement(b.kind,b.level,bed_level,door_level)
 if requirement!="":return reject(requirement)
 var data = Catalog.BUILDINGS[b.kind]
 var list_price=Catalog.upgrade_cost(b.kind,b.level)
 var price=building_price(list_price.x,list_price.y)
 if not afford(price.x,price.y):
  return false
 var paid_gold=price.x
 var paid_power=price.y
 if not spend_coupon(list_price-price): return false
 if not pay(paid_gold,paid_power): return reject("Upgrade could not be paid.")
 b.invested_gold=b.get("invested_gold",0.0)+paid_gold
 b.invested_power=b.get("invested_power",0.0)+paid_power
 b.level += 1
 construction_actions+=1
 presentation_action.emit("building_upgrade",{"kind":b.kind,"tile":tile,"level":b.level})
 return true

# Record actual successful payments, never infer investment from level or prices.
# Match buildings are transient, not part of profile saves. Unpaid fixtures have
# no refundable investment. Fractional currency is retained without rounding.
func building_refund(tile: int) -> Vector2:
 if tile<0 or tile>=tile_count() or not buildings.has(tile): return Vector2.ZERO
 var building=buildings[tile]
 var gold_paid=float(building.get("invested_gold",0.0))
 var power_paid=float(building.get("invested_power",0.0))
 if not is_finite(gold_paid) or not is_finite(power_paid) or gold_paid<0 or power_paid<0:
  return Vector2.ZERO
 return Vector2(gold_paid,power_paid)*Catalog.BUILDING_REFUND_FRACTION

func sell_building(tile: int) -> bool:
 if not alive: return reject("Resident eliminated.")
 if tile<0 or tile>=tile_count() or not buildings.has(tile): return reject("Select an existing building to sell.")
 var refund=building_refund(tile)
 buildings.erase(tile)
 gold+=refund.x
 electricity+=refund.y
 presentation_action.emit("sale",{"gold":refund.x,"power":refund.y,"tile":tile})
 last_error=""
 return true

func tick_economy(delta: float):
 if sleeping and alive: occupied_seconds+=delta
 var income = income_rate()/temporary_income*delta+item_bonus_income
 item_bonus_income=0
 gold += income
 income_total += income
 damage_flash = maxf(0,damage_flash-delta)
 if not alive or not sleeping:
  return
 for b in buildings.values():
  b.flash = maxf(0,b.flash-delta)
  if b.kind == "generator":
   electricity += Catalog.BUILDINGS.generator.rate*b.level*delta*power_multiplier
  elif b.kind == "repair" and door_hp > 0:
   door_hp = minf(max_hp(),door_hp+Catalog.BUILDINGS.repair.rate*b.level*delta*repair_factor)
