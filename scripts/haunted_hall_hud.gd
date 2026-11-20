extends RefCounted
## Observing changes only the camera. The room and its active placement remain intact.
var ui
var shield: Control
var banner: Panel
var title: Label
var status: Label
var watch: Button

func _init(interface):
 ui=interface
 shield=Control.new()
 shield.mouse_filter=Control.MOUSE_FILTER_STOP
 ui.attach(shield)
 shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shield.hide()
 banner=ui.box(Rect2(382,84,516,51),"221E31","847393")
 title=ui.label_at("",Vector2(14,-1),13,336,true,banner)
 title.clip_text=true
 status=ui.label_at("",Vector2(14,19),12,334,false,banner)
 status.modulate=Color("D6C7E5")
 status.clip_text=true
 watch=ui.button("WATCH HUNTER",Vector2(352,8),_toggle,152,35,banner)
 watch.add_theme_font_size_override("font_size",13)
 update()

func _toggle():
 if ui.game.hunter_spectating:ui.game.return_from_hunter()
 else:ui.game.watch_hunter()

func update():
 var game=ui.game
 var recovery=game.model.get("haunt_recovery")
 var observing: bool=game.hunter_spectating
 var active: bool=recovery!=null and recovery.phase in ["retreat","recover"]
 var play_screen: bool=ui.current_screen=="match" and ui.pause_items.is_empty()
 shield.visible=observing and play_screen
 banner.visible=play_screen and (observing or active)
 if not banner.visible:return
 banner.position.y=140 if ui.warning_box.visible else 84
 if is_instance_valid(ui.upgrade_notice) and banner.position.y==140:ui.upgrade_notice.visible=false
 if observing:
  ui.guide_box.hide()
  ui.guide_label.hide()
  ui.context_box.hide()
  if is_instance_valid(ui.run_panel):ui.run_panel.hide()
  if is_instance_valid(ui.teammates.body):ui.teammates.body.hide()
 watch.text="RETURN [HOME]" if observing else "WATCH HUNTER"
 watch.tooltip_text="Return to your own room and resume any unfinished placement." if observing else "Follow the Hunter's live position and HP. Building selection and placement are kept."
 if not active:
  title.text="WATCHING THE HUNTER"
  status.text="%d / %d HP · Returning to combat" % [roundi(game.model.hunter.hp),roundi(game.model.hunter.max_hp)]
  return
 var hall: Dictionary=game.model.map_data.get("halls",{}).get(recovery.hall_id,{})
 var place := str(hall.get("name","HAUNTED HALL")).to_upper()
 title.text="HUNTER RETREAT DETECTED" if recovery.phase=="retreat" else "HUNTER RECOVERING — "+place
 if recovery.phase=="retreat":
  status.text="Heading to "+str(hall.get("name","a Haunted Hall"))
 else:
  status.text="%d / %d HP · +%d restored" % [roundi(game.model.hunter.hp),roundi(game.model.hunter.max_hp),roundi(float(recovery.healed))]
