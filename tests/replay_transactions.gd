extends "res://tests/replay_endless.gd"
# Parent supplies real paid model/profile fixtures, not reward or snapshot mocks.
func durable_caps():
 var a=fixture("abandoned_dorm","standard",71,["coupon","time_freeze"]);var p=a.p;var m=a.m
 check(m.buy("turret",Support.nearest_pad(m.player(),m.player().door_approach())),"coupon fixture first pays weapon without spending coupon")
 check(p.activate_item(0,m,a.id) and m.player().coupon_armed,"combat may arm coupon for a later purchase")
 clear_wave(a)
 check(m.player().coupon_armed,"checkpoint retains legitimately armed unspent coupon")
 check(p.checkpoint_endless(m),"valid between-wave checkpoint commits")
 var snapshot=p.replay.checkpoint.duplicate(true);var stock=p.inventory.duplicate(true)
 check(m.continue_wave("power"),"continue preserves run identity")
 m.time=m.preparation+.1;m.items.tick(1.1,m)
 check(m.buy("generator",Support.nearest_pad(m.player(),m.player().door_approach())) and p.inventory.coupon==stock.coupon-1,"post-checkpoint discounted purchase consumes real coupon exactly once")
 m.hunter.state=HunterState.State.MOVE;m.hunter.target=0
 check(p.activate_item(1,m,a.id) and p.inventory.time_freeze==stock.time_freeze-1,"post-checkpoint Legendary genuinely consumes stock")
 var current=p.inventory.duplicate(true);var loaded=PlayerProfile.new(p.path)
 check(loaded.load_profile() and not loaded.read_only,"durable inventory/use ledger reopens with older checkpoint")
 var resumed=loaded.resume_endless()
 check(resumed!=null,"safe checkpoint resumes same run")
 if resumed==null:return
 check(loaded.inventory==current and resumed.items.legendary_used==1 and not resumed.player().coupon_armed,"resume cannot restore inventory, reset Legendary cap or rearm already-consumed coupon")
 check(not loaded.activate_item(1,resumed,a.id) and loaded.inventory==current,"old checkpoint cannot buy a second Legendary")
 check(resumed.continue_wave("repair"),"resumed wave explicitly starts")
 var wallet=[resumed.player().gold,resumed.player().electricity]
 check(resumed.buy("generator",Support.nearest_pad(resumed.player(),resumed.player().door_approach())) and absf(wallet[0]-resumed.player().gold-30)<.00001 and loaded.inventory==current,"consumed-checkpoint coupon cannot grant another discounted purchase")
 var stale=resumed;var before_hop=loaded._reward_snapshot()
 check(loaded.begin_match("standard","stage_1",true).is_empty() and loaded._reward_snapshot()==before_hop and loaded.resume_endless()!=null,"campaign cannot silently replace resumable Endless use ledger")
 check(loaded.forfeit_endless() and loaded.active_match.is_empty() and loaded.replay.checkpoint.is_empty() and loaded.inventory==current,"explicit forfeit clears old resume but cannot refund spent items")
 var campaign=loaded.begin_match("standard","stage_1",true)
 check(not campaign.is_empty() and loaded.resume_endless()==null,"campaign starts after explicit forfeit without parallel resume")
 var before=loaded._reward_snapshot()
 check(not loaded.checkpoint_endless(stale) and loaded._reward_snapshot()==before,"superseded model cannot rewrite checkpoint or claim run rewards")
 var next=loaded.begin_endless("haunted_hospital","hard",911)
 check(not next.is_empty() and int(next.run_id)>a.id and loaded.replay.checkpoint.is_empty(),"New Endless uses fresh monotonic identity and clears prior checkpoint")
 loaded.replay.checkpoint=snapshot
 check(loaded.resume_endless()==null,"valid old snapshot cannot substitute for a new run/map/seed")
func automatic_caps():
 var a=fixture("abandoned_dorm","standard",27,["feather"],["first_aid","reinforced"]);var p=a.p;var m=a.m;var r=m.player()
 clear_wave(a);check(p.checkpoint_endless(m),"automatic-use fixture checkpoints before rescue")
 check(m.continue_wave("power"),"automatic-use fixture continues")
 var stock=p.inventory.feather
 r.door_hp=r.max_hp()*.25+1;m.hunter.target=0;m.hunter.state=HunterState.State.ATTACK;m.hunter.position=r.door_approach()
 m.hunter._damage_door(r,m,2)
 check(m.items.feather_used and p.active_match.feather_used and p.inventory.feather==stock-1,"real critical crossing consumes Feather and durably marks it once")
 r.door_hp=r.max_hp()*.25+1;m.hunter._damage_door(r,m,2)
 check(r.rescue_used and p.active_match.rescue_used and p.inventory.feather==stock-1,"later real crossing durably uses rank rescue without another Feather")
 var loaded=PlayerProfile.new(p.path);check(loaded.load_profile() and not loaded.read_only,"automatic use flags reopen")
 var resumed=loaded.resume_endless()
 check(resumed!=null and resumed.items.feather_used and resumed.player().rescue_used and loaded.inventory.feather==stock-1,"older checkpoint cannot reset either automatic once-per-run use")
 if resumed!=null:
  resumed.player().door_hp=resumed.player().max_hp()*.2;var hp=resumed.player().door_hp
  check(not resumed.player().try_rescue() and resumed.player().door_hp==hp,"checkpoint rewind cannot create infinite rank healing")
 # Actual Game adopts/binds its model before the player claims any room.
 # An empty loadout must not need a later manual item activation to bind rescue.
 a=fixture("abandoned_dorm","standard",91,[],["first_aid","reinforced"],true);p=a.p;m=a.m;r=m.player()
 check(r.rescue_payment.is_valid(),"claim after pre-room Game bind installs durable rank-rescue callback")
 clear_wave(a);check(p.checkpoint_endless(m),"actual pre-claim binding flow checkpoints")
 check(m.continue_wave("power"),"actual pre-claim binding flow continues")
 r.door_hp=r.max_hp()*.25+1;m.hunter.target=0;m.hunter.state=HunterState.State.ATTACK;m.hunter.position=r.door_approach();m.hunter._damage_door(r,m,2)
 check(r.rescue_used and p.active_match.rescue_used,"empty-loadout rank rescue durably marks once without any manual item activation")
func milestone_transactions():
 var a=fixture();var p=a.p;var m=a.m
 var initial_cash=p.rm_cash;var initial_xp=p.xp;var statistics=p.statistics.duplicate(true);var records=p.campaign_records.duplicate(true);var inventory=p.inventory.duplicate(true)
 var max_bytes=0
 for wave in range(1,26):
  if wave>1:
   check(m.continue_wave("supply"),"stress wave continues exactly once")
   m.time=m.preparation+.1
  clear_wave(a)
  if wave==5:
   var before=p._reward_snapshot();var rng=p.reward_rng.state;var path=p.path;p.path=prefix+"missing/not-created.json"
   check(not p.checkpoint_endless(m) and p._reward_snapshot()==before and p.reward_rng.state==rng,"failed milestone save rolls back checkpoint/best/cash/XP/claims/RNG")
   p.path=path
  check(p.checkpoint_endless(m),"real wave checkpoint commits deterministic milestone transaction")
  var earned=mini(4,int(wave/5))
  check(p.rm_cash==initial_cash+8*earned and p.xp==initial_xp+20*earned,"only four once-only documented global milestones pay8RM/20XP")
  var cash=p.rm_cash;var xp=p.xp
  check(p.checkpoint_endless(m) and p.rm_cash==cash and p.xp==xp,"same cleared-wave checkpoint cannot duplicate milestone payout")
  check(p.statistics==statistics and p.campaign_records==records and p.inventory==inventory and p.pending_spins.is_empty(),"Endless does not manufacture campaign wins/stages/item stacks/spins")
  check(m.projectiles.size()<=Catalog.PROJECTILES.max_active and m.presentation_events.size()<=128 and m.combat_events.size()<=Catalog.PROJECTILES.max_events,"long-session combat buffers stay bounded")
  var bytes=FileAccess.get_file_as_bytes(p.path).size();max_bytes=maxi(max_bytes,bytes)
  check(bytes<65536,"checkpoint/profile size remains bounded rather than appending wave history")
 check(p.replay.best_wave==25 and p.replay.milestone_wave==20,"current best and claimed milestone remain distinct")
 print("REPLAY_STRESS_WAVES=25 MAX_SAVE_BYTES=",max_bytes)
 var loaded=PlayerProfile.new(p.path);check(loaded.load_profile() and not loaded.read_only and loaded.replay.best_wave==25,"long checkpoint reopens exact bounded progress")
 var resumed=loaded.resume_endless();check(resumed!=null,"long checkpoint restores")
 if resumed!=null:
  check(resumed.continue_wave("repair"),"long checkpoint continues")
  var r=resumed.player();r.buildings.clear();r.door_hp=1;resumed.time=resumed.preparation+.1
  resumed.hunter.state=HunterState.State.ATTACK;resumed.hunter.position=r.door_approach();resumed.hunter.target=0;resumed.hunter.cooldown=0;resumed.hunter.archetype_primed=true;resumed.hunter.encounter_attacks=1
  for i in range(1000):
   resumed.tick(.1)
   if resumed.result!="":break
  check(resumed.result=="defeat" and resumed.terminal_recorded,"actual post-resume lethal encounter records terminal defeat")
  var before=loaded._reward_snapshot();var path=loaded.path;loaded.path=prefix+"missing/not-created.json"
  check(loaded.settle_endless(resumed).is_empty() and loaded._reward_snapshot()==before,"failed final save preserves active run for exact retry")
  loaded.path=path;var award=loaded.settle_endless(resumed)
  check(not award.is_empty() and loaded.active_match.is_empty() and loaded.replay.checkpoint.is_empty() and loaded.replay.best_wave==25,"genuine final result closes once while retaining personal best")
  before=loaded._reward_snapshot()
  check(loaded.settle_endless(resumed).is_empty() and loaded._reward_snapshot()==before,"duplicate final result cannot close/pay again")
func exposed_defeat():
 serial+=1;var p=Support.profile(prefix+str(serial)+".json");p.pending_spins=[];p.item_loadout=[]
 var entry=p.begin_endless("abandoned_dorm","standard",101);var m=MatchModel.new();m.configure_endless("abandoned_dorm","standard",101,entry.run_id,RankCatalog.bonuses(entry.equipped))
 var before=p._reward_snapshot();m.result="defeat"
 check(p.settle_endless(m).is_empty() and p._reward_snapshot()==before,"forged unclaimed defeat without terminal evidence rejected")
 m.result="";m.time=m.preparation+26;m.hunter.position=m.player_position;m.tick(.1)
 check(m.player()==null and m.result=="defeat" and m.terminal_recorded and m.eliminations>0,"actual exposed contact can defeat before room claim")
 var cash=p.rm_cash;var xp=p.xp;var inventory=p.inventory.duplicate(true)
 var report=p.settle_endless(m)
 check(not report.is_empty() and p.active_match.is_empty() and p.replay.checkpoint.is_empty() and p.resume_endless()==null,"unclaimed terminal closes run without stuck active/resume state")
 check(p.rm_cash==cash and p.xp==xp and p.inventory==inventory,"unclaimed defeat grants no currency/XP/items")
func run():
 durable_caps();automatic_caps();milestone_transactions();exposed_defeat();Support.cleanup(prefix)
 print("REPLAY_TRANSACTION_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
