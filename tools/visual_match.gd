extends SceneTree
# Rendered match with an automated player. The fixture claims room 2 and sleeps
# at time zero, then uses BotAI for spending. No resources/damage are injected.
var game
var captured = {}
func _initialize():
 call_deferred("run")
func snapshot(name):
 await process_frame
 await process_frame
 var status = OS.execute("import",["-display",":99","-window","Nightfall Dorm Automated Match",ProjectSettings.globalize_path("res://docs/evidence/"+name)])
 var r=game.model.player()
 print("MATCH_FRAME ",JSON.stringify({"file":name,"capture_exit":status,"time":game.model.time,"result":game.model.result,"hunter_hp":game.model.hunter.hp,"hunter_level":game.model.hunter.level,"gold":r.gold,"electricity":r.electricity,"bed":r.bed_level,"door":r.door_level,"buildings":r.buildings,"shots":game.model.shots}))
func run():
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 DisplayServer.window_set_title("Nightfall Dorm Automated Match")
 await process_frame
 game.start_match()
 game.model.reset(71)
 game.model.claim_room(1)
 game.model.player_position=game.model.player().bed_position()
 game.model.sleep_player()
 game.model.player().profile="balanced"
 Engine.time_scale=4.0
 var started=Time.get_ticks_msec()
 while game.model.result=="" and Time.get_ticks_msec()-started<150000:
  await process_frame
  BotAI.tick(game.model.player(),game.get_process_delta_time())
  for threshold in [40,80,120,180,240,360]:
   if game.model.time>=threshold and not captured.has(threshold):
    captured[threshold]=true
    await snapshot("audit-match-%03d.png" % threshold)
 Engine.time_scale=1.0
 await snapshot("audit-match-terminal.png")
 print("MATCH_RESULT ",game.model.result," time=",game.model.time)
 quit(0 if game.model.result!="" else 1)
