class_name BuildingStats
extends RefCounted
# The same resolver supplies actual launch stats and read-only UI previews.
static func room_copy(room):
 var copy=RoomState.new(room.index)
 for key in ["layout","owner","alive","sleeping","closed","gold","electricity","bed_level","door_level","bed_branch","door_branch","door_hp","income_multiplier","power_multiplier","door_multiplier","turret_multiplier","trait_modifiers","trait_id","temporary_income","repair_factor","strategy_enabled","threat_income_factor","threat_power_factor","production_paused"]:
  var value=room.get(key);copy.set(key,value.duplicate(true) if value is Dictionary or value is Array else value)
 copy.buildings=room.buildings.duplicate(true)
 return copy
static func weapon_stats(model,room,b: Dictionary) -> Dictionary:
 var data=Catalog.BUILDINGS[b.kind];var branch=StrategyCatalog.weapon(b)
 if b.kind in ["flame","frost","shock"]:
  var special=DefenseEffects.new().stats(room,b);var relay=1.0
  for support in room.buildings.values():
   if support.kind=="enhancer":relay+=Catalog.support_output("enhancer",support.level)*StrategyCatalog.support(support).get("output",1.0)
  special.damage*=relay*room.turret_multiplier
  special.interval*=room.special_factor("interval",.8,1.0);special.range*=room.special_factor("range",.8,1.0)
  special.burn=float(special.get("burn",0.0))*relay*room.turret_multiplier
  special.hit=special.damage
  if model!=null:
   if model.hunter.conceal_remaining>0:special.range*=.8
   if room.owner==0:
    if float(model.items.timers.get("overdrive",0))>0:special.interval/=ItemCatalog.TUNING.overdrive_rate
    if model.hunter.transformed:special.hit*=model.match_boosts.get("reaper",1.0)
    if model.time<model.preparation+model.stage_bonus.get("seconds",0.0):special.hit*=model.stage_bonus.get("damage",1.0)
  special.dps=special.hit/special.interval;special.projectile_speed=Catalog.PROJECTILES[b.kind]
  return special
 var relay=1.0
 for support in room.buildings.values():
  if support.kind=="enhancer":relay+=Catalog.support_output("enhancer",support.level)*StrategyCatalog.support(support).get("output",1.0)
 var damage=Catalog.turret_damage(b.kind,b.level)*relay*room.turret_multiplier*branch.damage
 var interval=Catalog.turret_interval(b.kind,b.level)*branch.interval*room.special_factor("interval",.8,1.0)
 var range_value=data.range*branch.range*room.special_factor("range",.8,1.0)
 var hit=damage
 if model!=null:
  if model.hunter.conceal_remaining>0:range_value*=.8
  if room.owner==0:
   if float(model.items.timers.get("overdrive",0))>0:interval/=ItemCatalog.TUNING.overdrive_rate
   if model.hunter.transformed:hit*=model.match_boosts.get("reaper",1.0)
   if model.time<model.preparation+model.stage_bonus.get("seconds",0.0):hit*=model.stage_bonus.get("damage",1.0)
 return {"damage":damage,"hit":hit,"interval":interval,"dps":hit/maxf(.01,interval),"range":range_value,"projectile_speed":Catalog.PROJECTILES[b.kind]*branch.speed,"slow":branch.slow}
static func machine_stats(model,room,b: Dictionary) -> Dictionary:
 if b.kind in MagicDefense.KINDS:return MagicDefense.stats(b)
 if b.kind in DefenseEffects.WEAPONS:return weapon_stats(model,room,b)
 if b.kind in ["auto_repair","shield","decoy"]:
  var special=DefenseEffects.new().stats(room,b)
  if b.kind=="auto_repair":special.heal*=maxf(.65,room.repair_factor)
  return special
 var branch=StrategyCatalog.support(b);var rate=Catalog.support_output(b.kind,b.level)*branch.get("output",1.0)
 if b.kind=="generator":rate*=(0.0 if room.production_paused else room.threat_power_factor)*room.power_multiplier*room.trait_modifiers.power*room.special_factor("power",.55,1.5)*StrategyCatalog.BRANCHES.get(room.bed_branch,{}).get("power",1.0)
 if b.kind=="repair":rate*=room.repair_factor
 return {"rate":rate,"operating_power":branch.get("power_cost",0.0)*b.level,"income":room.income_rate(),"repair_gold":room.manual_repair_cost()}
static func frost_status(strength: float) -> Dictionary:
 # Match the existing actor-specific status application; preview does not alter it.
 var move=minf(.15,strength)
 return {"hunter_move":move,"hunter_interval":strength,"reaper_move":move*.5,"reaper_interval":strength*.5,"undead_move":minf(.35,strength)}
static func format_machine(model,room,b: Dictionary) -> String:
 var stats=machine_stats(model,room,b)
 if b.kind=="barrier":return "Reflect %.0f%% eligible Magic damage / %.1fs; Physical unaffected.\nReflection never blocks the original hit; no recursion." % [stats.reflect*100,stats.interval]
 if b.kind=="plasma":return "Absorb %.0f%% Magic; storage %.0f / %.0fs.\nConvert %.0f%% stored energy to door HP every3s; no Electricity gain." % [stats.absorb*100,stats.capacity,stats.expiry,stats.heal*100]
 if b.kind=="antenna":return "Magic shield %.0f HP / %.0fs recharge; cost %.1f E.\nHighest-level antenna only; Physical bypasses this shield." % [stats.capacity,stats.interval,stats.power]
 if b.kind=="auto_repair":return "Repair %.1f HP / %.1fs below %.0f%% HP\nUpkeep %.2f Gold + %.2f Electricity per burst" % [stats.heal,stats.interval,stats.threshold*100,stats.gold,stats.power]
 if b.kind=="shield":return "Barrier %.1f HP for %.1fs · room cooldown %.1fs\nUpkeep %.2f Electricity per activation" % [stats.capacity,stats.duration,stats.interval,stats.power]
 if b.kind=="decoy":return "Lure %.1fs · range %.0f · cooldown %.1fs\nUpkeep %.2f Electricity; Reaper duration halved" % [stats.duration,stats.range,stats.interval,stats.power]
 if b.kind=="flame":return "Hit %.1f · %.2fs / shot · range %.0f\nBurn %.1f HP/s for3s (strongest only) · targets %d" % [stats.hit,stats.interval,stats.range,stats.burn,stats.targets]
 if b.kind=="frost":
  var slow=frost_status(stats.slow)
  return "Hit %.1f · %.2fs / shot · range %.0f · targets %d · Undead move -%.0f%%\nHunter move -%.0f%% / attack interval +%.0f%%; Reaper move -%.1f%% / interval +%.0f%%" % [stats.hit,stats.interval,stats.range,stats.targets,slow.undead_move*100,slow.hunter_move*100,slow.hunter_interval*100,slow.reaper_move*100,slow.reaper_interval*100]
 if b.kind in DefenseEffects.WEAPONS:return "Hit %.1f · %.2fs / shot · %.1f DPS\nRange %.0f · projectile %.0f /s" % [stats.hit,stats.interval,stats.dps,stats.range,stats.projectile_speed]
 if b.kind=="generator":return "Output %.2f Electricity/s\nRoom income %.2f Gold/s" % [stats.rate,stats.income]
 if b.kind=="repair":return "Healing %.2f HP/s · upkeep %.2f E/s\nManual repair %.2f Gold" % [stats.rate,stats.operating_power,stats.repair_gold]
 return "Additive %s bonus +%.1f%%\nRoom income %.2f Gold/s" % ["income" if b.kind=="economy" else "turret hit",stats.rate*100,stats.income]
static func room_power_rate(model,room) -> float:
 if room.production_paused:return 0.0
 var rate=room.threat_power_factor*Catalog.BED_INCOME[room.bed_level]*StrategyCatalog.BRANCHES.get(room.bed_branch,{}).get("power_rate",0.0)
 for b in room.buildings.values():
  if b.kind=="generator":rate+=machine_stats(model,room,b).rate
 return rate if room.alive and room.sleeping else 0.0
static func branch_preview(model,room,b: Dictionary,id: String,structure: String="") -> String:
 var clone=room_copy(room)
 if structure!="":
  if structure=="bed":
   var old=room.income_rate();clone.bed_branch=id;clone.bed_level+=1
   return "Gold %.2f → %.2f /s · Electricity %.2f → %.2f /s\n%s" % [old,clone.income_rate(),room_power_rate(model,room),room_power_rate(model,clone),StrategyCatalog.BRANCHES[id].description]
  var old=room.max_hp();clone.door_branch=id;clone.door_level+=1
  var repair=Catalog.REPAIR_HEAL*clone.repair_factor*StrategyCatalog.BRANCHES[id].get("repair",1.0)
  return "HP %.0f → %.0f · mitigation %.0f%% → %.0f%%\nManual repair %.1f → %.1f HP\n%s" % [old,clone.max_hp(),100*(1-StrategyCatalog.BRANCHES.get(room.door_branch,{}).get("mitigation",1.0)),100*(1-StrategyCatalog.BRANCHES[id].get("mitigation",1.0)),Catalog.REPAIR_HEAL*room.repair_factor*StrategyCatalog.BRANCHES.get(room.door_branch,{}).get("repair",1.0),repair,StrategyCatalog.BRANCHES[id].description]
 var tile=-1
 for index in room.buildings:
  if room.buildings[index]==b:tile=index;break
 if tile<0:return "Select an actual owned machine."
 clone.buildings[tile].level=int(b.level)+1;clone.buildings[tile].specialization=id
 var before=machine_stats(model,room,b);var after=machine_stats(model,clone,clone.buildings[tile])
 if b.kind=="barrier":return "Reflection %.1f%% → %.1f%% · cooldown %.1f → %.1fs\nOriginal Magic hit remains; Physical bypasses reflection.\n%s" % [before.reflect*100,after.reflect*100,before.interval,after.interval,StrategyCatalog.BRANCHES[id].description]
 if b.kind=="plasma":return "Absorb %.0f%% → %.0f%% · storage %.0f → %.0f\nExpiry %.0f → %.0fs · healing conversion %.0f%% → %.0f%%\n%s" % [before.absorb*100,after.absorb*100,before.capacity,after.capacity,before.expiry,after.expiry,before.heal*100,after.heal*100,StrategyCatalog.BRANCHES[id].description]
 if b.kind=="antenna":return "Magic durability %.0f → %.0f · recharge %.0f → %.0fs\nElectricity %.1f → %.1f / refill; Physical bypasses this shield.\n%s" % [before.capacity,after.capacity,before.interval,after.interval,before.power,after.power,StrategyCatalog.BRANCHES[id].description]
 if b.kind=="auto_repair":return "Repair %.1f → %.1f HP / %.1f → %.1fs\nUpkeep %.1fG %.1fE → %.1fG %.1fE / burst\n%s" % [before.heal,after.heal,before.interval,after.interval,before.gold,before.power,after.gold,after.power,StrategyCatalog.BRANCHES[id].description]
 if b.kind=="shield":return "Barrier %.0f → %.0f HP · %.1f → %.1fs\nElectricity %.1f → %.1f / activation · 12s room cooldown\n%s" % [before.capacity,after.capacity,before.duration,after.duration,before.power,after.power,StrategyCatalog.BRANCHES[id].description]
 if b.kind=="decoy":return "Lure %.1f → %.1fs · range %.0f → %.0f\nElectricity %.1f → %.1f · cooldown %.1f → %.1fs\n%s" % [before.duration,after.duration,before.range,after.range,before.power,after.power,before.interval,after.interval,StrategyCatalog.BRANCHES[id].description]
 if b.kind=="flame":return "Hit %.1f → %.1f · burn %.1f → %.1f HP/s\nTargets %d → %d · interval %.2f → %.2fs\n%s" % [before.hit,after.hit,before.burn,after.burn,before.targets,after.targets,before.interval,after.interval,StrategyCatalog.BRANCHES[id].description]
 if b.kind=="frost":
  var prior=frost_status(before.slow);var next=frost_status(after.slow)
  return "Hit %.1f → %.1f · targets %d → %d · undead move -%.0f%% → -%.0f%%\nHunter move -%.0f%% → -%.0f%% / interval +%.0f%% → +%.0f%% (Reaper half)\n%s" % [before.hit,after.hit,before.targets,after.targets,prior.undead_move*100,next.undead_move*100,prior.hunter_move*100,next.hunter_move*100,prior.hunter_interval*100,next.hunter_interval*100,StrategyCatalog.BRANCHES[id].description]
 if b.kind in DefenseEffects.WEAPONS:
  return "Hit %.1f → %.1f · DPS %.1f → %.1f\nRate %.2fs → %.2fs · range %.0f → %.0f\n%s" % [before.hit,after.hit,before.dps,after.dps,before.interval,after.interval,before.range,after.range,StrategyCatalog.BRANCHES[id].description]
 if b.kind=="generator":return "Electricity %.2f → %.2f /s · Gold %.2f → %.2f /s\n%s" % [before.rate,after.rate,before.income,after.income,StrategyCatalog.BRANCHES[id].description]
 if b.kind=="repair":return "Healing %.2f → %.2f HP/s · upkeep %.2f → %.2f E/s\nRepair cost %.2f → %.2f Gold\n%s" % [before.rate,after.rate,before.operating_power,after.operating_power,before.repair_gold,after.repair_gold,StrategyCatalog.BRANCHES[id].description]
 if b.kind=="enhancer":return "Hit bonus +%.1f%% → +%.1f%%\nRoom range %.2fx → %.2fx · interval %.2fx → %.2fx\n%s" % [before.rate*100,after.rate*100,room.special_factor("range",.8,1.0),clone.special_factor("range",.8,1.0),room.special_factor("interval",.8,1.0),clone.special_factor("interval",.8,1.0),StrategyCatalog.BRANCHES[id].description]
 return "Bonus +%.1f%% → +%.1f%% · Gold %.2f → %.2f /s\n%s" % [before.rate*100,after.rate*100,before.income,after.income,StrategyCatalog.BRANCHES[id].description]
static func next_machine(model,room,tile: int) -> String:
 var b=room.buildings[tile]
 var current=format_machine(model,room,b)
 var branch_name=StrategyCatalog.BRANCHES.get(b.get("specialization",""),{}).get("name","Unmodified")
 var heading="LEVEL %d · %s" % [b.level,branch_name]
 if b.level>=10:return heading+" · MAX\n"+current
 if b.level==4 and b.get("specialization","")=="":return heading+"\n"+current+"\nChoose and confirm one exclusive specialization."
 var clone=room_copy(room);clone.buildings[tile].level+=1
 return heading+" · CURRENT\n"+current+"\nNEXT LEVEL %d\n" % (b.level+1)+format_machine(model,clone,clone.buildings[tile])

static func structure_preview(model,room,kind: String) -> String:
 var level=room.bed_level if kind=="bed" else room.door_level
 var branch=room.bed_branch if kind=="bed" else room.door_branch
 var name=StrategyCatalog.BRANCHES.get(branch,{}).get("name","Unmodified")
 var clone=room_copy(room)
 if kind=="bed":
  clone.bed_level=mini(9,level+1)
  return "LEVEL %d · %s\nCurrent %.2f Gold/s · %.2f Electricity/s\n%s" % [level+1,name,room.income_rate(),room_power_rate(model,room),"MAXIMUM LEVEL10" if level>=9 else "Next tier %.2f Gold/s · %.2f Electricity/s%s" % [clone.income_rate(),room_power_rate(model,clone)," (before branch choice)" if level==4 and branch=="" else ""]]
 clone.door_level=mini(9,level+1)
 return "LEVEL %d · %s\nHP %.1f / %.1f · mitigation %.0f%%\nManual repair %.1f HP for %.2f Gold\n%s" % [level+1,name,room.door_hp,room.max_hp(),100*(1-StrategyCatalog.BRANCHES.get(branch,{}).get("mitigation",1.0)),Catalog.REPAIR_HEAL*room.repair_factor*StrategyCatalog.BRANCHES.get(branch,{}).get("repair",1.0),room.manual_repair_cost(),"MAXIMUM LEVEL10" if level>=9 else "Next maximum %.1f HP%s" % [clone.max_hp()," (before branch choice)" if level==4 and branch=="" else ""]]
