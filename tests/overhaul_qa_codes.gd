extends SceneTree
const Support=preload("res://tests/replay_test_support.gd")
var checks=0
var failures=0
func ck(ok,label):
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func policy(m):
 var r=m.player()
 if r==null or not r.alive:return
 if r.door_hp>0 and r.door_hp<r.max_hp()*.65:m.repair_door()
 if r.bed_level<2 and m.upgrade_bed():return
 if r.door_level<2 and m.upgrade_door():return
 for kind in ["generator","turret","antenna","flame"]:
  if r.buildings.values().any(func(b):return b.kind==kind):continue
  for tile in range(r.tile_count()):
   if not r.buildings.has(tile) and m.buy(kind,tile):return
func worker(args):
 var index=int(args[1]);var progressed=int(args[2]);var output=args[3]
 var config={"map":MapCatalog.IDS[index%5],"seed":701+index,"archetype":StrategyCatalog.ARCHETYPE_IDS[index],"difficulty":"standard","preset":0,"gear":1}
 var prefix="user://overhaul-independent-code-%d-%d-%d" % [index,progressed,Time.get_ticks_usec()]
 var p=PlayerProfile.new(prefix+".json");p.tutorial_completed=true;p.xp=progressed;p.rm_cash=900 if progressed>0 else 0;p.equipped=["marksman","reaper_slayer"] if progressed>0 else []
 for id in ItemCatalog.IDS:p.inventory[id]=900 if progressed>0 else 1
 if not p.save_profile():quit(1);return
 OS.set_environment("NIGHTFALL_PROFILE_PATH",p.path)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.onboarding.set_process(false);game.onboarding.skip()
 var code=ChallengeCode.encode(config)
 if not game.start_challenge(code):quit(1);return
 var m=game.model;m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 var start={"gold":m.player().gold,"power":m.player().electricity,"boosts":m.match_boosts.duplicate(true),"gear":game.temporary_loadout.item_loadout.duplicate(),"inventory":game.temporary_loadout.inventory.duplicate(true)}
 var trace=[];var events={};var cursor=0
 for frame in range(2100):
  if frame%15==0:policy(m)
  m.tick(ChallengeCode.FIXED_STEP)
  for e in m.presentation_events:
   if e.id<=cursor:continue
   cursor=e.id;events[e.type]=int(events.get(e.type,0))+1
  if frame%30==0:
   var rooms=[]
   for r in m.rooms:rooms.append([r.owner,r.alive,r.gold,r.electricity,r.door_hp,r.bed_level,r.door_level,r.magic_state.duplicate(true),r.buildings.duplicate(true)])
   trace.append([m.time,m.hunter.archetype,m.hunter.state,m.hunter.target,m.hunter.hp,m.hunter.position.x,m.hunter.position.y,m.hunter.arcane.action,m.hunter.arcane.cooldown,m.hunter.arcane.casts.duplicate(true),str(m.random.state),rooms])
  if m.result!="":break
 var data={"code":code,"start":start,"result":m.result,"trace":trace,"events":events,"casts":m.hunter.arcane.casts.duplicate(true)}
 var f=FileAccess.open(output,FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
 game.audio_system.shutdown();await create_timer(.7).timeout;game.queue_free();await process_frame;await process_frame;Support.cleanup(prefix);quit()
func run():
 var args=OS.get_cmdline_user_args()
 if args.size()>0 and args[0]=="--worker":worker(args);return
 ck(ChallengeCode.RULESET==4,"actual combat advertises ruleset4")
 ck(StrategyCatalog.ARCHETYPE_IDS.slice(0,3)==["crusher","stalker","ravager"],"old archetype indices unchanged")
 ck(StrategyCatalog.ARCHETYPE_IDS.size()==6,"six legitimate archetypes")
 for version in [1,2,3]:
  var code=ChallengeCode.encode({"map":"abandoned_dorm","seed":71,"archetype":"crusher","difficulty":"standard","preset":0,"gear":0})
  var body=code.substr(0,code.rfind("-")).replace("NF2-4-","NF2-%d-" % version)
  var old=body+"-"+body.sha256_text().left(8).to_upper()
  ck(not ChallengeCode.decode(old).ok and ChallengeCode.decode(old,true).ok,"historical code safely archive only")
 for raw in ["", "NF2-4-99-1-0-0-0-0-AAAAAAAA", "NF2-999-0-1-0-0-0-0-AAAAAAAA", "x".repeat(1000)]:ck(not ChallengeCode.decode(raw).ok,"invalid/incompatible code rejected")
 var summary=[]
 for index in range(StrategyCatalog.ARCHETYPE_IDS.size()):
  var paths=[]
  for progressed in [0,20000]:
   var path="res://docs/evidence/gameplay-overhaul/qa-code4-%d-%d.json" % [index,progressed];paths.append(path)
   var output=[];var status=OS.execute(OS.get_executable_path(),["--headless","--path",ProjectSettings.globalize_path("res://"),"--script","res://tests/overhaul_qa_codes.gd","--","--worker",str(index),str(progressed),path],output,true)
   var f=FileAccess.open(path.replace(".json",".log"),FileAccess.WRITE);f.store_string("".join(output));f.close()
   ck(status==0 and not "SCRIPT ERROR" in "".join(output) and not "ERROR:" in "".join(output),"fresh actual engine worker clean")
  if not FileAccess.file_exists(paths[0]) or not FileAccess.file_exists(paths[1]):ck(false,"worker outputs exist");continue
  ck(FileAccess.get_file_as_bytes(paths[0])==FileAccess.get_file_as_bytes(paths[1]),"full fresh-engine trace identical for beginner/progressed "+StrategyCatalog.ARCHETYPE_IDS[index])
  var data=JSON.parse_string(FileAccess.get_file_as_string(paths[0]))
  ck(data.start.gold==25 and data.start.power==0 and data.start.boosts=={},"normalized actual resources/perks")
  ck(data.code.begins_with("NF2-4-") and data.trace.size()>10,"actual gameplay trace uses current ruleset")
  summary.append({"kind":StrategyCatalog.ARCHETYPE_IDS[index],"map":MapCatalog.IDS[index%5],"trace_points":data.trace.size(),"events":data.events,"casts":data.casts,"result":data.result})
 var f=FileAccess.open("res://docs/evidence/gameplay-overhaul/qa-codes-result.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"workers":12,"cases":summary}," "))
 print("OVERHAUL_QA_CODES_CHECKS=",checks," FRESH_WORKERS=12 FAILURES=",failures);quit(1 if failures else 0)
