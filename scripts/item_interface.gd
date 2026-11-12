extends RefCounted
var ui
var game
var hotbar: Array=[]
var feedback_label
var radar_label
var spin_tween: Tween
var spin_ready=false
var spin_claiming=false
var seen_event=0
var observed_model
var inventory_page=0
var legendary_banner
var legendary_name
var observed_effects
func _init(owner): ui=owner; game=ui.game
func art(id,pos,size=52):
 var icon=TextureRect.new()
 icon.texture=load("res://assets/items/"+id+".svg")
 icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 icon.position=pos; icon.size=Vector2(size,size)
 icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ui.panel.add_child(icon)
 return icon
func inventory():
 ui.clear(); ui.current_screen="inventory"
 ui.box(Rect2(60,35,1160,650))
 ui.label_at("CONSUMABLE INVENTORY",Vector2(90,55),30,1000,true)
 ui.label_at("Choose up to TWO item types. Equip is free; only a valid activation spends one. Permanent perks are separate.",Vector2(92,100),16,1090)
 for i in range(mini(8,ItemCatalog.IDS.size()-inventory_page*8)):
  var id=ItemCatalog.IDS[i+inventory_page*8]
  var data=ItemCatalog.ITEMS[id]
  var pos=Vector2(90+(i%2)*560,144+int(i/2)*112)
  ui.box(Rect2(pos,Vector2(540,109)),"203747",data.color)
  art(id,pos+Vector2(10,18),62)
  ui.label_at(data.name+" · ×%d" % int(game.profile.inventory.get(id,0)),pos+Vector2(82,8),19,440,true)
  var description=ui.label_at(data.rarity+" · "+data.description,pos+Vector2(82,34),12,432)
  description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  description.set_deferred("size",Vector2(432,42))
  description.tooltip_text=data.description
  var button=ui.button("Equipped ✓" if id in game.profile.item_loadout else "Equip",pos+Vector2(82,78),func():
   if not game.profile.equip_item(id): game.audio_event("failure")
   inventory(),140,22)
  button.disabled=game.profile.read_only or (id not in game.profile.item_loadout and (int(game.profile.inventory.get(id,0))<=0 or game.profile.item_loadout.size()>=ItemCatalog.SLOTS))
 ui.button(["Advanced items →","Legendary items →","← Original items"][inventory_page],Vector2(900,55),func(): inventory_page=(inventory_page+1)%3; inventory(),270,36)
 ui.label_at("Selected: "+", ".join(game.profile.item_loadout)+" · Stock persists; unused items stay yours.",Vector2(92,600),16,1080)
 ui.button("Back to loadout",Vector2(92,638),ui.progression.show_loadout,250,36)
 ui.button("Main menu",Vector2(360,638),game.return_menu,220,36)
 if not game.profile.pending_spins.is_empty(): ui.button("Resume reward",Vector2(890,638),spin,280,36)
func spin():
 if not game.profile.save_ok and not game.profile.save_profile():
  ui.clear(); ui.current_screen="spin_save_failed"
  ui.box(Rect2(230,170,820,360))
  ui.label_at("REWARD WAITING FOR A SAFE SAVE",Vector2(270,205),27,740,true)
  ui.label_at("No reward is lost in this session. Retry saving before the animation.",Vector2(270,265),18,740)
  ui.button("Retry saving reward",Vector2(270,340),spin,340,48)
  ui.button("Back",Vector2(650,340),ui.show_result if game.mode=="result" else game.return_menu,300,48)
  return
 var receipt=game.profile.pending_spin()
 if receipt.is_empty():
  if game.mode=="result": ui.show_result()
  else: inventory()
  return
 ui.clear(); ui.current_screen="spin"
 spin_ready=false; spin_claiming=false
 ui.box(Rect2(100,55,1080,610),"182B3A","BE9BEF")
 ui.label_at("VICTORY SPIN" if receipt.result=="victory" else "CONSOLATION SPIN",Vector2(140,80),32,1000,true)
 ui.label_at("Victory: up to 4 of one type · Consolation: 1 · Stock cap 9,999. Reward saved.",Vector2(140,126),16,990)
 var wheel=preload("res://scripts/item_wheel.gd").new()
 wheel.position=Vector2(155,175); wheel.size=Vector2(420,380)
 ui.panel.add_child(wheel)
 var rarity="Common 40% · Rare 40% · Epic 16% · Legendary 4%" if receipt.result=="victory" else "Common 80% · Rare 16% · Epic 3% · Legendary 1%"
 ui.label_at(rarity,Vector2(615,186),15,525,true)
 var probability=[]
 for i in range(ItemCatalog.IDS.size()): probability.append("%s %s%%" % [ItemCatalog.ITEMS[ItemCatalog.IDS[i]].name,str(snappedf(ItemCatalog.probability(receipt.result,i),.01))])
 var odds=ui.label_at("\n".join(probability),Vector2(640,218),11,470)
 odds.size.y=370
 var index=ItemCatalog.IDS.find(receipt.item)
 var target=TAU*4-index*TAU/ItemCatalog.IDS.size()
 spin_tween=wheel.create_tween()
 spin_tween.tween_property(wheel,"angle",target,2.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
 spin_tween.tween_callback(func(): reveal(receipt,wheel,target))
 ui.button("Skip animation",Vector2(225,590),func():
  if spin_ready: return
  if spin_tween!=null and spin_tween.is_valid(): spin_tween.kill()
  reveal(receipt,wheel,target),260,40)
func reveal(receipt,wheel,target):
 if spin_ready or not is_instance_valid(wheel): return
 spin_ready=true; wheel.angle=target; wheel.queue_redraw()
 game.audio_event("item_legendary_reveal" if ItemCatalog.legendary(receipt.item) else "item_reveal")
 ui.box(Rect2(615,215,525,350),"263E50",ItemCatalog.ITEMS[receipt.item].color)
 var reward_art=art(receipt.item,Vector2(805,235),104)
 if ItemCatalog.legendary(receipt.item):
  reward_art.pivot_offset=Vector2(52,52)
  reward_art.scale=Vector2(.65,.65)
  var flourish=reward_art.create_tween()
  flourish.tween_property(reward_art,"scale",Vector2.ONE,.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  ui.label_at("✦ LEGENDARY ✦",Vector2(645,220),18,150,true).modulate=Color("FFE291")
 var data=ItemCatalog.ITEMS[receipt.item]
 ui.label_at(data.name,Vector2(645,345),25,470,true)
 ui.label_at(data.rarity+(" · Stock full (9,999) · no items added" if int(receipt.get("quantity",1))==0 else " · +%d earned · Inventory ×%d" % [int(receipt.get("quantity",1)),int(game.profile.inventory.get(receipt.item,0))]),Vector2(645,388),18,470)
 var text=ui.label_at(data.description,Vector2(645,425),17,465)
 text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; text.set_deferred("size",Vector2(465,65))
 ui.button("Save reveal & continue",Vector2(650,512),func():
  if spin_claiming: return
  spin_claiming=true
  if game.profile.claim_spin(int(receipt.match_id)).is_empty():
   spin_claiming=false; game.audio_event("failure"); return
  if game.mode=="result": ui.show_result()
  else: inventory(),440,40)
func result_gate() -> bool:
 if game.profile.pending_spins.is_empty():
  if not game.profile.pending_stage_bonus.is_empty() and game.profile.pending_stage_bonus.choice=="" and game.mode=="result":
   ui.button("Choose stage bonus",Vector2(390,530),ui.progression.show_stage_bonus,495,44)
   return true
  return false
 ui.button("Lucky Spin · reveal earned item",Vector2(390,530),spin,495,44)
 ui.label_at("Reward saved · reveal it before continuing" if game.profile.save_ok else "Reward pending save · retry before closing",Vector2(390,580),15,495)
 return true
func choose_teammate(slot: int):
 if game.mode!="match": return
 var box=ui.box(Rect2(310,190,660,330))
 ui.label_at("TEAM RESCUE · choose an intact damaged door",Vector2(330,210),21,620)
 for i in range(game.model.rooms.size()):
  var r=game.model.rooms[i]
  var index=i
  var b=ui.button("%s · %d/%d HP" % [r.survivor_name(),r.door_hp,r.max_hp()],Vector2(330+(i%2)*310,255+int(i/2)*60),func():
   var ok=game.activate_item(slot,index)
   ui.show_match(),295,46)
  b.disabled=r.owner<=0 or not r.alive or not r.closed or r.door_hp<=0 or r.door_hp>=r.max_hp()
 ui.button("Cancel selection",Vector2(330,445),ui.show_match,300,44)
func create_hotbar():
 legendary_banner=ui.box(Rect2(20,215,334,44),"172338","EAC979")
 legendary_banner.mouse_filter=Control.MOUSE_FILTER_IGNORE
 legendary_name=ui.label_at("",Vector2(30,225),18,314,true)
 legendary_name.mouse_filter=Control.MOUSE_FILTER_IGNORE
 legendary_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 legendary_banner.visible=false
 legendary_name.visible=false
 hotbar.clear()
 var equipped=game.profile.active_match.get("items",[])
 for i in range(equipped.size()):
  var slot=i
  var b=ui.button("",Vector2(20,494+i*65),func(): game.activate_item(slot),270,58)
  b.add_theme_font_size_override("font_size",14)
  b.alignment=HORIZONTAL_ALIGNMENT_LEFT
  b.icon=load("res://assets/items/"+str(equipped[i])+".svg")
  b.expand_icon=true
  b.add_theme_constant_override("icon_max_width",40)
  hotbar.append(b)
 feedback_label=ui.label_at("",Vector2(20,454),15,360)
 radar_label=ui.label_at("",Vector2(20,384),14,365)
 radar_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 radar_label.set_deferred("size",Vector2(365,62))
func update(delta):
 if game.model!=observed_model or game.model.items!=observed_effects:
  observed_model=game.model; observed_effects=game.model.items; seen_event=0
 var fx=game.model.items
 for e in fx.events:
  if e.id<=seen_event: continue
  seen_event=e.id
  if e.phase=="income": continue
  game.audio_event("item_"+e.item if e.phase in ["activate","used"] else "item_explosion" if e.phase=="explode" else "item_end" if e.phase=="end" else "item_shield_hit")
 if game.mode!="match": return
 if is_instance_valid(legendary_banner) and is_instance_valid(legendary_name):
  legendary_banner.visible=false
  legendary_name.visible=false
  for event in fx.events:
   if ItemCatalog.legendary(str(event.item)) and event.phase=="activate" and event.age<1.6:
    var alpha=clampf((1.6-event.age)*3,0,1)
    legendary_banner.visible=true; legendary_name.visible=true
    legendary_banner.modulate=Color(1,1,1,alpha)
    legendary_name.modulate=Color("FFE5A1")*Color(1,1,1,alpha)
    legendary_name.text="✦ "+ItemCatalog.ITEMS[event.item].name.to_upper()+" ✦"
    var pulse=1.0 if game.profile.settings.get("reduced_effects",false) else 1+sin(event.age*PI/1.6)*.035
    legendary_name.pivot_offset=Vector2(157,12)
    legendary_name.scale=Vector2(pulse,pulse)
 var selected=game.profile.active_match.get("items",[])
 for i in range(hotbar.size()):
  if not is_instance_valid(hotbar[i]) or i>=selected.size(): continue
  var id=str(selected[i]); var quantity=int(game.profile.inventory.get(id,0)); var seconds=float(fx.timers.get(id,0))
  if id=="trap" and not fx.trap.is_empty(): seconds=fx.trap.remaining
  var special=""
  if id=="guardian_heart": special=" · USED" if fx.legendary_used>0 else " · AUTO lethal"
  if ItemCatalog.legendary(id) and id!="guardian_heart" and fx.legendary_used>0 and seconds<=0: special=" · USED"
  if id=="feather": special=" · USED" if fx.feather_used else " · AUTO at25%"
  if id=="coupon" and game.model.player()!=null and game.model.player().coupon_armed: special=" · ARMED40%"
  hotbar[i].text="[%d] %s ×%d%s" % [i+1,ItemCatalog.ITEMS[id].name,quantity," · %.1fs" % seconds if seconds>0 else " · CD %.1fs" % fx.cooldown if fx.cooldown>0 else ""]+special
  var reason=fx.can_activate(id,game.model)
  if id=="rescue" and reason.begins_with("Select"):
   if game.model.rooms.any(func(r):return r.owner>0 and r.alive and r.closed and r.door_hp>0 and r.door_hp<r.max_hp()): reason=""
  hotbar[i].disabled=quantity<=0 or reason!="" or game.profile.read_only
  hotbar[i].tooltip_text=ItemCatalog.ITEMS[id].description+"\n"+(reason if reason!="" else "Ready")
 if is_instance_valid(feedback_label):
  feedback_label.text=""
  if not fx.events.is_empty():
   var last=fx.events[-1]
   if last.age<1.8: feedback_label.text=ItemCatalog.ITEMS[last.item].name+(" · ended" if last.phase=="end" else " · -%s damage" % str(snappedf(last.value,.01)) if last.phase=="explode" else " · absorbed %s" % str(snappedf(last.value,.01)) if last.phase=="absorb" else " · saved %.1fG / %.1fE" % [last.value,last.get("power",0)] if last.phase=="used" else " · active" if last.value<=0 else " · +%s" % str(snappedf(last.value,.01)))
 if is_instance_valid(feedback_label) and not fx.events.is_empty():
  var recent=fx.events.filter(func(e): return ItemCatalog.legendary(str(e.item)) and e.phase=="activate" and e.age<1.8)
  var last=recent[-1] if not recent.is_empty() else fx.events[-1]
  if last.age<1.8 and last.phase=="activate":
   if last.item=="guardian_heart": feedback_label.text="GUARDIAN HEART ACTIVATED!"
   if last.item=="reaper_seal": feedback_label.text="SPECIAL ATTACK INTERRUPTED!"
   if last.item=="cursed_fortune": feedback_label.text="+500 GOLD · Hunter empowered for20s!"
 if is_instance_valid(radar_label):
  radar_label.text="RADAR %.0fs · Hunter L%d at %.0f,%.0f
Target %s · Map / M to locate" % [fx.timers.radar,game.model.hunter.level,game.model.hunter.position.x,game.model.hunter.position.y,"Room %d" % (game.model.hunter.target+1) if game.model.hunter.target>=0 else "seeking"] if float(fx.timers.get("radar",0))>0 else ""
