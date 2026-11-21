extends SceneTree
## Run with the desktop preview flags. Full Story matches use earned cash, matched
## profile copies, physical input and production settlement. Rare-item fixtures
## below isolate combat windows and are excluded from Story outcomes.
const STEP := .1
const BASE := 73191
const INDEPENDENT_BASE := 310087
var checks := 0
var errors: Array[String] = []
var serial := 0
var funded_profile_path := ""
var prefix := "user://phase23-item-" + str(Time.get_ticks_usec()) + "-"

func _initialize():
 for flag in ["PLAYER_FIRST","LIVING_DORM","LIVING_NIGHTMARE","PHASE16","WEAPON_FEEDBACK","VISUAL_REBIRTH","FULL_ROOM_GRID","PROCEDURAL_MAPS_V2","CLOSE_QUARTERS","BUILDING_SCALE","SURVIVOR_REBIRTH","PERFORMANCE_PREVIEW","TACTICAL_UI","HUNTER_INTELLIGENCE"]:
  OS.set_environment("NIGHTFALL_"+flag,"1")
 call_deferred("run")

func check(ok: bool, title: String):
 checks += 1
 if not ok:
  errors.append(title)
  push_error(title)

func fresh() -> PlayerProfile:
 serial += 1
 var wallet := PlayerProfile.new(prefix + str(serial) + ".json")
 wallet.reward_rng.seed=120031
 return wallet

func earn_and_compare(base: int) -> Dictionary:
 var wallet := fresh()
 wallet.story=StoryProgress.fresh(base)
 var funding := []
 while wallet.rm_cash<18 and funding.size()<6:
  funding.append(play_story(wallet,"standard","",false))
  if not errors.is_empty():return {}
 check(wallet.rm_cash>=18,"real prior settlements fund the most expensive common item")
 funded_profile_path=wallet.path
 var rows := []
 for item: String in OnboardingCatalog.PRICES:
  var pair := []
  for equipped in [false,true]:
   var copy:=fresh()
   check(DirAccess.copy_absolute(wallet.path,copy.path)==OK and copy.load_profile(true),"copy the same persisted earned profile")
   var before: int=copy.rm_cash
   if equipped:
    check(copy.buy_common(item,copy.purchase_serial+1) and copy.rm_cash==before-OnboardingCatalog.PRICES[item],"buy "+item+" from earned funds")
    check(copy.equip_item(item),"equip "+item)
   var row:=play_story(copy,"hard",item,equipped)
   row["shop_spent"]=before-int(row.get("cash_at_entry",before))
   pair.append(row)
   if not errors.is_empty():return {}
  check(pair[0].seed==pair[1].seed and pair[0].room==pair[1].room,"matched opportunity "+item)
  rows.append({"item":item,"without":pair[0],"with":pair[1]})
 return {"funding_matches":funding,"opening_cash":wallet.rm_cash,"matched_story":rows}

func setup(wallet: PlayerProfile, mode: String) -> MatchModel:
 var level:=StoryProgress.position(wallet.story,mode)
 var mission:=StoryCatalog.mission(level)
 var entry:=wallet.begin_match(mode,mission.stage_id,true,level)
 if entry.is_empty():return null
 var model:=MatchModel.new()
 model.reset(entry.story.seed)
 if not model.configure_match(mode,RankCatalog.bonuses(entry.equipped)) or not model.configure_stage(mission.stage_id) or not model.configure_balance():return null
 model.story_level=level
 model.preparation=maxf(model.preparation,mission.preparation)
 if not model.configure_strategy(entry.story.seed,entry.archetype,entry.contract,entry.id):return null
 StoryCatalog.apply_encounter(model)
 if not model.begin_room_rush(entry.id):return null
 wallet.bind_items(model,entry.id)
 return model

func walk(model: MatchModel, route: Array) -> bool:
 for waypoint: Vector2 in route:
  while model.player_position.distance_to(waypoint)>.25:
   var old: Vector2=model.player_position
   var delta:=minf(STEP,old.distance_to(waypoint)/model.SURVIVOR_SPEED)
   model.move_player(old.direction_to(waypoint),delta)
   model.tick(delta)
   if old.distance_to(model.player_position)<.001 or model.time>60:return false
 return true

func take_room(model: MatchModel) -> bool:
 var routes:=model.room_rush.routes_to_vacant_rooms(model,model.player_position)
 var best:=-1
 var distance:=INF
 for index: int in routes:
  var length:=RoomRush.route_length(model.player_position,routes[index])
  if length<distance:
   best=index
   distance=length
 if best<0 or not walk(model,routes[best]) or not model.claim_room(best):return false
 var room:=model.player()
 for side: Vector2 in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
  var point:=room.bed_position()+54.0*side
  if not room.floor_has_point(point) or not model.can_walk(point,best):continue
  var path:=model.room_rush.safe_path(model,model.player_position,point,best)
  if not path.is_empty() and walk(model,path):return model.sleep_player()
 return false

func play_story(wallet: PlayerProfile, mode: String, item: String, equipped: bool) -> Dictionary:
 var model:=setup(wallet,mode)
 if model==null or not take_room(model):
  check(false,"enter Story and reach a bed with movement")
  return {}
 var room:=model.player()
 var balance: int=wallet.rm_cash
 var inventory:=int(wallet.inventory.get(item,0))
 var next: float=model.time
 var first_needle:=-1.0
 var first_dynamo:=-1.0
 var activation:=-1.0
 var radar_spend:=-1.0
 var item_amount:=0.0
 var reserve_door := item=="radar"
 var first_contact:=-1.0
 while model.result=="" and model.time<900.0:
  if first_contact<0 and room.door_damage_taken>0:first_contact=model.time
  if model.time>=next:
   next+=1.5
   if equipped and activation<0:
    var should_use:=item in ["gold","battery"] or (item=="repair" and room.door_hp<room.max_hp()*.74) or (item=="radar" and model.hunter.state!=HunterState.State.DORMANT)
    if should_use and wallet.activate_item(0,model,wallet.active_match.id):
     activation=model.time
     item_amount=float(model.items.events[-1].value)
   # A radar user can follow a reported approach before the first blow.
   # Without radar the same player waits for their own door's visible hit.
   if reserve_door and (room.door_damage_taken>0 or model.items.timers.has("radar") and model.hunter.target==room.index):
    if model.upgrade_door():
     radar_spend=model.time
     reserve_door=false
   elif room.door_hp<room.max_hp()*.55 and model.repair_door():pass
   elif room.bed_level<1 and room.upgrade_bed():pass
   elif not BotAI.has_kind(room,"turret") and BotAI.tactical_build(room,"turret"):pass
   elif not reserve_door and room.door_level<1 and room.upgrade_door():pass
   elif room.bed_level<2 and room.upgrade_bed():pass
   elif not BotAI.has_kind(room,"generator") and BotAI.tactical_build(room,"generator"):pass
   elif not reserve_door and room.door_level<2 and room.upgrade_door():pass
   elif room.buildings.size()<4:BotAI.tactical_build(room,"turret")
   else:
    for id in room.buildings:
     if room.buildings[id].kind=="turret" and room.buildings[id].level<3 and room.upgrade_building(id):break
   if first_needle<0 and BotAI.has_kind(room,"turret"):first_needle=model.time
   if first_dynamo<0 and BotAI.has_kind(room,"generator"):first_dynamo=model.time
  model.tick(STEP)
 var bots:=[]
 for npc: RoomState in model.rooms:
  if npc.owner<=0:continue
  var ledger: Dictionary=npc.ledger.totals
  var gold: float=25+ledger.production_g+ledger.other_g+ledger.refund_g-ledger.spent_g-ledger.loss_g
  var power: float=ledger.production_e+ledger.other_e+ledger.refund_e-ledger.spent_e-ledger.loss_e
  check(absf(gold-npc.gold)<.001 and absf(power-npc.electricity)<.001 and npc.gold>=0 and npc.electricity>=0,"NPC earned wallet reconciles "+npc.profile)
  bots.append({"room":npc.index+1,"profile":npc.profile,"damage":npc.damage_dealt,"gold_spent":ledger.spent_g,"power_spent":ledger.spent_e})
 var depleted:=inventory-int(wallet.inventory.get(item,0))
 check(depleted==int(activation>=0),"one stock per successful item use "+item)
 var receipt:=wallet.settle_match(wallet.active_match.id,model)
 check(model.terminal_recorded and not receipt.is_empty(),"real terminal settlement")
 if not wallet.pending_spin().is_empty():wallet.claim_spin(wallet.pending_spin().match_id)
 return {"level":model.story_level,"difficulty":mode,"seed":model.map_seed,"room":room.index+1,"match_id":receipt.get("match_id",-1),"result":model.result,
  "seconds":snappedf(model.time,.1),"first_door_damage_at":snappedf(first_contact,.1),"activation_at":snappedf(activation,.1),"activation_value":item_amount,
  "radar_policy_door_upgrade_at":snappedf(radar_spend,.1),"door_hp_end":room.door_hp,"door_damage":room.door_damage_taken,"player_damage":room.damage_dealt,
  "bots":bots,"spent_gold":room.ledger.totals.spent_g,"spent_power":room.ledger.totals.spent_e,"first_needle_at":snappedf(first_needle,.1),"first_dynamo_at":snappedf(first_dynamo,.1),
  "stock_decrement":depleted,"cash_at_entry":balance,"cash_award":receipt.get("rm_cash",0)}

# Deliberately arranged combat windows. One diagnostic stock of each non-shop
# reward models an already-owned drop. No claim about its acquisition rate.
func window(item: String, equipped: bool) -> Dictionary:
 var wallet:=fresh()
 check(DirAccess.copy_absolute(funded_profile_path,wallet.path)==OK and wallet.load_profile(true),"initialize controlled window")
 if equipped:
  if OnboardingCatalog.PRICES.has(item):
   check(wallet.buy_common(item,wallet.purchase_serial+1),"purchase common fixture item")
  else:
   wallet.inventory[item]=1
  check(wallet.equip_item(item),"equip diagnostic "+item)
 var model:=setup(wallet,"hard")
 if model==null or not take_room(model):
  check(false,"prepare controlled room")
  return {}
 var room:=model.player()
 var h=model.hunter
 # Allow actual earned income and the other survivors to physically claim.
 while model.time<model.preparation-.2:model.tick(STEP)
 h.target=room.index
 h.position=room.door_approach()
 h.state=HunterState.State.ATTACK
 h.cooldown=.3
 h.tactical_cooldown=20.0
 h.boss_policy.enabled=false
 model.time=model.preparation+1.0
 var start: Vector2=h.position
 var duration:=2.0
 if item in ["radar","frost"]:
  start=model.map_data.hunter_spawn
  h.position=start
  h.state=HunterState.State.MOVE
  duration=1.5
 if item=="overdrive":
  check(BotAI.tactical_build(room,"turret"),"real paid turret for overdrive")
  h.cooldown=14.0
  duration=10.0
 if item=="guardian_heart":room.door_hp=10.0
 if item=="reaper_seal":
  h.transformed=true
  model.wrath.phase_announced=true
  check(model.wrath.begin("scythe_slash",model,room.index),"actual scythe cast opens counter window")
  duration=1.85
 var initial_door: float=room.door_hp
 var initial_damage: float=room.damage_dealt
 var initial_stock:=int(wallet.inventory.get(item,0))
 var active: bool=false
 var upgraded: bool=false
 var hp_before_counter: float=room.door_hp
 if equipped and item!="guardian_heart":
  active=wallet.activate_item(0,model,wallet.active_match.id)
  check(active,"activate during legitimate window "+item)
 if item=="radar" and model.items.timers.has("radar") and h.target==room.index:
  upgraded=model.upgrade_door()
 if item=="guardian_heart":
  model.apply_room_damage(room.index,room.max_hp(),"door strike")
 else:
  for _frame in range(roundi(duration/.05)):model.tick(.05)
 var travel:=start.distance_to(h.position)
 var spent:=initial_stock-int(wallet.inventory.get(item,0))
 check(spent==int(equipped),"stock consumption in controlled window "+item)
 return {"duration":0.0 if item=="guardian_heart" else duration,"stock_spent":spent,"activated":active or equipped and item=="guardian_heart",
  "radar_informed_paid_door_upgrade":upgraded,"hunter_target_room":h.target+1,"player_room":room.index+1,
  "door_hp_start":initial_door,"door_hp_end":room.door_hp,"door_hp_change":room.door_hp-hp_before_counter,
  "door_damage_taken":room.door_damage_taken,"door_hp_max":room.max_hp(),"hunter_displacement":travel,
  "player_shots":room.shots,"player_damage":room.damage_dealt-initial_damage,"guardian_shield_hp":model.items.guardian_shield_hp,
  "attacks":h.attacks,"boss_cast_completions":model.wrath.counts.get("scythe_slash",0),"boss_recovery_reason":model.wrath.last_end}

func windows() -> Array:
 var rows: Array=[]
 for item in ["radar","shield","frost","decoy","smoke","time_freeze","overdrive","guardian_heart","reaper_seal"]:
  var left:=window(item,false)
  var right:=window(item,true)
  if left.is_empty() or right.is_empty():return rows
  match item:
   "radar":check(right.radar_informed_paid_door_upgrade and not left.radar_informed_paid_door_upgrade,"radar-guided legal early door investment")
   "frost":check(right.hunter_displacement<left.hunter_displacement,"actual Frost approach slowed")
   "shield","decoy","smoke","time_freeze","guardian_heart","reaper_seal":check(right.door_hp_end>left.door_hp_end,"observed door protection "+item)
   "overdrive":check(right.player_damage>left.player_damage,"overdrive produces additional applied damage")
  rows.append({"item":item,"without":left,"with":right})
 return rows

# Enter the normal Hall state machine at a real entrance. Current HP and clock
# intentionally satisfy retreat eligibility. Both items see the same channel.
func hall_counter(item: String) -> Dictionary:
 var wallet:=fresh()
 check(DirAccess.copy_absolute(funded_profile_path,wallet.path)==OK and wallet.load_profile(true),"copy Hall fixture profile")
 wallet.inventory[item]=1
 check(wallet.equip_item(item),"equip Hall counter "+item)
 var m:=setup(wallet,"hard")
 if m==null or not take_room(m):
  check(false,"Hall fixture has a legitimate resident")
  return {}
 while m.time<m.preparation-.2:m.tick(STEP)
 var h=m.hunter
 h.target=m.player_room
 h.position=m.map_data.halls.north.entrance
 h.state=HunterState.State.MOVE
 h.hp=h.max_hp*.35
 h.boss_policy.enabled=false
 m.time=maxf(m.haunt_recovery.available_at,m.preparation+40)+1.0
 check(m.haunt_recovery.try_retreat(h,m),"existing Hunter selects reachable Hall")
 for frame in range(240):
  if m.haunt_recovery.phase!="retreat":break
  m.tick(.05)
 if m.haunt_recovery.phase!="recover":
  check(false,"Hunter reaches real healing channel")
  return {}
 var hall: String=m.haunt_recovery.hall_id
 var before: float=h.hp
 check(wallet.activate_item(0,m,wallet.active_match.id),"legal use during a Hall channel "+item)
 m.tick(.05)
 if item=="decoy":
  check(not m.haunt_recovery.is_active() and h.hp<=before,"decoy still interrupts actual Hall recovery")
 else:
  check(m.haunt_recovery.phase=="recover" and h.hp>before and h.state==HunterState.State.RECOVER,"smoke changes priority without interrupting Hall recovery")
 return {"item":item,"hall":hall,"phase_after":m.haunt_recovery.phase,"hp_before":before,"hp_after":h.hp,"stock_after":wallet.inventory[item]}

func run():
 var args:=OS.get_cmdline_user_args()
 var independent:=args.has("--independent")
 var evidence:=earn_and_compare(INDEPENDENT_BASE if independent else BASE)
 if not independent and errors.is_empty():
  evidence["controlled_pairs"]=windows()
  evidence["hall_counters"]=[hall_counter("decoy"),hall_counter("smoke")]
 evidence["checks"]=checks
 evidence["failures"]=errors
 if not args.is_empty() and args[0]!="--independent":
  var file:=FileAccess.open(args[0],FileAccess.WRITE)
  if file==null:
   push_error("Unable to write item evidence at "+args[0])
   quit(2)
   return
  file.store_string(JSON.stringify(evidence,"  ")+"\n")
 for i in range(1,serial+1):
  for suffix in ["",".tmp",".bak"]:
   var path: String=prefix+str(i)+".json"+suffix
   if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
 print("PHASE23 ITEM QA checks=",checks," failures=",errors)
 quit(int(not errors.is_empty()))
