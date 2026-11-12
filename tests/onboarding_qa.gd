extends SceneTree
# Independent deterministic profile/economy fixtures, not natural match or human-rate evidence.
var checks=0
var failures=0
var serial=0
var prefix="user://onboarding-qa-"
var catalog
func _initialize():prefix+=str(Time.get_ticks_usec())+"-";call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("ONBOARDING QA: "+label)
func fresh():
 serial+=1
 return PlayerProfile.new(prefix+str(serial)+".json")
func fixture(mode="standard",occupied=120.0,win=true):
 var m=MatchModel.new();m.configure_match(mode)
 m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 m.time=m.preparation+occupied;m.bot_claimed=5
 var r=m.player();r.occupied_seconds=occupied;r.damage_dealt=1000;r.door_damage_taken=200
 m.result="victory" if win else "defeat"
 if win:m.hunter.hp=0;m.hunter.state=HunterState.State.DEAD
 else:r.alive=false;r.sleeping=false
 return m
func erase_files():
 var directory=DirAccess.open("user://")
 if directory:
  for f in directory.get_files():
   if f.begins_with(prefix.trim_prefix("user://")):DirAccess.remove_absolute("user://"+f)
func run():
 catalog=load("res://scripts/onboarding_catalog.gd")
 check(catalog!=null,"onboarding catalog loads")
 check(ItemCatalog.IDS.size()==20 and ItemCatalog.SLOTS==2,"all20 and separate2slots preserved")
 var p=fresh()
 check(p.rm_cash==0 and not p.tutorial_completed,"new profile fresh mandatory and no fabricated cash")
 check(p.complete_tutorial() and p.tutorial_completed,"durable tutorial completion")
 var q=PlayerProfile.new(p.path)
 check(q.load_profile() and q.tutorial_completed and q.rm_cash==0,"tutorial flag reloads without rewards")
 var snapshot=p._reward_snapshot();var oldpath=p.path;p.path+="/missing.json";p.tutorial_completed=false
 check(not p.complete_tutorial() and not p.tutorial_completed,"failed tutorial save cannot confirm complete")
 p.path=oldpath
 # Every shop product is actually registered Common; purchases use the existing inventory.
 check(catalog.PRICES.size()==4,"four Common shop products")
 for id in catalog.PRICES:
  var price=int(catalog.PRICES[id]);p=fresh();p.rm_cash=price*3
  check(ItemCatalog.ITEMS.has(id) and ItemCatalog.ITEMS[id].rarity=="Common" and price>0,"only real Common priced "+id)
  var before=p.rm_cash
  check(p.buy_common(id,1),"valid buy "+id)
  check(p.rm_cash==before-price and p.inventory[id]==1 and p.purchase_serial==1,"exact atomic cash/stock/serial "+id)
  check(not p.buy_common(id,1) and p.rm_cash==before-price and p.inventory[id]==1,"double click token rejected "+id)
  q=PlayerProfile.new(p.path)
  check(q.load_profile() and q.rm_cash==p.rm_cash and q.inventory[id]==1,"purchase durable "+id)
  check(not q.buy_common(id,1),"reloaded purchase replay refused "+id)
  check(q.buy_common(id,2) and q.inventory[id]==2 and q.rm_cash==before-price*2,"next distinct purchase works "+id)
  for token in [-1,0,1,9,1.5,"3",INF,NAN]:check(not q.buy_common(id,token),"invalid/stale/future token refused "+id+str(token))
  p=fresh();p.rm_cash=price-1
  check(not p.buy_common(id,1) and p.rm_cash==price-1 and p.inventory.is_empty() and p.purchase_serial==0,"insufficient cash no mutations")
  p.rm_cash=price*2;p.inventory[id]=ItemCatalog.MAX_STOCK
  check(not p.buy_common(id,1) and p.rm_cash==price*2 and p.inventory[id]==ItemCatalog.MAX_STOCK,"stockcap no cash deduction")
  p.inventory[id]=0;p.path+="/missing.json"
  check(not p.buy_common(id,1) and p.rm_cash==price*2 and p.inventory[id]==0 and p.purchase_serial==0,"failed save rolls back both balances")
  p=fresh();p.rm_cash=1000;p.read_only=true
  check(not p.buy_common(id,1) and p.rm_cash==1000 and p.inventory.is_empty(),"readonly blocks shop")
 p=fresh();p.rm_cash=10000
 for id in ["unknown","shield","inferno","time_freeze",""]:
  check(not p.buy_common(id,1) and p.rm_cash==10000 and p.inventory.is_empty(),"shop excludes nonCommon/unknown "+id)
 # Settlement, failed writes, retry and duplicate/reload protection.
 for mode in ["standard","hard","hell"]:
  for win in [false,true]:
   p=fresh();var entry=p.begin_match(mode);var m=fixture(mode,120,win);p.reward_rng.seed=123
   var rng_before=p.reward_rng.state;oldpath=p.path;p.path+="/missing.json"
   check(p.settle_match(entry.id,m).is_empty() and p.rm_cash==0 and p.reward_rng.state==rng_before and not p.active_match.is_empty(),"failed RM settlement rolls back "+mode+str(win))
   p.path=oldpath
   var award=p.settle_match(entry.id,m);var cash=p.rm_cash
   check(not award.is_empty() and cash>0,"legitimate match earns RM "+mode+str(win))
   check(p.settle_match(entry.id,m).is_empty() and p.rm_cash==cash,"no repeated RM match settlement")
   q=PlayerProfile.new(p.path)
   check(q.load_profile() and q.rm_cash==cash and q.settle_match(entry.id,m).is_empty(),"RM reload duplicate guarded")
   check(p.xp==q.xp and p.inventory==q.inventory and p.pending_spins.size()==q.pending_spins.size(),"other reward balances survive RM reload")
   for index in range(mini(p.pending_spins.size(),q.pending_spins.size())):
    var original=p.pending_spins[index];var reloaded=q.pending_spins[index]
    check(int(original.match_id)==int(reloaded.match_id) and original.item==reloaded.item and original.result==reloaded.result and int(original.quantity)==int(reloaded.quantity),"spin receipt semantics survive RM reload")
 for occupied in [0.0,1.0,10.0,20.0,60.0,89.0]:
  p=fresh();var entry=p.begin_match();var m=fixture("standard",occupied,false)
  p.settle_match(entry.id,m)
  check(p.rm_cash==0,"quick loss no RM "+str(occupied))
 # Isolated tutorials cannot mint ordinary rewards, consume inventory, or use shop currency as match gold.
 for win in [false,true]:
  p=fresh();p.inventory={"gold":3};p.item_loadout=["gold"];p.rm_cash=123
  var entry=p.begin_match();var m=fixture("standard",120,win);m.tutorial_mode=true;p.bind_items(m,entry.id)
  var before=p._reward_snapshot()
  check(p.settle_match(entry.id,m).is_empty() and p._reward_snapshot()==before,"tutorial settlement no XP/RM/spin/achievements")
  check(not p.consume_item("gold",m,entry.id) and p.inventory.gold==3,"tutorial cannot consume real stock")
  check(not p.activate_item(0,m,entry.id) and p.inventory.gold==3,"tutorial cannot activate stored consumables")
 # Cash and purchase counters cannot overflow their persisted schema.
 p=fresh();p.rm_cash=catalog.MAX_CASH-2
 var cap_entry=p.begin_match();var cap_model=fixture()
 var cap_award=p.settle_match(cap_entry.id,cap_model)
 check(p.rm_cash==catalog.MAX_CASH and cap_award.rm_cash==2,"RM cap reports actual credited amount")
 p=fresh();p.rm_cash=100;p.purchase_serial=1000000000000
 check(not p.buy_common("repair",1000000000001) and p.rm_cash==100 and p.purchase_serial==1000000000000,"serial schema cap cannot create unloadable purchase")
 # Old progress proves graduation, blank old saves do not; no historical RM is fabricated.
 for proof in ["blank","xp","inventory","victory"]:
  p=fresh()
  if proof=="xp":p.xp=700;p.equipped=["dreamer"]
  if proof=="inventory":p.inventory={"smoke":7}
  if proof=="victory":p.statistics.matches=1;p.statistics.victories=1;p.statistics.standard=1
  check(p.save_profile(),"old fixture writes")
  var raw=JSON.parse_string(FileAccess.get_file_as_string(p.path));raw.erase("onboarding")
  var file=FileAccess.open(p.path,FileAccess.WRITE);file.store_string(JSON.stringify(raw));file.close()
  q=PlayerProfile.new(p.path)
  check(q.load_profile() and q.tutorial_completed==(proof!="blank") and q.rm_cash==0,"old migration proof "+proof)
  check(q.xp==p.xp and q.inventory==p.inventory and q.equipped==p.equipped,"old progress preserved "+proof)
 for bad in [{"version":2,"tutorial_completed":true,"rm_cash":20,"purchase_serial":0},{"version":1,"tutorial_completed":"yes","rm_cash":20,"purchase_serial":0},{"version":1,"tutorial_completed":true,"rm_cash":-1,"purchase_serial":0},{"version":1,"tutorial_completed":true,"rm_cash":1.5,"purchase_serial":0},{"version":1,"tutorial_completed":true,"rm_cash":20,"purchase_serial":-1},{"version":1,"tutorial_completed":true,"rm_cash":20,"purchase_serial":0.5},[]]:
  p=fresh();p.xp=700;p.inventory={"repair":9};p.save_profile()
  var raw=JSON.parse_string(FileAccess.get_file_as_string(p.path));raw.onboarding=bad
  var bytes=JSON.stringify(raw);var file=FileAccess.open(p.path,FileAccess.WRITE);file.store_string(bytes);file.close()
  q=PlayerProfile.new(p.path)
  check(q.load_profile() and q.read_only and q.xp==700 and q.inventory.repair==9,"bad optional meta preserves progress readonly")
  check(not q.complete_tutorial() and not q.buy_common("repair",1) and FileAccess.get_file_as_string(p.path)==bytes,"bad optional meta cannotoverwrite")
 erase_files()
 print("ONBOARDING_QA_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
