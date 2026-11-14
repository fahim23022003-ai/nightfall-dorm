class_name WaveReportView
extends RefCounted
static var tab="Damage"
static func metric(ui,title,value,at,color="DFC48B"):
 ui.box(Rect2(at,Vector2(244,76)))
 ui.label_at(title,at+Vector2(12,8),14,220).modulate=Color("B8C5C6")
 ui.label_at(value,at+Vector2(12,31),27,220,true).modulate=Color(color)
static func paragraph(ui,text,at=Vector2(125,284),font=20,height=280):
 var label=ui.label_at("",at,font,1010);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.text=text;label.size=Vector2(1010,height);label.set_deferred("size",Vector2(1010,height));return label
static func show(ui,chosen="Damage"):
 tab=chosen;var m=ui.game.model;var d=m.wave_metrics.report();ui.clear();ui.current_screen="wave_report";ui.box(Rect2(90,35,1100,650))
 ui.label_at("WAVE %d · DEFENSE REPORT" % m.endless.completed,Vector2(120,65),30,1030,true)
 if not d.available:
  paragraph(ui,"This checkpoint predates wave telemetry.\nNo historical performance or reasons are inferred.\nContinue to collect a fresh report.",Vector2(125,170));ui.button("Back · wave choices and Omens",Vector2(120,612),ui.replay_ui.show_intermission,1020,42);return
 for i in range(4):metric(ui,["Hunter damage · all rooms","Door damage · your room","Gold generated","Electricity generated"][i],["%.0f" % (d.total+d.allied),"%.0f" % d.door,"%.0f" % d.gold,"%.0f" % d.power][i],Vector2(120+i*258,128),["DFC48B","E3A2A8","DFC48B","8CD6DA"][i])
 var tabs=["Damage","Economy","Defense","Hunter Skills","Insights","Details"]
 for i in range(tabs.size()):
  var value=tabs[i];var button=ui.button(value,Vector2(120+i*172,224),func():show(ui,value),158,38);button.toggle_mode=true;button.button_pressed=value==chosen
 if chosen=="Damage":
  var rows=d.top.duplicate(true)
  for key in d.get("observations",{}):
   var row=d.observations[key]
   if rows.size()<6 and row.kind in DefenseEffects.WEAPONS and not d.buildings.has(key):rows.append({"id":row.id,"kind":row.kind,"level":row.level,"damage":0.0,"hits":0})
  if rows.is_empty():paragraph(ui,"No player weapon impacts recorded.\nAllied damage %.1f · Other player damage %.1f" % [d.allied,d.other])
  var maximum=maxf(1,rows[0].damage) if not rows.is_empty() else 1
  for i in range(rows.size()):
   var row=rows[i];var y=276+i*48;ui.icon(row.kind,Vector2(124,y+2),Vector2(32,32))
   ui.label_at("%d. %s L%d · #%d%s" % [i+1,Catalog.BUILDINGS[row.kind].name,row.level,row.id," · sold/destroyed" if not m.player().buildings.has(int(row.id)) else ""],Vector2(165,y),17,690)
   var value=ui.label_at("%.1f damage · %d hits" % [row.damage,row.hits],Vector2(860,y),16,275);value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
   var bar=ProgressBar.new();bar.position=Vector2(165,y+28);bar.show_percentage=false;bar.max_value=maximum;bar.value=row.damage;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
   bar.add_theme_stylebox_override("background",ui.meter_style(Color("17232B")));bar.add_theme_stylebox_override("fill",ui.meter_style(Color("B5A179")));ui.panel.add_child(bar);bar.size=Vector2(968,8);bar.set_deferred("size",Vector2(968,8))
  var shown=0.0
  for row in rows:shown+=row.damage
  paragraph(ui,"%d shown · Your room %.1f · Allies %.1f · Unshown weapons %.1f · Other sources %.1f" % [rows.size(),d.total,d.allied,maxf(0,d.total-d.other-shown),d.other],Vector2(125,574),13,28)
 elif chosen=="Economy":
  paragraph(ui,"%.2f Gold generated\n%.2f Electricity generated\n\nBeds and income supports generate Gold. Dynamos generate Electricity.\nThese are gross production totals—not wallet changes.\nPurchases, sales, theft, aid and Omen bonuses are excluded.")
 elif chosen=="Defense":
  paragraph(ui,"Door damage received: %.1f HP\nActual repair applied: %.1f HP\nSuccessful defense activations: %d\nMagic damage absorbed: %s\n\nRepair and support are separate from weapon damage.\nExisting statistics without absorption observations remain unknown." % [d.door,d.repair,d.activations,"%.1f HP" % d.magic_blocked if d.has("magic_blocked") else "not recorded"])
 elif chosen=="Hunter Skills":
  var text="No Hunter skill warnings recorded." if d.skills.is_empty() else "Encountered warnings / skills\n\n"+"\n".join(d.skills.map(func(v):return "• "+str(v).replace("_"," ").capitalize()))
  var scroll=ScrollContainer.new();scroll.position=Vector2(125,278);scroll.size=Vector2(1010,307);ui.panel.add_child(scroll)
  var label=Label.new();label.text=text;label.add_theme_font_size_override("font_size",19);scroll.add_child(label)
 elif chosen=="Insights":
  var text="OBSERVED, NOT GUESSED\n\n"
  for insight in WaveOpportunities.insights(d):text+="• "+insight+"\n\n"
  paragraph(ui,text,Vector2(125,280),18,310)
 else:
  paragraph(ui,"Actual impact/DoT amounts, not theoretical DPS. Hits count positive-damage projectile impacts; DoT does not invent extra hits.\n\nWeapon opportunity observations are read-only. No target, out of range and temporary disables are distinguished. Missing history means unknown. Turrets do not spend Electricity per shot.\n\nGross production excludes transfers/rewards. Repair excludes upgrade HP-cap increases. Shared consumable/reflection damage remains Other. Minion damage is excluded from Hunter totals.",Vector2(125,280),18,310)
 ui.button("Back · wave choices and Omens",Vector2(120,612),ui.replay_ui.show_intermission,1020,42)
