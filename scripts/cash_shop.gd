extends RefCounted
var game
var ui
var lock_until=0
var feedback=""
var buttons: Array=[]
var purchased_id=""
var paid=0
var tactical_back:=Callable()
var rendered_lock:=false
var rendered_cash:=-1
var rendered_read_only:=false
func _init(owner):ui=owner;game=ui.game
func show_shop():
 if ui.use_tactical_ui() and ui.current_screen!="shop":
  tactical_back=ui.show_result if game.mode=="result" else game.return_menu
  feedback=""
 ui.clear();ui.current_screen="shop";buttons.clear()
 if ui.use_tactical_ui():
  ui.tactical_back=tactical_back
  _tactical_shop()
  return
 var living: bool=ui.use_living_ui()
 if living:
  ui.theme_backdrop()
  ui.theme_panel(Rect2(100,50,1080,620),"shop" if ui.use_living_dorm() else "frame")
  ui.theme_label("DORM SUPPLIES",Vector2(140,75),33,860,"text",true)
 else:
  ui.box(Rect2(100,50,1080,610),"172839","8F687A")
  ui.label_at("DORM SUPPLIES · COMMON SHOP",Vector2(140,75),30,1000,true)
 ui.premium_icon("cash",Vector2(140,115),Vector2(42,42))
 ui.label_at("RM Cash %d · Earned in matches; in-game currency only." % game.profile.rm_cash,Vector2(195,122),20,930)
 if purchased_id!="":
  var deduction=ui.label_at("−%d RM Cash" % paid,Vector2(970,150),16,170)
  deduction.modulate=Color("E6C58B")
  var fade=deduction.create_tween().set_parallel()
  fade.tween_property(deduction,"position:y",132.0,.8)
  fade.tween_property(deduction,"modulate:a",0.0,.8)
 var index=0
 for id in OnboardingCatalog.PRICES:
  var data=ItemCatalog.ITEMS[id];var pos=Vector2(140+(index%2)*510,180+int(index/2)*185)
  var card=ui.theme_panel(Rect2(pos,Vector2(480,165)),"card") if living else ui.box(Rect2(pos,Vector2(480,165)),"203747",data.color)
  if living:
   ui.theme_panel(Rect2(pos+Vector2(9,12),Vector2(96,141)),"inset")
  else:
   ui.box(Rect2(pos+Vector2(9,12),Vector2(96,141)),"171C22","748275")
  var illustration=ui.items_ui.art(id,pos+Vector2(12,27),90)
  ui.label_at(data.name,pos+Vector2(118,10),22,345,true)
  ui.label_at("COMMON · Owned ×%d" % int(game.profile.inventory.get(id,0)),pos+Vector2(118,41),14,345).modulate=Color("B3C49E")
  var desc=ui.label_at(data.description,pos+Vector2(118,67),15,340);desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;desc.set_deferred("size",Vector2(340,44))
  var chosen=id;var token=game.profile.purchase_serial+1
  var b=ui.button("Buy · %d RM Cash" % OnboardingCatalog.PRICES[id],pos+Vector2(118,119),func():purchase(chosen,token),340,34)
  b.name="shop_buy_"+id
  if living:
   ui.theme_button(b,"shop","cash")
  if id==purchased_id:
   card.modulate=Color(1.32,1.26,1.08)
   card.create_tween().tween_property(card,"modulate",Color.WHITE,.7)
   ui.progression.flourish(illustration)
  buttons.append({"button":b,"id":id});index+=1
 if living:
  ui.theme_label(feedback,Vector2(140,555),17,990,"danger" if feedback.begins_with("Purchase failed") else "success")
 else:
  ui.label_at(feedback,Vector2(140,565),17,990)
 var back=ui.button("Back [Esc]" if ui.use_tactical_ui() else "Back to main menu",Vector2(140,607),tactical_back if ui.use_tactical_ui() else game.return_menu,360,38)
 back.name="shop_back"
 if living:
  ui.theme_button(back,"quiet")
 update()
 purchased_id="" # A success flourish belongs to this transaction, never a later visit.
func _tactical_shop() -> void:
 ui.theme_backdrop()
 ui.theme_panel(Rect2(83,49,1114,622),"frame")
 ui.theme_label("Dorm supplies",Vector2(123,79),40,701,"text",true)
 ui.premium_icon("cash",Vector2(891,87),Vector2(38,38))
 ui.theme_label("%d RM Cash" % game.profile.rm_cash,Vector2(941,88),23,218,"gold")
 var index:=0
 for id: String in OnboardingCatalog.PRICES:
  var item: Dictionary=ItemCatalog.ITEMS[id]
  var at:=Vector2(123+(index%2)*525,166+floori(index/2.0)*193)
  ui.theme_panel(Rect2(at,Vector2(507,178)),"card")
  ui.items_ui.art(id,at+Vector2(15,23),90)
  ui.theme_label(item.name,at+Vector2(118,12),23,376,"text")
  var desc: Label=ui.theme_label(item.description,at+Vector2(118,54),17,375,"muted")
  desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  ui.theme_label("Owned ×%d" % int(game.profile.inventory.get(id,0)),at+Vector2(13,120),16,105,"muted")
  var token: int=game.profile.purchase_serial+1
  var button: Button=ui.button("",at+Vector2(118,118),func():purchase(id,token),367,45)
  button.name="shop_buy_"+id
  ui.theme_button(button,"shop","cash")
  buttons.append({"button":button,"id":id})
  index+=1
 var message: String=feedback
 if message.is_empty() and game.profile.rm_cash<OnboardingCatalog.PRICES.values().min():
  message="Earn RM Cash by completing matches. Your balance carries over."
 ui.theme_label(message,Vector2(126,547),18,1015,"danger" if message.begins_with("Purchase failed") else "muted" if feedback.is_empty() else "success")
 var back: Button=ui.button("Back [Esc]",Vector2(124,603),tactical_back,193,44)
 back.name="shop_back"
 ui.theme_button(back,"quiet")
 rendered_cash=-1
 update()
 var focus: Button=back
 for entry in buttons:
  if not entry.button.disabled:
   focus=entry.button
   break
 focus.grab_focus()
 purchased_id=""

func purchase(id,token):
 if Time.get_ticks_msec()<lock_until:return
 lock_until=Time.get_ticks_msec()+450
 if game.profile.buy_common(id,token):
  purchased_id=id;paid=OnboardingCatalog.PRICES[id]
  feedback="Purchased: +1 %s · −%d RM Cash · %d remaining" % [ItemCatalog.ITEMS[id].name,paid,game.profile.rm_cash];game.audio_event("shop_purchase")
 else:
  purchased_id=""
  feedback="Purchase failed: need RM Cash, inventory space and a successful save. Nothing was spent."
  game.audio_event("failure")
 show_shop()
func update():
 if ui.current_screen!="shop":return
 var tactical: bool=ui.use_tactical_ui()
 var locked: bool=Time.get_ticks_msec()<lock_until
 if tactical:
  if rendered_cash==game.profile.rm_cash and rendered_lock==locked and rendered_read_only==game.profile.read_only:return
  rendered_cash=game.profile.rm_cash
  rendered_lock=locked
  rendered_read_only=game.profile.read_only
 for entry in buttons:
  if not is_instance_valid(entry.button):
   continue
  var cost: int=OnboardingCatalog.PRICES[entry.id]
  var stock_full: bool=int(game.profile.inventory.get(entry.id,0))>=ItemCatalog.MAX_STOCK
  entry.button.disabled=game.profile.read_only or locked or game.profile.rm_cash<cost or stock_full
  if tactical:
   var reason: String="Read-only profile" if game.profile.read_only else "Inventory full" if stock_full else "Need %d more RM" % (cost-game.profile.rm_cash) if game.profile.rm_cash<cost else ""
   entry.button.text="Buy · %d RM" % cost if reason.is_empty() else "%d RM · %s" % [cost,reason]
  elif ui.use_living_ui():
   var needed: int=maxi(0,cost-game.profile.rm_cash)
   entry.button.tooltip_text="Inventory full" if stock_full else "Need %d more RM Cash" % needed if needed>0 else "Buy one for %d RM Cash" % cost
