extends SceneTree
# CONTROLLED healed-door targeting fixture, not earned economy/win-rate evidence.
var checks=0
var failures=0
func check(value,message):
 checks+=1
 if not value:failures+=1;push_error(message)
func _initialize():call_deferred("run")
func run():
 var rows=[]
 for map_index in range(5):
  for ai in range(3):
   if "--hell-crusher-only" in OS.get_cmdline_user_args() and not (map_index==2 and ai==0):continue
   if "--ravager-only" in OS.get_cmdline_user_args() and ai!=2:continue
   var archetype=StrategyCatalog.ARCHETYPE_IDS[ai];var mode=["standard","hard","hell"][(map_index+ai)%3]
   var m=MatchModel.new();m.reset(17);m.configure_match(mode);m.configure_stage(StageCatalog.STAGES[map_index].id);m.configure_strategy(17,archetype,"")
   m.preparation=0;m.hunter.boss_policy.enabled=false
   for r in m.rooms:
    r.owner=r.index;r.sleeping=true;r.closed=true;r.strategy_enabled=true;r.bed_level=9;r.door_level=9;r.bed_branch="lucid";r.door_branch="bulwark";r.door_hp=r.max_hp();r.gold=100000;r.electricity=100000;r.bot_timer=10000
    check(r.build("repair",0),"controlled repair purchase")
    for level in range(1,4):check(r.upgrade_building(0),"controlled repair tier")
    check(r.specialize_building(0,"sustain"),"controlled repair branch")
    for level in range(5,10):check(r.upgrade_building(0),"controlled repair tier10")
   m.player_room=0;m.player_position=m.rooms[0].bed_position();m.bot_claimed=5
   var targets={};var warnings={};var events={};var last_event=0;var last_target=-1;var last_target_time=0.0;var changes=[];var warning_until=0.0;var minimum_gap=INF
   for step in range(1800):
    var previous=m.hunter.position;m.tick(.1)
    check(m.hunter.position.distance_to(previous)<=m.hunter.speed*.1+.25,"bounded normal/dash path displacement")
    check(m.navigation_walkable(m.hunter.position),"no navigation wall crossing "+m.map_id)
    if m.hunter.target>=0:targets[m.hunter.target]=true
    if m.hunter.target!=last_target and m.hunter.target>=0:
     if last_target>=0:minimum_gap=minf(minimum_gap,m.time-last_target_time)
     changes.append({"time":m.time,"room":m.hunter.target});last_target=m.hunter.target;last_target_time=m.time
    for e in m.presentation_events:
     if e.id<=last_event:continue
     last_event=e.id;events[e.type]=int(events.get(e.type,0))+1
     if e.type=="hunter_ability_warning":warnings[e.ability]=m.time+e.delay
     elif e.type=="hunter_ability" and e.ability!="feint":check(warnings.has(e.ability) and m.time+.11>=warnings[e.ability],"mechanical ability follows actual telegraph")
    if m.result!="":break
   check(targets.size()>1,"failed healed sieges choose alternatives "+archetype+" "+m.map_id)
   var counts=m.hunter.ability_counts.duplicate()
   check(counts.pressure>0 if archetype=="crusher" else counts.conceal>0 and counts.feint>0 if archetype=="stalker" else counts.dash>0,"real tactical action executes")
   # Once transformed, base archetype abilities clear rather than stacking with boss specials.
   m.hunter.transformed=true;m.hunter.tick(.1,m)
   check(m.hunter.tactical_action=="" and m.hunter.pressure_remaining==0 and m.hunter.conceal_remaining==0 and m.hunter.dash_remaining==0,"Reaper clears normal active abilities")
   rows.append({"map":m.map_id,"mode":mode,"archetype":archetype,"seconds":m.time,"result":m.result,"targets":targets.keys(),"target_changes":changes,"minimum_target_gap":minimum_gap if is_finite(minimum_gap) else 0,"abilities":counts,"events":events,"attacks":m.hunter.attacks})
 var f=FileAccess.open("res://docs/evidence/phase5d3/balance-ai"+("-ravager-final" if "--ravager-only" in OS.get_cmdline_user_args() else "-hell-crusher-final" if "--hell-crusher-only" in OS.get_cmdline_user_args() else "")+"-results.json",FileAccess.WRITE);f.store_string(JSON.stringify({"scope":"Controlled initial L10bed/door, paid L10repair, seeded wallets and paused bot purchasing to keep valid healed alternatives alive; actual Hunter navigation/ability/combat ticking. Not natural economy or victory evidence.","cases":rows,"checks":checks,"failures":failures}," "));f.close()
 print("PHASE5D3_AUDIT_AI_CASES=",rows.size()," CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
