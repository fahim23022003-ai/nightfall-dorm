extends RefCounted
var game
var ui
var lock_until=0
var feedback=""
var buttons: Array=[]
var purchased_id=""
var paid=0
func _init(owner):ui=owner;game=ui.game
func show_shop():
 ui.clear();ui.current_screen="shop";buttons.clear()
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
  var card=ui.box(Rect2(pos,Vector2(480,165)),"203747",data.color)
  ui.box(Rect2(pos+Vector2(9,12),Vector2(96,141)),"171C22","748275")
  var illustration=ui.items_ui.art(id,pos+Vector2(12,27),90)
  ui.label_at(data.name,pos+Vector2(118,10),22,345,true)
  ui.label_at("COMMON · Owned ×%d" % int(game.profile.inventory.get(id,0)),pos+Vector2(118,41),14,345).modulate=Color("B3C49E")
  var desc=ui.label_at(data.description,pos+Vector2(118,67),15,340);desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;desc.set_deferred("size",Vector2(340,44))
  var chosen=id;var token=game.profile.purchase_serial+1
  var b=ui.button("Buy · %d RM Cash" % OnboardingCatalog.PRICES[id],pos+Vector2(118,119),func():purchase(chosen,token),340,34)
  if id==purchased_id:
   card.modulate=Color(1.32,1.26,1.08)
   card.create_tween().tween_property(card,"modulate",Color.WHITE,.7)
   ui.progression.flourish(illustration)
  buttons.append({"button":b,"id":id});index+=1
 ui.label_at(feedback,Vector2(140,565),17,990)
 ui.button("Back to main menu",Vector2(140,607),game.return_menu,360,36)
 update()
 purchased_id="" # A success flourish belongs to this transaction, never a later visit.
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
 for entry in buttons:
  if is_instance_valid(entry.button):entry.button.disabled=game.profile.read_only or Time.get_ticks_msec()<lock_until or game.profile.rm_cash<OnboardingCatalog.PRICES[entry.id] or int(game.profile.inventory.get(entry.id,0))>=ItemCatalog.MAX_STOCK
