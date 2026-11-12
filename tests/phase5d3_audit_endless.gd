extends "res://tests/phase6_balance_endless.gd"
# Bounded independent Phase5D3 audit. Parent helper uses real movement/economy/combat.
var all_reaches={}
var current_cfg={}
var natural_profiles=[]
func upgrade(m,kind,goal,count,branch=""):
 var r=m.player();var found=kinds(r,kind)
 if found.size()<count:build(m,kind);return false
 for tile in found:
  var b=r.buildings[tile]
  if b.level<goal:
   if b.level==4:m.specialize_building(tile,branch if branch!="" else StrategyCatalog.branches(kind)[int(current_cfg.get("alternative",false))])
   else:m.upgrade_building(tile)
   return false
 return true
func record_reaches(m):
 var r=m.player()
 var levels={"bed":r.bed_level+1,"door":r.door_level+1}
 for kind in Catalog.BUILDINGS:
  levels[kind]=0
  for tile in kinds(r,kind):levels[kind]=maxi(levels[kind],r.buildings[tile].level)
 for kind in levels:
  if levels[kind]==10 and not all_reaches.has(kind):
   var paid=[]
   for tile in kinds(r,kind):
    var b=r.buildings[tile];paid.append({"tile":tile,"level":b.level,"branch":b.get("specialization",""),"gold":b.invested_gold,"electricity":b.invested_power})
   all_reaches[kind]={"wave":m.endless.wave,"seconds":snappedf(m.time,.1),"income":r.income_total,"gold":r.gold,"electricity":r.electricity,"paid_machines":paid,"bed_branch":r.bed_branch,"door_branch":r.door_branch}
func structural(m,kind):
 var r=m.player();var level=r.bed_level if kind=="bed" else r.door_level
 if level>=9:return true
 if level==4:r.specialize_structure(kind,StrategyCatalog.branches(kind)[int(current_cfg.get("alternative",false))])
 elif kind=="bed":m.upgrade_bed()
 else:m.upgrade_door()
 return false
func act(m,cfg,account):
 record_reaches(m)
 if not cfg.get("all_eight",false) or not all_reaches.has(StrategyCatalog.BRANCHES[cfg.branch].kind):
  super.act(m,cfg,account);return
 var r=m.player()
 if r.door_hp<r.max_hp()*.7:
  if (r.door_level!=4 and m.upgrade_door()) or m.repair_door():return
 if not upgrade(m,"generator",10,2):return
 if r.bed_level<9 or r.door_level<9:
  if r.bed_level<=r.door_level and r.bed_level<9:structural(m,"bed")
  else:structural(m,"door")
  return
 for kind in ["economy","repair","enhancer","turret","heavy"]:
  var branch=cfg.branch if kind==StrategyCatalog.BRANCHES[cfg.branch].kind else StrategyCatalog.branches(kind)[int(cfg.get("alternative",false))]
  if not upgrade(m,kind,10,1,branch):return
 if r.door_hp<r.max_hp()*.96:m.repair_door()
func save_earned(p,m,kind,reach,impact):
 if all_reaches.size()<8:return
 var name=str(current_cfg.map)+"-"+str(current_cfg.mode)+("-alternative" if current_cfg.get("alternative",false) else "")+str(current_cfg.get("variant",""))
 if natural_profiles.has(name):return
 if not p.checkpoint_endless(m):failures+=1;return
 var path="res://docs/evidence/phase5d3/balance-earned-all8-"+name+".json"
 var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(FileAccess.get_file_as_string(p.path));f.close()
 var loaded=PlayerProfile.new(path);var okay=loaded.load_profile();var restored=loaded.resume_endless() if okay else null
 if restored==null:failures+=1;push_error("Natural all-eight profile failed fresh restore")
 else:natural_profiles.append(name)
func run():
 var rows=[];var configs=[]
 if "--hell-final" in OS.get_cmdline_user_args():
  for i in [2,5]:configs.append({"map":MapCatalog.IDS[i%5],"mode":"hell","trait_id":StrategyCatalog.TRAIT_IDS[i%3],"branch":["precision","suppression","focus","storm"][i%4],"seed":11+i%3,"policy":"typical" if i<3 else "optimized","waves":12,"resume":true,"alternative":i%2==1})
  configs.append({"map":"cursed_mansion","mode":"hell","trait_id":"fortified","branch":"storm","seed":47,"policy":"optimized","waves":30,"resume":true,"all_eight":true,"alternative":true,"budget":"mythic_control"})
  configs.append({"map":"cursed_mansion","mode":"hell","trait_id":"fortified","branch":"storm","seed":47,"policy":"optimized","waves":65,"resume":true,"all_eight":true,"alternative":true,"budget":"mythic_control","variant":"-active65"})
 elif "--advanced" in OS.get_cmdline_user_args():
  configs.append({"map":"haunted_hospital","mode":"standard","trait_id":"economy","branch":"suppression","seed":11,"policy":"optimized","waves":80,"resume":true,"all_eight":true,"passive_from":20,"variant":"-passive80"})
  configs.append({"map":"cursed_mansion","mode":"hell","trait_id":"fortified","branch":"storm","seed":47,"policy":"optimized","waves":65,"resume":true,"all_eight":true,"alternative":true,"budget":"mythic_control","variant":"-active65"})
 elif "--probe" not in OS.get_cmdline_user_args():
  for i in range(6):configs.append({"map":MapCatalog.IDS[i%5],"mode":["standard","hard","hell"][i%3],"trait_id":StrategyCatalog.TRAIT_IDS[i%3],"branch":["precision","suppression","focus","storm"][i%4],"seed":11+i%3,"policy":"typical" if i<3 else "optimized","waves":12,"resume":true,"alternative":i%2==1})
 if "--advanced" not in OS.get_cmdline_user_args() and "--hell-final" not in OS.get_cmdline_user_args():configs.append({"map":"haunted_hospital","mode":"standard","trait_id":"economy","branch":"suppression","seed":11,"policy":"optimized","waves":30,"resume":true,"all_eight":true})
 if "--probe" not in OS.get_cmdline_user_args() and "--advanced" not in OS.get_cmdline_user_args() and "--hell-final" not in OS.get_cmdline_user_args():configs.append({"map":"cursed_mansion","mode":"hell","trait_id":"fortified","branch":"storm","seed":47,"policy":"optimized","waves":30,"resume":true,"all_eight":true,"alternative":true,"budget":"mythic_control"})
 for cfg in configs:
  all_reaches={};current_cfg=cfg
  var row=simulate(cfg);row.all_eight_reaches=all_reaches.duplicate(true);rows.append(row)
 var out={"scope":"Fresh Phase5D3 live earned-income, actual path/claim/sleep/combat. Prepared finite Master/Mythic perk/stock budgets. Decisions0.2/1s, no human/native Windows claim. No live funds/HP/time/position/waves injected.","runs":rows,"failures":failures,"resume_checks":resume_checks,"natural_all8_profiles":natural_profiles}
 var f=FileAccess.open("res://docs/evidence/phase5d3/balance-endless"+("-probe" if "--probe" in OS.get_cmdline_user_args() else "-advanced" if "--advanced" in OS.get_cmdline_user_args() else "-hell-final" if "--hell-final" in OS.get_cmdline_user_args() else "")+"-results.json",FileAccess.WRITE);f.store_string(JSON.stringify(out," "));f.close()
 print("PHASE5D3_AUDIT_ENDLESS_RUNS=",rows.size()," RESUMES=",resume_checks," ALL8_PROFILES=",natural_profiles.size()," FAILURES=",failures)
 quit(1 if failures else 0)
