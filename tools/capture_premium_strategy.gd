extends "res://tools/capture_visual_overhaul.gd"
# New-phase capture only. Existing evidence/helpers remain unchanged.
const BASELINE_SOURCE="496b9b9df9efbe95f99f2efc0e7a5de3c6597815"
func capture(name):
 # Prepared model edits bypass normal _process; render the current live HUD values.
 if game.mode=="match":
  game.ui.items_ui.update(0.0);game.ui.update_match()
 await super.capture(name)
func pointer(point):
 var event=InputEventMouseMotion.new();event.position=point;event.global_position=point
 Input.parse_input_event(event);await process_frame
func button_pose(label,pose,name):
 var b=named_button(label.trim_prefix("@")) if label.begins_with("@") else find_button(label)
 check(b!=null,"real control "+label)
 if b==null:return
 var at=root.get_final_transform()*b.get_global_rect().get_center()
 await pointer(at if pose!="focus" else root.get_final_transform()*Vector2(1260,700))
 if pose=="focus":b.grab_focus()
 if pose=="pressed":
  var event=InputEventMouseButton.new();event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;Input.parse_input_event(event)
 await advance(.18);await capture(name)
 if pose=="hover":check(b.is_hovered(),"actual engine hover state")
 if pose=="pressed":check(b.get_draw_mode() in [BaseButton.DRAW_PRESSED,BaseButton.DRAW_HOVER_PRESSED],"actual engine held-press state")
 if pose=="focus":check(b.has_focus(),"actual engine keyboard-focus state")
 print("PREMIUM_STATE ",label," ",pose," draw=",b.get_draw_mode()," focus=",b.has_focus())
 if pose=="pressed":
  var away=root.get_final_transform()*Vector2(1260,700);await pointer(away)
  var event=InputEventMouseButton.new();event.position=away;event.global_position=away;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=false;Input.parse_input_event(event);await process_frame
 await pointer(root.get_final_transform()*Vector2(1260,700))
func named_button(name,node=null):
 if node==null:node=game.ui.panel
 for child in node.get_children():
  if child is Button and str(child.name)==name and not child.is_queued_for_deletion():return child
  var found=named_button(name,child)
  if found!=null:return found
 return null
func key_action(code):
 for pressed in [true,false]:
  var event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed;Input.parse_input_event(event);await process_frame
func finish_capture():
 print("PREMIUM_RENDER_CHECKS=",checks," FAILURES=",failures," BASELINE_SOURCE=",BASELINE_SOURCE)
 game.audio_system.shutdown();await create_timer(.5).timeout;game.queue_free();await process_frame;quit(0 if failures==0 else 1)
func terminal_result(m):
 m.player().occupied_seconds=100;m.player().damage_dealt=2000;m.hunter.hp=0;m.tick(.01)
 check(m.result=="victory" and m.strategy.verified(m,game.profile.active_match),"prepared terminal sealed through actual model")
 game._process(.01);await advance(1.6)
func strategy_review():
 phase="after"
 var mixer=AudioEffectRecord.new();AudioServer.add_bus_effect(0,mixer);mixer.set_recording_active(true)
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  game.return_menu();game.ui.campaign.prepare("stage_2")
  await button_pose("@mode_hell","hover","extra-mode-hover-"+suffix)
  await button_pose("@mode_hell","pressed","extra-mode-pressed-"+suffix)
  await button_pose("@mode_hell","focus","extra-mode-focus-"+suffix)
  await click(named_button("mode_hard"));await advance(.1)
  check(game.profile.selected_difficulty=="hard","actual mode selection saves")
  game.ui.progression.show_perk_loadout();await capture("extra-perk-loadout-"+suffix)
  game.ui.progression.show_contracts();await capture("extra-contracts-"+suffix)
  var candidates=[]
  for child in game.ui.panel.get_children():
   if child is Button and child.text=="Choose contract" and not child.is_queued_for_deletion():candidates.append(child)
  if candidates.size()==3:await click(candidates[1])
  else:check(false,"three real optional contract selectors")
  check(game.profile.selected_contract=="limited_defense","actual optional contract chosen")
  await capture("extra-contract-selected-"+suffix)
  await click(find_button("Confirm & return"));await capture("extra-preparation-contract-"+suffix)
  game.profile.select_contract("")
  game.profile.rm_cash=0;game.ui.shop.show_shop();await capture("extra-shop-unaffordable-"+suffix)
  check(game.ui.shop.buttons.all(func(b):return b.button.disabled),"actual unaffordable shop states")
  game.profile.rm_cash=200
  for room_index in range(3):
   game.profile.pending_spins=[];check(game.start_stage("stage_1","standard"),"actual unclaimed room-selection match")
   game.set_process(false);game.tutorial_enabled=true
   var m=game.model;m.player_position=m.rooms[room_index].center();game.full_map=false;game.focus_camera(true);game.ui.update_match()
   await advance(.12);await capture("extra-room-"+str(room_index+1)+"-"+suffix)
   check(m.rooms[room_index].trait_id==StrategyCatalog.TRAIT_IDS[room_index],"real room benefit/drawback identity")
  for i in range(3):
   game.profile.statistics.matches=posmod(i-2,3)
   var m=fixture("stage_1");var id=StrategyCatalog.ARCHETYPE_IDS[i]
   check(m.hunter.archetype==id and m.strategy.archetype==id,"real deterministic "+id)
   m.hunter.position=m.player().door_approach();m.hunter.target=0;m.hunter.state=HunterState.State.ATTACK;m.hunter.cooldown=0
   await advance_model(.12)
   check(m.presentation_events.any(func(e):return e.type=="archetype_warning"),"actual audible telegraph "+id)
   await capture("extra-archetype-"+id+"-"+suffix)
  for id in StrategyCatalog.BRANCHES:
   var branch=StrategyCatalog.BRANCHES[id]
   game.profile.item_loadout=["coupon","time_freeze"]
   var m=fixture("stage_1");var r=m.player();r.gold=50000;r.electricity=10000;r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp()
   var tile=0;var distance=1e20
   for i in range(r.tile_count()):
    if r.tile_position(i).distance_to(r.door_approach())<distance:distance=r.tile_position(i).distance_to(r.door_approach());tile=i
   check(m.buy(branch.kind,tile),"actual branch turret purchase")
   for i in range(3):check(m.upgrade_building(tile),"actual paid level4 preparation")
   check(game.profile.activate_item(0,m,game.match_id),"actual construction coupon arm")
   game.selected_tile=tile;game.ui.open_context();game.ui.upgrade_selected()
   check(game.ui.context_mode=="specialize","real specialization inspector")
   if id in ["precision","focus"]:await capture("extra-specialization-"+branch.kind+"-"+suffix)
   var index=StrategyCatalog.branches(branch.kind).find(id)
   var quote=(Catalog.upgrade_cost(branch.kind,4)+StrategyCatalog.BRANCH_FEE)*ItemCatalog.TUNING.coupon_factor
   var before=Vector2(r.gold,r.electricity);var stock=game.profile.inventory.coupon
   await click(named_button("specialization_"+str(index)));await advance(.12)
   check(r.buildings[tile].get("specialization","")==id and r.buildings[tile].level==5,"actual selected single branch "+id)
   check((before-Vector2(r.gold,r.electricity)).distance_to(quote)<.001 and game.profile.inventory.coupon==stock-1,"actual coupon branch price/stock")
   await capture("extra-selected-"+id+"-"+suffix)
   for i in range(5):check(m.upgrade_building(tile),"actual paid level10 continuation")
   game.ui.refresh_context();m.hunter.target=0;m.hunter.position=r.door_approach();m.hunter.state=HunterState.State.ATTACK;m._turrets(.01)
   await advance(.04);await capture("extra-level10-"+id+"-"+suffix)
   if id=="precision" and resolution.y==720:
    var refund=r.building_refund(tile);before=Vector2(r.gold,r.electricity)
    await click(game.ui.actions.sell);await advance(.1)
    check(not r.buildings.has(tile) and (Vector2(r.gold,r.electricity)-before).distance_to(refund)<.001,"actual discounted sale refund")
    check(not m.sell_building(tile),"sold tile cannot refund twice")
  game.profile.item_loadout=["barricade","time_freeze"]
  game.profile.select_contract("limited_defense")
  var m=fixture("stage_1");m.player().gold=2000
  for tile in range(3):check(m.buy("turret",tile),"actual three-turret contract violation")
  check(m.strategy.failed,"real contract failure observed")
  await advance(.1);await capture("extra-contract-failed-hud-"+suffix)
  await terminal_result(m)
  check(game.last_progression.get("contract",{}).get("cash",-1)==0,"failed contract displays zero bonus")
  await capture("extra-contract-failed-result-"+suffix)
  game.return_menu();game.profile.select_contract("no_legendary")
  var claimed=game.profile.contract_claims.has(StrategyCatalog.claim_key("stage_1","hell","no_legendary"))
  m=fixture("stage_1");await terminal_result(m)
  check(game.last_progression.get("contract",{}).get("cash",-1)==(0 if claimed else 8) and game.last_progression.contract.qualified,"qualifying contract awards once / already claimed truthfully")
  await capture("extra-contract-qualified-"+suffix)
  var cash=game.profile.rm_cash
  check(game.profile.settle_match(game.match_id,m).is_empty() and game.profile.rm_cash==cash,"rendered result cannot pay twice")
  game.return_menu();game.profile.select_contract("")
 var boss=fixture("stage_5");boss.player().bed_level=4;boss.player().door_level=4;boss.player().door_hp=boss.player().max_hp()
 boss.hunter.boss_policy.enabled=true;boss.time=boss.preparation+float(boss.hunter.boss_policy.deadline)+1;boss.hunter.hp=boss.hunter.max_hp*.5
 boss.hunter.target=0;boss.hunter.position=boss.player().door_approach();update_model(.01);await advance_model(.7)
 check(boss.hunter.transformed and boss.hunter.state==HunterState.State.TRANSFORM,"actual archetype compatible Reaper transformation")
 await capture("extra-reaper-transformation-1080")
 await advance_model(BossCatalog.TRANSFORM_SECONDS+.15)
 boss.hunter.target=0;boss.hunter.position=boss.player().door_approach();boss.hunter.state=HunterState.State.ATTACK;boss.hunter.cooldown=0
 update_model(.01);await advance(.15);check(boss.hunter.boss_attack!="","actual Reaper attack telegraph")
 await capture("extra-reaper-telegraph-1080")
 await advance_model(2.0);check(boss.hunter.last_boss_attack!="","actual Reaper attack resolves")
 await capture("extra-reaper-impact-1080")
 game.return_menu();var settings=find_button("Settings");settings.grab_focus();await key_action(KEY_ENTER);await advance(.15)
 check(game.ui.current_screen=="settings","actual keyboard activation keeps menu action")
 await capture("extra-keyboard-settings-1080")
 mixer.set_recording_active(false);var recording=mixer.get_recording()
 check(recording!=null and recording.data.size()>1000,"actual premium review master-bus recording")
 if recording!=null:check(recording.save_to_wav(ProjectSettings.globalize_path(output+"render-premium-mix.wav"))==OK,"save actual engine mix")
 print("PREMIUM_AUDIO ",JSON.stringify(game.audio_system.get_diagnostics()))
func strategy_maps_review():
 phase="after";root.size=Vector2i(1280,720)
 for stage in StageCatalog.STAGES:
  game.profile.pending_spins=[];game.profile.select_contract("")
  check(game.start_stage(stage.id,"standard"),"real map "+stage.map)
  game.set_process(false);var m=game.model;game.tutorial_enabled=true
  m.player_position=m.rooms[0].center();game.full_map=false;game.focus_camera(true)
  await advance(.15);await capture("extra-map-"+m.map_id+"-focus")
  game.full_map=true;game.focus_camera(true);await capture("extra-map-"+m.map_id+"-overview")
 await benchmark("720-normal",Vector2i(1280,720),false)
 await benchmark("1080-normal",Vector2i(1920,1080),false)
 await benchmark("720-reduced",Vector2i(1280,720),true)
 var file=FileAccess.open(output+"render-frame-observations.json",FileAccess.WRITE)
 if file:file.store_string(JSON.stringify({"fresh_pre_phase_baseline_recorded":false,"scope":"Bounded warmed Linux llvmpipe observations of final prepared stage1 scene; not Windows FPS, not matched prephase comparison","observations":perf}," "))
func run():
 phase=OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "before"
 output="res://docs/evidence/premium-strategy/"
 if phase=="before" and FileAccess.file_exists(output+"before/01-menu-720.png"):
  push_error("Preserved premium baseline exists; refusing overwrite.");quit(1);return
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://premium-render-"+phase+"-"+str(Time.get_ticks_usec())+".json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 preload("res://tests/onboarding_test_support.gd").skip(game);game.set_process(false);game.onboarding.set_process(false)
 game.profile.next_match_id=2;game.profile.xp=3800;game.profile.rm_cash=200
 for stage in StageCatalog.STAGES:game.profile.campaign_records[stage.id]=record()
 for id in ItemCatalog.IDS:game.profile.inventory[id]=20
 game.profile.item_loadout=["barricade","time_freeze"];game.profile.equipped=["dreamer","first_aid"];game.profile.save_profile()
 if phase=="details":
  await strategy_review();await finish_capture();return
 if phase=="observations":
  await strategy_maps_review();await finish_capture();return
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  game.return_menu();await advance(.15);await capture("01-menu-"+suffix)
  await button_pose("Start Game","hover","02-play-hover-"+suffix)
  await button_pose("Start Game","pressed","03-play-pressed-"+suffix)
  await button_pose("Start Game","focus","04-play-focus-"+suffix)
  check(game.mode=="menu","held pointer cancels without entering match")
  game.ui.campaign.show_stages();await capture("05-stages-"+suffix)
  for difficulty in ["standard","hard","hell"]:
   game.profile.select_difficulty(difficulty);game.ui.campaign.prepare("stage_2");await capture("06-mode-"+difficulty+"-"+suffix)
  game.profile.rm_cash=200;game.ui.shop.show_shop();await capture("07-shop-"+suffix)
  await button_pose("Buy · 18 RM Cash","hover","08-shop-hover-"+suffix)
  await button_pose("Buy · 18 RM Cash","pressed","09-shop-pressed-"+suffix)
  check(game.profile.rm_cash==200,"held shop press cancellation spends nothing")
  var m=fixture("stage_1");m.time=5;m.hunter.state=HunterState.State.DORMANT
  await advance(.15);await capture("10-hud-preparation-"+suffix)
  m.time=m.preparation+90;m.hunter.target=0;m.hunter.position=m.player().door_approach();m.hunter.state=HunterState.State.ATTACK;m.player().door_hp=m.player().max_hp()*.4
  await advance(.2);await capture("11-hud-siege-"+suffix)
  game.selected_tile=0;game.ui.open_context();await capture("12-build-panel-"+suffix)
  game.ui.close_context();game.toggle_pause();await capture("13-pause-"+suffix);game.toggle_pause()
 root.size=Vector2i(1280,720)
 game.return_menu();game.ui.shop.show_shop();await click(find_button("Buy · 18 RM Cash"));await advance(.15);check(game.profile.rm_cash==182 and game.profile.inventory.repair==21,"actual purchase spends18 and grantsone");await capture("14-shop-success")
 for page in range(3):game.ui.items_ui.inventory_page=page;game.ui.items_ui.inventory();await capture("15-inventory-"+str(page+1))
 game.ui.progression.show_ranks();await capture("16-ranks")
 for page in range(2):game.ui.progression.achievement_page=page;game.ui.progression.show_achievements();await capture("17-achievements-"+str(page+1))
 game.ui.show_settings();await capture("18-settings")
 game.ui.show_help();await capture("19-handbook")
 var m=fixture("stage_3");var r=m.player();r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp();r.gold=30000;r.electricity=5000
 check(r.build("heavy",0),"real Arc purchase")
 for i in range(9):
  var success=r.specialize_building(0,"focus") if r.strategy_enabled and r.buildings[0].level==4 else r.upgrade_building(0)
  check(success,"paid upgrade / chosen level5 specialization")
 game.selected_tile=0;game.ui.open_context();await capture("20-upgrade-max-panel")
 game.ui.close_context();m.hunter.hp=0;r.occupied_seconds=100;r.damage_dealt=2000;m.tick(.01);check(m.result=="victory","real terminal result and strategy seal");game._process(.01)
 await advance(1.6);await capture("21-results")
 game.ui.items_ui.spin();await capture("22-lucky-spin");game.profile.claim_spin(game.match_id);game.return_menu()
 game.start_tutorial(true);m=game.model;m.claim_room(0);m.player_position=m.player().bed_position()+Vector2(35,0);game.onboarding.step=2;game.onboarding.refresh_objective();game.ui.update_match();game.focus_camera(true)
 await capture("23-genuine-tutorial");game.onboarding.finish_replay()
 game.onboarding.show_opening();game.onboarding.elapsed=6;game.onboarding.queue_redraw();await capture("24-opening")
 game.onboarding.show_title();game.onboarding.elapsed=2;game.onboarding.queue_redraw();await capture("25-title");game.onboarding.skip()
 print("PREMIUM_RENDER_CHECKS=",checks," FAILURES=",failures," BASELINE_SOURCE=",BASELINE_SOURCE)
 game.audio_system.shutdown();await create_timer(.5).timeout;game.queue_free();await process_frame;quit(0 if failures==0 else 1)
