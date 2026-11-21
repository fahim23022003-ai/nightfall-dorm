extends RefCounted

# Desktop inspector. All amounts and transactions belong to the existing match.
var ui
var plate: Panel
var grade: Label
var operation: Label
var contribution: Label
var upgrade_value: Label
var requirement: Label
var details_button: Button
var confirm_card: Panel
var refund_text: Label
var keep: Button
var detail_open := false
var identity := []
var pending_sale := []

func _init(owner):
 ui=owner
 plate=ui.theme_panel(Rect2(-144,0,508,488),"frame",ui.context_box)
 plate.name="MachineInspector"
 plate.mouse_filter=Control.MOUSE_FILTER_STOP
 ui.context_box.move_child(plate,0)
 plate.hide()
 ui.theme_label("MACHINE",Vector2(17,7),15,118,"gold",false,plate)
 ui.theme_panel(Rect2(15,48,478,158),"card",plate)
 grade=ui.theme_label("",Vector2(202,62),18,277,"gold",false,plate)
 grade.clip_text=true
 operation=ui.theme_label("",Vector2(202,97),17,278,"text",false,plate)
 operation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 operation.size.y=55
 contribution=ui.theme_label("",Vector2(202,154),15,278,"secondary",false,plate)
 contribution.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 contribution.size.y=46
 details_button=ui.button("Details",Vector2(389,215),toggle_details,103,36,plate)
 details_button.name="MachineDetails"
 details_button.add_theme_font_size_override("font_size",16)
 upgrade_value=ui.theme_label("",Vector2(18,216),18,360,"text",false,plate)
 upgrade_value.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 upgrade_value.size.y=63
 requirement=ui.theme_label("",Vector2(18,278),16,470,"secondary",false,plate)
 requirement.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 requirement.size.y=40
 confirm_card=ui.theme_panel(Rect2(0,208,508,280),"frame",plate)
 confirm_card.mouse_filter=Control.MOUSE_FILTER_STOP
 var prompt=ui.theme_label("Sell this machine?",Vector2(20,16),22,463,"text",false,confirm_card)
 prompt.name="SaleQuestion"
 refund_text=ui.theme_label("",Vector2(20,59),18,466,"secondary",false,confirm_card)
 refund_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 refund_text.size.y=105
 keep=ui.button("Keep machine",Vector2(18,195),cancel_sale,214,52,confirm_card)
 keep.name="KeepMachine"
 var confirm=ui.button("Confirm sale",Vector2(243,195),confirm_sale,245,52,confirm_card)
 confirm.name="ConfirmSale"
 ui.theme_button(confirm,"danger")
 confirm_card.hide()

func toggle_details():
 detail_open=not detail_open
 ui.refresh_context()

func clear():
 if not plate.visible:return
 plate.hide()
 identity.clear()
 pending_sale.clear()
 detail_open=false
 confirm_card.hide()

func key(room,b) -> Array:
 return [room.index,ui.game.selected_tile,int(b.get("instance_id",-1)),b.kind,b.level,b.get("specialization","")]

func ask_sale():
 var room=ui.game.model.player()
 if room==null or not ui.context_open or ui.context_mode!="upgrade" or not room.buildings.has(ui.game.selected_tile) or ui.action_reason("sell")!="":return
 var b: Dictionary=room.buildings[ui.game.selected_tile]
 pending_sale=key(room,b)
 pending_sale.append(room.building_refund(ui.game.selected_tile))
 ui.refresh_context()
 keep.grab_focus()

func cancel_sale():
 pending_sale.clear()
 ui.refresh_context()
 ui.actions.sell.grab_focus()

func confirm_sale():
 var room=ui.game.model.player()
 if room==null or not plate.is_visible_in_tree() or pending_sale.is_empty() or not room.buildings.has(ui.game.selected_tile):return
 var expected=key(room,room.buildings[ui.game.selected_tile])
 expected.append(room.building_refund(ui.game.selected_tile))
 if pending_sale!=expected or ui.action_reason("sell")!="":
  cancel_sale()
  return
 pending_sale.clear()
 ui.complete_selected_sale()

# Map the first improvement to the same stat used by the current building.
func primary_stat(kind: String,stats: Dictionary) -> Array:
 match kind:
  "barrier":return ["Magic reflected","%.1f%%" % (stats.reflect*100)]
  "plasma":return ["Storage capacity","%.0f HP" % stats.capacity]
  "shield","antenna":return ["Shield capacity","%.0f HP" % stats.capacity]
  "decoy":return ["Lure duration","%.2f s" % stats.duration]
  "auto_repair":return ["Repair per burst","%.1f HP" % stats.heal]
  "generator":return ["Electricity output","%.2f E/s" % stats.rate]
  "repair":return ["Nominal repair","%.2f HP/s" % stats.get("nominal_rate",stats.rate)]
  "enhancer","economy":return ["Output bonus","%.1f%%" % (stats.rate*100)]
 return ["Hit before mitigation","%.1f HP" % stats.hit]

func support_state(room,b: Dictionary,stats: Dictionary) -> String:
 if not ui.game.model.running or not room.alive or not room.sleeping:return "Idle · production paused"
 if b.kind in MagicDefense.KINDS and not is_same(MagicDefense.best(room,b.kind),b):return "Idle · another unit is active"
 if b.kind=="generator":return "Generating electricity" if stats.rate>0 else "Idle · output paused"
 if b.kind=="repair":return "Repair available" if str(stats.get("reason","")).is_empty() else str(stats.reason).capitalize()
 if b.kind in ["economy","enhancer"]:return "Active · room bonus"
 if float(b.get("cooldown",0))>0:return "Recharging"
 return "Ready · awaiting trigger"

func refresh(room,b: Dictionary):
 var model=ui.game.model
 var new_key=key(room,b)
 if identity!=new_key:
  detail_open=false
  pending_sale.clear()
  identity=new_key
  ui.bottom_context.stats_scroll.scroll_vertical=0
 plate.show()
 var branch: String=StrategyCatalog.BRANCHES.get(b.get("specialization",""),{}).get("name","Unmodified")
 grade.text="Level %d  ·  %s" % [b.level,branch]
 grade.tooltip_text=grade.text
 var stats=BuildingStats.machine_stats(model,room,b)
 var current=primary_stat(b.kind,stats)
 var has_receipt: bool=model.weapon_feedback.enabled and (b.kind in DefenseEffects.WEAPONS or b.kind=="barrier")
 if has_receipt:
  var readout=BuildingStats.combat_readout(model,room,ui.game.selected_tile).split("\n")
  operation.text=readout[2]+"\n"+readout[1]
  contribution.text=readout[3]+"\n"+readout[4]
 elif b.kind in DefenseEffects.WEAPONS:
  operation.text="Range %.0f · %.2f s / shot" % [stats.range,stats.interval]
  contribution.text="%s · %s" % current
 else:
  operation.text=support_state(room,b,stats)
  contribution.text="%s · %s" % current
 var maxed: bool=b.level>=Catalog.building_max_level(b.kind)
 var branch_choice: bool=room.strategy_enabled and b.level==4
 var price: Vector2=BalanceRules.upgrade(b.kind,b.level,model.balance_version)
 if branch_choice:price+=StrategyCatalog.BRANCH_FEE
 price=room.building_price(price.x,price.y)
 var reason: String=ui.action_reason("upgrade")
 if maxed:
  upgrade_value.text="%s · %s" % current
  requirement.text="Maximum level reached"
 elif branch_choice:
  upgrade_value.text="Level 5 · choose a specialization"
  var shortfall:=PackedStringArray()
  if room.gold+0.00001<price.x:shortfall.append("%s Gold" % ui._price_amount(price.x-room.gold))
  if room.electricity+0.00001<price.y:shortfall.append("%s Electricity" % ui._price_amount(price.y-room.electricity))
  requirement.text=reason if reason!="" else "To specialize, need %s more." % " + ".join(shortfall) if not shortfall.is_empty() else "Preview both branches before committing."
 else:
  var next_building=b.duplicate()
  next_building.level=b.level+1
  var following=primary_stat(b.kind,BuildingStats.machine_stats(model,room,next_building))
  upgrade_value.text="%s\n%s  →  %s" % [current[0],current[1],following[1]]
  requirement.text=reason if reason!="" else "Upgrade available"
 ui.actions.upgrade.text="Maximum level" if maxed else "%s   ·   %s G / %s E" % ["Preview branches" if branch_choice else "Upgrade to L%d" % (b.level+1),ui._price_amount(price.x),ui._price_amount(price.y)]
 ui.actions.upgrade.disabled=maxed or reason!=""
 ui.actions.sell.text="Sell…"
 var confirming=not pending_sale.is_empty()
 confirm_card.visible=confirming
 if confirming:
  var refund: Vector2=room.building_refund(ui.game.selected_tile)
  refund_text.text="%s L%d will be removed.\nRefund   %.2f Gold  /  %.2f Electricity\nThis sale cannot be undone." % [Catalog.BUILDINGS[b.kind].name,b.level,refund.x,refund.y]
 details_button.visible=not confirming
 details_button.text="Less" if detail_open else "Details"
 upgrade_value.visible=not confirming and not detail_open
 requirement.visible=not confirming and not detail_open
 ui.bottom_context.stats_scroll.visible=detail_open and not confirming
 if detail_open:
  var full_text:=BuildingStats.format_machine(model,room,b)
  if reason!="":full_text+="\n"+reason
  ui.selected_details.text=full_text
 ui.actions.upgrade.visible=not confirming
 ui.actions.sell.visible=not confirming
 ui.actions.upgrade.position=Vector2(-126,327)
 ui.actions.upgrade.size=Vector2(471,48)
 ui.actions.sell.position=Vector2(245,415)
 ui.actions.sell.size=Vector2(100,47)

func arrange_tools(controls,room):
 var selection: Dictionary=room.buildings.get(ui.game.selected_tile,{}) if room!=null else {}
 if selection.is_empty() or not plate.visible:return
 var ordinary: bool=pending_sale.is_empty()
 controls.move_button.visible=controls.move_button.visible and ordinary
 controls.undo_button.visible=controls.undo_button.visible and ordinary and not controls.undo_button.disabled
 controls.range_button.visible=controls.range_button.visible and ordinary and selection.kind in DefenseEffects.WEAPONS
 var left: float=-126.0
 for control: Button in [controls.move_button,controls.range_button,controls.undo_button]:
  if not control.visible:continue
  control.position=Vector2(left,415)
  control.size=Vector2(114,47)
  if control.get_theme_font_size("font_size")!=15:control.add_theme_font_size_override("font_size",15)
  left+=120
