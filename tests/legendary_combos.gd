extends SceneTree
# Independent transaction/combat fixtures. Injected stock/currency is not balance evidence.
var checks=0
var failures=0
var serial=0
var prefix="user://legendary-qa-"
const NEW=["time_freeze","reaper_seal","guardian_heart","cursed_fortune"]
func _initialize():
 prefix+=str(Time.get_ticks_usec())+"-"
 call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok: failures+=1;push_error("LEGENDARY QA: "+label)
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
 m.bot_claimed=5;m.time=m.preparation+100
 var r=m.player()
 r.occupied_seconds=100;r.gold=10000;r.electricity=10000
 r.door_level=4;r.door_hp=r.max_hp()
 var h=m.hunter
 h.state=HunterState.State.ATTACK;h.target=0;h.position=r.door_approach()
 h.boss_policy.enabled=false;h.tick(.01,m);h.cooldown=100
 r.door_hp=r.max_hp()
 return m
func actor(m,ids):
 var p=fresh()
 for id in ids:p.inventory[id]=3
 p.item_loadout=ids.duplicate()
 var entry=p.begin_match(m.difficulty)
 p.bind_items(m,entry.id)
 return {"p":p,"id":entry.id}
func use(a,m,slot=0):return a.p.activate_item(slot,m,a.id)
func warning(m,attack="siege"):
 var h=m.hunter
 h.transformed=true;h.state=HunterState.State.ATTACK;h.target=0;h.position=m.player().door_approach()
 h.boss_attack=attack;h.boss_attack_target=0;h.cooldown=BossCatalog.ATTACKS[attack].windup
 h.windup_remaining=h.cooldown
 h.boss_cooldowns[attack]=BossCatalog.ATTACKS[attack].cooldown
func cleanup():
 var d=DirAccess.open("user://")
 if d:
  for file in d.get_files():
   if file.begins_with(prefix.trim_prefix("user://")):DirAccess.remove_absolute("user://"+file)
func run():
 # Shield/Barricade are resolved before lethal interception; finite shields cannot revive forever.
 for support in ["shield","barricade","repair","feather"]:
  for mode in ["standard","hard","hell"]:
   var m=fixture(mode);var a=actor(m,["guardian_heart",support]);var r=m.player()
   r.rescue_fraction=.1
   r.door_hp=r.max_hp()*.3
   if support=="shield" or support=="barricade":check(use(a,m,1),"support activates "+support)
   var hp=r.door_hp
   var amount=hp*1.1
   if support in ["shield","barricade"]:
    m.hunter._damage_door(r,m,amount)
    check(r.door_hp>0 and a.p.inventory.guardian_heart==3,"mitigation/shield prevents unnecessary Heart")
   elif support=="repair":
    check(use(a,m,1),"repair before lethal")
    check(r.door_hp>hp and a.p.inventory.guardian_heart==3,"repair independently functional")
   else:
    m.hunter._damage_door(r,m,r.max_hp()*.1)
    check(a.p.inventory.feather==2 and a.p.inventory.guardian_heart==3,"nonfatal Feather does not spend Heart")
   var previous_rescue=r.rescue_used
   m.hunter._damage_door(r,m,100000)
   check(a.p.inventory.guardian_heart==2 and r.door_hp>0,"lethal after support triggers Heart")
   check(is_equal_approx(r.door_hp,r.max_hp()*ItemCatalog.TUNING.heart_fraction),"Heart heal exact no samehit FirstAid cascade")
   check(r.rescue_used==previous_rescue,"Heart interceptedhit does not change FirstAid state")
   m.items.tick(4,m)
   m.hunter._damage_door(r,m,100000)
   check(r.door_hp==0 and a.p.inventory.guardian_heart==2,"finite defense cannot infiniteheal")
 # Both auto items equipped; lethal intercept must not spend Feather on same hit.
 var m=fixture();var a=actor(m,["guardian_heart","feather"]);var r=m.player()
 r.door_hp=r.max_hp()*.9;m.hunter._damage_door(r,m,r.max_hp())
 check(a.p.inventory.guardian_heart==2 and a.p.inventory.feather==3,"Heart suppresses samehit Feather")
 check(not m.items.feather_used,"Feather remains available for later valid crossing")
 # Every ordered pair of Legendary types enforces one success, automatic included.
 for first in NEW:
  for second in NEW:
   if first==second:continue
   m=fixture();a=actor(m,[first,second]);r=m.player()
   if first=="guardian_heart":r.door_hp=10;m.hunter._damage_door(r,m,20)
   else:
    if first=="reaper_seal":warning(m)
    check(use(a,m),"first Legendary valid "+first)
   check(a.p.inventory[first]==2 and m.items.legendary_used==1,"first exactlyonce "+first)
   m.items.tick(25,m)
   if second=="guardian_heart":
    r.door_hp=10;m.hunter._damage_door(r,m,20)
    check(r.door_hp==0,"auto Heart blocked after "+first)
   else:
    if second=="reaper_seal":warning(m)
    check(not use(a,m,1),"second Legendary blocked "+second)
   check(a.p.inventory[second]==3 and m.items.legendary_used==1,"second consumesnothing")
 # Freeze + Frost: fixed freeze then bounded slow; control cannot cycle into Decoy.
 for boss in [false,true]:
  m=fixture("hell");a=actor(m,["frost","time_freeze"]);m.hunter.transformed=boss
  check(use(a,m),"Frost before freeze")
  m.tick(1.01)
  check(use(a,m,1),"Freeze stacks with non-disabling Frost")
  var hp=m.player().door_hp
  m.tick(.5)
  check(m.player().door_hp==hp,"combination stops attacks temporarily")
  check(m.items.can_activate("decoy",m)!="" and m.items.can_activate("smoke",m)!="","shared recovery blocks control chain")
  m.tick(21)
  check(not m.items.timers.has("frost") and not m.items.timers.has("time_freeze"),"both controls expire")
  m.hunter.target=0;m.hunter.state=HunterState.State.ATTACK;m.hunter.position=m.player().door_approach()
  m.hunter.cooldown=0;m.hunter.boss_cooldowns={"scythe":100.0,"siege":0.0,"surge":100.0}
  hp=m.player().door_hp;m.tick(.01);m.tick(2)
  check(m.player().door_hp<hp,"ordinary/Reaper attack resumes after combined expiry")
 # Cursed Fortune + old defense does not erase penalty, income actual and cleanup finite.
 for old in ["shield","barricade","repair"]:
  m=fixture("hell");a=actor(m,["cursed_fortune",old]);r=m.player()
  r.door_hp=r.max_hp()*.5
  var gold=r.gold
  check(use(a,m) and r.gold==gold+500,"Fortune gives500 with "+old)
  m.tick(1.01)
  check(use(a,m,1),"old defense remains usable after Legendary")
  var cursed_damage=m.hunter.damage
  m.tick(20);m.tick(.01)
  check(not m.items.timers.has("cursed_fortune") and m.items.legendary_used==1,"curse finite; budget retained")
  check(a.p.inventory.cursed_fortune==2 and a.p.inventory[old]==2,"combined stocks correct")
 cleanup()
 print("LEGENDARY_COMBO_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
