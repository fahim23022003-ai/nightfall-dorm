class_name RankCatalog
extends RefCounted

# Original offline progression: small optional boosts, never a paid advantage.
const VERSION=1
const MAX_EQUIPPED=2
const MAX_XP=100000000
const NAMES=["Bronze","Silver","Gold","Platinum","Diamond","Master","Mythic"]
const THRESHOLDS=[0,250,700,1400,2400,3800,8000]
const COLORS=["B77A4A","BBCAD4","F4C542","75D5C7","70C8FF","B493F5","E8BE61"]
const PERKS=[
 {"id":"pocket","name":"Pocket change","description":"Start with 5 extra gold.","rank":0,"gold":5.0},
 {"id":"reinforced","name":"Reinforced frame","description":"Your door has 5% more maximum HP.","rank":1,"door":1.05},
 {"id":"dreamer","name":"Deep sleeper","description":"Your occupied bed earns 3% more gold.","rank":2,"income":1.03},
 {"id":"capacitor","name":"Clean current","description":"Your Dynamos produce 4% more power.","rank":3,"power":1.04},
 {"id":"marksman","name":"Steady aim","description":"Your turrets deal 3% more damage.","rank":4,"damage":1.03},
 {"id":"first_aid","name":"Last light","description":"Once below 25% HP: heal 10%.\nCannot revive a broken door.","rank":5,"rescue":0.1},
 {"id":"reaper_slayer","name":"Reaper Slayer","description":"Your turret impacts deal 6% more damage to transformed Reaper.","rank":6,"reaper":1.06}
]
const DIFFICULTIES={
 "standard":{"name":"Normal","hp":1.0,"damage":1.0,"speed":1.0,"xp":1.0},
 "hard":{"name":"Long night","hp":1.15,"damage":1.3,"speed":1.08,"xp":1.25},
 "hell":{"name":"HELL MODE","hp":1.25,"damage":1.5,"speed":1.12,"xp":1.5}
}
# Separate behavior tuning; Normal preserves the original opening and economy.
const PRESSURE={
 "standard":{"opening":45.0,"growth_seconds":45.0,"damage_growth":10.0,"interval_scale":1.0,"commit":24.0,"door_weight":1.8,"repair_floor":1.0,"siege_ramp":16.0,"charged_every":0,"charged_scale":1.0,"windup":0.0},
 "hard":{"opening":45.0,"growth_seconds":32.0,"damage_growth":14.0,"interval_scale":0.94,"commit":16.0,"door_weight":0.35,"repair_floor":0.65,"siege_ramp":16.0,"charged_every":4,"charged_scale":1.65,"windup":0.75},
 "hell":{"opening":45.0,"growth_seconds":25.0,"damage_growth":18.0,"interval_scale":0.88,"commit":12.0,"door_weight":0.18,"repair_floor":0.4,"siege_ramp":12.0,"charged_every":3,"charged_scale":1.9,"windup":0.9}
}
static func pressure(mode: String) -> Dictionary:
 return PRESSURE.get(mode,PRESSURE.standard)
const MIN_OCCUPIED_SECONDS=20.0
const DEFEAT_CAP=30
const MYTHIC={"xp":8000,"advanced_wins":3,"reaper_defeats":3,"stage":"stage_5"}
const STAGE_XP=10
const REAPER_XP=40
const VICTORY_BASE=120

static func rank_for(xp: int) -> int:
 var rank=0
 for i in range(THRESHOLDS.size()):
  if xp>=THRESHOLDS[i]: rank=i
 return rank

static func mythic_ready(stats: Dictionary,records: Dictionary) -> bool:
 return int(stats.get("hard",0))+int(stats.get("hell",0))>=MYTHIC.advanced_wins and int(stats.get("reaper_defeats",0))>=MYTHIC.reaper_defeats and records.has(MYTHIC.stage)

static func perk(id: String) -> Dictionary:
 for item in PERKS:
  if item.id==id: return item
 return {}

static func unlocked(xp: int) -> Array:
 var out=[]
 for item in PERKS:
  if item.rank<=rank_for(xp): out.append(item.id)
 return out

static func bonuses(equipped: Array) -> Dictionary:
 var out={"gold":0.0,"door":1.0,"income":1.0,"power":1.0,"damage":1.0,"rescue":0.0,"reaper":1.0}
 for id in equipped:
  var item=perk(id)
  for key in out:
   if item.has(key): out[key]=out[key]+item[key] if key=="gold" else item[key]
 return out

static func performance(model) -> Dictionary:
 var r=model.player()
 var eligible=model.result in ["victory","defeat"] and r!=null and r.occupied_seconds>=MIN_OCCUPIED_SECONDS and model.time>=model.preparation+10.0
 var result={"victory":0,"survival":0,"damage":0,"defense":0,"difficulty_bonus":0,"loss_adjustment":0,"ceiling_adjustment":0,"total":0,"eligible":eligible,"difficulty":model.difficulty,"stage_bonus":0,"reaper_bonus":0}
 if not eligible: return result
 result.victory=VICTORY_BASE if model.result=="victory" else 0
 result.survival=mini(90,int(r.occupied_seconds/10.0)*3)
 result.damage=mini(100,int(r.damage_dealt/50.0))
 result.defense=mini(30,int(r.door_damage_taken/50.0)) if r.alive and r.door_hp>0 else 0
 if model.result=="victory" and model.hunter.hp<=0:
  result.stage_bonus=maxi(0,StageCatalog.index_of(model.stage_id)+1)*STAGE_XP
  result.reaper_bonus=REAPER_XP if model.hunter.transformed else 0
 var base=result.stage_bonus+result.reaper_bonus+result.victory+result.survival+result.damage+result.defense
 result.difficulty_bonus=int(floor(base*(DIFFICULTIES.get(model.difficulty,DIFFICULTIES.standard).xp-1.0)))
 result.total=base+result.difficulty_bonus
 if model.result=="defeat":
  var partial=mini(mini(DEFEAT_CAP,int(r.occupied_seconds/30.0)),int(floor((result.survival+result.damage+result.defense)*0.2)))
  result.difficulty_bonus=0
  result.loss_adjustment=partial-base
  result.total=partial
 return result
