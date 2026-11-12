extends SceneTree
const Support=preload("res://tests/replay_test_support.gd")
var checks=0
var failures=0
var serial=0
var prefix="user://replay-facts-"+str(Time.get_ticks_usec())+"-"
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("REPLAY FACTS: "+label)
func genuine_defeat():
 var p=Support.profile(prefix+"actual.json");p.pending_spins=[];p.item_loadout=["shield","repair"]
 for seed_value in range(1,10000):
  var rng=RandomNumberGenerator.new();rng.seed=seed_value
  if ItemCatalog.roll("defeat",rng)=="shield":p.reward_rng.seed=seed_value;break
 var entry=p.begin_match("standard","stage_1",true)
 var m=MatchModel.new();m.configure_match("standard",RankCatalog.bonuses(entry.equipped));m.configure_stage("stage_1");m.configure_strategy(int(p.statistics.matches),entry.archetype,entry.contract,entry.id)
 p.bind_items(m,entry.id);m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();m.bot_claimed=5;m.time=m.preparation+.1;m.player().occupied_seconds=90
 var h=m.hunter;h.boss_policy.enabled=false;h.state=HunterState.State.ATTACK;h.target=0;h.position=m.player().door_approach();h.cooldown=0
 var unused={"shield":p.inventory.shield,"repair":p.inventory.repair}
 for i in range(1600):
  m.tick(.05)
  if m.result!="":break
 check(m.result=="defeat" and m.terminal_recorded and not m.player().alive,"actual warned strikes/breach/bed contact produce legitimate defeat")
 var facts=m.defeat_facts.report.duplicate(true)
 check(not facts.is_empty() and facts.unused==unused,"unused equipped stock captured before settlement or consolation loot")
 check(facts.source==m.defeat_facts.last_source and facts.archetype==h.archetype and facts.reaper==h.transformed,"final source/archetype are actual encounter facts")
 check(facts.gold==m.player().gold and facts.power==m.player().electricity and facts.damage==m.player().door_damage_taken and facts.repairs==m.player().repair_actions and facts.elapsed==m.time,"resource/HP-damage/repair/time report equals actual terminal model")
 check(facts.sequence.size()<=16 and facts.sequence.any(func(e):return e.type=="door_break") and facts.sequence[-1].type=="elimination","bounded real death sequence includes actual breach and elimination")
 check(facts.tips.size()<=2,"optional analysis limits advice to two tips")
 for tip in facts.tips:
  if tip.contains("equipped"):check(unused.shield>0 or unused.repair>0,"item advice references genuinely equipped remaining stock")
  if tip.contains("next door upgrade"):check(m.player().door_level<4 and m.player().gold>=Catalog.DOOR_COST[m.player().door_level] and m.player().electricity>=Catalog.DOOR_POWER[m.player().door_level] and m.player().bed_level>=maxi(0,m.player().door_level-1),"upgrade advice uses real budget/prerequisite and never level6 door")
 var award=p.settle_match(entry.id,m)
 check(not award.is_empty() and p.pending_spins[0].item=="shield" and p.inventory.shield==unused.shield+1,"actual later consolation loot changes same item's stock")
 check(m.defeat_facts.report==facts and m.defeat_facts.report.unused.shield==unused.shield,"loot cannot retroactively inflate reported unused stock")
 var fake=MatchModel.new();fake.result="defeat";fake.defeat_facts.capture(fake)
 check(fake.defeat_facts.report.is_empty(),"unrecorded handwritten result cannot invent legitimate defeat analysis")
func cosmetic_transactions():
 var p=PlayerProfile.new(prefix+"new.json");check(p.save_profile(),"fresh cosmetic profile saves")
 var before=p._reward_snapshot()
 for id in CosmeticCatalog.ITEMS:
  check(not CosmeticCatalog.earned(p,id) and not p.equip_cosmetic(id) and p._reward_snapshot()==before,"unearned cosmetic cannot equip/spend/unlock: "+id)
 var earned=Support.profile(prefix+"earned.json")
 check(CosmeticCatalog.earned(earned,"iron_gate") and CosmeticCatalog.earned(earned,"reaper_crest"),"real prior campaign/Reaper completion records earn eligible cosmetics")
 check(not CosmeticCatalog.earned(earned,"coil_crown") and not CosmeticCatalog.earned(earned,"canopy"),"campaign progress cannot invent Endless milestone cosmetics")
 var cash=earned.rm_cash;var xp=earned.xp;var stock=earned.inventory.duplicate(true)
 for id in ["iron_gate","reaper_crest"]:
  var path=earned.path;earned.path=prefix+"missing/not-created.json";var old=earned.replay.cosmetics.duplicate(true)
  check(not earned.equip_cosmetic(id) and earned.replay.cosmetics==old,"failed cosmetic save rolls back equipped appearance")
  earned.path=path;check(earned.equip_cosmetic(id),"genuinely earned appearance equips")
 check(earned.rm_cash==cash and earned.xp==xp and earned.inventory==stock,"equipping appearance has zero economic/stat reward")
 var reopened=PlayerProfile.new(earned.path)
 check(reopened.load_profile() and not reopened.read_only and reopened.replay.cosmetics==earned.replay.cosmetics,"equipped appearances persist")
 # Cosmetics never enter model boosts, room multipliers, actual projectiles or RNG.
 var base=MatchModel.new();base.reset(31);base.configure_match("hell",RankCatalog.bonuses(earned.equipped));base.configure_stage("stage_1");base.configure_strategy(5,"crusher");base.claim_room(0);base.player_position=base.player().bed_position();base.sleep_player()
 var signature=Support.model_signature(base)
 check(earned.equip_cosmetic("iron_gate") and earned.equip_cosmetic("reaper_crest") and Support.model_signature(base)==signature,"appearance selection leaves every observed live model statistic/RNG unchanged")
func run():
 genuine_defeat();cosmetic_transactions();Support.cleanup(prefix)
 print("REPLAY_FACTS_COSMETIC_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
