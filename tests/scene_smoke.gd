extends SceneTree

var failures = 0
var checks = 0
var game

func check(condition: bool, label: String):
 checks += 1
 if not condition:
  failures += 1
  push_error("SCENE ASSERTION FAILED: " + label)

func press(text: String) -> bool:
 for node in game.ui.panel.get_children():
  if node is Button and node.text == text and not node.is_queued_for_deletion():
   node.pressed.emit()
   return true
 check(false,"button exists: " + text)
 return false

func click_position(position: Vector2):
 # Input.parse_input_event consumes physical window coordinates, including stretch.
 position = root.get_final_transform() * position
 var motion = InputEventMouseMotion.new()
 motion.position = position
 motion.global_position = position
 Input.parse_input_event(motion)
 await process_frame
 var down = InputEventMouseButton.new()
 down.position = position
 down.global_position = position
 down.button_index = MOUSE_BUTTON_LEFT
 down.pressed = true
 Input.parse_input_event(down)
 await process_frame
 var up = InputEventMouseButton.new()
 up.position = position
 up.global_position = position
 up.button_index = MOUSE_BUTTON_LEFT
 up.pressed = false
 Input.parse_input_event(up)
 await process_frame

func _initialize():
 call_deferred("run")

func run():
 var scene = load("res://scenes/main.tscn")
 check(scene is PackedScene,"main scene loads")
 game = scene.instantiate()
 root.add_child(game)
 await process_frame
 check(game.mode == "menu", "main menu initial mode")
 check(press("How to Play"),"help button connected")
 await process_frame
 var handbook = false
 for node in game.ui.panel.get_children():
  if node is Label and "SURVIVAL HANDBOOK" in node.text:
   handbook = true
 check(handbook,"help content shown")
 press("Back")
 await process_frame
 press("Settings")
 await process_frame
 var slider_found = false
 for node in game.ui.panel.get_children():
  if node is HSlider:
   slider_found = true
   node.value = 0.0
 check(slider_found and game.sound_volume == 0,"sound settings functional")
 press("Back")
 await process_frame
 press("Start Game")
 await process_frame
 check(game.mode=="menu","Start Game opens pre-match loadout")
 press("Start Night")
 await process_frame
 check(game.mode == "match" and game.model.time > 0,"Start Game starts active simulation")
 game.ui.pause_button.pressed.emit()
 var time_before = game.model.time
 await process_frame
 check(not game.model.running and game.model.time == time_before,"pause halts simulation")
 game.ui.pause_button.pressed.emit()
 game.model.claim_room(0)
 game.model.player_position = game.model.player().bed_position()
 game.model.sleep_player()
 game.focus_camera(true)
 game.model.player().gold = 1000
 game.model.player().electricity = 100
 game.ui.actions.bed.pressed.emit()
 check(game.model.player().bed_level == 1,"UI bed button invokes production upgrade")
 await click_position(game.world_to_screen(game.model.player().tile_position(1)))
 check(game.selected_tile == 1,"actual mouse input passes UI overlay and selects second floor tile")
 check(game.ui.context_open and game.ui.actions["build:generator"].visible,"floor selection opens contextual illustrated building cards")
 for node in game.ui.panel.get_children():
  if node is TextureRect:
   check(node.size.x<=154 and node.size.y<=154,"illustration control respects explicit display bounds")
 await click_position(game.ui.actions["build:generator"].get_global_rect().get_center())
 check(game.pending_build=="generator" and not game.model.player().buildings.has(1),"card enters preview without spending or building")
 await click_position(game.ui.confirm_button.get_global_rect().get_center())
 check(game.model.player().buildings.has(1) and game.model.player().buildings[1].kind == "generator","actual UI mouse click builds generator on selected floor")
 for kind in Catalog.BUILDINGS:
  check(not game.ui.building_effect(kind).is_empty(),"building effect tooltip formats for " + kind)
 game.model.result = "victory"
 await process_frame
 check(game.mode == "result", "model terminal result reaches end screen")
 press("Restart")
 await process_frame
 check(game.mode == "match" and game.model.result == "" and game.model.player_room == -1,"restart button clears match")
 game.model.result = "defeat"
 await process_frame
 press("Main menu")
 await process_frame
 check(game.mode == "menu", "result menu button returns menu")
 print("SCENE_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown()
 await create_timer(0.5).timeout
 game.queue_free()
 await create_timer(0.2).timeout
 quit(1 if failures else 0)
