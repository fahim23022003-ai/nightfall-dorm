extends SceneTree
# Invoked in separate OS processes: write, read, cleanup. Isolated QA file only.
const PATH="user://qa-cross-process-phase2.json"
func _initialize(): call_deferred("run")
func run():
 var args=OS.get_cmdline_user_args()
 var stage=args[0] if not args.is_empty() else ""
 if stage=="cleanup":
  for suffix in ["",".bak",".tmp"]:
   if FileAccess.file_exists(PATH+suffix): DirAccess.remove_absolute(PATH+suffix)
  print("PROFILE_PROCESS_CLEANUP=PASS")
  quit()
  return
 var p=PlayerProfile.new(PATH)
 var ok=false
 if stage=="write":
  p.xp=700
  p.equipped=["dreamer"]
  p.settings.music=0.21
  p.settings.effects=0.43
  p.settings.ambient=0.34
  p.settings.muted=true
  var entry=p.begin_match("hard")
  var model=MatchModel.new()
  model.configure_match("hard",RankCatalog.bonuses(entry.equipped))
  model.claim_room(0)
  model.player_position=model.player().bed_position()
  model.sleep_player()
  model.time=model.preparation+30
  model.player().occupied_seconds=30
  model.player().damage_dealt=100
  model.player().door_damage_taken=100
  model.result="victory"
  var award=p.settle_match(entry.id,model)
  ok=not award.is_empty() and p.xp==866 and p.save_ok
 elif stage=="read":
  ok=p.load_profile() and p.xp==866 and p.rank_name()=="Gold" and p.equipped==["dreamer"] and p.active_match.is_empty()
  ok=ok and is_equal_approx(p.settings.music,0.21) and is_equal_approx(p.settings.effects,0.43) and is_equal_approx(p.settings.ambient,0.34) and p.settings.muted
  var old=p.xp
  var model=MatchModel.new()
  model.result="victory"
  ok=ok and p.settle_match(p.last_award.match_id,model).is_empty() and p.xp==old
 print("PROFILE_PROCESS_",stage.to_upper(),"=","PASS" if ok else "FAIL")
 quit(0 if ok else 1)
