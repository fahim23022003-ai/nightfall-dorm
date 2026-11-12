extends SceneTree
var checks=0
var failures=0
var game

func check(value: bool,label: String):
 checks+=1
 if not value:
  failures+=1
  push_error("OVERHAUL UI: "+label)

func _initialize(): call_deferred("run")

func click_at(point: Vector2):
 point=root.get_final_transform()*point
 var move=InputEventMouseMotion.new()
 move.position=point
 move.global_position=point
 Input.parse_input_event(move)
 await process_frame
 for pressed in [true,false]:
  var event=InputEventMouseButton.new()
  event.position=point
  event.global_position=point
  event.button_index=MOUSE_BUTTON_LEFT
  event.pressed=pressed
  Input.parse_input_event(event)
  await process_frame

func escape():
 for pressed in [true,false]:
  var event=InputEventKey.new()
  event.keycode=KEY_ESCAPE
  event.physical_keycode=KEY_ESCAPE
  event.pressed=pressed
  Input.parse_input_event(event)
  await process_frame

func run():
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 preload("res://tests/onboarding_test_support.gd").skip(game)
 await process_frame
 game.sound_volume=0
 game.start_match()
 await process_frame
 check(not game.ui.context_open,"build cards start contextual rather than permanently displayed")
 check(not game.ui.actions["build:turret"].visible,"no permanent build-button sidebar")
 game.model.claim_room(3)
 var room=game.model.player()
 game.model.player_position=room.bed_position()
 game.model.sleep_player()
 game.focus_camera(true)
 room.gold=1000
 room.electricity=100
 await click_at(game.world_to_screen(room.tile_position(1)))
 check(game.selected_tile==1 and game.ui.context_open,"bottom-wing floor input selects correct model tile")
 var own_rect=Rect2(game.world_to_screen(room.bounds().position),room.bounds().size*game.camera.zoom)
 check(not game.ui.context_box.get_rect().intersects(own_rect),"context menu leaves own bedroom visible")
 check(not game.ui.context_box.get_global_rect().has_point(game.world_to_screen(room.bed_position())),"focused side inspector leaves sleeping character visible")
 for node in game.ui.build_items:
  check(node.visible,"all illustrated card components visible together")
  if node is TextureRect: check(node.size.x<=100 and node.size.y<=100,"card illustration size bounded")
 await click_at(game.ui.actions["build:generator"].get_global_rect().get_center())
 check(game.pending_build=="generator" and not room.buildings.has(1),"context card previews without spending")
 await click_at(game.ui.confirm_button.get_global_rect().get_center())
 check(room.buildings.has(1) and room.buildings[1].kind=="generator","confirmed card purchases in actual selected bottom-wing room")
 await click_at(game.world_to_screen(room.tile_position(1)))
 check(game.ui.actions.upgrade.visible and not game.ui.actions["build:turret"].visible,"built tile switches to focused upgrade panel")
 var bed_level=room.bed_level
 await click_at(game.ui.context_box.global_position+Vector2(5,5))
 check(room.bed_level==bed_level,"context background prevents clicks reaching covered dock actions")
 await escape()
 check(not game.ui.context_open and game.model.running,"first Escape closes context without pausing")
 await escape()
 check(not game.model.running and game.ui.pause_items.size()>0,"second Escape opens functional pause overlay")
 await escape()
 check(game.model.running and game.ui.pause_items.is_empty(),"Escape resumes and clears pause overlay")
 var dock=game.ui.room_dock.get_rect()
 check(dock.encloses(game.ui.room_bed_summary.get_rect()) and dock.encloses(game.ui.room_door_summary.get_rect()),"bed/door summary controls stay in compact dock")
 check(game.presentation.textures.size()>=32,"original environment and actor textures loaded")
 game.model.result="victory"
 await process_frame
 var restart: Button
 for node in game.ui.panel.get_children():
  if node is Button and node.text=="Restart" and not node.is_queued_for_deletion(): restart=node
 check(restart!=null and restart.disabled,"outcome reveal blocks invisible button clicks")
 await create_timer(1.1).timeout
 check(is_instance_valid(restart) and not restart.disabled and restart.modulate.a>0.99,"outcome buttons become visible and interactive")
 await click_at(restart.get_global_rect().get_center())
 check(game.mode=="match" and game.model.player_room==-1 and not game.ui.context_open,"actual result click restarts clean presentation and model")
 print("OVERHAUL_UI_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown()
 await create_timer(0.5).timeout
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)
