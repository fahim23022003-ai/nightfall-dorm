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
 list.position=Vector2(111,178)
 list.size=Vector2(418,451)
 list.add_theme_stylebox_override("panel",GothicTheme.living_surface("card"))
 list.add_theme_stylebox_override("selected",GothicTheme.living_surface("inventory"))
 list.add_theme_font_size_override("font_size",20)
 list.add_theme_constant_override("v_separation",12)
 ui.attach(list)
 list.item_selected.connect(select)
 for id in ItemCatalog.IDS:entries.append(id)
 entries.sort_custom(func(a,b):return int(game.profile.inventory.get(a,0))>int(game.profile.inventory.get(b,0)))
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
 equip=ui.button("Equip",Vector2(26,348),toggle_equip,331,56,detail)
 ui.theme_button(equip,"inventory","loadout")
 if not game.profile.pending_spins.is_empty():
  ui.theme_button(ui.button("Saved reward",Vector2(374,348),ui.items_ui.spin,207,56,detail),"accent")
 refresh_stock()
 list.select(0)
 select(0)

func refresh_stock() -> void:
 list.clear()
 for id: String in entries:
  var qty: int=game.profile.inventory.get(id,0)
  var equipped: bool=id in game.profile.item_loadout
  list.add_item("%s · ×%d%s" % [ItemCatalog.ITEMS[id].name,qty," · Equipped" if equipped else ""])
 equipped_line.text="Equipped %d / %d item types" % [game.profile.item_loadout.size(),ItemCatalog.SLOTS]

func select(index: int) -> void:
 selected=entries[index]
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
 var index:=entries.find(selected)
 if not game.profile.equip_item(selected):game.audio_event("failure")
 refresh_stock()
 list.select(index)
 select(index)
