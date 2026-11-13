extends SceneTree
var checks=0
var failures=0
var game
func check(value,label):
 checks+=1
 if not value:failures+=1;push_error("MENU "+label)
func key(code):
 var e=InputEventKey.new();e.keycode=code;e.pressed=true;Input.parse_input_event(e);await process_frame
 e=InputEventKey.new();e.keycode=code;e.pressed=false;Input.parse_input_event(e);await process_frame
func click(at):
 at=root.get_final_transform()*at
 var motion=InputEventMouseMotion.new();motion.position=at;Input.parse_input_event(motion);await process_frame
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;Input.parse_input_event(event);await process_frame
func named(title):
 for node in game.ui.panel.get_children():
  if node is Button and not node.is_queued_for_deletion() and node.text==title:return node
 return null
func fresh(path,returning):
 var profile=PlayerProfile.new(path);profile.tutorial_completed=returning;profile.xp=360;profile.rm_cash=123;profile.inventory={"shield":3,"repair":2};profile.save_profile()
 OS.set_environment("NIGHTFALL_PROFILE_PATH",path)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);await process_frame
 return FileAccess.get_file_as_bytes(path)
func destroy():
 game.audio_system.shutdown();await create_timer(.55).timeout;game.queue_free();await process_frame
func _initialize():call_deferred("run")
func run():
 var serial=str(Time.get_ticks_usec())
 for pixels in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=pixels;await process_frame
  var path="user://focused-menu-"+serial+"-"+str(pixels.x)+".json";var bytes=await fresh(path,true)
  check(game.onboarding.is_welcome_open(),"returning fresh app shows welcome")
  var close=game.onboarding.welcome_close
  check(close.size.x>=48 and Rect2(Vector2.ZERO,Vector2(1280,720)).encloses(close.get_rect()),"large close control inside window")
  await key(KEY_ESCAPE);await click(Vector2(90,430));game.onboarding._process(100)
  check(game.onboarding.is_welcome_open() and game.ui.current_screen=="menu","Escape/background/time never dismiss")
  game.ui.menu_start.pressed.emit();check(game.ui.current_screen=="menu","modal blocks underlying synthetic callback")
  await click(close.get_global_rect().get_center());check(not game.onboarding.is_welcome_open(),"real X mouse closes")
  check(root.gui_get_focus_owner()==game.ui.menu_start,"focus returns Start")
  check(game.profile.xp==360 and game.profile.rm_cash==123 and game.profile.inventory.shield==3,"real profile data retained")
  var rank_card=named("RANK & REWARDS");var shop_card=named("SHOP");var inv_card=named("INVENTORY")
  var meter=rank_card.get_node("RankProgress");var labels=rank_card.get_children().filter(func(n):return n is Label)
  var child_count=rank_card.get_child_count()
  check(meter.mouse_filter==Control.MOUSE_FILTER_IGNORE and meter.focus_mode==Control.FOCUS_NONE,"XP meter is display-only")
  check(meter.get_theme_stylebox("background") is StyleBoxFlat,"XP track uses clean progress material")
  check(is_equal_approx(meter.size.y,8.0),"actual laid-out XP meter stays eight pixels tall")
  for label in labels:check(not meter.get_global_rect().intersects(label.get_global_rect()),"actual meter stays clear of caption "+label.text)
  game.profile.xp=400;game.profile.rm_cash=222;game.profile.inventory.shield=4
  await create_timer(.25).timeout
  check(is_equal_approx(meter.value,150.0/450.0) and labels.any(func(l):return l.text=="150 / 450 XP this rank"),"live XP numerator/denominator and fill agree")
  check(shop_card.get_children().any(func(n):return n is Label and n.text=="222"),"wallet updates while menu visible")
  check(inv_card.get_children().any(func(n):return n is Label and n.text=="6 items"),"owned inventory count updates while visible")
  game.profile.xp=900;await create_timer(.25).timeout
  check(is_equal_approx(meter.value,200.0/700.0) and labels.any(func(l):return l.text=="Gold"),"rank promotion uses existing real thresholds")
  check(rank_card.get_child_count()==child_count,"data refresh creates no extra menu nodes")
  game.profile.xp=360;game.profile.rm_cash=123;game.profile.inventory.shield=3
  await create_timer(.25).timeout
  for title in ["Start Game","Endless Siege","SHOP","RANK & REWARDS","INVENTORY","How to Play","Settings","Extras · Challenge / Practice / Cosmetics"]:
   var b=named(title);check(b!=null and Rect2(Vector2.ZERO,Vector2(1280,720)).encloses(b.get_rect()),"visible clickable destination "+title)
   b.grab_focus();check(b.has_focus(),"keyboard focus "+title)
   await click(b.get_global_rect().get_center())
   var expected={"Start Game":"stages","Endless Siege":"endless_setup","SHOP":"shop","INVENTORY":"inventory","How to Play":"help","Settings":"settings","Extras · Challenge / Practice / Cosmetics":"replay_hub"}
   if expected.has(title):check(game.ui.current_screen==expected[title],"actual destination "+title+" got "+game.ui.current_screen)
   else:check(game.ui.current_screen!="menu" or game.ui.panel.get_children().any(func(n):return n is Label and "lifetime XP" in n.text),"rank destination")
   game.ui.show_menu();await process_frame;check(not game.onboarding.is_welcome_open(),"same session menu no reopen")
  rank_card=named("RANK & REWARDS");meter=rank_card.get_node("RankProgress");labels=rank_card.get_children().filter(func(n):return n is Label)
  game.profile.pending_spins=[{"match_id":1,"item":"shield","result":"victory","quantity":1}]
  game.profile.rm_cash=OnboardingCatalog.MAX_CASH;game.profile.xp=RankCatalog.MAX_XP;game.profile.highest_rank=6
  for id in ItemCatalog.IDS:game.profile.inventory[id]=ItemCatalog.MAX_STOCK
  await create_timer(.25).timeout
  check(meter.value==1.0 and labels.any(func(l):return "XP · MAX" in l.text),"live maximum rank remains accurate")
  game.ui.show_menu();await process_frame
  var controls=game.ui.panel.get_children().filter(func(node):return node is Button and not node.is_queued_for_deletion())
  for i in range(controls.size()):
   for j in range(i+1,controls.size()):check(not controls[i].get_global_rect().intersects(controls[j].get_global_rect()),"menu hit areas do not overlap "+controls[i].text+" / "+controls[j].text)
  var resume=named("Resume Lucky Spin");var extras=named("Extras · Challenge / Practice / Cosmetics")
  check(resume!=null and not resume.get_rect().intersects(extras.get_rect()),"pending spin remains distinct from Extras")
  for destination in game.ui.panel.get_children():
   if destination is MenuDestination:
    for label in destination.get_children():
     if label is Label:
      check(Rect2(Vector2.ZERO,destination.size).encloses(label.get_rect()),"card label stays inside silhouette "+label.text)
      check(label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x<=label.size.x,"large real data label fits "+label.text)
  await click(resume.get_global_rect().get_center());check(game.ui.current_screen=="spin","pending spin callback retained")
  game.ui.show_menu();await process_frame
  await click(named("Replay Tutorial").get_global_rect().get_center());check(game.tutorial_active,"Replay Tutorial callback retained")
  check(FileAccess.get_file_as_bytes(path)==bytes,"profile bytes unchanged by focused UI")
  await destroy()
  bytes=await fresh(path,true);check(game.onboarding.is_welcome_open(),"second fresh app shows welcome")
  game.onboarding.welcome_close.grab_focus();await key(KEY_SPACE);check(not game.onboarding.is_welcome_open(),"real focused Space activates X")
  await destroy()
 var path="user://focused-menu-first-"+serial+".json";await fresh(path,false)
 check(game.onboarding.phase=="cinematic","first time cinematic retained")
 game.onboarding.elapsed=14.99;game.onboarding._process(.02);check(game.onboarding.is_welcome_open(),"cinematic automatically reaches Welcome")
 await key(KEY_ENTER);check(game.mode=="menu" and not game.tutorial_active and not game.profile.tutorial_completed,"X Enter does not auto launch/reset tutorial")
 await click(game.ui.menu_start.get_global_rect().get_center());check(game.tutorial_active,"Start retains first-time tutorial flow")
 await destroy()
 print("FOCUSED_MENU_CHECKS=%d FAILURES=%d" % [checks,failures]);quit(1 if failures else 0)
