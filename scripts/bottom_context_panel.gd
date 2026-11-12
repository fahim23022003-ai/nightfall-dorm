class_name BottomContextPanel
extends RefCounted
# One sliding drawer above a genuinely bottom-aligned compact toolbar.
const HEADER=Rect2(20,650,1240,54)
const BODY=Rect2(20,438,1240,204)
const CLOSED=Vector2(20,724)
const SLIDE_SECONDS=.26
var ui
var idle_hint: Label
var tween: Tween
var expanded=false
var transitioning=false
var upgrade_shortcut: Button
func _init(owner):ui=owner
func place(node: Control,at: Vector2,size: Vector2):node.position=at;node.size=size
func install():
 place(ui.room_dock,HEADER.position,HEADER.size)
 place(ui.details,Vector2(33,665),Vector2(145,26));ui.details.add_theme_font_size_override("font_size",14)
 for button in [ui.room_selected_summary,ui.room_bed_summary,ui.room_door_summary,ui.quick_repair]:
  button.add_theme_font_size_override("font_size",14);button.expand_icon=true;button.add_theme_constant_override("icon_max_width",20);button.add_theme_constant_override("h_separation",6)
 ui.room_bed_summary.icon=ui.game.presentation.textures.bed;ui.room_door_summary.icon=ui.game.presentation.textures.door
 place(ui.room_selected_summary,Vector2(188,658),Vector2(180,38))
 place(ui.room_bed_summary,Vector2(380,658),Vector2(180,38))
 place(ui.room_door_summary,Vector2(572,658),Vector2(238,38))
 place(ui.quick_repair,Vector2(1058,658),Vector2(184,38))
 upgrade_shortcut=ui.button("Upgrade selected",Vector2(824,658),func():ui.open_context(),220,38)
 upgrade_shortcut.add_theme_font_size_override("font_size",14)
 upgrade_shortcut.tooltip_text="Select a machine to inspect its current level and upgrades."
 place(ui.context_box,CLOSED,BODY.size);ui.context_box.visible=false
 place(ui.context_title,Vector2(14,4),Vector2(1130,24))
 for child in ui.context_box.get_children():
  if child is Button and child.text=="×":place(child,Vector2(1190,2),Vector2(32,26))
 var count=int(ui.build_items.size()/5)
 for i in range(count):
  var base=i*5;var at=Vector2(10+(i%5)*244,32+int(i/5)*55)
  var b=ui.build_items[base];place(b,at,Vector2(238,52));b.text="BUILD";b.alignment=HORIZONTAL_ALIGNMENT_RIGHT;b.add_theme_font_size_override("font_size",13)
  place(ui.build_items[base+1],at+Vector2(4,6),Vector2(34,36))
  var name=ui.build_items[base+2];place(name,at+Vector2(43,2),Vector2(143,17));name.text=name.text.replace("\n"," ");name.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT;name.add_theme_font_size_override("font_size",14)
  var cost=ui.build_items[base+3];place(cost,at+Vector2(43,34),Vector2(178,15));cost.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT;cost.add_theme_font_size_override("font_size",12)
  var role=ui.build_items[base+4];place(role,at+Vector2(43,18),Vector2(143,15));role.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT;role.add_theme_font_size_override("font_size",12)
 place(ui.selected_icon,Vector2(14,44),Vector2(82,96))
 place(ui.selected_details,Vector2(110,33),Vector2(704,143));ui.selected_details.add_theme_font_size_override("font_size",14)
 place(ui.actions.upgrade,Vector2(840,40),Vector2(370,44))
 place(ui.actions.sell,Vector2(840,100),Vector2(370,54))
 place(ui.bed_items[0],Vector2(14,44),Vector2(82,104));place(ui.bed_details,Vector2(110,33),Vector2(704,143))
 place(ui.bed_button,Vector2(840,40),Vector2(370,44))
 place(ui.door_items[0],Vector2(14,44),Vector2(82,104));place(ui.door_details,Vector2(110,33),Vector2(704,143))
 place(ui.door_button,Vector2(840,40),Vector2(370,44));place(ui.actions.repair,Vector2(840,100),Vector2(370,42))
 place(ui.confirmation_icon,Vector2(14,44),Vector2(82,96));place(ui.confirmation_details,Vector2(110,33),Vector2(704,143))
 place(ui.confirm_button,Vector2(840,40),Vector2(370,44));place(ui.confirmation_items[-1],Vector2(840,100),Vector2(370,42))
 place(ui.specialization_items[0],Vector2(14,24),Vector2(1190,18))
 for i in range(2):place(ui.specialization_items[i+1],Vector2(14+i*610,35),Vector2(596,110));ui.specialization_items[i+1].add_theme_font_size_override("font_size",14)
 place(ui.specialization_items[3],Vector2(14,151),Vector2(280,44))
 if is_instance_valid(ui.branch_confirm):place(ui.branch_confirm,Vector2(840,151),Vector2(370,44))
 # Keep the complete toolbar above the travelling drawer for both drawing and
 # GUI hit testing; z_index alone would not fix Control input ordering.
 for control in [ui.room_dock,ui.details,ui.room_selected_summary,ui.room_bed_summary,ui.room_door_summary,ui.quick_repair,upgrade_shortcut,ui.teammates.home]:
  if is_instance_valid(control) and control.get_parent()==ui.panel:ui.panel.move_child(control,-1)
 refresh()
func is_transitioning() -> bool:return transitioning
func fit_action(button: Button):
 if not is_instance_valid(button):return
 var signature=button.text+"|"+str(button.size.x)
 if button.get_meta("price_fit","")==signature:return
 button.set_meta("price_fit",signature)
 var available=button.size.x-button.get_theme_stylebox("normal").get_minimum_size().x-4
 if button.icon!=null:available-=button.get_theme_constant("icon_max_width")+button.get_theme_constant("h_separation")
 var font=button.get_theme_font("font");var selected=14
 for size in [16,15,14]:
  if font.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x<=available:selected=size;break
 button.add_theme_font_size_override("font_size",selected)
func refresh():
 if not is_instance_valid(ui.context_box):return
 ui.context_box.size=BODY.size
 for button in [ui.actions.upgrade,ui.bed_button,ui.door_button]:fit_action(button)
 if ui.context_open!=expanded:
  expanded=ui.context_open
  if tween!=null and tween.is_valid():tween.kill()
  transitioning=true;ui.context_box.visible=true
  tween=ui.context_box.create_tween();tween.set_trans(Tween.TRANS_CUBIC);tween.set_ease(Tween.EASE_OUT if expanded else Tween.EASE_IN)
  tween.tween_property(ui.context_box,"position",BODY.position if expanded else CLOSED,SLIDE_SECONDS)
  tween.tween_callback(func():transitioning=false;ui.context_box.visible=expanded)
 elif not expanded and not transitioning:ui.context_box.visible=false
 if ui.context_mode=="specialize":ui.specialization_items[0].visible=false
 if is_instance_valid(upgrade_shortcut):
  var room=ui.game.model.player();upgrade_shortcut.disabled=room==null or not room.buildings.has(ui.game.selected_tile) or ui.game.watched_room>=0
 if is_instance_valid(ui.guide_box) and ui.context_open:ui.guide_box.visible=false;ui.guide_label.visible=false
