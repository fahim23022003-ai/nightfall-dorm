extends SceneTree

var assertions := 0
var failures := 0
var records: Array[Dictionary] = []

func _initialize() -> void:
 call_deferred("run")

func check(condition: bool, detail: String) -> void:
 assertions+=1
 if not condition:
  failures+=1
  push_error(detail)

func setup_weapon(kind: String, branch: String="") -> MatchModel:
 var model:=MatchModel.new()
 model.weapon_feedback.enabled=true
 model.weapon_feedback.received.connect(func(event: Dictionary): records.append(event.duplicate()))
 records.clear()
 model.configure_strategy(37,"ravager")
 check(model.claim_room(0),"Claim test room")
 var room:=model.player()
 model.player_position=room.bed_position()
 check(model.sleep_player(),"Sleep before buying")
 room.gold=100000;room.electricity=100000;room.bed_level=8;room.door_level=8
 check(room._purchase_building(kind,0),"Pay for "+kind)
 if branch!="":
  for level in range(1,4):check(model.upgrade_building(0),"Pay for branch prerequisite")
  check(model.specialize_building(0,branch),"Pay for actual specialization")
 model.hunter.position=room.tile_position(0)+Vector2(82,0)
 model.hunter.state=HunterState.State.MOVE
 model.hunter.boss_policy.enabled=false
 model.hunter.hp=10000
 model.hunter.max_hp=10000
 model.hunter._model_ref=weakref(model)
 model.time=model.preparation+1.0
 return model

func fire(model: MatchModel) -> Dictionary:
 model._turrets(.016)
 var launch: Dictionary = records.back()
 check(launch.type=="launch" and launch.projectile_id>0,"Recorded unique physical launch")
 return launch

func test_weapon(kind: String, branch: String="") -> void:
 var model:=setup_weapon(kind,branch)
 var room:=model.player()
 var launch:=fire(model)
 var first_position: Vector2=model.projectiles[0].position
 model._advance_projectiles(.041)
 var second_position: Vector2=model.projectiles[0].position
 check(first_position==room.tile_position(0) and second_position.x>first_position.x,"Authoritative flight advances on separate ticks")
 model.hunter.position+=Vector2(8,20)
 var hp: float=model.hunter.hp
 model.time+=.8
 model._advance_projectiles(.8)
 var hit: Dictionary=records.back()
 check(hit.type=="impact" and hit.projectile_id==launch.projectile_id,"Exactly matching impact after moving target")
 check(hit.building_id==0 and hit.building_instance_id==room.buildings[0].instance_id and hit.specialization==branch and hit.level==room.buildings[0].level,"Precise paid source attribution")
 check(hit.position==model.hunter.position and hit.hp_before==hp and is_equal_approx(hit.damage,hp-model.hunter.hp),"Contact at target; number input equals HP actually removed")
 var info:=model.weapon_feedback.machine(room,0)
 check(info.hits==1 and is_equal_approx(info.damage,hit.damage) and info.last_damage==hit.damage,"Inspector totals use actual hit")
 if kind=="frost":check(hit.slow and model.hunter.suppression_remaining>0,"Frost marks genuinely applied suppression")
 if kind=="flame":
  model.defenses.tick(.25,model)
  var burn: Dictionary=records.back()
  check(burn.type=="burn" and burn.damage>0 and burn.projectile_id==hit.projectile_id and burn.building_instance_id==hit.building_instance_id,"Burn inherits projectile attribution")
  check(info.hits==1 and is_equal_approx(info.burn,burn.damage) and is_equal_approx(info.damage,hit.damage+burn.damage),"Burn is separate and counted once")
 if kind=="turret":
  model._turrets(2.0)
  var shot: Dictionary=model.projectiles[0]
  check(model.sell_building(0) and room._purchase_building("turret",0),"Replace a firing machine on the same pad")
  model._advance_projectiles(.8)
  check(records.back().building_instance_id==shot.building_instance_id and model.weapon_feedback.machine(room,0).is_empty(),"Late shot can't double-credit a replacement")

func test_block_and_cancel() -> void:
 var model:=setup_weapon("turret")
 var hp: float=model.hunter.hp
 model.evolution.shield=100
 fire(model)
 model._advance_projectiles(.8)
 check(records.back().reason=="blocked" and records.back().damage==0 and model.hunter.hp==hp and model.hunter.hit_flash==0,"Shield blocks without fake damage or hurt flash")
 model.hunter.phase_guard_remaining=1.2
 model._turrets(2.0)
 model._advance_projectiles(.8)
 check(records.back().reason=="immune" and records.back().damage==0 and model.hunter.hp==hp,"True phase immunity is distinct")
 model._turrets(2.0)
 model.hunter.state=HunterState.State.DEAD
 model._advance_projectiles(.8)
 check(records.back().type=="cancel" and records.back().reason=="invalid_target" and model.projectiles.is_empty(),"Dead target cancels existing flight")
 var view:=preload("res://scripts/weapon_presentation.gd").new()
 for event in records:view._receive(event)
 check(view.numbers.size()==2 and view.numbers.all(func(entry):return entry.amount==0),"Cancel produced no visual hit or number")
 check(view.contacts.size()==2,"Only blocked and immune contacts render")

func test_group(source: String) -> void:
 var model:=setup_weapon("turret")
 var room:=model.player()
 fire(model)
 model._advance_projectiles(.8)
 var hit: Dictionary=records.back()
 var view:=preload("res://scripts/weapon_presentation.gd").new()
 view.player_room=room.index
 view.number_mode=source
 for index in range(60):
  var sample:=hit.duplicate()
  sample.room=room.index if index%2==0 else 1
  view._receive(sample)
 var represented:=0.0
 for entry in view.numbers:represented+=entry.amount
 check(is_equal_approx(represented,hit.damage*(0 if source=="off" else 30 if source=="mine" else 60)),"All represented hits sum exactly in "+source)
 check(view.numbers.size()==(0 if source=="off" else 1),"Dense simultaneous damage coalesces in "+source)

func test_ally_and_reflection() -> void:
 var model:=setup_weapon("turret")
 var npc: RoomState=model.rooms[1]
 npc.owner=1;npc.sleeping=true;npc.gold=1000
 check(npc.build("turret",0),"NPC buys its own weapon")
 model.player().buildings[0].cooldown=20
 model.spawn_undead(1)
 var undead: UndeadAgent=model.minions[0]
 undead.position=npc.tile_position(0)+Vector2(90,0)
 model.hunter.position=Vector2(-500,-500)
 var launch:=fire(model)
 check(launch.room==npc.index and launch.target_id==undead.id,"NPC shot attributed to ally and actual minion")
 var hp: float=undead.hp
 model._advance_projectiles(.8)
 var hit: Dictionary=records.back()
 check(hit.damage==hp-undead.hp and hit.damage>0 and npc.minion_damage_dealt==hit.damage,"NPC minion impact credits actual loss to NPC")
 check(model.weapon_feedback.machine(npc,0).hits==1 and model.weapon_feedback.machine(model.player(),0).is_empty(),"Ally contribution does not go to player's identical pad ID")
 var room:=model.player()
 check(room._purchase_building("barrier",1),"Buy Mirror Barrier")
 hp=model.hunter.hp
 MagicDefense.absorb(model,room,100.0,1,{"type":"magic","element":"ice"})
 check(records.back().type=="reflect" and records.back().building_id==1 and records.back().damage==hp-model.hunter.hp,"Mirror reflects actual Magic without inventing a projectile")
 check(model.weapon_feedback.machine(room,1).hits==1,"Reactive defense has actual contribution")

func test_endless_checkpoint() -> void:
 var model:=MatchModel.new()
 check(model.configure_endless("abandoned_dorm","standard",71,71) and model.configure_balance(),"Prepare real Endless save")
 check(model.claim_room(0),"Claim for Endless")
 var room:=model.player()
 model.player_position=room.bed_position()
 check(model.sleep_player() and model.buy("turret",0),"Buy in actual Endless room")
 model.time=model.preparation+.1
 model.hunter.state=HunterState.State.ATTACK
 model.hunter.target=0
 model.hunter.position=room.door_approach()
 model.hunter.cooldown=99
 model.hunter.hp=1
 model.hunter.boss_policy.enabled=false
 for index in range(80):
  model.tick(.05)
  if model.endless.phase=="intermission":break
 check(model.endless.phase=="intermission","Real kill reaches saveable intermission")
 var snapshot:=ReplaySnapshot.encode(model)
 var reopened:=ReplaySnapshot.restore(JSON.parse_string(JSON.stringify(snapshot)))
 check(reopened!=null,"Optional weapon counters survive actual JSON checkpoint roundtrip")
 if reopened!=null:
  var info:=reopened.weapon_feedback.machine(reopened.player(),0)
  check(info.damage==1 and info.hits==1 and info.last_damage==1,"Reloaded counter still equals clamped killing blow")

func test_specialization_targets() -> void:
 var model:=setup_weapon("flame","wildfire")
 model.spawn_undead(2)
 var origin:=model.player().tile_position(0)
 for index in range(model.minions.size()):model.minions[index].position=origin+Vector2(65,20+index*23)
 model._turrets(.016)
 var targets: Array=records.map(func(event):return event.target_id)
 check(model.projectiles.size()==3 and targets.has(1) and targets.has(model.minions[0].id) and targets.has(model.minions[1].id),"Wildfire fires at three genuine targets with separate IDs")
 check(records.all(func(event):return event.aim_position==records[0].aim_position),"Multi-target volley shares one physical muzzle aim")
 model._advance_projectiles(.8)
 var hits:=records.filter(func(event):return event.type=="impact" and event.damage>0)
 check(hits.size()==3 and model.weapon_feedback.machine(model.player(),0).hits==3,"Three actual contacts credit one source machine")

func test_lane_reuse() -> void:
 var model:=setup_weapon("turret")
 fire(model)
 model._advance_projectiles(.8)
 var view:=preload("res://scripts/weapon_presentation.gd").new()
 for index in range(8):
  view.clock+=.135
  view._receive(records.back())
 view.numbers.remove_at(0)
 view.numbers.remove_at(2)
 view.clock+=.135
 view._receive(records.back())
 var used: Dictionary={}
 for entry in view.numbers:used[entry.lane]=true
 check(used.size()==view.numbers.size(),"An expired number leaves a free slot without overlapping a visible label")

func test_profile() -> void:
 var path:="user://weapon-feedback-%d.json" % OS.get_process_id()
 OS.set_environment("NIGHTFALL_PROFILE_PATH",path)
 var profile:=PlayerProfile.new(path)
 check(profile.settings.damage_numbers=="all","Legacy or new profile defaults to On")
 check(profile.update_setting("damage_numbers","combined") and not profile.update_setting("damage_numbers","fake"),"Persist allowed options and reject unknown mode")
 var reopened:=PlayerProfile.new(path)
 reopened.load_profile()
 check(reopened.settings.damage_numbers=="combined","Real serialized setting reloads")

func run() -> void:
 for kind: String in DefenseEffects.WEAPONS:test_weapon(kind)
 test_weapon("turret","precision")
 test_weapon("flame","wildfire")
 test_block_and_cancel()
 test_ally_and_reflection()
 test_endless_checkpoint()
 test_specialization_targets()
 test_lane_reuse()
 for mode: String in WeaponFeedback.NUMBER_MODES:test_group(mode)
 test_profile()
 print("WEAPON_FEEDBACK_CHECKS=",assertions," FAILURES=",failures)
 quit(int(failures>0))
