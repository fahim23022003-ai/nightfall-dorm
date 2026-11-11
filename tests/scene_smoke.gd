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
 check(game.mode == "match" and game.model.time > 0,"Start Game starts active simulation")
 press("Pause / resume [Esc]")
 var time_before = game.model.time
 await process_frame
 check(not game.model.running and game.model.time == time_before,"pause halts simulation")
 press("Pause / resume [Esc]")
 game.model.claim_room(0)
 game.model.player_position = game.model.player().bed_position()
 game.model.sleep_player()
 game.model.player().gold = 1000
 game.model.player().electricity = 100
 press("Upgrade bed")
 check(game.model.player().bed_level == 1,"UI bed button invokes production upgrade")
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
 game.audio.stop()
 game.audio.stream = null
 game.queue_free()
 await create_timer(0.2).timeout
 quit(1 if failures else 0)
