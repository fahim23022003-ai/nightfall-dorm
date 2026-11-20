class_name StoryProgress
extends RefCounted

const VERSION := 1
const DIFFICULTIES := ["standard","hard","hell"]
const MAX_SEED := 2147483646
const LAST_LEGACY_LEVEL := 5

static func _track() -> Dictionary:
 return {"position":1,"highest":0,"last_completed":0,"last_match_id":0}

static func fresh(seed_base: int=1) -> Dictionary:
 var tracks:={}
 for mode: String in DIFFICULTIES:
  tracks[mode]=_track()
 return {"version":VERSION,"seed_base":clampi(seed_base,1,MAX_SEED),"tracks":tracks,"rewards":[]}

static func migrate(campaign_records: Dictionary, seed_base: int=1) -> Dictionary:
 var value:=fresh(seed_base)
 for level in range(1,LAST_LEGACY_LEVEL+1):
  var record: Dictionary=campaign_records.get("stage_%d" % level,{})
  if int(record.get("clears",0))<1:continue
  value.rewards.append(level)
  var mode: String=record.get("difficulty","")
  if mode not in DIFFICULTIES:continue
  var track: Dictionary=value.tracks[mode]
  if int(track.highest)!=level-1:continue
  track.highest=level
  track.last_completed=level
  track.position=level+1
 return value

static func _whole(value: Variant, minimum: int, maximum: int) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and value>=minimum and value<=maximum and float(value)==floorf(float(value))

static func valid(value: Variant) -> bool:
 if not value is Dictionary or value.get("version")!=VERSION or not _whole(value.get("seed_base"),1,MAX_SEED) or not value.get("tracks") is Dictionary or not value.get("rewards") is Array:
  return false
 var main: Dictionary=value
 if main.tracks.size()!=DIFFICULTIES.size() or main.rewards.size()>StoryCatalog.FINAL_LEVEL:return false
 var seen:={}
 for level in main.rewards:
  if not _whole(level,1,StoryCatalog.FINAL_LEVEL) or seen.has(int(level)):return false
  seen[int(level)]=true
 var greatest_clear:=0
 for mode: String in DIFFICULTIES:
  var track: Variant=main.tracks.get(mode)
  if not track is Dictionary or not _whole(track.get("highest"),0,StoryCatalog.FINAL_LEVEL):return false
  var highest:=int(track.highest)
  greatest_clear=maxi(greatest_clear,highest)
  if not _whole(track.get("position"),checkpoint_for(highest),mini(StoryCatalog.FINAL_LEVEL,highest+1)):return false
  if highest==StoryCatalog.FINAL_LEVEL and int(track.position)!=StoryCatalog.FINAL_LEVEL:return false
  if not _whole(track.get("last_completed"),0 if highest==0 else 1,highest) or not _whole(track.get("last_match_id"),0,1000000000000):return false
  for level in range(1,highest+1):
   if not seen.has(level):return false
 for level: int in seen:
  if level>maxi(LAST_LEGACY_LEVEL,greatest_clear):return false
 return true

static func checkpoint_for(highest: int) -> int:
 return maxi(1,mini(45,floori(float(highest)/StoryCatalog.CHAPTER_LENGTH)*StoryCatalog.CHAPTER_LENGTH))

static func seed_for(value: Dictionary, level: int) -> int:
 if level<1 or level>StoryCatalog.FINAL_LEVEL:return 0
 var mission:=StoryCatalog.mission(level)
 var origin:=int(value.get("seed_base",1))+level*345373+15617*level*level
 for step in range(512):
  var candidate:=posmod(origin+step,MAX_SEED)+1
  if NightmareMacroLayout.family_for(mission.theme,candidate)==mission.topology:return candidate
 return posmod(origin,MAX_SEED)+1

static func position(value: Dictionary, mode: String) -> int:
 return int(value.get("tracks",{}).get(mode,{}).get("position",1))

static func summary(value: Dictionary, mode: String) -> Dictionary:
 var track: Dictionary=value.get("tracks",{}).get(mode,_track())
 var level:=int(track.position)
 var highest:=int(track.highest)
 return {"position":level,"highest":highest,"last_completed":int(track.last_completed),
  "checkpoint":checkpoint_for(highest),"finished":highest==StoryCatalog.FINAL_LEVEL,"chapter":ceili(float(level)/StoryCatalog.CHAPTER_LENGTH)}

static func settle(value: Dictionary, mode: String, level: int, won: bool, match_id: int) -> Dictionary:
 if mode not in DIFFICULTIES or not valid(value) or level<1 or level>StoryCatalog.FINAL_LEVEL or match_id<1 or match_id>1000000000000 or position(value,mode)!=level:return {}
 var track: Dictionary=value.tracks[mode]
 if int(track.highest)==StoryCatalog.FINAL_LEVEL or match_id<=int(track.last_match_id):return {}
 var mission:=StoryCatalog.mission(level)
 var first_clear: bool=won and not _reward_claimed(value.rewards,level)
 if first_clear:value.rewards.append(level)
 track.last_match_id=match_id
 if won:
  track.highest=maxi(int(track.highest),level)
  track.last_completed=level
  track.position=mini(level+1,StoryCatalog.FINAL_LEVEL)
 else:
  track.position=maxi(level-1,checkpoint_for(int(track.highest)))
 var result:=summary(value,mode)
 result.merge({"level":level,"previous_position":level,"cleared":won,"difficulty":mode,
  "title":mission.title,"first_clear":first_clear,"reward_xp":int(mission.first_clear_xp) if first_clear else 0,
  "next_title":"" if result.finished else StoryCatalog.mission(result.position).title},true)
 return result

static func credit_legacy_reward(value: Dictionary, level: int) -> void:
 if level>=1 and level<=LAST_LEGACY_LEVEL and not value.is_empty() and not _reward_claimed(value.rewards,level):
  value.rewards.append(level)

static func _reward_claimed(rewards: Array, level: int) -> bool:
 # JSON decodes integral numbers as floats. A loaded reward is still the
 # same mission as its in-memory integer identifier.
 return rewards.any(func(reward):return int(reward)==level)
