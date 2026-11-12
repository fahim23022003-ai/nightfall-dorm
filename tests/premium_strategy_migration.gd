extends SceneTree
# Frozen pre-5D1 serialized profile written by old production code, not a new-schema mock.
const LEGACY="res://docs/evidence/premium-strategy/qa-legacy-profile.json"
var checks=0
var failures=0
var serial=0
var prefix="user://premium-migration-"+str(Time.get_ticks_usec())+"-"
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("PREMIUM MIGRATION: "+label)
func write(data):
 serial+=1
 var path=prefix+str(serial)+".json"
 var file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(data));file.close()
 return path
func numeric_same(a,b):
 # JSON parse uses float numbers; the production loader normalizes integer stock/
 # counters. Compare every value exactly while allowing numerically equal types.
 if a is Dictionary and b is Dictionary:
  if a.size()!=b.size():return false
  for key in a:
   if not b.has(key) or not numeric_same(a[key],b[key]):return false
  return true
 if a is Array and b is Array:
  if a.size()!=b.size():return false
  for i in range(a.size()):
   if not numeric_same(a[i],b[i]):return false
  return true
 return a==b
func original(p,source):
 check(p.xp==source.xp and p.highest_rank==6 and p.rank_index()==6,"Mythic XP/rank preserved")
 check(p.equipped==source.equipped and numeric_same(p.statistics,source.progression.statistics),"perks and match statistics preserved")
 check(numeric_same(p.inventory,source.consumables.inventory) and p.inventory.size()==20,"all20 distinct inventory stacks preserved")
 check(p.item_loadout==source.consumables.loadout and p.pending_spins==source.consumables.pending,"item selection and already-rolled spin preserved")
 check(p.campaign_records==source.campaign.records and p.selected_stage==source.campaign.selected_stage and p.selected_difficulty==source.campaign.difficulty,"all five stage records/selections preserved")
 check(p.achievements==source.rewards.achievements and p.reward_counters==source.rewards.counters and p.seen_items==source.rewards.seen_items,"achievement receipts/counters preserved")
 check(p.rm_cash==102 and p.purchase_serial==4 and p.tutorial_completed,"actual old shop transaction/cash/tutorial preserved")
 check(p.next_match_id==7 and p.active_match.is_empty() and p.settings==source.settings,"match identity and every setting preserved")
func run():
 var source=JSON.parse_string(FileAccess.get_file_as_string(LEGACY))
 check(source is Dictionary and not source.has("strategy"),"frozen real pre-strategy fixture has no new optional block")
 var p=PlayerProfile.new(write(source));check(p.load_profile() and not p.read_only,"old progressed save migrates writable")
 original(p,source)
 check(p.selected_contract=="" and p.contract_claims.is_empty(),"absent strategy block opts out without phantom claims")
 var before=p._reward_snapshot();check(p.save_profile(),"migrated profile safely saves new block")
 var reopened=PlayerProfile.new(p.path)
 check(reopened.load_profile() and reopened._reward_snapshot()==before,"migration roundtrip preserves complete reward snapshot")
 original(reopened,source)
 var inventory=reopened.inventory.duplicate(true)
 check(not reopened.claim_spin(6).is_empty() and reopened.inventory==inventory,"existing spin receipt claims without granting duplicate stock")
 check(reopened.claim_spin(6).is_empty() and reopened.inventory==inventory,"existing spin receipt cannot claim twice")
 check(reopened.buy_common("repair",5) and reopened.rm_cash==84 and reopened.purchase_serial==5,"old shop token continues legitimately after migration")
 check(not reopened.buy_common("repair",5) and reopened.rm_cash==84,"old shop token remains duplicate-safe")
 var invalids=[null,[],{}, {"version":2,"selected":"","claims":{}},{"version":1,"selected":"legendary_future","claims":{}},{"version":1,"selected":"","claims":[]},{"version":1,"selected":"","claims":{"stage_99:hell:no_legendary":1}},{"version":1,"selected":"","claims":{"stage_1:unknown:no_legendary":1}},{"version":1,"selected":"","claims":{"stage_1:hell:missing":1}},{"version":1,"selected":"","claims":{"stage_1:hell:no_legendary":-1}},{"version":1,"selected":"","claims":{"stage_1:hell:no_legendary":1.5}}]
 for value in invalids:
  var damaged=source.duplicate(true);damaged.strategy=value
  var path=write(damaged);var raw=FileAccess.get_file_as_string(path)
  var loaded=PlayerProfile.new(path);loaded.load_profile()
  check(loaded.read_only,"malformed/future optional strategy is read-only")
  original(loaded,source)
  check(not loaded.save_profile() and FileAccess.get_file_as_string(path)==raw,"malformed/future strategy bytes never overwritten")
  check(not loaded.select_contract("iron_survivor") and loaded.begin_match("standard","stage_1",true).is_empty(),"read-only strategy save cannot start/spend/overwrite")
 var valid=source.duplicate(true);valid.strategy={"version":1,"selected":"iron_survivor","claims":{"stage_1:hell:no_legendary":3}}
 var active=PlayerProfile.new(write(valid));check(active.load_profile() and not active.read_only,"valid existing strategy receipts load")
 check(active.selected_contract=="iron_survivor" and numeric_same(active.contract_claims,valid.strategy.claims),"selected contract and claim receipt preserved")
 var path=active.path;active.path=prefix+"missing/not-created.json"
 var snapshot=active._reward_snapshot()
 check(not active.select_contract("") and active._reward_snapshot()==snapshot,"failed contract-selection save rolls back selection")
 active.path=path
 var d=DirAccess.open("user://")
 for file in d.get_files():
  if file.begins_with(prefix.trim_prefix("user://")):DirAccess.remove_absolute("user://"+file)
 print("PREMIUM_MIGRATION_CHECKS=",checks," INVALID_BLOCKS=",invalids.size()," FAILURES=",failures)
 quit(0 if failures==0 else 1)
