class_name GameInterface
extends CanvasLayer

var game
var menu_start: Button
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
var horror_font=preload("res://assets/fonts/GrenzeGotisch-SemiBold.ttf")
var campaign
var shop
var teammates: TeammateInterface
var replay_ui: ReplayInterface
var items_ui
var progression: ProgressionInterface
var help_open=false
var audio_tab="Music"
var audio_group="Weapons"
var current_screen="menu"
var horror_layer: Control
var feedback_text=""
var feedback_until=0.0
var specialization_items: Array=[]
var specialization_structure=""
var expansion_ui
var bottom_context: BottomContextPanel
var branch_confirm: Button
var pending_branch=""

func _init(owner_game=null): game=owner_game

func _ready():
 panel=Control.new()
 panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(panel)
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var theme=GothicTheme.make_theme(default_font)
 panel.theme=theme
 items_ui=preload("res://scripts/item_interface.gd").new(self)
 shop=preload("res://scripts/cash_shop.gd").new(self)
 progression=ProgressionInterface.new(self)
 campaign=preload("res://scripts/campaign_interface.gd").new(self)
 replay_ui=ReplayInterface.new(self)
 teammates=TeammateInterface.new(self)
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
 specialization_items.clear();specialization_structure=""
 context_open=false;help_open=false;expansion_ui=null;bottom_context=null;branch_confirm=null;pending_branch=""
 feedback_text=""
 feedback_until=0

func style(fill: String="263E50",edge: String="607D8B",radius: int=10) -> StyleBox:
 return GothicTheme.surface(fill,edge)

func meter_style(color: Color) -> StyleBoxFlat:
 var s=StyleBoxFlat.new();s.bg_color=color;s.set_corner_radius_all(3)
 return s
func resource_text(value: float) -> String:
 if value>=1000000:return "%.1fM" % (value/1000000)
 if value>=100000:return "%.1fK" % (value/1000)
 return str(int(value))

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
 if heading:
  l.add_theme_font_override("font",horror_font if size>=20 else default_font)
  l.add_theme_color_override("font_color",Color("DDD3B9"))
 l.add_theme_color_override("font_shadow_color",Color("080B0F"))
 l.add_theme_constant_override("shadow_offset_y",1)
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

func premium_icon(id: String,pos: Vector2,size: Vector2,parent: Control=null) -> TextureRect:
 var t=TextureRect.new();t.texture=PremiumButton.texture(id)
 t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 t.position=pos;t.size=size;t.mouse_filter=Control.MOUSE_FILTER_IGNORE
 attach(t,parent)
 return t

func button(text: String,pos: Vector2,callback: Callable,width: float=240,height: float=44,parent: Control=null) -> Button:
 var b=Button.new()
 b.text=text
 b.position=pos
 b.size=Vector2(width,height)
 b.pressed.connect(func(): game.audio_event("button"))
 b.pressed.connect(func():
  if game.onboarding!=null and game.onboarding.is_welcome_open():return
  if game.cancelled_pointer:return
  if b.get_parent()==context_box and bottom_context!=null and (not context_open or bottom_context.is_transitioning()):return
  if bool(b.get_meta("ignore_double_release",false)):
   b.set_meta("ignore_double_release",false);return
  callback.call())
 b.gui_input.connect(func(event):
  if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:b.set_meta("ignore_double_release",event.double_click))
 b.mouse_entered.connect(func():
  if game.audio_system.streams.has("ui_hover"):game.audio_event("ui_hover"))
 var primary=text.begins_with("Start") or text.begins_with("Confirm") or text.begins_with("Continue") or text.begins_with("Claim reward") or text.begins_with("Buy")
 b.set_meta("visual_role","primary" if primary else "secondary")
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
  b.add_theme_stylebox_override(state,GothicTheme.surface(fill,"7BE3A1" if state in ["hover","focus"] else "938876",("primary_" if primary else "button_")+state))
 b.add_theme_color_override("font_color",Color("EDF5F7"))
 b.add_theme_color_override("font_disabled_color",Color("889CA8"))
 attach(b,parent)
 PremiumButton.decorate(b,game.profile.settings.get("reduced_effects",false))
 return b

func show_menu():
 game.audio_system.stop_preview()
 clear()
 current_screen="menu"
 if game.mobile_mode:
  game.mobile_ui.show_menu(self)
  return
 MainMenu.new(self).create()

func show_help():
 clear()
 current_screen="help"
 if game.mobile_mode:
  game.mobile_ui.show_help(self)
  return
 box(Rect2(90,65,1100,590))
 label_at("SURVIVAL HANDBOOK",Vector2(125,92),30,950,true)
 label_at("WASD / arrows: move     E: room / bed     M: map     Wheel: zoom     R: repair\n\nFind a vacant bedroom, press E inside, then E near its bed to sleep.\nGold starts while sleeping. You cannot leave the bed afterward.\n\nClick a floor pad, then BUILD on a machine card in the bottom panel.\nDisabled cards explain missing resources. Escape closes without spending.\nClick a machine for its upgrade panel. Click the bottom bed/door summaries\nfor upgrades and repair. A Dynamo produces electricity for advanced purchases.\n\nThe hunter arrives after 30 seconds. Your turrets fire real projectiles.\nDefeat the hunter to win; your elimination loses. Doors need bed progression.\nM switches between focused play and the strategic overview.\nEscape closes cards first, then pauses. Help/G toggles the short guide.",Vector2(125,156),19,1020)
 button("Back",Vector2(125,585),show_menu,180,46)

func show_settings():
 clear()
 current_screen="settings"
 if game.mobile_mode:
  game.mobile_ui.show_settings(self)
  return
 game.audio_event("menu")
 box(Rect2(110,35,1060,650))
 label_at("SOUND & CINEMATIC QUALITY",Vector2(145,62),30,990,true)
 for i in range(3):
  var key=["music","effects","ambient"][i]
  label_at(key.capitalize()+" volume",Vector2(150,130+i*94),20,420)
  var slider=HSlider.new();slider.name=key+"_volume";slider.position=Vector2(150,167+i*94);slider.size=Vector2(420,28);slider.step=.01;slider.min_value=0;slider.max_value=1;slider.value=game.profile.settings[key]
  var id=key;slider.value_changed.connect(func(value):game.change_setting(id,value));panel.add_child(slider)
 var quality=OptionButton.new();quality.name="graphics_quality";quality.position=Vector2(640,130);quality.size=Vector2(470,42)
 for text in ["LOW · essential effects","MEDIUM · balanced cinema","HIGH · full atmosphere"]:quality.add_item(text)
 quality.select(["low","medium","high"].find(game.profile.settings.get("graphics_quality","medium")))
 quality.item_selected.connect(func(index):game.change_setting("graphics_quality",["low","medium","high"][index]));panel.add_child(quality)
 var options=["reduced_motion","reduced_flashes","reduced_effects","muted","fullscreen","tutorial"]
 var names=["Reduce motion / camera impulse","Reduce flashes / light response","Reduced effects (overrides quality)","Mute all audio","Fullscreen","First-night tutorial"]
 for i in range(options.size()):
  var toggle=CheckButton.new();toggle.name=options[i];toggle.text=names[i];toggle.position=Vector2(640,190+i*50);toggle.size.x=470;toggle.button_pressed=game.profile.settings.get(options[i],false)
  var id=options[i];toggle.toggled.connect(func(value):game.change_setting(id,value));panel.add_child(toggle)
 label_at("All quality levels preserve danger warnings and timing.\nPreferences affect presentation only.",Vector2(150,449),16,450)
 button("Back",Vector2(150,592),show_menu,420,46)
 button("Audio listening room",Vector2(640,592),show_audio_test,470,46)
 if game.profile.warning!="":label_at(game.profile.warning,Vector2(150,540),14,960)

func show_match():
 clear()
 current_screen="match"
 box(Rect2(18,12,1244,64),"203747","607D8B")
 var brand=label_at("NIGHTFALL DORM",Vector2(34,23),26,240,true)
 brand.add_theme_font_override("font",horror_font)
 if game.model.run_kind!="campaign":
  brand.text="WAVE %d · ENDLESS" % game.model.endless.wave if game.model.run_kind=="endless" else "PRACTICE ROOM" if game.model.run_kind=="practice" else "CODE CHALLENGE"
  brand.add_theme_font_size_override("font_size",23);brand.position.y=17;brand.size.y=36
  replay_ui.wave_label=label_at("TEMPORARY · PAUSE TO RESET" if game.model.run_kind=="practice" else "NORMALIZED · FIXED 30Hz",Vector2(34,58),9,242)
 if game.model.run_kind=="endless":
  replay_ui.omen_icon=premium_icon("hell",Vector2(24,50),Vector2(15,15));replay_ui.omen_icon.visible=false
 if CosmeticPresentation.equipped(game,"badge"):premium_icon("reaper_crest",Vector2(242,27),Vector2(27,27))
 premium_icon("gold",Vector2(280,25),Vector2(32,32))
 label_at("GOLD",Vector2(320,14),11,126,true)
 gold_label=label_at("—",Vector2(320,32),22,126)
 gold_label.modulate=Color("DFC48B")
 premium_icon("power",Vector2(429,23),Vector2(30,36))
 label_at("ELECTRICITY",Vector2(468,14),11,106,true)
 power_label=label_at("—",Vector2(468,32),22,106)
 power_label.modulate=Color("8CD6DA")
 phase_label=label_at("",Vector2(576,22),18,120)
 hunter_label=label_at("",Vector2(704,21),18,290)
 hunter_label.mouse_filter=Control.MOUSE_FILTER_PASS
 hunter_bar=ProgressBar.new()
 hunter_bar.position=Vector2(704,46)
 hunter_bar.size=Vector2(286,8)
 hunter_bar.show_percentage=false
 hunter_bar.add_theme_font_size_override("font_size",1)
 hunter_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
 hunter_bar.add_theme_stylebox_override("background",meter_style(Color("15191F")))
 hunter_bar.add_theme_stylebox_override("fill",meter_style(Color("B65D67")))
 hunter_bar.size=Vector2(286,8)
 panel.add_child(hunter_bar)
 hunter_bar.set_deferred("size",Vector2(286,8))
 hunter_detail=label_at("",Vector2(704,58),11,290)
 map_button=button("Map",Vector2(1010,24),game.toggle_map,78,36)
 map_button.tooltip_text="Strategic map / focused room [M]"
 button("Help",Vector2(1098,24),game.toggle_guide,62,36)
 pause_button=button("Wave" if replay_ui.preparing else "Ⅱ",Vector2(1174,24),replay_ui.show_intermission if replay_ui.preparing else game.toggle_pause,62,36)
 pause_button.tooltip_text="Pause / resume [Esc]"
 guide_box=box(Rect2(20,92,334,112),"294957","7BE3A1")
 guide_label=label_at("",Vector2(34,153),16,306)
 guide_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 guide_label.size.y=160
 warning_box=box(Rect2(390,88,500,48),"583344","F05467")
 warning_label=label_at("",Vector2(402,98),18,476,true)
 warning_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 warning_box.visible=false
 warning_label.visible=false
 room_dock=box(Rect2(20,638,1240,66),"203747","607D8B")
 details=label_at("Choose a room",Vector2(35,653),18,205,true)
 room_bed_summary=button("Bed",Vector2(250,649),func(): open_room_panel("bed"),226,44)
 room_door_summary=button("Door",Vector2(490,649),func(): open_room_panel("door"),266,44)
 room_selected_summary=button("Build",Vector2(770,649),open_build_menu,263,44)
 quick_repair=button("Repair",Vector2(1047,649),func(): purchase(game.model.repair_door()),196,44)
 quick_repair.tooltip_text="Repair your door quickly [R]"
 # Side inspector lies beyond the focused bedroom's playable bounds.
 context_box=box(Rect2(900,246,364,382),"263E50","7F9DAA")
 context_box.mouse_filter=Control.MOUSE_FILTER_STOP
 context_title=label_at("BUILD A DEFENSE",Vector2(14,12),18,304,true,context_box)
 button("×",Vector2(326,8),game.cancel_placement,28,28,context_box)
 var descs={"barrier":"Reflects magic","plasma":"Stores magic","antenna":"Magic shield","turret":"Auto fire","heavy":"Arc damage","generator":"Makes power","repair":"Mends door","economy":"More income","enhancer":"Boost guns","flame":"Burn / DoT","frost":"Slow enemies","shock":"Charged strike","auto_repair":"Paid repairs","shield":"Paid barrier","decoy":"Timed legal lure"}
 var n=0
 for kind in Catalog.BUILDINGS:
  var id=kind
  var data=Catalog.BUILDINGS[kind]
  var at=Vector2(12+(n%3)*114,42+(n/3)*152)
  var b=button("",at,func(): game.begin_placement(id) if game.mobile_mode else game.build_selected(id),108,142,context_box)
  var art=icon(kind,at+Vector2(29,5),Vector2(50,48),context_box)
  var display_names={"turret":"Needle\nturret","heavy":"Arc\nturret","generator":"Dynamo","repair":"Repair\nstation","economy":"Dream\namplifier","enhancer":"Target\nrelay"}
  var name=label_at(display_names.get(kind,data.name),at+Vector2(3,53),16,102,false,context_box)
  name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  name.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  name.size=Vector2(102,38)
  var cost=label_at("%d G" % data.gold+("+%d E" % data.power if data.power>0 else ""),at+Vector2(3,94),16,102,false,context_box)
  cost.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  cost.modulate=Color("FFD27A")
  var effect=label_at(descs.get(kind,data.get("role","Defense")),at+Vector2(3,118),16,102,false,context_box)
  effect.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  actions["build:"+kind]=b
  build_items.append_array([b,art,name,cost,effect])
  card_visuals["build:"+kind]=[art,name,cost,effect]
  n+=1
 selected_icon=icon("turret",Vector2(14,52),Vector2(80,86),context_box)
 selected_details=label_at("",Vector2(104,50),16,244,false,context_box)
 selected_details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 selected_details.size.y=126
 actions.upgrade=button("Upgrade",Vector2(14,190),upgrade_selected,336,44,context_box)
 actions.sell=button("Sell · 50% refund",Vector2(14,240),sell_selected,336,44,context_box)
 actions.sell.add_theme_font_size_override("font_size",16)
 actions.sell.add_theme_constant_override("icon_max_width",22)
 actions.sell.add_theme_constant_override("h_separation",6)
 upgrade_items=[selected_icon,selected_details,actions.upgrade,actions.sell]
 var branch_hint=label_at("ONE PERMANENT CHOICE · advances to level 5",Vector2(14,43),13,336,false,context_box)
 specialization_items.append(branch_hint)
 for i in range(2):
  var choice=i
  var branch_button=button("",Vector2(14,76+i*105),func():
   var room=game.model.player()
   if room==null or (specialization_structure=="" and not room.buildings.has(game.selected_tile)):return
   var kind=specialization_structure if specialization_structure!="" else room.buildings[game.selected_tile].kind
   var ids=StrategyCatalog.branches(kind)
   if ids.size()==2:pending_branch=ids[choice];refresh_context(),336,96,context_box)
  branch_button.name="specialization_"+str(i)
  specialization_items.append(branch_button)
 var branch_cancel=button("Back · keep level 4",Vector2(14,294),func():context_mode=specialization_structure if specialization_structure!="" else "upgrade";specialization_structure="";refresh_context(),336,36,context_box)
 specialization_items.append(branch_cancel)
 branch_confirm=button("Confirm exclusive specialization",Vector2(14,330),confirm_specialization,336,38,context_box)
 specialization_items.append(branch_confirm)
 var bed_art=icon("bed",Vector2(14,52),Vector2(80,108),context_box)
 bed_details=label_at("",Vector2(104,50),18,244,false,context_box)
 bed_details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 bed_details.size.y=128
 bed_button=button("Upgrade bed",Vector2(14,190),func(): upgrade_structure("bed"),336,44,context_box)
 actions.bed=bed_button
 bed_items=[bed_art,bed_details,bed_button]
 var door_art=icon("door",Vector2(14,52),Vector2(80,108),context_box)
 door_details=label_at("",Vector2(104,50),18,244,false,context_box)
 door_details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 door_details.size.y=138
 door_button=button("Upgrade door",Vector2(14,198),func(): upgrade_structure("door"),336,40,context_box)
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
 var draw_target=horror_layer
 horror_layer.draw.connect(func(): game.horror.render_notifications(draw_target);game.presentation.wrath_presentation.overlay(draw_target,game.model))

 items_ui.create_hotbar()
 if not game.mobile_mode:
  teammates.create()
  bottom_context=BottomContextPanel.new(self);bottom_context.install()
  expansion_ui=preload("res://scripts/expansion_interface.gd").new(self);expansion_ui.create()

func open_build_menu():
 if game.watched_room>=0 or game.model.player()==null:return
 var room=game.model.player()
 if room.buildings.size()>=room.tile_count() and game.model.run_kind=="endless" and expansion_ui!=null:
  expansion_ui.open();return
 if game.selected_tile<0 or room.buildings.has(game.selected_tile):
  for tile in range(room.tile_count()):
   if not room.buildings.has(tile):game.selected_tile=tile;break
 open_context()
 if not room.buildings.has(game.selected_tile):context_mode="build";refresh_context()

func open_context():
 if game.watched_room>=0:return
 teammates.expanded=false;teammates.update()
 items_ui.expanded=false;help_open=false
 game.cancel_placement()
 context_open=true
 var room=game.model.player()
 context_mode="upgrade" if room!=null and room.buildings.has(game.selected_tile) else "build"
 if game.full_map and room!=null:
  game.full_map=false;game.focus_camera(true)
 refresh_context()

func open_room_panel(kind: String):
 if game.watched_room>=0:return
 teammates.expanded=false;teammates.update()
 if game.model.player()==null: return
 game.cancel_placement()
 context_open=true
 context_mode=kind
 if game.full_map:
  game.full_map=false;game.focus_camera(true)
 refresh_context()

func open_confirmation():
 if game.watched_room>=0:return
 context_open=true
 context_mode="confirm"
 refresh_context()

func close_context():
 game.pending_build=""
 game.placement_on_tile=false
 context_open=false;pending_branch=""
 if bottom_context==null:
  if is_instance_valid(context_box):context_box.visible=false
  for node in build_items+upgrade_items+bed_items+door_items+confirmation_items+specialization_items:node.visible=false
 if expansion_ui!=null:expansion_ui.refresh()
 if bottom_context!=null:bottom_context.refresh()

func refresh_context():
 if not context_open or game.model.player()==null: close_context(); return
 var room=game.model.player()
 var heights={"build":382,"upgrade":300,"bed":250,"door":300,"confirm":272,"specialize":344}
 if not game.mobile_mode and bottom_context==null:
  context_box.position=Vector2(900,628-heights[context_mode])
  context_box.size=Vector2(364,heights[context_mode])
 context_box.visible=true
 for group in {"build":build_items,"upgrade":upgrade_items,"bed":bed_items,"door":door_items,"confirm":confirmation_items,"specialize":specialization_items}:
  var list={"build":build_items,"upgrade":upgrade_items,"bed":bed_items,"door":door_items,"confirm":confirmation_items,"specialize":specialization_items}[group]
  for node in list: node.visible=group==context_mode
 if context_mode=="build": context_title.text="BUILD A DEFENSE"
 elif context_mode=="specialize" and (specialization_structure!="" or room.buildings.has(game.selected_tile)):
  var b={"kind":specialization_structure,"level":4,"specialization":""} if specialization_structure!="" else room.buildings[game.selected_tile]
  context_title.text="CHOOSE SPECIALIZATION"
  specialization_items[0].text="ONE PERMANENT CHOICE · advances to level %d" % (6 if specialization_structure!="" else 5)
  specialization_items[3].text="Back · keep level %d" % (5 if specialization_structure!="" else 4)
  var ids=StrategyCatalog.branches(b.kind)
  if ids.size()!=2:close_context();return
  var price=Vector2(Catalog.BED_COST[4],Catalog.BED_POWER[4]) if specialization_structure=="bed" else Vector2(Catalog.DOOR_COST[4],Catalog.DOOR_POWER[4]) if specialization_structure=="door" else Catalog.upgrade_cost(b.kind,b.level)+StrategyCatalog.BRANCH_FEE
  var quote=price if specialization_structure!="" else room.building_price(price.x,price.y)
  for i in range(2):
   var button=specialization_items[i+1]
   var id=ids[i];var data=StrategyCatalog.BRANCHES[id]
   var stats={"precision":"+55% damage · 40% slower shots\n15% shorter range (204px)","suppression":"20% weaker · 18% faster shots\nSlow 15% / Reaper 7.5% for 1s","focus":"+50% damage · 35% slower shots","storm":"28% weaker · 28% faster shots\n+20% range · +25% projectile speed"}
   var preview=BuildingStats.branch_preview(game.model,room,b,id,specialization_structure)
   var lines=preview.split("\n");lines.remove_at(lines.size()-1)
   button.text=("SELECTED · " if pending_branch==id else "CHOOSE · ")+data.name+"\n"+"\n".join(lines)+"\n%.1f Gold / %.1f Electricity%s" % [quote.x,quote.y," · COUPON" if room.coupon_armed and specialization_structure=="" else ""]
   button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
   button.icon=PremiumButton.texture(id);button.expand_icon=true;button.add_theme_constant_override("icon_max_width",36)
   button.add_theme_font_size_override("font_size",14)
   button.tooltip_text=data.description+"\n"+("Full-price level6 upgrade; coupon remains for a placeable machine." if specialization_structure!="" else "Price includes level5 upgrade and25G/4E branch fee.")+" One branch only; level10cap."
   button.disabled=not game.model._can_purchase() or b.level!=4 or b.get("specialization","")!="" or room.bed_level<2 or room.door_level<2 or room.gold<quote.x or room.electricity<quote.y
  branch_confirm.disabled=pending_branch not in ids or not game.model._can_purchase() or room.gold<quote.x or room.electricity<quote.y
 elif context_mode=="upgrade" and room.buildings.has(game.selected_tile):
  var b=room.buildings[game.selected_tile]
  selected_icon.texture=game.presentation.cartoon[game.presentation.building_key(b.kind,b.level)]
  context_title.text=Catalog.BUILDINGS[b.kind].name.to_upper()
  var list_price=Catalog.upgrade_cost(b.kind,b.level)
  var quote=room.building_price(list_price.x,list_price.y)
  selected_details.tooltip_text=StrategyCatalog.BRANCHES.get(b.get("specialization",""),{}).get("description","")
  selected_details.text=BuildingStats.next_machine(game.model,room,game.selected_tile)+"\n"+action_reason("upgrade")+(" · COUPON %.1fG/%.1fE" % [quote.x,quote.y] if room.coupon_armed else "")
  if room.strategy_enabled and b.level==4:actions.upgrade.text="Specialize → Level 5"
 elif context_mode=="bed":
  context_title.text="BED LEVEL %d / 10" % (room.bed_level+1)
  bed_details.text=BuildingStats.structure_preview(game.model,room,"bed")+"\n"+action_reason("bed")
 elif context_mode=="door":
  context_title.text="DOOR LEVEL %d / 10" % (room.door_level+1)
  door_details.text=BuildingStats.structure_preview(game.model,room,"door")+"\n"+action_reason("door")
 elif context_mode=="confirm" and game.pending_build!="":
  var data=Catalog.BUILDINGS[game.pending_build]
  context_title.text="PLACE "+data.name.to_upper()
  confirmation_icon.texture=game.presentation.textures[game.pending_build]
  var reason=game.placement_reason()
  var quoted=room.building_price(data.gold,data.power)
  confirmation_details.text="%.1f G / %.1f E%s\n%s" % [quoted.x,quoted.y," · COUPON40%" if room.coupon_armed else "",reason if reason!="" else "Pad locked. Confirm to buy, or click another pad."]
  confirm_button.disabled=reason!=""
 if expansion_ui!=null:expansion_ui.refresh()
 if context_mode=="bed" and room.bed_branch!="":bed_details.tooltip_text=StrategyCatalog.BRANCHES[room.bed_branch].description
 if context_mode=="door" and room.door_branch!="":door_details.tooltip_text=StrategyCatalog.BRANCHES[room.door_branch].description
 if context_mode=="specialize":
  branch_confirm.visible=true
  branch_confirm.text="Confirm "+StrategyCatalog.BRANCHES.get(pending_branch,{}).get("name","exclusive choice")
 if bottom_context!=null:bottom_context.refresh()
 if game.mobile_mode: game.mobile_ui.context(self)

func selected_stats(b) -> String:
 var d=Catalog.BUILDINGS[b.kind]
 if b.kind in ["turret","heavy"]:
  var branch=StrategyCatalog.weapon(b)
  var id=b.get("specialization","")
  return "Level %d / 10%s\n%s\nDamage %.1f · Range %.0f\nEvery %.2fs" % [b.level," · MAX" if b.level==10 else "",StrategyCatalog.BRANCHES[id].name if id!="" else "Unmodified",Catalog.turret_damage(b.kind,b.level)*(game.model.player().turret_multiplier if game.model.player()!=null else 1)*branch.damage,d.range*branch.range,Catalog.turret_interval(b.kind,b.level)*branch.interval]
 if b.kind=="generator": return "Level %d / 10\nBase %.1f electricity/s\n%s" % [b.level,Catalog.support_output(b.kind,b.level)*StrategyCatalog.support(b).get("output",1.0),StrategyCatalog.support(b).get("name","Unmodified")]
 if b.kind=="repair": return "Level %d / 10\nBase %.1f door HP/s\n%s" % [b.level,Catalog.support_output(b.kind,b.level)*StrategyCatalog.support(b).get("output",1.0),StrategyCatalog.support(b).get("name","Unmodified")]
 return "Level %d / 10\n+%d%% %s\n%s" % [b.level,Catalog.support_output(b.kind,b.level)*StrategyCatalog.support(b).get("output",1.0)*100,"income" if b.kind=="economy" else "turret damage",StrategyCatalog.support(b).get("name","Unmodified")]

func upgrade_selected():
 var room=game.model.player()
 if room!=null and room.strategy_enabled and room.buildings.has(game.selected_tile):
  var b=room.buildings[game.selected_tile]
  if b.level==4:pending_branch="";specialization_structure="";context_mode="specialize";refresh_context();return
 purchase(game.model.upgrade_building(game.selected_tile))

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
 if game.model.run_kind=="practice":
  var reset=button("Reset Practice",Vector2(450,465),game.reset_practice,380,44)
  pause_items.append(reset)

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
 if m.run_kind=="endless" and m.endless.phase=="intermission":return "INTERMISSION · NO INCOME\nBuild, upgrade or sell. WAVE / Esc saves and returns to your choice."
 var room=m.player()
 if room==null:
  if m.strategy.enabled:
   var closest=null
   for candidate in m.rooms:
    if candidate.owner<0 and (closest==null or candidate.center().distance_to(m.player_position)<closest.center().distance_to(m.player_position)):closest=candidate
   if closest==null:return "NO VACANT ROOM\nEvery room is claimed. Restart to choose a room."
   var room_trait=StrategyCatalog.TRAITS[closest.trait_id]
   return "ROOM %d · %s\n%s / %s. Enter and press E." % [closest.index+1,room_trait.name,room_trait.benefit,room_trait.drawback]
  return "1 / 5  FIND A ROOM\nMove with WASD. Press E inside a vacant bedroom."
 if not room.sleeping: return "2 / 5  OCCUPY THE BED\nApproach your bed and press E. Gold starts while sleeping."
 if room.income_total<8: return "3 / 5  EARN GOLD\nYour bed earns gold automatically while you sleep."
 if room.bed_level==0 and room.door_level==0: return "4 / 5  UPGRADE\nClick the bed or door summary below."
 for b in room.buildings.values():
  if b.kind in ["turret","heavy"]: return "NIGHTWATCH READY\nSave for power and stronger defenses. Help/G hides this guide."
 return "5 / 5  FIRST DEFENSE\nClick a floor pad, then BUILD a turret in the bottom panel."

func update_match():
 if not is_instance_valid(gold_label) or game.mode!="match": return
 var m=game.model
 var room=m.player()
 if m.strategy.enabled:
  guide_label.tooltip_text=StrategyCatalog.ARCHETYPES[m.strategy.archetype].hint+"\n"+m.strategy.status()
 gold_label.text=resource_text(room.gold) if room!=null else "—"
 gold_label.tooltip_text="Gold: %s" % str(snappedf(room.gold,.01)) if room!=null else "Gold"
 power_label.text=resource_text(room.electricity) if room!=null else "—"
 power_label.tooltip_text="Electricity: %s" % str(snappedf(room.electricity,.01)) if room!=null else "Electricity"
 phase_label.text="%02d:%02d\n%s" % [int(m.time)/60,int(m.time)%60,"PREP %ds" % maxi(0,ceili(m.preparation-m.time)) if m.time<m.preparation else "SURVIVE"]
 hunter_label.text=("REAPER · %d/%d" % [roundi(m.hunter.hp),roundi(m.hunter.max_hp)]) if m.hunter.transformed else "HUNTER L%d  ·  %d/%d" % [m.hunter.level,roundi(m.hunter.hp),roundi(m.hunter.max_hp)]
 hunter_detail.text="%d ATK · %.2fs%s · TEAM %d" % [m.hunter.damage,m.hunter.interval," · WINDUP!" if m.hunter.charged_ready else "",m.rooms.filter(func(r):return r.owner>=0 and r.alive).size()]
 if m.hunter.state==HunterState.State.TRANSFORM: hunter_detail.text="AWAKENING · %.1fs · TRANSITION GUARD" % m.hunter.transform_remaining
 elif m.hunter.tactical_action!="":hunter_detail.text="%s · %.1fs · WATCH THE DOOR" % [m.hunter.tactical_action.to_upper(),m.hunter.tactical_windup]
 elif m.hunter.boss_attack!="": hunter_detail.text="%s · %.1fs" % [BossCatalog.ATTACKS[m.hunter.boss_attack].name,m.hunter.windup_remaining]
 elif m.hunter.surge_remaining>0: hunter_detail.text="SURGE · %.1fs · REAPER EXPOSED +20%%" % m.hunter.surge_remaining
 hunter_detail.modulate=Color("FF7777") if m.difficulty=="hell" else Color("FFD27A")
 hunter_bar.max_value=m.hunter.max_hp
 hunter_bar.value=m.hunter.hp
 hunter_label.tooltip_text="Hunter damage, affinity and acquired evolution effects."
 hunter_detail.tooltip_text=""
 if m.strategy.enabled:
  hunter_label.tooltip_text=StrategyCatalog.ARCHETYPES[m.strategy.archetype].name+"\n"+StrategyCatalog.ARCHETYPES[m.strategy.archetype].hint
  if m.hunter.state!=HunterState.State.TRANSFORM and m.hunter.boss_attack=="" and m.hunter.surge_remaining<=0 and m.hunter.tactical_action=="":
   var contract_state="No contract" if m.strategy.contract=="" else "CONTRACT FAILED" if m.strategy.failed else "CONTRACT ACTIVE"
   hunter_detail.text=StrategyCatalog.ARCHETYPES[m.strategy.archetype].name+" · TEAM %d · " % m.rooms.filter(func(r):return r.owner>=0 and r.alive).size()+contract_state
  hunter_detail.clip_text=true;hunter_detail.tooltip_text=StrategyCatalog.ARCHETYPES[m.strategy.archetype].hint+"\n"+m.strategy.status()
 if not m.evolution.acquired.is_empty():
  hunter_label.text+=" · ↑%d" % m.evolution.acquired.size()
  hunter_label.tooltip_text="ACQUIRED EVOLUTIONS (this run)"
  for id in m.evolution.acquired:hunter_label.tooltip_text+="\n"+HunterEvolution.BUFFS[id].name+": "+HunterEvolution.BUFFS[id].effect
 if m.wrath.active():hunter_detail.text="%s · %.1fs · ROOM %d" % [ReaperWrath.ABILITIES[m.wrath.ability].name.to_upper(),m.wrath.warning,m.wrath.cast_target+1]
 elif m.hunter.phase_guard_remaining>0:hunter_detail.text="PHASE TRANSITION GUARD · %.1fs" % m.hunter.phase_guard_remaining
 elif m.hunter.transformed and m.hunter.state!=HunterState.State.TRANSFORM and m.hunter.boss_attack=="" and m.hunter.surge_remaining<=0:hunter_detail.text="PHASE %s · %d UNDEAD · POWER %d" % ["II" if m.wrath.phase==2 else "I",m.minions.size(),m.evolution.acquired.size()]
 if game.tutorial_active:
  phase_label.text="PRACTICE\nSTEP %d / 9" % [game.onboarding.step+1]
  if game.onboarding.step<7:
   hunter_label.text="SAFE PRACTICE · NO ENEMY YET"
   hunter_detail.text="Learn at your own pace"
   hunter_bar.value=0
  else:
   hunter_label.text="PRACTICE HUNTER · %d / %d" % [roundi(m.hunter.hp),roundi(m.hunter.max_hp)]
   hunter_detail.text="Very weak attack · practice only"
 map_button.text="Focus" if game.full_map else "Map"
 guide_box.visible=((help_open and not game.full_map) or game.presentation.clock<feedback_until) and not (game.model.map_id!="legacy" and context_open)
 guide_label.visible=guide_box.visible
 if guide_label.visible: guide_label.text=feedback_text if game.presentation.clock<feedback_until else tutorial_text()
 var threat=room!=null and (m.hunter.target==room.index and m.hunter.state==HunterState.State.ATTACK or m.minions.any(func(u):return u.hp>0 and u.target==room.index and u.position.distance_to(room.door_approach())<=3))
 # Routine positive feedback yields to real danger; errors and requested Help
 # remain visible. Existing selection/upgrade pulse still confirms the action.
 if threat and not help_open and feedback_text in ["Defense improved!","Building sold · 50% gold and electricity refunded."]:
  guide_box.visible=false;guide_label.visible=false
 warning_box.visible=threat or game.level_warning_time>0 or m.wrath.active()
 warning_label.visible=warning_box.visible
 if not threat and game.level_warning_time>0: warning_label.text="THE HUNTER GROWS STRONGER · LEVEL %d" % m.hunter.level
 if threat:
  warning_label.text="DOOR %d/%d · UNDER ATTACK" % [roundi(room.door_hp),roundi(room.max_hp())]
  if m.hunter.tactical_action!="":warning_label.text="%s %.1fs · PREPARE DEFENSES" % [m.hunter.tactical_action.to_upper(),m.hunter.tactical_windup]
  elif m.hunter.charged_ready: warning_label.text="HEAVY STRIKE %.1fs · REPAIR / UPGRADE" % m.hunter.windup_remaining
  elif m.hunter.archetype_primed:warning_label.text="%s · STRIKE WARNING · REPAIR NOW" % StrategyCatalog.ARCHETYPES[m.hunter.archetype].name.to_upper()
  elif room.repair_factor<0.99: warning_label.text="DOOR %d/%d · REPAIRS %d%%" % [roundi(room.door_hp),roundi(room.max_hp()),roundi(room.repair_factor*100)]
  if m.hunter.boss_attack!="":
   warning_label.text="%s %.1fs · REPAIR NOW" % [BossCatalog.ATTACKS[m.hunter.boss_attack].name,m.hunter.windup_remaining]
  elif m.hunter.shadow_active(room.index): warning_label.text="TURRETS SILENCED %.1fs · KEEP REPAIRING" % m.hunter.surge_remaining
  warning_box.modulate.a=0.75+game.danger_time*0.35
 if m.hunter.nightmare.action!="":
  hunter_detail.text=NightmareCombat.SKILLS[m.hunter.nightmare.action].name+" · %.1fs · INTERRUPT / DEFEND" % m.hunter.nightmare.warning
  hunter_detail.tooltip_text=NightmareCombat.SKILLS[m.hunter.nightmare.action].help
  if threat:warning_label.text=hunter_detail.text
 elif m.evolution.rebirth_remaining>0:
  hunter_detail.text="TRUE NIGHTMARE · REBIRTH %.1fs" % m.evolution.rebirth_remaining
  warning_label.text=hunter_detail.text;warning_label.visible=true;warning_box.visible=true
 hunter_label.text=("REAPER" if m.hunter.transformed else "HUNTER")+" EVO %d · %d/%d" % [m.evolution.evolution_level,roundi(m.hunter.hp),roundi(m.hunter.max_hp)]
 hunter_label.tooltip_text+="\nEvolution %d/10: forms at4/7/10. Combat level %d is separate; no extra HP multiplier. Endless +1 per5 waves. Campaign: stage,75s survival steps,+1 Hell,one step per3 kill buffs. Skills at4; signature at10." % [m.evolution.evolution_level,m.hunter.level]
 if m.wrath.active():warning_label.text="%s · %.1fs · ROOM %d" % [ReaperWrath.ABILITIES[m.wrath.ability].name.to_upper(),m.wrath.warning,m.wrath.cast_target+1]
 if warning_label.visible and (threat or m.hunter.nightmare.action!=""):
  hunter_detail.tooltip_text+="\n"+hunter_detail.text
  hunter_detail.text="[Hover for Hunter details]"
  hunter_detail.modulate=Color(.72,.77,.82)
 else:hunter_detail.modulate=Color.WHITE
 details.text="Choose a room" if room==null else "%s · %s" % [game.presentation.ROOM_NAMES[room.index].capitalize(),"sleeping" if room.sleeping else "awake"]
 for control in [room_bed_summary,room_door_summary,room_selected_summary]: control.disabled=room==null
 if room!=null:
  room_bed_summary.text="Bed L%d  ·  %.1f G/s" % [room.bed_level+1,room.income_rate()]
  room_door_summary.text="Door L%d  ·  %d/%d" % [room.door_level+1,roundi(room.door_hp),roundi(room.max_hp())]
  room_selected_summary.text="Build · choose pad"
  var bed_cost="MAX" if room.bed_level>=9 else "%d Gold / %d Electricity" % [Catalog.BED_COST[room.bed_level],Catalog.BED_POWER[room.bed_level]]
  var door_cost="MAX" if room.door_level>=9 else "%d Gold / %d Electricity" % [Catalog.DOOR_COST[room.door_level],Catalog.DOOR_POWER[room.door_level]]
  bed_button.text="Upgrade Bed — "+bed_cost
  door_button.text="Upgrade Door — "+door_cost
  if room.buildings.has(game.selected_tile):
   var b=room.buildings[game.selected_tile]
   var d=Catalog.BUILDINGS[b.kind]
   var refund=room.building_refund(game.selected_tile)
   actions.sell.text="Sell · 50%% actual investment\n+%.2f Gold / +%.2f Electricity" % [refund.x,refund.y]
   var price=Catalog.upgrade_cost(b.kind,b.level)
   actions.upgrade.text="MAX LEVEL" if b.level>=Catalog.building_max_level(b.kind) else "Upgrade L%d — %d Gold / %d Electricity" % [b.level+1,price.x,price.y]
   if room.strategy_enabled and b.level==4:actions.upgrade.text="Specialize → Level 5"
  else: actions.upgrade.text="Select a building to upgrade"
 actions.repair.text="Repair · %.1f gold" % (room.manual_repair_cost() if room!=null else Catalog.REPAIR_COST)
 hunter_label.tooltip_text+="\nDamage: Physical claws; telegraphed Magic specials. Affinity: "+DamageRules.affinity(m.hunter.archetype).capitalize()+".\nFire > Ice > Earth > Electric > Fire: +15% strong, -10% weak; neutral unchanged."
 if m.hunter.arcane.action!="":hunter_detail.text=m.hunter.arcane.action.replace("_"," ").to_upper()+" · %.1fs" % m.hunter.arcane.warning
 if room!=null and room.magic_state.disrupt>0:warning_label.text="TURRET INTERFERENCE · %.1fs · Repair remains available" % room.magic_state.disrupt;warning_label.visible=true
 var immediate=room!=null and room.alive and room.door_hp<room.max_hp()*.35 and game.model.hunter.target==room.index and game.model.hunter.state in [HunterState.State.ATTACK,HunterState.State.BREACH]
 # Theme overrides invalidate control layout: only change material on a real state transition.
 if not room_door_summary.has_meta("danger_skin") or room_door_summary.get_meta("danger_skin")!=immediate:
  room_door_summary.add_theme_stylebox_override("normal",GothicTheme.surface("583344" if immediate else "22292B","BC626B" if immediate else "938876","button_normal"))
  room_door_summary.set_meta("danger_skin",immediate)
 room_door_summary.modulate=Color(1,.91+.09*sin(game.presentation.clock*3),.91+.09*sin(game.presentation.clock*3)) if immediate and not game.profile.settings.reduced_effects else Color.WHITE
 quick_repair.text="Repair %.1f G [R]" % (room.manual_repair_cost() if room!=null else Catalog.REPAIR_COST)
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
 if bottom_context!=null:bottom_context.refresh()
 if game.model.run_kind!="campaign":replay_ui.update_hud()
 if not game.mobile_mode:teammates.update()

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
 if game.model.result=="defeat" and not game.model.defeat_facts.report.is_empty():button("Why did I lose?",Vector2(945,440),replay_ui.show_defeat_analysis,300,44)
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
  gold = room.manual_repair_cost()
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
  if room.strategy_enabled and b.level==4:return ""
  var requirement=Catalog.upgrade_requirement(b.kind,b.level,room.bed_level,room.door_level)
  if requirement!="":return requirement
  var price=Catalog.upgrade_cost(b.kind,b.level)
  gold=price.x
  power=price.y
 if action.begins_with("build:") or action=="upgrade":
  var quoted=room.building_price(gold,power)
  gold=quoted.x; power=quoted.y
 if room.gold+0.00001 < gold: return "Need %d more gold." % ceili(gold-room.gold)
 if room.electricity+0.00001 < power: return "Need %d more electricity. Build a Dynamo." % ceili(power-room.electricity)
 return ""

func tile_description(room: RoomState) -> String:
 if not room.buildings.has(game.selected_tile):
  return "Empty floor: choose a building"
 var b = room.buildings[game.selected_tile]
 var d = Catalog.BUILDINGS[b.kind]
 if b.level >= Catalog.building_max_level(b.kind):
  return "%s L%d · MAX" % [d.name,b.level]
 return "%s L%d" % [d.name,b.level]


func building_effect(kind: String) -> String:
 var data = Catalog.BUILDINGS[kind]
 match kind:
  "barrier":return "Returns a bounded share of eligible Magic damage to its attacker with a shared cooldown. Original damage still reaches the door; no recursive reflection. Physical bypasses it. Highest-level unit per kind; equal levels use first placed."
  "plasma":return "Absorbs part of Magic damage into finite temporary storage. Spends stored energy on limited intact-door healing; never grants Gold or Electricity. Physical bypasses it. Highest-level unit per kind; equal levels use first placed."
  "antenna":return "Pays Electricity to regenerate finite Magic-only shield durability. One highest-level antenna operates per room; equal levels use first placed. Physical bypasses it."
  "turret", "heavy", "flame", "frost", "shock":
   return "%.1f damage / %.1fs; range %.1fpx. Upgrades increase damage and attack speed. %s" % [data.damage,data.interval,data.range,"Requires bed level 2." if kind=="heavy" else ""]
  "auto_repair":return "Automatically pays Gold and Electricity to repair a damaged intact door. No free healing."
  "shield":return "Pays Electricity for a finite short barrier; shared room refractory prevents permanent immunity."
  "decoy":return "Pays Electricity for a finite legal-path Hunter diversion. Shared cooldown; Reaper resistant."
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

func show_audio_test():
 clear();current_screen="audio_test"
 box(Rect2(80,40,1120,640))
 label_at("HORROR AUDIO · LISTENING ROOM",Vector2(110,66),28,1050,true)
 label_at("Saved Music/Effects/Mute settings apply. Human quality and scariness require your ears.",Vector2(110,112),16,1050)
 for i in range(3):
  var tab=["Music","Voices","Action SFX"][i]
  var chosen=tab
  var b=button(tab,Vector2(110+i*360,155),func():game.audio_system.stop_preview();audio_tab=chosen;show_audio_test(),330,44)
  b.toggle_mode=true;b.button_pressed=audio_tab==tab
 if audio_tab=="Music":
  var names=["music_intro","music_menu","music_calm","music_approach","music_danger","music_reaper","music_endless","music_crimson"]
  for i in range(names.size()):
   var id=names[i]
   button(id.trim_prefix("music_").capitalize()+" · score",Vector2(110+(i%2)*540,220+int(i/2)*72),func():game.audio_system.preview_track(id),510,54)
 elif audio_tab=="Voices":
  var voices=["death_scream_1","hunter_laugh","reaper_laugh","intro_breath","reaper_charge"]
  for i in range(voices.size()):
   var id=voices[i]
   button(id.replace("_"," ").capitalize(),Vector2(110+(i%2)*540,230+int(i/2)*80),func():game.audio_system.preview_effect(id),510,58)
 else:
  var groups=game.audio_system.sfx_preview_groups();var keys=groups.keys()
  for i in range(keys.size()):
   var group=keys[i]
   var b=button(group,Vector2(110+i*270,220),func():audio_group=group;show_audio_test(),250,44)
   b.toggle_mode=true;b.button_pressed=audio_group==group
  if audio_group not in groups:audio_group=keys[0]
  var names=groups[audio_group]
  for i in range(names.size()):
   var id=names[i]
   button(id.replace("_"," ").capitalize(),Vector2(110+(i%2)*540,290+int(i/2)*78),func():game.audio_system.preview_effect(id),510,58)
 button("Stop audition",Vector2(110,598),game.audio_system.stop_preview,330,44)
 button("Back to settings",Vector2(650,598),func():game.audio_system.stop_preview();show_settings(),510,44)

func upgrade_structure(kind: String):
 var room=game.model.player()
 if room==null:return
 if (room.bed_level if kind=="bed" else room.door_level)==4 and (room.bed_branch if kind=="bed" else room.door_branch)=="":
  pending_branch="";specialization_structure=kind;context_mode="specialize";refresh_context();return
 purchase(game.model.upgrade_bed() if kind=="bed" else game.model.upgrade_door())

func confirm_specialization():
 var room=game.model.player()
 if room==null or pending_branch=="" or not game.model._can_purchase():return
 var ok=room.specialize_structure(specialization_structure,pending_branch) if specialization_structure!="" else game.model.specialize_building(game.selected_tile,pending_branch)
 if ok:
  if game.audio_system.streams.has("ui_confirm"):game.audio_event("ui_confirm")
  context_mode=specialization_structure if specialization_structure!="" else "upgrade"
  specialization_structure="";pending_branch=""
 purchase(ok);refresh_context()
