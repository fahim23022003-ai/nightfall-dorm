extends SceneTree
# Prepared graduate profile; actual controls/layout/materials at two Windows targets.
var checks=0
var failures=0
var game
var profile_path="user://visual-ui-"+str(Time.get_ticks_usec())+".json"
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("VISUAL UI: "+label)
func controls(node,type):
 var out=[]
 for child in node.get_children():
  if child.is_queued_for_deletion():continue
  if is_instance_of(child,type):out.append(child)
  out.append_array(controls(child,type))
 return out
func settle():
 await process_frame
 await process_frame
func inside(a,b):return a.position.x>=b.position.x-.1 and a.position.y>=b.position.y-.1 and a.end.x<=b.end.x+.1 and a.end.y<=b.end.y+.1
func check_screen(name):
 var buttons=controls(game.ui.panel,Button)
 check(not buttons.is_empty(),name+" has functional buttons")
 for b in buttons:
  if not b.is_visible_in_tree():continue
  check(inside(b.get_global_rect(),Rect2(0,0,1280,720)),name+" button inside logical viewport: "+b.text)
  for state in ["normal","hover","pressed","disabled","focus"]:
   check(b.get_theme_stylebox(state) is StyleBoxTexture,name+" consistent material state "+state)
func card_buttons(screen,selector,card_width):
 var cards=[]
 for node in controls(game.ui.panel,Panel):
  if is_equal_approx(node.size.x,card_width):cards.append(node)
 var selected=[]
 for b in controls(game.ui.panel,Button):
  if selector.call(b):selected.append(b)
 check(not selected.is_empty(),screen+" compact actions present")
 for b in selected:
  var found=false
  for card in cards:
   if inside(b.get_global_rect(),card.get_global_rect()):found=true;break
  check(found,screen+" compact action fits its visible card: "+b.text+" "+str(b.get_rect()))
func run():
 OS.set_environment("NIGHTFALL_PROFILE_PATH",profile_path)
 var p=PlayerProfile.new(profile_path);p.tutorial_completed=true;p.xp=8000;p.next_match_id=7
 p.statistics={"matches":5,"victories":5,"defeats":0,"standard":0,"hard":0,"hell":5,"reaper_defeats":3}
 for i in range(5):p.campaign_records[StageCatalog.STAGES[i].id]={"clears":1,"best_time":180.0,"best_damage":2000.0,"best_xp":200,"difficulty":"hell","first_match_id":i+1}
 p.highest_rank=6;p.rm_cash=100
 for id in ItemCatalog.IDS:p.inventory[id]=3
 check(p.save_profile(),"prepared profile saves")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await settle()
 game.set_process(false);game.onboarding.skip();await settle()
 check(game.mode=="menu" and game.profile.rank_index()==6,"prepared qualified Mythic profile opens real menu after skip")
 var snapshot=game.profile._reward_snapshot()
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution
  for screen in ["menu","stages","loadout","shop","ranks","achievements","settings"]:
   match screen:
    "menu":game.return_menu()
    "stages":game.ui.campaign.show_stages()
    "loadout":game.ui.progression.show_loadout()
    "shop":game.ui.shop.show_shop()
    "ranks":game.ui.progression.show_ranks()
    "achievements":game.ui.progression.show_achievements()
    "settings":game.ui.show_settings()
   await settle();check_screen(screen+str(resolution))
   if screen=="shop":card_buttons(screen,func(b):return b.text.begins_with("Buy"),480)
   if screen=="achievements":card_buttons(screen,func(b):return b.text in ["Claim reward","Claimed"],530)
  for page in range(3):
   game.ui.items_ui.inventory_page=page;game.ui.items_ui.inventory();await settle()
   check_screen("inventory"+str(page)+str(resolution))
   card_buttons("inventory"+str(page),func(b):return b.text in ["Equip","Equipped ✓"],540)
 check(game.profile._reward_snapshot()==snapshot,"pure screen navigation cannot grant/spend/lose saved progression")
 # Repeated screen changes must reuse materials rather than make a texture every draw.
 var cache=GothicTheme.materials.size()
 for i in range(10):
  game.ui.shop.show_shop();await settle();game.return_menu();await settle()
 check(GothicTheme.materials.size()==cache,"repeated known screens keep texture cache stable")
 game.audio_system.shutdown()
 var until=Time.get_ticks_msec()+550
 while Time.get_ticks_msec()<until:await process_frame
 game.queue_free();await process_frame
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(profile_path+suffix):DirAccess.remove_absolute(profile_path+suffix)
 print("VISUAL_UI_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
