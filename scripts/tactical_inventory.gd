extends RefCounted
## Contained stock list and one retained item detail pane.

var ui
var game
var entries: Array=[]
var list: ItemList
var title: Label
var details: Label
var quantity: Label
var badge: TextureRect
var equip: Button
var equipped_line: Label
var selected: String
var back: Callable
var show_unowned:=false
var group: Button

func _init(interface) -> void:
 ui=interface
 game=ui.game

func open() -> void:
 back=ui.campaign.story_ui.show_prepare if ui.current_screen=="story_prepare" else ui.show_result if game.mode=="result" else game.return_menu
 ui.clear()
 ui.current_screen="inventory"
 ui.tactical_back=back
 ui.theme_backdrop()
 ui.theme_panel(Rect2(80,50,1120,620),"frame")
 ui.theme_label("Inventory",Vector2(110,70),46,705,"text",true)
 equipped_line=ui.theme_label("",Vector2(113,132),19,1000,"muted")
 var back_button: Button=ui.button("Back [Esc]",Vector2(995,75),back,171,43)
 back_button.name="inventory_back"
 ui.theme_button(back_button,"quiet")
 list=ItemList.new()
 list.name="inventory_stock"
 list.position=Vector2(111,232)
 list.size=Vector2(418,397)
 list.add_theme_stylebox_override("panel",GothicTheme.living_surface("card"))
 list.add_theme_stylebox_override("selected",GothicTheme.living_surface("inventory"))
 list.add_theme_font_size_override("font_size",20)
 list.add_theme_constant_override("v_separation",12)
 ui.attach(list)
 list.item_selected.connect(select)
 group=ui.button("",Vector2(111,178),toggle_group,418,45)
 group.name="inventory_group"
 ui.theme_button(group,"inventory","inventory")
 var detail: Panel=ui.theme_panel(Rect2(553,178,614,451),"card")
 badge=TextureRect.new()
 badge.position=Vector2(24,23)
 badge.size=Vector2(125,125)
 badge.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 badge.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 detail.add_child(badge)
 title=ui.theme_label("",Vector2(168,35),29,402,"text",false,detail)
 title.clip_text=true
 quantity=ui.theme_label("",Vector2(168,90),20,402,"gold",false,detail)
 details=ui.theme_label("",Vector2(26,178),20,561,"muted",false,detail)
 details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 details.size.y=152
 if ui.large_reading_text:details.add_theme_font_size_override("font_size",24)
 equip=ui.button("Equip",Vector2(26,348),toggle_equip,331,56,detail)
 ui.theme_button(equip,"inventory","loadout")
 if not game.profile.pending_spins.is_empty():
  ui.theme_button(ui.button("Saved reward",Vector2(374,348),ui.items_ui.spin,207,56,detail),"accent")
 refresh_stock()

func toggle_group() -> void:
 show_unowned=not show_unowned
 refresh_stock()

func refresh_stock() -> void:
 list.clear()
 entries.clear()
 for id in ItemCatalog.IDS:
  var owned: bool=game.profile.inventory.get(id,0)>0 or id in game.profile.item_loadout
  if owned!=show_unowned:entries.append(id)
 entries.sort_custom(func(a,b):
  var a_equipped: bool=a in game.profile.item_loadout
  var b_equipped: bool=b in game.profile.item_loadout
  if a_equipped!=b_equipped:return a_equipped
  return ItemCatalog.ITEMS[a].name.naturalnocasecmp_to(ItemCatalog.ITEMS[b].name)<0)
 for id: String in entries:
  var qty: int=game.profile.inventory.get(id,0)
  var equipped: bool=id in game.profile.item_loadout
  list.add_item("%s · ×%d%s" % [ItemCatalog.ITEMS[id].name,qty," · Equipped" if equipped else ""])
 group.text="Show owned equipment" if show_unowned else "Browse unowned items"
 equipped_line.text="%s   ·   %d / %d slots equipped" % ["Unowned items" if show_unowned else "Owned equipment",game.profile.item_loadout.size(),ItemCatalog.SLOTS]
 if entries.is_empty():
  badge.texture=PremiumButton.texture("inventory")
  title.text="Collection complete" if show_unowned else "Your inventory is empty"
  quantity.text=""
  details.text="All item types are in your inventory." if show_unowned else "Buy supplies with RM Cash in the Shop. Owned items appear here, ready to equip."
  equip.hide()
  return
 var index:=maxi(0,entries.find(ui.last_inventory_item))
 list.select(index)
 list.ensure_current_is_visible()
 select(index)

func select(index: int) -> void:
 selected=entries[index]
 if not show_unowned:ui.last_inventory_item=selected
 equip.show()
 var data: Dictionary=ItemCatalog.ITEMS[selected]
 var qty: int=game.profile.inventory.get(selected,0)
 var equipped: bool=selected in game.profile.item_loadout
 badge.texture=load("res://assets/items/%s.svg" % selected)
 title.text=data.name
 quantity.text="%s · %d owned" % [data.rarity,qty]
 details.text=data.description
 equip.name="inventory_equip_"+selected
 equip.text="Unequip item" if equipped else "Equip item"
 equip.disabled=game.profile.read_only or not equipped and (qty==0 or game.profile.item_loadout.size()>=ItemCatalog.SLOTS)
 equip.tooltip_text="No copies in stock" if qty==0 else "Two item types are already equipped" if equip.disabled and not game.profile.read_only else "Equipment changes are saved immediately"

func toggle_equip() -> void:
 if not game.profile.equip_item(selected):game.audio_event("failure")
 else:game.audio_event("ui_confirm")
 refresh_stock()
