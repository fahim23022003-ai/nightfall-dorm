class_name BottomContextPanel
extends RefCounted
# One predictable building region. Camera sizing is fixed independently of mode.
const HEADER=Rect2(20,460,1240,46)
const BODY=Rect2(20,506,1240,198)
var ui
var idle_hint: Label
func _init(owner):ui=owner
func place(node: Control,at: Vector2,size: Vector2):
 node.position=at;node.size=size
func install():
 place(ui.room_dock,HEADER.position,HEADER.size)
 place(ui.details,Vector2(34,469),Vector2(200,30));ui.details.add_theme_font_size_override("font_size",16)
 place(ui.room_bed_summary,Vector2(250,466),Vector2(226,34))
 place(ui.room_door_summary,Vector2(490,466),Vector2(266,34))
 place(ui.room_selected_summary,Vector2(770,466),Vector2(263,34))
 place(ui.quick_repair,Vector2(1047,466),Vector2(196,34))
 place(ui.context_box,BODY.position,BODY.size)
 place(ui.context_title,Vector2(14,4),Vector2(1130,24))
 for child in ui.context_box.get_children():
  if child is Button and child.text=="×":place(child,Vector2(1190,2),Vector2(32,26))
 # Palette uses whole-card BUILD targets with role art and literal prices.
 var count=int(ui.build_items.size()/5)
 for i in range(count):
  var base=i*5;var at=Vector2(10+(i%4)*306,26+int(i/4)*48)
  var b=ui.build_items[base]
  place(b,at,Vector2(298,46));b.text="BUILD";b.alignment=HORIZONTAL_ALIGNMENT_RIGHT
  b.add_theme_font_size_override("font_size",14)
  place(ui.build_items[base+1],at+Vector2(5,3),Vector2(40,40))
  var name=ui.build_items[base+2];place(name,at+Vector2(52,2),Vector2(180,16))
  name.text=name.text.replace("\n"," ")
  name.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT;name.add_theme_font_size_override("font_size",14)
  var cost=ui.build_items[base+3];place(cost,at+Vector2(52,31),Vector2(180,14))
  cost.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT;cost.add_theme_font_size_override("font_size",12)
  var role=ui.build_items[base+4];place(role,at+Vector2(52,17),Vector2(180,14))
  role.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT;role.add_theme_font_size_override("font_size",12)
 place(ui.selected_icon,Vector2(14,42),Vector2(82,96))
 place(ui.selected_details,Vector2(110,30),Vector2(704,138))
 ui.selected_details.add_theme_font_size_override("font_size",14)
 place(ui.actions.upgrade,Vector2(840,38),Vector2(370,44));ui.actions.upgrade.add_theme_font_size_override("font_size",16)
 place(ui.actions.sell,Vector2(840,94),Vector2(370,54))
 place(ui.bed_items[0],Vector2(14,40),Vector2(82,104))
 place(ui.bed_details,Vector2(110,30),Vector2(704,138))
 place(ui.bed_button,Vector2(840,38),Vector2(370,44));ui.bed_button.add_theme_font_size_override("font_size",16)
 place(ui.door_items[0],Vector2(14,40),Vector2(82,104))
 place(ui.door_details,Vector2(110,30),Vector2(704,138))
 place(ui.door_button,Vector2(840,38),Vector2(370,44));ui.door_button.add_theme_font_size_override("font_size",16)
 place(ui.actions.repair,Vector2(840,97),Vector2(370,42))
 place(ui.confirmation_icon,Vector2(14,42),Vector2(82,96))
 place(ui.confirmation_details,Vector2(110,30),Vector2(704,138))
 place(ui.confirm_button,Vector2(840,38),Vector2(370,44))
 place(ui.confirmation_items[-1],Vector2(840,97),Vector2(370,42))
 place(ui.specialization_items[0],Vector2(14,24),Vector2(1190,18))
 for i in range(2):
  var b=ui.specialization_items[i+1]
  place(b,Vector2(14+i*610,35),Vector2(596,110))
  b.add_theme_font_size_override("font_size",14)
 place(ui.specialization_items[3],Vector2(14,146),Vector2(280,44))
 if is_instance_valid(ui.branch_confirm):place(ui.branch_confirm,Vector2(840,146),Vector2(370,44))
 idle_hint=ui.label_at("Select a numbered floor pad to build. Select a machine, Bed or Door to inspect actual upgrades.\nGold and Electricity are separate. Purchases and exclusive choices spend only when confirmed.",Vector2(30,40),19,1160,false,ui.context_box)
 idle_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;idle_hint.size.y=116
 refresh()
func fit_action(button: Button):
 if not is_instance_valid(button):return
 var signature=button.text+"|"+str(button.size.x)
 if button.get_meta("price_fit","")==signature:return
 button.set_meta("price_fit",signature)
 var available=button.size.x-button.get_theme_stylebox("normal").get_minimum_size().x-4
 if button.icon!=null:available-=button.get_theme_constant("icon_max_width")+button.get_theme_constant("h_separation")
 var font=button.get_theme_font("font")
 var selected=14
 for size in [16,15,14]:
  if font.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x<=available:selected=size;break
 button.add_theme_font_size_override("font_size",selected)
func refresh():
 if not is_instance_valid(ui.context_box):return
 place(ui.context_box,BODY.position,BODY.size)
 for button in [ui.actions.upgrade,ui.bed_button,ui.door_button]:fit_action(button)
 ui.context_box.visible=ui.context_open
 if is_instance_valid(idle_hint):idle_hint.visible=not ui.context_open
 if ui.context_mode=="specialize":ui.specialization_items[0].visible=false
 if not ui.context_open:ui.context_title.text="YOUR DEFENSES · select a pad or structure"
 # Essential danger remains top-center; secondary guide/items never cover detail.
 if is_instance_valid(ui.guide_box) and ui.context_open:
  ui.guide_box.visible=false;ui.guide_label.visible=false
