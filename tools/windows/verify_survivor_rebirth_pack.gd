extends SceneTree
## Enter the offline lobby from the embedded game and check fresh competition.

var checks:=0
var failures:=0

func _initialize():
 call_deferred("run")

func check(condition: bool, label: String):
 checks+=1
 if not condition:
  failures+=1
  push_error(label)

func run():
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 check(game.story_preview_enabled and game.survivor_preview_enabled,"Both preview flags are enabled")
 check(game.profile.complete_tutorial(),"Set up isolated pack test profile")
 if is_instance_valid(game.onboarding):
  game.onboarding.skip()
  game.onboarding.close_welcome()
 game.enter_game()
 check(game.ui.current_screen=="story_prepare","Open current Story preparation")
 check(game.open_story_lobby("standard"),"Load the bundled Story lobby")
 var lobby=game.story_lobby
 if is_instance_valid(lobby):
  lobby.set_process(false)
  await process_frame
  await process_frame
  var initial_time: float=game.model.time
  var roster: Array=lobby.roster()
  check(roster.size()==6 and roster.filter(func(slot):return slot.human).size()==1,"One human and five offline survivors")
  lobby.advance(14.99)
  check(not lobby.loading and game.model.time==initial_time,"Waiting leaves the model suspended for 14.99 seconds")
  lobby.advance(.01)
  check(lobby.loading and lobby.ready_ai_count()==5,"15 seconds enters the local loading transition")
  lobby.advance(1.0)
  await process_frame
  await process_frame
  check(game.mode=="match" and game.model.story_level==1,"Story launches from the ready state")
  if OS.get_environment("NIGHTFALL_CLOSE_QUARTERS")=="1":
   check(game.model.map_data.get("version")==NightmareMap.CLOSE_QUARTERS_VERSION,"Fresh Story launches the packed close-quarters geometry")
  check(game.model.room_rush_active() and game.model.room_rush_runners().size()==5,"Pack initializes five physical runners")
  if OS.get_environment("NIGHTFALL_PHASE16")=="1":
   check(game.model.room_rush.planned_pacing,"Phase 16 launcher enables the advisory room-race planner")
   check(game.model.preparation>=float(StoryCatalog.mission(1).encounter.preparation),"The real Story launch applies the authored opening")
   for kind: String in ["auto_repair","decoy","economy","enhancer","generator","plasma","repair","shield","shock"]:
    var idle:=load("res://assets/visual_rebirth/buildings/%s/idle_support.png" % kind) as Texture2D
    check(idle!=null and idle.get_size()==Vector2(576,384),"Pack contains the resting atlas for "+kind)
  for runner in game.model.room_rush_runners():
   check(runner.position==game.model.player_position,"NPC appears at the shared spawn")
  check(game.model.rooms.all(func(room):return room.owner<0),"No room was preassigned")
  check(not game.model.claim_room(0),"Remote claim is rejected")
  var room: RoomState=game.model.rooms[0]
  var entry:=room.door_position()-room.door_normal()*35.0
  var route: Array=game.model.player_navigation_path(game.model.player_position,entry)
  for waypoint: Vector2 in route:
   for step in range(500):
    var delta: Vector2=waypoint-game.model.player_position
    if delta.length()<.2:break
    game.model.move_player(delta.normalized(),minf(.02,delta.length()/MatchModel.SURVIVOR_SPEED))
  game.model.interact()
  check(game.model.player_room==0 and game.model.player()!=null and game.model.player().spatial.grid,"Physical claim preserves Full Room Grid")
  if OS.get_environment("NIGHTFALL_LIVING_DORM")=="1":
   check(game.ui.living_dorm_hud!=null and game.model.living_dorm_tactics(),"Phase 19 enables HUD and reachable-room variation")
   check(game.profile.settings.graphics_quality=="low" and not game.model.mini_hunters_requested,"starts Low and leaves the experimental pilot off")
   check(ResourceLoader.exists("res://assets/visual_rebirth/buildings/door/living_dorm.png"),"gothic door atlas included")
  if OS.get_environment("NIGHTFALL_BUILDING_SCALE")=="1":
   check(game.model.player().spatial.rules_version==SpatialConstruction.SUBSTANTIAL_VERSION,"Physical Story claim enables revised footprints")
  if OS.get_environment("NIGHTFALL_PLAYER_FIRST")=="1":
   check(game.model.uses_player_door_survival(),"Phase 20 door rules are active in Story")
   check(game.profile.settings.adaptive_performance,"Adaptive performance starts enabled")
 game.return_menu()
 game.audio_system.shutdown()
 await create_timer(.5).timeout
 game.queue_free()
 await create_timer(.2).timeout
 print("SURVIVOR_REBIRTH_PACK_CHECKS=",checks," FAILURES=",failures," NATIVE_WINDOWS=UNVERIFIED")
 quit(int(failures>0))
