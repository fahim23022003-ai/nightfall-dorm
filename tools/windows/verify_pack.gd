extends SceneTree
var checks=0
var failures=0
func require(value: bool,message: String):
 checks+=1
 if not value:failures+=1;push_error(message)
func _initialize():call_deferred("run")
func run():
 require(ProjectSettings.get_setting("application/config/version","")=="0.6.0-rc1","RC version packaged")
 require(ResourceLoader.exists("res://scenes/main.tscn"),"main scene packaged")
 require(not DirAccess.dir_exists_absolute("res://tests") and not DirAccess.dir_exists_absolute("res://docs") and not DirAccess.dir_exists_absolute("res://tools"),"development files excluded")
 for path in ["res://assets/fonts/Interface.ttf","res://assets/fonts/GrenzeGotisch-SemiBold.ttf","res://assets/premium_ui/endless.svg"]:
  require(ResourceLoader.load(path)!=null,"required asset "+path)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 await process_frame;await process_frame
 require(game.profile!=null and game.ui!=null,"actual launch/profile/UI initialized")
 require(game.audio_system.streams.size()==105,"all audio streams packaged")
 require(ItemCatalog.IDS.size()==20 and MapCatalog.IDS.size()==5,"item/map catalogs packaged")
 require(game.start_practice("crusher",false,["shield","repair"]),"actual practice starts")
 await process_frame
 require(game.model.player()!=null and game.model.run_kind=="practice","actual model integrated")
 game.return_menu();game.audio_system.shutdown()
 await create_timer(0.5).timeout
 game.queue_free();await create_timer(0.2).timeout
 print("WINDOWS_EMBEDDED_PACK_LINUX_CHECKS=",checks," FAILURES=",failures," NATIVE_WINDOWS=UNVERIFIED")
 quit(1 if failures else 0)
