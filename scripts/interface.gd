class_name GameInterface
extends CanvasLayer

var game
var panel: Control
var message: Label
var details: Label
var status: Label
var actions: Dictionary={}
var bed_button: Button
var door_button: Button
var pause_button: Button
var map_button: Button
var context_open=false
var context_mode="build"
var context_box: Panel
var context_title: Label
var build_items: Array=[]
var upgrade_items: Array=[]
var bed_items: Array=[]
var door_items: Array=[]
var confirmation_items: Array=[]
var pause_items: Array=[]
var card_visuals: Dictionary={}
var selected_icon: TextureRect
var selected_details: Label
var bed_details: Label
var door_details: Label
var confirmation_details: Label
var confirmation_icon: TextureRect
var confirm_button: Button
var gold_label: Label
var power_label: Label
var phase_label: Label
var hunter_label: Label
var hunter_detail: Label
var hunter_bar: ProgressBar
var room_dock: Panel
var room_bed_summary: Button
var room_door_summary: Button
var room_selected_summary: Button
var quick_repair: Button
var guide_box: Panel
var guide_label: Label
var warning_box: Panel
var warning_label: Label
var default_font=preload("res://assets/fonts/Interface.ttf")
var display_font=preload("res://assets/fonts/CartoonDisplay.ttf")
var campaign
var items_ui
var progression: ProgressionInterface
var current_screen="menu"
var horror_layer: Control
var feedback_text=""
var feedback_until=0.0

func _init(owner_game=null): game=owner_game

func _ready():
 panel=Control.new()
 panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(panel)
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var theme=Theme.new()
 theme.default_font=default_font
 theme.default_font_size=18
 panel.theme=theme
 items_ui=preload("res://scripts/item_interface.gd").new(self)
 progression=ProgressionInterface.new(self)
 campaign=preload("res://scripts/campaign_interface.gd").new(self)
 show_menu()

func clear():
 for child in panel.get_children(): child.queue_free()
 actions.clear()
 build_items.clear()
 upgrade_items.clear()
 bed_items.clear()
 door_items.clear()
 confirmation_items.clear()
 pause_items.clear()
 card_visuals.clear()
 context_open=false
 feedback_text=""
 feedback_until=0

func style(fill: String="263E50",edge: String="607D8B",radius: int=10) -> StyleBoxFlat:
 var s=StyleBoxFlat.new()
 s.bg_color=Color(fill)
 s.border_color=Color(edge)
 s.set_border_width_all(2)
 s.set_corner_radius_all(radius)
 s.shadow_color=Color(0.04,0.09,0.14,0.4)
 s.shadow_size=4
 s.shadow_offset=Vector2(0,3)
 return s

func attach(node: Control,parent: Control=null):
 (panel if parent==null else parent).add_child(node)

func box(rect: Rect2,fill: String="263E50",edge: String="607D8B",parent: Control=null) -> Panel:
 var p=Panel.new()
 p.position=rect.position
 p.size=rect.size
 p.mouse_filter=Control.MOUSE_FILTER_IGNORE
 p.add_theme_stylebox_override("panel",style(fill,edge))
 attach(p,parent)
 return p

func label_at(text: String,pos: Vector2,size: int=18,width: float=900,heading: bool=false,parent: Control=null) -> Label:
 var l=Label.new()
 l.position=pos
 l.size=Vector2(width,30)
 l.text=text
 l.mouse_filter=Control.MOUSE_FILTER_IGNORE
 l.add_theme_font_size_override("font_size",size)
 l.add_theme_color_override("font_color",Color("EDF5F7"))
 if heading: l.add_theme_font_override("font",display_font)
 attach(l,parent)
 return l

func icon(name: String,pos: Vector2,size: Vector2,parent: Control=null) -> TextureRect:
 var t=TextureRect.new()
 t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 t.texture=game.presentation.textures[name]
 t.position=pos
 t.size=size
 t.mouse_filter=Control.MOUSE_FILTER_IGNORE
 attach(t,parent)
 return t

func button(text: String,pos: Vector2,callback: Callable,width: float=240,height: float=44,parent: Control=null) -> Button:
 var b=Button.new()
 b.text=text
 b.position=pos
 b.size=Vector2(width,height)
 b.pressed.connect(func(): game.audio_event("button"))
 b.pressed.connect(callback)
 # Disabled economic actions still explain an unaffordable attempt audibly.
 b.gui_input.connect(func(event):
  if not b.disabled or not event is InputEventMouseButton or not event.pressed or event.button_index!=MOUSE_BUTTON_LEFT: return
  var reason=""
  if b==confirm_button: reason=game.placement_reason()
  else:
   for action in actions:
    if actions[action]==b: reason=action_reason(action); break
  if reason.contains("more gold"): game.audio_event("insufficient_gold")
  elif reason.contains("more electricity"): game.audio_event("insufficient_power"))
 for state in ["normal","hover","pressed","disabled","focus"]:
  var fill="3F6675" if state=="hover" else "304D61"
  if state=="disabled": fill="263746"
  b.add_theme_stylebox_override(state,style(fill,"7BE3A1" if state in ["hover","focus"] else "607D8B",8))
 b.add_theme_color_override("font_color",Color("EDF5F7"))
 b.add_theme_color_override("font_disabled_color",Color("889CA8"))
 attach(b,parent)
 return b

func show_menu():
 clear()
 current_screen="menu"
 if game.mobile_mode:
  game.mobile_ui.show_menu(self)
  return
 label_at("SMALL ROOMS. BIG NIGHTMARES.",Vector2(72,108),18,580).modulate=Color("7BE3A1")
 label_at("NIGHTFALL\nDORM",Vector2(66,157),58,600,true)
 label_at("Claim a bed. Build your defenses.\nMake it through the night.",Vector2(72,315),20,590)
 button("Start Game",Vector2(72,405),campaign.show_stages,330,54)
 button("How to Play",Vector2(72,477),show_help,160,46)
 button("Settings",Vector2(242,477),show_settings,160,46)
 button("Exit Game",Vector2(72,539),game.request_quit,330,44)
 progression.menu_summary()
 button("Consumable inventory",Vector2(72,644),items_ui.inventory,330,36)
 if not game.profile.pending_spins.is_empty(): button("Resume Lucky Spin",Vector2(430,644),items_ui.spin,240,36)
 label_at("Original cartoon dormitory survival defense",Vector2(72,690),16,620).modulate=Color("9DB6C2")

func show_help():
 clear()
 current_screen="help"
 if game.mobile_mode:
  game.mobile_ui.show_help(self)
  return
 box(Rect2(90,65,1100,590))
 label_at("SURVIVAL HANDBOOK",Vector2(125,92),30,950,true)
 label_at("WASD / arrows: move     E: room / bed     M: map     Wheel: zoom     R: repair\n\nFind a vacant bedroom, press E inside, then E near its bed to sleep.\nGold starts while sleeping. You cannot leave the bed afterward.\n\nClick a floor pad, choose a building card, then confirm its green preview.\nRed previews cannot be purchased. Escape cancels without spending.\nClick a machine for its upgrade panel. Click the bottom bed/door summaries\nfor upgrades and repair. A Dynamo produces electricity for advanced purchases.\n\nThe hunter arrives after 30 seconds. Your turrets fire real projectiles.\nDefeat the hunter to win; your elimination loses. Doors need bed progression.\nM switches between focused play and the strategic overview.\nEscape closes cards first, then pauses. Help/G toggles the short guide.",Vector2(125,156),19,1020)
 button("Back",Vector2(125,585),show_menu,180,46)

func show_settings():
 clear()
 current_screen="settings"
 if game.mobile_mode:
  game.mobile_ui.show_settings(self)
  return
 game.audio_event("menu")
 box(Rect2(330,40,620,640))
 label_at("SETTINGS",Vector2(370,70),30,540,true)
 for i in range(3):
  var key=["music","effects","ambient"][i]
  label_at(key.capitalize()+" volume",Vector2(370,125+i*84),20,520)
  var slider=HSlider.new()
  slider.name=key+"_volume"
  slider.position=Vector2(370,164+i*84)
  slider.size=Vector2(530,28)
  slider.step=0.01
  slider.min_value=0
  slider.max_value=1
  slider.value=game.profile.settings[key]
  var id=key
  slider.value_changed.connect(func(value): game.change_setting(id,value))
  panel.add_child(slider)
 var options=["muted","fullscreen","tutorial"]
 var names=["Mute all audio","Fullscreen","First-night tutorial"]
 for i in range(3):
  var toggle=CheckButton.new()
  toggle.name=options[i]
  toggle.text=names[i]
  toggle.position=Vector2(370,395+i*54)
  toggle.button_pressed=game.profile.settings[options[i]]
  var id=options[i]
  toggle.toggled.connect(func(value): game.change_setting(id,value))
  panel.add_child(toggle)
 button("Back",Vector2(370,590),show_menu,200,46)
 if game.profile.warning!="":
  var text=label_at(game.profile.warning,Vector2(590,585),16,310)
  text.clip_text=true
  text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  text.size=Vector2(310,70)

func show_match():
 clear()
 current_screen="match"
 box(Rect2(18,12,1244,64),"203747","607D8B")
 label_at("NIGHTFALL DORM",Vector2(34,27),23,260,true)
 icon("coin",Vector2(280,25),Vector2(32,32))
 gold_label=label_at("—",Vector2(320,24),25,98)
 icon("power",Vector2(429,23),Vector2(30,36))
 power_label=label_at("—",Vector2(468,24),25,98)
 phase_label=label_at("",Vector2(576,22),18,120)
 hunter_label=label_at("",Vector2(704,21),18,290)
 hunter_bar=ProgressBar.new()
 hunter_bar.position=Vector2(704,46)
 hunter_bar.size=Vector2(286,8)
 hunter_bar.show_percentage=false
 hunter_bar.add_theme_font_size_override("font_size",1)
 hunter_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
 hunter_bar.add_theme_stylebox_override("background",style("182B3A","607D8B",4))
 hunter_bar.add_theme_stylebox_override("fill",style("F05467","F05467",4))
 hunter_bar.size=Vector2(286,8)
 panel.add_child(hunter_bar)
 hunter_bar.set_deferred("size",Vector2(286,8))
 hunter_detail=label_at("",Vector2(704,58),11,290)
 map_button=button("Map",Vector2(1010,24),game.toggle_map,78,36)
 map_button.tooltip_text="Strategic map / focused room [M]"
 button("Help",Vector2(1098,24),game.toggle_guide,62,36)
 pause_button=button("Ⅱ",Vector2(1174,24),game.toggle_pause,62,36)
 pause_button.tooltip_text="Pause / resume [Esc]"
 guide_box=box(Rect2(20,92,334,112),"294957","7BE3A1")
 guide_label=label_at("",Vector2(34,105),18,306)
 guide_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 guide_label.size.y=90
 warning_box=box(Rect2(390,88,500,48),"583344","F05467")
 warning_label=label_at("",Vector2(402,98),18,476,true)
 warning_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 warning_box.visible=false
 warning_label.visible=false
 room_dock=box(Rect2(20,638,1240,66),"203747","607D8B")
 details=label_at("Choose a room",Vector2(35,653),18,205,true)
 room_bed_summary=button("Bed",Vector2(250,649),func(): open_room_panel("bed"),226,44)
 room_door_summary=button("Door",Vector2(490,649),func(): open_room_panel("door"),266,44)
 room_selected_summary=button("Build pads",Vector2(770,649),open_context,263,44)
 quick_repair=button("Repair",Vector2(1047,649),func(): purchase(game.model.repair_door()),196,44)
 quick_repair.tooltip_text="Repair your door quickly [R]"
 # Side inspector lies beyond the focused bedroom's playable bounds.
 context_box=box(Rect2(900,246,364,382),"263E50","7F9DAA")
 context_box.mouse_filter=Control.MOUSE_FILTER_STOP
 context_title=label_at("BUILD A DEFENSE",Vector2(14,12),18,304,true,context_box)
 button("×",Vector2(326,8),game.cancel_placement,28,28,context_box)
 var descs={"turret":"Auto fire","heavy":"Arc damage","generator":"Makes power","repair":"Mends door","economy":"More income","enhancer":"Boost guns"}
 var n=0
 for kind in Catalog.BUILDINGS:
  var id=kind
  var data=Catalog.BUILDINGS[kind]
  var at=Vector2(12+(n%3)*114,42+(n/3)*152)
  var b=button("",at,func(): game.begin_placement(id),108,142,context_box)
  var art=icon(kind,at+Vector2(29,5),Vector2(50,48),context_box)
  var display_names={"turret":"Needle\nturret","heavy":"Arc\nturret","generator":"Dynamo","repair":"Repair\nstation","economy":"Dream\namplifier","enhancer":"Target\nrelay"}
  var name=label_at(display_names[kind],at+Vector2(3,53),16,102,false,context_box)
  name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  name.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  name.size=Vector2(102,38)
  var cost=label_at("%d G" % data.gold+("+%d E" % data.power if data.power>0 else ""),at+Vector2(3,94),16,102,false,context_box)
  cost.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  cost.modulate=Color("FFD27A")
  var effect=label_at(descs[kind],at+Vector2(3,118),16,102,false,context_box)
  effect.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  actions["build:"+kind]=b
  build_items.append_array([b,art,name,cost,effect])
  card_visuals["build:"+kind]=[art,name,cost,effect]
  n+=1
 selected_icon=icon("turret",Vector2(14,52),Vector2(80,86),context_box)
 selected_details=label_at("",Vector2(104,50),16,244,false,context_box)
 selected_details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 selected_details.size.y=126
 actions.upgrade=button("Upgrade",Vector2(14,190),func(): purchase(game.model.upgrade_building(game.selected_tile)),336,44,context_box)
 actions.sell=button("Sell · 50% refund",Vector2(14,240),sell_selected,336,44,context_box)
 upgrade_items=[selected_icon,selected_details,actions.upgrade,actions.sell]
 var bed_art=icon("bed",Vector2(14,52),Vector2(80,108),context_box)
 bed_details=label_at("",Vector2(104,50),18,244,false,context_box)
 bed_details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 bed_details.size.y=128
 bed_button=button("Upgrade bed",Vector2(14,190),func(): purchase(game.model.upgrade_bed()),336,44,context_box)
 actions.bed=bed_button
 bed_items=[bed_art,bed_details,bed_button]
 var door_art=icon("door",Vector2(14,52),Vector2(80,108),context_box)
 door_details=label_at("",Vector2(104,50),18,244,false,context_box)
 door_details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 door_details.size.y=138
 door_button=button("Upgrade door",Vector2(14,198),func(): purchase(game.model.upgrade_door()),336,40,context_box)
 actions.door=door_button
 actions.repair=button("Repair",Vector2(14,246),func(): purchase(game.model.repair_door()),336,40,context_box)
 door_items=[door_art,door_details,door_button,actions.repair]
 confirmation_icon=icon("turret",Vector2(14,54),Vector2(80,86),context_box)
 confirmation_details=label_at("",Vector2(104,52),18,244,false,context_box)
 confirmation_details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 confirmation_details.size.y=120
 confirm_button=button("Confirm placement",Vector2(14,180),func(): game.confirm_placement(),336,40,context_box)
 var cancel=button("Cancel · no charge",Vector2(14,228),game.cancel_placement,336,30,context_box)
 confirmation_items=[confirmation_icon,confirmation_details,confirm_button,cancel]
 message=guide_label
 status=phase_label
 close_context()
 if game.mobile_mode: game.mobile_ui.match_layout(self)
 update_match()

 horror_layer=Control.new()
 horror_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
 horror_layer.size=Vector2(1280,720)
 panel.add_child(horror_layer)
 horror_layer.draw.connect(func(): game.horror.render_notifications(horror_layer))

 items_ui.create_hotbar()

func open_context():
 game.cancel_placement()
 game.full_map=false
 game.focus_camera(true)
 context_open=true
 var room=game.model.player()
 context_mode="upgrade" if room!=null and room.buildings.has(game.selected_tile) else "build"
 refresh_context()

func open_room_panel(kind: String):
 if game.model.player()==null: return
 game.cancel_placement()
 game.full_map=false
 game.focus_camera(true)
 context_open=true
 context_mode=kind
 refresh_context()

func open_confirmation():
 context_open=true
 context_mode="confirm"
 refresh_context()

func close_context():
 game.pending_build=""
 game.placement_on_tile=false
 context_open=false
 if is_instance_valid(context_box): context_box.visible=false
 for node in build_items+upgrade_items+bed_items+door_items+confirmation_items: node.visible=false

func refresh_context():
 if not context_open or game.model.player()==null: close_context(); return
 var room=game.model.player()
 var heights={"build":382,"upgrade":300,"bed":250,"door":300,"confirm":272}
 if not game.mobile_mode:
  context_box.position=Vector2(900,628-heights[context_mode])
  context_box.size=Vector2(364,heights[context_mode])
 context_box.visible=true
 for group in {"build":build_items,"upgrade":upgrade_items,"bed":bed_items,"door":door_items,"confirm":confirmation_items}:
  var list={"build":build_items,"upgrade":upgrade_items,"bed":bed_items,"door":door_items,"confirm":confirmation_items}[group]
  for node in list: node.visible=group==context_mode
 if context_mode=="build": context_title.text="BUILD A DEFENSE"
 elif context_mode=="upgrade" and room.buildings.has(game.selected_tile):
  var b=room.buildings[game.selected_tile]
  selected_icon.texture=game.presentation.cartoon[game.presentation.building_key(b.kind,b.level)]
  context_title.text=Catalog.BUILDINGS[b.kind].name.to_upper()
  selected_details.text=selected_stats(b)+"\n"+action_reason("upgrade")
 elif context_mode=="bed":
  context_title.text="BED LEVEL %d / 5" % (room.bed_level+1)
  bed_details.text="Income %.1f gold/s\nNext: %s\n%s" % [room.income_rate(),"MAX" if room.bed_level>=4 else str(Catalog.BED_INCOME[room.bed_level+1])+" gold/s",action_reason("bed")]
 elif context_mode=="door":
  context_title.text="DOOR LEVEL %d / 5" % (room.door_level+1)
  door_details.text="%d / %d HP\nNext: %s\n%s" % [room.door_hp,room.max_hp(),"MAX" if room.door_level>=4 else str(Catalog.DOOR_HP[room.door_level+1]*room.door_multiplier)+" HP",action_reason("door")]
 elif context_mode=="confirm" and game.pending_build!="":
  var data=Catalog.BUILDINGS[game.pending_build]
  context_title.text="PLACE "+data.name.to_upper()
  confirmation_icon.texture=game.presentation.textures[game.pending_build]
  var reason=game.placement_reason()
  confirmation_details.text="%d G / %d E\n%s" % [data.gold,data.power,reason if reason!="" else "Pad locked. Confirm to buy, or click another pad."]
  confirm_button.disabled=reason!=""
 if game.mobile_mode: game.mobile_ui.context(self)

func selected_stats(b) -> String:
 var d=Catalog.BUILDINGS[b.kind]
 if b.kind in ["turret","heavy"]:
  return "Level %d / 4\nDamage %.0f\nRange %.0f\nEvery %.2fs" % [b.level,d.damage*b.level*(game.model.player().turret_multiplier if game.model.player()!=null else 1),d.range,d.interval/(1+(b.level-1)*0.12)]
 if b.kind=="generator": return "Level %d / 4\n%.1f electricity/s" % [b.level,d.rate*b.level*(game.model.player().power_multiplier if game.model.player()!=null else 1)]
 if b.kind=="repair": return "Level %d / 4\n%.1f door HP/s" % [b.level,d.rate*b.level]
 return "Level %d / 4\n+%d%% %s" % [b.level,d.rate*b.level*100,"income" if b.kind=="economy" else "turret damage"]

func show_pause(open: bool):
 game.pending_build=""
 close_context()
 for node in pause_items:
  if is_instance_valid(node): node.queue_free()
 pause_items.clear()
 if not open: return
 if game.mobile_mode:
  game.mobile_ui.show_pause(self)
  return
 var veil=ColorRect.new()
 veil.size=Vector2(1280,720)
 veil.color=Color(0.05,0.1,0.16,0.75)
 panel.add_child(veil)
 var bg=box(Rect2(420,180,440,350))
 var title=label_at("NIGHTWATCH PAUSED",Vector2(450,218),24,390,true)
 var subtitle=label_at("Your room can wait a moment.",Vector2(450,266),18,390)
 var resume=button("Resume",Vector2(450,329),game.toggle_pause,380,48)
 var menu=button("Return to main menu",Vector2(450,397),game.return_menu,380,48)
 pause_items=[veil,bg,title,subtitle,resume,menu]

func sell_selected():
 var success=game.model.sell_building(game.selected_tile)
 if success: close_context()
 purchase(success)
 if success: feedback_text="Building sold · 50% gold and electricity refunded."

func purchase(success: bool):
 var reason=game.model.purchase_error() if not success else ""
 var cue="purchase" if success else "insufficient_gold" if reason.contains("more gold") else "insufficient_power" if reason.contains("more electricity") else "failure"
 game.audio_event(cue)
 feedback_text="Defense improved!" if success else game.model.purchase_error()
 feedback_until=game.presentation.clock+2
 update_match()

func tutorial_text() -> String:
 if game.mobile_mode: return game.mobile_ui.tutorial_text()
 var m=game.model
 var room=m.player()
 if room==null: return "1 / 5  FIND A ROOM\nMove with WASD. Press E inside a vacant bedroom."
 if not room.sleeping: return "2 / 5  OCCUPY THE BED\nApproach your bed and press E. Gold starts while sleeping."
 if room.income_total<8: return "3 / 5  EARN GOLD\nYour bed earns gold automatically while you sleep."
 if room.bed_level==0 and room.door_level==0: return "4 / 5  UPGRADE\nClick the bed or door summary below."
 for b in room.buildings.values():
  if b.kind in ["turret","heavy"]: return "NIGHTWATCH READY\nSave for power and stronger defenses. Help/G hides this guide."
 return "5 / 5  FIRST DEFENSE\nClick a green floor pad, choose a turret and confirm."

func update_match():
 if not is_instance_valid(gold_label) or game.mode!="match": return
 var m=game.model
 var room=m.player()
 gold_label.text=str(int(room.gold)) if room!=null else "—"
 power_label.text=str(int(room.electricity)) if room!=null else "—"
 phase_label.text="%02d:%02d\n%s" % [int(m.time)/60,int(m.time)%60,"PREP %ds" % maxi(0,ceili(m.preparation-m.time)) if m.time<m.preparation else "SURVIVE"]
 hunter_label.text=("REAPER · %d/%d" % [m.hunter.hp,m.hunter.max_hp]) if m.hunter.transformed else "HUNTER L%d  ·  %d/%d" % [m.hunter.level,m.hunter.hp,m.hunter.max_hp]
 hunter_detail.text="%d ATK · %.2fs%s" % [m.hunter.damage,m.hunter.interval," · WINDUP!" if m.hunter.charged_ready else ""]
 if m.hunter.state==HunterState.State.TRANSFORM: hunter_detail.text="AWAKENING · %.1fs · KEEP FIRING" % m.hunter.transform_remaining
 elif m.hunter.boss_attack!="": hunter_detail.text="%s · %.1fs" % [BossCatalog.ATTACKS[m.hunter.boss_attack].name,m.hunter.windup_remaining]
 elif m.hunter.surge_remaining>0: hunter_detail.text="SURGE · %.1fs · REAPER EXPOSED +20%%" % m.hunter.surge_remaining
 hunter_detail.modulate=Color("FF7777") if m.difficulty=="hell" else Color("FFD27A")
 hunter_bar.max_value=m.hunter.max_hp
 hunter_bar.value=m.hunter.hp
 map_button.text="Focus" if game.full_map else "Map"
 guide_box.visible=((game.tutorial_enabled and not game.full_map) or game.presentation.clock<feedback_until) and not (game.model.map_id!="legacy" and context_open)
 guide_label.visible=guide_box.visible
 if guide_label.visible: guide_label.text=feedback_text if game.presentation.clock<feedback_until else tutorial_text()
 var threat=room!=null and m.hunter.target==room.index and m.hunter.state==HunterState.State.ATTACK
 warning_box.visible=threat or game.level_warning_time>0
 warning_label.visible=warning_box.visible
 if not threat and game.level_warning_time>0: warning_label.text="THE HUNTER GROWS STRONGER · LEVEL %d" % m.hunter.level
 if threat:
  warning_label.text="DOOR %d/%d · UNDER ATTACK" % [room.door_hp,room.max_hp()]
  if m.hunter.charged_ready: warning_label.text="HEAVY STRIKE %.1fs · REPAIR / UPGRADE" % m.hunter.windup_remaining
  elif room.repair_factor<0.99: warning_label.text="DOOR %d/%d · REPAIRS %d%%" % [room.door_hp,room.max_hp(),roundi(room.repair_factor*100)]
  if m.hunter.boss_attack!="":
   warning_label.text="%s %.1fs · REPAIR NOW" % [BossCatalog.ATTACKS[m.hunter.boss_attack].name,m.hunter.windup_remaining]
  elif m.hunter.shadow_active(room.index): warning_label.text="TURRETS SILENCED %.1fs · KEEP REPAIRING" % m.hunter.surge_remaining
  warning_box.modulate.a=0.75+game.danger_time*0.35
 details.text="Choose a room" if room==null else "%s · %s" % [game.presentation.ROOM_NAMES[room.index].capitalize(),"sleeping" if room.sleeping else "awake"]
 for control in [room_bed_summary,room_door_summary,room_selected_summary]: control.disabled=room==null
 if room!=null:
  room_bed_summary.text="Bed L%d  ·  %.1f G/s" % [room.bed_level+1,room.income_rate()]
  room_door_summary.text="Door L%d  ·  %d/%d" % [room.door_level+1,room.door_hp,room.max_hp()]
  room_selected_summary.text=Catalog.BUILDINGS[room.buildings[game.selected_tile].kind].name if room.buildings.has(game.selected_tile) else "Build on a floor pad"
  var bed_cost="MAX" if room.bed_level>=4 else "%dG / %dE" % [Catalog.BED_COST[room.bed_level],Catalog.BED_POWER[room.bed_level]]
  var door_cost="MAX" if room.door_level>=4 else "%dG / %dE" % [Catalog.DOOR_COST[room.door_level],Catalog.DOOR_POWER[room.door_level]]
  bed_button.text="Upgrade bed  ·  "+bed_cost
  door_button.text="Upgrade door  ·  "+door_cost
  if room.buildings.has(game.selected_tile):
   var b=room.buildings[game.selected_tile]
   var d=Catalog.BUILDINGS[b.kind]
   var refund=room.building_refund(game.selected_tile)
   actions.sell.text="Sell · +%s G / +%s E (50%%)" % [str(refund.x),str(refund.y)]
   actions.upgrade.text="MAX LEVEL" if b.level>=4 else "Upgrade  ·  %dG / %dE" % [d.gold*b.level,(d.power+3)*b.level]
  else: actions.upgrade.text="Select a building to upgrade"
 actions.repair.text="Repair  ·  %d gold" % Catalog.REPAIR_COST
 quick_repair.text="Repair %d G  [R]" % Catalog.REPAIR_COST
 quick_repair.disabled=action_reason("repair")!=""
 for action in actions:
  var b=actions[action]
  var reason=action_reason(action)
  b.disabled=reason!=""
  if card_visuals.has(action):
   for node in card_visuals[action]: node.modulate.a=0.55 if b.disabled else 1.0
  if game.mobile_mode and action.begins_with("build:"): b.disabled=false
  b.tooltip_text=(building_effect(action.trim_prefix("build:"))+"\n" if action.begins_with("build:") else "")+(reason if reason!="" else "Ready")
 refresh_context()
 if game.mobile_mode: game.mobile_ui.update_match(self)

func show_result():
 clear()
 var veil=ColorRect.new()
 veil.size=Vector2(1280,720)
 veil.color=Color(0.04,0.08,0.13,0.1)
 panel.add_child(veil)
 veil.create_tween().tween_property(veil,"color",Color(0.04,0.08,0.13,0.93),1.2)
 box(Rect2(340,100,600,520),"263E50","7BE3A1" if game.model.result=="victory" else "F05467")
 icon("economy" if game.model.result=="victory" else "hunter_idle",Vector2(585,118),Vector2(110,110))
 var title=label_at(("STAGE CLEARED" if game.model.result=="victory" else "STAGE FAILED") if game.campaign_mode else ("YOU SURVIVED!" if game.model.result=="victory" else "LIGHTS OUT"),Vector2(375,243),34,530,true)
 if game.model.result=="victory" and game.model.hunter.transformed:
  title.text="REAPER DEFEATED"
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 if game.campaign_mode:
  var stage=StageCatalog.stage(game.model.stage_id)
  if not stage.is_empty():
   var caption=label_at("Stage %d · %s · %s" % [stage.number,stage.title,RankCatalog.DIFFICULTIES[game.model.difficulty].name],Vector2(390,284),16,500)
   caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var m=game.model
 var r=m.player()
 var l=label_at("%ds survived  ·  Hunter level %d\n%d shots  ·  %d damage\n%d gold earned  ·  %d residents lost" % [m.time,m.hunter.level,r.shots if r!=null else 0,r.damage_dealt if r!=null else 0,r.income_total if r!=null else 0,m.eliminations],Vector2(390,312),20,500)
 l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 progression.result_summary()
 if items_ui.result_gate(): pass
 elif game.campaign_mode: campaign.result_actions()
 else:
  button("Loadout",Vector2(390,580),progression.show_loadout,235,32)
  button("Restart",Vector2(390,530),game.start_match,235,48)
  button("Main menu",Vector2(650,530),game.return_menu,235,48)
 if game.mobile_mode: game.mobile_ui.result_layout(self)
 for item in panel.get_children():
  if item==veil: continue
  item.modulate.a=0
  if item is BaseButton: item.disabled=true
  var t=item.create_tween()
  t.tween_interval(0.65)
  t.tween_property(item,"modulate",Color.WHITE,0.3)
  if item is BaseButton: t.tween_callback(func():
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
  if game.selected_tile < 0 or game.selected_tile >= room.tile_count(): return "Select a numbered floor tile in your room."
  if room.buildings.has(game.selected_tile): return "Tile occupied. Select an empty numbered tile."
  var kind = action.trim_prefix("build:")
  if kind == "heavy" and room.bed_level < 1: return "Requires bed level 2."
  gold = Catalog.BUILDINGS[kind].gold
  power = Catalog.BUILDINGS[kind].power
 elif action == "sell":
  if not room.buildings.has(game.selected_tile): return "Select an existing building."
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

func touch_notice(text: String):
 feedback_text=text
 feedback_until=game.presentation.clock+3
 update_match()
