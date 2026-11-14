class_name RunChoiceInterface
extends RefCounted
static func show(ui):
 var m=ui.game.model
 if m.balance_version!=2 or m.run_kind!="endless":return
 if m.endless.phase!="intermission":
  if is_instance_valid(ui.run_panel):ui.run_panel.visible=not ui.run_panel.visible
  return
 var c=m.choices;c.prepare(m)
 ui.replay_ui.page("RUN CHOICES · EARNED POWER","Optional. One perk from3 at waves1/4/8/13/19/26; limited supplies every intermission. Gold/Electricity spent here cannot buy infrastructure. All expire with this run.","run_choices")
 var y=184
 if not c.draft.is_empty():
  for i in range(c.draft.size()):
   var id=c.draft[i];var d=RunChoices.CATALOG[id];var x=107+i*362
   ui.box(Rect2(x,y,342,142));ui.icon(d.icon,Vector2(x+12,y+10),Vector2(28,28)) if d.icon in Catalog.BUILDINGS else ui.premium_icon("endless",Vector2(x+12,y+10),Vector2(28,28))
   ui.label_at(d.name,Vector2(x+48,y+10),20,280,true)
   var l=ui.label_at("",Vector2(x+12,y+44),14,316);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.text=d.text;l.set_deferred("size",Vector2(316,62))
   ui.button("Choose · "+d.name,Vector2(x+12,y+108),func():ui.game.run_transaction("choose",id),316,30)
 else:ui.label_at("No pending draft. Active perks: "+summary(c),Vector2(107,y+20),16,1060)
 ui.label_at("MERCHANT · current-run stock only · no rerolls · failed actions spend nothing",Vector2(107,343),16,1060,true)
 for i in range(c.offers.size()):
  var offer=c.offers[i];var id=offer.id;var d=ItemCatalog.ITEMS[id];var x=107+i*362
  ui.box(Rect2(x,373,342,145));ui.label_at(d.name,Vector2(x+12,383),20,316,true)
  var l=ui.label_at("",Vector2(x+12,414),13,316);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.text=d.get("description",d.get("effect","Existing consumable · activate during combat from Run Supplies [K]."));l.set_deferred("size",Vector2(316,42))
  var b=ui.button("Buy %s · %.0fG / %.0fE · ×%d" % [id.capitalize(),offer.gold,offer.power,offer.left],Vector2(x+12,473),func():ui.game.run_transaction("buy",id),316,32)
  b.add_theme_font_size_override("font_size",13)
  b.disabled=offer.left==0 or m.player().gold<offer.gold or m.player().electricity<offer.power or int(c.stock.get(id,0))>=3
  b.tooltip_text="Maximum3 carried per item; actual existing item restrictions apply. Temporary supplies never enter permanent inventory."
 ui.label_at("Active: "+summary(c),Vector2(107,539),13,1060)
 ui.button("Decline draft / keep supplies",Vector2(107,574),func():ui.game.run_transaction("decline",""),515,36)
 ui.button("Back · aid and Omens",Vector2(647,574),ui.replay_ui.show_intermission,528,36)
 ui.label_at("Fewer than3 eligible perks: remaining options only. With none, continue normally. Charges do not refresh on reload.",Vector2(107,633),13,1060)
static func summary(c) -> String:
 var names=[]
 for id in c.selected:names.append(RunChoices.CATALOG[id].name+(" (used)" if id in ["latch","reserve"] and int(c.used.get(id,0))>0 else " · %d left" % maxi(0,3-int(c.used.get(id,0))) if id=="grid" else ""))
 return ", ".join(names) if not names.is_empty() else "None yet"
static func attach(ui):
 var m=ui.game.model
 if m.balance_version!=2 or m.run_kind!="endless":return
 var open=ui.button("Run supplies [K]",Vector2(20,92),func():show(ui),160,34);open.add_theme_font_size_override("font_size",12)
 ui.run_panel=ui.box(Rect2(20,260,330,330));ui.run_panel.mouse_filter=Control.MOUSE_FILTER_STOP;ui.run_panel.visible=false
 ui.label_at("CURRENT RUN · temporary",Vector2(12,8),16,275,true,ui.run_panel)
 ui.button("×",Vector2(294,5),func():ui.run_panel.visible=false,28,28,ui.run_panel)
 var text=ui.label_at("",Vector2(12,35),12,300,false,ui.run_panel);text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.text=summary(m.choices);text.set_deferred("size",Vector2(300,78))
 ui.run_panel.set_meta("summary",text)
 text.tooltip_text="\n".join(m.choices.selected.map(func(id):return RunChoices.CATALOG[id].text))
 var ids=RunChoices.ITEMS.duplicate();ids.append("reserve")
 for i in range(ids.size()):
  var id=ids[i];var b=ui.button("Use "+(ItemCatalog.ITEMS[id].name if id in ItemCatalog.ITEMS else "Reserve Cell"),Vector2(10,115+i*32),func():ui.game.use_run_stock(id),310,29,ui.run_panel)
  b.add_theme_font_size_override("font_size",13);ui.actions["run:"+id]=b
static func refresh(ui):
 var m=ui.game.model
 if m.balance_version!=2 or m.run_kind!="endless":return
 if is_instance_valid(ui.run_panel) and ui.run_panel.has_meta("summary"):ui.run_panel.get_meta("summary").text=summary(m.choices)
 for id in RunChoices.ITEMS+["reserve"]:
  var b=ui.actions.get("run:"+id)
  if not is_instance_valid(b):continue
  var count=int(m.choices.stock.get(id,0)) if id!="reserve" else 1 if m.choices.has("reserve") and int(m.choices.used.get("reserve",0))==0 else 0
  b.disabled=count==0 or (m.items.can_activate(id,m)!="" if id!="reserve" else m.player()==null or m.player().door_hp<=0 or m.player().door_hp>=m.player().max_hp()*.4)
  b.text="Use "+(ItemCatalog.ITEMS[id].name if id in ItemCatalog.ITEMS else "Reserve Cell")+" ×%d" % count
  b.tooltip_text=m.items.can_activate(id,m) if id!="reserve" else RunChoices.CATALOG.reserve.text
