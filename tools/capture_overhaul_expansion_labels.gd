extends "res://tools/capture_phase5d3_team.gd"
var observations=[]
func run():
 output="res://docs/evidence/gameplay-overhaul/expansion-render/";phase="after-label-fix"
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://overhaul-label-render-"+str(Time.get_ticks_usec())+".json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 preload("res://tests/onboarding_test_support.gd").skip(game);game.set_process(false);game.onboarding.set_process(false)
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution
  for room_index in [0,3]:
   game.return_menu();check(game.start_endless("underground_lab","standard",17),"actual Lab Endless")
   game.set_process(false);game.tutorial_enabled=false
   var m=game.model;check(m.claim_room(room_index),"actual opposite-facing room claim")
   m.player_position=m.player().bed_position();check(m.sleep_player(),"actual occupied room")
   var r=m.player();r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp();r.gold=100000;r.electricity=100000
   for tier in range(8):
    if tier in [0,7]:
     game.ui.close_context();game.full_map=false;game.focus_camera(true);await advance(.3)
     var name="lab-room"+str(room_index+1)+"-slots"+str(r.tile_count())+"-"+str(resolution.y)
     await capture(name)
     observations.append({"room":room_index,"slots":r.tile_count(),"normal":str(r.door_normal()),"bounds":str(r.bounds()),"bed":str(r.bed_position()),"camera":str(game.camera.position),"zoom":str(game.camera.zoom)})
    if tier<7:check(m.expansion.purchase(m),"actual paid expansion API")
 var f=FileAccess.open(output+phase+"/result.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"fixture":"Narrow affected label rerender, actual Lab opposite room claim/paid expansion API; injected100ktemporarywallet/BedDoor5, frozencombat. Not natural progression or human/Windows verification."}," "))
 print("OVERHAUL_EXPANSION_LABEL_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
