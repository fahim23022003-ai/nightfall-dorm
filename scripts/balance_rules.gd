class_name BalanceRules
extends RefCounted
# Immutable run version. Version1 remains the complete legacy continuation path.
const CURRENT=2
const START_GOLD=25.0
const PREPARATION=40.0
const AMP_BUDGET=2.0
const AMPLIFIER_LIMIT=3
const REPAIR_UPKEEP=.35
const MERCHANT_GOLD={"repair":65,"shield":85,"frost":85,"barricade":85}
const MERCHANT_POWER={"repair":3,"pillow":3,"shield":6,"frost":6,"barricade":6}
const DISCIPLINE_MAX=80.0
const BED=[1.5,3.0,6.0,10.0,17.0,27.0,40.0,58.0,80.0,105.0]
const BED_G=[30,85,200,450,900,1700,3000,4800,7200]
const BED_E=[0,0,15,40,85,160,280,440,650]
const DOOR_G=[35,100,240,500,950,1700,2800,4400,6500]
const DOOR_E=[0,0,10,30,65,120,210,340,520]
const DYNAMO=[.6,1.05,1.7,2.6,3.8,5.2,6.8,8.6,10.6,13.0]
const FACTORS=[2.0,3.5,6.0,10.0,16.0,24.0,35.0,50.0,70.0]
static func price(kind: String,version: int=1) -> Vector2:
 var d=Catalog.BUILDINGS[kind]
 if version==1:return Vector2(d.gold,d.power)
 if kind=="turret":return Vector2(20,0)
 if kind=="generator":return Vector2(120,0)
 if kind=="economy":return Vector2(120,60)
 if kind=="enhancer":return Vector2(100,25)
 if kind=="repair":return Vector2(65,12)
 return Vector2(ceil(d.gold*1.2),ceil(d.power*1.5))
static func upgrade(kind: String,level: int,version: int=1) -> Vector2:
 if version==1:return Catalog.upgrade_cost(kind,level)
 if level<1 or level>=10:return Vector2.ZERO
 var base=price(kind,version)
 return Vector2(base.x*FACTORS[level-1]*(.3 if kind=="economy" else 1.0),maxf(4,base.y*.5+4)*FACTORS[level-1]*(.4 if kind=="economy" else 1.0))
static func structure(kind: String,level: int,version: int=1) -> Vector2:
 if level<0 or level>=9:return Vector2.ZERO
 if kind=="bed":return Vector2(BED_G[level],BED_E[level]) if version==2 else Vector2(Catalog.BED_COST[level],Catalog.BED_POWER[level])
 return Vector2(DOOR_G[level],DOOR_E[level]) if version==2 else Vector2(Catalog.DOOR_COST[level],Catalog.DOOR_POWER[level])
static func income(level: int,version: int=1) -> float:return BED[level] if version==2 else Catalog.BED_INCOME[level]
static func output(kind: String,level: int,version: int=1) -> float:
 if version==1:return Catalog.support_output(kind,level)
 if kind=="generator":return DYNAMO[clampi(level,1,10)-1]
 if kind=="economy":return .12+.09*(clampi(level,1,10)-1)
 return Catalog.support_output(kind,level)
static func requirement(kind: String,level: int,bed: int,door: int,version: int=1) -> String:
 if version==1:return Catalog.upgrade_requirement(kind,level,bed,door)
 if level>=10:return "Maximum level10."
 var required=maxi(0,level-1) # upgrading to L10 requires Bed/Door L9, then their own linked ladders.
 if bed<required or door<required:return "Requires Bed and Door level %d." % (required+1)
 return ""
static func build_requirement(kind: String,room) -> String:
 if room.balance_version==2 and kind=="economy" and room.buildings.values().filter(func(b):return b.kind=="economy").size()>=AMPLIFIER_LIMIT:return "Room amplifier budget:3 machines. Existing units can still be upgraded; returns diminish."
 if kind=="heavy" and room.bed_level<1:return "Arc turret requires Bed level2."
 if room.balance_version==2 and kind in ["economy","enhancer"] and not room.buildings.values().any(func(b):return b.kind=="generator"):return "Requires an owned Dynamo; Electricity is infrastructure."
 return ""
static func amplifier(raw: float,version: int=1) -> float:return 1.0+AMP_BUDGET*raw/(AMP_BUDGET+raw) if version==2 else 1.0+raw
static func expansion(tier: int,version: int=1) -> Vector2:return RoomExpansion.COSTS[tier]*(1.0+.18*maxi(0,tier-1)) if version==2 else RoomExpansion.COSTS[tier]
static func title(version: int) -> String:return "EARNED POWER · v2" if version==2 else "LEGACY · v1 economy retained"

static func merchant_price(room,id: String) -> Vector2:
 var gold=ceil(clampf(room.income_rate()*8,20,4000)) if id=="pillow" else float(MERCHANT_GOLD[id])+room.bed_level*12
 return Vector2(gold,MERCHANT_POWER[id])
