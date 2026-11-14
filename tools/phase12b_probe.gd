extends SceneTree
var output="res://docs/evidence/fair-difficulty/baseline.json"
var policy_id="principal"
var kind="campaign"
var mistake=false
var mode="hard"
var seeds=[1,2,3,4,5]
var duration=900.0
var label="Phase12 delivery actual rules"
var ablation="none"
var rows=[]
func _initialize():call_deferred("run")
func state(m):
 var r=m.player();var h=m.hunter;var buildings=[]
 for id in r.buildings:buildings.append({"id":id,"kind":r.buildings[id].kind,"level":r.buildings[id].level})
 var available=[]
 for kind in Catalog.BUILDINGS:
  var quote=r.quote_build(kind)
  if quote.x<=r.gold and quote.y<=r.electricity and BalanceRules.build_requirement(kind,r)=="":available.append(kind)
 var d=BalanceRules.structure("door",r.door_level,2)
 return {"time":m.time,"wallet":[r.gold,r.electricity],"rates":[r.income_rate(),BuildingStats.room_power_rate(m,r)],"bed":r.bed_level+1,"door":r.door_level+1,"hp":r.door_hp,"max_hp":r.max_hp(),"repair_cost":r.manual_repair_cost(),"repair_restore":Catalog.REPAIR_HEAL*r.repair_factor*StrategyCatalog.BRANCHES.get(r.door_branch,{}).get("repair",1.0),"repair_factor":r.repair_factor,"affordable_builds_not_geometry":available,"door_upgrade_affordable":r.door_level<9 and r.gold>=d.x and r.electricity>=d.y and r.bed_level>=maxi(0,r.door_level-1),"buildings":buildings,"hunter_hp":h.hp,"hunter_base_damage":h.damage,"interval":h.interval,"growth":h.growth_at(HunterPressure.growth_clock(m,m.hunter_active_seconds())),"level":h.level,"evolution":m.evolution.evolution_level,"kill_buffs":m.evolution.acquired.duplicate(),"kill_factor":m.evolution.damage_factor(false),"special_kill_factor":m.evolution.damage_factor(true),"pressure":m.pressure.factor(m),"pressure_stacks":m.pressure.stacks,"hunter_target":h.target,"hunter_state":h.state,"hunter_pressure_ability":h.pressure_remaining,"nominal_unmitigated_ordinary_damage":h.damage*m.evolution.damage_factor(false)*m.pressure.factor(m)}
func simulate(seed_number):
 var m=MatchModel.new();m.reset(seed_number);
 if ablation=="slow-growth":m.hunter=preload("res://tools/phase12b_diagnostic_hunter.gd").new()
 if kind=="endless":m.configure_endless("abandoned_dorm",mode,seed_number,seed_number)
 else:m.configure_stage("stage_1");m.configure_match(mode);m.configure_strategy(seed_number)
 m.configure_balance(2);m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 var policy=preload("res://tools/phase12_test_policy.gd").new() if policy_id.begins_with("principal") else preload("res://tools/phase12b_policy.gd").new()
 policy.balance=2
 if not policy_id.begins_with("principal"):policy.style=policy_id
 var detailed=seed_number in [1,2];var row={"seed":seed_number,"mode":mode,"map":m.map_id,"room":0,"archetype":m.hunter.archetype,"policy":policy_id,"actions":[],"events":[],"samples":[],"first_attack":{},"repair_gold":0.0,"automatic_repair":0.0,"windows":[]};var decision=0.0;var sample=0.0;var last=0;var first_player_hit=-1.0;var breach=-1.0;var useful=[];var corrected=false
 while m.time<duration and m.result=="":
  if kind=="endless" and m.endless.phase=="intermission":m.continue_wave("repair")
  if m.time>=decision:
   var before=state(m);var spend=m.player().spent;var repair=m.player().repair_actions;var old=m.player().buildings.duplicate(true)
   if mistake and m.time<.01:m.buy("turret",0)
   elif mistake and not corrected and m.time>m.preparation+2 and m.player().buildings.has(0):
    corrected=m.sell_building(0);row.correction_time=m.time
   elif policy_id!="passive":policy.act(m,policy_id.trim_prefix("principal-") if policy_id.contains("-") else "balanced")
   decision+=1.0
   if spend!=m.player().spent:
    var entry={"before":before,"after":state(m),"kind":"repair" if m.player().repair_actions>repair else "bed" if m.player().bed_level+1>before.bed else "door" if m.player().door_level+1>before.door else "building"}
    if entry.kind=="repair":row.repair_gold+=m.player().spent-spend
    row.actions.append(entry);useful.append(m.time)
  if m.time>=sample:
   if detailed:row.samples.append(state(m))
   sample+=5
  m.tick(.1)
  for event in m.presentation_events:
   if event.id<=last:continue
   last=event.id
   if event.type=="door_damage" and event.damage>0 and not row.first_attack.has(str(event.room)):row.first_attack[str(event.room)]={"time":event.time,"damage":event.damage}
   if event.type=="door_damage" and event.room==0 and event.damage>0 and first_player_hit<0:first_player_hit=event.time
   if event.type=="door_break" and event.room==0:breach=event.time
   if detailed and event.type in ["door_damage","door_break","elimination","hunter_evolved","hunter_ability_warning","archetype_warning","charged_attack","nightmare_warning","nightmare_impact","nightmare_cancel","defense_heal","defense_activate","sale"]:
    var copy=event.duplicate(true);copy.erase("position");copy.erase("origin");copy.context=state(m);row.events.append(copy)
  if ablation=="no-contact":m.pressure.stacks=0;m.pressure.warning=9999
  if ablation=="no-repair-suppression":m.player().repair_factor=1.0
 row.result=m.result if m.result!="" else "unfinished";row.final=state(m);row.first_player_hit=first_player_hit;row.breach_time=breach;row.eliminations=m.eliminations;row.damage=m.player().damage_dealt;row.automatic_repair=m.player().economy_repaired;row.flow=m.player().ledger.totals.duplicate(true);row.player_door_damage=m.player().door_damage_taken;row.kind=kind;row.completed=m.endless.completed if kind=="endless" else int(m.result=="victory")
 row.npcs=[]
 for r in m.rooms:
  if r.owner>0:row.npcs.append({"owner":r.owner,"room":r.index,"alive":r.alive,"income":r.income_total,"spent":r.spent,"damage":r.damage_dealt,"door":r.door_level+1,"bed":r.bed_level+1,"wallet":[r.gold,r.electricity],"buildings":r.buildings.values()})
 var gaps=[]
 for i in range(1,useful.size()):gaps.append(useful[i]-useful[i-1])
 row.decision_gaps=gaps
 return row
func run():
 var args=OS.get_cmdline_user_args()
 for i in range(args.size()-1):
  if args[i]=="--output":output=args[i+1]
  if args[i]=="--label":label=args[i+1]
  if args[i]=="--policy":policy_id=args[i+1]
  if args[i]=="--mode":mode=args[i+1]
  if args[i]=="--kind":kind=args[i+1]
  if args[i]=="--mistake":mistake=args[i+1]=="yes"
  if args[i]=="--duration":duration=float(args[i+1])
  if args[i]=="--ablation":ablation=args[i+1]
  if args[i]=="--seeds":seeds=Array(args[i+1].split(",")).map(func(s):return int(s))
 for seed_number in seeds:
  var row=simulate(seed_number);rows.append(row);print("CASE ",policy_id," ",mode," seed=",seed_number," ",row.result," time=",row.final.time)
 var f=FileAccess.open(output,FileAccess.WRITE);f.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"label":label,"entry":"Fresh stage1; no difficulty progression lock, permanent bonuses, inventory or injected resources. Existing auto claim/sleep at t0 for simulation only. One paid action/second, .1 model ticks; accelerated execution, normal gameplay clock, not a human/input recording.","ablation":ablation,"mistake_fixture":mistake,"policy":policy_id,"rows":rows}," "));quit()
