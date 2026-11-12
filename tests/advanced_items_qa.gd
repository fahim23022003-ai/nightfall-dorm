extends SceneTree
# Independent fixed-case transactions/combat fixtures; injected currency is not balance evidence.
var checks=0
var failures=0
var serial=0
var prefix="user://advanced-qa-"
const NEW=["barricade","feather","inferno","pillow","coupon","decoy","rescue","smoke"]
const OLD=["repair","gold","battery","radar","shield","overdrive","frost","trap"]
func _initialize():
 prefix+=str(Time.get_ticks_usec())+"-"
 call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("ADVANCED QA: "+label)
func fresh():
 serial+=1
 return PlayerProfile.new(prefix+str(serial)+".json")
func fixture(mode="standard",stage="stage_5"):
 var m=MatchModel.new()
 m.configure_match(mode)
 m.configure_stage(stage)
 m.claim_room(0)
 m.player_position=m.player().bed_position()
 m.sleep_player()
 m.bot_claimed=5
 m.time=m.preparation+100
 var r=m.player()
 r.occupied_seconds=100
 r.gold=10000;r.electricity=10000
 r.door_level=4;r.door_hp=r.max_hp()
 m.hunter.state=HunterState.State.ATTACK
 m.hunter.target=0;m.hunter.position=r.door_approach()
 m.hunter.boss_policy.enabled=false;m.hunter.tick(.01,m);m.hunter.cooldown=100
 r.door_hp=r.max_hp()
 return m
func actor(m,items):
 var p=fresh()
 for id in items:p.inventory[id]=3
 p.item_loadout=items.duplicate()
 var entry=p.begin_match(m.difficulty)
 p.bind_items(m,entry.id)
 return {"p":p,"id":entry.id}
func use(a,m,slot=0,target=-1):return a.p.activate_item(slot,m,a.id,target)
func cleanup():
 var d=DirAccess.open("user://")
 if d:
  for file in d.get_files():
   if file.begins_with(prefix.trim_prefix("user://")):DirAccess.remove_absolute("user://"+file)
func run():
 check(ItemCatalog.IDS.size()==20,"all20 registered")
 for id in OLD+NEW:
  check(id in ItemCatalog.IDS and ItemCatalog.ITEMS.has(id),"registered "+id)
  check(ResourceLoader.exists("res://assets/items/"+id+".svg"),"originalicon "+id)
 for outcome in ["victory","defeat"]:
  var weights=ItemCatalog.TABLES[outcome]
  check(weights.size()==20,"exact20probabilities")
  var sum=0
  var rarities={"Common":0,"Rare":0,"Epic":0,"Legendary":0}
  for i in range(20):sum+=weights[i];rarities[ItemCatalog.ITEMS[ItemCatalog.IDS[i]].rarity]+=weights[i]
  check(sum==(1000 if outcome=="victory" else 4000),"integer weight sum")
  check(rarities==({"Common":400,"Rare":400,"Epic":160,"Legendary":40} if outcome=="victory" else {"Common":3200,"Rare":640,"Epic":120,"Legendary":40}),"documentedraritydistribution "+outcome)
  var rng=RandomNumberGenerator.new();rng.seed=775
  var second=RandomNumberGenerator.new();second.seed=775
  var reached={}
  for i in range(2000):
   var id=ItemCatalog.roll(outcome,rng)
   check(id==ItemCatalog.roll(outcome,second) and id in ItemCatalog.IDS,"seeded implemented reward")
   reached[id]=true
  check(reached.size()==20,"seed sweep reaches all20")
 # Migrate existing8item inventories and queued receipts without changing them.
 var legacy=fresh()
 for id in OLD:legacy.inventory[id]=7
 legacy.item_loadout=["gold","shield"]
 legacy.xp=3800;legacy.equipped=["first_aid"]
 legacy.next_match_id=4
 legacy.pending_spins=[{"match_id":2,"item":"repair","result":"victory","quantity":4}]
 check(legacy.save_profile(),"legacy8inventory fixture saves")
 var reload=PlayerProfile.new(legacy.path)
 check(reload.load_profile() and reload.xp==3800 and reload.equipped==["first_aid"],"legacyrankperk preserved")
 for id in OLD:check(reload.inventory[id]==7,"oldstock preserved "+id)
 check(reload.pending_spin().item=="repair" and int(reload.pending_spin().quantity)==4,"old predeterminedreceipt preserved")
 check(not reload.claim_spin(2).is_empty() and reload.inventory.repair==7,"oldreveal cannotregrant")
 # Reduced-effects preference is additive, persisted and leaves old settings intact.
 check(reload.update_setting("reduced_effects",true),"reducedeffects setting saves")
 var settings_disk=PlayerProfile.new(reload.path)
 check(settings_disk.load_profile() and settings_disk.settings.reduced_effects and settings_disk.equipped==["first_aid"],"reducedeffects persists alongside perks")
 # Actual mitigation, shielding order, timers and all-mode/all-map compatibility.
 for mode in ["standard","hard","hell"]:
  for stage in StageCatalog.STAGES:
   var m=fixture(mode,stage.id)
   var a=actor(m,["barricade","shield"])
   var r=m.player()
   check(use(a,m),"barricade valid "+mode+stage.id)
   check(a.p.inventory.barricade==2,"barricade oneconsume")
   var hp=r.door_hp
   m.hunter._damage_door(r,m,100)
   check(is_equal_approx(hp-r.door_hp,75),"actual25percentmitigation")
   check(not use(a,m) and a.p.inventory.barricade==2,"barricade cannotrefreshsameframe")
   m.items.tick(1.01,m)
   check(use(a,m,1),"shield combines")
   var shield=m.items.shield_hp
   hp=r.door_hp;m.hunter._damage_door(r,m,100)
   check(r.door_hp==hp and is_equal_approx(shield-m.items.shield_hp,75),"mitigation before shield absorption")
   m.items.tick(21,m)
   hp=r.door_hp;m.hunter._damage_door(r,m,100)
   check(is_equal_approx(hp-r.door_hp,100),"mitigationandshieldexpire")
   # Pillow actual income, inactive beds and expiry.
   m=fixture(mode,stage.id);a=actor(m,["pillow"]);r=m.player()
   var baseline=r.income_rate();var gold=r.gold
   check(use(a,m),"pillow activation")
   m.tick(2)
   check(is_equal_approx(r.gold-gold,baseline*3),"income actual1.5factor")
   r.sleeping=false;gold=r.gold;r.tick_economy(2)
   check(r.gold==gold,"pillow cannotpayinactivebed")
   r.sleeping=true;m.items.tick(26,m)
   check(is_equal_approx(r.income_rate(),baseline),"pillow expiry restores income")
   # Rescue requires explicit eligible teammate and heals exact25percent.
   m=fixture(mode,stage.id);a=actor(m,["rescue"])
   check(not use(a,m) and a.p.inventory.rescue==3,"no validselectedteammate no consumption")
   var friend=m.rooms[1];friend.owner=1;friend.sleeping=true;friend.closed=true
   friend.door_hp=friend.max_hp()*.5
   hp=friend.door_hp
   check(use(a,m,0,1),"selected validteammate rescue")
   check(is_equal_approx(friend.door_hp-hp,friend.max_hp()*.25) and a.p.inventory.rescue==2,"rescue exactheal oneconsume")
   m.items.tick(1.01,m);friend.alive=false
   check(not use(a,m,0,1) and a.p.inventory.rescue==2,"eliminatedteammate cannotrescue")
 # Coupon successful real purchase/upgrade ledger and separate currencies/refund.
 for upgrade in [false,true]:
  var m=fixture();var a=actor(m,["coupon"]);var r=m.player()
  if upgrade:check(r.build("turret",0),"preexistingbuilding purchase")
  var stock=a.p.inventory.coupon
  check(use(a,m),"coupon arms")
  check(a.p.inventory.coupon==stock,"coupon arming consumesnothing")
  var paid_g=r.gold;var paid_e=r.electricity
  var list_g=float(Catalog.BUILDINGS.turret.gold)
  var list_e=float(Catalog.BUILDINGS.turret.power+3 if upgrade else Catalog.BUILDINGS.turret.power)
  var old_g=float(r.buildings[0].invested_gold) if upgrade else 0.0
  var old_e=float(r.buildings[0].invested_power) if upgrade else 0.0
  check(r.upgrade_building(0) if upgrade else r.build("turret",0),"valid coupon transaction")
  check(is_equal_approx(paid_g-r.gold,list_g*.6) and is_equal_approx(paid_e-r.electricity,list_e*.6),"40percent actualcurrencydiscount")
  check(a.p.inventory.coupon==stock-1,"coupon consumesonsuccessonly")
  check(is_equal_approx(r.buildings[0].invested_gold,old_g+list_g*.6) and is_equal_approx(r.buildings[0].invested_power,old_e+list_e*.6),"actualeligibleinvestment ledger")
  var refund=r.building_refund(0)
  check(is_equal_approx(refund.x,(old_g+list_g*.6)*.5) and is_equal_approx(refund.y,(old_e+list_e*.6)*.5),"refundhalfactualpaid bothcurrencies")
  paid_g=r.gold;paid_e=r.electricity
  check(r.sell_building(0) and is_equal_approx(r.gold-paid_g,refund.x) and is_equal_approx(r.electricity-paid_e,refund.y),"actualsale correct")
  check(not r.sell_building(0),"nodouble refund")
 var m=fixture();var a=actor(m,["coupon"]);var r=m.player()
 check(use(a,m),"failedpurchase coupon armed")
 check(not r.build("turret",-1) and a.p.inventory.coupon==3,"invalidtile no coupon loss")
 var initial_gold=r.gold;var initial_power=r.electricity;r.gold=0;r.electricity=0
 check(not r.build("turret",0) and a.p.inventory.coupon==3 and r.coupon_armed,"insufficientfunds preserve armedcoupon")
 r.gold=initial_gold;r.electricity=initial_power
 var original=a.p.path;a.p.path="user://nonexistent-advanced-dir/profile.json"
 var gold=r.gold;var power=r.electricity
 check(not r.build("turret",0),"couponfailedsave blocks purchase")
 check(r.gold==gold and r.electricity==power and not r.buildings.has(0) and a.p.inventory.coupon==3,"failedsave full accountingrollback")
 a.p.path=original
 check(r.build("turret",0) and a.p.inventory.coupon==2,"couponretry once")
 # Automatic Feather: crossing intact threshold, once, save-before-heal and no revival.
 m=fixture();a=actor(m,["feather"]);r=m.player()
 check(not use(a,m) and a.p.inventory.feather==3,"feather cannotbe manually consumed")
 r.door_hp=r.max_hp()*.3
 var expected=r.door_hp-r.max_hp()*.1+r.max_hp()*.15
 m.hunter._damage_door(r,m,r.max_hp()*.1)
 check(is_equal_approx(r.door_hp,expected) and a.p.inventory.feather==2,"feather heals15percent on validcross")
 r.door_hp=r.max_hp()*.3;m.hunter._damage_door(r,m,r.max_hp()*.1)
 check(a.p.inventory.feather==2,"feather onlyoncepermatch")
 m=fixture();a=actor(m,["feather"]);r=m.player();r.door_hp=1
 m.hunter._damage_door(r,m,100)
 check(r.door_hp==0 and a.p.inventory.feather==3,"feather cannotrevivebroken door")
 m=fixture();a=actor(m,["feather"]);r=m.player();r.door_hp=r.max_hp()*.3
 a.p.path="user://nonexistent-advanced-dir/feather.json"
 m.hunter._damage_door(r,m,r.max_hp()*.1)
 check(is_equal_approx(r.door_hp,r.max_hp()*.2) and a.p.inventory.feather==3,"failedsavedoesnotconsumeorheal feather")
 # One coupon never discounts a second purchase; heavy currency costs remain fractional/exact.
 m=fixture();a=actor(m,["coupon"]);r=m.player();r.bed_level=1
 check(use(a,m) and not use(a,m),"coupon arm cannotduplicate")
 gold=r.gold;power=r.electricity
 check(r.build("heavy",0),"couponheavy purchase")
 check(is_equal_approx(gold-r.gold,Catalog.BUILDINGS.heavy.gold*.6) and is_equal_approx(power-r.electricity,Catalog.BUILDINGS.heavy.power*.6),"couponheavy bothresource discount")
 gold=r.gold;power=r.electricity
 check(r.build("heavy",1),"secondbuilding valid")
 check(is_equal_approx(gold-r.gold,Catalog.BUILDINGS.heavy.gold) and is_equal_approx(power-r.electricity,Catalog.BUILDINGS.heavy.power) and a.p.inventory.coupon==2,"secondpurchase fullprice no secondconsume")
 # Golden Pillow integration is step-size independent and ends after exactly25s.
 for dt in [.1,.5,1.0,30.0]:
  m=fixture();a=actor(m,["pillow"]);r=m.player();var initial_income=r.income_total
  var base=r.income_rate();check(use(a,m),"pillowstepfixture")
  var elapsed=0.0
  while elapsed<30-.0001:
   var step=minf(dt,30-elapsed);m.tick(step);elapsed+=step
  check(is_equal_approx(r.income_total-initial_income,base*42.5),"pillowexact25windowdt"+str(dt))
 # Feather threshold boundaries and interaction with the existing Last Light perk.
 for initial_delta in [0.0,1.0]:
  m=fixture();a=actor(m,["feather"]);r=m.player();r.door_hp=r.max_hp()*.25+initial_delta
  m.hunter._damage_door(r,m,1)
  check(a.p.inventory.feather==(3 if initial_delta==0 else 2),"feather requires downward crossing")
 m=fixture();a=actor(m,["feather"]);r=m.player();r.rescue_fraction=.1;r.door_hp=r.max_hp()*.3
 m.hunter._damage_door(r,m,r.max_hp()*.25)
 check(is_equal_approx(r.door_hp,r.max_hp()*.3) and r.rescue_used and a.p.inventory.feather==2,"Feather and LastLight eachtriggeronce boundedcombinedheal")
 # Inferno must originate at owned impacts, refresh one bounded burn, and respect resistance.
 for boss in [false,true]:
  m=fixture();a=actor(m,["inferno","overdrive"]);r=m.player()
  r.build("turret",0)
  check(use(a,m),"inferno actual activation")
  m.hunter.hp=5000;m.hunter.transformed=boss
  m.projectiles=[{"id":1,"from":m.hunter.position,"position":m.hunter.position,"target_id":1,"damage":10.0,"speed":200.0,"kind":"turret","room":0,"level":1,"age":0.0}]
  m._advance_projectiles(.1)
  check(m.items.burn_remaining>0,"owned projectile ignites Hunter")
  for i in range(100):m.items.ignite(m,0)
  var hp=m.hunter.hp
  m.items.tick(4,m)
  var expected_burn=ItemCatalog.TUNING.burn_dps*4*(ItemCatalog.TUNING.burn_boss_factor if boss else 1.0)
  check(is_equal_approx(hp-m.hunter.hp,expected_burn),"single bounded burn no100foldstack")
  hp=m.hunter.hp;m.items.tick(10,m)
  check(m.hunter.hp==hp,"expired burn stopsdamage")
  m.items.ignite(m,1)
  check(m.items.burn_remaining==0,"teammate attacks cannotignite ownedbuff")
 # AI disruptions stay navigable, bounded and cannot chain or remove the last target.
 for stage in StageCatalog.STAGES:
  for effect in ["decoy","smoke"]:
   m=fixture("hell",stage.id);a=actor(m,[effect,"smoke" if effect=="decoy" else "decoy"])
   m.hunter.transformed=true
   var second_room=m.rooms[1];second_room.owner=1;second_room.sleeping=true;second_room.closed=true
   check(use(a,m),"control usable "+effect+stage.id)
   var maximum=4.0 if effect=="decoy" else 3.0
   check(m.items.timers[effect]<=maximum,"Reaper control resistance")
   m.items.tick(1.1,m)
   check(not use(a,m,1) and a.p.inventory[a.p.active_match.items[1]]==3,"shared recovery preventscontrolchain")
   for i in range(180):
    var before=m.hunter.position
    m.tick(.05)
    check(m.hunter.position.distance_to(before)<=m.hunter.speed*.05+.2,"control no teleport")
    check(m.navigation_walkable(m.hunter.position),"control navigation stayswalkable")
    if m.result!="":break
   check(not m.items.timers.has(effect),"control expires "+effect)
  m=fixture("hell",stage.id);a=actor(m,["smoke"])
  check(use(a,m),"lastroom smoke valid")
  var attacks=m.hunter.attacks;m.hunter.cooldown=0
  m.hunter.tick(.1,m)
  check(m.hunter.target==0 and m.hunter.attacks>attacks,"lastroom remainsattackable")
 # Large-step Pillow integration must earn exactly25 boosted seconds, not zero/all30.
 m=fixture();a=actor(m,["pillow"]);r=m.player();r.gold=0
 var base_rate=r.income_rate()
 check(use(a,m),"integration pillow")
 m.tick(30)
 check(is_equal_approx(r.income_total,base_rate*(30+25*.5)),"pillow actual25second window even30sstep")
 print("ADVANCED_QA_CHECKS=",checks," FAILURES=",failures)
 cleanup();quit(0 if failures==0 else 1)
