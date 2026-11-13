class_name MainMenu
extends RefCounted
var ui
func _init(owner):ui=owner
func card(title: String,at: Vector2,size: Vector2,shape: String,callback: Callable,icon: String,subtitle: String,color: String) -> MenuDestination:
 var button=MenuDestination.new();button.text=title;button.position=at;button.size=size;button.silhouette=shape;button.accent=Color(color)
 var empty=StyleBoxEmpty.new()
 for state in ["normal","hover","pressed","disabled","focus"]:button.add_theme_stylebox_override(state,empty)
 for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:button.add_theme_color_override(state,Color.TRANSPARENT)
 button.pressed.connect(func():
  if ui.game.onboarding!=null and ui.game.onboarding.is_welcome_open():return
  ui.game.audio_event("button");callback.call())
 button.mouse_entered.connect(func():ui.game.audio_event("ui_hover"))
 ui.panel.add_child(button)
 var is_start=shape=="start";var icon_size=Vector2(52,52) if is_start else Vector2(64,64)
 var icon_at=Vector2(24,(size.y-icon_size.y)*.5) if is_start else Vector2((size.x-icon_size.x)*.5,32 if shape=="shop" else 17)
 var art=ui.premium_icon(icon,icon_at,icon_size,button)
 var heading=ui.label_at(title,Vector2(90,15) if is_start else Vector2(10,102),30 if is_start else 21,size.x-110 if is_start else size.x-20,true,button)
 heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT if is_start else HORIZONTAL_ALIGNMENT_CENTER
 if is_start:heading.add_theme_font_override("font",ui.horror_font)
 var sub=ui.label_at(subtitle,Vector2(92,53) if is_start else Vector2(12,133),15,size.x-110 if is_start else size.x-24,false,button)
 sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT if is_start else HORIZONTAL_ALIGNMENT_CENTER;sub.modulate=Color("D1C8B7")
 return button
func create():
 var game=ui.game;var profile=game.profile
 ui.label_at("SMALL ROOMS. BIG NIGHTMARES.",Vector2(70,87),17,600).modulate=Color("ACBDAD")
 var logo=ui.label_at("NIGHTFALL\nDORM",Vector2(65,122),64,600,true);logo.add_theme_font_override("font",ui.horror_font);logo.add_theme_constant_override("line_spacing",-32)
 ui.label_at("—  THE NIGHT WATCH  —",Vector2(74,262),13,600).modulate=Color("B8A478")
 ui.label_at("Claim a bed. Build your defenses.\nMake it through the night.",Vector2(73,293),20,580)
 ui.menu_start=card("Start Game",Vector2(70,382),Vector2(480,98),"start",game.enter_game,"play","Prepare for your next night","D2BC83")
 var endless=ui.button("Endless Siege",Vector2(94,494),ui.replay_ui.show_endless,432,48);endless.icon=PremiumButton.texture("endless")
 ui.label_at("One room. Stronger waves. How long can you last?",Vector2(96,551),14,480).modulate=Color("BCA8C4")
 var shop=card("SHOP",Vector2(614,357),Vector2(190,220),"shop",ui.shop.show_shop,"shop","Buy supplies","BD9980")
 ui.label_at("WALLET · RM CASH",Vector2(14,168),11,162,true,shop).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var balance=ui.label_at(str(profile.rm_cash),Vector2(14,186),19,162,false,shop);balance.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shop.tooltip_text="Wallet balance: %d RM Cash" % profile.rm_cash
 var rank=card("RANK & REWARDS",Vector2(820,357),Vector2(206,230),"rank",ui.progression.show_ranks,"rank",profile.rank_name()+" · %d XP" % profile.xp,"BBACC9")
 # Replace generic shield with the actual existing rank emblem.
 for child in rank.get_children():
  if child is TextureRect:child.texture=load("res://assets/ranks/"+profile.rank_name().to_lower()+".svg");child.position=Vector2(65,13);child.size=Vector2(76,76)
 var tier=profile.rank_index();var progress=ProgressBar.new();progress.position=Vector2(20,170);progress.size=Vector2(166,10);progress.mouse_filter=Control.MOUSE_FILTER_IGNORE;progress.show_percentage=false
 progress.max_value=1;progress.value=1.0 if tier>=6 else clampf(float(profile.xp-RankCatalog.THRESHOLDS[tier])/maxf(1,RankCatalog.THRESHOLDS[tier+1]-RankCatalog.THRESHOLDS[tier]),0,1);rank.add_child(progress)
 var next=ui.label_at("MYTHIC" if tier>=6 else "XP ready · view requirements" if tier==5 and profile.xp>=RankCatalog.THRESHOLDS[6] else "%d XP to %s" % [maxi(0,RankCatalog.THRESHOLDS[tier+1]-profile.xp),RankCatalog.NAMES[tier+1]],Vector2(14,190),13,178,false,rank);next.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 rank.tooltip_text=profile.promotion_requirement()
 var count=0
 for value in profile.inventory.values():count+=int(value)
 var inventory=card("INVENTORY",Vector2(1042,370),Vector2(168,207),"inventory",ui.items_ui.inventory,"inventory","Items you own","96B6B0")
 ui.label_at("%d items" % count,Vector2(14,170),15,140,true,inventory).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 ui.button("Extras · Challenge / Practice / Cosmetics",Vector2(666,600),ui.replay_ui.show_hub,480,38)
 var footer_y=650
 ui.button("How to Play",Vector2(70,footer_y),ui.show_help,150,38)
 ui.button("Replay Tutorial",Vector2(230,footer_y),func():game.start_tutorial(true),170,38)
 ui.button("Settings",Vector2(410,footer_y),ui.show_settings,140,38)
 ui.button("Exit",Vector2(566,footer_y),game.request_quit,100,38)
 if not profile.pending_spins.is_empty():ui.button("Resume Lucky Spin",Vector2(690,footer_y),ui.items_ui.spin,230,38)
 if profile.warning!="":ui.label_at(profile.warning,Vector2(74,594),13,510).modulate=Color("EDBD8A")
 ui.menu_start.grab_focus()
