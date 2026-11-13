extends SceneTree
# Actual controls and real input on prepared qualified profile. D owns raster quality.
var checks=0
var failures=0
var game
var profile_path="user://premium-ui-"+str(Time.get_ticks_usec())+".json"
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("PREMIUM UI: "+label)
func controls(node,type):
 var out=[]
 for child in node.get_children():
  if child.is_queued_for_deletion():continue
  if is_instance_of(child,type):out.append(child)
  out.append_array(controls(child,type))
 return out
func settle():
 await process_frame
 # Ordinary screenshot/inspection actions wait for the new real drawer slide.
 # Transition-time input safety has its own independent adversarial gate.
 if game!=null and is_instance_valid(game) and game.mode=="match" and game.ui.bottom_context!=null:
  var deadline=Time.get_ticks_msec()+1500
  while game.ui.bottom_context.is_transitioning() and Time.get_ticks_msec()<deadline:await process_frame
 await process_frame
func inside(a,b):return a.position.x>=b.position.x-.1 and a.position.y>=b.position.y-.1 and a.end.x<=b.end.x+.1 and a.end.y<=b.end.y+.1
func find(text):
 for b in controls(game.ui.panel,Button):
  if b.text==text:return b
 return null
func click(b,double_click=false):
 await settle()
 check(b!=null and b.is_visible_in_tree() and not b.disabled,"real mouse target is available")
 if b==null or not b.is_visible_in_tree() or b.disabled:return
 var point=root.get_final_transform()*b.get_global_rect().get_center()
 var motion=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;Input.parse_input_event(motion);await process_frame
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.double_click=double_click if pressed else false
  Input.parse_input_event(event);await process_frame
 await settle()
func screen(name):
 var visible=[]
 for b in controls(game.ui.panel,Button):
  if not b.is_visible_in_tree():continue
  visible.append(b)
  check(inside(b.get_global_rect(),Rect2(0,0,1280,720)),name+" button fits logical viewport: "+b.text)
  for state in ["normal","hover","pressed","disabled","focus"]:check(b.get_theme_stylebox(state) is StyleBoxTexture,name+" dimensional button material: "+state)
  check(b.focus_mode!=Control.FOCUS_NONE,name+" keyboard focus remains available")
 for i in range(visible.size()):
  for j in range(i):check(not visible[i].get_global_rect().intersects(visible[j].get_global_rect()),name+" interactive buttons do not overlap: "+visible[i].text+" "+str(visible[i].get_global_rect())+" / "+visible[j].text+" "+str(visible[j].get_global_rect()))
 for label in controls(game.ui.panel,Label):
  if label.is_visible_in_tree():check(inside(label.get_global_rect(),Rect2(0,0,1280,720)),name+" label fits logical viewport: "+label.text.left(35))
func artwork():
 var hashes=[]
 for id in ["play","shop","inventory","loadout","rank","achievement","tutorial","settings","pause","next","retry","build","repair","upgrade","sell","gold","power","cash","standard","hard","hell","crusher","stalker","ravager","precision","suppression","focus","storm","contract"]:
  var path="res://assets/premium_ui/"+id+".svg"
  check(ResourceLoader.exists(path) and PremiumButton.texture(id)!=null,"original local actionable artwork: "+id)
  var hash=FileAccess.get_file_as_string(path).sha256_text()
  check(hash not in hashes,"action/currency/mode artwork is distinct: "+id);hashes.append(hash)
 for font in [game.ui.default_font,game.ui.horror_font]:
  for code in range(32,127):check(font.has_char(code),"bundled typography covers English ASCII "+str(code))
 check(game.ui.horror_font!=game.ui.default_font,"heading and body fonts are genuinely separate bundled resources")
func ink_vertical(label):
 # Label rectangles include unused Gothic ascender/descent space. Measure actual
 # local-font raster glyph ink at the same shaped line baselines instead.
 var font=label.get_theme_font("font");var size=label.get_theme_font_size("font_size")
 var ts=TextServerManager.get_primary_interface();var rid=font.get_rids()[0]
 var baseline=label.get_global_rect().position.y+font.get_ascent(size)
 var top=INF;var bottom=-INF;var line=0
 for text in label.text.split("\n"):
  for index in range(text.length()):
   var glyph=ts.font_get_glyph_index(rid,size,text.unicode_at(index),0)
   ts.font_render_glyph(rid,Vector2i(size,0),glyph)
   var offset=ts.font_get_glyph_offset(rid,Vector2i(size,0),glyph)
   var ink=ts.font_get_glyph_size(rid,Vector2i(size,0),glyph)
   if ink.y>0:
    top=minf(top,baseline+offset.y);bottom=maxf(bottom,baseline+offset.y+ink.y)
  baseline+=label.get_line_height(line)+label.get_theme_constant("line_spacing");line+=1
 return Vector2(top,bottom)
func menu_text():
 var title=null;var subtitle=null
 for label in controls(game.ui.panel,Label):
  if label.text=="NIGHTFALL\nDORM":title=label
  if label.text=="—  THE NIGHT WATCH  —":subtitle=label
 check(title!=null and subtitle!=null,"actual main wordmark and subtitle exist")
 if title!=null and subtitle!=null:
  check(title.get_line_count()==2,"horror wordmark retains intentional two-line typography")
  var title_ink=ink_vertical(title);var subtitle_ink=ink_vertical(subtitle)
  print("PREMIUM_MENU_INK title=",title_ink," subtitle=",subtitle_ink)
  check(is_finite(title_ink.x) and is_finite(subtitle_ink.x) and title_ink.y<=subtitle_ink.x-3,"actual raster glyph ink clears subtitle: "+str(title_ink)+" / "+str(subtitle_ink))
 for text in ["Start Game","How to Play","Settings","Consumable inventory","Shop · Common supplies","Replay Tutorial"]:
  var b=find(text)
  check(b!=null,"important menu action exists: "+text)
  if b==null:continue
  var style=b.get_theme_stylebox("normal")
  var icon_width=0.0
  if b.icon!=null:
   icon_width=float(b.icon.get_width())
   if b.expand_icon:icon_width*=maxf(0,b.size.y-style.get_minimum_size().y)/maxf(1,b.icon.get_height())
   var limit=b.get_theme_constant("icon_max_width")
   if limit>0:icon_width=minf(icon_width,limit)
  var text_width=b.get_theme_font("font").get_string_size(b.text,HORIZONTAL_ALIGNMENT_LEFT,-1,b.get_theme_font_size("font_size")).x
  var needed=text_width+icon_width+(b.get_theme_constant("h_separation") if icon_width>0 else 0)+style.get_minimum_size().x
  if b.size.x<=180:print("PREMIUM_MENU_TEXT ",text," needed=",needed," available=",b.size.x)
  check(needed<=b.size.x+.1,"full menu text plus actual icon and padding fit without ellipsis: "+text+" "+str(needed)+"/"+str(b.size.x))
func preparation():
 game.campaign_mode=true;game.ui.progression.show_loadout();await settle();screen("preparation")
 var modes={}
 for id in ["standard","hard","hell"]:
  var b=game.ui.panel.find_child("mode_"+id,false,false)
  check(b!=null and b.tooltip_text!="","mode has actual card and gameplay explanation")
  modes[id]=b.get_global_rect()
  check(controls(game.ui.panel,Label).any(func(l):return l.text==RankCatalog.DIFFICULTIES[id].name.to_upper()),"mode has readable text identity")
 check(modes.standard.size==modes.hard.size and modes.hard.size==modes.hell.size,"difficulty cards keep consistent hit-target dimensions")
 var hell=game.ui.panel.find_child("mode_hell",false,false);await click(hell);await settle()
 check(game.ui.progression.difficulty=="hell" and game.profile.selected_difficulty=="hell","actual Hell card persists chosen mode")
 check(controls(game.ui.panel,Label).any(func(l):return l.text=="SELECTED ✓"),"chosen difficulty has non-color selected feedback")
 await click(find("Optional contracts"));await settle();screen("contracts")
 var candidates=[]
 for b in controls(game.ui.panel,Button):
  if b.text=="Choose contract":candidates.append(b)
 check(candidates.size()==3,"three optional contracts are accessible")
 await click(candidates[0]);await settle()
 check(game.profile.selected_contract=="no_legendary","actual contract button saves choice")
 check(controls(game.ui.panel,Label).any(func(l):return l.text.contains("without triggering any Legendary")),"contract objective is actually displayed")
 await click(find("No contract · standard match"));await settle()
 check(game.profile.selected_contract=="","opting out is an actual functional control")
 await click(find("Confirm & return"));await settle()
 await click(find("Permanent perk loadout"));await settle();screen("perks")
 check(game.ui.current_screen=="perk_loadout","permanent perks retain accessible dedicated screen")
 await click(find("Back to preparation"));await settle()
func match_and_branch():
 check(game.start_stage("stage_1","standard"),"real scene starts strategic stage")
 game.set_process(false);await settle()
 var m=game.model
 game.ui.update_match();await settle()
 check(m.strategy.enabled and game.ui.tutorial_text().contains(StrategyCatalog.TRAITS[m.rooms[0].trait_id].name),"real room-selection guide explains actual trait")
 m.player_position=m.rooms[0].center();m.rooms[0].owner=1
 var nearest=null
 for candidate in m.rooms:
  if candidate.owner<0 and (nearest==null or candidate.center().distance_to(m.player_position)<nearest.center().distance_to(m.player_position)):nearest=candidate
 check(nearest!=null and game.ui.tutorial_text().begins_with("ROOM %d ·" % (nearest.index+1)),"nearby occupied room0 cannot hide the true nearest available room")
 for candidate in m.rooms:candidate.owner=candidate.index+1
 check(not game.ui.tutorial_text().begins_with("ROOM "),"all-occupied guide honestly reports no room instead of suggesting an invalid claim")
 for candidate in m.rooms:candidate.owner=-1
 check(game.ui.hunter_label.tooltip_text.contains(StrategyCatalog.ARCHETYPES[m.hunter.archetype].name),"actual Hunter identity and counterplay accessible in HUD")
 m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 m.rooms[1].owner=1;m.rooms[1].sleeping=true;m.rooms[1].closed=true
 game.ui.update_match()
 check(game.ui.hunter_detail.text.contains("TEAM2") or game.ui.hunter_detail.text.contains("TEAM 2"),"strategy HUD retains true living-owned team count")
 m.rooms[1].alive=false;game.ui.update_match()
 check(game.ui.hunter_detail.text.contains("TEAM1") or game.ui.hunter_detail.text.contains("TEAM 1"),"strategy HUD team count responds to real survivor state")
 var r=m.player();r.gold=30000;r.electricity=30000;r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp()
 check(m.buy("turret",0),"UI branch fixture pays real purchase")
 for i in range(3):check(m.upgrade_building(0),"UI branch fixture pays early tiers")
 game.selected_tile=0;game.ui.open_context();game.ui.upgrade_selected();await settle();screen("specialization")
 check(game.ui.context_mode=="specialize","real selected-upgrade action opens milestone choice")
 var options=[]
 for b in controls(game.ui.context_box,Button):
  if b.name.begins_with("specialization_"):options.append(b)
 check(options.size()==2,"exactly two mutually exclusive branch choices")
 for b in options:
  check(b.icon!=null and inside(b.get_global_rect(),game.ui.context_box.get_global_rect()),"branch art/control fits actual inspector")
  check(b.text.contains("Gold /") and b.tooltip_text.contains("One branch only"),"branch actual price/tradeoff is visible")
 var wallet=[r.gold,r.electricity];var quote=Catalog.upgrade_cost("turret",4)+StrategyCatalog.BRANCH_FEE
 await click(options[0]);await settle()
 check(r.buildings[0].level==4 and r.gold==wallet[0] and r.electricity==wallet[1],"branch preview cannot spend before explicit confirmation")
 await click(game.ui.branch_confirm);await settle()
 check(r.buildings[0].level==5 and r.buildings[0].specialization=="precision","actual branch mouse input buys one specialization")
 check(absf(wallet[0]-r.gold-quote.x)<.00001 and absf(wallet[1]-r.electricity-quote.y)<.00001,"branch UI charges actual exact Gold and Electricity")
 check(game.ui.context_mode=="upgrade" and game.ui.selected_details.text.contains("Heavy Precision"),"successful branch returns to truthful selected-building progression")
 game.ui.update_match();screen("specialized HUD")
 check(game.ui.actions.upgrade.text.contains("6"),"specialized turret retains next-level upgrade action")
 var owned=game.profile._reward_snapshot();game.toggle_pause();await settle()
 check(not m.running,"pause control stops actual match")
 await click(find("Resume"));await settle()
 check(m.running and game.profile._reward_snapshot()==owned,"actual Resume preserves all saved progression")
func refund_labels():
 # Real paid max tiers, including coupon-discounted branch fees; no forged ledgers.
 game.profile.item_loadout=["coupon"]
 for kind in ["turret","heavy"]:
  for discounted in [false,true]:
   game.return_menu()
   check(game.start_stage("stage_1","standard"),"refund UI fixture starts actual equipped match")
   game.set_process(false);await settle()
   var m=game.model;m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
   var r=m.player();r.gold=30000;r.electricity=30000;r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp()
   check(m.buy(kind,0),"refund UI pays actual base purchase")
   for i in range(3):check(m.upgrade_building(0),"refund UI pays actual early tiers")
   var stock=int(game.profile.inventory.coupon)
   if discounted:check(game.activate_item(0),"refund UI coupon arms through real inventory")
   var wallet=[r.gold,r.electricity]
   var quote=(Catalog.upgrade_cost(kind,4)+StrategyCatalog.BRANCH_FEE)*(.6 if discounted else 1)
   check(m.specialize_building(0,StrategyCatalog.branches(kind)[0]),"refund UI pays actual specialization")
   check(absf(wallet[0]-r.gold-quote.x)<.00001 and absf(wallet[1]-r.electricity-quote.y)<.00001,"refund UI branch pays exact discounted/ordinary Gold and Electricity")
   check(game.profile.inventory.coupon==stock-(1 if discounted else 0),"refund UI discounted branch consumes exactly one coupon")
   while r.buildings[0].level<10:check(m.upgrade_building(0),"refund UI pays actual prestige tier")
   game.selected_tile=0;game.ui.open_context();game.ui.update_match();await settle()
   var b=game.ui.actions.sell;var refund=r.building_refund(0)
   check(b.is_visible_in_tree() and not b.disabled and b.icon!=null,"real max-tier Sell remains actionable with recognizable icon")
   check(b.text=="Sell · 50%% actual investment\n+%.2f Gold / +%.2f Electricity" % [refund.x,refund.y],"Sell names both actual resource refunds and50% without abbreviated amounts")
   var style=b.get_theme_stylebox("normal")
   var icon_width=minf(b.get_theme_constant("icon_max_width"),float(b.icon.get_width())*(b.size.y-style.get_minimum_size().y)/b.icon.get_height())
   var text_width=0.0
   for line in b.text.split("\n"):text_width=maxf(text_width,b.get_theme_font("font").get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,b.get_theme_font_size("font_size")).x)
   var required=text_width+icon_width+b.get_theme_constant("h_separation")+style.get_minimum_size().x
   print("PREMIUM_SELL_TEXT ",kind," discounted=",discounted," required=",required," available=",b.size.x," text=",b.text)
   check(required<=b.size.x+.1 and b.get_theme_font_size("font_size")>=16,"both exact max-tier refunds and50% fit actual icon/glyph/padding budget")
   check(inside(b.get_global_rect(),game.ui.context_box.get_global_rect()),"max-tier Sell hit target remains inside inspector")
   wallet=[r.gold,r.electricity];await click(b);await settle()
   check(not r.buildings.has(0) and absf(r.gold-wallet[0]-refund.x)<.00001 and absf(r.electricity-wallet[1]-refund.y)<.00001,"actual Sell click transfers the exact displayed resource refunds")
func tutorial_reentry():
 var snapshot=game.profile._reward_snapshot()
 game.level_warning_time=3;game.danger_time=1;game.last_hunter_level=9;game.last_attacks=100;game.last_shots=100
 game.floating=[{"text":"STALE COMBAT"}];game.last_income={0:999};game.income_clock=5;game.ui_clock=5
 check(game.start_tutorial(true),"existing Replay Tutorial starts safely after combat presentation")
 game.set_process(false);game.ui.update_match();await settle()
 check(game.tutorial_active and game.model.tutorial_mode and not game.model.strategy.enabled,"replay retains nine-step safe practice isolation")
 check(game.level_warning_time==0 and game.danger_time==0 and game.last_hunter_level==1 and game.last_attacks==0 and game.last_shots==0,"practice resets inherited Hunter danger/level/shot feedback")
 check(game.floating.is_empty() and game.last_income.is_empty() and game.income_clock==0 and game.ui_clock==0,"practice clears stale floating/income feedback")
 check(not game.ui.warning_box.visible and not game.ui.warning_label.visible and game.ui.hunter_label.text.contains("SAFE PRACTICE"),"safe practice cannot show stale Hunter growth or danger ribbon")
 check(game.profile._reward_snapshot()==snapshot,"tutorial reentry cannot mutate active receipt/inventory/rewards")
 var exit=null
 for b in controls(game.onboarding,Button):
  if b.text=="Exit practice":exit=b
 await click(exit);await settle()
 check(not game.tutorial_active and game.mode=="menu","actual Exit practice returns to menu")
func run():
 OS.set_environment("NIGHTFALL_PROFILE_PATH",profile_path)
 DirAccess.copy_absolute("res://docs/evidence/premium-strategy/qa-legacy-profile.json",profile_path)
 var p=PlayerProfile.new(profile_path);check(p.load_profile(),"prepared real old profile loads")
 p.pending_spins=[];check(p.save_profile(),"fixture clears already-rolled notification before menu flow")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
 game.set_process(false);preload("res://tests/onboarding_test_support.gd").skip(game);await settle();artwork()
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  game.profile.settings.reduced_effects=resolution.x>1280
  root.size=resolution;game.return_menu();await settle();screen("menu"+str(resolution))
  menu_text()
  check(find("Start Game").icon!=null and find("Settings").icon!=null,"main actions include recognizable icons")
  var settings=find("Settings");settings.grab_focus();await settle()
  check(settings.has_focus(),"Windows keyboard focus can reach Settings")
  await create_timer(.15).timeout
  check(settings.self_modulate.r>1.05,"keyboard focus produces actual animated/reduced-effects emphasis")
  var key=InputEventKey.new();key.keycode=KEY_ENTER;key.pressed=true;Input.parse_input_event(key);await process_frame
  key=InputEventKey.new();key.keycode=KEY_ENTER;key.pressed=false;Input.parse_input_event(key);await settle()
  check(game.ui.current_screen=="settings","real Enter key activates focused Settings")
  screen("settings");game.return_menu();await settle()
  await click(find("Start Game"));await settle();screen("stages")
  check(game.ui.current_screen=="stages","real main Play click retains stage progression action")
  await preparation()
  for name in ["shop","inventory","ranks","achievements"]:
   match name:
    "shop":game.ui.shop.show_shop()
    "inventory":game.ui.items_ui.inventory()
    "ranks":game.ui.progression.show_ranks()
    "achievements":game.ui.progression.show_achievements()
   await settle();screen(name)
  await match_and_branch()
  await refund_labels()
  await tutorial_reentry()
 game.audio_system.shutdown()
 var until=Time.get_ticks_msec()+550
 while Time.get_ticks_msec()<until:await process_frame
 game.queue_free();await process_frame
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(profile_path+suffix):DirAccess.remove_absolute(profile_path+suffix)
 print("PREMIUM_UI_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
