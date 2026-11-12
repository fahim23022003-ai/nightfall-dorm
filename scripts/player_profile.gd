class_name PlayerProfile
extends RefCounted

var path="user://profile.json"
var xp=0
var equipped: Array=[]
var settings={"music":0.5,"effects":0.65,"ambient":0.5,"muted":false,"fullscreen":false,"tutorial":true,"battery_saver":false}
var next_match_id=1
var active_match: Dictionary={}
var last_award: Dictionary={}
var warning=""
var read_only=false
var save_ok=true
var selected_stage="stage_1"
var selected_difficulty="standard"
var campaign_records: Dictionary={}


func _init(save_path: String="user://profile.json"):
 path=save_path

func rank_index() -> int: return RankCatalog.rank_for(xp)
func rank_name() -> String: return RankCatalog.NAMES[rank_index()]
func unlocked() -> Array: return RankCatalog.unlocked(xp)

func _whole(value, minimum: int, maximum: int=1000000000000) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and value>=minimum and value<=maximum

func _valid_loadout(value, points: int) -> bool:
 if not value is Array or value.size()>RankCatalog.MAX_EQUIPPED: return false
 var unique=[]
 for id in value:
  if not id is String or id not in RankCatalog.unlocked(points) or id in unique: return false
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
 if not active.is_empty():
  if not _whole(active.get("id"),1,int(value.next_match_id)-1): return {}
  if not _valid_loadout(active.get("equipped"),int(value.xp)): return {}
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
 next_match_id=int(data.next_match_id)
 equipped=[]
 for id in data.equipped:
  if id is String and id in unlocked() and id not in equipped and equipped.size()<RankCatalog.MAX_EQUIPPED: equipped.append(id)
 for key in ["music","effects","ambient"]:
  var value=data.settings.get(key,settings[key])
  if (value is float or value is int) and is_finite(float(value)): settings[key]=clampf(float(value),0,1)
 for key in ["muted","fullscreen","tutorial","battery_saver"]:
  if data.settings.get(key) is bool: settings[key]=data.settings[key]
 active_match=data.get("active_match",{}).duplicate(true)
 last_award=data.get("last_award",{}).duplicate(true)
 return true

func save_profile() -> bool:
 if read_only:
  save_ok=false
  return false
 var data={"version":RankCatalog.VERSION,"xp":xp,"equipped":equipped,"settings":settings,"next_match_id":next_match_id,"active_match":active_match,"last_award":last_award,"campaign":{"selected_stage":selected_stage,"difficulty":selected_difficulty,"records":campaign_records}}
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
 elif RankCatalog.MAX_EQUIPPED==1: equipped=[id]
 elif equipped.size()<RankCatalog.MAX_EQUIPPED: equipped.append(id)
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
 if stage_id!="" and (read_only or not stage_unlocked(stage_id)): return {}
 if next_match_id>=1000000000000:
  warning="Match counter limit reached; progress saving disabled."
  read_only=true
  return {}
 if not RankCatalog.DIFFICULTIES.has(difficulty): difficulty="standard"
 var before=active_match.duplicate(true)
 active_match={"id":next_match_id,"difficulty":difficulty,"equipped":equipped.duplicate()}
 if stage_id!="": active_match.stage_id=stage_id
 next_match_id+=1
 if not save_profile() and stage_id!="":
  next_match_id-=1
  active_match=before
  return {}
 return active_match.duplicate(true)

func settle_match(id: int,model) -> Dictionary:
 if active_match.is_empty() or id!=int(active_match.id) or model.result not in ["victory","defeat"]: return {}
 if not last_award.is_empty() and id<=int(last_award.match_id): return {}
 if model.difficulty!=active_match.difficulty: return {}
 if not _valid_loadout(active_match.equipped,xp): return {}
 var expected=RankCatalog.bonuses(active_match.equipped)
 var neutral=RankCatalog.bonuses([])
 for key in expected:
  if model.match_boosts.get(key,neutral[key])!=expected[key]: return {}
 var campaign_id=str(active_match.get("stage_id",""))
 if campaign_id!="" and (not stage_unlocked(campaign_id) or not "stage_id" in model or model.stage_id!=campaign_id): return {}
 var points=RankCatalog.performance(model)
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
  campaign_report={"stage_id":campaign_id,"cleared":cleared,"first_clear":first,"reward_xp":reward,
   "next_stage":StageCatalog.next_stage(campaign_id) if cleared else ""}

 var before=rank_index()
 points.ceiling_adjustment=-maxi(0,int(points.total)-(RankCatalog.MAX_XP-xp))
 points.total=mini(int(points.total),RankCatalog.MAX_XP-xp)
 xp+=int(points.total)
 var after=rank_index()
 last_award={"match_id":id,"breakdown":points,"old_rank":before,"new_rank":after,"promoted":after>before,"result":model.result}
 if not campaign_report.is_empty(): last_award.campaign=campaign_report
 active_match={}
 save_profile()
 return last_award.duplicate(true)
