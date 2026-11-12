extends "res://tests/phase5d4_qa_boss.gd"
func all_items():
 check(ItemCatalog.IDS.size()==20,"all twenty existing consumables remain registered")
 for id in ItemCatalog.IDS:
  var m=boss();var r=m.player();r.gold=100000;r.electricity=10000;r.door_hp=r.max_hp()*.5
  check(m.buy("flame",0) and m.buy("frost",1) and m.buy("shock",2),"item integration owns all three real new offensive roles")
  var a=bind(m,[id]);var stocks=a.p.inventory.duplicate(true);var permanent=[a.p.xp,a.p.rm_cash,a.p.pending_spins.duplicate(true),a.p.achievements.duplicate(true),a.p.campaign_records.duplicate(true)]
  m.wrath.rules_remaining=2
  check(not a.p.activate_item(0,m,a.id) and a.p.inventory==stocks,"Rules lock failed activation preserves exact stock "+id)
  m.wrath.rules_remaining=0;m.items.cooldown=0
  var gold=r.gold;var power=r.electricity
  if id=="guardian_heart":
   r.door_hp=10;m.apply_room_damage(0,100,"actual lethal special",1,true)
   check(r.door_hp>0 and m.items.legendary_used==1,"Guardian actual lethal rescue remains functional with newmachines")
  elif id=="feather":
   r.door_hp=r.max_hp()*.3;m.apply_room_damage(0,r.max_hp()*.1,"actual threshold special",1,true)
   check(m.items.feather_used and is_equal_approx(r.door_hp,r.max_hp()*.35),"Feather actual threshold rescue remains functional")
  else:
   if id=="rescue":m.rooms[1].door_hp=m.rooms[1].max_hp()*.5
   if id=="reaper_seal":check(m.wrath.begin("scythe_slash",m,0),"genuine Seal warning starts")
   check(a.p.activate_item(0,m,a.id,1 if id=="rescue" else -1),"actual valid existing item activates with new combat "+id)
   if id=="coupon":
    check(a.p.inventory[id]==3 and r.coupon_armed,"arming coupon consumes nothing")
    check(m.buy("auto_repair",3) and not r.coupon_armed,"real discounted new machine consumes armed coupon once")
   elif id=="gold":check(r.gold==gold+150,"Gold crate measurable reward")
   elif id=="battery":check(r.electricity==power+80,"Battery measurable reward")
   elif id=="repair":check(is_equal_approx(r.door_hp,r.max_hp()*.75),"Repair kit measurable actual recovery")
   elif id=="rescue":check(is_equal_approx(m.rooms[1].door_hp,m.rooms[1].max_hp()*.75),"Rescue heals actual selected teammate")
   elif id=="cursed_fortune":check(r.gold==gold+500 and m.items.legendary_used==1 and m.items.timers.cursed_fortune>0,"Fortune actual reward and finite drawback")
   elif id=="reaper_seal":check(not m.wrath.active() and m.items.legendary_used==1,"Seal actually interrupts selected warning")
   elif id=="trap":
    var hp=m.hunter.hp;var at=m.items.trap.position;m.items.trigger_segment(at-Vector2(10,0),at+Vector2(10,0),m)
    check(m.items.trap.is_empty() and m.hunter.hp<hp,"existing trap actual segment collision damage")
   else:check(float(m.items.timers.get(id,0))>0,"existing finite active feedback timer registered "+id)
  check(a.p.inventory[id]==2,"successful actual effect consumes exactly one existing stock "+id)
  check([a.p.xp,a.p.rm_cash,a.p.pending_spins,a.p.achievements,a.p.campaign_records]==permanent,"activation cannot leak unrelated permanent progression "+id)
  var q=PlayerProfile.new(a.p.path);check(q.load_profile() and q.inventory==a.p.inventory,"actual one-use inventory transaction reloads safely "+id)
func offensive_combinations():
 for kind in ["flame","frost","shock"]:
  var m=boss();var r=m.player();r.gold=10000;r.electricity=10000;check(m.buy(kind,0),"new weapon bought for Overdrive/Inferno "+kind)
  var a=bind(m,["overdrive","inferno"]);var before=BuildingStats.weapon_stats(m,r,r.buildings[0])
  check(a.p.activate_item(0,m,a.id),"Overdrive recognizes new offense "+kind)
  var after=BuildingStats.weapon_stats(m,r,r.buildings[0]);check(is_equal_approx(after.interval,before.interval/1.35),"Overdrive actual rate applies once to new offense "+kind)
  m.items.tick(1.1,m);check(a.p.activate_item(1,m,a.id),"Inferno recognizes new offense "+kind)
  var origin=r.tile_position(0);m.spawn_undead(1);var u=m.minions[0];u.position=origin+Vector2(20,0);m.hunter.position=m.map_data.hunter_spawn
  m._turrets(.01);m._advance_projectiles(1)
  check(m.defenses.burn_dps(u.id)>=12,"owned actual minion hit gets real Inferno burn "+kind)
  var hp=u.hp;m.defenses.tick(.5,m);check(u.hp<hp,"new weapon Inferno combination deals measurable actual undead DoT "+kind)
  check(a.p.inventory.overdrive==2 and a.p.inventory.inferno==2,"combination spends exactly one of each")
func practice_isolation():
 var path=prefix+"-permanent.json";var p=PlayerProfile.new(path);p.xp=13000;p.rm_cash=123;p.inventory.inferno=7;p.item_loadout=["inferno"];p.save_profile()
 var before=FileAccess.get_file_as_bytes(path)
 for id in ItemCatalog.IDS:
  var m=MatchModel.new();var temp=PracticeRoom.configure(m,"crusher",true,[id])
  var r=m.player();r.gold=100000;r.electricity=10000;r.door_hp=r.max_hp()*.5
  var free=-1
  for tile in range(r.tile_count()):
   if not r.buildings.has(tile):free=tile;break
  check(m.buy("flame",free),"practice supports real new building purchase")
  m.hunter.transformed=true;m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.position=r.door_approach();m.hunter.tick(0,m)
  if id=="reaper_seal":m.wrath.begin("scythe_slash",m,0)
  temp.activate_item(0,m,1,1 if id=="rescue" else -1)
  check(FileAccess.get_file_as_bytes(path)==before and p.inventory.inferno==7 and p.xp==13000 and p.rm_cash==123,"practice newbuild/item activation cannot consume realstock or grantprogression "+id)
func global_seal():
 for id in ["phantom_scream","rules_judgement","final_judgement"]:
  var m=boss();m.wrath.phase=2 if id!="rules_judgement" else 1;var a=bind(m,["reaper_seal"])
  check(m.wrath.begin(id,m,1),"global warning chosenNPC starts "+id)
  check(a.p.activate_item(0,m,a.id) and not m.wrath.active() and a.p.inventory.reaper_seal==2,"Seal legitimately counters global effect threatening player despiteNPCcasttarget "+id)
func run():
 all_items();offensive_combinations();practice_isolation();global_seal()
 preload("res://tests/replay_test_support.gd").cleanup(prefix)
 print("PHASE5D4_QA_ITEMS_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
