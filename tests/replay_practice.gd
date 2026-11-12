extends SceneTree
const Support=preload("res://tests/replay_test_support.gd")
const Practice=preload("res://scripts/practice_room.gd")
var checks=0
var failures=0
var training_cases=0
var prefix="user://replay-practice-"+str(Time.get_ticks_usec())+"-"
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("REPLAY PRACTICE: "+label)
func item_effects(permanent):
 var signature=Support.profile_signature(permanent);var bytes=FileAccess.get_file_as_bytes(permanent.path)
 for id in ItemCatalog.IDS:
  var m=MatchModel.new();var wallet=Practice.configure(m,"crusher",false,[id]);var r=m.player();var h=m.hunter
  h.position=r.door_approach();h.target=0;h.state=HunterState.State.ATTACK;h.cooldown=100
  if id in ["repair","rescue"]:r.door_hp=r.max_hp()*.5
  if id=="reaper_seal":
   h.transformed=true;h.boss_attack="siege";h.boss_attack_target=0;h.cooldown=1;h.windup_remaining=1
  var before=wallet.inventory[id];var activated=false;var old_gold=r.gold;var old_power=r.electricity;var old_hp=r.door_hp
  if id=="feather":
   r.door_hp=r.max_hp()*.25+1;h._damage_door(r,m,2);activated=m.items.feather_used
  elif id=="guardian_heart":
   r.door_hp=1;h._damage_door(r,m,2);activated=m.items.legendary_used==1 and r.door_hp>1
  else:activated=wallet.activate_item(0,m,1,1 if id=="rescue" else -1)
  check(activated,"temporary selected item has real successful activation/automatic trigger: "+id)
  if id=="coupon":
   check(wallet.inventory[id]==before and r.coupon_armed,"practice coupon arms without premature consumption")
   check(m.buy("generator",Support.nearest_pad(r,r.door_approach())),"practice coupon pays a real discounted transaction")
  check(wallet.inventory[id]==before-1,"successful actual effect consumes exactly one temporary stock: "+id)
  if id=="repair":check(is_equal_approx(r.door_hp-old_hp,r.max_hp()*.25),"temporary repair restores actual HP")
  if id=="gold":check(r.gold==old_gold+150,"temporary crate adds actual match Gold")
  if id=="battery":check(r.electricity==old_power+80,"temporary battery adds actual match Electricity")
  if id=="shield":
   var hp=r.door_hp;h._damage_door(r,m,20)
   check(r.door_hp==hp and m.items.shield_hp<r.max_hp()*.3,"temporary shield absorbs real incoming damage")
  if id=="barricade":
   var hp=r.door_hp;h._damage_door(r,m,20)
   check(is_equal_approx(hp-r.door_hp,15),"temporary barricade changes actual incoming damage25%")
  if id=="overdrive":
   m._turrets(.01)
   check(is_equal_approx(r.buildings[m.practice_tile].cooldown+.01,Catalog.turret_interval("turret",4)/1.35),"temporary Overdrive changes actual firing interval")
  if id=="frost":
   h.tick(.01,m)
   check(is_equal_approx(h.speed,Catalog.HUNTER.speed*StrategyCatalog.ARCHETYPES.crusher.speed*.6),"temporary Frost changes actual movement speed")
  if id=="trap":
   var hp=h.hp;m.items.tick(.1,m);var after=h.hp;m.items.tick(.1,m)
   check(is_equal_approx(hp-after,220) and h.hp==after and m.items.trap.is_empty(),"temporary trap damages actual contact once without duplicate explosion")
  if id=="decoy":
   h.cooldown=0;var hp=r.door_hp;m.tick(.1)
   check(h.state==HunterState.State.MOVE and r.door_hp==hp and h.attacks==0,"temporary decoy legitimately interrupts actual targeting/attacks")
  if id=="rescue":check(is_equal_approx(m.rooms[1].door_hp,m.rooms[1].max_hp()*.9),"temporary rescue restores real selected ally HP")
  if id=="time_freeze":
   h.cooldown=0;m.tick(.2)
   check(m.items.frozen_delta>0 and h.cooldown==0 and h.attacks==0,"temporary Time Freeze holds real Hunter action clock")
  if id=="reaper_seal":check(h.boss_attack=="" and h.cooldown>=1.25,"temporary Seal cancels actual warned boss attack")
  if id=="cursed_fortune":
   m.items.tick(.01,m);h.tick(.01,m)
   check(r.gold==old_gold+500 and is_equal_approx(h.damage,22*1.2*1.25),"temporary Fortune grants actual Gold with real cursed Hunter damage")
  if ItemCatalog.legendary(id):
   check(not wallet.activate_item(0,m,1) and wallet.inventory[id]==before-1,"practice still enforces one Legendary per attempt")
  if id=="pillow":
   var gold=r.gold;m.tick(1)
   check(is_equal_approx(r.gold-gold,r.income_rate()),"temporary Pillow pays actual50% increased occupied income")
  if id=="inferno":
   var hp=h.hp;m._turrets(.1);m._advance_projectiles(2);m.items.tick(.1,m)
   check(h.hp<hp and m.items.burn_remaining>0,"temporary Inferno produces actual impact plus burn")
  check(Support.profile_signature(permanent)==signature and FileAccess.get_file_as_bytes(permanent.path)==bytes,"practice item cannot alter any permanent field/bytes/RNG: "+id)
func actual_training(permanent):
 var signature=Support.profile_signature(permanent);var bytes=FileAccess.get_file_as_bytes(permanent.path)
 for map in MapCatalog.IDS:
  for archetype in StrategyCatalog.ARCHETYPE_IDS:
   training_cases+=1
   var m=MatchModel.new();var wallet=Practice.configure(m,archetype,false,["shield","repair"],map)
   var r=m.player();var h=m.hunter;var hp=r.door_hp
   check(not m.tutorial_mode and m.run_kind=="practice" and m.practice_tile>=0,"advanced practice uses real combat without tutorial damage scale")
   check(r.tile_position(m.practice_tile).distance_to(r.door_approach())<=204,"starter L4 turret is genuinely in range even for Precision")
   for i in range(1200):
    m.tick(.05)
    check(m.navigation_walkable(h.position),"real practice Hunter follows authored valid floor")
    if r.door_hp<hp:break
   check(h.target==0 and r.door_hp<hp and hp-r.door_hp>10,"real archetype physically threatens player with unreduced normal damage")
   check(m.specialize_building(m.practice_tile,"suppression"),"practice demonstrates actual paid branch choice")
   var old=wallet
   wallet=Practice.configure(m,archetype,false,["shield","repair"],map)
   check(m.result=="" and wallet!=old and wallet.inventory.shield==5 and m.player().buildings[m.practice_tile].level==4,"reset restores only temporary scenario/inventory, no application restart")
   check(Support.profile_signature(permanent)==signature and FileAccess.get_file_as_bytes(permanent.path)==bytes,"map/archetype combat/reset cannot touch permanent save")
func mode_guards(permanent):
 permanent.item_loadout=["shield"];var entry=permanent.begin_match("standard","stage_1",true)
 var before=permanent._reward_snapshot();var bytes=FileAccess.get_file_as_bytes(permanent.path);var rng=permanent.reward_rng.state
 for kind in ["practice","challenge"]:
  var m=MatchModel.new();var local=Practice.configure(m,"crusher",false,["shield"]);m.run_kind=kind
  check(not permanent.consume_item("shield",m,entry.id),"direct permanent consume blocked in normalized/training mode")
  check(not permanent.activate_item(0,m,entry.id),"direct permanent activation blocked before binding local wallet")
  m.result="victory";m.hunter.hp=0
  check(permanent.settle_match(entry.id,m).is_empty() and permanent._reward_snapshot()==before and FileAccess.get_file_as_bytes(permanent.path)==bytes and permanent.reward_rng.state==rng,"direct permanent settlement cannot award/mutate practice/challenge profile")
func run():
 var p=Support.profile(prefix+"permanent.json");p.pending_spins=[];p.save_profile()
 item_effects(p)
 if "--items-only" not in OS.get_cmdline_user_args():actual_training(p)
 mode_guards(p);Support.cleanup(prefix)
 print("REPLAY_PRACTICE_CHECKS=",checks," ITEMS=20 MAP_ARCHETYPES=",training_cases," FAILURES=",failures)
 quit(0 if failures==0 else 1)
