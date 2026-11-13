class_name ReplaySnapshot
extends RefCounted
const SCHEMA=2
const RULESET=5
const LEGACY_RULESET_MAX=4
const ROOM_NUMBERS=["gold","electricity","bed_level","door_level","door_hp","income_total","shots","damage_dealt","spent","occupied_seconds","door_damage_taken","income_multiplier","power_multiplier","door_multiplier","turret_multiplier","rescue_fraction","construction_actions","repair_actions","bot_timer","repair_factor","temporary_income"]
const ROOM_FLAGS=["alive","sleeping","closed","rescue_used","coupon_armed","breach_reacted"]
const ITEM_NUMBERS=["shield_hp","cooldown","burn_remaining","control_recovery","legendary_used","guardian_shield_hp"]
static func number(value,low=0.0,high=1e12) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and value>=low and value<=high
static func whole(value,low=0,high=1000000000000) -> bool:
 return number(value,low,high) and float(value)==floor(float(value))
static func point(value) -> bool:
 return value is Array and value.size()==2 and number(value[0],-10000,10000) and number(value[1],-10000,10000)
static func vec(value) -> Vector2:return Vector2(value[0],value[1])
static func pair(value: Vector2) -> Array:return [value.x,value.y]
static func valid_boosts(boosts: Dictionary) -> bool:
 var candidates=[[]];var ids=[]
 for perk in RankCatalog.PERKS:ids.append(perk.id);candidates.append([perk.id])
 for i in range(ids.size()):
  for j in range(i):candidates.append([ids[i],ids[j]])
 for selected in candidates:
  var expected=RankCatalog.bonuses(selected);var same=true
  for key in expected:
   if float(boosts.get(key,0.0 if key in ["gold","rescue"] else 1.0))!=float(expected[key]):same=false;break
  if same:return true
 return false
static func encode(model,use_counts: Dictionary={}) -> Dictionary:
 var run=model.endless
 if model.run_kind!="endless" or run==null or run.phase!="intermission" or run.completed!=run.sealed_wave or model.hunter.hp>0 or model.player()==null or not model.player().alive:return {}
 var data={"version":SCHEMA,"ruleset":RULESET,"run_id":run.run_id,"map":model.map_id,"difficulty":model.difficulty,"seed":run.seed_value,"rng":str(model.random.state),"completed":run.completed,"time":model.time,"preparation":model.preparation,"player_room":model.player_room,"player_position":pair(model.player_position),"bot_claimed":model.bot_claimed,"eliminations":model.eliminations,"shots":model.shots,"damage":model.damage_dealt,"boosts":model.match_boosts.duplicate(true),"expansion":model.expansion.snapshot(model),"evolution":model.evolution.snapshot(),"defense_refractory":model.defenses.shield_cooldowns.duplicate(true),"repair_refractory":model.defenses.repair_cooldowns.duplicate(true),"lure_refractory":model.defenses.lure_cooldown,"rooms":[],"items":{},"use_counts":use_counts.duplicate(true)}
 data.omen=run.omen.snapshot()
 for room in model.rooms:
  var saved={"owner":room.owner,"profile":room.profile,"bed_branch":room.bed_branch,"door_branch":room.door_branch,"trait":room.trait_id,"position":pair(room.resident_position),"main_damage":room.main_damage_dealt,"minion_damage":room.minion_damage_dealt,"buildings":[]}
  for key in ROOM_NUMBERS+ROOM_FLAGS:saved[key]=room.get(key)
  if room.spatial!=null:saved.construction=room.spatial.snapshot()
  saved.magic_state=room.magic_state.duplicate(true)
  saved.bot_timer=maxf(0,saved.bot_timer)
  for tile in room.buildings:
   var b=room.buildings[tile]
   var encoded={"tile":tile,"instance_id":int(b.get("instance_id",int(tile)+1)),"kind":b.kind,"level":b.level,"specialization":b.get("specialization",""),"invested_gold":b.get("invested_gold",0.0),"invested_power":b.get("invested_power",0.0),"cooldown":maxf(0,b.cooldown)}
   if room.spatial!=null:
    if not b.get("position") is Vector2:return {}
    encoded.position=pair(b.position)
   saved.buildings.append(encoded)
  data.rooms.append(saved)
 var fx=model.items
 for key in ITEM_NUMBERS:data.items[key]=fx.get(key)
 data.items.feather_used=fx.feather_used;data.items.timers=fx.timers.duplicate(true);data.items.decoy_point=pair(fx.decoy_point)
 data.items.trap={"position":pair(fx.trap.position),"remaining":fx.trap.remaining} if not fx.trap.is_empty() else {}
 return data if valid(data) else {}
static func valid(data) -> bool:
 if not data is Dictionary or not whole(data.get("version"),1,SCHEMA) or not whole(data.get("ruleset"),1,RULESET) or data.get("map","") not in MapCatalog.IDS or data.get("difficulty","") not in RankCatalog.DIFFICULTIES:return false
 if (data.version==1 and data.ruleset>LEGACY_RULESET_MAX) or (data.version==SCHEMA and data.ruleset!=RULESET):return false
 for key in ["run_id","seed","completed"]:
  if not whole(data.get(key),1):return false
 if data.has("omen") and not NightOmens.valid(data.omen,int(data.completed)):return false
 for key in ["time","preparation","shots","damage","eliminations"]:
  if not number(data.get(key)):return false
 if not whole(data.get("player_room"),0,5) or not whole(data.get("bot_claimed"),0,5) or not point(data.get("player_position")):return false
 if not data.get("rng") is String or data.rng.length()>20 or not data.rng.is_valid_int():return false
 var digits=data.rng.trim_prefix("-")
 var limit="9223372036854775808" if data.rng.begins_with("-") else "9223372036854775807"
 if digits.length()>19 or (digits.length()==19 and digits.casecmp_to(limit)>0):return false
 if str(int(data.rng))!=data.rng:return false
 if not data.get("boosts") is Dictionary or data.boosts.size()>8:return false
 for key in data.boosts:
  if key not in ["gold","door","income","power","damage","rescue","reaper"] or not number(data.boosts[key],0,100):return false
 if not valid_boosts(data.boosts):return false
 if not data.get("rooms") is Array or data.rooms.size()!=6 or not data.get("items") is Dictionary:return false
 if not data.get("use_counts",{}) is Dictionary:return false
 for key in data.get("use_counts",{}):
  if key not in ItemCatalog.IDS or not whole(data.use_counts[key],0,ItemCatalog.MAX_STOCK):return false
 if int(data.ruleset)>=4 and not data.has("expansion"):return false
 if data.has("expansion") and not RoomExpansion.valid(data.expansion,data.map):return false
 var owners=[];var map=MapCatalog.map(data.map)
 if data.has("expansion"):
  for i in range(6):map.rooms[i]=RoomExpansion.geometry(data.map,i,int(data.expansion.levels[i]),data.expansion.legacy)
 if vec(data.player_position).distance_to(map.rooms[int(data.player_room)].bed)>1:return false
 for i in range(6):
  var room=data.rooms[i]
  if not room is Dictionary or not whole(room.get("owner"),-1,5) or room.get("profile","") not in ["player"]+Catalog.BOT_PROFILES or room.get("trait","")!=StrategyCatalog.trait_for(i,data.map) or not point(room.get("position")) or not room.get("buildings") is Array or room.buildings.size()>map.rooms[i].tiles.size():return false
  if room.owner>=0:
   if room.owner in owners:return false
   owners.append(room.owner)
  if not number(room.get("main_damage",0)) or not number(room.get("minion_damage",0)):return false
  for key in ROOM_NUMBERS:
   if not number(room.get(key)):return false
  for key in ROOM_FLAGS:
   if not room.get(key) is bool:return false
  for key in ["shots","construction_actions","repair_actions"]:
   if not whole(room[key]):return false
  if room.sleeping and (not room.alive or not room.closed):return false
  if room.owner<0 and (room.sleeping or room.closed or not room.alive or not room.buildings.is_empty()):return false
  if room.owner>0 and room.sleeping and vec(room.position).distance_to(map.rooms[i].bed)>2:return false
  if not whole(room.bed_level,0,9) or not whole(room.door_level,0,9) or room.door_multiplier<=0 or room.temporary_income not in [1.0,1.5] or room.door_hp>Catalog.DOOR_HP[int(room.door_level)]*room.door_multiplier*StrategyCatalog.TRAITS[room.trait].door*StrategyCatalog.BRANCHES.get(room.get("door_branch",""),{}).get("hp",1.0)+.0001:return false
  for kind in ["bed","door"]:
   var branch=room.get(kind+"_branch","")
   if not branch is String or (branch!="" and branch not in StrategyCatalog.branches(kind)) or (room[kind+"_level"]>=5 and branch=="") or (room[kind+"_level"]<5 and branch!=""):return false
  for rule in {"door_multiplier":"door","income_multiplier":"income","power_multiplier":"power","turret_multiplier":"damage","rescue_fraction":"rescue"}:
   var field={"door_multiplier":"door","income_multiplier":"income","power_multiplier":"power","turret_multiplier":"damage","rescue_fraction":"rescue"}[rule]
   var expected=float(data.boosts.get(field,0.0 if field=="rescue" else 1.0)) if room.owner==0 else 0.0 if field=="rescue" else 1.0
   if not is_equal_approx(float(room[rule]),expected):return false
  if room.has("magic_state"):
   if not room.magic_state is Dictionary or room.magic_state.size()!=8:return false
   for key in ["stored","shield","reflect_cd","shield_cd","storage_time","heal_cd","disrupt","disrupt_guard"]:
    if not number(room.magic_state.get(key),0,350 if key=="stored" else 250 if key=="shield" else 30):return false
  var spatial=data.version==2 and i==int(data.player_room)
  if spatial and not room.has("construction"):return false
  if room.has("construction") and not spatial:return false
  var tiles=[];var instances=[]
  for b in room.buildings:
   if not b is Dictionary or b.get("kind","") not in Catalog.BUILDINGS or not whole(b.get("tile"),0,SpatialConstruction.MAX_ID-1 if spatial else map.rooms[i].tiles.size()-1) or int(b.tile) in tiles or not whole(b.get("level"),1,Catalog.building_max_level(b.kind)) or not b.get("specialization","") is String:return false
   tiles.append(int(b.tile))
   if data.version==2 or b.has("instance_id"):
    if not whole(b.get("instance_id"),1,1e12) or int(b.instance_id) in instances:return false
    instances.append(int(b.instance_id))
   var branch=b.specialization
   if branch!="" and (branch not in StrategyCatalog.branches(b.kind) or b.level<5):return false
   if b.level>=5 and branch=="":return false
   var ceiling=Vector2(Catalog.BUILDINGS[b.kind].gold,Catalog.BUILDINGS[b.kind].power)
   for level in range(1,int(b.level)):ceiling+=Catalog.upgrade_cost(b.kind,level)
   if branch!="":ceiling+=StrategyCatalog.BRANCH_FEE
   if not number(b.get("invested_gold"),0,ceiling.x+.0001) or not number(b.get("invested_power"),0,ceiling.y+.0001) or not number(b.get("cooldown"),0,24 if b.kind=="decoy" else 12 if b.kind=="shield" else 10):return false
  if spatial and not SpatialConstruction.valid_room(room,map.rooms[i]):return false
  var has_magic=room.buildings.any(func(b):return b.kind in MagicDefense.KINDS)
  if has_magic and not room.has("magic_state"):return false
  if room.has("magic_state"):
   var capacity=0.0;var shield_capacity=0.0
   for b in room.buildings:
    if b.kind=="plasma":capacity=maxf(capacity,MagicDefense.stats(b).capacity)
    if b.kind=="antenna":shield_capacity=maxf(shield_capacity,MagicDefense.stats(b).capacity)
   if room.magic_state.stored>capacity+.0001 or room.magic_state.shield>shield_capacity+.0001:return false
 if data.rooms[int(data.player_room)].owner!=0 or not data.rooms[int(data.player_room)].alive or not data.rooms[int(data.player_room)].sleeping:return false
 if owners.size()-1!=data.bot_claimed or not whole(data.eliminations,0,6) or not whole(data.shots):return false
 if int(data.ruleset)>=3 and not data.has("evolution"):return false
 if data.has("evolution") and not HunterEvolution.valid(data.evolution,data.rooms):return false
 if not data.get("defense_refractory",{}) is Dictionary or data.get("defense_refractory",{}).size()>6:return false
 for key in data.get("defense_refractory",{}):
  if key not in ["0","1","2","3","4","5"] or not number(data.defense_refractory[key],0,12):return false
 if not data.get("repair_refractory",{}) is Dictionary or data.get("repair_refractory",{}).size()>6:return false
 for key in data.get("repair_refractory",{}):
  if key not in ["0","1","2","3","4","5"] or not number(data.repair_refractory[key],0,5):return false
 if not number(data.get("lure_refractory",0),0,24):return false
 var fx=data.items
 for key in ITEM_NUMBERS:
  if not number(fx.get(key),0,10000):return false
 if not whole(fx.legendary_used,0,1) or not fx.get("feather_used") is bool or not fx.get("timers") is Dictionary or fx.timers.size()>20 or not point(fx.get("decoy_point")) or not fx.get("trap") is Dictionary:return false
 for key in fx.timers:
  if key not in ItemCatalog.IDS or not number(fx.timers[key],0,60):return false
 if not fx.trap.is_empty() and (not point(fx.trap.get("position")) or not number(fx.trap.get("remaining"),0,45)):return false
 return true
static func restore(data) -> MatchModel:
 if not valid(data):return null
 var model=MatchModel.new();var run=EndlessRun.new()
 if not run.configure(model,data.map,data.difficulty,int(data.seed),int(data.run_id),data.boosts):return null
 if data.has("expansion"):model.expansion.configure(model,data.expansion.legacy,data.expansion.levels)
 else:model.expansion.configure(model,true)
 model.random.state=int(data.rng);model.time=data.time;model.preparation=data.preparation
 model.player_room=int(data.player_room);model.player_position=vec(data.player_position);model.bot_claimed=int(data.bot_claimed)
 model.eliminations=int(data.eliminations);model.shots=int(data.shots);model.damage_dealt=data.damage
 for i in range(6):
  var room=model.rooms[i];var saved=data.rooms[i]
  room.bed_branch=saved.get("bed_branch","");room.door_branch=saved.get("door_branch","")
  room.main_damage_dealt=float(saved.get("main_damage",0));room.minion_damage_dealt=float(saved.get("minion_damage",0))
  room.owner=int(saved.owner);room.profile=saved.profile;room.resident_position=vec(saved.position)
  for key in ROOM_NUMBERS+ROOM_FLAGS:room.set(key,saved[key])
  room.magic_state=saved.get("magic_state",room.magic_state).duplicate(true)
  for b in saved.buildings:
   var building=b.duplicate(true);building.erase("tile");building.flash=0.0
   if saved.has("construction"):building.position=vec(b.position)
   room.buildings[int(b.tile)]=building
 var player=model.player()
 player.spatial=SpatialConstruction.new(player)
 if data.version==1:
  if not player.spatial.adopt_legacy():return null
 else:
  player.spatial.next_id=int(data.rooms[int(data.player_room)].construction.next_id)
  player.spatial.used_legacy=data.rooms[int(data.player_room)].construction.used_legacy.map(func(id):return int(id))
 # Fixed NPC rooms keep their historic placement and deterministic economy.
 for room in model.rooms:
  if room.owner==0:continue
  var uid=1;var taken=[]
  for b in room.buildings.values():
   if b.has("instance_id"):taken.append(int(b.instance_id))
  for b in room.buildings.values():
   if not b.has("instance_id"):
    while uid in taken:uid+=1
    b.instance_id=uid;taken.append(uid)
 for key in ITEM_NUMBERS:model.items.set(key,data.items[key])
 model.items.feather_used=data.items.feather_used;model.items.timers=data.items.timers.duplicate(true);model.items.decoy_point=vec(data.items.decoy_point)
 if data.has("evolution"):model.evolution.restore(data.evolution)
 model.defenses.repair_cooldowns=data.get("repair_refractory",{}).duplicate(true);model.defenses.shield_cooldowns=data.get("defense_refractory",{}).duplicate(true);model.defenses.lure_cooldown=float(data.get("lure_refractory",0))
 if not data.items.trap.is_empty():model.items.trap={"position":vec(data.items.trap.position),"remaining":data.items.trap.remaining}
 run.wave=int(data.completed);run.completed=int(data.completed);run.sealed_wave=run.completed;run.phase="intermission"
 model.evolution.evolution_level=maxi(model.evolution.evolution_level,clampi(1+int((run.wave-1)/5),1,10))
 if data.has("omen"):run.omen.restore(data.omen)
 model.hunter.hp=0;model.hunter.state=HunterState.State.DEAD
 return model
