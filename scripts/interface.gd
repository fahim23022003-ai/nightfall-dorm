class_name GameInterface
extends CanvasLayer

var game
var panel: Control
var status: Label
var message: Label
var details: Label
var buttons: Array = []
var bed_button: Button
var door_button: Button

func _init(owner_game = null):
 game = owner_game

func _ready():
 panel = Control.new()
 panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(panel)
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 show_menu()

func clear():
 for child in panel.get_children():
  child.queue_free()
 buttons.clear()

func label_at(text: String, pos: Vector2, size: int = 20, width: float = 900) -> Label:
 var label = Label.new()
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 label.text = text
 label.position = pos
 label.size = Vector2(width,50)
 label.add_theme_font_size_override("font_size",size)
 panel.add_child(label)
 return label

func button(text: String, pos: Vector2, callback: Callable, width: float = 240) -> Button:
 var b = Button.new()
 b.text = text
 b.position = pos
 b.size = Vector2(width,38)
 b.pressed.connect(callback)
 panel.add_child(b)
 return b

func show_menu():
 clear()
 label_at("NIGHTFALL DORM",Vector2(365,160),48)
 label_at("Keep the lights alive. Hold the door until dawn.",Vector2(370,225),20)
 button("Start Game",Vector2(505,320),game.start_match)
 button("How to Play",Vector2(505,370),show_help)
 button("Settings",Vector2(505,420),show_settings)
 button("Exit Game",Vector2(505,470),func(): game.get_tree().quit())

func show_help():
 clear()
 label_at("SURVIVAL HANDBOOK",Vector2(100,110),36)
 label_at("WASD / arrows: move    E: claim room / sleep    Esc: pause\n\nWalk through a doorway into a free room. Press E to claim it.\nApproach the cyan bed and press E again: your door closes and gold starts.\n\nClick a numbered floor tile, then buy a building from the right panel.\nDynamo produces electricity. Amplifier boosts gold. Relay boosts turret damage.\nRepair station heals intact doors; manual repair costs 12 gold.\nClick an occupied tile and choose Upgrade selected to improve its building.\n\nThe hunter arrives after 30 seconds. Turrets fire automatically.\nUpgrade beds for income and doors for durability. Five bots defend other rooms.\nHunter defeated = victory. Your resident eliminated = defeat.\n\nDoors require bed progression; advanced beds and doors need electricity.\nYou cannot leave bed after sleeping. Choose your room carefully.",Vector2(100,185),21)
 button("Back",Vector2(100,750),show_menu)

func show_settings():
 clear()
 label_at("SETTINGS",Vector2(420,200),38)
 var slider = HSlider.new()
 slider.position = Vector2(420,320)
 slider.size = Vector2(350,40)
 slider.step = 0.01
 slider.min_value = 0
 slider.max_value = 1
 slider.value = game.sound_volume
 slider.value_changed.connect(func(value): game.sound_volume = value)
 panel.add_child(slider)
 label_at("Sound volume (original synthesized effects)",Vector2(420,270),20)
 var toggle = CheckButton.new()
 toggle.text = "Fullscreen"
 toggle.position = Vector2(420,390)
 toggle.button_pressed = DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
 toggle.toggled.connect(func(value): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED))
 panel.add_child(toggle)
 button("Back",Vector2(420,480),show_menu)

func show_match():
 clear()
 status = label_at("",Vector2(35,12),19,1180)
 message = label_at("WASD / arrows to move. Enter a free room; E to claim, then E near bed to sleep.",Vector2(35,57),17,1200)
 details = label_at("",Vector2(965,107),15,300)
 bed_button = button("Upgrade bed",Vector2(970,240),func(): purchase(game.model.upgrade_bed()),280)
 door_button = button("Upgrade door",Vector2(970,284),func(): purchase(game.model.upgrade_door()),280)
 button("Repair door · 12 gold",Vector2(970,328),func(): purchase(game.model.repair_door()),280)
 var y = 385
 for kind in Catalog.BUILDINGS:
  var data = Catalog.BUILDINGS[kind]
  var id = kind
  var build_button = button("%s · %d G / %d E" % [data.name,data.gold,data.power],Vector2(970,y),func(): purchase(game.model.buy(id,game.selected_tile)),280)
  build_button.tooltip_text = building_effect(kind)
  y += 43
 button("Upgrade selected tile",Vector2(970,655),func(): purchase(game.model.upgrade_building(game.selected_tile)),280)
 button("Pause / resume [Esc]",Vector2(970,710),game.toggle_pause,280)
 button("Return to main menu",Vector2(970,755),game.return_menu,280)

func purchase(success: bool):
 if success:
  message.text = "Purchase complete."
  game.play_tone(650)
 else:
  message.text = game.model.purchase_error()
  game.play_tone(160)

func update_match():
 if not is_instance_valid(status) or game.mode != "match":
  return
 var m = game.model
 var room = m.player()
 status.text = "NIGHTFALL   %03ds   |   %s   |   Hunter L%d  %d / %d HP" % [m.time,"Arrival in %ds" % maxi(0,ceili(m.preparation-m.time)) if m.time<m.preparation else "HUNTER ACTIVE",m.hunter.level,m.hunter.hp,m.hunter.max_hp]
 if not m.running:
  status.text += "   [PAUSED]"
 if room == null:
  details.text = "Choose a free room.\nE inside claims it.\nE near bed sleeps.\n\nBeds only earn while asleep."
 else:
  details.text = "ROOM %d · %s\nGold: %d    Electricity: %d\nBed L%d · %.1f gold/s\nDoor L%d · %d / %d HP\nTile %d: %s" % [room.index+1,"SLEEPING" if room.sleeping else "AWAKE",room.gold,room.electricity,room.bed_level+1,room.income_rate(),room.door_level+1,room.door_hp,room.max_hp(),game.selected_tile+1,tile_description(room)]
  var bed_cost = "MAX" if room.bed_level>=4 else "%dG / %dE" % [Catalog.BED_COST[room.bed_level],Catalog.BED_POWER[room.bed_level]]
  var door_cost = "MAX" if room.door_level>=4 else "%dG / %dE" % [Catalog.DOOR_COST[room.door_level],Catalog.DOOR_POWER[room.door_level]]
  bed_button.text = "Bed L%d → %s" % [room.bed_level+1,bed_cost]
  door_button.text = "Door L%d → %s" % [room.door_level+1,door_cost]
  # Progression requirements are explained in the help screen and tooltips.
  bed_button.tooltip_text = "Next income: %s gold/s. Requires door level %d." % ["MAX" if room.bed_level>=4 else str(Catalog.BED_INCOME[room.bed_level+1]),maxi(1,room.bed_level)]
  door_button.tooltip_text = "Next durability: %s HP. Requires bed level %d. Preserves current damage." % ["MAX" if room.door_level>=4 else str(Catalog.DOOR_HP[room.door_level+1]),maxi(1,room.door_level)]
  details.tooltip_text = tile_description(room)

func tile_description(room: RoomState) -> String:
 if not room.buildings.has(game.selected_tile):
  return "Empty floor: choose a building"
 var b = room.buildings[game.selected_tile]
 var d = Catalog.BUILDINGS[b.kind]
 if b.level >= Catalog.BUILDING_MAX_LEVEL:
  return "%s L%d · MAX" % [b.kind.capitalize(),b.level]
 return "%s L%d · up %dG/%dE" % [b.kind.capitalize(),b.level,d.gold*b.level,(d.power+3)*b.level]

func show_result():
 clear()
 var veil = ColorRect.new()
 veil.color = Color(0.035,0.055,0.085,0.96)
 veil.size = Vector2(1280,800)
 panel.add_child(veil)
 var m = game.model
 label_at("DAWN SURVIVED" if m.result=="victory" else "YOUR LIGHT WENT OUT",Vector2(300,210),42)
 label_at("Time survived: %ds     Hunter level: %d\nShots fired: %d     Damage dealt: %d\nGold earned: %d     Residents lost: %d" % [m.time,m.hunter.level,m.player().shots if m.player()!=null else 0,m.player().damage_dealt if m.player()!=null else 0,m.player().income_total if m.player()!=null else 0,m.eliminations],Vector2(380,300),23)
 button("Restart",Vector2(480,470),game.start_match)
 button("Main menu",Vector2(480,520),game.return_menu)

func building_effect(kind: String) -> String:
 var data = Catalog.BUILDINGS[kind]
 match kind:
  "turret", "heavy":
   return "%.1f damage / %.1fs; range %.1fpx. Upgrades increase damage and attack speed. %s" % [data.damage,data.interval,data.range,"Requires bed level 2." if kind=="heavy" else ""]
  "generator":
   return "%.1f electricity per second per level." % data.rate
  "repair":
   return "%.1f door HP per second per level. Cannot restore a destroyed door." % data.rate
  "economy":
   return "+%d%% bed gold income per level." % (data.rate*100)
  "enhancer":
   return "+%d%% room turret damage per level." % (data.rate*100)
 return ""
