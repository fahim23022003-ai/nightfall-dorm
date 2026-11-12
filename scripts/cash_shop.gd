extends RefCounted
var game
var ui
var lock_until=0
var feedback=""
var buttons: Array=[]
func _init(owner):ui=owner;game=ui.game
func show_shop():
 ui.clear();ui.current_screen="shop";buttons.clear()
 ui.box(Rect2(100,50,1080,610),"172839","8F687A")
 ui.label_at("DORM SUPPLIES · COMMON SHOP",Vector2(140,75),30,1000,true)
 ui.label_at("RM Cash %d · Earned in matches; in-game currency only." % game.profile.rm_cash,Vector2(140,122),20,990)
 var index=0
 for id in OnboardingCatalog.PRICES:
  var data=ItemCatalog.ITEMS[id];var pos=Vector2(140+(index%2)*510,180+int(index/2)*185)
  ui.box(Rect2(pos,Vector2(480,165)),"203747",data.color)
  ui.items_ui.art(id,pos+Vector2(12,18),56)
  ui.label_at(data.name,pos+Vector2(82,12),21,380,true)
  ui.label_at("Common · Owned ×%d" % int(game.profile.inventory.get(id,0)),pos+Vector2(82,43),16,380)
  var desc=ui.label_at(data.description,pos+Vector2(82,72),16,375);desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;desc.set_deferred("size",Vector2(375,44))
  var chosen=id;var token=game.profile.purchase_serial+1
  var b=ui.button("Buy · %d RM Cash" % OnboardingCatalog.PRICES[id],pos+Vector2(82,119),func():purchase(chosen,token),360,34)
  buttons.append({"button":b,"id":id});index+=1
 ui.label_at(feedback,Vector2(140,565),17,990)
 ui.button("Back to main menu",Vector2(140,607),game.return_menu,360,36)
 update()
func purchase(id,token):
 if Time.get_ticks_msec()<lock_until:return
 lock_until=Time.get_ticks_msec()+450
 if game.profile.buy_common(id,token):feedback="Purchased: +1 %s · %d RM Cash saved" % [ItemCatalog.ITEMS[id].name,game.profile.rm_cash];game.audio_event("shop_purchase")
 else:
  feedback="Purchase failed: need RM Cash, inventory space and a successful save. Nothing was spent."
  game.audio_event("failure")
 show_shop()
func update():
 for entry in buttons:
  if is_instance_valid(entry.button):entry.button.disabled=game.profile.read_only or Time.get_ticks_msec()<lock_until or game.profile.rm_cash<OnboardingCatalog.PRICES[entry.id] or int(game.profile.inventory.get(entry.id,0))>=ItemCatalog.MAX_STOCK
