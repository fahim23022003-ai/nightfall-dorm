extends SceneTree
var checks=0
var failures=0
func require(value: bool,message: String):
 checks+=1
 if not value:failures+=1;push_error(message)
func _initialize():call_deferred("run")
func run():
 require(ProjectSettings.get_setting("application/config/version","")==OS.get_environment("NIGHTFALL_EXPECTED_BUILD_VERSION") and OS.get_environment("NIGHTFALL_EXPECTED_BUILD_VERSION")!="","RC version packaged")
 require(ResourceLoader.exists("res://scenes/main.tscn"),"main scene packaged")
 require(not DirAccess.dir_exists_absolute("res://tests") and not DirAccess.dir_exists_absolute("res://docs") and not DirAccess.dir_exists_absolute("res://tools"),"development files excluded")
 for path in ["res://assets/fonts/Interface.ttf","res://assets/fonts/GrenzeGotisch-SemiBold.ttf","res://assets/premium_ui/endless.svg"]:
  require(ResourceLoader.load(path)!=null,"required asset "+path)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 await process_frame;await process_frame
 require(game.profile!=null and game.ui!=null,"actual launch/profile/UI initialized")
 require(game.audio_system.streams.size()==AudioDirector.LOOP_NAMES.size()+AudioDirector.EFFECT_NAMES.size(),"all audio streams packaged")
 require(ItemCatalog.IDS.size()==20 and MapCatalog.IDS.size()==5,"item/map catalogs packaged")
 require(Catalog.BUILDINGS.size()==15 and HunterEvolution.BUFFS.size()==15,"Expanded building and evolution catalogs packaged")
 for kind in ["flame","frost","shock","auto_repair","shield","decoy","barrier","plasma","antenna"]:
  require(ResourceLoader.load("res://assets/wrath/"+kind+".svg")!=null,"new building art packaged: "+kind)
 require(game.audio_system.streams.has("music_crimson") and game.audio_system.streams.has("hunter_evolve"),"Crimson music and evolution stream packaged")
 require(StrategyCatalog.ARCHETYPE_IDS.size()==6,"all six Hunters packaged")
 for kind in StrategyCatalog.ARCHETYPE_IDS:
  require(ResourceLoader.load("res://assets/premium_ui/"+kind+".svg")!=null,"Hunter menu art packaged: "+kind)
  for pose in ["idle","walk","attack","hurt","defend","special","death"]:
   require(ResourceLoader.load("res://assets/hunters/"+kind+"_"+pose+".svg")!=null,"Hunter pose packaged: "+kind+"/"+pose)
 for element in ["fire","ice","electric","earth"]:
  require(ResourceLoader.load("res://assets/hunters/element_"+element+".svg")!=null,"affinity art packaged: "+element)
 require(RoomExpansion.SLOTS==[3,6,8,10,11,12,14,16] and ChallengeCode.RULESET==4,"expansion/current rules packaged")
 require(game.start_practice("witch",false,["shield","repair"]),"actual new Hunter practice starts")
 await process_frame
 require(game.model.player()!=null and game.model.run_kind=="practice","actual model integrated")
 require(game.model.wrath!=null and game.model.evolution!=null and game.model.defenses!=null,"Wrath runtime components initialize in exported practice")
 game.return_menu();game.audio_system.shutdown()
 await create_timer(0.5).timeout
 game.queue_free();await create_timer(0.2).timeout
 print("WINDOWS_EMBEDDED_PACK_LINUX_CHECKS=",checks," FAILURES=",failures," NATIVE_WINDOWS=UNVERIFIED")
 quit(1 if failures else 0)
