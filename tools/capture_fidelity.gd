extends SceneTree
# Rendered evidence, not manual play: fixed seeds, fixture claim/sleep, ordinary
# starting funds and production BotAI decisions. Passive defeat uses no purchases.
var game
var captures: Dictionary = {}
var output = "res://docs/screenshots/"

func _initialize():
 call_deferred("run")

func capture(name: String, freeze_combat: bool = false):
 if captures.has(name): return
 captures[name] = true
 var running = game.model.running
 if freeze_combat: game.model.running = false
 await process_frame
 await process_frame
 var path = ProjectSettings.globalize_path(output+name+".png")
 await RenderingServer.frame_post_draw
 var code = root.get_texture().get_image().save_png(path)
 var room = game.model.player()
 print("CAPTURE ",JSON.stringify({"file":name+".png","exit":code,"time":game.model.time,"result":game.model.result,"paused_for_frame":freeze_combat,"gold":room.gold if room != null else 0,"electricity":room.electricity if room != null else 0,"hunter_state":HunterState.State.keys()[game.model.hunter.state],"hunter_hp":game.model.hunter.hp,"shots":game.model.shots}))
 if freeze_combat: game.model.running = running
 if code != 0:
  push_error("Screenshot capture failed: "+name)
  quit(1)

func run():
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
 game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 root.title = "Nightfall Dorm Capture"
 root.mode = Window.MODE_FULLSCREEN
 game.sound_volume = 0
 await create_timer(0.5).timeout
 await capture("01-main-menu")
 game.start_match()
 game.model.reset(71)
 await capture("02-full-dormitory")
 game.model.claim_room(1)
 game.model.player_position = game.model.player().bed_position()
 await capture("03-room-claimed-fixture")
 game.model.sleep_player()
 Engine.time_scale = 4
 var combat_only = "--combat-only" in OS.get_cmdline_user_args()
 var started = Time.get_ticks_msec()
 while game.model.result == "" and Time.get_ticks_msec()-started < 120000:
  await process_frame
  var room = game.model.player()
  BotAI.tick(room,game.get_process_delta_time())
  if game.model.time > 2: await capture("04-sleeping-income")
  if room.bed_level >= 1 and room.door_level >= 1: await capture("05-bed-door-upgraded")
  if room.buildings.has(0): await capture("06-turret-built")
  if room.buildings.size() >= 6: await capture("07-electricity-support-buildings")
  if game.model.hunter.state == HunterState.State.MOVE: await capture("08-hunter-approaching")
  if game.model.hunter.state == HunterState.State.ATTACK: await capture("09-hunter-attacking",true)
  for r in game.model.rooms:
   for b in r.buildings.values():
    if b.flash > 0: await capture("10-turrets-firing",true)
  if combat_only and captures.has("09-hunter-attacking") and captures.has("10-turrets-firing"):
   Engine.time_scale = 1
   game.queue_free()
   await process_frame
   quit(0)
   return
 Engine.time_scale = 1
 await capture("11-victory")
 var victory = game.model.result == "victory"
 print("ACTIVE_MATCH result=",game.model.result," time=",game.model.time)
 game.start_match()
 game.model.reset(8)
 game.model.claim_room(2)
 game.model.player_position = game.model.player().bed_position()
 game.model.sleep_player()
 Engine.time_scale = 4
 started = Time.get_ticks_msec()
 while game.model.result == "" and Time.get_ticks_msec()-started < 60000:
  await process_frame
 Engine.time_scale = 1
 await capture("12-defeat")
 var defeat = game.model.result == "defeat"
 print("PASSIVE_MATCH result=",game.model.result," time=",game.model.time)
 print("SCREENSHOTS=",captures.size()," VICTORY=",victory," DEFEAT=",defeat)
 game.queue_free()
 await process_frame
 quit(0 if victory and defeat and captures.size() == 12 else 1)
