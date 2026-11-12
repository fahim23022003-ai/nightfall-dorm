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
 check(ItemCatalog.IDS.size()==20 and ItemCatalog.SLOTS==2,"20 items; two slots")
 for id in NEW:
  check(ItemCatalog.ITEMS[id].rarity=="Legendary","rarity "+id)
  check(ResourceLoader.exists("res://assets/items/"+id+".svg"),"icon "+id)
  check(ResourceLoader.exists("res://assets/audio/item_"+id+".wav"),"audio "+id)
 for outcome in ["victory","defeat"]:
  var weights=ItemCatalog.TABLES[outcome]
  var sum=0;var rarity={"Common":0,"Rare":0,"Epic":0,"Legendary":0}
  check(weights.size()==20,"20 weights "+outcome)
  for i in range(20):
   check(weights[i]>0,"all items obtainable")
   sum+=weights[i];rarity[ItemCatalog.ITEMS[ItemCatalog.IDS[i]].rarity]+=weights[i]
  check(sum==(1000 if outcome=="victory" else 4000),"configured integer denominator")
  check(rarity==({"Common":400,"Rare":400,"Epic":160,"Legendary":40} if outcome=="victory" else {"Common":3200,"Rare":640,"Epic":120,"Legendary":40}),"documented rarity odds")
  var rng=RandomNumberGenerator.new();rng.seed=1212
  var twin=RandomNumberGenerator.new();twin.seed=1212
  var reached={}
  for i in range(10000):
   var id=ItemCatalog.roll(outcome,rng)
   check(id==ItemCatalog.roll(outcome,twin) and id in ItemCatalog.IDS,"fixedseed valid reward")
   reached[id]=true
  check(reached.size()==20,"seed sweep all20")
 # Migration preserves all old16, rank/campaign/receipt; new stocks persist normally.
 var p=fresh()
 for id in ItemCatalog.IDS:p.inventory[id]=7
 p.item_loadout=["guardian_heart","time_freeze"];p.xp=8200
 p.equipped=["first_aid"];p.next_match_id=3
 p.pending_spins=[{"match_id":1,"item":"smoke","result":"victory","quantity":4}]
 check(p.save_profile(),"all20 inventory saves")
 var reload=PlayerProfile.new(p.path)
 check(reload.load_profile() and reload.xp==8200 and reload.equipped==["first_aid"],"rank and perk persist")
 for id in ItemCatalog.IDS:check(reload.inventory[id]==7,"stack persists "+id)
 check(reload.item_loadout==p.item_loadout,"two Legendary equipped without spending")
 check(reload.claim_spin(1).item=="smoke" and reload.inventory.smoke==7,"old receipt no regrant")
 check(reload.claim_spin(1).is_empty(),"receipt no double claim")
 # Every new reward is granted through real settlement; reload/reveal cannot duplicate it.
 for desired in NEW:
  var seed_value=0
  var finder=RandomNumberGenerator.new()
  while seed_value<100000:
   finder.seed=seed_value
   if ItemCatalog.roll("victory",finder)==desired:break
   seed_value+=1
  var m=fixture();var a=actor(m,[desired]);a.p.reward_rng.seed=seed_value
  m.hunter.hp=0;m.result="victory"
  check(not a.p.settle_match(a.id,m).is_empty(),"real victory settles "+desired)
  check(a.p.inventory[desired]==7 and a.p.pending_spin().item==desired,"Legendary legitimate stack reward")
  var disk=PlayerProfile.new(a.p.path)
  check(disk.load_profile() and disk.inventory[desired]==7,"reward fixed on disk")
  check(disk.settle_match(a.id,m).is_empty(),"replayed settlement no award")
  check(not disk.claim_spin(a.id).is_empty() and disk.inventory[desired]==7,"reveal no extra stock")
  check(disk.claim_spin(a.id).is_empty(),"repeated reveal blocked")
 # Same-match budget survives profile reload/rebinding; invalid counters reject safely.
 var lm=fixture();var la=actor(lm,["cursed_fortune","time_freeze"])
 check(use(la,lm),"persisted budget first activation")
 var lp=PlayerProfile.new(la.p.path)
 check(lp.load_profile() and int(lp.active_match.legendary_used)==1,"budget persisted atomically")
 var lm2=fixture();lp.bind_items(lm2,la.id)
 check(not lp.activate_item(1,lm2,la.id) and lp.inventory.time_freeze==3,"same-id reload cannot bypass Legendary limit")
 var raw=JSON.parse_string(FileAccess.get_file_as_string(lp.path))
 for malformed in [-1,1.5,"1",2]:
  var bad=raw.duplicate(true);bad.active_match.legendary_used=malformed
  var bad_path=fresh().path
  var writer=FileAccess.open(bad_path,FileAccess.WRITE);writer.store_string(JSON.stringify(bad));writer.close()
  check(lp._decode(bad_path).is_empty(),"malformed Legendary counter rejected safely")
 var legacy_active=raw.duplicate(true);legacy_active.active_match.erase("legendary_used")
 var legacy_path=fresh().path
 var legacy_writer=FileAccess.open(legacy_path,FileAccess.WRITE);legacy_writer.store_string(JSON.stringify(legacy_active));legacy_writer.close()
 check(not lp._decode(legacy_path).is_empty(),"older active snapshot missing counter accepted")
 # Fresh matches receive a fresh budget, while old sixteen-item profiles preserve stacks.
 var next_entry=lp.begin_match("standard");var next_model=fixture();lp.bind_items(next_model,next_entry.id)
 check(next_model.items.legendary_used==0 and lp.activate_item(1,next_model,next_entry.id),"new match resets budget only for new ID")
 var old_profile=fresh()
 for id in ItemCatalog.IDS:
  if not id in NEW:old_profile.inventory[id]=11
 old_profile.item_loadout=["smoke","feather"]
 old_profile.xp=3800;old_profile.equipped=["first_aid"]
 check(old_profile.save_profile(),"old16 fixture saves without Legendary keys")
 var old_disk=PlayerProfile.new(old_profile.path)
 check(old_disk.load_profile() and old_disk.item_loadout==["smoke","feather"],"old16 loadout preserved")
 for id in ItemCatalog.IDS:
  check(int(old_disk.inventory.get(id,0))==(0 if id in NEW else 11),"migration preserves oldstock and no freeLegendary")
 for outcome in ["victory","defeat"]:
  for id in NEW:
   check(is_equal_approx(ItemCatalog.probability(outcome,ItemCatalog.IDS.find(id)),1.0 if outcome=="victory" else .25),"exact visible probability "+outcome+id)
 # Actual freeze movement/cooldown/attack progress, economy unaffected at frame boundaries.
 for mode in ["standard","hard","hell"]:
  for boss in [false,true]:
   for delta in [.1,.5,1.0,4.0]:
    var m=fixture(mode);var a=actor(m,["time_freeze"]);var h=m.hunter;var r=m.player()
    h.transformed=boss;h.cooldown=10
    h.boss_cooldowns={"scythe":20.0,"siege":20.0,"surge":20.0}
    var gold=r.gold;var rate=r.income_rate();var hp=r.door_hp
    check(use(a,m),"freeze activates "+mode)
    var duration=1.5 if boss else 3.0
    check(is_equal_approx(m.items.timers.time_freeze,duration),"boss resistance exact")
    var initial=h.position;var elapsed=0.0
    while elapsed+delta<duration-.001:
     m.tick(delta);elapsed+=delta
     check(h.position==initial and h.cooldown==10 and r.door_hp==hp,"freeze halts attack and movement")
     check(is_equal_approx(r.gold-gold,rate*elapsed),"economy continues")
    var before=h.cooldown
    m.tick(duration-elapsed+.25)
    check(is_equal_approx(h.cooldown,before-.25),"fractional expiry only remaining .25 advances")
    check(not m.items.timers.has("time_freeze"),"freeze expires")
    check(a.p.inventory.time_freeze==2 and not use(a,m),"one stock and no repeatedfreeze")
 # Freeze preserves real charged windup, transformation resumes, and exposed pursuit pauses.
 for state in ["charged","transform","exposed"]:
  var m=fixture("hell");var a=actor(m,["time_freeze"]);var h=m.hunter
  if state=="charged":warning(m)
  if state=="transform":h._begin_transformation(m)
  if state=="exposed":h.position=m.map_data.hunter_spawn;h.state=HunterState.State.MOVE
  var transform=h.transform_remaining;var cooldown=h.cooldown;var pos=h.position
  check(use(a,m),"freeze valid "+state)
  if state=="exposed":m.player().sleeping=false;m.player_position=m.player().bed_position()
  m.tick(.5)
  check(h.position==pos,"freeze no movement "+state)
  if state=="charged":check(h.boss_attack=="siege" and h.cooldown==cooldown,"freeze retains charged warning")
  if state=="transform":check(h.transform_remaining==transform,"freeze retains transformation")
  m.tick(4)
  if state=="transform":check(h.state!=HunterState.State.TRANSFORM,"transformation resumes and completes")
  if state=="exposed":check(h.position!=pos,"exposed pursuit resumes")
 # Seal all real special warning types; preserve cooldown and subsequent AI.
 for attack in BossCatalog.ATTACKS:
  var m=fixture("hell");var a=actor(m,["reaper_seal"]);var h=m.hunter
  warning(m,attack)
  var cds=h.boss_cooldowns.duplicate();var hp=m.player().door_hp
  check(use(a,m),"seal real "+attack)
  check(h.boss_attack=="" and h.boss_cooldowns==cds,"seal cancels current only; keeps special cooldown")
  check(h.cooldown>=1.25 and a.p.inventory.reaper_seal==2,"balanced recovery and one stock")
  m.tick(.1)
  check(m.player().door_hp==hp,"interrupted hit absent")
  h.boss_cooldowns={"scythe":0.0,"siege":0.0,"surge":0.0};h.cooldown=0
  m.tick(.01)
  check(h.boss_attack!="","boss can start later special")
  m.tick(2)
  check(m.result=="" and h.state!=HunterState.State.DEAD,"boss remains functional")
 for invalid in ["ordinary","dead","no_warning","expired","wrongtarget","broken","transform","paused"]:
  var m=fixture();var a=actor(m,["reaper_seal"]);warning(m)
  match invalid:
   "ordinary":m.hunter.transformed=false
   "dead":m.hunter.hp=0
   "no_warning":m.hunter.boss_attack=""
   "expired":m.hunter.cooldown=0
   "wrongtarget":m.hunter.boss_attack_target=1
   "broken":m.player().door_hp=0
   "transform":m.hunter.state=HunterState.State.TRANSFORM
   "paused":m.running=false
  check(not use(a,m) and a.p.inventory.reaper_seal==3,"invalid seal no consumption "+invalid)
  check(m.items.cooldown==0 and m.items.events.is_empty() and a.p.item_error!="","invalid reason no false FX/cooldown")
 # Heart real lethal hit, same-frame second impact, no repeat and no overheal.
 for mode in ["standard","hard","hell"]:
  for stage in StageCatalog.STAGES:
   var m=fixture(mode,stage.id);var a=actor(m,["guardian_heart"]);var r=m.player()
   check(not use(a,m) and a.p.inventory.guardian_heart==3,"Heart automatic only")
   r.door_hp=100;m.hunter._damage_door(r,m,25)
   check(r.door_hp==75 and a.p.inventory.guardian_heart==3,"nonfatal hit no Heart")
   m.hunter._damage_door(r,m,1000)
   check(r.door_hp>0 and r.door_hp<=r.max_hp() and r.alive,"Heart intercepts lethal intact door")
   check(a.p.inventory.guardian_heart==2 and m.items.legendary_used==1,"Heart exactly one stock and shared limit")
   check(r.door_damage_taken>=0,"Heart damage accounting nonnegative")
   m.hunter._damage_door(r,m,1)
   check(r.door_hp>0 and a.p.inventory.guardian_heart==2,"sameframe shield safely absorbs small second hit")
   m.items.tick(4,m)
   m.hunter._damage_door(r,m,100000)
   check(r.door_hp==0 and a.p.inventory.guardian_heart==2,"shield expires; later lethal breaks no infinite rescue")
 # Automatic Heart never fires for invalid or unequipped owners, even under lethal test damage.
 for invalid in ["no_stock","unequipped","paused","terminal","eliminated","broken","open","unoccupied","read_only"]:
  var m=fixture();var a=actor(m,["guardian_heart"]);var r=m.player()
  r.door_hp=10
  match invalid:
   "no_stock":a.p.inventory.guardian_heart=0
   "unequipped":a.p.active_match.items=[]
   "paused":m.running=false
   "terminal":m.result="defeat"
   "eliminated":r.alive=false
   "broken":r.door_hp=0
   "open":r.closed=false
   "unoccupied":r.sleeping=false
   "read_only":a.p.read_only=true
  var stock=a.p.inventory.guardian_heart
  m.hunter._damage_door(r,m,20)
  check(a.p.inventory.guardian_heart==stock and m.items.legendary_used==0 and r.door_hp==0,"invalid Heart no rescue/stockloss "+invalid)
 # No save means no spend/no effect, and retry remains valid for manual Legendary.
 for id in NEW:
  var m=fixture();var a=actor(m,[id]);var r=m.player()
  if id=="reaper_seal":warning(m)
  var old_path=a.p.path;a.p.path="user://nonexistent-legendary-dir/profile.json"
  var gold=r.gold
  if id=="guardian_heart":
   r.door_hp=10;m.hunter._damage_door(r,m,20)
   check(r.door_hp==0,"failed save no Heart revival")
  else:check(not use(a,m),"failed save no activation "+id)
  check(a.p.inventory[id]==3 and m.items.legendary_used==0 and int(a.p.active_match.get("legendary_used",0))==0 and r.gold==gold,"failed save no stock/gold/limit change "+id)
  a.p.path=old_path
 # Fortune exact money, actual offense, nonstacking, and expiry derived baseline restoration.
 for mode in ["standard","hard","hell"]:
  var m=fixture(mode);var base=fixture(mode);var a=actor(m,["cursed_fortune","time_freeze"])
  var gold=m.player().gold
  check(use(a,m) and m.player().gold==gold+500,"Fortune exact500 "+mode)
  check(a.p.inventory.cursed_fortune==2 and m.items.legendary_used==1,"Fortune consumesonce")
  m.tick(.1);base.tick(.1)
  check(m.hunter.damage>base.hunter.damage and m.hunter.interval<base.hunter.interval,"curse actual damage and pressure")
  check(not use(a,m,1) and a.p.inventory.time_freeze==3,"shared Legendary cap blocks secondtype")
  m.items.tick(21,m);base.items.tick(21,base)
  m.items.tick(.01,m);base.items.tick(.01,base)
  m.hunter.tick(.01,m);base.hunter.tick(.01,base)
  check(is_equal_approx(m.hunter.damage,base.hunter.damage) and is_equal_approx(m.hunter.interval,base.hunter.interval),"curse expires without permanentstat corruption")
  check(not use(a,m) and a.p.inventory.cursed_fortune==2,"cannot duplicate500afterexpiry")
 # Manual legendary spent blocks auto Heart; auto Heart blocks other Legendary.
 for first in ["manual","automatic"]:
  var m=fixture();var a=actor(m,["cursed_fortune","guardian_heart"]);var r=m.player()
  if first=="manual":
   check(use(a,m),"manual first succeeds")
   r.door_hp=10;m.hunter._damage_door(r,m,20)
   check(r.door_hp==0 and a.p.inventory.guardian_heart==3,"used limit prevents auto spend")
  else:
   r.door_hp=10;m.hunter._damage_door(r,m,20)
   check(not use(a,m) and a.p.inventory.cursed_fortune==3,"auto uses shared cap")
 # Every manual invalid state leaves inventory, cooldown and FX intact.
 for id in ["time_freeze","cursed_fortune"]:
  for invalid in ["paused","terminal","no_stock","wrong_id","dormant","dead"]:
   var m=fixture();var a=actor(m,[id])
   match invalid:
    "paused":m.running=false
    "terminal":m.result="defeat"
    "no_stock":a.p.inventory[id]=0
    "wrong_id":a.id+=9
    "dormant":m.hunter.state=HunterState.State.DORMANT
    "dead":m.hunter.hp=0
   var stock=a.p.inventory[id]
   check(not use(a,m) and a.p.inventory[id]==stock,"invalid manual "+id+invalid)
   check(m.items.cooldown==0 and m.items.events.is_empty(),"invalid no feedback animation")
 cleanup()
 print("LEGENDARY_QA_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
