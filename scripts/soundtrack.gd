class_name Soundtrack
extends RefCounted
const EXTRA=["music_lantern","music_portrait","music_dust","music_siege","music_procession","music_opening_alt"]
const TITLES={"music_menu":"The Night Watch","music_lantern":"Lantern Lament","music_portrait":"Portraits at Midnight","music_calm":"Sleeping Halls","music_dust":"Dust Waltz","music_approach":"Footsteps Below","music_danger":"Door Siege","music_siege":"Broken Vespers","music_endless":"Endless Watch","music_procession":"The Last Procession"}
const FAMILIES={"music_intro":["music_intro","music_opening_alt"],"music_menu":["music_menu","music_lantern","music_portrait"],"music_calm":["music_calm","music_dust"],"music_approach":["music_approach","music_siege"],"music_danger":["music_danger","music_siege"],"music_endless":["music_endless","music_procession","music_dust"]}
var rng=RandomNumberGenerator.new()
var history={"version":1,"bags":{},"last":{}}
var path=""
var mode="shuffle"
var manual="music_calm"
var family=""
var current=""
var elapsed=0.0
func _init(file=""):
 rng.randomize();path=file
 if path=="":
  path=OS.get_environment("NIGHTFALL_PROFILE_PATH")
  if path=="":path="user://profile.json"
  path+=".soundtrack.json"
 for candidate in [path,path+".bak"]:
  if not FileAccess.file_exists(candidate):continue
  var parsed=JSON.parse_string(FileAccess.get_file_as_string(candidate))
  if valid(parsed):history=parsed;break
static func valid(d) -> bool:
 if not d is Dictionary or d.get("version")!=1 or not d.get("bags") is Dictionary or not d.get("last") is Dictionary:return false
 for key in d.bags:
  if not FAMILIES.has(key) or not d.bags[key] is Array or d.bags[key].size()>FAMILIES[key].size():return false
  var seen=[]
  for id in d.bags[key]:
   if id not in FAMILIES[key] or id in seen:return false
   seen.append(id)
 for key in d.last:
  if not FAMILIES.has(key) or d.last[key] not in FAMILIES[key]:return false
 return true
func draw(key: String) -> String:
 var bag=history.bags.get(key,[]).duplicate()
 if bag.is_empty():
  bag=FAMILIES[key].duplicate()
  for i in range(bag.size()-1,0,-1):
   var j=rng.randi_range(0,i);var value=bag[i];bag[i]=bag[j];bag[j]=value
 if bag.size()>1 and bag.back()==history.last.get(key,""):
  var value=bag[0];bag[0]=bag.back();bag[-1]=value
 var chosen=bag.pop_back();history.bags[key]=bag;history.last[key]=chosen;save()
 return chosen
func save():
 var f=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if f==null:return
 f.store_string(JSON.stringify(history));f.flush();f.close()
 if FileAccess.file_exists(path) and valid(JSON.parse_string(FileAccess.get_file_as_string(path))):DirAccess.copy_absolute(path,path+".bak")
 DirAccess.rename_absolute(path+".tmp",path)
func settings(values):
 var next=values.get("music_mode",mode);var track=values.get("manual_track",manual)
 if next not in ["shuffle","classic","manual","off"]:next=mode
 if track not in TITLES:track=manual
 if next!=mode or track!=manual:family="";current="";elapsed=0
 mode=next;manual=track
func route(targets: Dictionary,delta: float,streams: Dictionary):
 if mode=="classic":return
 var chosen="";var weight=0.0
 for key in targets:
  if key.begins_with("music") and targets[key]>weight:chosen=key;weight=targets[key]
 for key in streams:
  if key.begins_with("music") and not targets.has(key):targets[key]=0.0
 if mode=="off":
  for key in targets:
   if key.begins_with("music"):targets[key]=0.0
  return
 # Cinematic and boss compositions keep their dedicated identities.
 if chosen not in FAMILIES:return
 if chosen!=family or current=="" or elapsed>=streams[current].get_length():
  family=chosen;current=manual if mode=="manual" and chosen not in ["music_menu","music_intro"] else draw(chosen);elapsed=0
 elapsed+=delta
 for key in targets:
  if key.begins_with("music"):targets[key]=0.0
 targets[current]=minf(.95,maxf(.75,weight))
