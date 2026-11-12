extends SceneTree
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("PHASE6 INPUT: "+label)
func _initialize():call_deferred("run")
func run():
 var good=ChallengeCode.encode({"map":"abandoned_dorm","seed":17,"archetype":"crusher","difficulty":"standard","preset":0,"gear":0})
 check(ChallengeCode.decode(good).ok,"canonical valid baseline")
 var rng=RandomNumberGenerator.new();rng.seed=6062026
 var cases=["", " ", "../profile.json",good+"\n",good+String.chr(1),good.repeat(5000),"NF2-99999999999999999999999999999", "ＮＦ２-１-０-１７", "\u202e"+good]
 for i in range(2000):
  var code=good
  var at=rng.randi_range(0,code.length()-1)
  code=code.left(at)+String.chr(rng.randi_range(1,126))+code.substr(at+1)
  cases.append(code)
 for code in cases:
  var decoded=ChallengeCode.decode(code)
  check(decoded.has("ok") and decoded.ok is bool,"decoder returns controlled result for bounded mutation")
  if decoded.ok:
   check(ChallengeCode.encode(decoded.config)==decoded.code and decoded.code==code.strip_edges().to_upper(),"accepted mutation remains canonical complete validated conditions")
  else:check(decoded.get("error","")!="","rejection gives useful error")
 var path="user://phase6-invalid-input-"+str(Time.get_ticks_usec())+".json"
 var p=PlayerProfile.new(path);check(p.save_profile(),"isolated profile baseline")
 var original=FileAccess.get_file_as_bytes(path);var fields=p._reward_snapshot()
 for id in ["", "../repair", "../../profile.json", "future_item", "repair"+String.chr(1), "canopy/../coil_crown", "Ｒｅｐａｉｒ"]:
  check(not p.equip_item(id),"invalid inventory identifier rejected")
  check(not p.equip_cosmetic(id),"invalid cosmetic identifier rejected")
  check(not p.buy_common(id,1),"invalid shop identifier rejected")
  check(not p.select_stage(id),"invalid stage identifier rejected")
  check(not p.select_difficulty(id),"invalid difficulty identifier rejected")
  check(p._reward_snapshot()==fields and FileAccess.get_file_as_bytes(path)==original,"invalid identifiers leave all rewards and save bytes unchanged")
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 print("PHASE6_INPUT_CHECKS=",checks," CASES=",cases.size()," FAILURES=",failures)
 quit(0 if failures==0 else 1)
