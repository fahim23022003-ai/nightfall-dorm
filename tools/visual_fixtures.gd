extends SceneTree
# Deterministic UI fixtures: these screenshots are rendered state inspection,
# not evidence of naturally reached gameplay outcomes. Requires Xorg :99 and import.
var game
var output = "res://docs/evidence/"
func _initialize():
 call_deferred("run")
func capture(name):
 await process_frame
 await process_frame
 await create_timer(0.2).timeout
 var status = OS.execute("import",["-display",":99","-window","Nightfall Dorm Visual Audit",ProjectSettings.globalize_path(output+name)])
 print("VISUAL capture ",name," physical=",DisplayServer.window_get_size()," exit=",status)
func run():
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 DisplayServer.window_set_title("Nightfall Dorm Visual Audit")
 await process_frame
 game.start_match()
 game.model.claim_room(1)
 game.model.player_position=game.model.player().bed_position()
 game.model.sleep_player()
 var room=game.model.player()
 room.gold=200000
 room.electricity=200000
 room.bed_level=4
 room.door_level=4
 room.door_hp=room.max_hp()
 for i in range(6):
  room.build(Catalog.BUILDINGS.keys()[i],i)
  for level in range(3):
   room.upgrade_building(i)
 game.selected_tile=4
 game.model.running=false
 await capture("audit-max-level-final.png")
 root.size = Vector2i(960,600)
 await capture("audit-physical-960-final.png")
 game.mode="menu"
 game.ui.show_settings()
 await process_frame
 for child in game.ui.panel.get_children():
  if child is CheckButton:
   child.button_pressed=true
 await create_timer(0.4).timeout
 await capture("audit-settings-fullscreen-final.png")
 game.mode="match"
 game.ui.show_match()
 await capture("audit-fullscreen-final.png")
 root.mode = Window.MODE_WINDOWED
 root.size = Vector2i(1280,800)
 await create_timer(0.2).timeout
 room.bed_level=0
 room.door_level=0
 room.gold=0
 room.electricity=0
 room.door_hp = room.max_hp()
 game.model.running=true
 game.ui.bed_button.pressed.emit()
 game.model.running=false
 await capture("audit-rejection-final.png")
 game.model.result="defeat"
 game.mode="result"
 game.ui.show_result()
 await capture("audit-result-final.png")
 quit()
