extends RefCounted
var ui
var shortcut: Button
var controls=[]
var info: Label
var purchase_button: Button
func _init(owner):ui=owner
func create():
 shortcut=ui.button("Expand room",Vector2(1005,2),open,175,28,ui.context_box);shortcut.add_theme_font_size_override("font_size",14)
 controls.append(ui.premium_icon("expansion",Vector2(24,50),Vector2(88,105),ui.context_box))
 info=ui.label_at("",Vector2(140,40),17,660,false,ui.context_box);info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;info.size.y=145;controls.append(info)
 purchase_button=ui.button("Purchase expansion",Vector2(840,40),purchase,370,44,ui.context_box);controls.append(purchase_button)
 controls.append(ui.button("Back to buildings",Vector2(840,100),ui.open_build_menu,370,42,ui.context_box))
 refresh()
func open():
 if ui.game.watched_room>=0 or ui.game.model.run_kind!="endless" or ui.game.model.player()==null:return
 ui.context_open=true;ui.context_mode="expansion";ui.refresh_context()
func purchase():
 var m=ui.game.model
 var ok=m.expansion.purchase(m)
 if ok:ui.game.audio_event("prestige_upgrade");ui.game.focus_camera(false)
 ui.purchase(ok);refresh()
func refresh():
 if not is_instance_valid(shortcut):return
 var m=ui.game.model;var r=m.player();var applicable=m.run_kind=="endless" and r!=null
 shortcut.visible=applicable and ui.context_open and ui.context_mode!="expansion"
 var active=applicable and ui.context_open and ui.context_mode=="expansion"
 for control in controls:control.visible=active
 if not active:return
 ui.context_title.text="ENDLESS ROOM · PHYSICAL EXPANSION"
 var tier=r.expansion_tier;var next=mini(7,tier+1);var cost=RoomExpansion.COSTS[next];var reason=m.expansion.reason(m,r.index)
 info.text="%s · capacity %d buildings\n%s\n%s\nExisting buildings, doorway and occupied bed stay in place.\nExpansion is permanent for this run; machine coupons stay armed." % [RoomExpansion.NAMES[tier],r.tile_count(),"ULTIMATE CAPACITY · 16 BUILDINGS" if tier>=7 else "Next: %s · capacity %d" % [RoomExpansion.NAMES[next],RoomExpansion.SLOTS[next]],reason if reason!="" else "Ready · %.0f Gold + %.0f Electricity" % [cost.x,cost.y]]
 purchase_button.text="MAXIMUM ROOM" if tier>=7 else "Expand — %.0f Gold / %.0f Electricity" % [cost.x,cost.y]
 purchase_button.disabled=reason!="";purchase_button.tooltip_text=reason if reason!="" else "Pay once to physically extend this room and increase capacity and unlock the new floor."
 if ui.bottom_context!=null:ui.bottom_context.fit_action(purchase_button)
