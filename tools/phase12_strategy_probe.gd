extends SceneTree
# Actual paid production-code strategies, not optimal/human play. No budget/stat injection.
var output="res://docs/evidence/earned-power/baseline-strategies.json"
var source_label="b2f78fa46ebdbe0a12f4e7a15f09ce1631d98e5f baseline classes loaded before edits"
var balance=1
var only_strategy=""
var mode="standard"
var rewards=false
var perk_fixture=[]
var supplies=false
var seed_count=20
var duration=1200.0
var rows=[]
var started=0
func _initialize():call_deferred("run")
func count(r,kind):return r.buildings.values().filter(func(b):return b.kind==kind).size()
func machine(m,kind):
 var r=m.player();var ids=r.buildings.keys();ids.sort_custom(func(a,b):return r.tile_position(a).distance_to(r.door_approach())<r.tile_position(b).distance_to(r.door_approach()))
 for id in ids:
  var b=r.buildings[id]
  if b.kind!=kind or b.level>=10:continue
  if kind=="repair" and b.level>=4:return false # Deliberate base-stationL4 ceiling; identical to baseline effective behavior.
  if b.level==4:return m.specialize_building(id,"dividend" if kind=="economy" else "regulated" if kind=="generator" else "precision" if kind=="turret" else "focus" if kind=="heavy" else "efficient")
  return m.upgrade_building(id)
 return false
func build(m,kind):
 var r=m.player();var ids=[]
 for id in range(r.tile_count()):
  if not r.buildings.has(id):ids.append(id)
 ids.sort_custom(func(a,b):return r.tile_position(a).distance_to(r.door_approach())<r.tile_position(b).distance_to(r.door_approach()))
 for id in ids:
  if m.buy(kind,id):return true
 return false
func structure(m,kind):
 var r=m.player();var level=r.bed_level if kind=="bed" else r.door_level
 if level==4 and (r.bed_branch if kind=="bed" else r.door_branch)=="":return r.specialize_structure(kind,"lucid" if kind=="bed" else "bulwark")
 return m.upgrade_bed() if kind=="bed" else m.upgrade_door()
func act(m,strategy):
 var r=m.player()
 var urgent=.25 if strategy=="greedy" else .55 if strategy=="balanced" else .78
 if r.door_hp<r.max_hp()*urgent:
  if structure(m,"door") or m.repair_door():return
 if strategy=="greedy" and r.bed_level<2:
  if structure(m,"bed") or structure(m,"door"):return
 if count(r,"turret")==0 and build(m,"turret"):return
 if r.bed_level<1 and structure(m,"bed"):return
 if r.door_level<1 and structure(m,"door"):return
 if count(r,"generator")==0 and build(m,"generator"):return
 if balance==2 and count(r,"generator")==0 and strategy!="greedy":return
 if balance==2 and r.electricity<40 and machine(m,"generator"):return
 if strategy=="defense" and machine(m,"turret"):return
 if r.bed_level<2 and structure(m,"bed"):return
 if r.door_level<2 and structure(m,"door"):return
 if m.run_kind=="endless" and r.buildings.size()>=r.tile_count()-1 and r.tile_count()<16 and m.expansion.purchase(m):return
 var amplification=3 if strategy=="greedy" else 1 if strategy=="balanced" else 0
 if count(r,"economy")<amplification and build(m,"economy"):return
 if strategy!="greedy" and count(r,"repair")==0 and build(m,"repair"):return
 if strategy=="greedy" and machine(m,"economy"):return
 if count(r,"generator")<2 and r.bed_level>=3 and build(m,"generator"):return
 if strategy=="balanced":
  if count(r,"heavy")==0 and build(m,"heavy"):return
  if machine(m,"heavy") or machine(m,"turret"):return
 if structure(m,"bed"):return
 if structure(m,"door"):return
 if machine(m,"generator"):return
 if strategy=="greedy" and count(r,"repair")==0 and build(m,"repair"):return
 if machine(m,"turret") or machine(m,"heavy") or machine(m,"repair"):return
 if count(r,"heavy")<3:build(m,"heavy")
func point(m):
 var r=m.player();var levels={}
 for b in r.buildings.values():
  if not levels.has(b.kind):levels[b.kind]=[]
  levels[b.kind].append(b.level)
 return {"time":m.time,"gold":r.gold,"electricity":r.electricity,"gold_rate":r.income_rate(),"electricity_rate":BuildingStats.room_power_rate(m,r),"gross_gold":r.income_total,"gross_electricity":r.generated_power,"flows":r.ledger.totals.duplicate(true),"spent_gold":r.spent,"bed":r.bed_level+1,"door":r.door_level+1,"door_hp":r.door_hp,"capacity":r.tile_count(),"buildings":levels,"survival":r.alive,"survivor_eliminations":m.eliminations,"completed":m.endless.completed if m.endless!=null else int(m.result=="victory"),"wave":m.endless.wave if m.endless!=null else 0,"hunter_hp":m.hunter.hp}
func simulate(kind,strategy,seed_number):
 var p=PlayerProfile.new("user://phase12-probe-"+str(Time.get_ticks_usec())+".json")
 if not perk_fixture.is_empty():p.xp=RankCatalog.THRESHOLDS[-1];p.equipped=perk_fixture.duplicate()
 if supplies:p.inventory={"repair":2,"shield":2};p.item_loadout=["repair","shield"]
 var entry={}
 if supplies:entry=p.begin_endless("abandoned_dorm",mode,seed_number) if kind=="endless" else p.begin_match(mode,"stage_1",true)
 var m=MatchModel.new();m.reset(seed_number)
 if kind=="endless":m.configure_endless("abandoned_dorm",mode,seed_number,int(entry.id) if not entry.is_empty() else seed_number,RankCatalog.bonuses(perk_fixture))
 else:m.configure_stage("stage_1");m.configure_match(mode,RankCatalog.bonuses(perk_fixture));m.configure_strategy(seed_number)
 m.configure_balance(balance)
 m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 if supplies:p.bind_items(m,int(entry.id))
 var r=m.player();var initial=[r.gold,r.electricity];var data={"kind":kind,"strategy":strategy,"seed":seed_number,"archetype":m.hunter.archetype,"fresh_xp":p.xp,"fresh_inventory":p.inventory.size(),"starting_gold":r.gold,"starting_electricity":r.electricity,"milestones":{},"samples":[],"actions":0,"repair_spent":0.0,"reconciled_gold_residual":0.0,"observations":[]}
 var next_action=0.0;var targets=[60,180,300,600,1200];var peak_gold=r.gold;var gross_start=r.income_total
 while m.time<duration and m.result=="":
  if m.endless!=null and m.endless.phase=="intermission":
   if rewards and balance==2:
    var c=m.choices
    if not c.draft.is_empty():c.choose(m,c.draft[0] if strategy=="greedy" else c.draft[-1])
    for offer in c.offers:
     if r.gold>offer.gold*3 and offer.id in ["repair","shield"]:c.buy(m,offer.id)
   if not m.continue_wave("repair"):break
  if m.time+0.0001>=next_action:
   var before=[r.gold,r.electricity,r.repair_actions];act(m,strategy);next_action+=1
   if r.gold!=before[0] or r.electricity!=before[1]:
    data.actions+=1
    if r.repair_actions>before[2]:data.repair_spent+=before[0]-r.gold
    if seed_number==1:data.observations.append({"time":m.time,"action_gold":r.gold-before[0],"action_power":r.electricity-before[1],"wallet":[r.gold,r.electricity],"bed":r.bed_level+1,"door":r.door_level+1})
  if rewards and balance==2 and r.door_hp<r.max_hp()*.5:
   for item in ["repair","shield","reserve"]:m.choices.activate(m,item)
  if supplies and r.door_hp<r.max_hp()*.6:
   for slot in range(2):p.activate_item(slot,m,int(entry.id))
  m.tick(.2);peak_gold=maxf(peak_gold,r.gold)
  if count(r,"generator")>0 and not data.milestones.has("first_generator"):data.milestones.first_generator=m.time
  for b in r.buildings.values():
   if b.level==10 and not data.milestones.has("first_machine10"):data.milestones.first_machine10=m.time
  if r.bed_level==9 and not data.milestones.has("bed10"):data.milestones.bed10=m.time
  if r.door_level==9 and not data.milestones.has("door10"):data.milestones.door10=m.time
  while not targets.is_empty() and m.time+.0001>=targets[0]:data.samples.append(point(m));targets.pop_front()
 data.npc_flows=[]
 for ally in m.rooms:
  if ally.owner>0:
   ally.ledger.reconcile(ally,m.time);data.npc_flows.append({"room":ally.index,"alive":ally.alive,"gold":ally.gold,"electricity":ally.electricity,"flows":ally.ledger.totals,"bed":ally.bed_level+1,"door":ally.door_level+1})
 data.final=point(m);data.result=m.result if m.result!="" else "ongoing_at_horizon";data.peak_gold=peak_gold;data.wall_seconds=(Time.get_ticks_usec()-started)/1e6;data.literal_five_minute_billion=data.samples.any(func(s):return s.time<=300.01 and s.gold>=1e9)
 data.reconciled_gold_residual=r.gold-initial[0]-(r.income_total-gross_start)+r.spent
 return data
func run():
 var args=OS.get_cmdline_user_args()
 for i in range(args.size()-1):
  if args[i]=="--output":output=args[i+1]
  if args[i]=="--label":source_label=args[i+1]
  if args[i]=="--balance":balance=int(args[i+1])
  if args[i]=="--strategy":only_strategy=args[i+1]
  if args[i]=="--mode":mode=args[i+1]
  if args[i]=="--perks":perk_fixture=Array(args[i+1].split(",",false))
  if args[i]=="--supplies":supplies=args[i+1]=="yes"
  if args[i]=="--rewards":rewards=args[i+1]=="yes"
  if args[i]=="--seeds":seed_count=int(args[i+1])
  if args[i]=="--duration":duration=float(args[i+1])
 started=Time.get_ticks_usec();print("PHASE12_PROBE_CLASSES_LOADED · baseline actual production rules · ",Time.get_ticks_msec())
 for kind in ["campaign","endless"]:
  for strategy in ([only_strategy] if only_strategy!="" else ["greedy","defense","balanced"]):
   for seed_number in range(1,seed_count+1):
    var row=simulate(kind,strategy,seed_number);rows.append(row)
    print("PROBE ",kind," ",strategy," ",seed_number," ",row.result," t=",row.final.time," gold=",row.final.gold)
 var f=FileAccess.open(output,FileAccess.WRITE);f.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"source_commit":source_label,"permanent_loadout":perk_fixture,"prepared_supplies":supplies,"profile_context":"Prepared progressed fixture with compatible permanent loadout/limited stock" if not perk_fixture.is_empty() or supplies else "Fresh profile; no unlocks/injected funds","mode":mode,"balance":balance,"seeds_per_strategy":seed_count,"simulation_horizon":duration,"step":.2,"strategies":"Greedy buys beds/amplifiers first; defense upgrades its weapon/door before economy; balanced grows both and buys Arc. One decision/s, paid model APIs, auto-claim/sleep at t0, actual NPCs, normal Reinforce each intermission. Not optimal/human. No injected resources, no HP edits, no manual kill or stock.","rows":rows,"wall_seconds":(Time.get_ticks_usec()-started)/1e6}," "))
 print("PHASE12_PROBE_COMPLETE ",rows.size()," cases, output ",output);quit()
