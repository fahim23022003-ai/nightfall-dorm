extends SceneTree
var checks=0
var failures=0
var game
func check(ok: bool,label: String):
 checks+=1
 if not ok:
  failures+=1
  push_error("HORROR UI: "+label)
func _initialize(): call_deferred("run")
func click(button):
 var point=root.get_final_transform()*button.get_global_rect().get_center()
 for pressed in [true,false]:
  var e=InputEventMouseButton.new()
  e.position=point
  e.global_position=point
  e.button_index=MOUSE_BUTTON_LEFT
  e.pressed=pressed
  Input.parse_input_event(e)
  await process_frame
func run():
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://horror-ui-test.json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 preload("res://tests/onboarding_test_support.gd").skip(game)
 await process_frame
 game.start_match()
 game.set_process(false)
 game.model.claim_room(0)
 var room=game.model.player()
 game.model.player_position=room.bed_position()
 game.model.sleep_player()
 room.gold=0
 game.ui.open_context()
 game.ui.update_match()
 game.audio_system.update_state(0.5,game.model,"match")
 await process_frame
 var before=game.audio_system.event_counts.get("insufficient_gold",0)
 await click(game.ui.actions["build:turret"])
 check(game.audio_system.event_counts.get("insufficient_gold",0)==before+1,"real disabled gold card plays specific rejection")
 check(room.buildings.is_empty() and room.gold==0,"disabled gold click never spends")
 room.gold=1000
 room.electricity=0
 game.ui.update_match()
 game.audio_system.update_state(0.5,game.model,"match")
 before=game.audio_system.event_counts.get("insufficient_power",0)
 await click(game.ui.actions["build:repair"])
 check(game.audio_system.event_counts.get("insufficient_power",0)==before+1,"real disabled power card plays specific rejection")
 check(room.buildings.is_empty() and room.gold==1000 and room.electricity==0,"disabled power click never spends")
 check(game.ui.horror_layer.mouse_filter==Control.MOUSE_FILTER_IGNORE,"notifications never capture building input")
 game.audio_system.shutdown()
 await create_timer(0.5).timeout
 game.queue_free()
 await process_frame
 print("HORROR_UI_CHECKS=%d FAILURES=%d" % [checks,failures])
 quit(0 if failures==0 else 1)
