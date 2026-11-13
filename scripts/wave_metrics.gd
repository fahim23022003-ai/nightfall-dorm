class_name WaveMetrics
extends RefCounted
var data={"version":1,"available":true,"total":0.0,"allied":0.0,"door":0.0,"repair":0.0,"gold":0.0,"power":0.0,"activations":0,"skills":[],"buildings":{}}
func reset():data={"version":1,"available":true,"total":0.0,"allied":0.0,"door":0.0,"repair":0.0,"gold":0.0,"power":0.0,"activations":0,"skills":[],"buildings":{}}
func total(room: int,player: int,amount: float,target: int):
 if target!=1:return
 if room==player:data.total+=amount
 else:data.allied+=amount
func hit(room: int,player: int,id: int,kind: String,level: int,amount: float,target: int,impact=true):
 if room!=player or id<0 or target!=1 or amount<=0:return
 var key=str(id)
 if not data.buildings.has(key) and data.buildings.size()>=256:return
 if not data.buildings.has(key):data.buildings[key]={"id":id,"kind":kind,"level":level,"damage":0.0,"hits":0}
 var row=data.buildings[key];row.damage+=amount;row.level=maxi(int(row.level),level)
 if impact:row.hits+=1
func event(type: String,room: int,player: int,payload: Dictionary):
 if type in ["hunter_ability_warning","nightmare_warning","boss_ability_activate","archetype_warning"]:
  var skill=str(payload.get("ability",payload.get("action",payload.get("skill",payload.get("archetype",type)))))
  if skill not in data.skills and data.skills.size()<32:data.skills.append(skill)
 if room!=player:return
 if type=="door_damage":data.door+=payload.get("damage",0)
 if type in ["repair","healing","plasma_release"]:data.repair+=payload.get("amount",0)
 if type in ["defense_heal","item_rescue"]:data.repair+=payload.get("damage",0)
 if type in ["defense_activate","magic_shield","magic_reflect"]:data.activations+=1
 if type=="defense_item":data.activations+=1
func report() -> Dictionary:
 var result=data.duplicate(true);var top=data.buildings.values().duplicate(true);top.sort_custom(func(a,b):return a.damage>b.damage if a.damage!=b.damage else a.id<b.id)
 var attributed=0.0
 for row in top:attributed+=row.damage
 result.other=maxf(0,data.total-attributed);result.top=top.slice(0,6);return result
static func valid(d) -> bool:
 if not d is Dictionary or d.get("version")!=1 or not d.get("available") is bool:return false
 for key in ["total","allied","door","repair","gold","power"]:
  if not ReplaySnapshot.number(d.get(key)):return false
 if not ReplaySnapshot.whole(d.get("activations")) or not d.get("skills") is Array or d.skills.size()>32 or not d.get("buildings") is Dictionary or d.buildings.size()>256:return false
 for skill in d.skills:
  if not skill is String or skill.length()>100:return false
 var sum=0.0
 for key in d.buildings:
  var row=d.buildings[key]
  if not row is Dictionary or not ReplaySnapshot.whole(row.get("id"),0,SpatialConstruction.MAX_ID) or row.get("kind") not in DefenseEffects.WEAPONS or not ReplaySnapshot.whole(row.get("level"),1,10) or not ReplaySnapshot.number(row.get("damage")) or not ReplaySnapshot.whole(row.get("hits")):return false
  if str(int(row.id))!=str(key):return false
  sum+=row.damage
 return sum<=d.total+.001
