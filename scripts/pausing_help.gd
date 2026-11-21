extends RefCounted

const PAGES := [
 ["Getting started","WASD or arrows move. Enter a vacant room and press E to claim it. Press E near the bed to sleep and earn Gold."],
 ["Buildings and Electricity","Press B to open Build. Place a Dynamo on valid floor to produce Electricity. Put a Needle in range of the door. Q rotates the footprint. Esc cancels placement."],
 ["Door and protection","The bar shows your actual door HP. On Phase 20 Campaign, upgrades add up to 22% physical armor. A main-Hunter siege adds 50% Bed Gold. R buys 25 seconds of gradual repair with a 60-second cooldown. F activates the paid Emergency Ward where available."],
 ["Items","Press I to open your equipped items. Choose an item to read its effect and eligibility. Use selected item confirms the transaction. Some items require a target."],
 ["Hunters and damage","Physical and magical attacks use the damage rules below. Neutral damage has no elemental adjustment."],
 ["Story and ranks","Story has 50 levels and separate difficulty tracks. Every fifth level is a checkpoint. Permanent rank comes from lifetime XP. Match rewards appear after settlement."],
 ["Controls and camera","Middle-button drag moves the camera. Scroll zooms. Home returns and locks to your room. M toggles the full map. T opens teammates. G opens this guide and Esc closes it."],
]

# The key and action diagram uses the same icon assets as the HUD.
const EXAMPLES: Array=[
 [["practice","WASD","Move"],["next","E","Claim"],["gold","E at bed","Sleep"]],
 [["build","B","Open Build"],["expansion","Q","Rotate"],["next","Esc","Cancel"]],
 [["iron_gate","Door HP","Inspect"],["repair","R","Repair"],["ward","F","Ward"]],
 [["inventory","I","Open items"],["loadout","1 / 2","Inspect"],["play","Use item","Confirm"]],
 [["ballistic","Needle","Physical"],["electric","Arc","Magical"]],
 [["play","Story","50 levels"],["rank","Rank","Lifetime XP"]],
 [["focus","Middle drag","Pan"],["next","Home","My room"],["expansion","M","Map"]],
]
var examples: Array=[]
var game
var root: Control
var title: Label
var copy: Label
var exit_action: Callable
var navigation: Array[Button]=[]

func _init(owner) -> void:
 game=owner

func open(pausing: bool=true,on_exit: Callable=Callable()) -> void:
 var ui=game.ui
 exit_action=game.close_pausing_help if pausing else on_exit
 root=Control.new()
 root.name="PausingHelp"
 root.size=Vector2(1280,720)
 root.mouse_filter=Control.MOUSE_FILTER_STOP
 root.z_index=100
 ui.panel.add_child(root)
 ui.box(Rect2(0,0,1280,720),"111722","111722",root).mouse_filter=Control.MOUSE_FILTER_STOP
 ui.theme_panel(Rect2(117,75,1046,568),"settings",root)
 ui.theme_label("SURVIVAL GUIDE",Vector2(153,104),34,845,"text",true,root)
 if pausing:ui.theme_label("MATCH PAUSED",Vector2(153,151),16,845,"gold",true,root)
 for index in range(PAGES.size()):
  var tab: Button=ui.button(PAGES[index][0],Vector2(154,196+index*49),func():select(index),275,43,root)
  ui.theme_button(tab,"settings")
  navigation.append(tab)
 title=ui.theme_label("",Vector2(462,198),25,650,"text",true,root)
 copy=ui.theme_label("",Vector2(462,243),19,640,"text",false,root)
 copy.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 if ui.use_tactical_ui():
  var scroller:=ScrollContainer.new()
  scroller.position=Vector2(462,240)
  scroller.size=Vector2(643,169)
  scroller.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
  root.add_child(scroller)
  copy.reparent(scroller,false)
  copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  copy.add_theme_font_size_override("font_size",24 if ui.large_reading_text else 21)
  for i in range(3):
   var tile: Panel=ui.theme_panel(Rect2(462+i*215,428,204,98),"card",root)
   var icon: TextureRect=ui.premium_icon("build",Vector2(14,14),Vector2(33,33),tile)
   var keycap: Label=ui.theme_label("",Vector2(56,10),20,139,"gold",false,tile)
   var caption: Label=ui.theme_label("",Vector2(15,51),20,177,"text",false,tile)
   examples.append([tile,icon,keycap,caption])
  for tab in navigation:tab.alignment=HORIZONTAL_ALIGNMENT_LEFT
 var resume: Button=ui.button("Resume game [Esc]" if pausing else "Back [Esc]",Vector2(849,562),leave,273,48,root)
 ui.theme_button(resume,"primary")
 resume.grab_focus()
 select(0)

func select(index: int) -> void:
 if game.ui.use_tactical_ui():
  for i in range(navigation.size()):game.ui.theme_button(navigation[i],"settings" if i==index else "secondary")
 for i in range(examples.size()):
  var visible_example: bool=i<EXAMPLES[index].size()
  examples[i][0].visible=visible_example
  if visible_example:
   var data: Array=EXAMPLES[index][i]
   examples[i][1].texture=PremiumButton.texture(data[0])
   examples[i][2].text=data[1]
   examples[i][3].text=data[2]
 if copy.get_parent() is ScrollContainer:copy.get_parent().scroll_vertical=0
 title.text=PAGES[index][0]
 copy.text=PAGES[index][1]
 if index==4:
  var lines:=PackedStringArray()
  for id in StrategyCatalog.ARCHETYPE_IDS:
   var affinity:=DamageRules.affinity(id)
   var counters:=PackedStringArray()
   for element in DamageRules.ELEMENTS:
    if DamageRules.multiplier(element,affinity)>1.0:counters.append(element.capitalize())
   lines.append("%s · %s%s" % [HunterIdentity.display(id),affinity.capitalize()," · Vulnerable to "+", ".join(counters) if not counters.is_empty() else ""])
  copy.text+="\n\n"+ "\n".join(lines)+"\n\nStrong elements deal +15%; resisted elements deal −10%."

func leave() -> void:
 if exit_action.is_valid():exit_action.call()

func close() -> void:
 if is_instance_valid(root):
  root.hide()
  root.queue_free()
