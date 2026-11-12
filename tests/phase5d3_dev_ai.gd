extends SceneTree
var checks=0
var failures=0
func check(value,message):
 checks+=1
 if not value:failures+=1;push_error(message)
func _initialize():call_deferred("run")
func run():
 for archetype in StrategyCatalog.ARCHETYPE_IDS:
  var m=MatchModel.new();m.configure_stage("stage_1");m.configure_strategy(17,archetype,"")
  m.preparation=0;m.hunter.boss_policy.enabled=false
  for r in m.rooms:
   r.owner=r.index;r.sleeping=true;r.closed=true;r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp();r.gold=10000;r.electricity=10000;r.bot_timer=1000000
   r.build("repair",0)
   for i in range(3):r.upgrade_building(0)
  m.player_room=0;m.player_position=m.rooms[0].bed_position();m.bot_claimed=5
  var seen={};var starts={};var last=m.hunter.position
  for i in range(10800):
   m.tick(1.0/60)
   if m.hunter.target>=0:seen[m.hunter.target]=true
   check(m.hunter.position.distance_to(last)<10,"movement obeys bounded navigation step")
   last=m.hunter.position
   for k in m.hunter.ability_counts:starts[k]=m.hunter.ability_counts[k]
   if m.result!="":break
  check(seen.size()>1,"healed failed sieges choose alternate valid targets "+archetype)
  check(starts.pressure>0 if archetype=="crusher" else starts.conceal>0 and starts.feint>0 if archetype=="stalker" else starts.dash>0,"real archetype mechanics executed "+archetype)
  print("ARCHETYPE=",archetype," TARGETS=",seen.keys()," ABILITIES=",starts," ATTACKS=",m.hunter.attacks)
  m.hunter.transformed=true;m.hunter.tick(.1,m)
  check(m.hunter.tactical_action=="" and m.hunter.pressure_remaining==0 and m.hunter.dash_remaining==0,"Reaper clears normal abilities")
 print("PHASE5D3_DEV_AI_CHECKS=",checks," FAILURES=",failures)
 quit(1 if failures else 0)
