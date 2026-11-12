extends "res://tools/capture_phase5d3_team.gd"
# Actual clean457560d baseline, prior to overhaul production edits.
const SOURCE="457560dc4a8712dd644b7a7cdca509218fe83f70"
var observations=[]
func baseline_camera():return {"position":str(game.camera.position),"zoom":str(game.camera.zoom),"player":str(game.model.player_position)}
func run():
 output="res://docs/evidence/gameplay-overhaul/";phase="baseline-render"
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://overhaul-baseline-"+str(OS.get_process_id())+"-"+str(Time.get_ticks_usec())+".json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 preload("res://tests/onboarding_test_support.gd").skip(game);game.set_process(false);game.onboarding.set_process(false)
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  game.return_menu();check(game.start_stage("stage_1","standard"),"real campaign Stage1 launches")
  game.set_process(false);game.tutorial_enabled=false
  var m=game.model;check(m.map_id=="abandoned_dorm","actual authored map")
  check(m.claim_room(0),"real room ownership API");m.player_position=m.player().bed_position();m.sleep_player();m.bot_claimed=5
  for i in range(1,6):
   var r=m.rooms[i];r.owner=i;r.sleeping=true;r.closed=true;r.resident_position=r.bed_position()
  game.ui.teammates.expanded=false;game.ui.items_ui.expanded=false;game.ui.help_open=false;game.ui.close_context();game.focus_camera(true)
  await advance(2.2);var before=baseline_camera();var player=m.player()
  check(not game.ui.context_open and not game.ui.context_box.visible,"default has closed detail panel")
  await capture("default-hud-"+suffix)
  await world_click(player.tile_position(0));await advance(.35)
  check(game.ui.context_open and game.ui.context_mode=="build","real pad click opens build panel")
  check(player.gold==25 and player.electricity==0,"inspection spends no starting resources")
  observations.append({"resolution":suffix,"map":m.map_id,"header_rect":str(game.ui.room_dock.get_global_rect()),"body_rect":str(game.ui.context_box.get_global_rect()),"camera_before":before,"camera_after":baseline_camera(),"default_gold":player.gold,"default_electricity":player.electricity,"tile_count":player.tile_count()})
  await capture("open-build-"+suffix)
 var file=FileAccess.open("res://docs/evidence/gameplay-overhaul/baseline-ux-observations.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"source":SOURCE,"checks":checks,"failures":failures,"observations":observations,"fixture":"Fresh isolated profile. Actual Stage1 Normal campaign, real claim/sleep APIs; player moved to bed for controlled seated HUD. Five actual NPC room states populated for roster layout. Real pad-click input; starting25Gold/0Electricity unchanged. Combat model held while renderer/UI advance. Linux real Xorg/Mesa/Dummy audio; noWindows/audio/naturalplayclaim."}," "))
 print("OVERHAUL_BASELINE_RENDER_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
