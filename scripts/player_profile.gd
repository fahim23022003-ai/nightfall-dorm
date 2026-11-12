class_name PlayerProfile
extends RefCounted

var path="user://profile.json"
var xp=0
var equipped: Array=[]
var settings={"music":0.5,"effects":0.65,"ambient":0.5,"muted":false,"fullscreen":false,"tutorial":true,"battery_saver":false,"reduced_effects":false}
var next_match_id=1
var active_match: Dictionary={}
var last_award: Dictionary={}
var warning=""
var read_only=false
var save_ok=true
var selected_stage="stage_1"
var selected_difficulty="standard"
var campaign_records: Dictionary={}
var statistics={"matches":0,"victories":0,"defeats":0,"standard":0,"hard":0,"hell":0,"reaper_defeats":0}
var highest_rank=0
var inventory: Dictionary={}
var item_loadout: Array=[]
var pending_spins: Array=[]
var reward_rng=RandomNumberGenerator.new()
var item_error=""
var achievements: Dictionary={}
var reward_counters={"door_damage":0.0,"income":0.0,"construction":0,"legendary":0,"perfect_team":0}
var seen_items: Array=[]
var pending_stage_bonus: Dictionary={}
var stage_bonus_queue: Array=[]
func perk_slots() -> int: return 2 if rank_index()>=5 else 1
func _reward_snapshot() -> Dictionary:
 var out={}
 for key in ["xp","equipped","highest_rank","statistics","campaign_records","inventory","item_loadout","pending_spins","active_match","last_award","achievements","reward_counters","seen_items","pending_stage_bonus","stage_bonus_queue","next_match_id"]:
  var v=get(key)
  out[key]=v.duplicate(true) if v is Dictionary or v is Array else v
 return out
func _restore_rewards(before: Dictionary):
 for key in before:set(key,before[key])
func refresh_achievements() -> Array:
 for id in inventory:
  if int(inventory[id])>0 and id not in seen_items:seen_items.append(id)
 var evidence={"first_victory":statistics.victories>=1,"first_blood":statistics.victories>=1,"night_survivor":statistics.hard>=1,"hell_survivor":statistics.hell>=1,"reaper_hunter":statistics.reaper_defeats>=1,"reaper_slayer":statistics.reaper_defeats>=3,"perfect_team":reward_counters.perfect_team>=1,"iron_fortress":reward_counters.door_damage>=RewardCatalog.CONDITIONS.door_damage,"economy_master":reward_counters.income>=RewardCatalog.CONDITIONS.income,"master_builder":reward_counters.construction>=RewardCatalog.CONDITIONS.construction,"item_collector":seen_items.size()>=RewardCatalog.CONDITIONS.distinct_items,"legendary_survivor":reward_counters.legendary>=1}
 var earned=[]
 for id in evidence:
  if evidence[id] and not achievements.has(id):achievements[id]={"claimed":false};earned.append(id)
 return earned
func claim_achievement(id: String) -> bool:
 var definition=RewardCatalog.achievement(id)
 if read_only or definition.is_empty() or not achievements.has(id) or achievements[id].claimed:return false
 if int(inventory.get(definition.item,0))>=ItemCatalog.MAX_STOCK:return false
 var before=_reward_snapshot()
 achievements[id].claimed=true
 xp=mini(RankCatalog.MAX_XP,xp+definition.xp)
 inventory[definition.item]=int(inventory.get(definition.item,0))+1
 refresh_achievements()
 highest_rank=maxi(highest_rank,rank_index())
 if not save_profile():_restore_rewards(before);return false
 return true
func choose_stage_bonus(choice: String) -> bool:
 if read_only or not RewardCatalog.STAGE_BONUSES.has(choice) or pending_stage_bonus.is_empty() or pending_stage_bonus.get("choice","")!="":return false
 var old=pending_stage_bonus.duplicate(true)
 pending_stage_bonus.choice=choice
 if not save_profile():pending_stage_bonus=old;return false
 return true
func apply_stage_bonus(model,entry: Dictionary):
 if model.time>0 or model.player_room>=0:return false
 if entry.get("stage_id","")==model.stage_id and RewardCatalog.STAGE_BONUSES.has(entry.get("stage_bonus","")):
  model.stage_bonus=RewardCatalog.STAGE_BONUSES[entry.stage_bonus].duplicate(true)
func _item_failure(model,reason: String) -> bool:
 item_error=reason
 model.feedback.emit(reason)
 return false
func _valid_item_snapshot(value) -> bool:
 if not value is Array or value.size()>ItemCatalog.SLOTS: return false
 var seen=[]
 for id in value:
  if not id is String or not ItemCatalog.ITEMS.has(id) or id in seen: return false
  seen.append(id)
 return true
func pending_spin() -> Dictionary:
 return pending_spins[0].duplicate(true) if not pending_spins.is_empty() else {}
func equip_item(id: String) -> bool:
 if read_only or not ItemCatalog.ITEMS.has(id): return false
 var before=item_loadout.duplicate()
 if id in item_loadout: item_loadout.erase(id)
 elif int(inventory.get(id,0))<=0 or item_loadout.size()>=ItemCatalog.SLOTS: return false
 else: item_loadout.append(id)
 if not save_profile(): item_loadout=before; return false
 return true
func claim_spin(id: int) -> Dictionary:
 if read_only or pending_spins.is_empty() or int(pending_spins[0].match_id)!=id: return {}
 var reward=pending_spins.pop_front()
 if not save_profile(): pending_spins.push_front(reward); return {}
 return reward.duplicate(true)
func bind_items(model,id: int):
 model.items.profile_ref=weakref(self)
 model.items.match_id=id
 model.items.legendary_used=maxi(model.items.legendary_used,int(active_match.get("legendary_used",0)))
 if model.player()!=null:
  var effects=weakref(model.items)
  var reference=weakref(model)
  model.player().coupon_payment=func(saved: Vector2):
   var fx=effects.get_ref()
   var m=reference.get_ref()
   var ok=fx!=null and m!=null and fx.consume("coupon",m)
   if ok:
    fx.emit_item("coupon",m,saved.x,"used")
    fx.events[-1].power=saved.y
   return ok
func consume_item(item: String,model,id: int) -> bool:
 if read_only or active_match.is_empty() or int(active_match.id)!=id or item not in active_match.get("items",[]) or int(inventory.get(item,0))<=0: return false
 var selected=item_loadout.duplicate()
 var old_active=active_match.duplicate(true)
 if ItemCatalog.legendary(item):
  if maxi(int(active_match.get("legendary_used",0)),model.items.legendary_used)>=ItemCatalog.TUNING.legendary_limit: return false
  active_match["legendary_used"]=int(active_match.get("legendary_used",0))+1
 inventory[item]-=1
 if inventory[item]<=0: item_loadout.erase(item)
 if not save_profile(): inventory[item]+=1; item_loadout=selected; active_match=old_active; return false
 return true
func activate_item(slot: int,model,id: int,target: int=-1) -> bool:
 item_error=""
 if read_only: return _item_failure(model,"Items unavailable: profile is read-only.")
 if active_match.is_empty() or int(active_match.id)!=id or not _valid_item_snapshot(active_match.get("items",[])) or slot<0 or slot>=active_match.get("items",[]).size(): return _item_failure(model,"No item equipped in that slot for this match.")
 var item=str(active_match.items[slot])
 if int(inventory.get(item,0))<=0: return _item_failure(model,"No stock remaining.")
 bind_items(model,id)
 model.items.rescue_target=target
 var reason=model.items.can_activate(item,model)
 if reason!="": return _item_failure(model,reason)
 if item=="coupon":
  model.items.apply(item,model)
  return true
 if not consume_item(item,model,id): return _item_failure(model,"Item not used: inventory or Legendary limit could not be saved.")
 model.items.apply(item,model)
 return true


func _init(save_path: String="user://profile.json"):
 path=save_path
 reward_rng.randomize()

func rank_index() -> int:
 var rank=RankCatalog.rank_for(xp)
 if rank==6 and not RankCatalog.mythic_ready(statistics,campaign_records): rank=5
 return maxi(rank,highest_rank)
func highest_completed_stage() -> int:
 var number=0
 for id in campaign_records: number=maxi(number,StageCatalog.index_of(id)+1)
 return number
func promotion_requirement() -> String:
 if rank_index()==6: return "MYTHIC achieved · permanent prestige"
 if rank_index()<5: return "%d XP to %s" % [RankCatalog.THRESHOLDS[rank_index()+1]-xp,RankCatalog.NAMES[rank_index()+1]]
 return "Mythic: %d/8000 XP · Stage 5 %s · Advanced wins %d/3 · Reapers %d/3" % [xp,"cleared" if campaign_records.has("stage_5") else "needed",statistics.hard+statistics.hell,statistics.reaper_defeats]
func rank_name() -> String: return RankCatalog.NAMES[rank_index()]
func unlocked() -> Array:
 return RankCatalog.PERKS.filter(func(p):return p.rank<=rank_index()).map(func(p):return p.id)

func _whole(value, minimum: int, maximum: int=1000000000000) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and value>=minimum and value<=maximum

func _valid_loadout(value, points: int, effective: int=-1) -> bool:
 var rank=RankCatalog.rank_for(points) if effective<0 else effective
 if not value is Array or value.size()>(2 if rank>=5 else 1): return false
 var unique=[]
 for id in value:
  if not id is String or RankCatalog.perk(id).is_empty() or RankCatalog.perk(id).rank>rank or id in unique: return false
  unique.append(id)
 return true

func stage_unlocked(id: String) -> bool:
 var definition=StageCatalog.stage(id)
 return not definition.is_empty() and (definition.requires=="" or campaign_records.has(definition.requires))

func stage_record(id: String) -> Dictionary:
 return campaign_records.get(id,{}).duplicate(true)

func highest_unlocked_stage() -> int:
 var highest=1
 for item in StageCatalog.STAGES:
  if stage_unlocked(item.id): highest=maxi(highest,item.number)
 return highest

func select_stage(id: String) -> bool:
 if read_only or not stage_unlocked(id): return false
 var before=selected_stage
 selected_stage=id
 if not save_profile():
  selected_stage=before
  return false
 return true

func select_difficulty(id: String) -> bool:
 if read_only or not RankCatalog.DIFFICULTIES.has(id): return false
 var before=selected_difficulty
 selected_difficulty=id
 if not save_profile():
  selected_difficulty=before
  return false
 return true

func _valid_campaign(value) -> bool:
 if not value is Dictionary: return false
 if not value.get("records") is Dictionary: return false
 if not value.get("selected_stage") is String or StageCatalog.stage(value.selected_stage).is_empty(): return false
 if not value.get("difficulty") in RankCatalog.DIFFICULTIES: return false
 var records=value.records
 for id in records:
  var definition=StageCatalog.stage(id)
  var record=records[id]
  if definition.is_empty() or not record is Dictionary: return false
  if definition.requires!="" and not records.has(definition.requires): return false
  if not _whole(record.get("clears"),1) or not _whole(record.get("best_xp"),0,RankCatalog.MAX_XP): return false
  if not record.get("difficulty") in RankCatalog.DIFFICULTIES: return false
  if not _whole(record.get("first_match_id"),1): return false
  for field in ["best_time","best_damage"]:
   var n=record.get(field)
   if not (n is int or n is float) or not is_finite(float(n)) or n<0 or n>1000000000000: return false
 var chosen=StageCatalog.stage(value.selected_stage)
 return chosen.requires=="" or records.has(chosen.requires)

func _json(text: String):
 var parser=JSON.new()
 if parser.parse(text)!=OK: return null
 return parser.data

func _decode(file_path: String) -> Dictionary:
 if not FileAccess.file_exists(file_path): return {}
 var f=FileAccess.open(file_path,FileAccess.READ)
 if f==null or f.get_length()>1024*1024: return {}
 var value=_json(f.get_as_text())
 if not value is Dictionary: return {}
 # Reject unknown versions instead of silently downgrading a future save.
 if value.get("version",0)!=RankCatalog.VERSION: return {}
 if not _whole(value.get("xp"),0,RankCatalog.MAX_XP) or not _whole(value.get("next_match_id"),1): return {}
 if not value.get("equipped") is Array or not value.get("settings") is Dictionary: return {}
 if not value.get("active_match",{}) is Dictionary or not value.get("last_award",{}) is Dictionary: return {}
 if value.has("campaign"):
  if not _valid_campaign(value.campaign): return {}
  for record in value.campaign.records.values():
   if not _whole(record.first_match_id,1,int(value.next_match_id)-1): return {}
 var active=value.get("active_match",{})
 if not _whole(active.get("legendary_used",0),0,int(ItemCatalog.TUNING.legendary_limit)): return {}
 if not active.is_empty():
  if not _whole(active.get("id"),1,int(value.next_match_id)-1): return {}
  var effective=RankCatalog.rank_for(int(value.xp))
  if effective==6 and not RankCatalog.mythic_ready(value.get("progression",{}).get("statistics",{}),value.get("campaign",{}).get("records",{})):effective=5
  if not _valid_loadout(active.get("equipped"),int(value.xp),effective): return {}
  if not active.get("difficulty") in RankCatalog.DIFFICULTIES or not active.get("equipped") is Array: return {}
  if active.has("stage_id"):
   if not active.stage_id is String or StageCatalog.stage(active.stage_id).is_empty() or not value.has("campaign"): return {}
   var definition=StageCatalog.stage(active.stage_id)
   if definition.requires!="" and not value.campaign.records.has(definition.requires): return {}
 var previous=value.get("last_award",{})
 if not previous.is_empty():
  if not _whole(previous.get("match_id"),1,int(value.next_match_id)-1): return {}
  if not previous.get("breakdown") is Dictionary: return {}
  if not active.is_empty() and int(active.id)<=int(previous.match_id): return {}
 return value

func load_profile() -> bool:
 var primary_exists=FileAccess.file_exists(path)
 var data=_decode(path)
 if data.is_empty():
  var recovered=_decode(path+".bak")
  if primary_exists:
   # Preserve unknown/corrupt bytes before any future write. Future schemas are read-only.
   var raw=FileAccess.get_file_as_string(path)
   var unknown=_json(raw)
   if unknown is Dictionary and (unknown.get("version") is int or unknown.get("version") is float) and unknown.version>RankCatalog.VERSION:
    read_only=true
    warning="This save belongs to a newer game version. Progress saving is disabled to preserve it."
    return false
   var quarantine=path+".corrupt."+str(Time.get_unix_time_from_system()).replace(".","_")
   if DirAccess.copy_absolute(path,quarantine)!=OK:
    read_only=true
    warning="Cannot preserve damaged save; saving disabled. Your original file is untouched."
    return false
  if recovered.is_empty():
   warning="Damaged save preserved. A new profile is available." if primary_exists else ""
   return not primary_exists
  data=recovered
  warning="Recovered previous profile backup; damaged primary was preserved."
 var campaign=data.get("campaign",{"selected_stage":"stage_1","difficulty":"standard","records":{}})
 selected_stage=campaign.selected_stage
 selected_difficulty=campaign.difficulty
 campaign_records=campaign.records.duplicate(true)
 xp=int(data.xp)
 statistics={"matches":0,"victories":0,"defeats":0,"standard":0,"hard":0,"hell":0,"reaper_defeats":0}
 highest_rank=mini(5,RankCatalog.rank_for(xp))
 var progression=data.get("progression",{})
 if progression is Dictionary and progression.get("version")==1:
  var valid=progression.get("statistics") is Dictionary
  if valid:
   for key in statistics:
    if not _whole(progression.statistics.get(key),0): valid=false
  if valid:
   var st=progression.statistics
   valid=st.matches==st.victories+st.defeats and st.victories==st.standard+st.hard+st.hell and st.reaper_defeats<=st.victories
  if valid:
   for key in statistics: statistics[key]=int(progression.statistics[key])
   if _whole(progression.get("highest_rank"),0,RankCatalog.rank_for(xp)) and (int(progression.highest_rank)<6 or RankCatalog.mythic_ready(statistics,campaign_records)):
    highest_rank=maxi(highest_rank,int(progression.highest_rank))
  else: warning="Optional statistics were damaged; existing XP, perks and campaign were preserved."
 if progression is Dictionary and _whole(progression.get("version"),2):
  read_only=true
  warning="This progression belongs to a newer game version; saving disabled to preserve it."
 highest_rank=maxi(highest_rank,rank_index())
 var consumables=data.get("consumables",{})
 inventory={}; item_loadout=[]; pending_spins=[]
 if consumables is Dictionary and consumables.get("version")==1:
  var valid=consumables.get("inventory") is Dictionary and consumables.get("loadout") is Array and consumables.get("pending") is Array
  if valid:
   for key in consumables.inventory:
    if not ItemCatalog.ITEMS.has(key) or not _whole(consumables.inventory[key],0,ItemCatalog.MAX_STOCK): valid=false
   if consumables.loadout.size()>ItemCatalog.SLOTS: valid=false
   var seen=[]
   for key in consumables.loadout:
    if not key is String or not ItemCatalog.ITEMS.has(key) or key in seen: valid=false
    seen.append(key)
   var ids=[]
   if consumables.pending.size()>128: valid=false
   for spin in consumables.pending:
    if not spin is Dictionary or not _whole(spin.get("quantity",1),0,4) or not _whole(spin.get("match_id"),1,int(data.next_match_id)-1) or not spin.get("item","") in ItemCatalog.IDS or not spin.get("result","") in ["victory","defeat"]: valid=false
    elif spin.match_id in ids: valid=false
    else: ids.append(spin.match_id)
  if valid:
   for key in consumables.inventory: inventory[key]=int(consumables.inventory[key])
   item_loadout=consumables.loadout.duplicate()
   pending_spins=consumables.pending.duplicate(true)
  else:
   read_only=true
   warning="Consumable records are damaged; existing progression loaded read-only to preserve inventory."
 elif not consumables is Dictionary or (not consumables.is_empty() and consumables.get("version")!=1):
  read_only=true
  warning="Unknown consumable save version; saving disabled to preserve it."
 next_match_id=int(data.next_match_id)
 equipped=[]
 for id in data.equipped:
  if id is String and id in unlocked() and id not in equipped and equipped.size()<perk_slots(): equipped.append(id)
 for key in ["music","effects","ambient"]:
  var value=data.settings.get(key,settings[key])
  if (value is float or value is int) and is_finite(float(value)): settings[key]=clampf(float(value),0,1)
 for key in ["muted","fullscreen","tutorial","battery_saver","reduced_effects"]:
  if data.settings.get(key) is bool: settings[key]=data.settings[key]
 active_match=data.get("active_match",{}).duplicate(true)
 if not _valid_item_snapshot(active_match.get("items",[])):
  read_only=true
  active_match["items"]=[]
  warning="Active item snapshot was damaged; saving disabled to preserve your original profile."
 last_award=data.get("last_award",{}).duplicate(true)
 var rewards=data.get("rewards",{})
 if not rewards is Dictionary:
  read_only=true;warning="Reward records invalid; existing progress preserved read-only."
 elif not rewards.is_empty():
  if not _valid_rewards(rewards):
   read_only=true;warning="Reward records are damaged or newer; progress preserved read-only."
  else:
   achievements=rewards.achievements.duplicate(true)
   reward_counters=rewards.counters.duplicate(true)
   seen_items=rewards.seen_items.duplicate()
   pending_stage_bonus=rewards.stage_bonus.duplicate(true)
   stage_bonus_queue=rewards.get("stage_queue",[]).duplicate(true)
   if not pending_stage_bonus.is_empty():pending_stage_bonus.match_id=int(pending_stage_bonus.match_id)
   for offer in stage_bonus_queue:offer.match_id=int(offer.match_id)
 if not read_only:
  var before=_reward_snapshot()
  var earned=refresh_achievements()
  if not earned.is_empty() and not save_profile():_restore_rewards(before)
 return true

func save_profile() -> bool:
 if read_only:
  save_ok=false
  return false
 var data={"rewards":{"version":1,"achievements":achievements,"counters":reward_counters,"seen_items":seen_items,"stage_bonus":pending_stage_bonus,"stage_queue":stage_bonus_queue},"consumables":{"version":1,"inventory":inventory,"loadout":item_loadout,"pending":pending_spins},"version":RankCatalog.VERSION,"progression":{"version":1,"statistics":statistics,"highest_rank":maxi(highest_rank,rank_index())},"xp":xp,"equipped":equipped,"settings":settings,"next_match_id":next_match_id,"active_match":active_match,"last_award":last_award,"campaign":{"selected_stage":selected_stage,"difficulty":selected_difficulty,"records":campaign_records}}
 var f=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if f==null: return _write_failed()
 f.store_string(JSON.stringify(data," "))
 f.flush()
 var error=f.get_error()
 f.close()
 if error!=OK: return _write_failed()
 if _decode(path+".tmp").is_empty(): return _write_failed()
 # Copy a valid old generation first; never replace the backup with corrupt bytes.
 if not _decode(path).is_empty():
  if DirAccess.copy_absolute(path,path+".bak")!=OK: return _write_failed()
 if DirAccess.rename_absolute(path+".tmp",path)!=OK: return _write_failed()
 save_ok=true
 return true

func _write_failed() -> bool:
 save_ok=false
 warning="Progress could not be saved. Check disk permissions; retry before closing."
 return false

func equip(id: String) -> bool:
 if id not in unlocked(): return false
 var before=equipped.duplicate()
 if id in equipped: equipped.erase(id)
 elif perk_slots()==1: equipped=[id]
 elif equipped.size()<perk_slots(): equipped.append(id)
 else: return false
 if not save_profile():
  equipped=before
  return false
 return true

func update_setting(key: String,value) -> bool:
 if not settings.has(key): return false
 if key in ["music","effects","ambient"]:
  if not (value is int or value is float) or not is_finite(float(value)): return false
  value=clampf(float(value),0,1)
 elif not value is bool: return false
 settings[key]=value
 return save_profile()

func begin_match(difficulty: String="standard",stage_id: String="") -> Dictionary:
 if read_only or pending_spins.size()>=128 or (stage_id!="" and not stage_unlocked(stage_id)): return {}
 if next_match_id>=1000000000000:
  warning="Match counter limit reached; progress saving disabled."
  read_only=true
  return {}
 if not RankCatalog.DIFFICULTIES.has(difficulty): difficulty="standard"
 var old_bonus=pending_stage_bonus.duplicate(true)
 var old_queue=stage_bonus_queue.duplicate(true)
 if not pending_stage_bonus.is_empty() and pending_stage_bonus.target==stage_id and pending_stage_bonus.choice=="":return {}
 var before=active_match.duplicate(true)
 active_match={"id":next_match_id,"difficulty":difficulty,"equipped":equipped.duplicate(),"items":item_loadout.duplicate()}
 if stage_id!="": active_match.stage_id=stage_id
 if not pending_stage_bonus.is_empty() and pending_stage_bonus.target==stage_id:
  active_match.stage_bonus=pending_stage_bonus.choice
  pending_stage_bonus=stage_bonus_queue.pop_front() if not stage_bonus_queue.is_empty() else {}
 next_match_id+=1
 if not save_profile():
  next_match_id-=1
  pending_stage_bonus=old_bonus
  stage_bonus_queue=old_queue
  active_match=before
  return {}
 return active_match.duplicate(true)

func settle_match(id: int,model) -> Dictionary:
 if active_match.is_empty() or id!=int(active_match.id) or model.result not in ["victory","defeat"]: return {}
 if not last_award.is_empty() and id<=int(last_award.match_id): return {}
 if model.difficulty!=active_match.difficulty: return {}
 if model.result=="victory" and (model.hunter.hp>0 or model.player()==null or not model.player().alive): return {}
 if not _valid_loadout(active_match.equipped,xp,rank_index()): return {}
 var expected=RankCatalog.bonuses(active_match.equipped)
 var neutral=RankCatalog.bonuses([])
 for key in expected:
  if model.match_boosts.get(key,neutral[key])!=expected[key]: return {}
 var campaign_id=str(active_match.get("stage_id",""))
 if campaign_id!="" and (not stage_unlocked(campaign_id) or not "stage_id" in model or model.stage_id!=campaign_id): return {}
 var transaction_before=_reward_snapshot()
 var rng_before=reward_rng.state
 var points=RankCatalog.performance(model)
 var old_xp=xp
 var old_rank=rank_index()
 var campaign_report={}
 if campaign_id!="":
  var definition=StageCatalog.stage(campaign_id)
  var cleared=model.result=="victory" and points.eligible and model.hunter.hp<=0 and model.player()!=null and model.player().alive
  var first=cleared and not campaign_records.has(campaign_id)
  var reward=int(definition.first_clear_xp) if first else 0
  points["stage_reward"]=reward
  points.total+=reward
  if cleared:
   var old=campaign_records.get(campaign_id,{})
   campaign_records[campaign_id]={"clears":mini(1000000000000,int(old.get("clears",0))+1),
    "best_time":minf(float(old.get("best_time",model.time)),model.time),
    "best_damage":maxf(float(old.get("best_damage",0)),model.player().damage_dealt),
    "best_xp":maxi(int(old.get("best_xp",0)),mini(int(points.total),RankCatalog.MAX_XP-xp)),
    "difficulty":active_match.difficulty,"first_match_id":old.get("first_match_id",id)}
  if first and StageCatalog.next_stage(campaign_id)!="":
   var offer={"source":campaign_id,"target":StageCatalog.next_stage(campaign_id),"choice":"","match_id":id}
   if pending_stage_bonus.is_empty():pending_stage_bonus=offer
   else:stage_bonus_queue.append(offer)
  campaign_report={"stage_id":campaign_id,"cleared":cleared,"first_clear":first,"reward_xp":reward,
   "next_stage":StageCatalog.next_stage(campaign_id) if cleared else ""}

 var before=old_rank
 var defeated=model.result=="defeat" and ((model.player()!=null and not model.player().alive) or (model.player()==null and model.eliminations>0))
 var victorious=model.result=="victory" and model.player()!=null and model.hunter.hp<=0 and model.player().alive
 var legitimate=model.time>=model.preparation and (defeated or victorious)
 if legitimate and statistics.matches<1000000000000:
  statistics.matches=mini(1000000000000,statistics.matches+1)
  if model.result=="victory" and model.hunter.hp<=0 and model.player().alive:
   statistics.victories=mini(1000000000000,statistics.victories+1)
   statistics[model.difficulty]=mini(1000000000000,statistics[model.difficulty]+1)
   if model.hunter.transformed: statistics.reaper_defeats=mini(1000000000000,statistics.reaper_defeats+1)
  else: statistics.defeats=mini(1000000000000,statistics.defeats+1)
 points.ceiling_adjustment=-maxi(0,int(points.total)-(RankCatalog.MAX_XP-xp))
 points.total=mini(int(points.total),RankCatalog.MAX_XP-xp)
 xp+=int(points.total)
 var after=rank_index()
 highest_rank=maxi(highest_rank,after)
 last_award={"match_id":id,"old_xp":old_xp,"new_xp":xp,"breakdown":points,"old_rank":before,"new_rank":after,"promoted":after>before,"result":model.result}
 if not campaign_report.is_empty(): last_award.campaign=campaign_report
 if ItemCatalog.reward_eligible(model):
  var item=ItemCatalog.roll(model.result,reward_rng)
  var quantity=4 if model.result=="victory" else 1
  var granted=mini(quantity,ItemCatalog.MAX_STOCK-int(inventory.get(item,0)))
  inventory[item]=int(inventory.get(item,0))+granted
  pending_spins.append({"match_id":id,"item":item,"result":model.result,"quantity":granted})
 if points.eligible and legitimate and model.player()!=null:
  var room=model.player()
  if room.alive:reward_counters.door_damage=minf(1e12,reward_counters.door_damage+room.door_damage_taken)
  reward_counters.income=minf(1e12,reward_counters.income+room.income_total)
  reward_counters.construction=mini(1000000000000,int(reward_counters.construction)+room.construction_actions)
  reward_counters.legendary=mini(1000000000000,int(reward_counters.legendary)+int(active_match.get("legendary_used",0)))
  if victorious and model.rooms.all(func(r):return r.alive and r.sleeping and r.owner>=0):reward_counters.perfect_team+=1
 last_award.achievements=refresh_achievements()
 active_match={}
 if not save_profile():
  _restore_rewards(transaction_before)
  reward_rng.state=rng_before
  return {}
 return last_award.duplicate(true)

func _valid_rewards(value) -> bool:
 if not value is Dictionary or value.get("version")!=1 or not value.get("achievements") is Dictionary or not value.get("counters") is Dictionary or not value.get("seen_items") is Array or not value.get("stage_bonus") is Dictionary:return false
 for id in value.achievements:
  if RewardCatalog.achievement(id).is_empty() or not value.achievements[id] is Dictionary or not value.achievements[id].get("claimed") is bool:return false
 for key in reward_counters:
  var n=value.counters.get(key)
  if not (n is int or n is float) or not is_finite(float(n)) or n<0 or n>1e12:return false
  if key in ["construction","legendary","perfect_team"] and not _whole(n,0):return false
 var seen=[]
 for id in value.seen_items:
  if not id is String or not ItemCatalog.ITEMS.has(id) or id in seen:return false
  seen.append(id)
 if not value.get("stage_queue",[]) is Array or value.get("stage_queue",[]).size()>4:return false
 var offers=value.get("stage_queue",[]).duplicate(true)
 if not value.stage_bonus.is_empty():offers.append(value.stage_bonus)
 var sources=[]
 for bonus in offers:
  if not bonus is Dictionary or bonus.is_empty() or bonus.get("source","") in sources:return false
  sources.append(bonus.get("source",""))
  if not bonus.get("source","") in campaign_records or bonus.get("target","")!=StageCatalog.next_stage(bonus.source) or not _whole(bonus.get("match_id"),1) or (bonus.get("choice","")!="" and not RewardCatalog.STAGE_BONUSES.has(bonus.choice)):return false
 return true

func achievement_progress(id: String) -> String:
 var numbers={"first_victory":[statistics.victories,1],"first_blood":[statistics.victories,1],"night_survivor":[statistics.hard,1],"hell_survivor":[statistics.hell,1],"reaper_hunter":[statistics.reaper_defeats,1],"reaper_slayer":[statistics.reaper_defeats,3],"perfect_team":[reward_counters.perfect_team,1],"iron_fortress":[reward_counters.door_damage,RewardCatalog.CONDITIONS.door_damage],"economy_master":[reward_counters.income,RewardCatalog.CONDITIONS.income],"master_builder":[reward_counters.construction,RewardCatalog.CONDITIONS.construction],"item_collector":[seen_items.size(),RewardCatalog.CONDITIONS.distinct_items],"legendary_survivor":[reward_counters.legendary,1]}
 var n=numbers.get(id,[0,1])
 return "%d / %d" % [mini(int(n[0]),int(n[1])),int(n[1])]
