extends SceneTree
# Real action/terminal/settlement paths with prepared budgets and target HP.
# These are transaction fixtures, never natural-win or balance evidence.
var checks=0
var failures=0
var serial=0
var prefix="user://premium-contract-"+str(Time.get_ticks_usec())+"-"
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("PREMIUM CONTRACT: "+label)
func fresh(contract=""):
 serial+=1
 var p=PlayerProfile.new(prefix+str(serial)+".json")
 for id in ItemCatalog.IDS:p.inventory[id]=2
 p.item_loadout=["time_freeze","repair"]
 p.reward_rng.seed=14123
 check(p.select_contract(contract),"optional contract saves/opts out")
 return p
func begin(p,mode="standard"):
 var entry=p.begin_match(mode,"stage_1",true)
 check(not entry.is_empty(),"actual strategic profile match begins")
 var m=MatchModel.new();m.reset(72);m.configure_match(mode,RankCatalog.bonuses(entry.equipped));m.configure_stage("stage_1")
 check(m.configure_strategy(int(p.statistics.matches),entry.archetype,entry.contract,entry.id),"profile snapshot binds exact model strategy")
 m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 m.bot_claimed=5;m.time=m.preparation+25
 var r=m.player();r.occupied_seconds=25;r.gold=10000;r.electricity=10000;r.bed_level=2;r.door_level=2;r.door_hp=r.max_hp()
 m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.position=r.door_approach();m.hunter.cooldown=100;m.hunter.boss_policy.enabled=false
 p.bind_items(m,entry.id)
 return {"p":p,"m":m,"id":entry.id,"entry":entry}
func finish(a,win=true):
 var m=a.m;var r=m.player()
 if win:
  # A real paid turret launches and physically impacts; production tick sets result.
  var covered=false
  for tile in r.buildings:
   if r.buildings[tile].kind=="turret" and r.tile_position(tile).distance_to(m.hunter.position)<=Catalog.BUILDINGS.turret.range:covered=true
  if not covered:
   var nearest=-1
   for tile in range(r.tile_count()):
    if not r.buildings.has(tile) and (nearest<0 or r.tile_position(tile).distance_to(m.hunter.position)<r.tile_position(nearest).distance_to(m.hunter.position)):nearest=tile
   check(nearest>=0 and m.buy("turret",nearest),"terminal fixture buys real in-range turret")
  m.hunter.hp=1
  for i in range(40):
   m.tick(.1)
   if m.result!="":break
 else:
  m.hunter.cancel_boss_attack();m.hunter.encounter_attacks=1;m.hunter.cooldown=0
  m.hunter.archetype_primed=true;r.door_hp=1
  for i in range(300):
   m.tick(.1)
   if m.result!="":break
 check(m.result==("victory" if win else "defeat"),"production combat reaches requested fixture terminal result")
 check(m.strategy.verified(m,a.entry),"terminal facts sealed by actual model path")
func settle(a):return a.p.settle_match(a.id,a.m)
func fail_condition(a,contract):
 var m=a.m;var p=a.p;var r=m.player()
 match contract:
  "no_legendary":
   check(p.activate_item(0,m,a.id),"real Legendary inventory transaction triggers contract failure")
   # Expire actual freeze before the terminal fixture's physical shots.
   m.items.tick(4,m)
  "limited_defense":
   for tile in range(3):check(m.buy("turret",tile),"real paid turret counted")
   check(m.sell_building(2),"offending third turret can be sold legitimately")
  "iron_survivor":
   r.door_hp=r.max_hp()-30;check(m.repair_door(),"actual paid manual repair counted")
 check(m.strategy.failed and m.strategy.failure_reason!="","actual restriction failure is irreversible and explained")
func payouts():
 for mode in ["standard","hard","hell"]:
  var baseline=begin(fresh(),mode);finish(baseline)
  var neutral=settle(baseline)
  check(not neutral.is_empty() and not neutral.has("contract"),"opting out preserves ordinary rewards")
  for contract in StrategyCatalog.CONTRACTS:
   var a=begin(fresh(contract),mode);finish(a)
   var award=settle(a);var p=a.p
   check(not award.is_empty() and award.contract.qualified and award.contract.cash==StrategyCatalog.CONTRACTS[contract].cash,"qualifying genuine terminal pays documented contract bonus")
   check(award.rm_cash==neutral.rm_cash+StrategyCatalog.CONTRACTS[contract].cash and p.xp==baseline.p.xp,"contract adds only advertised cash, preserving XP rules")
   var key=StrategyCatalog.claim_key("stage_1",mode,contract)
   check(p.contract_claims.get(key)==a.id and p.pending_spins.size()==1 and p.campaign_records.has("stage_1"),"claim, stage record and existing Lucky Spin commit together")
   var before=p._reward_snapshot();var rng=p.reward_rng.state
   check(settle(a).is_empty() and p._reward_snapshot()==before and p.reward_rng.state==rng,"duplicate result cannot pay cash/items/XP/spin again")
   var loaded=PlayerProfile.new(p.path);check(loaded.load_profile() and loaded.contract_claims.has(key),"contract receipt persists after reload")
   var next=begin(loaded,mode);finish(next)
   var second=settle(next)
   check(not second.is_empty() and second.contract.qualified and second.contract.cash==0 and loaded.contract_claims.size()==1,"same stage/mode/contract cannot farm bonus on later valid win")
   var failed=begin(fresh(contract),mode);fail_condition(failed,contract);finish(failed)
   var declined=settle(failed)
   check(not declined.is_empty() and not declined.contract.qualified and declined.contract.cash==0 and failed.p.contract_claims.is_empty(),"failed contract pays no bonus while ordinary result still settles")
 for contract in StrategyCatalog.CONTRACTS:
  var a=begin(fresh(contract));finish(a,false)
  var award=settle(a)
  check(not award.is_empty() and award.contract.cash==0 and not award.contract.qualified and a.p.contract_claims.is_empty(),"real defeat cannot earn victory contract cash")
func identity_and_tampering():
 var p=fresh("no_legendary")
 var expected=p.next_archetype("stage_1","hell")
 for i in range(6):
  var entry=p.begin_match("hell","stage_1",true)
  check(entry.archetype==expected and p.statistics.matches==0,"aborted fresh IDs do not reroll archetype or count legitimate results")
  var loaded=PlayerProfile.new(p.path);check(loaded.load_profile() and loaded.next_archetype("stage_1","hell")==expected and loaded.active_match.archetype==expected,"reload preserves active and next encounter identity")
  p=loaded
 var a=begin(fresh("no_legendary"));var m=a.m
 var before=a.p._reward_snapshot();var rng=a.p.reward_rng.state
 m.hunter.hp=0;m.result="victory"
 check(settle(a).is_empty() and a.p._reward_snapshot()==before and a.p.reward_rng.state==rng,"handwritten result without actual terminal seal is rejected")
 for tamper in ["hunter","contract","time","result","match_id","counters"]:
  a=begin(fresh("no_legendary"));finish(a)
  before=a.p._reward_snapshot();rng=a.p.reward_rng.state
  match tamper:
   "hunter":a.m.hunter.archetype="invalid"
   "contract":a.m.strategy.contract="iron_survivor"
   "time":a.m.time+=1
   "result":a.m.result="defeat"
   "match_id":a.m.strategy.match_id+=1
   "counters":a.m.strategy.legendary_uses+=1
  check(settle(a).is_empty() and a.p._reward_snapshot()==before and a.p.reward_rng.state==rng,"changed terminal identity/facts rejected: "+tamper)
 a=begin(fresh("iron_survivor"));before=a.p._reward_snapshot()
 check(settle(a).is_empty() and a.p._reward_snapshot()==before,"aborting an unfinished contract pays nothing")
 var tutorial=MatchModel.new();tutorial.tutorial_mode=true
 check(not tutorial.configure_strategy(0,"crusher","iron_survivor") and not tutorial.strategy.enabled,"nine-step practice rejects advanced strategy/rewards")
func rollback():
 for contract in StrategyCatalog.CONTRACTS:
  var a=begin(fresh(contract));finish(a)
  var before=a.p._reward_snapshot();var rng=a.p.reward_rng.state
  var path=a.p.path;a.p.path=prefix+"missing/not-created.json"
  check(settle(a).is_empty() and a.p._reward_snapshot()==before and a.p.reward_rng.state==rng,"failed settlement atomically restores claim/cash/XP/items/stage/spin/active/RNG")
  a.p.path=path
  var control=begin(fresh(contract));finish(control);var expected=settle(control)
  var retried=settle(a)
  check(not retried.is_empty() and retried==expected and a.p.rm_cash==control.p.rm_cash and a.p.inventory==control.p.inventory,"retry after failed save produces exact original deterministic award")
  var snapshot=a.p._reward_snapshot()
  check(settle(a).is_empty() and a.p._reward_snapshot()==snapshot,"successful retry cannot repeat")
 var a=begin(fresh("no_legendary"));a.p.rm_cash=OnboardingCatalog.MAX_CASH-1;finish(a)
 var award=settle(a)
 check(award.contract.cash==0 and a.p.rm_cash==OnboardingCatalog.MAX_CASH and a.p.contract_claims.is_empty(),"full wallet records no partial or phantom contract payout")
 for token in range(1,4):check(a.p.buy_common("repair",token),"full-wallet player may legitimately free enough space for base reward plus bonus")
 var next=begin(a.p);finish(next);award=settle(next)
 check(award.contract.cash==StrategyCatalog.CONTRACTS.no_legendary.cash and a.p.contract_claims.size()==1,"postponed contract remains claimable on later qualifying match")
func legendary_edges():
 var p=fresh("no_legendary");p.item_loadout=["guardian_heart"]
 var a=begin(p);var m=a.m;var r=m.player();var h=m.hunter
 r.door_hp=1;h.cooldown=0;h.archetype_primed=true;h.encounter_attacks=1
 h.tick(.1,m)
 check(r.door_hp>1 and p.inventory.guardian_heart==1 and m.items.legendary_used==1,"real lethal Hunter strike triggers exactly one equipped Guardian rescue")
 check(m.strategy.failed and m.strategy.legendary_uses==1,"automatic Legendary genuinely fails No Legendary contract once")
 finish(a);var award=settle(a)
 check(not award.is_empty() and award.contract.cash==0 and not award.contract.qualified,"automatic rescue cannot bypass restriction at settlement")
 a=begin(fresh("no_legendary"));var path=a.p.path;a.p.path=prefix+"missing/not-created.json"
 check(not a.p.activate_item(0,a.m,a.id) and a.p.inventory.time_freeze==2,"failed Legendary save consumes no item")
 check(not a.m.strategy.failed and a.m.strategy.legendary_uses==0 and a.m.items.legendary_used==0 and not a.m.items.timers.has("time_freeze"),"failed activation cannot falsely fail contract or apply power")
 a.p.path=path;finish(a);award=settle(a)
 check(not award.is_empty() and award.contract.qualified and award.contract.cash==8,"valid later win remains eligible after genuinely failed activation")
func run():
 payouts();identity_and_tampering();rollback();legendary_edges()
 var d=DirAccess.open("user://")
 for file in d.get_files():
  if file.begins_with(prefix.trim_prefix("user://")):DirAccess.remove_absolute("user://"+file)
 print("PREMIUM_CONTRACT_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
