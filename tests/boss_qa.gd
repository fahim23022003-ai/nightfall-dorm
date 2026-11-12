extends SceneTree
# Independent state/combat QA. Large resource values below are explicit fixtures,
# never balance evidence; boss_matrix.gd uses earned resources only.
var checks=0
var failures=0
func check(ok: bool,label: String):
 checks+=1
 if not ok:
  failures+=1
  push_error("BOSS QA: "+label)
func events(model,kind): return model.presentation_events.filter(func(e):return e.type==kind)
func _initialize(): call_deferred("run")
func fixture(mode="standard",stage="stage_5",boss=true):
 var m=MatchModel.new()
 m.configure_match(mode)
 m.configure_stage(stage)
 m.claim_room(0)
 var r=m.player()
 m.player_position=r.bed_position()
 m.sleep_player()
 m.bot_claimed=5 # Focused fixtures intentionally isolate a single resident.
 r.gold=10000
 r.electricity=10000
 r.door_level=4
 r.door_hp=r.max_hp()
 m.time=m.preparation+100
 var h=m.hunter
 h.boss_policy.enabled=false
 h.state=HunterState.State.ATTACK
 h.target=0
 h.position=r.door_approach()
 h.cooldown=100
 h.tick(0.01,m) # Apply preexisting timed growth before measuring transformation HP.
 h.boss_policy.enabled=boss # All-map forced encounter fixture, including introductory maps.
 h.cooldown=0
 return m
func awaken(m):
 var h=m.hunter
 h.hp=h.max_hp*0.5
 h.tick(0.01,m)
 for i in range(25): h.tick(0.1,m)
 h.tick(0.01,m)
 h.position=m.player().door_approach()
 h.target=m.player_room
 h.state=HunterState.State.ATTACK
 h.cooldown=0
func select_attack(m,kind):
 var h=m.hunter
 h.boss_cooldowns={"scythe":100.0,"siege":100.0,"surge":100.0}
 h.boss_cooldowns[kind]=0
 h.cooldown=0
 h.tick(0.01,m)
func add_turrets(m):
 var r=m.player()
 var total=0
 for tile in range(r.tile_count()):
  if r.tile_position(tile).distance_to(m.hunter.position)<=Catalog.BUILDINGS.turret.range:
   check(r.build("turret",tile),"fixture buys real turret")
   total+=1
   if total==2: break
 check(total==2,"map has two turret positions in range")
func run():
 for mode in ["standard","hard","hell"]:
  for stage in StageCatalog.STAGES:
   var initial=MatchModel.new()
   initial.configure_match(mode)
   initial.configure_stage(stage.id)
   check(not initial.hunter.transformed and initial.hunter.state==HunterState.State.DORMANT,"normal form at start "+mode+stage.id)
   var expected=stage.number>=int(BossCatalog.ENCOUNTERS[mode].first_stage)
   check(initial.hunter.boss_policy.enabled==expected,"data-driven stage gating "+mode+stage.id)
   var m=fixture(mode,stage.id)
   var h=m.hunter
   var r=m.player()
   var identity=h.get_instance_id()
   h.hp=h.max_hp*0.5
   var before=h.hp
   var maximum=h.max_hp
   var original_position=h.position
   h.tick(0.01,m)
   check(h.state==HunterState.State.TRANSFORM and h.transformed,"valid transformation "+mode+stage.id)
   check(h.get_instance_id()==identity and h.hp==before and h.max_hp==maximum,"same entity no health refill")
   check(h.boss_attack=="" and h.position==original_position,"transition cancels attacks without teleport")
   var door_before=r.door_hp
   for step in range(23): h.tick(0.1,m)
   check(h.state==HunterState.State.TRANSFORM and r.door_hp==door_before,"transition cannot hit or complete early")
   h.tick(0.11,m)
   check(h.state==HunterState.State.SEEK and h.hp==before and h.max_hp==maximum,"finite transition preserves health")
   for step in range(10): h.tick(0.1,m)
   check(events(m,"boss_transform").size()==1 and events(m,"boss_awakened").size()==1,"once-only transition events")
   check(h.state in [HunterState.State.ATTACK,HunterState.State.MOVE],"valid state after transformation")
   # Real navigation from the map spawn to its door, with no hand-stepped teleport.
   h.position=m.map_data.hunter_spawn
   h.state=HunterState.State.SEEK
   var travelled=0.0
   for step in range(1500):
    var old=h.position
    h.tick(0.05,m)
    travelled+=old.distance_to(h.position)
    check(old.distance_to(h.position)<=h.speed*0.05+0.01,"movement bounded "+mode+stage.id)
    check(m.navigation_walkable(h.position),"navigation stays in walkable geometry "+mode+stage.id)
    if h.state==HunterState.State.ATTACK: break
   check(h.state==HunterState.State.ATTACK and h.position.distance_to(r.door_approach())<3 and travelled>0,"all-map boss reaches correct approach")
   check(r.alive and r.door_hp>0,"navigation does not bypass intact door")
   for kind in ["scythe","siege","surge"]:
    var combat=fixture(mode,stage.id)
    awaken(combat)
    var ch=combat.hunter
    var cr=combat.player()
    if kind=="surge": add_turrets(combat)
    var old_hp=cr.door_hp
    var old_attacks=ch.attacks
    select_attack(combat,kind)
    check(ch.boss_attack==kind and events(combat,"boss_warning").size()==1,"select actual "+kind+mode+stage.id)
    check(cr.door_hp==old_hp and ch.attacks==old_attacks,"warning precedes damage "+kind)
    check(ch.boss_cooldowns[kind]>0,"cooldown consumed at warning "+kind)
    var delay=float(BossCatalog.ATTACKS[kind].windup)
    ch.tick(delay-0.01,combat)
    check(cr.door_hp==old_hp and not ch.shadow_active(0),"no early effect "+kind)
    ch.tick(0.02,combat)
    check(ch.boss_attack=="" and ch.cooldown>0,"attack ends in recovery "+kind)
    if kind=="surge":
     check(cr.door_hp==old_hp and ch.shadow_active(0),"surge suppresses without artificial damage")
     var shots=combat.shots
     combat._turrets(0.1)
     check(combat.shots==shots,"suppressed room cannot launch")
     check(not ch.shadow_active(1),"neighboring room not suppressed")
     var hp=ch.hp
     ch.hurt(10)
     check(is_equal_approx(hp-ch.hp,10*BossCatalog.SURGE_VULNERABILITY),"surging boss is vulnerable counterplay")
     cr.door_hp-=100
     var door=cr.door_hp
     check(cr.repair_door() and cr.door_hp>door,"repair counterplay available during surge")
     ch.cooldown=100
     ch.tick(BossCatalog.SURGE_SECONDS+0.01,combat)
     check(not ch.shadow_active(0),"surge expires")
     combat._turrets(0.1)
     check(combat.shots>shots,"turrets resume after suppression")
    else:
     var applied=old_hp-cr.door_hp
     check(is_equal_approx(applied,ch.damage*BossCatalog.ATTACKS[kind].damage),"exact real damage "+kind)
     check(ch.attacks==old_attacks+1 and events(combat,"door_damage").size()==1,"one hit and damage number event "+kind)
     var feedback=load("res://scripts/horror_feedback.gd").new()
     feedback.update(0.01,combat)
     check(feedback.damage_numbers.size()==1 and is_equal_approx(feedback.damage_numbers[0].damage,applied),"floating number retains actual boss damage")
     ch.cooldown=0
     ch.tick(0.01,combat)
     check(ch.boss_attack=="","cooldown prevents repeated "+kind)
    # Existing projectile impacts still hurt the same target identity.
    combat.projectiles=[{"id":1,"from":ch.position,"position":ch.position,"target_id":1,"damage":10.0,"speed":200.0,"kind":"turret","room":0,"level":1,"age":0.0}]
    var hp=ch.hp
    combat._advance_projectiles(0.1)
    check(ch.hp<hp,"turret projectile damages boss "+kind)
   # Transformation can be killed, then never resumes or grants repeated victory.
   var dying=fixture(mode,stage.id)
   dying.hunter.hp=1
   dying.hunter.tick(0.01,dying)
   dying.hunter.hurt(10)
   check(dying.hunter.state==HunterState.State.DEAD and dying.hunter.transform_remaining==0,"death interrupts transformation")
   dying.tick(0.1)
   check(dying.result=="victory" and events(dying,"boss_death").size()==1,"death produces victory and one boss death event")
   for step in range(5): dying.tick(10)
   check(events(dying,"boss_death").size()==1 and events(dying,"boss_awakened").is_empty(),"terminal state never awakens or repeats death")
   dying.reset()
   check(not dying.hunter.transformed and dying.hunter.boss_attack=="" and dying.hunter.surge_remaining==0,"restart resets all boss state")
 # Interruptions must not redirect a pending damage packet.
 for cause in ["displaced","target_changed","target_dead","target_awake","door_broken","door_open","terminal"]:
  var m=fixture()
  awaken(m)
  select_attack(m,"siege")
  var before=m.player().door_hp
  match cause:
   "displaced": m.hunter.position=m.map_data.hunter_spawn
   "target_changed": m.hunter.target=1
   "target_dead": m.player().alive=false
   "target_awake": m.player().sleeping=false
   "door_broken": m.player().door_hp=0
   "door_open": m.player().closed=false
   "terminal": m.result="defeat"
  m.hunter.tick(2.0,m)
  check(m.hunter.boss_attack=="" and events(m,"boss_impact").is_empty(),"interrupted siege cannot apply "+cause)
  check(m.hunter.boss_cooldowns.siege>0,"interruption retains cooldown "+cause)
  if cause not in ["door_broken"]: check(m.player().door_hp==before,"interrupted target keeps HP "+cause)
 # Equal-valued turret dictionaries on different pads must use their own range.
 var ranged=fixture("standard","stage_5")
 awaken(ranged)
 var near=[]
 var far=[]
 for tile in range(ranged.player().tile_count()):
  if ranged.player().tile_position(tile).distance_to(ranged.hunter.position)<=Catalog.BUILDINGS.turret.range: near.append(tile)
  else: far.append(tile)
 check(near.size()>=2 and far.size()>=1,"range regression has near and distant pads")
 if near.size()>=2 and far.size()>=1:
  ranged.player().build("turret",near[0])
  ranged.player().build("turret",far[0])
  check(ranged.hunter._choose_boss_attack(ranged.player())!="surge","one in-range plus identical distant turret does not trigger Surge")
  ranged.player().buildings.clear()
  ranged.player().build("turret",far[0])
  ranged.player().build("turret",near[0])
  ranged.player().build("turret",near[1])
  check(ranged.hunter._choose_boss_attack(ranged.player())=="surge","two in-range turrets count despite identical distant first entry")
 # Exposed player handling must not override the transformation state.
 var exposed=fixture()
 exposed.player().sleeping=false
 exposed.player_position=exposed.hunter.position
 exposed.hunter.hp=exposed.hunter.max_hp*0.5
 exposed.tick(0.1)
 check(exposed.hunter.state==HunterState.State.TRANSFORM and exposed.result=="","exposed player does not cancel transformation or die on warning")
 var remaining=exposed.hunter.transform_remaining
 exposed.tick(0.1)
 check(exposed.hunter.transform_remaining<remaining,"exposed transformation advances real delta")
 # A real sleep action while a transforming hunter is inside another room must
 # defer its exit, preserving the once-only animation and physical navigation.
 for definition in StageCatalog.STAGES:
  var sleeping=fixture("hard",definition.id)
  var sh=sleeping.hunter
  sleeping.player().sleeping=false
  sh.position=sleeping.rooms[1].center()
  sh.state=HunterState.State.MOVE
  sh.hp=sh.max_hp*0.5
  sh.tick(0.01,sleeping)
  check(sh.state==HunterState.State.TRANSFORM,"sleep edge starts in real transformation "+definition.id)
  var origin=sh.position
  var duration=sh.transform_remaining
  check(sleeping.sleep_player(),"actual sleep action succeeds in different room "+definition.id)
  check(sh.state==HunterState.State.TRANSFORM and sh.transform_remaining==duration and sh.position==origin,"sleep cannot replace transformation with exit "+definition.id)
  for step in range(23): sh.tick(0.1,sleeping)
  check(sh.state==HunterState.State.TRANSFORM and sh.position==origin,"deferred exit cannot move before transition completes "+definition.id)
  sh.tick(0.11,sleeping)
  check(sh.state==HunterState.State.EXIT and sh.target==1 and sh.transform_remaining==0,"completed transformation resumes requested exit "+definition.id)
  var bounded=true
  var walkable=true
  for step in range(1500):
   var before_position=sh.position
   sh.tick(0.05,sleeping)
   if before_position.distance_to(sh.position)>sh.speed*0.05+0.01: bounded=false
   if not sleeping.navigation_walkable(sh.position): walkable=false
   if sh.state!=HunterState.State.EXIT: break
  check(bounded and walkable and sh.state==HunterState.State.SEEK and sh.position.distance_to(sleeping.rooms[1].corridor_anchor())<3,"deferred exit follows actual map geometry "+definition.id)
  sh.tick(0.05,sleeping)
  check(events(sleeping,"boss_transform").size()==1 and events(sleeping,"boss_awakened").size()==1,"sleep edge emits transformation completion exactly once "+definition.id)
 # Displacement ends both suppression and its corresponding vulnerability.
 var displaced=fixture()
 awaken(displaced)
 add_turrets(displaced)
 select_attack(displaced,"surge")
 displaced.hunter.tick(BossCatalog.ATTACKS.surge.windup+0.01,displaced)
 check(displaced.hunter.shadow_active(0),"displacement regression starts from real active Surge")
 displaced.hunter.position=displaced.map_data.hunter_spawn
 displaced.hunter.tick(0.01,displaced)
 var hp_before=displaced.hunter.hp
 displaced.hunter.hurt(10)
 check(displaced.hunter.state==HunterState.State.MOVE and displaced.hunter.surge_remaining==0 and not displaced.hunter.shadow_active(0),"displaced Surge immediately clears suppression")
 check(is_equal_approx(hp_before-displaced.hunter.hp,10.0),"displaced boss takes exactly10 damage, no lingering20percent vulnerability")
 displaced.hunter.surge_remaining=1.0 # Defensive stale-data guard: inactive state owns no effect.
 hp_before=displaced.hunter.hp
 displaced.hunter.hurt(10)
 check(is_equal_approx(hp_before-displaced.hunter.hp,10.0),"inactive Surge timer alone cannot amplify damage")
 # Ordinary hunter idle time must neither bank hits nor gain boss interruption delay.
 var idle=MatchModel.new()
 idle.time=idle.preparation+1
 for step in range(1000): idle.hunter.tick(0.1,idle)
 check(idle.hunter.cooldown<=0,"ordinary targetless hunter receives no boss cancellation recovery")
 idle.claim_room(0)
 idle.player_position=idle.player().bed_position()
 idle.sleep_player()
 idle.hunter.state=HunterState.State.ATTACK
 idle.hunter.target=0
 idle.hunter.position=idle.player().door_approach()
 for step in range(5): idle.hunter.tick(0.02,idle)
 check(idle.hunter.attacks==1,"ordinary hunter immediately attacks once after idle without half-second reset or burst")
 # Deterministic opening gate and deadline, including no valid room.
 var gated=fixture()
 gated.time=gated.preparation+BossCatalog.ENCOUNTERS.standard.opening-0.01
 gated.hunter.hp=1
 gated.hunter.tick(0.01,gated)
 check(not gated.hunter.transformed,"low health cannot bypass opening")
 gated.time=gated.preparation+BossCatalog.ENCOUNTERS.standard.opening
 gated.hunter.tick(0.01,gated)
 check(gated.hunter.state==HunterState.State.TRANSFORM,"opening exact boundary triggers")
 var targetless=MatchModel.new()
 targetless.configure_stage("stage_5")
 targetless.time=targetless.preparation+BossCatalog.ENCOUNTERS.standard.deadline
 targetless.hunter.state=HunterState.State.SEEK
 targetless.hunter.tick(0.01,targetless)
 check(targetless.hunter.state==HunterState.State.TRANSFORM and events(targetless,"boss_transform").size()==1,"deadline works without valid target and records global warning")
 var defeat=fixture()
 awaken(defeat)
 select_attack(defeat,"siege")
 defeat.player().alive=false
 defeat.tick(0.1)
 check(defeat.result=="defeat" and defeat.hunter.boss_attack=="" and defeat.hunter.surge_remaining==0,"player defeat clears active abilities")
 # Real profile settlement: no new reward path, existing dedup remains authoritative.
 var path="user://boss-qa-profile.json"
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
 var profile=PlayerProfile.new(path)
 for stage in StageCatalog.STAGES:
  var entry=profile.begin_match("standard",stage.id)
  var m=fixture("standard",stage.id)
  m.player().occupied_seconds=100
  awaken(m)
  m.hunter.hurt(1e9)
  m.tick(0.1)
  var reward=profile.settle_match(entry.id,m)
  check(not reward.is_empty() and reward.campaign.first_clear,"boss victory uses existing stage settlement "+stage.id)
  var xp=profile.xp
  check(profile.settle_match(entry.id,m).is_empty() and profile.xp==xp,"duplicate boss victory cannot duplicate XP")
 var reloaded=PlayerProfile.new(path)
 check(reloaded.load_profile() and reloaded.xp==profile.xp and reloaded.highest_unlocked_stage()==5,"boss campaign progress survives load")
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
 print("BOSS_QA_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
