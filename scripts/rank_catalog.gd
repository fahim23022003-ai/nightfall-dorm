class_name RankCatalog
extends RefCounted

# Original offline progression: small optional boosts, never a paid advantage.
const VERSION=1
const MAX_EQUIPPED=1
const MAX_XP=100000000
const NAMES=["Bronze","Silver","Gold","Platinum","Diamond","Master"]
const THRESHOLDS=[0,250,700,1400,2400,3800]
const COLORS=["B77A4A","BBCAD4","F4C542","75D5C7","70C8FF","B493F5"]
const PERKS=[
 {"id":"pocket","name":"Pocket change","description":"Start with 5 extra gold.","rank":0,"gold":5.0},
 {"id":"reinforced","name":"Reinforced frame","description":"Your door has 5% more maximum HP.","rank":1,"door":1.05},
 {"id":"dreamer","name":"Deep sleeper","description":"Your occupied bed earns 3% more gold.","rank":2,"income":1.03},
 {"id":"capacitor","name":"Clean current","description":"Your Dynamos produce 4% more power.","rank":3,"power":1.04},
 {"id":"marksman","name":"Steady aim","description":"Your turrets deal 3% more damage.","rank":4,"damage":1.03},
 {"id":"first_aid","name":"Last light","description":"Once below 25% HP: heal 10%.\nCannot revive a broken door.","rank":5,"rescue":0.1}
]
const DIFFICULTIES={
 "standard":{"name":"Night watch","hp":1.0,"damage":1.0,"speed":1.0,"xp":1.0},
 "hard":{"name":"Long night","hp":1.15,"damage":1.15,"speed":1.05,"xp":1.25}
}
const MIN_OCCUPIED_SECONDS=20.0
const DEFEAT_CAP=80
const VICTORY_BASE=120

static func rank_for(xp: int) -> int:
 var rank=0
 for i in range(THRESHOLDS.size()):
  if xp>=THRESHOLDS[i]: rank=i
 return rank

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
 var out={"gold":0.0,"door":1.0,"income":1.0,"power":1.0,"damage":1.0,"rescue":0.0}
 for id in equipped:
  var item=perk(id)
  for key in out:
   if item.has(key): out[key]=out[key]+item[key] if key=="gold" else item[key]
 return out

static func performance(model) -> Dictionary:
 var r=model.player()
 var eligible=model.result in ["victory","defeat"] and r!=null and r.occupied_seconds>=MIN_OCCUPIED_SECONDS and model.time>=model.preparation+10.0
 var result={"victory":0,"survival":0,"damage":0,"defense":0,"difficulty_bonus":0,"loss_adjustment":0,"ceiling_adjustment":0,"total":0,"eligible":eligible,"difficulty":model.difficulty}
 if not eligible: return result
 result.victory=VICTORY_BASE if model.result=="victory" else 0
 result.survival=mini(90,int(r.occupied_seconds/10.0)*3)
 result.damage=mini(100,int(r.damage_dealt/50.0))
 result.defense=mini(30,int(r.door_damage_taken/50.0)) if r.alive and r.door_hp>0 else 0
 var base=result.victory+result.survival+result.damage+result.defense
 result.difficulty_bonus=int(floor(base*(DIFFICULTIES.get(model.difficulty,DIFFICULTIES.standard).xp-1.0)))
 result.total=base+result.difficulty_bonus
 if model.result=="defeat":
  var partial=mini(DEFEAT_CAP,int(floor(result.total*0.35)))
  result.loss_adjustment=partial-result.total
  result.total=partial
 return result
