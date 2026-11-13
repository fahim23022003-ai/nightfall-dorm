extends "res://tests/phase5d4_qa_ui.gd"
# Independent actual-input/tween QA. Simulation is frozen except explicit attack.
var measurements=[]
func wallet():
 var r=game.model.player()
 return [r.gold,r.electricity,r.buildings.duplicate(true)]
func await_drawer(expanded):
 var started=Time.get_ticks_msec()
 while is_instance_valid(game.ui.context_box) and game.ui.bottom_context.is_transitioning() and Time.get_ticks_msec()-started<1500:
  await process_frame
  game.ui.update_match()
 check(not game.ui.bottom_context.is_transitioning() and game.ui.context_open==expanded,"drawer reaches requested state without softlock")
 await settle()
func timed_transition(expanded,label):
 var ui=game.ui;var bottom=ui.bottom_context;var id=ui.context_box.get_instance_id();var prior=state();var cam=camera();var start=Time.get_ticks_usec()
 if expanded:ui.open_context()
 else:ui.close_context()
 check(bottom.is_transitioning() and ui.context_box.visible,"actual drawer starts visible tween "+label)
 var previous=ui.context_box.position.y;var samples=[]
 while bottom.is_transitioning() and Time.get_ticks_usec()-start<1200000:
  await process_frame;ui.update_match();var current=ui.context_box.position.y
  check(current<=previous+.05 if expanded else current>=previous-.05,"drawer follows correct monotonic vertical direction "+label)
  check(current>=437.9 and current<=724.1,"drawer remains within finite designed endpoints "+label)
  samples.append(current);previous=current
 var elapsed=(Time.get_ticks_usec()-start)/1000000.0
 check(elapsed>=.20 and elapsed<=.35,"actual frame tween duration is0.20–0.35seconds "+label+str(elapsed))
 check(ui.context_box.position.is_equal_approx(Vector2(20,438) if expanded else Vector2(20,724)) and ui.context_box.visible==expanded,"drawer reaches exact visible/hidden endpoint "+label)
 check(ui.context_box.get_instance_id()==id and state()==prior and camera()==cam,"animation reuses one panel and changes no model/RNG/camera/player "+label)
 measurements.append({"label":label,"seconds":elapsed,"samples":samples,"physical_size":[root.size.x,root.size.y],"logical_size":[root.get_visible_rect().size.x,root.get_visible_rect().size.y]})
func moving_click(expanded):
 var ui=game.ui;var bottom=ui.bottom_context
 if expanded:ui.open_context()
 else:ui.close_context()
 await create_timer(.09).timeout
 check(bottom.is_transitioning(),"actual tween is moving before input guard probe")
 # Pause only to keep a moving hit target under the pointer while injecting
 # real mouse events; a separate unpaused test measures actual duration.
 bottom.tween.pause()
 var card=ui.actions["build:"+Catalog.BUILDINGS.keys()[4]];var pressed=[0]
 card.pressed.connect(func():pressed[0]+=1)
 var prior=wallet();var before=state();var cam=camera();await point_click(card.get_global_rect().get_center())
 check(pressed[0]>0,"moving-drawer guard probe reaches actual BaseButton pressed signal")
 check(wallet()==prior and state()==before and camera()==cam,"moving/opening/closing economic control cannot spend or move player")
 bottom.tween.play();await await_drawer(expanded)
func stable_geometry(label):
 var ui=game.ui;var body=ui.context_box.get_global_rect();var header=ui.room_dock.get_global_rect()
 check(header.position.y>=645 and header.end.y<=720 and header.size.y<=60,"closed primary toolbar stays compact at bottom "+label)
 for b in [ui.room_selected_summary,ui.room_bed_summary,ui.room_door_summary,ui.quick_repair,ui.bottom_context.upgrade_shortcut]:
  check(inside(b.get_global_rect(),header),"real primary mouse control fits compact toolbar "+label)
 check(body==Rect2(20,438,1240,204),"intentional open drawer fits lower middle without oversized panel "+label)
 for kind in Catalog.BUILDINGS:
  var card=ui.actions["build:"+kind]
  check(card.is_visible_in_tree() and inside(card.get_global_rect(),body),"every actually registered building card is accessible inside drawer "+kind)
 # Prove reserved fourth/fifth columns and all15 future slots fit the defined
 # layout mathematically. Future actual cards will be checked by the loop above.
 for i in range(15):
  var slot=Rect2(body.position+Vector2(10+(i%5)*244,32+int(i/5)*55),Vector2(238,52))
  check(inside(slot,body),"fifteen-card target geometry fits without fourth-row overflow")
func economic_flow():
 var ui=game.ui;var r=game.model.player();var kind=Catalog.BUILDINGS.keys()[4];var tile=game.selected_tile;var card=ui.actions["build:"+kind]
 var at=card.get_global_rect().get_center();var before=wallet();await point_click(at);await point_click(at,true)
 check(r.buildings.has(tile) and r.buildings[tile].kind==kind and r.buildings[tile].level==1,"real rapid BUILD buys one L1 despite inspector control replacing same position")
 check(is_equal_approx(before[0]-r.gold,Catalog.BUILDINGS[kind].gold) and is_equal_approx(before[1]-r.electricity,Catalog.BUILDINGS[kind].power),"rapid BUILD charges exactly one separate Gold/Electricity price")
 check(game.pending_build=="" and not game.placement_on_tile and ui.context_mode=="upgrade","new drawer leaves no stuck mouse-follow placement")
 before=wallet();var cost=Catalog.upgrade_cost(kind,1);at=ui.actions.upgrade.get_global_rect().get_center();await point_click(at);await point_click(at,true)
 check(r.buildings[tile].level==2 and is_equal_approx(before[0]-r.gold,cost.x) and is_equal_approx(before[1]-r.electricity,cost.y),"actual rapid upgrade charges exactly one L1→2")
 var refund=r.building_refund(tile);before=wallet();at=ui.actions.sell.get_global_rect().get_center();await point_click(at);await point_click(at,true)
 check(not r.buildings.has(tile) and is_equal_approx(r.gold-before[0],refund.x) and is_equal_approx(r.electricity-before[1],refund.y),"actual rapid sale refunds once and releases occupied pad")
 ui.close_context();await await_drawer(false)
 await click(ui.room_selected_summary);await await_drawer(true)
 var original=state();at=ui.actions["build:"+kind].get_global_rect().get_center();await pointer(at,true);await key(KEY_ESCAPE);await pointer(at,false);await await_drawer(false)
 check(state()==original and not ui.context_open and game.pending_build=="","held BUILD then Escape cancels before release without spending")
 await click(ui.room_selected_summary);await await_drawer(true)
 check(ui.context_mode=="build" and not ui.actions["build:"+kind].disabled,"same pad and menu reopen without stuck cancellation flag")
 before=wallet();await click(ui.actions["build:"+kind]);check(r.buildings.has(game.selected_tile) and r.gold<before[0],"next legitimate purchase succeeds after cancellation")
func attacks_and_keys():
 var ui=game.ui;var m=game.model;var r=m.player();ui.close_context();await await_drawer(false)
 await click(ui.room_door_summary);await await_drawer(true)
 var cam=camera();var h=m.hunter;h.state=HunterState.State.ATTACK;h.target=r.index;h.position=r.door_approach();h.cooldown=100;h.boss_policy.enabled=false;h.tick(0,m)
 var hp=r.door_hp;var damage=m.apply_room_damage(r.index,20,"HUD actual contact",1)
 ui.update_match();await settle()
 check(damage>0 and r.door_hp<hp and ui.context_open and ui.context_mode=="door" and not ui.bottom_context.is_transitioning(),"genuine attack updates danger without auto-closing intentionally open drawer")
 check(camera()==cam,"attack and panel state do not change camera/player")
 var gold=r.gold;var quote=r.manual_repair_cost();await key(KEY_R)
 check(r.door_hp>hp-damage and is_equal_approx(gold-r.gold,quote) and ui.context_open,"Windows R repair remains real, paid and usable with drawer open")
 await key(KEY_ESCAPE);await await_drawer(false)
 check(not ui.context_open and m.running,"first Escape restores compact toolbar without pausing match")
 # Switching relevant toolbar modes midway through one real tween keeps a
 # single panel and must not charge until an actual upgrade is requested.
 var before=wallet();var id=ui.context_box.get_instance_id();await click(ui.room_bed_summary);await click(ui.room_door_summary);await await_drawer(true)
 check(ui.context_mode=="door" and ui.context_box.get_instance_id()==id and wallet()==before,"rapid bed→door switch selects relevant panel without duplicates or economic action")
func toolbar_during_slide():
 var ui=game.ui;ui.close_context();await await_drawer(false);ui.open_context();await create_timer(.06).timeout
 ui.bottom_context.tween.pause()
 check(ui.context_box.get_global_rect().intersects(ui.room_door_summary.get_global_rect()),"actual travelling drawer overlaps toolbar in affected geometry")
 var before=wallet();var cam=camera();var pressed=[0];ui.room_door_summary.pressed.connect(func():pressed[0]+=1)
 await click(ui.room_door_summary)
 check(pressed[0]>0 and ui.context_mode=="door","toolbar remains actual mouse target above moving drawer")
 check(wallet()==before and camera()==cam,"toolbar mode selection during overlap cannot charge or move camera")
 if ui.bottom_context.tween.is_valid():ui.bottom_context.tween.play()
 await await_drawer(true);ui.close_context();await await_drawer(false)
func reset_mid_tween(map):
 var ui=game.ui;ui.close_context();await await_drawer(false);ui.open_context();await create_timer(.07).timeout
 var old=weakref(ui.context_box);check(ui.bottom_context.is_transitioning(),"reset probe starts during actual active drawer tween")
 game.reset_practice();await settle();await create_timer(.34).timeout;game.ui.update_match()
 check(old.get_ref()==null and not game.ui.context_open and not game.ui.context_box.visible and not game.ui.bottom_context.is_transitioning(),"reset frees old animated panel and restores safe compact HUD")
 check(game.model.map_id==map and game.model.run_kind=="practice" and game.model.player()!=null,"reset preserves selected actual practice map and valid player")
func run():
 profile_path="user://overhaul-qa-hud-"+str(Time.get_ticks_usec())+".json";var p=PlayerProfile.new(profile_path);p.tutorial_completed=true;p.save_profile();OS.set_environment("NIGHTFALL_PROFILE_PATH",profile_path)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.onboarding.set_process(false);preload("res://tests/onboarding_test_support.gd").skip(game);await settle()
 var disk=FileAccess.get_file_as_bytes(profile_path);var sig=Support.profile_signature(game.profile);var scenarios=0
 for physical in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=physical;await settle()
  for map in MapCatalog.IDS:
   game.ui.replay_ui.practice_map=map
   game.start_practice("crusher",false,["repair","shield"],map);await settle();game.focus_camera(true);var ui=game.ui;var r=game.model.player();game.selected_tile=next_pad();ui.update_match();var cam=camera()
   check(not ui.context_open and not ui.context_box.visible and ui.room_dock.visible,"fresh actual gameplay defaults to compact HUD "+map)
   if "--toolbar-only" in OS.get_cmdline_user_args():
    await toolbar_during_slide()
    check(FileAccess.get_file_as_bytes(profile_path)==disk and Support.profile_signature(game.profile)==sig,"toolbar probe preserves permanent profile")
    game.return_menu();await settle();scenarios+=1;continue
   if "--reset-only" in OS.get_cmdline_user_args():
    await reset_mid_tween(map)
    check(FileAccess.get_file_as_bytes(profile_path)==disk and Support.profile_signature(game.profile)==sig,"reset-only test preserves permanent profile")
    game.return_menu();await settle();scenarios+=1;continue
   await timed_transition(true,map+" open");stable_geometry(map);await timed_transition(false,map+" close")
   await moving_click(true);await moving_click(false)
   var original=state();var node=ui.context_box.get_instance_id();var tween_count=get_processed_tweens().size()
   for i in range(20):ui.open_context();ui.close_context()
   await await_drawer(false);check(state()==original and camera()==cam and ui.context_box.get_instance_id()==node,"twenty rapid open/close cycles never mutate model or duplicate panel")
   check(get_processed_tweens().size()<=tween_count+4,"cancelled drawer tweens do not accumulate")
   await click(ui.room_selected_summary);await await_drawer(true);await economic_flow();await attacks_and_keys();await toolbar_during_slide();await reset_mid_tween(map)
   check(FileAccess.get_file_as_bytes(profile_path)==disk and Support.profile_signature(game.profile)==sig,"HUD inputs and temporary practice transactions preserve permanent save byte-for-byte")
   game.return_menu();await settle();scenarios+=1
 var f=FileAccess.open("res://docs/evidence/gameplay-overhaul/qa-hud-toolbar-timing.json" if "--toolbar-only" in OS.get_cmdline_user_args() else "res://docs/evidence/gameplay-overhaul/qa-hud-reset-timing.json" if "--reset-only" in OS.get_cmdline_user_args() else "res://docs/evidence/gameplay-overhaul/qa-hud-timing.json",FileAccess.WRITE);f.store_string(JSON.stringify(measurements," "));f.close()
 print("OVERHAUL_QA_HUD_CHECKS=",checks," SCENARIOS=",scenarios," REGISTERED_BUILDINGS=",Catalog.BUILDINGS.size()," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;Support.cleanup(profile_path);quit(1 if failures else 0)
