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
var pause_button: Button
var actions: Dictionary = {}
var context_open = false
var context_items: Array = []
var build_items: Array = []
var upgrade_items: Array = []
var pause_items: Array = []
var card_visuals: Dictionary = {}
var context_box: Panel
var context_title: Label
var selected_icon: TextureRect
var selected_details: Label
var gold_label: Label
var power_label: Label
var phase_label: Label
var hunter_label: Label
var hunter_bar: ProgressBar
var default_font = preload("res://assets/fonts/Interface.ttf")
var display_font = preload("res://assets/fonts/Display.ttf")

func _init(owner_game = null):
 game = owner_game

func _ready():
 panel = Control.new()
 panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(panel)
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var theme = Theme.new()
 theme.default_font = default_font
 theme.default_font_size = 15
 panel.theme = theme
 show_menu()

func clear():
 for child in panel.get_children(): child.queue_free()
 buttons.clear()
 actions.clear()
 context_items.clear()
 build_items.clear()
 upgrade_items.clear()
 pause_items.clear()
 card_visuals.clear()
 context_open = false

func style(fill: String = "1c2b3c",edge: String = "796c62",radius: int = 10) -> StyleBoxFlat:
 var s = StyleBoxFlat.new()
 s.bg_color = Color(fill)
 s.border_color = Color(edge)
 s.set_border_width_all(1)
 s.set_corner_radius_all(radius)
 s.shadow_color = Color(0.02,0.04,0.09,0.5)
 s.shadow_size = 8
 s.shadow_offset = Vector2(0,4)
 return s

func box(rect: Rect2, fill: String = "1c2b3c", edge: String = "796c62") -> Panel:
 var p = Panel.new()
 p.position = rect.position
 p.size = rect.size
 p.mouse_filter = Control.MOUSE_FILTER_IGNORE
 p.add_theme_stylebox_override("panel",style(fill,edge))
 panel.add_child(p)
 return p

func label_at(text: String, pos: Vector2, size: int = 20, width: float = 900, heading: bool = false) -> Label:
 var l = Label.new()
 l.mouse_filter = Control.MOUSE_FILTER_IGNORE
 l.text = text
 l.position = pos
 l.size = Vector2(width,40)
 l.add_theme_font_size_override("font_size",size)
 l.add_theme_color_override("font_color",Color("f0e6d3"))
 if heading: l.add_theme_font_override("font",display_font)
 panel.add_child(l)
 return l

func icon(name: String,pos: Vector2,size: Vector2) -> TextureRect:
 var t = TextureRect.new()
 t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 t.texture = game.presentation.textures[name]
 t.position = pos
 t.size = size
 t.mouse_filter = Control.MOUSE_FILTER_IGNORE
 panel.add_child(t)
 return t

func button(text: String,pos: Vector2,callback: Callable,width: float = 240,height: float = 42) -> Button:
 var b = Button.new()
 b.text = text
 b.position = pos
 b.size = Vector2(width,height)
 b.pressed.connect(callback)
 for state in ["normal","hover","pressed","disabled","focus"]:
  var fill = "304b54" if state == "hover" else "263b49"
  if state == "disabled": fill = "202b39"
  var s = style(fill,"dfbd83" if state in ["hover","focus"] else "8e806a",7)
  s.shadow_size = 2
  b.add_theme_stylebox_override(state,s)
 b.add_theme_color_override("font_color",Color("f2e7d3"))
 b.add_theme_color_override("font_disabled_color",Color("8e9298"))
 panel.add_child(b)
 return b

func action_icon(b: Button,name: String):
 b.icon = game.presentation.textures[name]
 b.expand_icon = true
 b.add_theme_constant_override("icon_max_width",38)

func show_menu():
 clear()
 label_at("A MIDNIGHT SURVIVAL TALE",Vector2(100,182),12,500).modulate = Color("d7b783")
 label_at("NIGHTFALL\nDORM",Vector2(92,223),65,570,true)
 label_at("The halls are quiet. The doors won't hold forever.\nChoose a room. Keep one last light alive.",Vector2(100,404),16,540)
 var start = button("Start Game",Vector2(100,495),game.start_match,310,58)
 start.add_theme_font_size_override("font_size",23)
 button("How to Play",Vector2(100,569),show_help,150,44)
 button("Settings",Vector2(260,569),show_settings,150,44)
 button("Exit Game",Vector2(100,628),func(): game.get_tree().quit(),310,42)
 label_at("An original dormitory defense game",Vector2(100,813),12,500).modulate=Color("9aaeb5")

func show_help():
 clear()
 box(Rect2(100,100,1080,696))
 label_at("SURVIVAL HANDBOOK",Vector2(140,135),32,900,true)
 label_at("WASD / arrows: move     E: claim a room / sleep     Esc: close cards / pause\n\nEnter a vacant room. Press E to claim it, then approach the bed and press E.\nYour door closes and gold begins to grow. Sleeping commits you to that room.\n\nClick the brass floor sigils to open illustrated building cards.\nA Dynamo makes electricity; a Dream amplifier boosts bed income.\nRepair stations mend intact doors. Relays strengthen room turrets.\nSelect a built machine to upgrade it. Hover cards for effects and requirements.\n\nUse the bed and door cards below the map for upgrades. Repair costs 12 gold.\nAdvanced levels require electricity and matching bed/door progression.\n\nThe hunter arrives after 30 seconds. Your turrets fire automatically.\nDefeat the hunter to survive. A breached room leaves its sleeper exposed.\nFive other residents build their own defenses. Your elimination ends the match.",Vector2(140,203),18,1000)
 button("Back",Vector2(140,724),show_menu,180)

func show_settings():
 clear()
 box(Rect2(350,180,580,460))
 label_at("SETTINGS",Vector2(420,215),34,460,true)
 label_at("Sound volume",Vector2(420,310),18,400)
 var slider = HSlider.new()
 slider.position = Vector2(420,354)
 slider.size = Vector2(400,36)
 slider.step = 0.01
 slider.min_value = 0
 slider.max_value = 1
 slider.value = game.sound_volume
 slider.value_changed.connect(func(value): game.sound_volume=value)
 panel.add_child(slider)
 var toggle = CheckButton.new()
 toggle.text = "Fullscreen"
 toggle.position = Vector2(420,417)
 toggle.button_pressed = DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
 toggle.toggled.connect(func(value): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED))
 panel.add_child(toggle)
 button("Back",Vector2(420,537),show_menu,180)

func show_match():
 clear()
 box(Rect2(28,18,1224,73),"162737","8b826c")
 icon("economy",Vector2(42,28),Vector2(45,46))
 label_at("NIGHTFALL",Vector2(96,30),21,250,true)
 label_at("DORMITORY  /  NIGHT WATCH",Vector2(97,59),10,260).modulate=Color("b4b4a6")
 icon("coin",Vector2(359,32),Vector2(37,36))
 gold_label=label_at("0",Vector2(402,32),24,110)
 icon("power",Vector2(506,31),Vector2(34,39))
 power_label=label_at("0",Vector2(548,32),24,105)
 phase_label=label_at("",Vector2(680,29),16,185)
 hunter_label=label_at("",Vector2(876,27),12,280)
 hunter_bar=ProgressBar.new()
 hunter_bar.position=Vector2(876,57)
 hunter_bar.size=Vector2(280,11)
 hunter_bar.show_percentage=false
 hunter_bar.add_theme_stylebox_override("background",style("101c2d","574c63",4))
 hunter_bar.add_theme_stylebox_override("fill",style("b57b9e","d2b8be",4))
 hunter_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
 panel.add_child(hunter_bar)
 pause_button=button("Ⅱ",Vector2(1189,35),game.toggle_pause,42,35)
 pause_button.tooltip_text="Pause / resume [Esc]"
 box(Rect2(280,96,720,30),"1b2b39","465767")
 message=label_at("Enter a room, claim it with E, then sleep in its bed.",Vector2(292,101),13,696)
 message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 # Compact room dock replaces the debugging sidebar.
 box(Rect2(145,782,990,88),"182a39","a18d6f")
 label_at("YOUR NIGHTWATCH",Vector2(168,798),10,210).modulate=Color("c9b58c")
 details=label_at("Choose a room",Vector2(168,820),18,220,true)
 bed_button=button("Upgrade bed",Vector2(390,797),func(): purchase(game.model.upgrade_bed()),200,61)
 door_button=button("Upgrade door",Vector2(604,797),func(): purchase(game.model.upgrade_door()),200,61)
 actions.bed=bed_button
 actions.door=door_button
 action_icon(bed_button,"bed")
 action_icon(door_button,"door")
 actions.repair=button("Repair\n12 gold",Vector2(818,797),func(): purchase(game.model.repair_door()),151,61)
 action_icon(actions.repair,"repair")
 icon("foundation",Vector2(991,800),Vector2(33,33))
 label_at("Click a floor sigil\nto build or upgrade",Vector2(987,836),10,150)
 label_at("WASD / arrows  Move     E  Interact     Click  Build     Esc  Close / pause",Vector2(145,878),11,1000).modulate=Color("9ab0b8")
 # Context card nodes are retained but hidden until a real floor selection.
 context_box=box(Rect2(170,772,940,118),"1a2a3b","c3a67a")
 context_box.mouse_filter=Control.MOUSE_FILTER_STOP
 context_title=label_at("CHOOSE A DEFENSE",Vector2(190,779),13,800,true)
 var close=button("×",Vector2(1067,778),close_context,27,24)
 context_items=[context_box,context_title,close]
 var n=0
 for kind in Catalog.BUILDINGS:
  var id=kind
  var data=Catalog.BUILDINGS[kind]
  var b=button("",Vector2(184+n*154,804),func(): purchase(game.model.buy(id,game.selected_tile)),142,78)
  b.add_theme_font_size_override("font_size",12)
  var art=icon(kind,b.position+Vector2(46,0),Vector2(50,48))
  var title=label_at(data.name,b.position+Vector2(3,46),11,136)
  title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  var price=label_at("%d G  ·  %d E" % [data.gold,data.power],b.position+Vector2(3,62),10,136)
  price.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  actions["build:"+kind]=b
  card_visuals["build:"+kind]=[art,title,price]
  build_items.append_array([b,art,title,price])
  n+=1
 selected_icon=icon("turret",Vector2(195,805),Vector2(72,72))
 selected_details=label_at("",Vector2(292,808),13,510)
 selected_details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 selected_details.size.y=66
 actions.upgrade=button("Upgrade selected tile",Vector2(840,813),func(): purchase(game.model.upgrade_building(game.selected_tile)),235,51)
 upgrade_items=[selected_icon,selected_details,actions.upgrade]
 close_context()

func open_context():
 context_open=true
 refresh_context()

func close_context():
 context_open=false
 for node in context_items+build_items+upgrade_items:
  if is_instance_valid(node): node.visible=false

func refresh_context():
 if not context_open: return
 var room=game.model.player()
 if room==null: close_context(); return
 var y=772.0
 var shift=y-context_box.position.y
 for node in context_items+build_items+upgrade_items: node.position.y+=shift
 var built=room.buildings.has(game.selected_tile)
 for node in context_items: node.visible=true
 for node in build_items: node.visible=not built
 for node in upgrade_items: node.visible=built
 if built:
  var b=room.buildings[game.selected_tile]
  selected_icon.texture=game.presentation.textures[b.kind]
  context_title.text=Catalog.BUILDINGS[b.kind].name.to_upper()+"  /  LEVEL %d" % b.level
  selected_details.text=building_effect(b.kind)+"\n"+action_reason("upgrade")
 else:
  context_title.text="CHOOSE A DEFENSE  /  EMPTY FOUNDATION"

func show_pause(open: bool):
 close_context()
 for node in pause_items:
  if is_instance_valid(node): node.queue_free()
 pause_items.clear()
 if not open: return
 var veil=ColorRect.new()
 veil.color=Color(0.03,0.06,0.12,0.72)
 veil.size=Vector2(1280,900)
 panel.add_child(veil)
 var bg=box(Rect2(420,260,440,350))
 var title=label_at("NIGHTWATCH PAUSED",Vector2(455,300),24,380,true)
 var help=label_at("Take a breath. Your room can wait.",Vector2(455,350),15,370)
 var resume=button("Resume",Vector2(455,419),game.toggle_pause,370,48)
 var menu=button("Return to main menu",Vector2(455,485),game.return_menu,370,48)
 pause_items=[veil,bg,title,help,resume,menu]

func purchase(success: bool):
 message.text="Your nightwatch grows stronger." if success else game.model.purchase_error()
 game.play_tone(650 if success else 160)
 if success:
  message.modulate=Color("f5d48f")
  create_tween().tween_property(message,"modulate",Color.WHITE,0.7)
 update_match()

func update_match():
 if not is_instance_valid(message) or game.mode!="match": return
 var m=game.model
 var room=m.player()
 gold_label.text=str(int(room.gold)) if room!=null else "—"
 power_label.text=str(int(room.electricity)) if room!=null else "—"
 phase_label.text="PREPARATION\n%02ds to midnight" % maxi(0,ceili(m.preparation-m.time)) if m.time<m.preparation else "NIGHT %02d:%02d\nHOLD THE DOOR" % [int(m.time)/60,int(m.time)%60]
 hunter_label.text="THE NIGHT MOTH  ·  LV %d      %d / %d" % [m.hunter.level,m.hunter.hp,m.hunter.max_hp]
 hunter_bar.max_value=m.hunter.max_hp
 hunter_bar.value=m.hunter.hp
 hunter_bar.modulate=Color(1,1,1,0.4 if m.time<m.preparation else 1.0)
 if room!=null:
  details.text="%s  /  %s" % [game.presentation.ROOM_NAMES[room.index].capitalize(),"Sleeping" if room.sleeping else "Awake"]
  var bed_cost="MAX" if room.bed_level>=Catalog.BED_COST.size() else "%dG / %dE" % [Catalog.BED_COST[room.bed_level],Catalog.BED_POWER[room.bed_level]]
  var door_cost="MAX" if room.door_level>=Catalog.DOOR_COST.size() else "%dG / %dE" % [Catalog.DOOR_COST[room.door_level],Catalog.DOOR_POWER[room.door_level]]
  bed_button.text="Bed L%d  ·  %.1f/s\n%s" % [room.bed_level+1,room.income_rate(),bed_cost]
  door_button.text="Door %d  ·  %d/%d\n%s" % [room.door_level+1,room.door_hp,room.max_hp(),door_cost]
  if room.buildings.has(game.selected_tile):
   var b=room.buildings[game.selected_tile]
   var data=Catalog.BUILDINGS[b.kind]
   actions.upgrade.text="MAX LEVEL" if b.level>=Catalog.BUILDING_MAX_LEVEL else "Upgrade  ·  %dG / %dE" % [data.gold*b.level,(data.power+3)*b.level]
  else: actions.upgrade.text="Select a building to upgrade"
 for action in actions:
  var b=actions[action]
  var reason=action_reason(action)
  b.disabled=not reason.is_empty()
  if card_visuals.has(action):
   for visual in card_visuals[action]: visual.modulate=Color(1,1,1,0.65 if b.disabled else 1.0)
  var effect=building_effect(action.trim_prefix("build:")) if action.begins_with("build:") else ""
  if action=="bed": effect="Upgrade bed income. Later levels require door progression and electricity."
  if action=="door": effect="Increase maximum HP, preserving existing damage. Later levels require bed progression."
  b.tooltip_text=effect+("\n" if effect!="" else "")+(reason if reason!="" else "Ready to purchase.")
 refresh_context()

func show_result():
 clear()
 var veil=ColorRect.new()
 veil.color=Color(0.03,0.05,0.10,0.08)
 veil.size=Vector2(1280,900)
 panel.add_child(veil)
 veil.create_tween().tween_property(veil,"color",Color(0.03,0.05,0.10,0.94),1.2)
 box(Rect2(330,160,620,606),"1b2b3d","c7aa7c")
 icon("economy" if game.model.result=="victory" else "hunter_idle",Vector2(563,180),Vector2(154,154))
 var title=label_at("DAWN SURVIVED" if game.model.result=="victory" else "THE LIGHT WENT OUT",Vector2(365,349),32,550,true)
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var m=game.model
 var r=m.player()
 var stats=label_at("%ds SURVIVED    ·    HUNTER LEVEL %d\n\n%d shots fired     /     %d damage dealt\n\n%d gold earned     ·     %d residents lost" % [m.time,m.hunter.level,r.shots if r!=null else 0,r.damage_dealt if r!=null else 0,r.income_total if r!=null else 0,m.eliminations],Vector2(385,425),18,510)
 stats.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 button("Restart",Vector2(390,655),game.start_match,235,49)
 button("Main menu",Vector2(650,655),game.return_menu,235,49)
 # Let the real hunter dissolve / resident loss read before the report arrives.
 for item in panel.get_children():
  if item==veil: continue
  item.modulate=Color(1,1,1,0)
  if item is BaseButton: item.disabled=true
  var reveal=item.create_tween()
  reveal.tween_interval(0.65)
  reveal.tween_property(item,"modulate",Color.WHITE,0.3)
  if item is BaseButton:
   reveal.tween_callback(func():
    if is_instance_valid(item): item.disabled=false)

func action_reason(action: String) -> String:
 # Read-only presentation query: never spend resources or change last_error.
 var m = game.model
 if not m.running:
  return "Paused. Resume to purchase."
 if m.result != "":
  return "The match has ended."
 var room = m.player()
 if room == null:
  return "Claim a room first."
 if not room.alive:
  return "Resident eliminated."
 var gold = 0.0
 var power = 0.0
 if action == "bed":
  if room.bed_level >= Catalog.BED_COST.size(): return "Maximum bed level."
  if room.door_level < maxi(0,room.bed_level-1): return "Requires door level %d." % room.bed_level
  gold = Catalog.BED_COST[room.bed_level]
  power = Catalog.BED_POWER[room.bed_level]
 elif action == "door":
  if room.door_hp <= 0: return "Door destroyed."
  if room.door_level >= Catalog.DOOR_COST.size(): return "Maximum door level."
  if room.bed_level < maxi(0,room.door_level-1): return "Requires bed level %d." % room.door_level
  gold = Catalog.DOOR_COST[room.door_level]
  power = Catalog.DOOR_POWER[room.door_level]
 elif action == "repair":
  if room.door_hp <= 0: return "Destroyed doors cannot be repaired."
  if room.door_hp >= room.max_hp(): return "Door already at full health."
  gold = Catalog.REPAIR_COST
 elif action.begins_with("build:"):
  if not room.sleeping: return "Sleep in your bed before building."
  if game.selected_tile < 0 or game.selected_tile > 5: return "Select a numbered floor tile in your room."
  if room.buildings.has(game.selected_tile): return "Tile occupied. Select an empty numbered tile."
  var kind = action.trim_prefix("build:")
  if kind == "heavy" and room.bed_level < 1: return "Requires bed level 2."
  gold = Catalog.BUILDINGS[kind].gold
  power = Catalog.BUILDINGS[kind].power
 elif action == "upgrade":
  if not room.buildings.has(game.selected_tile): return "Select an existing building."
  var b = room.buildings[game.selected_tile]
  if b.level >= Catalog.BUILDING_MAX_LEVEL: return "Maximum building level."
  gold = Catalog.BUILDINGS[b.kind].gold*b.level
  power = (Catalog.BUILDINGS[b.kind].power+3)*b.level
 if room.gold+0.00001 < gold: return "Need %d more gold." % ceili(gold-room.gold)
 if room.electricity+0.00001 < power: return "Need %d more electricity. Build a Dynamo." % ceili(power-room.electricity)
 return ""

func tile_description(room: RoomState) -> String:
 if not room.buildings.has(game.selected_tile):
  return "Empty floor: choose a building"
 var b = room.buildings[game.selected_tile]
 var d = Catalog.BUILDINGS[b.kind]
 if b.level >= Catalog.BUILDING_MAX_LEVEL:
  return "%s L%d · MAX" % [d.name,b.level]
 return "%s L%d" % [d.name,b.level]


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
