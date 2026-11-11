extends SceneTree
# Actual renderer captures. Prepared room/preview images are fixtures; full
# matches use normal funds and production BotAI decisions, not a human player.
var game
var names={}
var output="res://docs/screenshots/redesign/"

func _initialize(): call_deferred("run")

func capture(name: String):
 if names.has(name): return
 names[name]=true
 await process_frame
 await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image()
 var code=image.save_png(ProjectSettings.globalize_path(output+name+".png"))
 print("RENDER ",name," size=",image.get_size()," exit=",code," t=",snappedf(game.model.time,0.1)," result=",game.model.result," shots=",game.model.shots)
 if code!=OK: quit(1)

func fixture(index: int):
 game.start_match()
 game.model.reset(71)
 game.model.claim_room(index)
 var r=game.model.player()
 game.model.player_position=r.bed_position()
 game.model.sleep_player()
 r.gold=1000
 r.electricity=200
 game.tutorial_enabled=false
 game.focus_camera(true)
 return r

func run():
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 root.mode=Window.MODE_FULLSCREEN
 game.sound_volume=0
 await create_timer(0.2).timeout
 await capture("01-menu")
 game.start_match()
 game.full_map=true
 game.focus_camera(true)
 await capture("02-overview")
 for i in range(6):
  fixture(i)
  await capture("room-%d-theme" % (i+1))
 if "--rooms-only" in OS.get_cmdline_user_args():
  game.queue_free()
  await process_frame
  quit()
  return
 var room=fixture(1)
 game.selected_tile=0
 game.ui.open_context()
 await capture("03-build-cards")
 game.begin_placement("generator")
 await capture("04-valid-preview")
 game.placement_on_tile=false
 game.preview_position=Vector2(490,420)
 game.ui.update_match()
 await capture("05-invalid-preview")
 game.cancel_placement()
 game.model.buy("turret",0)
 game.model.buy("generator",1)
 game.model.buy("repair",2)
 game.selected_tile=0
 game.ui.open_context()
 await capture("06-upgrade-panel")
 game.ui.close_context()
 for level in range(4):
  room.bed_level=level
  room.door_level=level
  for building in room.buildings.values(): building.level=level+1
  await capture("stage-%d-fixture" % (level+1))
 room.bed_level=4
 await capture("stage-5-bed-fixture")
 room=fixture(1)
 game.model.time=game.model.preparation+1
 game.model.hunter.target=1
 game.model.hunter.position=room.door_position()+Vector2(0,22)
 game.model.hunter.state=HunterState.State.ATTACK
 game.model.hunter.cooldown=0
 await process_frame
 game.focus_camera(true)
 await capture("10-own-door-attack-fixture")
 game.start_match()
 game.model.reset(71)
 game.model.claim_room(1)
 room=game.model.player()
 game.model.player_position=room.bed_position()
 game.model.sleep_player()
 game.focus_camera(true)
 Engine.time_scale=4
 var started=Time.get_ticks_msec()
 while game.model.result=="" and Time.get_ticks_msec()-started<110000:
  await process_frame
  BotAI.tick(room,game.get_process_delta_time())
  if game.model.time>3: await capture("07-natural-sleep-income")
  if room.bed_level>=1 and room.door_level>=1: await capture("08-natural-bed-door-upgrade")
  if game.model.hunter.state==HunterState.State.MOVE: await capture("09-hunter-moving")
  if game.model.hunter.state==HunterState.State.ATTACK and game.model.hunter.target==game.model.player_room: await capture("10-own-door-under-attack")
  if not game.model.projectiles.is_empty(): await capture("11-travelling-projectiles")
  for event in game.model.combat_events:
   if event.type=="impact" and event.remaining>0.3: await capture("12-actual-impact")
  if room.buildings.size()==6: await capture("13-natural-support-economy")
 Engine.time_scale=1
 await create_timer(0.12).timeout
 await capture("14-hunter-death")
 await create_timer(1).timeout
 await capture("15-victory")
 var won=game.model.result=="victory"
 print("NATURAL_ACTIVE result=",game.model.result," time=",game.model.time," gold=",room.gold," buildings=",room.buildings.size())
 game.start_match()
 game.model.reset(8)
 game.model.claim_room(2)
 room=game.model.player()
 game.model.player_position=room.bed_position()
 game.model.sleep_player()
 game.focus_camera(true)
 Engine.time_scale=4
 started=Time.get_ticks_msec()
 while game.model.result=="" and Time.get_ticks_msec()-started<60000: await process_frame
 Engine.time_scale=1
 await create_timer(1.1).timeout
 await capture("16-defeat")
 var lost=game.model.result=="defeat"
 print("NATURAL_PASSIVE result=",game.model.result," time=",game.model.time)
 print("RENDER_SUMMARY files=",names.size()," won=",won," lost=",lost)
 game.queue_free()
 await process_frame
 quit(0 if won and lost else 1)
