extends SceneTree
# Real frozen pre-5D2 profile, not a mock of the new schema.
const Support=preload("res://tests/replay_test_support.gd")
const Progress=preload("res://scripts/replay_progress.gd")
const BASE="res://docs/evidence/replay/qa-legacy-profile.json"
var checks=0
var failures=0
var serial=0
var prefix="user://replay-migration-"+str(Time.get_ticks_usec())+"-"
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("REPLAY MIGRATION: "+label)
func write(data):
 serial+=1;var path=prefix+str(serial)+".json"
 var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close();return path
func preserved(p,source):
 check(p.xp==8200 and p.rank_index()==6 and p.equipped==source.equipped,"Mythic XP/rank/permanent perks preserved")
 check(Support.numeric_same(p.inventory,source.consumables.inventory) and p.inventory.size()==20 and p.item_loadout==source.consumables.loadout,"all20 nonuniform stacks and equipped items preserved")
 check(Support.numeric_same(p.statistics,source.progression.statistics) and Support.numeric_same(p.campaign_records,source.campaign.records),"statistics and all five stage records preserved")
 check(p.pending_spins==source.consumables.pending and p.pending_stage_bonus==source.rewards.stage_bonus,"already-rolled spin and stage choices preserved")
 check(p.rm_cash==84 and p.purchase_serial==5 and p.tutorial_completed and p.settings==source.settings,"real previous shop cash/token, tutorial and every setting preserved")
 check(p.selected_contract=="iron_survivor" and Support.numeric_same(p.contract_claims,source.strategy.claims),"5D1 strategy selection and claim receipt preserved")
 check(p.achievements==source.rewards.achievements and Support.numeric_same(p.reward_counters,source.rewards.counters),"achievement unlock/claim/counter state preserved")
func invalid_optional(source):
 var valid=Progress.defaults()
 var cases=[null,[],{}, {"version":2},valid.duplicate(true),valid.duplicate(true),valid.duplicate(true),valid.duplicate(true),valid.duplicate(true),valid.duplicate(true),valid.duplicate(true),valid.duplicate(true),valid.duplicate(true),valid.duplicate(true),valid.duplicate(true)]
 cases[4].pity.epic_dry=8;cases[5].pity.legendary_dry=40;cases[6].pity.legendary_dry=-1;cases[7].pity.epic_dry=.5;cases[8].pity={}
 cases[9].cosmetics.door="future_skin";cases[10].cosmetics.door="coil_crown";cases[11].checkpoint={"version":2};cases[12].run_serial=1e13;cases[13].best_wave=19;cases[13].milestone_wave=20;cases[14].best_wave=25;cases[14].milestone_wave=25
 for value in cases:
  var data=source.duplicate(true);data.replay=value
  var path=write(data);var bytes=FileAccess.get_file_as_bytes(path);var p=PlayerProfile.new(path);p.load_profile()
  check(p.read_only,"malformed/future replay block stays read-only")
  preserved(p,source)
  check(not p.save_profile() and FileAccess.get_file_as_bytes(path)==bytes,"bad optional replay data cannot overwrite original progressed bytes")
  check(p.begin_endless(MapCatalog.IDS[0],"standard",1).is_empty(),"read-only replay state cannot start/spend persistent run")
func active_ledger(source):
 var p=PlayerProfile.new(write(source));check(p.load_profile(),"active ledger source loads")
 p.pending_spins=[];p.item_loadout=["coupon","time_freeze"]
 var entry=p.begin_endless(MapCatalog.IDS[0],"standard",19)
 check(not entry.is_empty(),"valid current Endless active snapshot uses actual writer")
 var current=JSON.parse_string(FileAccess.get_file_as_string(p.path))
 for change in ["missing_legendary","negative_count","fractional_count","unknown_item","too_many","missing_feather","missing_rescue","wrong_run","future_kind"]:
  var data=current.duplicate(true)
  match change:
   "missing_legendary":data.active_match.erase("legendary_used")
   "negative_count":data.active_match.use_counts={"coupon":-1}
   "fractional_count":data.active_match.use_counts={"coupon":.5}
   "unknown_item":data.active_match.use_counts={"future_item":1}
   "too_many":data.active_match.use_counts={"coupon":ItemCatalog.MAX_STOCK+1}
   "missing_feather":data.active_match.erase("feather_used")
   "missing_rescue":data.active_match.erase("rescue_used")
   "wrong_run":data.active_match.run_id+=1
   "future_kind":data.active_match.run_kind="future_mode"
  var path=write(data);var bytes=FileAccess.get_file_as_bytes(path);var loaded=PlayerProfile.new(path);loaded.load_profile()
  check(loaded.read_only and loaded.xp==8200 and Support.numeric_same(loaded.inventory,current.consumables.inventory) and loaded.rm_cash==84,"malformed active run ledger preserves old progress read-only: "+change)
  check(not loaded.save_profile() and FileAccess.get_file_as_bytes(path)==bytes,"malformed active run ledger cannot rewrite original: "+change)
func run():
 var source=JSON.parse_string(FileAccess.get_file_as_string(BASE))
 check(source is Dictionary and not source.has("replay"),"frozen previous-writer fixture predates pity/cosmetics/Endless")
 var p=PlayerProfile.new(write(source));check(p.load_profile() and not p.read_only,"previous progressed profile migrates writable")
 preserved(p,source)
 check(p.replay.pity=={"epic_dry":0,"legendary_dry":0} and p.replay.best_wave==0 and p.replay.checkpoint.is_empty(),"missing optional block gets neutral empty defaults")
 check(Progress.valid(JSON.parse_string(JSON.stringify(Progress.defaults()))),"new default replay block survives real JSON numeric types")
 var before=p._reward_snapshot();check(p.save_profile(),"migrated profile saves new block")
 var reopened=PlayerProfile.new(p.path);check(reopened.load_profile() and not reopened.read_only and Support.numeric_same(reopened._reward_snapshot(),before),"new replay block reopens with every old/new reward field preserved")
 preserved(reopened,source)
 invalid_optional(source);active_ledger(source);Support.cleanup(prefix)
 print("REPLAY_MIGRATION_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
