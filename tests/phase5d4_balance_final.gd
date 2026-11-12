extends "res://tests/phase6_balance_campaign.gd"
# Final paired owner-feedback audit. Same baseline inputs; new mechanics explicitly tracked.
var results=[]
var total_extra_cases=0
func _initialize():call_deferred("run")
func structure(m,kind):
 var r=m.player();var level=r.bed_level if kind=="bed" else r.door_level
 if level>=9:return false
 if level==4:return r.specialize_structure(kind,"lucid" if kind=="bed" else "bulwark")
 return m.upgrade_bed() if kind=="bed" else m.upgrade_door()
func passive_act(m,policy):
 var r=m.player()
 if policy=="idle":return
 if r.door_hp<r.max_hp()*.75:
  if structure(m,"door") or m.repair_door():return
 if policy=="bed_door_only":
  if r.bed_level<2:m.upgrade_bed()
  elif r.door_level<2:m.upgrade_door()
  return
 if tiles(r,"generator").is_empty():empty(m,"generator");return
 if r.bed_level<1:m.upgrade_bed();return
 if r.door_level<1:m.upgrade_door();return
 if tiles(r,"repair").is_empty():empty(m,"repair");return
 if r.bed_level<2:m.upgrade_bed();return
 if r.door_level<2:m.upgrade_door();return
 if not upgrade_kind(m,"generator",4,1):return
 if r.bed_level<3:m.upgrade_bed();return
 if r.door_level<3:m.upgrade_door();return
 if not upgrade_kind(m,"economy",4,2):return
 if not upgrade_kind(m,"repair",4,1):return
 if r.bed_level<4:m.upgrade_bed();return
 if r.door_level<4:m.upgrade_door();return
 if r.bed_level<9 or r.door_level<9:
  structure(m,"bed" if r.bed_level<=r.door_level and r.bed_level<9 else "door")
func simulate_baseline(map_index,mode,archetype,seed_value,policy,high_npc=false):
 serial+=1
 var stage=StageCatalog.STAGES[map_index].id;var trait_choice=StrategyCatalog.TRAIT_IDS[map_index%3]
 var p=PlayerProfile.new(prefix+"5d4-"+str(serial)+".json");p.xp=3800 if policy=="active" else 0;p.equipped=["dreamer","first_aid"] if policy=="active" else [];p.tutorial_completed=true
 p.inventory={"shield":4,"guardian_heart":1} if policy=="active" else {};p.item_loadout=["shield","guardian_heart"] if policy=="active" else []
 for known in StageCatalog.STAGES:p.campaign_records[known.id]={"clears":1,"best_time":100.0,"best_damage":1000.0,"best_xp":100,"difficulty":"standard","first_match_id":1}
 while p.next_archetype(stage,mode)!=archetype:p.statistics.matches+=1;p.statistics.defeats+=1;p.next_match_id+=1
 var entry=p.begin_match(mode,stage,true);var m=MatchModel.new();m.reset(seed_value);m.configure_match(mode,RankCatalog.bonuses(p.equipped));m.configure_stage(stage);m.configure_strategy(seed_value,archetype,"",entry.get("id",0));p.bind_items(m,entry.id)
 var target=choose_room(m,trait_choice);var route=m.player_navigation_path(m.player_position,m.rooms[target].bed_position()+Vector2(31,49));var invalid=[];var funded={};var states={};var events={};var last_event=0;var steps=0;var first_hit=-1.0;var first_attack=-1.0;var first_player_hit=-1.0;var transform_time=-1.0;var min_eligible_ratio=1.0;var last_alive_ratio=1.0;var last_alive_time=0.0;var door_damage_total=0.0;var npc_damage=0.0;var hunter_pre_arrival_damage=0.0;var max_npc_door=0;var max_npc_bed=0;var max_npc_machine=0;var shield_uses=0;var drained_gold=0.0;var drained_power=0.0;var peak_minions=0;var peak_projectiles=0;var phases=[];var cast_counts={};var buffs=[];var domains=[];var last_kill_event=0;var max_evolution=0;var boss_ultimate_warnings=0
 while m.result=="" and steps<9000:
  if m.player_room<0:
   if m.rooms[target].owner>=0:
    target=choose_room(m,trait_choice)
    if target<0:invalid.append("no vacant room");break
    route=m.player_navigation_path(m.player_position,m.rooms[target].bed_position()+Vector2(31,49))
   if m.rooms[target].bounds().has_point(m.player_position):m.interact()
   else:walk_step(m,route)
  elif not m.player().sleeping:
   walk_step(m,route)
   if m.player_position.distance_to(m.player().bed_position())<=60:m.sleep_player()
  elif steps%2==0:
   if policy=="active":
    act(m,"suppression","frontline","");advance_weapon(m,"suppression")
    if m.hunter.target==m.player_room and m.hunter.state==HunterState.State.ATTACK and m.player().door_hp<m.player().max_hp()*.5 and p.activate_item(0,m,entry.id):shield_uses+=1
   else:passive_act(m,policy)
  if high_npc:
   for r in m.rooms:
    if r.owner>0 and not funded.has(r.index):r.gold+=10000;r.electricity+=1000;funded[r.index]=true
  states[HunterState.State.keys()[m.hunter.state]]=float(states.get(HunterState.State.keys()[m.hunter.state],0))+.1
  if m.hunter.hp>0:
   last_alive_ratio=m.hunter.hp/maxf(1,m.hunter.max_hp);last_alive_time=m.time
   if m.hunter.boss_policy.enabled and m.hunter_active_seconds()>=float(m.hunter.boss_policy.get("hp_opening",8.0)):min_eligible_ratio=minf(min_eligible_ratio,last_alive_ratio)
  m.tick(.1)
  peak_minions=maxi(peak_minions,m.minions.filter(func(u):return u.hp>0).size());peak_projectiles=maxi(peak_projectiles,m.projectiles.size());max_evolution=maxi(max_evolution,m.evolution.acquired.size())
  if peak_minions>10:invalid.append("minion cap")
  if m.wrath.domain_active() and m.minions.any(func(u):return u.hp>0):invalid.append("domain minions violate1v1")
  if first_hit<0 and m.hunter.hp<m.hunter.max_hp:first_hit=m.time
  if first_attack<0 and m.hunter.attacks>0:first_attack=m.time
  if m.time<=m.preparation:hunter_pre_arrival_damage=maxf(hunter_pre_arrival_damage,m.hunter.max_hp-m.hunter.hp)
  if m.hunter.transformed and transform_time<0:transform_time=m.time
  for e in m.presentation_events:
   if e.id<=last_event:continue
   last_event=e.id;events[e.type]=int(events.get(e.type,0))+1
   if e.type in ["boss_resource_drain","soul_drain"] and e.room==m.player_room:drained_gold+=float(e.get("gold",0.0));drained_power+=float(e.get("power",0.0))
   if e.type=="boss_phase":phases.append({"phase":e.phase,"time":m.time,"hp":m.hunter.hp})
   if e.type=="boss_ability_activate":
    cast_counts[e.ability]=int(cast_counts.get(e.ability,0))+1
    if e.ability=="crimson_execution":domains.append({"room":e.room,"owner":m.rooms[e.room].owner,"time":m.time,"hp":m.hunter.hp})
   if e.type=="boss_ability_warning" and e.ability=="crimson_execution":boss_ultimate_warnings+=1
   if e.type=="hunter_evolved":buffs.append({"id":e.buff_id,"room":e.room,"time":m.time,"source":e.get("source","")})
   if e.type=="door_damage":
    door_damage_total+=e.damage
    if e.room==m.player_room and first_player_hit<0:first_player_hit=m.time
  for r in m.rooms:
   if r.owner>0:
    max_npc_door=maxi(max_npc_door,r.door_level+1);max_npc_bed=maxi(max_npc_bed,r.bed_level+1)
    for building in r.buildings.values():max_npc_machine=maxi(max_npc_machine,building.level)
  if m.player()!=null:
   var r=m.player()
   if absf(r.gold+r.spent+drained_gold-25-r.income_total)>.1:invalid.append("unearned player gold");break
   if policy!="active" and (r.shots>0 or r.damage_dealt>0 or r.buildings.values().any(func(b):return b.kind in ["turret","heavy"])):invalid.append("forbidden player weapon/damage");break
  steps+=1
 var npcs=[]
 for r in m.rooms:
  if r.owner>0:
   npc_damage+=r.damage_dealt
   npcs.append({"owner":r.owner,"room":r.index,"profile":r.profile,"alive":r.alive,"gold":r.gold,"power":r.electricity,"income":r.income_total,"spent":r.spent,"bed":r.bed_level+1,"door":r.door_level+1,"door_branch":r.door_branch,"repairs":r.repair_actions,"door_damage_taken":r.door_damage_taken,"shots":r.shots,"damage":r.damage_dealt,"main_damage":r.main_damage_dealt,"minion_damage":r.minion_damage_dealt,"buildings":r.buildings})
 var r=m.player();var award=p.settle_match(entry.id,m) if m.result!="" else {};var reason="transformed" if m.hunter.transformed else "stage ineligible" if not m.hunter.boss_policy.enabled else "ended before eligible opening" if m.hunter_active_seconds()<float(m.hunter.boss_policy.get("hp_opening",8.0)) else "eligible opening passed; threshold/deadline or breach/exit state timing"
 if m.result=="":invalid.append("nonterminal")
 elif award.is_empty():invalid.append("settlement")
 var row={"stage":stage,"map":m.map_id,"mode":mode,"archetype":archetype,"seed":seed_value,"policy":policy,"high_NPC_counterfactual":high_npc,"room":m.player_room,"result":m.result,"seconds":m.time,"preparation":m.preparation,"active_seconds":m.hunter_active_seconds(),"boss_policy":m.hunter.boss_policy,"boss_reason":reason,"transform_time":transform_time,"min_alive_hp_ratio_after_opening":min_eligible_ratio,"last_alive_ratio":last_alive_ratio,"last_alive_time":last_alive_time,"first_hunter_damage":first_hit,"first_hunter_door_attack":first_attack,"first_player_door_hit":first_player_hit,"pre_arrival_hunter_damage":hunter_pre_arrival_damage,"hunter_states_seconds":states,"hunter_retargets":m.hunter.retargets,"hunter_attacks":m.hunter.attacks,"door_damage_total":door_damage_total,"npc_damage":npc_damage,"player_damage":r.damage_dealt if r else 0,"player_shots":r.shots if r else 0,"player_bed":r.bed_level+1 if r else 0,"player_door":r.door_level+1 if r else 0,"player_spent":r.spent if r else 0,"player_income":r.income_total if r else 0,"player_gold":r.gold if r else 0,"player_power":r.electricity if r else 0,"player_buildings":r.buildings if r else {},"shield_uses":shield_uses,"legendary_uses":m.items.legendary_used,"NPC_max_bed":max_npc_bed,"NPC_max_door":max_npc_door,"NPC_max_machine":max_npc_machine,"NPCs":npcs,"events":events,"drained_gold":drained_gold,"drained_power":drained_power,"peak_minions":peak_minions,"peak_projectiles":peak_projectiles,"boss_phases":phases,"boss_casts":cast_counts,"buffs":buffs,"max_evolution":max_evolution,"domains":domains,"ultimate_warnings":boss_ultimate_warnings,"evolution_count":m.evolution.acquired.size(),"evolution_credited":m.evolution.credited,"invalid":invalid}
 if not invalid.is_empty():failures+=1
 print("PHASE5D4_PAIRED ",JSON.stringify(row))
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(p.path+suffix):DirAccess.remove_absolute(p.path+suffix)
 return row
func run():
 if "--hell-final" in OS.get_cmdline_user_args():
  for map_index in range(5):
   for policy in ["idle","bed_door_only","support_only"]:results.append(simulate_baseline(map_index,"hell",StrategyCatalog.ARCHETYPE_IDS[(map_index+2)%3],[11,47,91][map_index%3],policy))
  for i in range(3):
   results.append(simulate_baseline([1,2,4][i],"hell",StrategyCatalog.ARCHETYPE_IDS[i],[17,47,91][i],"active"))
   results.append(simulate_baseline([1,2,4][i],"hell",StrategyCatalog.ARCHETYPE_IDS[i],[17,47,91][i],"idle",true))
  for map_index in range(5):results.append(simulate_baseline(map_index,"hell",StrategyCatalog.ARCHETYPE_IDS[(map_index+3)%3],173+map_index*37,"bed_door_only"))
  for i in range(3):results.append(simulate_baseline([1,2,4][i],"hell",StrategyCatalog.ARCHETYPE_IDS[(i+1)%3],241+i*73,"active"))
 elif "--fresh" in OS.get_cmdline_user_args():
  for map_index in range(5):
   for mi in range(3):results.append(simulate_baseline(map_index,["standard","hard","hell"][mi],StrategyCatalog.ARCHETYPE_IDS[(map_index+mi+1)%3],173+map_index*37,"bed_door_only"))
  for i in range(3):results.append(simulate_baseline([1,2,4][i],"hell",StrategyCatalog.ARCHETYPE_IDS[(i+1)%3],241+i*73,"active"))
 elif "--controls" in OS.get_cmdline_user_args():
  for i in range(3):
   results.append(simulate_baseline([1,2,4][i],"hell",StrategyCatalog.ARCHETYPE_IDS[i],[17,47,91][i],"active"))
   results.append(simulate_baseline([1,2,4][i],"hell",StrategyCatalog.ARCHETYPE_IDS[i],[17,47,91][i],"idle",true))
 else:
  for map_index in range(5):
   for mi in range(3):
    for policy in ["idle","bed_door_only","support_only"]:results.append(simulate_baseline(map_index,["standard","hard","hell"][mi],StrategyCatalog.ARCHETYPE_IDS[(map_index+mi)%3],[11,47,91][map_index%3],policy))
 var out={"source":"Final Phase5D4 paired runtime, exact source hashes in manifest","scope":"Actual live model navigation/claim/sleep/economy/fullNPC AI/Hunter evolution.0XP/no-perk/no-stock player for no-turret arms; active Master4Shield+1Heart finite budget; highNPC separatelydeclared +10000G/+1000EonceperNPC. No player live funds/HP/time/position injection.","rows":results,"failures":failures}
 var suffix="-hell-final" if "--hell-final" in OS.get_cmdline_user_args() else "-fresh" if "--fresh" in OS.get_cmdline_user_args() else "-controls" if "--controls" in OS.get_cmdline_user_args() else ""
 var f=FileAccess.open("res://docs/evidence/phase5d4/balance-paired"+suffix+"-results.json",FileAccess.WRITE);f.store_string(JSON.stringify(out," "));f.close()
 print("PHASE5D4_PAIRED_CASES=",results.size()," FAILURES=",failures)
 quit(1 if failures else 0)
