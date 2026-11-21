extends RefCounted
## Shared desktop settings view. Saves each real preference through Game.

const PAGES:=["Graphics","Audio","Gameplay","Controls","Accessibility","Interface / HUD"]

var ui
var game
var root: Control
var body: VBoxContainer
var scroll: ScrollContainer
var tabs: Array[Button]=[]
var title: Label
var back: Callable

func _init(interface) -> void:
 ui=interface
 game=ui.game

func open(on_close: Callable) -> void:
 back=on_close
 root=ColorRect.new()
 root.name="TacticalSettings"
 root.color=Color("111923")
 root.size=Vector2(1280,720)
 root.mouse_filter=Control.MOUSE_FILTER_STOP
 root.z_index=90
 ui.attach(root)
 var frame: Panel=ui.theme_panel(Rect2(86,48,1108,624),"frame",root)
 ui.theme_label("Settings",Vector2(32,17),45,690,"text",true,frame)
 var done: Button=ui.button("Back [Esc]",Vector2(902,22),close,172,46,frame)
 done.name="settings_back"
 ui.theme_button(done,"quiet")
 for i in range(PAGES.size()):
  var b: Button=ui.button(PAGES[i],Vector2(30,103+i*73),func():select_page(i),252,54,frame)
  b.name="settings_page_"+str(i)
  b.alignment=HORIZONTAL_ALIGNMENT_LEFT
  b.add_theme_font_size_override("font_size",21)
  tabs.append(b)
 var area: Panel=ui.theme_panel(Rect2(307,100,769,474),"card",frame)
 title=ui.theme_label("",Vector2(24,13),27,702,"text",false,area)
 scroll=ScrollContainer.new()
 scroll.position=Vector2(24,64)
 scroll.size=Vector2(721,399)
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.follow_focus=true
 area.add_child(scroll)
 body=VBoxContainer.new()
 body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 body.add_theme_constant_override("separation",13)
 scroll.add_child(body)
 select_page(0)
 tabs[0].grab_focus()

func close() -> void:
 if not is_instance_valid(root):return
 game.audio_system.stop_preview()
 root.hide()
 root.queue_free()
 root=null
 back.call()

func select_page(index: int) -> void:
 for child in body.get_children():
  body.remove_child(child)
  child.queue_free()
 scroll.scroll_vertical=0
 title.text=PAGES[index]
 for i in range(tabs.size()):ui.theme_button(tabs[i],"settings" if i==index else "secondary")
 match index:
  0:
   choices("graphics_quality","Quality preset",["Low","Standard","High"],["low","medium","high"])
   label("Low keeps combat cues and reduces ambient detail.",17)
   toggle("fullscreen","Fullscreen")
   label("Current viewport · %d × %d" % [game.get_window().size.x,game.get_window().size.y],17)
   toggle("adaptive_performance","Adaptive performance")
  1:
   for pair in [["music","Music"],["effects","Sound effects"],["ambient","Ambience"]]:
    volume(pair[0],pair[1])
   toggle("muted","Mute all audio")
   choices("music_mode","Soundtrack",["Dynamic shuffle","Classic","Manual track","Off"],["shuffle","classic","manual","off"])
   choices("manual_track","Manual track",Soundtrack.TITLES.values(),Soundtrack.TITLES.keys())
   action("Preview selected music",func():game.audio_system.preview_track(game.profile.settings.manual_track))
   action("Stop audio preview",game.audio_system.stop_preview)
  2:
   toggle("tutorial","First-night tutorial")
   choices("room_identity","Room identity",PlayerProfile.ROOM_IDENTITIES,PlayerProfile.ROOM_IDENTITIES)
   label("Room identity is cosmetic and stored with your profile.",17)
  3:
   for pair in [["Move / claim or sleep","WASD or arrows / E"],["Build / rotate / cancel","B / Q / Esc"],["Plan / range / move / undo","P / O / V / Z"],["Repair / Ward","R / F"],["Items / inspect slot","I / 1 or 2"],["Map / danger shading","M / H on the map"],["Free camera / lock room","Middle-drag or scroll / Home"],["Teammates / cycle","T / Page Up or Page Down"],["Help / pause","G / Esc"]]:
    label("%s     %s" % [pair[0],pair[1]],19)
  4:
   toggle("reduced_motion","Reduce camera and interface motion")
   toggle("reduced_flashes","Reduce flashes")
   toggle("reduced_effects","Reduce decorative effects")
  5:
   choices("damage_numbers","Damage numbers",["All","My weapons","Combined","Off"],WeaponFeedback.NUMBER_MODES)
   choices("guidance_mode","Objective guidance",["Show","Minimal","Off"],["show","minimal","off"])
   toggle("tactical_alerts","Teammate and evolution alerts")
   label("Urgent combat cues remain visible.",17)

func label(text: String,pixels: int) -> Label:
 var node:=Label.new()
 node.text=text
 node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 node.add_theme_font_size_override("font_size",pixels)
 node.add_theme_color_override("font_color",GothicTheme.palette().text)
 body.add_child(node)
 return node

func toggle(key: String,text: String) -> void:
 var node:=CheckButton.new()
 node.name=key
 node.text=text
 node.custom_minimum_size.y=46
 node.add_theme_font_size_override("font_size",20)
 node.button_pressed=game.profile.settings.get(key,false)
 node.toggled.connect(func(value):game.change_setting(key,value))
 body.add_child(node)
 ui.theme_button(node,"secondary")

func choices(key: String,text: String,names: Array,values: Array) -> void:
 label(text,19)
 var node:=OptionButton.new()
 node.name=key
 node.custom_minimum_size.y=46
 node.add_theme_font_size_override("font_size",20)
 for name in names:node.add_item(str(name))
 node.select(maxi(0,values.find(game.profile.settings.get(key))))
 node.item_selected.connect(func(i):game.change_setting(key,values[i]))
 body.add_child(node)
 ui.theme_button(node,"settings")
 node.get_popup().add_theme_stylebox_override("panel",GothicTheme.living_surface("frame"))

func volume(key: String,text: String) -> void:
 var caption:=label("",19)
 var slider:=HSlider.new()
 slider.name=key+"_volume"
 slider.max_value=1
 slider.step=.01
 slider.value=game.profile.settings[key]
 slider.custom_minimum_size.y=32
 caption.text="%s · %d%%" % [text,roundi(slider.value*100)]
 slider.value_changed.connect(func(value):
  game.change_setting(key,value)
  caption.text="%s · %d%%" % [text,roundi(value*100)])
 body.add_child(slider)

func action(text: String,callback: Callable) -> void:
 var button: Button=ui.button(text,Vector2.ZERO,callback,0,46,body)
 button.custom_minimum_size.y=46
 ui.theme_button(button,"settings")
