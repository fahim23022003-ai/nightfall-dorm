extends SceneTree
# Two complete rendered matches with normal funds. Claim/bed and balanced input
# are automated through production model APIs; no gifted resources or forced result.
var game
func _initialize(): call_deferred("run")
func capture(name: String):
 await process_frame
 await RenderingServer.frame_post_draw
 var code=root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/screenshots/phase2/"+name+".png"))
 print("PHASE2_NATURAL_CAPTURE ",name," code=",code)
 if code!=OK: quit(1)
func run():
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://phase2-natural-capture-"+str(Time.get_ticks_usec())+".json")
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 root.mode=Window.MODE_FULLSCREEN
 var valid=true
 for active in [true,false]:
  game.start_match("standard")
  game.model.random.seed=7 if active else 8
  game.model.claim_room(1 if active else 2)
  var room=game.model.player()
  game.model.player_position=room.bed_position()
  game.model.sleep_player()
  room.profile="balanced"
  game.focus_camera(true)
  var before=game.profile.xp
  var combat_frame=false
  var began=Time.get_ticks_msec()
  Engine.time_scale=4
  while game.model.result=="" and Time.get_ticks_msec()-began<110000:
   await process_frame
   if active: BotAI.tick(room,game.get_process_delta_time())
   if active and not combat_frame and game.model.hunter.level>=2:
    game.full_map=true
    game.focus_camera(true)
    await capture("08-natural-escalated-defense")
    game.full_map=false
    game.focus_camera(true)
    combat_frame=true
  Engine.time_scale=1
  await create_timer(1.2).timeout
  var expected="victory" if active else "defeat"
  var passed=game.model.result==expected and game.profile.xp>before and game.profile.save_ok
  valid=valid and passed
  await capture("09-natural-victory-xp" if active else "10-natural-defeat-xp")
  var fresh=PlayerProfile.new(game.profile.path)
  passed=passed and fresh.load_profile() and fresh.xp==game.profile.xp
  valid=valid and passed
  print("PHASE2_NATURAL_MATCH active=",active," result=",game.model.result," time=",game.model.time," initial_gold=25 xp_before=",before," xp_after=",game.profile.xp," breakdown=",JSON.stringify(game.last_progression)," disk_reload=",passed)
 game.audio_system.shutdown()
 await create_timer(0.5).timeout
 game.queue_free()
 await process_frame
 print("PHASE2_NATURAL_MATCHES=2 PASS=",valid)
 quit(0 if valid else 1)
