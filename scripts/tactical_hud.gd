extends RefCounted
## Desktop presentation of the same actions, with one active transient panel.

var ui
var game
var more: Button
var menu: Panel
var objective: Label
var tool_summary: Label
var place_tool: Button
var tool_icon: TextureRect
var toast_key:=""
var toast_until:=0.0

func _init(interface) -> void:
 ui=interface
 game=ui.game

func arrange(control: Control,at: Vector2,extent: Vector2) -> void:
 control.position=at
 control.size=extent

func install(top: Panel,brand: Label,help: Button,gold_icon: Control,gold_caption: Label,power_icon: Control,power_caption: Label) -> void:
 var colors:=GothicTheme.palette()
 top.add_theme_stylebox_override("panel",GothicTheme.living_surface("frame"))
 brand.hide()
 help.hide()
 ui.map_button.hide()
 for pair in [[gold_icon,Vector2(36,30)],[gold_caption,Vector2(78,13)],[ui.gold_label,Vector2(78,34)],
  [power_icon,Vector2(217,27)],[power_caption,Vector2(257,13)],[ui.power_label,Vector2(257,34)],
  [ui.phase_label,Vector2(443,18)],[ui.hunter_label,Vector2(630,14)],[ui.hunter_bar,Vector2(630,49)],
  [ui.hunter_detail,Vector2(630,57)]]:
  pair[0].position=pair[1]
 for count in [gold_caption,power_caption]:
  count.add_theme_font_size_override("font_size",14)
  count.modulate=colors.muted
 ui.hunter_label.size.x=440
 ui.hunter_detail.size.x=440
 ui.hunter_detail.clip_text=true
 ui.hunter_detail.add_theme_font_size_override("font_size",14)
 ui.hunter_bar.set_deferred("size",Vector2(440,8))
 ui.hunter_bar.add_theme_stylebox_override("fill",ui.meter_style(colors.danger))
 ui.pause_button.text="Menu"
 arrange(ui.pause_button,Vector2(1121,23),Vector2(122,42))
 ui.theme_button(ui.pause_button,"quiet","pause")
 ui.room_dock.add_theme_stylebox_override("panel",GothicTheme.living_surface("frame"))
 arrange(ui.room_dock,Vector2(342,653),Vector2(596,56))
 arrange(ui.room_selected_summary,Vector2(350,659),Vector2(134,44))
 arrange(ui.quick_repair,Vector2(494,659),Vector2(142,44))
 arrange(ui.items_ui.item_toggle,Vector2(646,659),Vector2(136,44))
 ui.theme_button(ui.quick_repair,"protection","repair")
 more=ui.button("More",Vector2(792,659),toggle_more,138,44)
 more.name="tactical_more"
 ui.theme_button(more,"settings","settings")
 for action: Button in [ui.room_selected_summary,ui.quick_repair,ui.items_ui.item_toggle,more]:
  action.add_theme_font_size_override("font_size",19)
  action.clip_text=true
 arrange(ui.room_door_summary,Vector2(20,653),Vector2(310,56))
 ui.room_door_summary.add_theme_font_size_override("font_size",19)
 ui.room_door_summary.clip_text=true
 arrange(ui.teammates.home,Vector2(350,659),Vector2(134,44))
 ui.teammates.home.text="My room"
 ui.details.hide()
 ui.room_bed_summary.hide()
 ui.bottom_context.upgrade_shortcut.hide()
 ui.guide_box.hide()
 ui.guide_label.hide()
 arrange(ui.warning_box,Vector2(390,85),Vector2(500,40))
 ui.warning_box.add_theme_stylebox_override("panel",GothicTheme.living_surface("danger"))
 arrange(ui.warning_label,Vector2(406,90),Vector2(468,30))
 ui.warning_label.clip_text=true
 objective=ui.theme_label("",Vector2(30,91),17,328,"muted")
 objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 install_menu()
 install_tool()

func install_menu() -> void:
 menu=ui.theme_panel(Rect2(825,258,423,366),"frame")
 menu.mouse_filter=Control.MOUSE_FILTER_STOP
 ui.theme_label("ROOM UTILITIES",Vector2(18,12),19,288,"gold",true,menu)
 ui.theme_button(ui.button("Close",Vector2(320,8),toggle_more,86,34,menu),"quiet")
 var entries: Array=[
  ["Map [M]",game.toggle_map,"settings"],["Spectate [T]",ui.teammates.toggle_panel,"secondary"],
  ["Free look",free_look,"secondary"],["Lock my room [Home]",game.return_to_my_room,"secondary"],
  ["Find machines",game.construction.toggle_machines,"secondary"],["Bed & income",func():ui.open_room_panel("bed"),"secondary"],
  ["Room effects",toggle_room_info,"secondary"],["Help [G]",game.toggle_guide,"settings"],
  ["Settings",ui.open_match_settings,"settings"],
 ]
 for i in range(entries.size()):
  var entry: Array=entries[i]
  var action: Callable=entry[1]
  var callback:=func():
   menu.hide()
   action.call()
  var control: Button=ui.button(entry[0],Vector2(15+(i%2)*200,54+floori(float(i)/2)*56),callback,193,46,menu)
  control.name=["utility_map","utility_spectate","utility_camera","utility_lock","utility_machines","utility_bed","utility_room","utility_help","utility_settings"][i]
  ui.theme_button(control,entry[2])
 if is_instance_valid(ui.ward_button):
  ui.ward_button.reparent(menu,false)
  arrange(ui.ward_button,Vector2(215,278),Vector2(193,46))
  ui.theme_button(ui.ward_button,"protection","ward")
 menu.hide()

func install_tool() -> void:
 var frame: Panel=ui.grid_placement_banner
 arrange(frame,Vector2(878,457),Vector2(370,176))
 frame.mouse_filter=Control.MOUSE_FILTER_STOP
 arrange(ui.grid_placement_label,Vector2(58,10),Vector2(303,30))
 ui.grid_placement_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
 ui.grid_placement_label.clip_text=true
 tool_icon=ui.premium_icon("build",Vector2(14,14),Vector2(32,32),frame)
 tool_summary=ui.theme_label("",Vector2(18,48),15,334,"muted",false,frame)
 tool_summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 tool_summary.size.y=67
 var rotate: Button=game.construction.rotate_button
 rotate.reparent(frame,false)
 arrange(rotate,Vector2(14,122),Vector2(102,40))
 ui.theme_button(rotate,"settings")
 place_tool=ui.button("Place",Vector2(125,122),confirm,102,40,frame)
 ui.theme_button(place_tool,"primary")
 arrange(ui.grid_placement_cancel_button,Vector2(236,122),Vector2(120,40))
 ui.grid_placement_cancel_button.clip_text=true
 ui.grid_placement_cancel_button.set_deferred("size",Vector2(120,40))

func confirm() -> void:
 if not place_tool.disabled:
  game.construction.confirm(game.construction.point)

func free_look() -> void:
 if game.full_map:game.toggle_map()
 if game.watched_room>=0:game.return_to_my_room()
 game.phase20_camera_anchor=game.camera.position
 game.phase20_free_camera=true

func dismiss(keep: String="") -> void:
 if keep!="more" and is_instance_valid(menu):menu.hide()
 if keep!="items" and ui.items_ui.expanded:
  ui.items_ui.expanded=false
  if is_instance_valid(ui.items_ui.drawer):ui.items_ui.drawer.hide()
 if keep!="team":ui.teammates.expanded=false
 if keep!="machines":game.construction.machines_open=false
 if keep!="room" and ui.living_dorm_hud!=null:ui.living_dorm_hud.traits_open=false
 if keep!="context" and ui.context_open:ui.close_context()

func dismiss_escape() -> bool:
 if menu.visible:
  menu.hide()
  more.grab_focus()
  return true
 if ui.items_ui.expanded:
  ui.items_ui.toggle_expanded()
  ui.items_ui.item_toggle.grab_focus()
  return true
 if ui.teammates.expanded or game.construction.machines_open or ui.living_dorm_hud.traits_open:
  dismiss()
  ui.update_match()
  return true
 return false

func toggle_more() -> void:
 var show_menu:=not menu.visible
 if show_menu:
  dismiss("more")
  if game.construction.active():game.cancel_placement()
 menu.visible=show_menu
 if show_menu:menu.get_node("utility_map").grab_focus()
 else:more.grab_focus()

func toggle_room_info() -> void:
 var open: bool=not ui.living_dorm_hud.traits_open
 dismiss("room")
 ui.living_dorm_hud.traits_open=open
 ui.update_match()

func refresh(room: RoomState) -> void:
 var tutorial: bool=game.tutorial_active
 var placing: bool=game.construction.active()
 var auxiliary: bool=not tutorial and not placing and not ui.context_open and not game.full_map and not ui.items_ui.expanded and ui.pause_items.is_empty()
 ui.guide_box.hide()
 ui.guide_label.hide()
 if is_instance_valid(ui.living_dorm_hud.objective):ui.living_dorm_hud.objective.hide()
 if is_instance_valid(ui.living_dorm_hud.traits_button):
  ui.living_dorm_hud.traits_button.hide()
 ui.teammates.toggle.hide()
 game.construction.machine_button.hide()
 ui.room_bed_summary.hide()
 ui.bottom_context.upgrade_shortcut.hide()
 ui.details.hide()
 more.visible=not tutorial
 ui.items_ui.item_toggle.visible=not tutorial
 ui.room_dock.visible=not tutorial
 ui.quick_repair.visible=not tutorial
 ui.room_door_summary.visible=room!=null and not tutorial
 if ui.room_door_summary.visible and room.door_hp>0.0:
  var armor: int=roundi(PlayerDoorSurvival.armor(room.door_level)*100) if game.model.uses_player_door_survival() else 0
  ui.room_door_summary.text="Door %s/%s · Armor %d%%" % [ui.resource_text(room.door_hp),ui.resource_text(room.max_hp()),armor]
 if tutorial:ui.room_selected_summary.position.x=573
 objective.visible=auxiliary and not menu.visible and not ui.teammates.expanded and game.profile.settings.guidance_mode=="show"
 if objective.visible:
  var task: String="Claim a vacant room [E]" if room==null else "Reach your bed and sleep [E]" if not room.sleeping else ""
  if room!=null and room.fear_bed_multiplier>1.0:task="Siege income · Bed Gold ×1.5"
  if ui.feedback_until>game.presentation.clock and not ui.warning_box.visible and ui.feedback_text!="Defense improved!":task=ui.feedback_text
  objective.text=task
  objective.visible=not task.is_empty()
 if not tutorial:
  ui.items_ui.item_toggle.text="Items ×%d" % ui.items_ui.hotbar.size()
  ui.quick_repair.text="Repair"
  var repair: PlayerDoorSurvival=game.model.door_survival
  if game.model.uses_player_door_survival():
   if repair.remaining>0.0:ui.quick_repair.text="Repair · %ds" % ceili(repair.remaining)
   elif game.model.time<repair.ready_at:ui.quick_repair.text="Repair · %ds" % ceili(repair.ready_at-game.model.time)
  ui.room_selected_summary.text="Build"
  ui.hunter_label.text+="  ·  %s / %s" % [ui.resource_text(game.model.hunter.hp),ui.resource_text(game.model.hunter.max_hp)] if not "/" in ui.hunter_label.text else ""
  if ui.hunter_detail.text.begins_with("Evolution ") and " HP" in ui.hunter_detail.text:
   ui.hunter_detail.text=ui.hunter_detail.text.get_slice(" · ",0)
 var note: String=ui.warning_label.text if ui.warning_box.visible else ""
 if note.begins_with("DOOR ") and "UNDER ATTACK" in note:note="Hunter at your door"
 if note.begins_with("CRITICAL DOOR"):note="Critical door · Repair when available"
 if room!=null and room.door_hp>0.0 and room.door_hp<=room.max_hp()*.30 and not tutorial:
  note="Critical door · Repair when available"
  ui.warning_box.show()
  ui.warning_label.show()
 if game.model.run_kind=="endless":
  ui.phase_label.text="Wave %d" % game.model.endless.wave
  if is_instance_valid(ui.replay_ui.wave_label):
   ui.replay_ui.wave_label.position=Vector2(443,47)
   ui.replay_ui.wave_label.size=Vector2(186,28)
   ui.replay_ui.wave_label.clip_text=true
  if is_instance_valid(ui.replay_ui.omen_icon):ui.replay_ui.omen_icon.position=Vector2(413,47)
 if note!=toast_key:
  toast_key=note
  toast_until=game.presentation.clock+3.0
 ui.warning_label.text=note
 if tutorial and game.onboarding!=null and not game.model.running or note=="Hunter at your door" and game.presentation.clock>toast_until:
  ui.warning_box.hide()
  ui.warning_label.hide()
 if placing and ui.grid_placement_banner.visible:
  var control=game.construction
  var kind: String=control.active_kind()
  var moving: bool=control.moving>=0
  var extent: Vector2=room.spatial.footprint_for(control.point,kind,control.rotation).size/SpatialConstruction.CELL_SIZE
  var price: Vector2=Vector2.ZERO if moving else room.quote_build(kind)
  var fee: String="Move existing machine" if moving else "%s G · %s E" % [ui._price_amount(price.x),ui._price_amount(price.y)]
  ui.grid_placement_label.text=Catalog.BUILDINGS[kind].name
  ui.grid_placement_cancel_button.text="Cancel"
  tool_icon.texture=game.presentation.textures[kind]
  var error: String=control.current_preview_error
  tool_summary.text="%s · %d×%d cells · %d°\n%s" % [fee,int(extent.x),int(extent.y),control.rotation*90,"Ready · click the floor or Place" if error=="" else error]
  tool_summary.modulate=GothicTheme.palette().muted if error=="" else Color("FFADB6")
  place_tool.disabled=error!=""
  place_tool.text="Move" if moving else "Place"
