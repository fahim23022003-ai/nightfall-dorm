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
 var active=value.get("active_match",{})
 if not active.is_empty():
  if not _whole(active.get("id"),1,int(value.next_match_id)-1): return {}
  if not _valid_loadout(active.get("equipped"),int(value.xp)): return {}
  if not active.get("difficulty") in RankCatalog.DIFFICULTIES or not active.get("equipped") is Array: return {}
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
 var data={"version":RankCatalog.VERSION,"xp":xp,"equipped":equipped,"settings":settings,"next_match_id":next_match_id,"active_match":active_match,"last_award":last_award}
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

func begin_match(difficulty: String="standard") -> Dictionary:
 if next_match_id>=1000000000000:
  warning="Match counter limit reached; progress saving disabled."
  read_only=true
  return {}
 if not RankCatalog.DIFFICULTIES.has(difficulty): difficulty="standard"
 active_match={"id":next_match_id,"difficulty":difficulty,"equipped":equipped.duplicate()}
 next_match_id+=1
 save_profile()
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
 var points=RankCatalog.performance(model)
 var before=rank_index()
 points.ceiling_adjustment=-maxi(0,int(points.total)-(RankCatalog.MAX_XP-xp))
 points.total=mini(int(points.total),RankCatalog.MAX_XP-xp)
 xp+=int(points.total)
 var after=rank_index()
 last_award={"match_id":id,"breakdown":points,"old_rank":before,"new_rank":after,"promoted":after>before,"result":model.result}
 active_match={}
 save_profile()
 return last_award.duplicate(true)
