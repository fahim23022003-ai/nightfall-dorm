extends SceneTree
# Real controller/model routes and input; fixture positioning is documented, D owns rendered walkthrough.
var checks=0
var failures=0
var game
var serial=0
var prefix="user://onboarding-flow-"
func _initialize():prefix+=str(Time.get_ticks_usec())+"-";call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("ONBOARDING FLOW: "+label)
func create(completed=false):
 serial+=1;var path=prefix+str(serial)+".json"
 if completed:
  var p=PlayerProfile.new(path);p.tutorial_completed=true;p.save_profile()
 OS.set_environment("NIGHTFALL_PROFILE_PATH",path)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 await process_frame
 game.set_process(false);game.onboarding.set_process(false)
 return game
func dispose():
 game.audio_system.shutdown();await create_timer(.5).timeout
 game.queue_free();await process_frame
func key(code):
 for pressed in [true,false]:
  var event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
  Input.parse_input_event(event);await process_frame
func mouse_button(button,double_click=false):
 var point=root.get_final_transform()*button.get_global_rect().get_center()
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.position=point;event.global_position=point
  event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.double_click=double_click if pressed else false
  Input.parse_input_event(event);await process_frame
func walk_to(target):
 var m=game.model
 var path=m.navigation_path(m.player_position,target,true)
 for point in path:
  var safety=0
  while m.player_position.distance_to(point)>2 and safety<1000:
   m.move_player((point-m.player_position).normalized(),.02);game.onboarding.tutorial_tick(.02);safety+=1
 check(m.player_position.distance_to(target)<8,"actual player motion reaches target")
func practice_tick(seconds):
 var safety=0
 while seconds>0 and safety<10000:
  var delta=minf(seconds,.05)
  game.model.tick(delta);game.onboarding.tutorial_tick(delta)
  seconds-=delta;safety+=1
func buy(kind,tile):
 game.selected_tile=tile;game.begin_placement(kind)
 return game.confirm_placement()
func graduate(replay=false):
 var fx=game.onboarding;var m=game.model
 check(fx.phase=="tutorial" and fx.step==0 and m.tutorial_mode,"actual practice model starts")
 fx.save_completion();check(not game.profile.tutorial_completed or replay,"cannot complete before lesson")
 m.move_player(Vector2.RIGHT,.25);m.move_player(Vector2.RIGHT,.1);fx.tutorial_tick(.1)
 check(fx.step==1,"successful actual movement completes first lesson")
 await walk_to(m.rooms[0].bed_position()+Vector2(31,49))
 await key(KEY_E);fx.tutorial_tick(.1)
 check(m.player()!=null and fx.step==2,"actual E claims a room")
 if m.player()==null:return
 await key(KEY_E);fx.tutorial_tick(.1)
 check(m.player().sleeping and fx.step==3,"actual E sleeps and locks door")
 var r=m.player();var gold=r.gold
 practice_tick(2)
 check(r.gold>gold and r.income_total>=3 and fx.step==4,"real occupied bed generates Gold")
 check(r.electricity==0,"bed does not generate electricity")
 fx.recover();check(buy("generator",0),"practice Dynamo purchased using real placement")
 practice_tick(2)
 check(r.electricity>0 and fx.step==5,"real generator produces separate Electricity")
 var near=-1;var far=-1
 for tile in range(r.tile_count()):
  if r.buildings.has(tile):continue
  var distance=r.tile_position(tile).distance_to(r.door_approach())
  if distance<=Catalog.BUILDINGS.turret.range and near<0:near=tile
  if distance>Catalog.BUILDINGS.turret.range:far=tile
 if far>=0:
  check(buy("turret",far),"out of range practice turret can be bought")
  fx.tutorial_tick(.1)
  check(fx.step==5,"far turret cannot satisfy real defense lesson")
  r.sell_building(far)
 check(near>=0 and buy("turret",near),"real in-range defense purchased")
 fx.tutorial_tick(.1)
 check(fx.step==6 and r.door_hp<r.max_hp(),"upgrade/repair lesson has real damage")
 check(m.upgrade_building(near),"real turret upgrade succeeds")
 await key(KEY_R);fx.tutorial_tick(.1)
 check(r.repair_actions>0 and fx.step==7,"actual repair control and upgrade complete lesson")
 # A sold defense cannot strand the combat lesson; recover returns to the real purchase objective.
 r.sell_building(near);fx.recover();fx.tutorial_tick(.1)
 check(fx.step==5,"missing defense safely returns to build lesson")
 check(buy("turret",near),"replacement defense purchased after recovery")
 fx.tutorial_tick(.1)
 check(fx.step==6,"replacement defense restarts upgrade lesson")
 m.upgrade_building(near);m.repair_door();fx.tutorial_tick(.1)
 check(fx.step==7,"repair/upgrade progress can recover")
 practice_tick(20)
 check(fx.step==8 and r.alive and fx.damage_observed and r.shots>0,"weak threat shows real attack and turret fire, then completion")
func run():
 # Fresh process starts opening, not menu; every skip state resolves exactly once.
 for elapsed in [0.0,3.9,4.4,8.5,10.8,14.9]:
  await create(false)
  check(game.mode=="intro" and game.onboarding.phase=="cinematic","fresh launch starts cinematic")
  game.onboarding.elapsed=elapsed
  await key(KEY_SPACE)
  check(game.tutorial_active and game.onboarding.phase=="tutorial" and not game.profile.tutorial_completed,"skip safely routes fresh player to mandatory tutorial")
  check(game.profile.xp==0 and game.profile.rm_cash==0 and game.profile.pending_spins.is_empty(),"opening/skip cannot grant match rewards")
  await dispose()
 await create(true)
 var fx=game.onboarding
 for i in range(60):fx._process(.25)
 check(fx.phase=="title","15 second real intro transitions to title")
 var source=FileAccess.get_file_as_string("res://scripts/onboarding.gd")
 check("Welcome to NightFall Dorm" in source and "Created by Fahim" in source,"exact welcome and creator text present")
 for i in range(16):fx._process(.25)
 check(game.mode=="menu" and fx.phase=="idle" and not fx.active,"complete opening <=19 seconds routes graduated player to menu")
 game.return_menu();check(fx.phase=="idle" and not fx.active,"return to menu never repeats intro")
 game.profile.inventory={"repair":3};game.profile.rm_cash=55;game.profile.xp=700;game.profile.save_profile()
 game.ui.shop.show_shop()
 var cash=game.profile.rm_cash;var stock=int(game.profile.inventory.get("repair",0))
 game.ui.shop.purchase("repair",game.profile.purchase_serial+1)
 game.ui.shop.purchase("repair",game.profile.purchase_serial+1)
 check(game.profile.rm_cash==cash-OnboardingCatalog.PRICES.repair and game.profile.inventory.repair==stock+1,"UI double press with newly rendered token still buys exactly once")
 await create_timer(.5).timeout
 game.ui.shop.update()
 var before_double_cash=game.profile.rm_cash;var before_double_stock=game.profile.inventory.repair
 await mouse_button(game.ui.shop.buttons[0].button,true)
 check(game.profile.rm_cash==before_double_cash and game.profile.inventory.repair==before_double_stock,"Windows double-click second press/release suppressed after 500ms with refreshed button")
 await mouse_button(game.ui.shop.buttons[0].button,false)
 check(game.profile.rm_cash==before_double_cash-OnboardingCatalog.PRICES.repair and game.profile.inventory.repair==before_double_stock+1,"separate real mouse shop click purchases normally")
 var before=game.profile._reward_snapshot()
 check(game.start_tutorial(true),"replay tutorial starts")
 game.onboarding.set_process(false)
 await graduate(true)
 game.onboarding.save_completion()
 var after=game.profile._reward_snapshot()
 check(after==before and game.mode=="menu" and not game.tutorial_active,"replay preserves all real progress, cash, inventory and rewards")
 await dispose()
 # Fresh graduation save failure leaves completion pending, retry is durable.
 await create(false);game.onboarding.skip();game.onboarding.set_process(false)
 check(not game.start_match(),"normal matches blocked until fresh tutorial completed")
 game.onboarding.set_process(false)
 await graduate(false)
 var path=game.profile.path;game.profile.path+="/missing.json"
 game.onboarding.save_completion()
 check(not game.profile.tutorial_completed and game.onboarding.phase=="tutorial" and game.onboarding.step==8,"failed completion save cannot unlock gameplay")
 game.profile.path=path;game.onboarding.save_completion()
 check(game.profile.tutorial_completed and game.mode=="menu" and not game.tutorial_active,"completion retry unlocks menu once durable")
 var reload=PlayerProfile.new(path)
 check(reload.load_profile() and reload.tutorial_completed and reload.xp==0 and reload.rm_cash==0 and reload.inventory.is_empty(),"fresh tutorial completes without campaign rewards")
 await dispose()
 # A closed application restarts an unfinished practice; no campaign state was touched.
 await create(false);game.profile.save_profile();var interrupted_path=game.profile.path
 game.onboarding.skip();game.onboarding.set_process(false)
 game.model.move_player(Vector2.RIGHT,.25);game.model.move_player(Vector2.RIGHT,.1);game.onboarding.tutorial_tick(.1)
 check(game.onboarding.step==1,"unfinished tutorial reached real movement objective")
 await dispose()
 OS.set_environment("NIGHTFALL_PROFILE_PATH",interrupted_path)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.set_process(false);game.onboarding.set_process(false);game.onboarding.skip()
 check(game.tutorial_active and game.onboarding.step==0 and not game.profile.tutorial_completed and game.profile.xp==0,"mid-tutorial relaunch safely restarts mandatory practice")
 game.onboarding.set_process(false)
 # Deliberately fill every practice pad incorrectly; recovery frees an actual purchase pad.
 var m=game.model;m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 var r=m.player();r.gold=100000;r.electricity=100000
 for tile in range(r.tile_count()):check(r.build("turret",tile),"prepare occupied practice grid")
 game.onboarding.step=4;game.onboarding.recover()
 check(r.buildings.size()==r.tile_count()-1 and not r.buildings.has(game.selected_tile),"recovery frees a real practice pad")
 check(buy("generator",game.selected_tile),"freed pad supports actual missing Dynamo purchase")
 check(game.profile.inventory.is_empty() and game.profile.rm_cash==0,"recovery sales/resources remain practice-only")
 await dispose()
 var d=DirAccess.open("user://")
 if d:
  for file in d.get_files():
   if file.begins_with(prefix.trim_prefix("user://")):DirAccess.remove_absolute("user://"+file)
 print("ONBOARDING_FLOW_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
