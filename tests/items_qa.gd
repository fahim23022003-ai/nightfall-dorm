extends SceneTree
# Independent deterministic Phase5B1 QA. Explicit resource/state setup is a fixture,
# not balance evidence; items_balance.gd uses earned currency and a stated item budget.
var checks=0
var failures=0
var serial=0
var prefix="user://items-qa-"
func _initialize():
 prefix+=str(Time.get_ticks_usec())+"-"
 call_deferred("run")
func check(ok: bool,label: String):
 checks+=1
 if not ok:
  failures+=1
  push_error("ITEM QA: "+label)
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
 m.player().occupied_seconds=100
 m.player().gold=10000
 m.player().electricity=10000
 m.player().door_level=4
 m.player().door_hp=m.player().max_hp()
 m.hunter.state=HunterState.State.ATTACK
 m.hunter.target=0
 m.hunter.position=m.player().door_approach()
 m.hunter.boss_policy.enabled=false
 m.hunter.tick(0.01,m)
 m.hunter.cooldown=100
 m.player().door_hp=m.player().max_hp()
 return m
func terminal(mode="standard",outcome="victory",stage=""):
 var m=MatchModel.new()
 m.configure_match(mode)
 if stage!="":m.configure_stage(stage)
 m.claim_room(0)
 m.player_position=m.player().bed_position()
 m.sleep_player()
 m.time=m.preparation+120
 m.player().occupied_seconds=120
 m.player().damage_dealt=1500
 m.player().door_damage_taken=500
 if outcome=="victory":
  m.hunter.hp=0
  m.hunter.state=HunterState.State.DEAD
 else:m.player().alive=false
 m.result=outcome
 return m
func cleanup():
 var d=DirAccess.open("user://")
 if d:
  for file in d.get_files():
   if file.begins_with(prefix.trim_prefix("user://")): DirAccess.remove_absolute("user://"+file)
func actor(m,id,quantity=3):
 var p=fresh()
 p.inventory[id]=quantity
 p.item_loadout=[id]
 var entry=p.begin_match(m.difficulty)
 return {"profile":p,"match_id":int(entry.id)}
func activate(a,m):return a.profile.activate_item(0,m,a.match_id)
func run():
 check(ItemCatalog.IDS.size()==16 and ItemCatalog.SLOTS==2,"sixteen functional items and two types")
 for outcome in ["victory","defeat"]:
  check(ItemCatalog.TABLES[outcome].size()==16,"table covers exactly implemented items")
  var total=0
  for weight in ItemCatalog.TABLES[outcome]:
   check(weight>0,"positive configured reward weight")
   total+=weight
  check(total==100,"visible probabilities total100")
  var first=RandomNumberGenerator.new()
  var second=RandomNumberGenerator.new()
  first.seed=991
  second.seed=991
  var counts={}
  for i in range(1000):
   var item=ItemCatalog.roll(outcome,first)
   check(item==ItemCatalog.roll(outcome,second) and item in ItemCatalog.IDS,"repeatable seed yields implemented reward")
   counts[item]=int(counts.get(item,0))+1
  check(counts.size()==16,"seed sweep reaches all functional items")
 # Inventory and save migration are additive to the existing profile.
 var p=fresh()
 check(p.inventory.is_empty() and p.item_loadout.is_empty(),"fresh inventory and loadout empty")
 check(not p.equip_item("gold"),"zero stock cannot equip")
 p.inventory={"gold":2,"repair":2,"battery":2}
 check(p.save_profile(),"seed inventory fixture saves")
 check(p.equip_item("gold") and p.equip_item("repair"),"two owned types equip")
 check(not p.equip_item("battery") and p.item_loadout.size()==2,"third type rejected")
 check(p.inventory.gold==2 and p.inventory.repair==2,"equipping does not consume")
 var reload=PlayerProfile.new(p.path)
 check(reload.load_profile() and reload.inventory.gold==2 and reload.item_loadout==p.item_loadout,"inventory and loadout persist")
 check(not p.equip_item("not_an_item"),"unknown item rejected")
 # Every reward originates in terminal settlement and is claimed exactly once.
 for outcome in ["victory","defeat"]:
  var owner=fresh()
  var entry=owner.begin_match("standard")
  var m=terminal("standard",outcome)
  var award=owner.settle_match(entry.id,m)
  check(not award.is_empty() and not owner.pending_spin().is_empty(),"eligible "+outcome+" creates pending spin")
  var pending=owner.pending_spin()
  check(int(pending.quantity)==(4 if outcome=="victory" else 1),"victory stack4 versus consolation1")
  var saved=PlayerProfile.new(owner.path)
  check(saved.load_profile() and int(saved.pending_spin().get("match_id",-1))==int(pending.match_id) and saved.pending_spin().get("item","")==pending.item and saved.pending_spin().get("result","")==pending.result,"predetermined reward persists before animation")
  var granted=saved.inventory.duplicate(true)
  check(int(saved.inventory.get(pending.item,0))==int(pending.get("quantity",1)),"settlement awards exact receipt quantity")
  var reward=saved.claim_spin(entry.id)
  check(not reward.is_empty() and saved.pending_spin().is_empty(),"claim persisted "+outcome+" spin")
  check(saved.inventory==granted,"skip/reveal acknowledgment cannot change granted quantity")
  var stock=saved.inventory.duplicate(true)
  check(saved.claim_spin(entry.id).is_empty() and saved.inventory==stock,"repeated claim cannot duplicate")
  var twice=PlayerProfile.new(saved.path)
  check(twice.load_profile() and twice.claim_spin(entry.id).is_empty() and twice.inventory==stock,"reload cannot reclaim")
  check(twice.settle_match(entry.id,m).is_empty(),"repeated terminal cannot reroll")
 # Anti-farm fixtures are intentionally finalized quickly or without contribution.
 for seconds in [0,10,30,59.9]:
  var owner=fresh()
  var entry=owner.begin_match("hell")
  var m=terminal("hell","defeat")
  m.player().occupied_seconds=seconds
  m.time=m.preparation+seconds
  owner.settle_match(entry.id,m)
  check(owner.pending_spin().is_empty(),"instant/short defeat has no reward "+str(seconds))
 var idle=fresh()
 var entry=idle.begin_match()
 var loss=terminal("standard","defeat")
 loss.player().damage_dealt=0
 loss.player().door_damage_taken=0
 idle.settle_match(entry.id,loss)
 check(idle.pending_spin().is_empty(),"uncontributing idle defeat cannot spin")
 # Save failure must leave a pending reward available, without any stock grant.
 var failing=fresh()
 var started=failing.begin_match()
 failing.settle_match(started.id,terminal())
 var original=failing.path
 var pending=failing.pending_spin()
 var before_stock=failing.inventory.duplicate(true)
 failing.path="user://missing-items-directory/never/profile.json"
 check(failing.claim_spin(started.id).is_empty(),"failed claim save refuses reward")
 check(failing.pending_spin()==pending and failing.inventory==before_stock,"failed claim rolls back all changes")
 failing.path=original
 check(not failing.claim_spin(started.id).is_empty(),"claim retry succeeds once")

 # Legacy profile migration preserves rank/perk/campaign without inventing items.
 var old=fresh()
 var legacy={"version":1,"xp":3800,"equipped":["first_aid"],"next_match_id":2,"settings":{"music":.23,"muted":true},"active_match":{},"last_award":{}}
 var f=FileAccess.open(old.path,FileAccess.WRITE)
 f.store_string(JSON.stringify(legacy));f.close()
 check(old.load_profile() and old.xp==3800 and old.equipped==["first_aid"] and old.inventory.is_empty(),"old save progression/perks preserved with empty new inventory")
 check(old.save_profile(),"legacy migrated generation saves")
 # Damaged/future optional records must preserve known progression without overwriting stock.
 for bad in [{"version":2},{"version":1,"inventory":{"gold":-1},"loadout":[],"pending":[]},{"version":1,"inventory":{"gold":1.5},"loadout":[],"pending":[]},{"version":1,"inventory":{"gold":99999999},"loadout":[],"pending":[]},{"version":1,"inventory":{},"loadout":["gold","gold"],"pending":[]}]:
  var damaged=fresh()
  var bytes=legacy.duplicate(true)
  bytes.consumables=bad
  var file=FileAccess.open(damaged.path,FileAccess.WRITE);file.store_string(JSON.stringify(bytes));file.close()
  check(damaged.load_profile() and damaged.xp==3800 and damaged.read_only,"invalid optional inventory loads base read-only")
  check(not damaged.save_profile(),"damaged inventory cannot be silently overwritten")
 # Corrupt optional active item snapshots cannot crash activation or erase base XP.
 for bad_items in [123,"gold",["gold","gold"],["unknown"],["gold","repair","shield"]]:
  var corrupt=fresh()
  var payload=legacy.duplicate(true)
  payload.next_match_id=3
  payload.active_match={"id":2,"difficulty":"standard","equipped":["first_aid"],"items":bad_items}
  var file=FileAccess.open(corrupt.path,FileAccess.WRITE);file.store_string(JSON.stringify(payload));file.close()
  check(corrupt.load_profile() and corrupt.xp==3800,"corrupt active items preserve XP")
  check(corrupt.read_only and corrupt.active_match.get("items",[]) is Array,"corrupt active items become safe read-only")
  check(not corrupt.activate_item(0,fixture(),2),"malformed snapshot activation safely refused")
 # A persisted reward quantity respects the stock ceiling without duplicate grants.
 var capped=fresh()
 var rng=RandomNumberGenerator.new();rng.seed=1234
 var expected_item=ItemCatalog.roll("victory",rng)
 capped.reward_rng.seed=1234
 capped.inventory[expected_item]=ItemCatalog.MAX_STOCK-2
 var cap_entry=capped.begin_match()
 capped.settle_match(cap_entry.id,terminal())
 check(capped.inventory[expected_item]==ItemCatalog.MAX_STOCK,"reward stock capped9999")
 check(int(capped.pending_spin().quantity)==2,"receipt reports actual capped quantity")
 capped.claim_spin(cap_entry.id)
 check(capped.inventory[expected_item]==ItemCatalog.MAX_STOCK,"reveal never adds capped stock twice")
 # Every successful activation persists stock first and rejects repeated input.
 for mode in ["standard","hard","hell"]:
  for stage in StageCatalog.STAGES:
   for item in ["repair","gold","battery","radar","shield","overdrive","frost","trap"]:
    var m=fixture(mode,stage.id)
    if item=="repair":m.player().door_hp-=m.player().max_hp()*.5
    if item=="overdrive":check(m.player().build("turret",0),"real turret fixture purchase")
    var a=actor(m,item)
    var p_before=a.profile.inventory[item]
    var hp=m.player().door_hp
    var gold=m.player().gold
    var power=m.player().electricity
    check(activate(a,m),"successful "+mode+stage.id+item)
    check(a.profile.inventory[item]==p_before-1,"one successful activation consumes one")
    var disk=PlayerProfile.new(a.profile.path)
    check(disk.load_profile() and disk.inventory[item]==p_before-1,"consumption persists before effect")
    check(not activate(a,m) and a.profile.inventory[item]==p_before-1,"same-frame input cannot doubleconsume")
    match item:
     "repair":check(is_equal_approx(m.player().door_hp-hp,m.player().max_hp()*.25),"repair exact25percent")
     "gold":check(is_equal_approx(m.player().gold-gold,150),"gold exact150")
     "battery":check(is_equal_approx(m.player().electricity-power,80),"electricity exact80")
     "radar":check(is_equal_approx(m.items.timers.radar,30),"radar actual30second state")
     "shield":
      check(is_equal_approx(m.items.shield_hp,m.player().max_hp()*.3),"shield30percent")
      var before=m.items.shield_hp
      m.hunter._damage_door(m.player(),m,50)
      check(m.player().door_hp==hp and is_equal_approx(m.items.shield_hp,before-50),"real Hunter damage absorbed first")
      m.hunter._damage_door(m.player(),m,before)
      check(is_equal_approx(m.player().door_hp,hp-50),"only overflow damages door")
     "frost":
      check(is_equal_approx(m.items.speed_factor(m.hunter),.6),"normal slow40percent")
      m.hunter.transformed=true
      check(is_equal_approx(m.items.speed_factor(m.hunter),.75),"boss bounded resistance25percent")
     "trap":
      check(not m.items.trap.is_empty() and m.navigation_walkable(m.items.trap.position),"trap deploys actual valid approach")
      var before=m.hunter.hp
      m.items.tick(.1,m)
      check(m.items.trap.is_empty() and is_equal_approx(before-m.hunter.hp,220),"trap triggers real220 damage once")
      before=m.hunter.hp
      m.items.tick(.1,m)
      check(m.hunter.hp==before,"trap cannot retrigger")
     "overdrive":check(is_equal_approx(m.items.timers.overdrive,12),"overdrive12seconds")
    m.items.tick(60,m)
    check(m.items.timers.is_empty() and m.items.trap.is_empty() and m.items.shield_hp==0,"all temporary effects expire")
    check(is_equal_approx(m.items.speed_factor(m.hunter),1),"normal speed restored")
    check(a.profile.inventory[item]>=0,"stock nonnegative")
 # Invalid activation never spends or changes a model, including write failure.
 for reason in ["full_door","broken_door","paused","terminal","no_turret","unclaimed","dormant","wrong_id","bad_slot","no_stock","save_fail"]:
  var m=fixture()
  var item="repair" if reason in ["full_door","broken_door"] else "overdrive" if reason=="no_turret" else "radar" if reason=="dormant" else "gold"
  var a=actor(m,item)
  match reason:
   "broken_door":m.player().door_hp=0
   "paused":m.running=false
   "terminal":m.result="defeat"
   "unclaimed":m.player_room=-1
   "dormant":m.hunter.state=HunterState.State.DORMANT
   "wrong_id":a.match_id+=100
   "no_stock":a.profile.inventory[item]=0
   "save_fail":a.profile.path="user://missing-items-directory/never/activation.json"
  var before=a.profile.inventory.duplicate(true)
  var gold=m.rooms[0].gold
  check(not a.profile.activate_item(-1 if reason=="bad_slot" else 0,m,a.match_id),"invalid activation rejects "+reason)
  check(a.profile.inventory==before and m.rooms[0].gold==gold and m.items.events.is_empty(),"invalid activation no stock/effect "+reason)
 # Spending last stock removes only the next-match selection, with rollback on failure.
 var last_model=fixture()
 var last_actor=actor(last_model,"gold",1)
 var last_path=last_actor.profile.path
 last_actor.profile.path="user://missing-items-directory/never/last-stock.json"
 check(not activate(last_actor,last_model) and last_actor.profile.inventory.gold==1 and last_actor.profile.item_loadout==["gold"],"failed last-stock save restores quantity and future selection")
 last_actor.profile.path=last_path
 check(activate(last_actor,last_model) and last_actor.profile.inventory.gold==0 and last_actor.profile.item_loadout.is_empty(),"successful last-stock consumption clears future selection")
 check(last_actor.profile.active_match.items==["gold"],"active hotbar snapshot remains stable after final unit")
 var last_disk=PlayerProfile.new(last_path)
 check(last_disk.load_profile() and last_disk.inventory.gold==0 and last_disk.item_loadout.is_empty(),"last-stock consumption persists without stale future loadout")
 # Global debounce spans distinct slots; active effects cannot be refreshed/stacked.
 var m=fixture()
 var a=actor(m,"shield")
 a.profile.inventory.gold=3
 a.profile.item_loadout=["shield","gold"]
 a.profile.active_match.items=["shield","gold"]
 check(activate(a,m),"first shield activates")
 check(not a.profile.activate_item(1,m,a.match_id),"cross-slot same-frame debounce")
 m.items.tick(1.1,m)
 check(not activate(a,m),"active shield cannot stack or refresh")
 check(a.profile.activate_item(1,m,a.match_id),"other item works after debounce")
 # Real firing cadence, not merely animation, changes and then restores.
 var shots=[]
 for boosted in [false,true]:
  var shoot=fixture()
  shoot.hunter.position=shoot.player().tile_position(0)
  shoot.player().build("turret",0)
  if boosted:shoot.items.apply("overdrive",shoot)
  for i in range(100):shoot._turrets(.1)
  shots.append(shoot.shots)
 check(shots[1]>shots[0]*1.2,"overdrive increases actual launch frequency")
 # Movement slowing changes actual navigation distance and pauses safely.
 var movement=[]
 for frozen in [false,true]:
  var move=fixture()
  move.hunter.position=move.map_data.hunter_spawn
  move.hunter.state=HunterState.State.MOVE
  move.hunter.target=0
  if frozen:move.items.apply("frost",move)
  var start=move.hunter.position
  move.hunter.tick(.1,move)
  movement.append(start.distance_to(move.hunter.position))
  if frozen:
   move.running=false
   var remaining=move.items.timers.frost
   move.tick(10)
   check(move.items.timers.frost==remaining,"paused model does not age consumables")
 check(movement[0]>0 and is_equal_approx(movement[1]/movement[0],.6),"frost slows real route movement40percent")
 # A real long frame must not let a breaching Hunter tunnel across an armed trap.
 for stage in StageCatalog.STAGES:
  var sweep=fixture("standard",stage.id)
  sweep.time=sweep.preparation+300
  sweep.player().door_hp=0
  sweep.hunter.state=HunterState.State.BREACH
  sweep.hunter.position=sweep.player().door_approach()+sweep.player().door_normal()*45
  sweep.items.apply("trap",sweep)
  sweep.tick(1)
  sweep.tick(1)
  var explosions=sweep.items.events.filter(func(e):return e.item=="trap" and e.phase=="explode")
  check(sweep.items.trap.is_empty() and explosions.size()==1,"swept trap triggers once across long frame "+stage.id)
 # Terminal cleanup and reset cannot leak active effects.
 for outcome in ["victory","defeat"]:
  var end=fixture()
  end.items.apply("frost",end)
  end.items.apply("shield",end)
  end.items.apply("trap",end)
  if outcome=="victory":end.hunter.hurt(1e9)
  else:end.player().alive=false
  end.tick(.1)
  check(end.result==outcome and end.items.timers.is_empty() and end.items.trap.is_empty() and end.items.shield_hp==0,"terminal cleans items "+outcome)
  end.reset()
  check(end.items.events.is_empty() and end.items.timers.is_empty(),"reset creates fresh item state")
 print("ITEM_QA_CHECKS=",checks," FAILURES=",failures)
 cleanup()
 quit(0 if failures==0 else 1)
