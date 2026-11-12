class_name StrategyCatalog
extends RefCounted

const ARCHETYPE_IDS=["crusher","stalker","ravager"]
const ARCHETYPES={
 "crusher":{"name":"The Crusher","hp":1.15,"damage":1.2,"speed":.82,"windup":.65,"commit":1.4,"hint":"Heavy door blows, slow approach. Build concentrated fire; repair after its deliberate wind-up.","color":"C8A277"},
 "stalker":{"name":"The Stalker","hp":.92,"damage":.82,"speed":1.08,"windup":.55,"commit":.9,"hint":"Seeks isolated defenses; warns before its first strike. Cover exposed doors with ranged turrets.","color":"A39AC8"},
 "ravager":{"name":"The Ravager","hp":.88,"damage":.85,"speed":1.18,"windup":.3,"commit":.7,"hint":"Fast pressure, fragile body. Three strikes then a recovery window; invest in rapid fire.","color":"CA7872"}}
const BRANCHES={
 "lucid":{"kind":"bed","name":"Lucid Dividend","income":1.25,"power":.9,"description":"25% more occupied bed income; generators produce 10% less electricity."},
 "conductor":{"kind":"bed","name":"Dream Conductor","income":.85,"power_rate":.04,"description":"15% less bed income; occupied bed converts 4% base income into Electricity/s."},
 "bulwark":{"kind":"door","name":"Cursed Bulwark","hp":1.2,"mitigation":.9,"repair":.8,"description":"20% more durability and10% mitigation; manual repairs20% weaker."},
 "renewal":{"kind":"door","name":"Living Threshold","hp":.9,"mitigation":1.0,"repair":1.5,"description":"50% stronger manual repairs; maximum durability10% lower."},
 "regulated":{"kind":"generator","name":"Regulated Core","output":1.2,"income":.95,"description":"20% more power; occupied bed income 5% lower while installed."},
 "overcharge":{"kind":"generator","name":"Overcharge","output":1.6,"income":.8,"description":"60% more power; occupied bed income 20% lower while installed. Penalties bounded."},
 "sustain":{"kind":"repair","name":"Powered Sutures","output":1.35,"power_cost":.25,"description":"35% more healing; consumes 0.25E per level/s and stops without power."},
 "conservation":{"kind":"repair","name":"Careful Restoration","output":.8,"repair_cost":.75,"description":"20% weaker station healing; manual repair Gold cost 25% lower (total discount capped 40%)."},
 "dividend":{"kind":"economy","name":"Golden Reverie","output":1.3,"power":.85,"description":"30% stronger amplifier bonus; generators produce 15% less power."},
 "capacitive":{"kind":"economy","name":"Conductive Dream","output":.8,"power":1.3,"description":"20% weaker income bonus; 30% greater generator output (room cap 50%)."},
 "ballistic":{"kind":"enhancer","name":"Focused Relay","output":1.2,"range":.9,"description":"20% stronger additive damage bonus; all room turret ranges 10% shorter."},
 "coolant":{"kind":"enhancer","name":"Cooling Relay","output":.75,"interval":.9,"description":"25% weaker damage bonus; room turrets fire 10% faster (total rate benefit capped 20%)."},
 "precision":{"kind":"turret","name":"Heavy Precision","damage":1.55,"interval":1.4,"range":.85,"speed":1.0,"slow":0.0,"description":"+55% hit damage / 40% longer interval / 15% shorter range (204px). Concentrated shots; placement matters."},
 "suppression":{"kind":"turret","name":"Suppression","damage":.8,"interval":.82,"range":1.0,"speed":1.0,"slow":.15,"description":"20% weaker hits / 18% shorter interval. Hits slow movement 15% for 1s; Reaper 7.5%."},
 "focus":{"kind":"heavy","name":"Focused Discharge","damage":1.5,"interval":1.35,"range":1.0,"speed":1.0,"slow":0.0,"description":"50% stronger hits / 35% longer interval. Powerful single-target bursts."},
 "storm":{"kind":"heavy","name":"Storm Coil","damage":.72,"interval":.72,"range":1.2,"speed":1.25,"slow":0.0,"description":"28% weaker hits / 28% shorter interval. 20% more range; 25% faster projectiles."},
 "searing":{"kind":"flame","name":"Searing Lance","damage":1.35,"interval":1.0,"range":1.0,"speed":1.0,"slow":0.0,"description":"45% stronger burn and35% stronger contact damage, but only one target."},
 "wildfire":{"kind":"flame","name":"Wildfire Fan","damage":.72,"interval":1.0,"range":1.0,"speed":1.0,"slow":0.0,"description":"Hits up to three nearby targets; each hit28% weaker and burn35% weaker."},
 "deep_chill":{"kind":"frost","name":"Deep Chill","damage":1.15,"interval":1.0,"range":1.0,"speed":1.0,"slow":.3,"description":"15% stronger hits, one target. Hunter movement -15%, attack interval +30%; Reaper movement -7.5%, interval +15%; undead movement -30%."},
 "rime_field":{"kind":"frost","name":"Rime Field","damage":.65,"interval":1.0,"range":1.0,"speed":1.0,"slow":.16,"description":"Three targets;35% weaker hits. Hunter movement -15%, attack interval +16%; Reaper movement -7.5%, interval +8%; undead movement -16%."},
 "capacitor_burst":{"kind":"shock","name":"Capacitor Burst","damage":1.5,"interval":1.25,"range":1.0,"speed":1.0,"slow":.15,"description":"50% stronger charged impact; recharge25% longer. Brief slow, never a stun."},
 "rapid_discharge":{"kind":"shock","name":"Rapid Discharge","damage":.65,"interval":.667,"range":1.0,"speed":1.0,"slow":.15,"description":"One-third shorter recharge;35% weaker hit. Cannot stun-lock the Hunter."},
 "efficient_mending":{"kind":"auto_repair","name":"Efficient Mending","description":"Same steady repairs for30% less operating Gold. Paid Electricity still required."},
 "emergency_protocol":{"kind":"auto_repair","name":"Emergency Protocol","description":"80% stronger burst only below45% door HP; slower5s cycle,60% more Gold and50% more Electricity."},
 "aegis_burst":{"kind":"shield","name":"Aegis Burst","description":"50% more absorption for2s;25% more operating Electricity. Room refractory remains12s."},
 "steady_veil":{"kind":"shield","name":"Steady Veil","description":"35% weaker absorption for4s;20% less operating Electricity. No overlapping barriers."},
 "force_lure":{"kind":"decoy","name":"Force Lure","description":"Lures from240px for3s; requires paid Electricity and legal navigation."},
 "faint_echo":{"kind":"decoy","name":"Faint Echo","description":"Longer4s lure but shorter160px reach. Reaper duration halved; shared24s cooldown."}}
const BRANCH_FEE=Vector2(25,4)
const TRAIT_IDS=["fortified","power","economy"]
const TRAITS={
 "fortified":{"name":"Fortified","icon":"fortified","door":1.15,"income":.9,"power":1.0,"benefit":"+15% door durability","drawback":"-10% bed income"},
 "power":{"name":"Power Conduit","icon":"power","door":.9,"income":1.0,"power":1.2,"benefit":"+20% Dynamo electricity","drawback":"-10% door durability"},
 "economy":{"name":"Prosperous","icon":"gold","door":1.0,"income":1.15,"power":.9,"benefit":"+15% bed income","drawback":"-10% Dynamo electricity"}}
const CONTRACTS={
 "no_legendary":{"name":"No Legendary Help","objective":"Win without triggering any Legendary consumable.","cash":8},
 "limited_defense":{"name":"Limited Defense","objective":"Win without ever owning more than TWO offensive turrets at once.","cash":10},
 "iron_survivor":{"name":"Iron Survivor","objective":"Win without using manual door repair. Stations, upgrades and items remain valid.","cash":8}}
static func choose_archetype(ordinal: int,stage: String,mode: String) -> String:
 # No gameplay/reward RNG consumption; aborts and reloads retain the same encounter.
 return ARCHETYPE_IDS[posmod(ordinal+StageCatalog.index_of(stage)*2+["standard","hard","hell"].find(mode),3)]
static func trait_for(room_index: int,map: String) -> String:
 return TRAIT_IDS[posmod(room_index+MapCatalog.IDS.find(map),3)]
static func branches(kind: String) -> Array:
 var result=[]
 for id in BRANCHES:
  if BRANCHES[id].kind==kind:result.append(id)
 return result
static func weapon(building: Dictionary) -> Dictionary:
 var d={"damage":1.0,"interval":1.0,"range":1.0,"speed":1.0,"slow":0.0}
 var id=str(building.get("specialization",""))
 if building.kind in DefenseEffects.WEAPONS and BRANCHES.has(id) and BRANCHES[id].kind==building.kind:return BRANCHES[id]
 return d
static func claim_key(stage: String,mode: String,contract: String) -> String:
 return stage+":"+mode+":"+contract

static func support(building: Dictionary) -> Dictionary:
 var id=str(building.get("specialization",""))
 return BRANCHES[id] if building.kind in ["generator","repair","economy","enhancer"] and id in BRANCHES and BRANCHES[id].kind==building.kind else {}
