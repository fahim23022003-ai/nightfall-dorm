extends RefCounted
## One persistent meter inside the existing door button, with secondary cards on demand.

const FILLS := [Color("64C98F"), Color("E0A64B"), Color("CF5B69")]
var ui
var meter: ProgressBar
var fills: Array[StyleBoxFlat] = []
var band := -1
var objective: Label
var traits_button: Button
var traits: Panel
var trait_title: Label
var benefit: Label
var drawback: Label
var traits_open := false
var repair_until := 0.0
var repair_message := ""

func _init(owner) -> void:
 ui=owner

func install() -> void:
 ui.theme_button(ui.quick_repair,"protection")
 ui.theme_button(ui.room_door_summary,"protection")
 if ui.game.model.player_first_requested:
  ui.room_door_summary.icon=null
  ui.room_door_summary.add_theme_font_size_override("font_size",13)
 meter=ProgressBar.new()
 meter.name="player_door_integrity"
 meter.mouse_filter=Control.MOUSE_FILTER_IGNORE
 meter.show_percentage=false
 meter.max_value=1.0
 meter.step=0.0
 meter.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
 meter.offset_left=9
 meter.offset_right=-9
 meter.offset_top=-8
 meter.offset_bottom=-3
 meter.add_theme_stylebox_override("background",ui.meter_style(Color("121A21")))
 for color in FILLS:
  fills.append(ui.meter_style(color))
 ui.room_door_summary.add_child(meter)
 if ui.game.tutorial_active:return
 ui.guide_box.position=Vector2(20,146)
 ui.guide_box.size=Vector2(320,66)
 ui.guide_box.add_theme_stylebox_override("panel",GothicTheme.living_surface("settings"))
 objective=ui.theme_label("OBJECTIVE",Vector2(32,151),12,280,"settings",true)
 ui.guide_label.position=Vector2(32,168)
 ui.guide_label.size=Vector2(294,40)
 ui.guide_label.add_theme_font_size_override("font_size",14)
 traits_button=ui.button("Room effects",Vector2(20,218),toggle_traits,320,34)
 ui.theme_button(traits_button,"settings")
 traits=ui.theme_panel(Rect2(20,257,320,78),"card")
 trait_title=ui.theme_label("",Vector2(12,5),14,296,"text",true,traits)
 benefit=ui.theme_label("",Vector2(12,25),13,296,"success",false,traits)
 drawback=ui.theme_label("",Vector2(12,45),13,296,"danger",false,traits)

func toggle_traits() -> void:
 traits_open=not traits_open
 ui.update_match()

func repaired(amount: float) -> void:
 repair_until=ui.game.presentation.clock+2.0
 repair_message="+%s HP · door repaired" % WeaponFeedback.format_damage(amount)

func refresh(room, repair_reason: String) -> void:
 var status: bool=room!=null and not ui.game.tutorial_active
 meter.visible=status
 if not is_instance_valid(objective):return
 var drawer: bool=ui.items_ui.expanded
 var secondary: bool=not drawer and not ui.game.full_map and not ui.game.tutorial_active and ui.pause_items.is_empty()
 var room_effect: Dictionary=StrategyCatalog.TRAITS.get(room.trait_id,{}) if room!=null else {}
 traits_button.visible=secondary and not room_effect.is_empty()
 traits.visible=traits_button.visible and traits_open
 traits_button.text="Hide room effects" if traits_open else "Room effects"
 if traits.visible:
  trait_title.text=room_effect.name
  benefit.text=room_effect.benefit
  drawback.text=room_effect.drawback
 if not ui.game.tutorial_active:
  ui.guide_box.visible=secondary
  ui.guide_label.visible=secondary
  objective.visible=secondary
  if secondary:
   if ui.game.presentation.clock<repair_until:
    ui.guide_label.text=repair_message
   elif ui.game.presentation.clock>=ui.feedback_until and not ui.help_open:
    ui.guide_label.text="Find a vacant room · [E] Claim" if room==null else "Reach your bed · [E] Sleep" if not room.sleeping else "Survive the night · [B] Build · [R] Repair"
 else:
  objective.visible=false
 if not status:
  return
 var hp01:=clampf(room.door_hp/maxf(1.0,room.max_hp()),0.0,1.0)
 meter.value=hp01
 meter.modulate=Color(1.0,.82,.82) if room.damage_flash>0.0 else Color.WHITE
 var next_band:=0 if hp01>.65 else 1 if hp01>.30 else 2
 if next_band!=band:
  band=next_band
  meter.add_theme_stylebox_override("fill",fills[band])
 ui.room_door_summary.text="Destroyed · 0 HP" if hp01==0.0 else "Door %s/%s HP · %d%%" % [roundi(room.door_hp),roundi(room.max_hp()),roundi(hp01*100)]
 ui.room_door_summary.tooltip_text="Room %02d · Door level %d" % [room.index+1,room.door_level+1]
 ui.quick_repair.tooltip_text=repair_reason if repair_reason!="" else "Repair your door [R]"
 if ui.game.model.uses_player_door_survival():
  var recovery: PlayerDoorSurvival=ui.game.model.door_survival
  ui.room_door_summary.text+=" · Armor %d%%" % roundi(PlayerDoorSurvival.armor(room.door_level)*100)
  ui.room_door_summary.tooltip_text+=" · Physical armor"
  if room.fear_bed_multiplier>1.0:
   ui.room_bed_summary.text="Fear ×1.5 · %.1f G/s" % (room.income_rate()*room.fear_bed_multiplier)
   ui.room_bed_summary.tooltip_text="Main Hunter siege grants +50% Bed Gold. Electricity is unchanged."
  if recovery.remaining>0.0:
   ui.quick_repair.text="Repair %ds · +%d HP" % [ceili(recovery.remaining),roundi(recovery.restored)]
   ui.quick_repair.tooltip_text="Cooldown %ds. %d real HP restored." % [ceili(maxf(0.0,recovery.ready_at-ui.game.model.time)),roundi(recovery.restored)]
  elif repair_reason!="":ui.quick_repair.text=repair_reason
  else:ui.quick_repair.text="Repair %.0f G [R]" % recovery.price(room)
  return
 if repair_reason.begins_with("Need"):
  ui.quick_repair.text=repair_reason
 elif hp01==0.0:
  ui.quick_repair.text="Door destroyed"
 elif hp01>=1.0:
  ui.quick_repair.text="Door at full health"
