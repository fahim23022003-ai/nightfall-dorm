extends SceneTree
# Whitelist/checksum tests plus actual fixed-step model simulations in fresh processes.
const Support=preload("res://tests/replay_test_support.gd")
const Code=preload("res://scripts/challenge_code.gd")
var checks=0
var failures=0
var prefix="user://replay-codes-"+str(Time.get_ticks_usec())+"-"
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("REPLAY CODE: "+label)
func signed(body):return body+"-"+body.sha256_text().left(8).to_upper()
func validation():
 for map in MapCatalog.IDS:
  for mode in ["standard","hard","hell"]:
   for archetype in StrategyCatalog.ARCHETYPE_IDS:
    for preset in [0,1]:
     for gear in [0,1]:
      for seed_value in [1,999999]:
       var config={"map":map,"difficulty":mode,"archetype":archetype,"preset":preset,"gear":gear,"seed":seed_value}
       var code=Code.encode(config);var decoded=Code.decode(code)
       check(code.length()<=128 and decoded.ok and Support.numeric_same(decoded.config,config),"all supported map/mode/archetype/resource/gear/extreme seed configurations roundtrip")
       check(Code.decode("  "+code.to_lower()+"\n").ok,"outer whitespace/case normalize canonically")
 var good=Code.encode({"map":MapCatalog.IDS[0],"difficulty":"standard","archetype":"crusher","preset":0,"gear":0,"seed":71})
 var malformed=["","NF2","not a challenge",good.left(-1),good+"garbage","x".repeat(129),good.replace("-71-","-72-"),signed("NF2-2-0-71-0-0-0-0"),signed("NF2-1-5-71-0-0-0-0"),signed("NF2-1-0-0-0-0-0-0"),signed("NF2-1-0-1000000-0-0-0-0"),signed("NF2-1-0-71-3-0-0-0"),signed("NF2-1-0-71-0-3-0-0"),signed("NF2-1-0-71-0-0-2-0"),signed("NF2-1-0-71-0-0-0-2"),signed("NF2-1-00-71-0-0-0-0"),signed("NF2-1-0-+71-0-0-0-0"),signed("NF2-1-0-71.5-0-0-0-0")]
 for code in malformed:
  var result=Code.decode(code)
  check(not result.ok and result.get("error","")!="","tampered/malformed/future/noncanonical code rejected with useful error")
func policy(m):
 var r=m.player()
 if r==null or not r.alive:return
 if r.door_hp<r.max_hp()*.3 and m.repair_door():return
 if r.bed_level<2:
  if m.upgrade_bed():return
 if r.door_level<2:
  if m.upgrade_door():return
 for kind in ["turret","generator","repair","heavy","enhancer"]:
  if not r.buildings.values().any(func(b):return b.kind==kind):
   var tile=Support.nearest_pad(r,r.door_approach())
   if tile>=0 and m.buy(kind,tile):return
 for tile in r.buildings:
  var b=r.buildings[tile]
  if b.kind in ["turret","heavy"]:
   if b.level==4:
    if m.specialize_building(tile,"suppression" if b.kind=="turret" else "focus"):return
   elif b.level<10 and m.upgrade_building(tile):return
func worker(args):
 var result=Code.decode(args[1]);var output=args[2];var advanced=args[3]=="advanced"
 if not result.ok:quit(2);return
 var path=prefix+"worker.json"
 var p=Support.profile(path) if advanced else PlayerProfile.new(path)
 if not advanced:p.save_profile()
 var signature=Support.profile_signature(p);var bytes=FileAccess.get_file_as_bytes(path)
 var m=MatchModel.new()
 if not Code.configure(m,result.config):quit(3);return
 m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 var trace=[];var ticks=0
 while ticks<9000 and m.result=="":
  if ticks%30==0:policy(m)
  m.tick(Code.FIXED_STEP);ticks+=1
  if ticks%300==0:trace.append(Support.model_signature(m))
 var data={"code":result.code,"engine":Engine.get_version_info().string,"step":Code.FIXED_STEP,"ticks":ticks,"trace":trace,"final":Support.model_signature(m),"normalized":m.match_boosts.is_empty(),"profile_unchanged":Support.profile_signature(p)==signature and FileAccess.get_file_as_bytes(path)==bytes}
 var f=FileAccess.open(output,FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
 Support.cleanup(prefix);print("REPLAY_CODE_WORKER=PASS TICKS=",ticks," OUTCOME=",m.result);quit()
func fresh_processes():
 var fixtures=[{"map":MapCatalog.IDS[0],"difficulty":"standard","archetype":"crusher","preset":0,"gear":0,"seed":719},{"map":MapCatalog.IDS[3],"difficulty":"hard","archetype":"stalker","preset":1,"gear":0,"seed":1013},{"map":MapCatalog.IDS[4],"difficulty":"hell","archetype":"ravager","preset":0,"gear":0,"seed":7019}]
 for i in range(fixtures.size()):
  var outputs=[];var code=Code.encode(fixtures[i])
  for profile in ["beginner","advanced"]:
   var path="res://docs/evidence/replay/qa-code-process-"+str(i)+"-"+profile+".json"
   var capture=[]
   var status=OS.execute(OS.get_executable_path(),["--headless","--path",ProjectSettings.globalize_path("res://"),"--script","res://tests/replay_codes.gd","--","--worker",code,path,profile],capture,true)
   check(status==0 and not str(capture).contains("ERROR"),"fresh actual engine worker exits cleanly")
   if not FileAccess.file_exists(path):check(false,"worker writes actual simulation evidence");continue
   var data=JSON.parse_string(FileAccess.get_file_as_string(path));outputs.append(data)
   check(data.normalized and data.profile_unchanged,"fixed challenge ignores permanent rank/perks/stock and cannot spend profile")
   check(data.final.result in ["victory","defeat"],"actual normalized policy reaches real terminal outcome")
  if outputs.size()==2:check(outputs[0]==outputs[1],"fresh-process fixed30Hz full trace/outcome identical for beginner versus Mythic20item profile")
func run():
 var args=OS.get_cmdline_user_args()
 if not args.is_empty() and args[0]=="--worker":worker(args);return
 validation();fresh_processes()
 print("REPLAY_CODE_CHECKS=",checks," FRESH_PROCESSES=6 FAILURES=",failures)
 quit(0 if failures==0 else 1)
