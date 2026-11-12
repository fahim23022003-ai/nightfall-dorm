extends SceneTree
# Paired prepared production fixtures, actual Godot rendering. No natural-play claim.
var game
var checks=0
var failures=0
var phase="before"
var output="res://docs/evidence/visual-overhaul/"
var recording
var perf=[]
var perf_seconds=2.5
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("VISUAL REVIEW: "+label)
func capture(name):
 game.queue_redraw()
 if is_instance_valid(game.ui.horror_layer):game.ui.horror_layer.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output+phase+"/"+name+".png"))==OK,"capture "+name)
 print("VISUAL_CAPTURE ",phase,"/",name)
func advance(seconds):
 var start=Time.get_ticks_usec();var previous=start
 while Time.get_ticks_usec()-start<seconds*1000000:
  await process_frame
  var now=Time.get_ticks_usec();var delta=(now-previous)/1000000.0;previous=now
  game.presentation.update(delta,game.model);game.horror.update(delta,game.model)
  if game.audio_system.has_method("set_tension"):game.audio_system.set_tension(game.presentation.identity.tension,game.presentation.identity.intensity)
  game.audio_system.update_state(delta,game.model,game.mode)
  if game.mode=="match" and not game.tutorial_active:game.audio_system.update_environment(game.presentation.environment)
  if game.ui.current_screen=="shop":game.ui.shop.update()
  game.ui.items_ui.update(delta)
  if game.mode=="match":game.ui.update_match()
  game.queue_redraw()
func record():return {"clears":1,"best_time":180.0,"best_damage":2000.0,"best_xp":200,"difficulty":"hell","first_match_id":1}
func fixture(stage="stage_1"):
 game.tutorial_active=false;game.profile.pending_spins=[];game.profile.pending_stage_bonus={};game.profile.stage_bonus_queue=[]
 check(game.start_stage(stage,"hell"),"real stage "+stage)
 game.set_process(false);game.tutorial_enabled=false
 var m=game.model;m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();m.bot_claimed=5
 m.time=m.preparation+90;m.hunter.boss_policy.enabled=false
 for i in range(1,m.rooms.size()):
  var r=m.rooms[i];r.owner=i;r.sleeping=true;r.closed=true;r.resident_position=r.bed_position()
 m.hunter.target=0;m.hunter.position=m.map_data.spawn;m.hunter.state=HunterState.State.MOVE;m.hunter.cooldown=100
 game.presentation.reset();game.horror.reset();game.audio_system.reset_match(m)
 game.full_map=false;game.focus_camera(true)
 game.presentation.update(.1,m);game.horror.update(.1,m);game.ui.update_match()
 return m
func find_button(text,node=null):
 if node==null:node=game.ui.panel
 for child in node.get_children():
  if child is Button and child.text==text and not child.is_queued_for_deletion():return child
  var found=find_button(text,child)
  if found!=null:return found
 return null
func click(button,double_click=false):
 check(button!=null,"actual button exists")
 if button==null:return
 var point=root.get_final_transform()*button.get_global_rect().get_center()
 var motion=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;Input.parse_input_event(motion);await process_frame
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.position=point;event.global_position=point;event.pressed=pressed;event.button_index=MOUSE_BUTTON_LEFT;event.double_click=double_click if pressed else false
  Input.parse_input_event(event);await process_frame
func update_model(delta):
 game.model.tick(delta)
 game.presentation.update(delta,game.model);game.horror.update(delta,game.model)
 if game.audio_system.has_method("set_tension"):game.audio_system.set_tension(game.presentation.identity.tension,game.presentation.identity.intensity)
 game.audio_system.update_state(delta,game.model,game.mode)
 game.audio_system.update_environment(game.presentation.environment)
 game.ui.items_ui.update(delta);game.ui.update_match();game.queue_redraw()
func advance_model(seconds):
 var start=Time.get_ticks_usec();var previous=start
 while Time.get_ticks_usec()-start<seconds*1000000:
  await process_frame
  var now=Time.get_ticks_usec();var delta=(now-previous)/1000000.0;previous=now
  update_model(delta)
func material_cache_size():
 if FileAccess.file_exists("res://scripts/gothic_theme.gd"):
  return load("res://scripts/gothic_theme.gd").materials.size()
 return -1 # Baseline uses flat StyleBoxFlat surfaces; no material texture cache.
func benchmark(label,resolution,reduced):
 root.size=resolution
 var m=fixture("stage_1");m.time=0;m.hunter.state=HunterState.State.DORMANT
 game.profile.settings.reduced_effects=reduced
 await advance_model(.35)
 var cache_before=material_cache_size();var nodes_before=root.get_child_count()
 var samples=[];var start=Time.get_ticks_usec();var previous=start
 while Time.get_ticks_usec()-start<perf_seconds*1000000:
  await process_frame
  var now=Time.get_ticks_usec();var elapsed=(now-previous)/1000.0;previous=now;samples.append(elapsed)
  update_model(elapsed/1000.0)
 samples.sort()
 var mean=0.0
 for sample in samples:mean+=sample
 mean/=maxi(1,samples.size())
 var row={"label":label,"sample_window_seconds":perf_seconds,"resolution":str(resolution),"reduced":reduced,"frames":samples.size(),"mean_frame_ms":mean,"p95_frame_ms":samples[int((samples.size()-1)*.95)],"approx_process_fps":1000.0/mean,"material_cache_before":cache_before,"material_cache_after":material_cache_size(),"root_children_before":nodes_before,"root_children_after":root.get_child_count(),"renderer":"Godot4.6.3 OpenGL/Mesa software display; controlled preparation fixture","source_phase":phase}
 check(cache_before==material_cache_size(),"cached materials stable during warm repeated redraws "+label)
 perf.append(row);print("VISUAL_PERF ",JSON.stringify(row))
func extra_review():
 root.size=Vector2i(1280,720)
 game.return_menu();game.ui.shop.show_shop()
 var cash=game.profile.rm_cash;var stock=game.profile.inventory.get("repair",0)
 await click(find_button("Buy · 18 RM Cash"));await advance(.15)
 check(game.profile.rm_cash==cash-18 and game.profile.inventory.repair==stock+1,"actual redesigned shop purchase")
 await capture("extra-shop-success")
 var deadline=Time.get_ticks_msec()+550
 while Time.get_ticks_msec()<deadline:await process_frame
 game.ui.shop.update()
 await click(find_button("Buy · 18 RM Cash"),true)
 check(game.profile.rm_cash==cash-18 and game.profile.inventory.repair==stock+1,"late OS double click spends nothing")
 await click(find_button("Buy · 18 RM Cash"));await advance(.15)
 check(game.profile.rm_cash==cash-36 and game.profile.inventory.repair==stock+2,"ordinary purchase remains usable")
 var m=fixture("stage_4");m.hunter.target=1;m.hunter.position=m.rooms[0].door_approach();m.hunter.state=HunterState.State.MOVE
 game.full_map=true;game.focus_camera(true)
 await advance_model(.45);await capture("extra-hunter-direction-right")
 check(game.presentation.identity.heading.is_finite() and game.presentation.identity.heading.x>0,"actual rightward movement facing")
 print("VISUAL_DIRECTION right ",game.presentation.identity.heading)
 m.hunter.target=0;m.hunter.state=HunterState.State.MOVE
 await advance_model(.45);await capture("extra-hunter-direction-left")
 check(game.presentation.identity.heading.x<0,"actual leftward motion / door facing")
 print("VISUAL_DIRECTION left ",game.presentation.identity.heading)
 var position=m.hunter.position;var hunter_clock=game.presentation.hunter_clock
 m.running=false
 var direction=game.presentation.identity.heading
 await advance(.3)
 check(m.hunter.position==position and game.presentation.hunter_clock==hunter_clock and game.presentation.identity.heading==direction,"pause holds actual and visual Hunter")
 m.running=true
 check(game.profile.activate_item(1,m,game.match_id),"actual equipped Time Freeze")
 direction=game.presentation.identity.heading;position=m.hunter.position;hunter_clock=game.presentation.hunter_clock
 await advance_model(.35)
 check(m.hunter.position==position and game.presentation.identity.heading==direction and is_equal_approx(game.presentation.hunter_clock,hunter_clock),"freeze holds movement/facing/animation")
 await capture("extra-frozen-hunter")
 await advance_model(3.0)
 check(not m.items.timers.has("time_freeze") and game.presentation.hunter_clock>hunter_clock,"freeze expires and Hunter animation resumes")
 m.hunter.target=1;m.hunter.state=HunterState.State.MOVE
 await advance_model(.4)
 check(m.hunter.position!=position,"actual navigation resumes after freeze")
 for stage in StageCatalog.STAGES:
  m=fixture(stage.id);m.hunter.position=m.player().door_approach();m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.cooldown=1;m.player().door_hp=m.player().max_hp()*.4
  await advance(.2);await capture("extra-siege-focus-"+m.map_id)
 game.profile.inventory.barricade=9999;game.profile.inventory.time_freeze=9999;m=fixture()
 m.player().gold=123456;m.player().electricity=123456;game.ui.update_match()
 game.profile.activate_item(0,m,game.match_id);await advance(.2)
 await capture("extra-large-counts-and-active-slot")
 game.profile.inventory.barricade=20;game.profile.inventory.time_freeze=20
 game.start_tutorial(true);m=game.model;m.claim_room(0);m.player_position=m.player().bed_position()+Vector2(35,0);game.onboarding.step=2;game.onboarding.refresh_objective();game.ui.update_match();game.focus_camera(true)
 await capture("extra-genuine-room-tutorial-panel");game.onboarding.finish_replay()
 m=fixture("stage_1");m.time=m.preparation+200;m.hunter.position=m.player().door_approach();m.hunter.target=0;m.hunter.state=HunterState.State.ATTACK;m.hunter.cooldown=0
 m.hunter.encounter_attacks=int(RankCatalog.pressure(m.hunter.difficulty).charged_every)-1
 update_model(.01);await advance(.15)
 check(m.hunter.charged_ready,"real charged attack enters windup")
 await capture("extra-charged-windup")
 m=fixture("stage_5");m.hunter.boss_policy.enabled=true;m.time=m.preparation+float(m.hunter.boss_policy.deadline)+1;m.hunter.hp=m.hunter.max_hp*.5
 m.hunter.position=m.player().door_approach();m.hunter.target=0
 update_model(.01);await advance(.15)
 check(m.hunter.transformed and m.hunter.state==HunterState.State.TRANSFORM,"actual Reaper policy transformation")
 await capture("extra-reaper-transform")
 await advance_model(BossCatalog.TRANSFORM_SECONDS+.15)
 m.hunter.position=m.player().door_approach();m.hunter.target=0;m.hunter.state=HunterState.State.ATTACK;m.hunter.cooldown=0
 update_model(.01);await advance(.15)
 check(m.hunter.boss_attack!="","real Reaper telegraph selected")
 await capture("extra-reaper-windup")
 await advance_model(2.0)
 check(m.hunter.last_boss_attack!="","real Reaper impact resolves")
 await capture("extra-reaper-impact")
 await benchmark("720-normal",Vector2i(1280,720),false)
 await benchmark("1080-normal",Vector2i(1920,1080),false)
 await benchmark("720-reduced",Vector2i(1280,720),true)
 var file=FileAccess.open(output+"render-performance.json",FileAccess.WRITE)
 if file:file.store_string(JSON.stringify({"before_quantitative_baseline":false,"conditions":"Controlled Linux software-rendered observation only; no native Windows or hardware comparison","observations":perf}," "))
func detail_review():
 phase="after"
 var m=fixture("stage_5");m.hunter.boss_policy.enabled=true;m.time=m.preparation+float(m.hunter.boss_policy.deadline)+1;m.hunter.hp=m.hunter.max_hp*.5
 m.hunter.position=m.player().door_approach();m.hunter.target=0
 update_model(.01);await advance_model(.7)
 check(m.hunter.state==HunterState.State.TRANSFORM and m.hunter.transform_remaining<BossCatalog.TRANSFORM_SECONDS-.5,"real mid-transformation model progress")
 await capture("extra-reaper-transform")
 game.profile.item_loadout=["guardian_heart","cursed_fortune"];game.profile.inventory.guardian_heart=9999;game.profile.inventory.cursed_fortune=9999
 m=fixture("stage_5");m.player().gold=123456789;m.player().electricity=123456789
 m.hunter.target=0;m.hunter.position=m.player().door_approach();m.hunter.state=HunterState.State.ATTACK
 m.hunter._damage_door(m.player(),m,200)
 await advance(.15)
 check(game.profile.inventory.guardian_heart==9998 and m.items.guardian_shield_hp>0,"actual automatic Guardian consumption and shield")
 check(game.ui.items_ui.hotbar[1].disabled and game.ui.items_ui.hotbar[1].text.contains("USED") and not game.ui.items_ui.hotbar[1].text.contains("READY"),"spent Legendary allowance never advertised ready")
 check(game.ui.gold_label.tooltip_text.contains("123456789") and game.ui.power_label.tooltip_text.contains("123456789"),"compact resource fields preserve exact tooltips")
 await capture("extra-guardian-max-stock-resource")
 game.profile.inventory.guardian_heart=9999
 m=fixture("stage_4");m.hunter.position=m.player().door_approach();m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.cooldown=1;m.player().door_hp=m.player().max_hp()*.4
 await advance(.15);await capture("extra-siege-focus-underground_lab")
 var automatic=game.ui.items_ui.hotbar[0]
 var text_width=automatic.get_theme_font("font").get_multiline_string_size(automatic.text,HORIZONTAL_ALIGNMENT_LEFT,-1,automatic.get_theme_font_size("font_size")).x
 check(automatic.size.x<=334.1 and text_width<=274,"automatic max-stock text preserves icon space and slot bounds")
 game.profile.item_loadout=["barricade","time_freeze"]
 m=fixture("stage_5");m.hunter.target=0;m.hunter.position=m.player().door_approach();m.hunter.state=HunterState.State.ATTACK;m.record_event("approach",0)
 check(game.profile.activate_item(1,m,game.match_id),"actual Legendary activation beside genuine notice")
 await advance(.3)
 var flourish=game.ui.items_ui.legendary_banner.get_global_rect()
 check(not flourish.intersects(Rect2(20,218,420,180)) and flourish.end.x<=1280 and flourish.end.y<=720,"Legendary flourish avoids notice area and remains onscreen")
 await capture("extra-frozen-hunter")
 root.size=Vector2i(1920,1080);await capture("extra-frozen-hunter-1080");root.size=Vector2i(1280,720)
 game.profile.inventory.time_freeze=20;game.profile.inventory.barricade=20 # Reset paired prepared stock before overview comparisons.
 for stage in StageCatalog.STAGES:
  m=fixture(stage.id);game.full_map=true;game.focus_camera(true);game.presentation.environment.update(8,m,false);await advance(.1);await capture("15-world-"+m.map_id)
 print("VISUAL_DETAIL_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.5).timeout;quit(0 if failures==0 else 1)
func run():
 if not OS.get_cmdline_user_args().is_empty():phase=OS.get_cmdline_user_args()[0]
 if OS.get_cmdline_user_args().size()>1:perf_seconds=clampf(float(OS.get_cmdline_user_args()[1]),2.5,30.0)
 if phase=="before" and FileAccess.file_exists(output+"before/01-main-menu-720.png"):
  push_error("Preserved baseline already exists; refusing to overwrite original before evidence.");quit(1);return
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://visual-overhaul-"+phase+"-"+str(Time.get_ticks_usec())+".json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 preload("res://tests/onboarding_test_support.gd").skip(game);game.set_process(false);game.onboarding.set_process(false)
 root.size=Vector2i(1280,720)
 game.profile.next_match_id=2;game.profile.xp=3800;game.profile.rm_cash=200
 for stage in StageCatalog.STAGES:game.profile.campaign_records[stage.id]=record()
 for id in ItemCatalog.IDS:game.profile.inventory[id]=20
 game.profile.item_loadout=["barricade","time_freeze"];game.profile.equipped=["dreamer","first_aid"];game.profile.save_profile()
 if phase=="detail-review":
  await detail_review();return
 if phase=="after":
  recording=AudioEffectRecord.new();AudioServer.add_bus_effect(0,recording);recording.set_recording_active(true)
 if phase.begins_with("perf"):
  await benchmark("720-normal",Vector2i(1280,720),false)
  await benchmark("1080-normal",Vector2i(1920,1080),false)
  await benchmark("720-reduced",Vector2i(1280,720),true)
  var file=FileAccess.open(output+phase+".json",FileAccess.WRITE)
  if file:file.store_string(JSON.stringify({"phase":phase,"conditions":"Matched prepared fixture, Linux software display only; shared-host timing, no Windows/hardware FPS claim","observations":perf}," "))
  print("VISUAL_PERF_ONLY_CHECKS=",checks," FAILURES=",failures)
  game.audio_system.shutdown();await create_timer(.5).timeout;quit(0 if failures==0 else 1);return
 game.return_menu();await advance(.15);await capture("01-main-menu-720")
 game.ui.campaign.show_stages();await capture("02-stage-selection")
 game.ui.campaign.prepare("stage_2");await capture("03-perk-difficulty-loadout")
 game.ui.shop.show_shop();await capture("04-common-shop")
 for page in range(3):game.ui.items_ui.inventory_page=page;game.ui.items_ui.inventory();await capture("05-inventory-page-"+str(page+1))
 game.ui.progression.show_ranks();await capture("06-ranks")
 for page in range(2):game.ui.progression.achievement_page=page;game.ui.progression.show_achievements();await capture("07-achievements-page-"+str(page+1))
 game.ui.show_settings();await capture("08-settings")
 var m=fixture()
 m.time=5;m.hunter.state=HunterState.State.DORMANT
 await advance(.1);await capture("09-quiet-preparation")
 m.time=m.preparation+90;m.hunter.state=HunterState.State.MOVE;m.hunter.target=0;m.hunter.position=m.player().door_approach()+Vector2(0,70)
 m.record_event("approach",0);await advance(.25);await capture("10-hunter-approaching")
 m.hunter.position=m.player().door_approach();m.hunter.state=HunterState.State.ATTACK;m.hunter.cooldown=0
 m.hunter.tick(.01,m);await advance(.25);await capture("11-door-siege")
 m.player().door_hp=m.player().max_hp()*.2;await advance(.15);await capture("12-player-danger")
 game.toggle_pause();await capture("13-pause");game.toggle_pause()
 var r=m.rooms[1];m.hunter.target=1;m.hunter.state=HunterState.State.ATTACK;m.hunter.position=r.door_approach();m.hunter.cooldown=0;r.door_hp=1
 m.hunter.tick(.01,m)
 for i in range(200):
  if not r.alive:break
  m.hunter.tick(.1,m)
 await advance(.8);game.full_map=true;game.focus_camera(true);await capture("14-survivor-eliminated")
 for stage in StageCatalog.STAGES:
  m=fixture(stage.id);game.full_map=true;game.focus_camera(true);game.presentation.environment.update(8,m,false);await advance(.1);await capture("15-world-"+m.map_id)
 m=fixture("stage_3");r=m.player();r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp();r.gold=30000;r.electricity=5000
 var tile=0;var best=1e20
 for i in range(r.tile_count()):
  var distance=r.tile_position(i).distance_to(r.door_approach())
  if distance<best:best=distance;tile=i
 check(r.build("heavy",tile),"actual Arc purchase")
 for i in range(9):check(r.upgrade_building(tile),"actual paid prestige upgrade")
 m.hunter.position=r.door_approach();m.hunter.target=0;m.hunter.state=HunterState.State.ATTACK;m.hunter.transformed=true
 m._turrets(.01);game.selected_tile=tile;game.ui.open_context();await advance(.15);await capture("16-level-ten-firing")
 game.ui.close_context();m.hunter.transformed=false;m.hunter.hp=0;m.player().occupied_seconds=100;m.player().damage_dealt=2000;m.result="victory";game._process(.01)
 await advance(1.6);await capture("17-match-results")
 game.ui.items_ui.spin();await capture("18-lucky-spin")
 game.profile.claim_spin(game.match_id);game.return_menu()
 game.start_tutorial(true);game.onboarding.step=2;game.onboarding.refresh_objective();await capture("19-tutorial-panel");game.onboarding.finish_replay()
 game.onboarding.show_opening();game.onboarding.elapsed=6;game.onboarding.queue_redraw();await capture("20-opening-hunter")
 game.onboarding.show_title();game.onboarding.elapsed=2;game.onboarding.queue_redraw();await capture("21-title-story");game.onboarding.skip()
 root.size=Vector2i(1920,1080);game.return_menu();await capture("22-main-menu-1080")
 game.ui.shop.show_shop();await capture("23-shop-1080")
 game.ui.campaign.prepare("stage_2");await capture("24-loadout-1080")
 m=fixture("stage_5");await advance(.15);await capture("25-gameplay-1080")
 root.size=Vector2i(1280,720);game.profile.settings.reduced_effects=true;await capture("26-reduced-gameplay")
 if phase=="after":
  await extra_review()
  recording.set_recording_active(false);var recorded=recording.get_recording()
  check(recorded!=null and recorded.data.size()>1000,"actual engine master recording")
  if recorded!=null:check(recorded.save_to_wav(ProjectSettings.globalize_path(output+"render-visual-mix.wav"))==OK,"save actual engine mixer")
  print("VISUAL_AUDIO ",JSON.stringify(game.audio_system.get_diagnostics()))
 print("VISUAL_REVIEW_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.5).timeout;game.queue_free();await process_frame;quit(0 if failures==0 else 1)
