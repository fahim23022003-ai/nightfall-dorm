class_name Catalog
extends RefCounted

const BUILDING_REFUND_FRACTION = 0.5
const SURVIVOR_NAMES = ["You","Alex","Mia","Rowan","Kai","Nora"]
const PREPARATION = 30.0
const BED_INCOME = [2.0,4.0,8.0,15.0,26.0,40.0,58.0,80.0,105.0,135.0]
const BED_COST = [25,70,160,350,650,1000,1500,2200,3200]
const BED_POWER = [0,0,12,30,60,100,160,240,350]
const DOOR_HP = [150.0,300.0,600.0,1100.0,1800.0,2500.0,3300.0,4200.0,5200.0,6400.0]
const DOOR_COST = [30,85,190,400,700,1100,1650,2400,3400]
const DOOR_POWER = [0,0,10,30,60,100,160,240,350]
const BUILDINGS = {
 "turret": {"name":"Needle turret", "gold":20, "power":0, "damage":9.0, "range":240.0, "interval":0.9, "color":Color("63cdd2")},
 "heavy": {"name":"Arc turret", "gold":95, "power":12, "damage":28.0, "range":300.0, "interval":1.3, "color":Color("a78bfa")},
 "generator": {"name":"Dynamo", "gold":30, "power":0, "rate":1.5, "color":Color("e9ce67")},
 "repair": {"name":"Repair station", "gold":40, "power":5, "rate":7.0, "color":Color("7cdea0")},
 "economy": {"name":"Dream amplifier", "gold":45, "power":4, "rate":0.35, "color":Color("efab71")},
 "enhancer": {"name":"Target relay", "gold":65, "power":8, "rate":0.35, "color":Color("ee8fb2")},
 "flame":{"name":"Flame Turret","gold":75,"power":10,"damage":4.0,"range":190.0,"interval":1.35,"color":Color("f38345")},
 "frost":{"name":"Frost Tower","gold":80,"power":12,"damage":5.0,"range":220.0,"interval":1.4,"color":Color("80dce7")},
 "shock":{"name":"Shock Trap","gold":65,"power":10,"damage":24.0,"range":155.0,"interval":3.6,"color":Color("c0a3fa")},
 "auto_repair":{"name":"Auto Repair Station","gold":85,"power":12,"rate":3.0,"color":Color("9dd6ad")},
 "shield":{"name":"Shield Generator","gold":100,"power":18,"rate":1.0,"color":Color("7abbee")},
 "decoy":{"name":"Decoy Beacon","gold":70,"power":10,"rate":1.0,"color":Color("d198be")},
 "barrier":{"name":"Mirror Barrier","gold":90,"power":15,"rate":1.0,"color":Color("dbabef")},
 "plasma":{"name":"Plasma Capacitor","gold":100,"power":18,"rate":1.0,"color":Color("ed9dca")},
 "antenna":{"name":"Ward Antenna","gold":85,"power":14,"rate":1.0,"color":Color("8fdde5")}
}
const BOT_PROFILES = ["guard", "engineer", "economist", "gunner", "balanced"]

const HUNTER = {"hp":5000.0,"retarget_seconds":24.0,"door_weight":1.8,"growth_seconds":45.0,"hp_growth":100.0,"damage":22.0,"damage_growth":10.0,"interval":1.1,"interval_growth":0.04,"min_interval":0.45,"speed":80.0}
const REPAIR_COST = 12
const REPAIR_HEAL = 70.0
const BUILDING_MAX_LEVEL = 10
const AI_PROFILES = {
 "guard":{"priorities":["turret","generator","repair","economy","heavy","enhancer"],"bed_goal":2,"door_goal":3,"interval":1.1},
 "engineer":{"priorities":["generator","turret","repair","economy","enhancer","heavy"],"bed_goal":2,"door_goal":1,"interval":1.0},
 "economist":{"priorities":["economy","generator","turret","repair","heavy","enhancer"],"bed_goal":3,"door_goal":1,"interval":1.2},
 "gunner":{"priorities":["turret","generator","heavy","enhancer","economy","repair"],"bed_goal":1,"door_goal":1,"interval":0.9},
 "balanced":{"priorities":["turret","generator","economy","repair","heavy","enhancer"],"bed_goal":2,"door_goal":2,"interval":1.1}
}

# Real homing shots; original economy and turret attack intervals remain unchanged.
const PROJECTILES = {"turret":480.0,"heavy":360.0,"flame":340.0,"frost":370.0,"shock":600.0,"max_age":5.0,"max_active":256,"max_events":96,"event_lifetime":0.45}

# Preserve the first active phase; each later level ramps its stats over eight seconds.
const HUNTER_ESCALATION={"ramp_seconds":8.0,"speed_growth":1.5,"speed_bonus_cap":8.0,"dps_weight":2.0,"dps_penalty_cap":90.0,"repair_penalty_cap":35.0,"retarget_improvement":0.12,"minimum_commitment":8.0,"stuck_seconds":4.0}

# All six permanent machines support late tiers through10. Early prices stay
# unchanged; autonomous spending goals remain separately bounded in BotAI.
const DEFENSE_MAX_LEVEL=10
const PRESTIGE_COST_FACTORS=[5,7,10,14,19,25]
static func building_max_level(kind: String) -> int:
 return DEFENSE_MAX_LEVEL if BUILDINGS.has(kind) else 0
static func upgrade_cost(kind: String,level: int) -> Vector2:
 if not BUILDINGS.has(kind) or level<1 or level>=building_max_level(kind):return Vector2.ZERO
 var factor=float(level) if level<4 else float(PRESTIGE_COST_FACTORS[level-4])
 var data=BUILDINGS[kind]
 return Vector2(data.gold*factor,(data.power+3)*factor)
static func upgrade_requirement(kind: String,level: int,bed: int,door: int) -> String:
 if level>=building_max_level(kind):return "Building is at maximum level."
 if BUILDINGS.has(kind) and level>=4:
  var required=2 if level<7 else 3
  if bed<required or door<required:return "Prestige tier requires bed and door level %d." % (required+1)
 return ""
static func turret_damage(kind: String,level: int) -> float:
 return BUILDINGS[kind].damage*clampi(level,1,DEFENSE_MAX_LEVEL)
static func turret_interval(kind: String,level: int) -> float:
 return BUILDINGS[kind].interval/(1.0+(clampi(level,1,DEFENSE_MAX_LEVEL)-1)*0.12)

static func support_output(kind: String,level: int) -> float:
 var tier=float(clampi(level,1,10))
 if kind in ["economy","enhancer"]:tier=minf(4,tier)+maxf(0,tier-4)*.5
 return BUILDINGS[kind].rate*tier
