extends SceneTree
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok: failures+=1; push_error(label)
func _initialize():
 var path="user://mythic-exposed-edge.json"
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
 var profile=PlayerProfile.new(path)
 var abandoned=profile.begin_match()
 var entry=profile.begin_match()
 check(profile.statistics.matches==0,"aborted starts do not count")
 var model=MatchModel.new()
 model.time=model.preparation+30
 model.player_position=model.hunter.position
 model.tick(.1)
 check(model.result=="defeat" and model.player()==null and model.eliminations>0,"actual exposed capture without claimed room")
 var award=profile.settle_match(entry.id,model)
 check(not award.is_empty() and award.breakdown.total==0,"exposed loss has zero XP")
 check(profile.statistics.matches==1 and profile.statistics.defeats==1,"exposed loss recorded once")
 check(profile.settle_match(entry.id,model).is_empty() and profile.statistics.matches==1,"repeat does not count")
 var loaded=PlayerProfile.new(path)
 check(loaded.load_profile() and loaded.statistics.matches==1 and loaded.statistics.defeats==1,"exposed loss persists")
 check(loaded.settle_match(entry.id,model).is_empty() and loaded.statistics.matches==1,"reloaded duplicate blocked")
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
 print("MYTHIC_EDGE_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
