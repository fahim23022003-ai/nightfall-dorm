class_name MainMenu
extends RefCounted
const GOLD_EDGE := "D2BC83"
var ui
func _init(owner):ui=owner
func card(title: String,at: Vector2,size: Vector2,shape: String,callback: Callable,icon: String,subtitle: String,color: String) -> MenuDestination:
 var button=MenuDestination.new();button.text=title;button.position=at;button.size=size;button.silhouette=shape;button.accent=Color(color);button.reduced=ui.game.profile.settings.get("reduced_effects",false)
 var empty=StyleBoxEmpty.new()
 for state in ["normal","hover","pressed","disabled","focus"]:button.add_theme_stylebox_override(state,empty)
 for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:button.add_theme_color_override(state,Color.TRANSPARENT)
 button.pressed.connect(func():
  if ui.game.onboarding!=null and ui.game.onboarding.is_welcome_open():return
  ui.game.audio_event("button");callback.call())
 button.mouse_entered.connect(func():ui.game.audio_event("ui_hover"))
 ui.panel.add_child(button)
 var is_start=shape=="start";var icon_size=Vector2(52,52) if is_start else Vector2(64,64)
 var icon_at=Vector2(24,(size.y-icon_size.y)*.5) if is_start else Vector2((size.x-icon_size.x)*.5,35 if shape=="shop" else 22)
 var art=ui.premium_icon(icon,icon_at,icon_size,button)
 if shape in ["shop","inventory"]:art.texture=load("res://assets/menu/"+("merchant_bag.svg" if shape=="shop" else "inventory_case.svg"))
 var heading=ui.label_at(title,Vector2(90,15) if is_start else Vector2(10,107),30 if is_start else 21,size.x-110 if is_start else size.x-20,true,button)
 heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT if is_start else HORIZONTAL_ALIGNMENT_CENTER
 if is_start:heading.add_theme_font_override("font",ui.horror_font)
 var sub=ui.label_at(subtitle,Vector2(92,53) if is_start else Vector2(12,135),15,size.x-110 if is_start else size.x-24,false,button)
 sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT if is_start else HORIZONTAL_ALIGNMENT_CENTER;sub.modulate=Color("D1C8B7")
 return button
func secondary(button: Button,role="utility"):
 for state in ["normal","hover","pressed","disabled","focus"]:
  var style=StyleBoxFlat.new();style.set_corner_radius_all(17 if role=="play" else 8)
  style.bg_color=Color("262A30") if role!="play" else Color("302734")
  if state=="hover":style.bg_color=style.bg_color.lightened(.08)
  elif state=="pressed":style.bg_color=style.bg_color.darkened(.2)
  style.border_color=Color("B7BBA2") if state=="focus" else Color("A795AE") if state=="hover" else Color("676A68")
  style.set_border_width_all(2 if state=="focus" else 1)
  for side in [SIDE_LEFT,SIDE_RIGHT]:style.set_content_margin(side,12)
  for side in [SIDE_TOP,SIDE_BOTTOM]:style.set_content_margin(side,5)
  button.add_theme_stylebox_override(state,style)
 button.add_theme_font_size_override("font_size",17 if role=="play" else 15)
func create():
 if ui.use_tactical_ui():
  _create_tactical()
  return
 if ui.use_living_ui():
  _create_living()
  return
 var game=ui.game;var profile=game.profile
 ui.label_at("SMALL ROOMS. BIG NIGHTMARES.",Vector2(70,87),17,600).modulate=Color("ACBDAD")
 var logo=ui.label_at("NIGHTFALL\nDORM",Vector2(65,122),64,600,true);logo.add_theme_font_override("font",ui.horror_font);logo.add_theme_constant_override("line_spacing",-32)
 ui.label_at("—  THE NIGHT WATCH  —",Vector2(74,262),13,600).modulate=Color("B8A478")
 ui.label_at("Claim a bed. Build your defenses.\nMake it through the night.",Vector2(73,293),20,580)
 if game.story_preview_enabled:
  var mode: String=profile.selected_difficulty
  var track:=StoryProgress.summary(profile.story,mode)
  var mission:=StoryCatalog.mission(track.position)
  var subtitle: String="All 50 levels cleared" if track.finished else "Level %02d / 50   ·   %s" % [track.position,mission.title]
  ui.menu_start=card("CONTINUE STORY",Vector2(70,367),Vector2(514,108),"start",game.enter_game,"play",subtitle,GOLD_EDGE)
  ui.label_at("%s   ·   %d / 50 cleared" % [RankCatalog.DIFFICULTIES[mode].name,track.highest],Vector2(161,447),13,405).modulate=Color("B9B09A")
  var objective: String="Revisit your chapters or choose another difficulty." if track.finished else mission.objective
  ui.label_at(objective,Vector2(94,485),15,481).modulate=Color("C9C0AC")
 else:
  ui.menu_start=card("Start Game",Vector2(70,382),Vector2(480,98),"start",game.enter_game,"play","Next: Stage 1 · Normal" if profile.tutorial_completed and profile.statistics.matches==0 else "Prepare for your next night","D2BC83")
 var y:=524 if game.story_preview_enabled else 494
 var endless=ui.button("ENDLESS MODE" if game.story_preview_enabled else "Endless Siege",Vector2(94,y),ui.replay_ui.show_endless,432,48);endless.icon=PremiumButton.texture("endless");secondary(endless,"play")
 ui.label_at("One room. Stronger waves. How long can you last?",Vector2(96,y+56),14,480).modulate=Color("BCA8C4")
 var shop=card("SHOP",Vector2(614,357),Vector2(190,220),"shop",ui.shop.show_shop,"shop","Buy supplies","BD9980")
 ui.label_at("WALLET · RM CASH",Vector2(14,170),12,162,true,shop).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var balance=ui.label_at("",Vector2(14,189),19,162,false,shop);balance.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 shop.bind_data(func():return str(profile.rm_cash),func():balance.text=str(profile.rm_cash);shop.tooltip_text="Wallet balance: %d RM Cash" % profile.rm_cash)
 var rank=card("RANK & REWARDS",Vector2(820,357),Vector2(206,230),"rank",ui.progression.show_ranks,"rank","","BBACC9")
 var emblem: TextureRect
 var rank_name: Label
 for child in rank.get_children():
  if child is TextureRect:emblem=child;emblem.position=Vector2(71,22);emblem.size=Vector2(64,64)
  elif child is Label and child.position.y==135:rank_name=child
 var xp=ui.label_at("",Vector2(14,156),12,178,false,rank);xp.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;xp.size.y=18;rank_name.size.y=18
 var progress=ProgressBar.new();progress.name="RankProgress";progress.position=Vector2(20,178);progress.mouse_filter=Control.MOUSE_FILTER_IGNORE;progress.focus_mode=Control.FOCUS_NONE;progress.show_percentage=false;progress.max_value=1;progress.step=0.0
 var track=StyleBoxFlat.new();track.bg_color=Color("111A23");track.border_color=Color("625D70");track.set_border_width_all(1);track.set_corner_radius_all(4);progress.add_theme_stylebox_override("background",track)
 var fill=StyleBoxFlat.new();fill.set_corner_radius_all(4);progress.add_theme_stylebox_override("fill",fill);rank.add_child(progress)
 # Size only after percentage/font minimum and final styles are configured.
 progress.size=Vector2(166,8)
 var next=ui.label_at("",Vector2(14,193),12,178,false,rank);next.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;next.size.y=18
 rank.bind_data(func():return str(profile.xp)+":"+profile.rank_name()+":"+profile.promotion_requirement(),func():
  var tier=profile.rank_index();rank_name.text=profile.rank_name()
  if int(emblem.get_meta("rank",-1))!=tier:emblem.texture=load("res://assets/ranks/"+profile.rank_name().to_lower()+".svg");emblem.set_meta("rank",tier)
  fill.bg_color=Color(RankCatalog.COLORS[tier]).darkened(.15)
  var needed=1 if tier>=6 else RankCatalog.THRESHOLDS[tier+1]-RankCatalog.THRESHOLDS[tier]
  var earned=clampi(profile.xp-RankCatalog.THRESHOLDS[tier],0,needed)
  xp.text="%d XP · MAX" % profile.xp if tier>=6 else "%d / %d XP this rank" % [earned,needed]
  progress.value=1.0 if tier>=6 else clampf(float(profile.xp-RankCatalog.THRESHOLDS[tier])/maxf(1,RankCatalog.THRESHOLDS[tier+1]-RankCatalog.THRESHOLDS[tier]),0,1)
  next.text="MYTHIC" if tier>=6 else "XP ready · view requirements" if tier==5 and profile.xp>=RankCatalog.THRESHOLDS[6] else "%d XP to %s" % [maxi(0,RankCatalog.THRESHOLDS[tier+1]-profile.xp),RankCatalog.NAMES[tier+1]]
  rank.tooltip_text="Lifetime XP: %d\n%s" % [profile.xp,profile.promotion_requirement()])
 var inventory=card("INVENTORY",Vector2(1042,370),Vector2(168,207),"inventory",ui.items_ui.inventory,"inventory","Items you own","96B6B0")
 var owned=ui.label_at("",Vector2(14,173),15,140,true,inventory);owned.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 inventory.bind_data(func():return str(profile.inventory),func():
  var total=0
  for value in profile.inventory.values():total+=int(value)
  owned.text="%d items" % total)
 ui.button("Extras · Challenge / Practice / Cosmetics",Vector2(666,600),ui.replay_ui.show_hub,480,38)
 var footer_y=650
 ui.button("How to Play",Vector2(70,footer_y),ui.show_help,150,38)
 ui.button("Replay Tutorial",Vector2(230,footer_y),func():game.start_tutorial(true),170,38)
 ui.button("Settings",Vector2(410,footer_y),ui.show_settings,140,38)
 ui.button("Exit",Vector2(566,footer_y),game.request_quit,100,38)
 if not profile.pending_spins.is_empty():ui.button("Resume Lucky Spin",Vector2(690,footer_y),ui.items_ui.spin,230,38)
 if profile.warning!="":ui.label_at(profile.warning,Vector2(74,611 if game.story_preview_enabled else 594),13,510).modulate=Color("EDBD8A")
 for node in ui.panel.get_children():
  if node is Button and not node is MenuDestination and node!=endless:secondary(node)
 ui.menu_start.grab_focus()

func _create_tactical() -> void:
 var game=ui.game
 var profile: PlayerProfile=game.profile
 var track:=StoryProgress.summary(profile.story,profile.selected_difficulty)
 var mission:=StoryCatalog.mission(track.position)
 ui.theme_panel(Rect2(76,85,1128,552),"overlay")
 ui.theme_label("Nightfall Dorm",Vector2(116,127),70,622,"text",true)
 ui.theme_label("Chapter %02d · %s" % [mission.chapter,mission.chapter_title],Vector2(121,227),20,610,"gold")
 ui.theme_label("Level %02d / 50 · %s" % [mission.level,mission.title],Vector2(121,264),24,610,"text")
 ui.menu_start=_destination("mode_story","Story Archive" if track.finished else "Continue Story","Open the current mission and loadout.",Vector2(118,323),546,game.enter_game,"primary","play")
 ui.menu_start.add_theme_font_size_override("font_size",24)
 _destination("mode_endless","Endless Siege","Play escalating waves.",Vector2(118,412),546,ui.replay_ui.show_endless,"secondary","endless")
 _destination("menu_extras","Other modes & archives","Classic Campaign, practice, challenge codes and the Story archive.",Vector2(118,495),546,ui.replay_ui.show_hub,"quiet","practice")
 ui.theme_panel(Rect2(695,146,473,419),"frame")
 ui.theme_label("%d RM Cash" % profile.rm_cash,Vector2(719,165),20,216,"gold")
 ui.theme_label("%s · %d XP" % [profile.rank_name(),profile.xp],Vector2(943,165),18,207,"muted")
 var actions: Array=[
  ["menu_shop","Shop",ui.shop.show_shop,"shop","shop"],
  ["menu_inventory","Inventory",ui.items_ui.inventory,"inventory","inventory"],
  ["menu_ranks","Rank & Rewards",ui.progression.show_ranks,"accent","rank"],
  ["menu_settings","Settings",ui.show_settings,"settings","settings"],
  ["menu_help","Help",ui.show_help,"secondary","tutorial"],
  ["menu_replay","Replay Tutorial",func():game.start_tutorial(true),"secondary","retry"],
 ]
 for i in range(actions.size()):
  var entry: Array=actions[i]
  _destination(entry[0],entry[1],"",Vector2(714+(i%2)*222,220+floori(float(i)/2)*83),215,entry[2],entry[3],entry[4])
 ui.theme_button(ui.button("Exit",Vector2(1018,581),game.request_quit,150,39),"quiet")
 if not profile.pending_spins.is_empty():
  ui.theme_button(ui.button("Resume saved reward",Vector2(714,581),ui.items_ui.spin,282,39),"accent")
 elif not profile.warning.is_empty():
  ui.theme_label(profile.warning,Vector2(119,581),14,575,"danger").clip_text=true
 ui.menu_start.grab_focus()


func other_modes() -> void:
 ui.clear()
 ui.current_screen="replay_hub"
 ui.tactical_back=ui.game.return_menu
 ui.theme_backdrop()
 ui.theme_panel(Rect2(156,85,968,550),"frame")
 ui.theme_label("Other modes & archives",Vector2(198,115),38,870,"text",true)
 var choices: Array=[
  ["mode_campaign","Classic Campaign","Choose a stage and difficulty.",ui.campaign.show_stages,"next"],
  ["mode_challenge","Challenge Codes","Play a fixed seed with normalized gear.",ui.replay_ui.show_codes,"challenge"],
  ["mode_practice","Practice Room","Rehearse against a Hunter with training supplies.",ui.replay_ui.show_practice,"practice"],
  ["mode_archive","Story Archive","Revisit the chapters you have reached.",ui.campaign.story_ui.show_archive,"contract"],
  ["mode_cosmetics","Earned Cosmetics","Choose an appearance you have unlocked.",ui.replay_ui.show_cosmetics,"cosmetic"],
 ]
 for i in choices.size():
  var choice: Array=choices[i]
  var button:=_destination(choice[0],choice[1],choice[2],Vector2(199+(i%2)*447,201+floori(i/2.0)*95),422,choice[3],"secondary",choice[4])
  if i==0:button.grab_focus()
 var pity: Dictionary=ui.game.profile.replay.pity
 var odds: Label=ui.theme_label("Next victory spin · "+SpinPity.summary("victory",pity),Vector2(648,397),16,417,"muted")
 odds.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 ui.theme_button(ui.button("Back [Esc]",Vector2(199,548),ui.game.return_menu,189,48),"quiet")

func _destination(id: String, title: String, subtitle: String, at: Vector2, width: float, callback: Callable, role: String, icon: String) -> Button:
 var control: Button = ui.button(title,at,callback,width,68)
 control.name=id
 ui.theme_button(control,role,icon)
 control.alignment=HORIZONTAL_ALIGNMENT_LEFT
 control.add_theme_font_size_override("font_size",19)
 control.add_theme_constant_override("icon_max_width",30)
 control.add_theme_stylebox_override("normal",GothicTheme.living_surface(role))
 control.tooltip_text=subtitle
 return control


func _create_living() -> void:
 var game=ui.game
 var profile=game.profile
 ui.theme_panel(Rect2(65,62,1150,596),"overlay")
 ui.theme_label("NIGHTFALL DORM",Vector2(104,91),51,900,"text",true)
 ui.theme_label("Claim a bed. Build defenses. Survive the night.",Vector2(108,153),19,765,"muted")
 ui.theme_panel(Rect2(104,208,525,369),"frame")
 ui.theme_panel(Rect2(650,208,525,369),"frame")
 ui.theme_label("CHOOSE A MODE",Vector2(124,222),20,480,"gold",true)
 ui.theme_label("SUPPLIES & PROFILE",Vector2(674,222),20,480,"gold",true)
 if game.story_preview_enabled:
  var mode: String=profile.selected_difficulty
  var track:=StoryProgress.summary(profile.story,mode)
  var mission:=StoryCatalog.mission(track.position)
  var story_label: String="Continue Story" if track.highest > 0 else "Start Story"
  if track.finished:
   story_label="Story Archive"
  var subtitle: String="All 50 levels cleared" if track.finished else "Level %02d / 50 · %s" % [track.position,mission.title]
  ui.menu_start=_destination("mode_story",story_label,subtitle,Vector2(124,268),485,game.enter_game,"primary","play")
  ui.theme_label(subtitle,Vector2(180,337),15,423,"muted")
  _destination("mode_endless","Endless","Defend the same room through escalating waves.",Vector2(124,375),485,ui.replay_ui.show_endless,"secondary","endless")
  _destination("mode_campaign","Campaign","Choose a stage and difficulty.",Vector2(124,459),485,ui.campaign.show_stages,"secondary","next")
 else:
  ui.menu_start=_destination("mode_campaign","Campaign","Choose a stage and difficulty.",Vector2(124,268),485,game.enter_game,"primary","play")
  _destination("mode_endless","Endless","Defend the same room through escalating waves.",Vector2(124,375),485,ui.replay_ui.show_endless,"secondary","endless")
 _destination("menu_shop","Shop","Buy common supplies with in-game RM Cash.",Vector2(674,268),226,ui.shop.show_shop,"shop","shop")
 _destination("menu_inventory","Inventory","View owned supplies and equip up to two types.",Vector2(924,268),226,ui.items_ui.inventory,"inventory","inventory")
 _destination("menu_ranks","Rank & Rewards","View rank progress and claim rewards.",Vector2(674,355),226,ui.progression.show_ranks,"accent","rank")
 _destination("menu_settings","Settings","Adjust graphics, audio and guidance.",Vector2(924,355),226,ui.show_settings,"settings","settings")
 ui.theme_label("Wallet · %d RM Cash" % profile.rm_cash,Vector2(678,435),17,224,"gold")
 ui.theme_label("%s · %d XP" % [profile.rank_name(),profile.xp],Vector2(926,435),16,224,"muted")
 var extras: Button=ui.button("Challenge, Practice & Cosmetics",Vector2(674,502),ui.replay_ui.show_hub,476,44)
 extras.name="menu_extras"
 ui.theme_button(extras,"quiet")
 var utilities: Array = [
  ["How to Play",ui.show_help],
  ["Replay Tutorial",func():game.start_tutorial(true)],
  ["Exit",game.request_quit],
 ]
 for i in range(utilities.size()):
  var utility: Button=ui.button(utilities[i][0],Vector2(104+i*194,600),utilities[i][1],180,38)
  ui.theme_button(utility,"quiet")
 if not profile.pending_spins.is_empty():
  var spin: Button=ui.button("Resume Lucky Spin",Vector2(924,600),ui.items_ui.spin,226,38)
  ui.theme_button(spin,"accent")
 elif not profile.warning.is_empty():
  var warning: Label=ui.theme_label(profile.warning,Vector2(653,586),13,492,"danger")
  warning.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 ui.menu_start.grab_focus()
