extends SceneTree
# Actual conditional tables and saved campaign result transactions; fixtures are not balance runs.
const Support=preload("res://tests/replay_test_support.gd")
const Pity=preload("res://scripts/spin_pity.gd")
var checks=0
var failures=0
var serial=0
var prefix="user://replay-pity-"+str(Time.get_ticks_usec())+"-"
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("REPLAY PITY: "+label)
func tables():
 var base={"epic_dry":0,"legendary_dry":0}
 check(Pity.weights("victory",base)==ItemCatalog.TABLES.victory,"ordinary Victory table retains registered weights")
 check(Pity.weights("defeat",base)==ItemCatalog.TABLES.defeat,"ordinary Consolation table retains registered weights")
 check(Pity.odds("victory",base)=={"Common":40.0,"Rare":40.0,"Epic":16.0,"Legendary":4.0},"actual ordinary Victory rarity odds")
 check(Pity.odds("defeat",base)=={"Common":80.0,"Rare":16.0,"Epic":3.0,"Legendary":1.0},"actual ordinary Consolation rarity odds")
 for epic in range(Pity.EPIC_LIMIT):
  for legendary in range(Pity.LEGENDARY_LIMIT):
   var state={"epic_dry":epic,"legendary_dry":legendary}
   var odds=Pity.odds("victory",state);var sum=0.0
   for value in odds.values():sum+=value
   check(is_equal_approx(sum,100),"every conditional rarity distribution normalizes")
   check(Pity.weights("defeat",state)==ItemCatalog.TABLES.defeat,"Consolation odds do not secretly change with Victory counters")
   if legendary==Pity.LEGENDARY_LIMIT-1:check(is_equal_approx(odds.Legendary,100),"Legendary boundary takes priority over Epic guarantee")
   elif epic==Pity.EPIC_LIMIT-1:check(odds.Common==0 and odds.Rare==0 and is_equal_approx(odds.Epic,80) and is_equal_approx(odds.Legendary,20),"Epic+ boundary uses actual original high-rarity relative weights")
   else:check(odds.Common==40 and odds.Rare==40 and odds.Epic==16 and odds.Legendary==4,"before either threshold ordinary odds remain unchanged")
 var rng=RandomNumberGenerator.new();rng.seed=7231
 var pity=base.duplicate();var epic_dry=0;var legendary_dry=0
 for i in range(6000):
  var before=pity.duplicate();var id=Pity.roll("victory",rng,pity);var rarity=ItemCatalog.ITEMS[id].rarity
  check(id in ItemCatalog.IDS,"roll only awards one of20 implemented items")
  epic_dry=0 if rarity in ["Epic","Legendary"] else epic_dry+1
  legendary_dry=0 if rarity=="Legendary" else legendary_dry+1
  check(epic_dry<Pity.EPIC_LIMIT and legendary_dry<Pity.LEGENDARY_LIMIT,"observed draw history never exceeds configured dry limits")
  check(pity.epic_dry==epic_dry and pity.legendary_dry==legendary_dry,"persistent counters match independent observed draw history exactly")
  if i%5==0:
   var unchanged=pity.duplicate();Pity.roll("defeat",rng,pity)
   check(pity==unchanged,"Consolation draw cannot advance/reset Victory-only counters")
func fixture(outcome="victory",eligible=true):
 serial+=1
 var p=Support.profile(prefix+str(serial)+".json")
 p.pending_spins=[];p.item_loadout=[];p.reward_rng.seed=95173
 p.replay.pity={"epic_dry":Pity.EPIC_LIMIT-1,"legendary_dry":Pity.LEGENDARY_LIMIT-1}
 var entry=p.begin_match("standard","stage_1",true)
 var m=MatchModel.new();m.configure_match("standard",RankCatalog.bonuses(entry.equipped));m.configure_stage("stage_1")
 m.configure_strategy(int(p.statistics.matches),entry.archetype,entry.contract,entry.id)
 m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();m.time=m.preparation+25;m.bot_claimed=5
 var r=m.player();r.occupied_seconds=25 if outcome=="victory" else 90 if eligible else 0
 m.hunter.boss_policy.enabled=false;m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.position=r.door_approach();m.hunter.cooldown=100
 if outcome=="victory":
  check(m.buy("turret",Support.nearest_pad(r,m.hunter.position)),"real terminal fixture buys an in-range turret")
  m.hunter.hp=1
 else:
  if eligible:r.damage_dealt=100
  r.door_hp=1;m.hunter.cooldown=0;m.hunter.archetype_primed=true;m.hunter.encounter_attacks=1
 for i in range(400):
  m.tick(.1)
  if m.result!="":break
 check(m.result==outcome and m.strategy.verified(m,entry),"real combat terminal path seals campaign result")
 return {"p":p,"m":m,"id":entry.id}
func transactions():
 var a=fixture();var p=a.p;var before=p._reward_snapshot();var rng=p.reward_rng.state;var path=p.path
 p.path=prefix+"missing/not-created.json"
 check(p.settle_match(a.id,a.m).is_empty() and p._reward_snapshot()==before and p.reward_rng.state==rng,"failed save restores pity/rolled inventory/receipt/rewards and reward RNG")
 p.path=path
 var control=fixture();var expected=control.p.settle_match(control.id,control.m)
 var award=p.settle_match(a.id,a.m)
 check(not award.is_empty() and award==expected and p.inventory==control.p.inventory and p.replay.pity==control.p.replay.pity,"retry uses exact original deterministic roll and complete transaction")
 check(p.replay.pity.legendary_dry==0 and p.replay.pity.epic_dry==0 and ItemCatalog.legendary(str(p.pending_spins[0].item)),"guaranteed Legendary saved with reset counters and pending rolled receipt")
 check(p.pending_spins[0].get("odds","")==Pity.summary("victory",{"epic_dry":Pity.EPIC_LIMIT-1,"legendary_dry":Pity.LEGENDARY_LIMIT-1}) and p.pending_spins[0].odds!=Pity.summary("victory",p.replay.pity),"receipt preserves actual guarantee draw-time odds rather than reset next-draw odds")
 var snapshot=p._reward_snapshot();rng=p.reward_rng.state
 check(p.settle_match(a.id,a.m).is_empty() and p._reward_snapshot()==snapshot and p.reward_rng.state==rng,"duplicate result cannot draw again or advance pity")
 var reopened=PlayerProfile.new(p.path);check(reopened.load_profile(),"rolled reward and pity reopen")
 var saved_inventory=reopened.inventory.duplicate(true);var saved_pity=reopened.replay.pity.duplicate(true)
 var revealed=reopened.claim_spin(a.id)
 print("REPLAY_PITY_REVEAL readonly=",reopened.read_only," warning=",reopened.warning," reward=",revealed," inventory_same=",reopened.inventory==saved_inventory," pity_same=",reopened.replay.pity==saved_pity)
 check(not revealed.is_empty() and reopened.inventory==saved_inventory and reopened.replay.pity==saved_pity,"revealing already-rolled spin consumes receipt only")
 check(reopened.claim_spin(a.id).is_empty() and reopened.inventory==saved_inventory and reopened.replay.pity==saved_pity,"reload/reveal cannot grant/roll duplicate reward")
 a=fixture("defeat",true);before=a.p.replay.pity.duplicate(true)
 award=a.p.settle_match(a.id,a.m)
 check(not award.is_empty() and a.p.pending_spins.size()==1 and a.p.replay.pity==before,"eligible genuine Consolation preserves Victory pity counters")
 a=fixture("defeat",false);before=a.p.replay.pity.duplicate(true);var stock=a.p.inventory.duplicate(true)
 award=a.p.settle_match(a.id,a.m)
 check(not award.is_empty() and a.p.pending_spins.is_empty() and a.p.replay.pity==before and a.p.inventory==stock,"quick low-contribution loss cannot progress pity or create a spin")
func run():
 tables();transactions();Support.cleanup(prefix)
 print("REPLAY_PITY_CHECKS=",checks," VICTORY_DRAWS=6000 FAILURES=",failures)
 quit(0 if failures==0 else 1)
