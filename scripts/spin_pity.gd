class_name SpinPity
extends RefCounted
const EPIC_LIMIT=8
const LEGENDARY_LIMIT=40
static func weights(result: String,pity: Dictionary) -> Array:
 var out=ItemCatalog.TABLES.get(result,ItemCatalog.TABLES.defeat).duplicate()
 if result!="victory":return out
 var legendary=int(pity.get("legendary_dry",0))>=LEGENDARY_LIMIT-1
 var epic=int(pity.get("epic_dry",0))>=EPIC_LIMIT-1
 for i in range(out.size()):
  var rarity=ItemCatalog.ITEMS[ItemCatalog.IDS[i]].rarity
  if legendary and rarity!="Legendary":out[i]=0
  elif epic and rarity not in ["Epic","Legendary"]:out[i]=0
 return out
static func odds(result: String,pity: Dictionary) -> Dictionary:
 var out={"Common":0.0,"Rare":0.0,"Epic":0.0,"Legendary":0.0}
 var table=weights(result,pity);var total=0.0
 for weight in table:total+=weight
 for i in range(table.size()):out[ItemCatalog.ITEMS[ItemCatalog.IDS[i]].rarity]+=100.0*table[i]/total
 return out
static func summary(result: String,pity: Dictionary) -> String:
 var d=odds(result,pity)
 return "Common %.0f%% · Rare %.0f%% · Epic %.0f%% · Legendary %.0f%%" % [d.Common,d.Rare,d.Epic,d.Legendary]
static func roll(result: String,rng: RandomNumberGenerator,pity: Dictionary) -> String:
 var table=weights(result,pity);var total=0
 for weight in table:total+=int(weight)
 var value=rng.randi_range(1,total);var item=ItemCatalog.IDS[0]
 for i in range(table.size()):
  value-=int(table[i])
  if value<=0:item=ItemCatalog.IDS[i];break
 if result=="victory":
  var rarity=ItemCatalog.ITEMS[item].rarity
  pity.epic_dry=0 if rarity in ["Epic","Legendary"] else mini(EPIC_LIMIT-1,int(pity.get("epic_dry",0))+1)
  pity.legendary_dry=0 if rarity=="Legendary" else mini(LEGENDARY_LIMIT-1,int(pity.get("legendary_dry",0))+1)
 return item
