extends SceneTree

var checks:=0
var failures:=0
var profile_prefix:="user://survivor-defeat-cash-%d-" % OS.get_process_id()

func _initialize() -> void:
 call_deferred("run")

func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(message)

func profile(label: String) -> PlayerProfile:
 var next:=PlayerProfile.new(profile_prefix+label+".json")
 next.tutorial_completed=true
 check(next.save_profile(),"save clean profile "+label)
 return next

func campaign(p: PlayerProfile,mode: String="standard",level: int=0) -> MatchModel:
 var stage: String=StoryCatalog.mission(level).get("stage_id","") if level>0 else ""
 var entry:=p.begin_match(mode,stage,level>0,level)
 check(not entry.is_empty(),"transactionally begin Campaign/Story match")
 var m:=MatchModel.new()
 if level>0:
  m.reset(int(entry.story.seed))
 m.configure_match(mode,RankCatalog.bonuses(p.equipped))
 if level>0:
  check(m.configure_stage(stage),"configure established Story theme")
  m.story_level=level
  check(m.configure_strategy(int(entry.story.seed),entry.archetype,entry.contract,int(entry.id)),"configure the recorded Story opponent")
 return m

func endless(p: PlayerProfile,label: String="standard") -> MatchModel:
 var entry:=p.begin_endless("abandoned_dorm",label,71)
 check(not entry.is_empty(),"transactionally begin Endless")
 var m:=MatchModel.new()
 check(m.configure_endless("abandoned_dorm",label,71,entry.run_id,RankCatalog.bonuses(p.equipped)),"configure the recorded Endless identity")
 return m

func occupy(m: MatchModel, owner: PlayerProfile, claim: int=0) -> void:
 check(m.claim_room(claim),"claim a real room")
 m.player_position=m.player().bed_position()
 check(m.sleep_player(),"sleep in the occupied bed")
 owner.bind_items(m,int(owner.active_match.id))

func tick_to(m: MatchModel,until: float) -> void:
 for _index in range(2000):
  if m.result!="" or m.time>=until:
   return
  m.tick(.1)

func early_door_loss(m: MatchModel) -> void:
 tick_to(m,m.preparation+.2)
 var room:=m.player()
 # Stage an exposed opening at a nearly destroyed door. The engine owns
 # the actual strike, breach, resident elimination and terminal receipt.
 m.apply_room_damage(room.index,room.door_hp-1.0)
 m.hunter.state=HunterState.State.ATTACK
 m.hunter.position=room.door_approach()
 m.hunter.target=room.index
 m.hunter.cooldown=0.0
 m.hunter.archetype_primed=true
 m.hunter.encounter_attacks=1
 tick_to(m,m.time+30.0)
 check(m.result=="defeat" and m.terminal_recorded and not room.alive and m.eliminations>0,"actual model strike and breach record a terminal loss")

func nonterminal_and_campaign() -> void:
 var p:=profile("campaign")
 var m:=campaign(p)
 var id:=int(p.active_match.id)
 var before:=p._reward_snapshot()
 check(p.settle_match(id,m).is_empty() and p._reward_snapshot()==before,"leaving an unfinished run pays no cash")
 m.result="defeat"
 check(OnboardingCatalog.cash_reward(m,p.reward_rng)==0,"forged result without terminal evidence pays zero")
 m.result=""
 occupy(m,p)
 early_door_loss(m)
 check(m.player().occupied_seconds<90.0,"fixture reproduces real defeat before the old payout gate")
 var expected_xp:=int(RankCatalog.performance(m).total)
 var rng_before: int=p.reward_rng.state
 var path: String=p.path
 before=p._reward_snapshot()
 p.path=profile_prefix+"missing/path.json"
 check(p.settle_match(id,m).is_empty() and p._reward_snapshot()==before and p.reward_rng.state==rng_before,"failed defeat save rolls back cash, rewards, RNG and lease")
 p.path=path
 var report:=p.settle_match(id,m)
 check(report.rm_cash>=6 and report.rm_cash<=14 and report.rm_balance==p.rm_cash,"real early defeat credits bounded permanent cash and reports final balance")
 check(p.xp==expected_xp and p.statistics.defeats==1,"rank XP and defeat count retain existing rules")
 print("CAMPAIGN_EARLY_CASH occupied=",snappedf(m.player().occupied_seconds,.1)," first_award=",report.rm_cash," balance=",report.rm_balance," defeat_xp=",expected_xp)
 check(p.settle_match(id,m).is_empty(),"duplicate Campaign settlement pays zero")
 var loaded:=PlayerProfile.new(path)
 check(loaded.load_profile() and loaded.rm_cash==report.rm_balance,"reload preserves the payout")
 check(loaded.settle_match(id,m).is_empty() and loaded.rm_cash==report.rm_balance,"reopened profile cannot replay a paid settlement")

 var second:=campaign(loaded)
 occupy(second,loaded)
 early_door_loss(second)
 var second_award:=loaded.settle_match(int(loaded.active_match.id),second)
 check(not second_award.is_empty() and loaded.rm_cash>=OnboardingCatalog.PRICES.radar,"two tested early defeats afford a real shop item")
 var cash_before_buy: int=loaded.rm_cash
 var count:=int(loaded.inventory.get("radar",0))
 check(loaded.buy_common("radar",loaded.purchase_serial+1) and loaded.rm_cash==cash_before_buy-OnboardingCatalog.PRICES.radar and int(loaded.inventory.get("radar",0))==count+1,"shop purchase pays exact RM and grants one Radar")
 check(loaded.equip_item("radar") and "radar" in loaded.item_loadout,"purchased Radar is equipped through the profile")
 print("DEFEAT_TO_SHOP second_award=",second_award.rm_cash," price=",OnboardingCatalog.PRICES.radar," balance=",loaded.rm_cash)
 var next:=campaign(loaded)
 occupy(next,loaded)
 tick_to(next,next.preparation+1.0)
 var slot:=loaded.item_loadout.find("radar")
 check(slot>=0 and "radar" in loaded.active_match.items,"next attempt snapshots the paid loadout")
 if slot>=0:
  check(loaded.activate_item(slot,next,int(loaded.active_match.id)) and int(loaded.inventory.get("radar",0))==count,"actual next-attempt Radar use consumes the purchased stock")

func late_caps_and_legacy() -> void:
 var p:=profile("cap")
 p.rm_cash=OnboardingCatalog.MAX_CASH-2
 check(p.save_profile(),"persist near-capped wallet")
 var m:=campaign(p,"hell")
 occupy(m,p)
 early_door_loss(m)
 var room:=m.player()
 room.occupied_seconds=44.99
 room.damage_dealt=199.99
 room.door_damage_taken=0.0
 check(OnboardingCatalog.cash_reward(m,p.reward_rng)==6,"bonuses start at complete time and contribution units")
 room.occupied_seconds=45.0
 room.damage_dealt=200.0
 check(OnboardingCatalog.cash_reward(m,p.reward_rng)==8,"first complete duration and contribution units each add one RM")
 m.tutorial_mode=true
 check(OnboardingCatalog.cash_reward(m,p.reward_rng)==0,"tutorial loss cannot generate permanent cash")
 m.tutorial_mode=false
 m.run_kind="practice"
 check(OnboardingCatalog.cash_reward(m,p.reward_rng)==0,"practice loss cannot generate permanent cash")
 m.run_kind="campaign"
 room.occupied_seconds=600
 room.damage_dealt=4000
 check(OnboardingCatalog.cash_reward(m,p.reward_rng)==14,"time and contribution each cap their cash contribution")
 var report:=p.settle_match(int(p.active_match.id),m)
 check(report.rm_cash==2 and report.rm_balance==OnboardingCatalog.MAX_CASH,"award reports only cash the wallet can actually accept")
 OS.set_environment("NIGHTFALL_SURVIVOR_REBIRTH","0")
 room.occupied_seconds=60
 check(OnboardingCatalog.cash_reward(m,p.reward_rng)==0,"legacy fallback retains the 90-second loss gate")
 room.occupied_seconds=180
 m.time=m.preparation+180
 var old_cash:=OnboardingCatalog.cash_reward(m,p.reward_rng)
 check(old_cash>=4 and old_cash<=6,"legacy fallback retains its original payout bounds")
 OS.set_environment("NIGHTFALL_SURVIVOR_REBIRTH","1")

func story_and_victory() -> void:
 var p:=profile("story")
 check(p.enable_story(),"enable Story on a real profile")
 var m:=campaign(p,"standard",1)
 occupy(m,p)
 tick_to(m,m.preparation+10.2)
 m.hunter.hp=0
 m.tick(.1)
 check(m.result=="victory" and m.terminal_recorded,"actual model victory records terminal result")
 var old_rng: int=p.reward_rng.state
 var preview_reward:=OnboardingCatalog.cash_reward(m,p.reward_rng)
 p.reward_rng.state=old_rng
 OS.set_environment("NIGHTFALL_SURVIVOR_REBIRTH","0")
 var legacy_reward:=OnboardingCatalog.cash_reward(m,p.reward_rng)
 p.reward_rng.state=old_rng
 OS.set_environment("NIGHTFALL_SURVIVOR_REBIRTH","1")
 check(preview_reward==legacy_reward and preview_reward>=24,"victory cash is identical and generally exceeds defeat cash")
 var win:=p.settle_match(int(p.active_match.id),m)
 check(win.story.position==2 and win.story.cleared and StoryProgress.position(p.story,"standard")==2,"victory advances the Story track normally")
 var loss:=campaign(p,"standard",2)
 occupy(loss,p)
 early_door_loss(loss)
 var start_xp: int=p.xp
 var expected_xp:=int(RankCatalog.performance(loss).total)
 var settled:=p.settle_match(int(p.active_match.id),loss)
 check(settled.story.position==1 and not settled.story.cleared and StoryProgress.position(p.story,"standard")==1,"early defeat keeps the normal Story setback")
 check(settled.rm_cash>=6 and p.xp==start_xp+expected_xp,"Story loss pays cash without altering the rank XP formula")

func endless_outcomes() -> void:
 var p:=profile("endless")
 var m:=endless(p)
 occupy(m,p)
 tick_to(m,m.preparation+1.0)
 m.hunter.hp=0
 m.tick(.1)
 check(p.checkpoint_endless(m),"save an actual between-wave checkpoint")
 var reopened:=PlayerProfile.new(p.path)
 check(reopened.load_profile(),"reopen the durable Endless profile")
 var resumed: MatchModel=reopened.resume_endless()
 check(resumed!=null and resumed.continue_wave("repair"),"continue a reloaded Endless run")
 if resumed==null:return
 early_door_loss(resumed)
 var before:=reopened._reward_snapshot()
 var rng_before: int=reopened.reward_rng.state
 var path: String=reopened.path
 reopened.path=profile_prefix+"missing/endless.json"
 check(reopened.settle_endless(resumed).is_empty() and reopened._reward_snapshot()==before and reopened.reward_rng.state==rng_before,"failed Endless loss save keeps checkpoint, cash, XP, stock and lease")
 reopened.path=path
 var report:=reopened.settle_endless(resumed)
 check(report.rm_cash>=6 and report.rm_cash<=14 and report.rm_balance==reopened.rm_cash and report.completed==1,"actual post-resume loss pays once")
 check(reopened.xp==before.xp and reopened.inventory==before.inventory and reopened.statistics==before.statistics,"Endless cash leaves XP, items and Campaign stats untouched")
 print("ENDLESS_RESUMED_CASH completed=",report.completed," award=",report.rm_cash," balance=",report.rm_balance)
 var loaded:=PlayerProfile.new(path)
 check(loaded.load_profile() and loaded.resume_endless()==null and loaded.rm_cash==report.rm_balance and loaded.settle_endless(resumed).is_empty(),"reload cannot reopen or double-pay the settled Endless run")

 var quit_model:=endless(p)
 occupy(quit_model,p)
 var cash: int=p.rm_cash
 check(p.settle_endless(quit_model).is_empty() and p.forfeit_endless() and p.rm_cash==cash,"aborted Endless via real forfeit pays no cash")
 var cleared:=endless(p)
 occupy(cleared,p)
 tick_to(cleared,cleared.preparation+1)
 cleared.hunter.hp=0
 cleared.tick(.1)
 var retirement:=p.end_endless_here(cleared)
 check(retirement.safe_end and retirement.rm_cash==0 and p.rm_cash==cash,"safe retirement does not masquerade as a defeated run")

 var unclaimed:=endless(p)
 unclaimed.time=unclaimed.preparation+26.0
 unclaimed.hunter.position=unclaimed.player_position
 unclaimed.tick(.1)
 check(unclaimed.result=="defeat" and unclaimed.terminal_recorded and unclaimed.player()==null,"actual exposed unclaimed loss reaches terminal state")
 var exposed:=p.settle_endless(unclaimed)
 check(not exposed.is_empty() and exposed.rm_cash==0 and p.rm_cash==cash,"unclaimed contact defeat cannot farm cash")

func run() -> void:
 OS.set_environment("NIGHTFALL_SURVIVOR_REBIRTH","1")
 OS.set_environment("NIGHTFALL_PROCEDURAL_MAPS","0")
 OS.set_environment("NIGHTFALL_PROCEDURAL_MAPS_V2","0")
 OS.set_environment("NIGHTFALL_FULL_ROOM_GRID","0")
 nonterminal_and_campaign()
 late_caps_and_legacy()
 story_and_victory()
 endless_outcomes()
 print("SURVIVOR_DEFEAT_CASH_CHECKS=",checks," FAILURES=",failures)
 quit(int(failures>0))
