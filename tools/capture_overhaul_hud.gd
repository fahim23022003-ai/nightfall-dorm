extends "res://tools/capture_phase5d3_team.gd"
# Independent actual rendered/input gate; temporary fixtures, not balance proof.
var rows=[]
var slide_rows=[]
func write_result():
 var f=FileAccess.open("res://docs/evidence/gameplay-overhaul/hud/result.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":rows,"transitions":slide_rows,"fixture":"Linux actual Xorg/Mesa/Dummy sink. Unique isolated profile; controlled seated Stage1 campaign layout for default/build/purchase; Practice's own temporary resources for upgrade/branches. Held model except actual scripted door damage. No natural-play/audio/Windows/performance claim."}," "))
func scene_ready():
 game.set_process(false);game.tutorial_enabled=false
 game.ui.teammates.expanded=false;game.ui.items_ui.expanded=false;game.ui.help_open=false;game.ui.close_context();game.focus_camera(true)
 await advance(.4)
func finish_slide(label):
 var samples=[];var start=Time.get_ticks_usec()
 while game.ui.bottom_context.is_transitioning() and Time.get_ticks_usec()-start<1200000:
  samples.append({"elapsed":(Time.get_ticks_usec()-start)/1000000.0,"y":game.ui.context_box.position.y,"visible":game.ui.context_box.visible})
  await advance(.016)
 samples.append({"elapsed":(Time.get_ticks_usec()-start)/1000000.0,"y":game.ui.context_box.position.y,"visible":game.ui.context_box.visible})
 slide_rows.append({"label":label,"configured_seconds":BottomContextPanel.SLIDE_SECONDS,"samples":samples})
 check(not game.ui.bottom_context.is_transitioning(),"actual Tween completes "+label)
func close_button():
 for child in game.ui.context_box.get_children():
  if child is Button and child.text=="×":return child
 return null
func run():
 output="res://docs/evidence/gameplay-overhaul/";phase="hud"
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://overhaul-hud-render-"+str(OS.get_process_id())+"-"+str(Time.get_ticks_usec())+".json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 preload("res://tests/onboarding_test_support.gd").skip(game);game.set_process(false);game.onboarding.set_process(false)
 if "transitions" in OS.get_cmdline_user_args():
  await transitions_only();return
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  game.return_menu();check(game.start_stage("stage_1","standard"),"real Stage1 Normal launches")
  var m=game.model;check(m.claim_room(0),"real room claim")
  m.player_position=m.player().bed_position();m.sleep_player();m.bot_claimed=5
  for i in range(1,6):
   var r=m.rooms[i];r.owner=i;r.sleeping=true;r.closed=true;r.resident_position=r.bed_position()
  await scene_ready();await advance(1.8)
  var ui=game.ui;var room=m.player();var camera=game.camera.position;var zoom=game.camera.zoom;var player=m.player_position
  check(ui.room_dock.position.y>=650 and ui.room_dock.get_global_rect().end.y<=720,"toolbar genuinely bottom aligned")
  for button in [ui.room_selected_summary,ui.room_bed_summary,ui.room_door_summary,ui.quick_repair,ui.bottom_context.upgrade_shortcut]:
   check(button.get_global_rect().position.y>=650 and button.get_global_rect().end.y<=704,"all primary toolbar actions fit")
  check(not ui.context_box.visible,"default drawer hidden")
  await capture("default-hud-"+suffix)
  var stock=room.gold;var power=room.electricity
  await click(ui.room_selected_summary)
  check(ui.context_open and ui.context_mode=="build","actual toolbar Build opens drawer")
  check(ui.bottom_context.is_transitioning(),"drawer begins real opening Tween")
  await capture("opening-build-"+suffix)
  await finish_slide("open-"+suffix)
  check(ui.context_box.position.is_equal_approx(BottomContextPanel.BODY.position),"drawer settles at authored location")
  for id in Catalog.BUILDINGS:
   var b=ui.actions["build:"+id]
   check(ui.context_box.get_global_rect().encloses(b.get_global_rect()),"build card contained "+id)
  await capture("open-build-"+suffix)
  check(room.gold==stock and room.electricity==power,"opening spends nothing")
  await click(ui.actions["build:heavy"])
  check(room.buildings.is_empty() and room.gold==stock and room.electricity==power,"unaffordable Arc cannot buy or charge")
  await click(ui.actions["build:turret"])
  var tile=game.selected_tile
  check(room.buildings.has(tile) and room.buildings[tile].kind=="turret" and room.gold==stock-20 and room.electricity==power,"one real direct purchase exact20Gold")
  check(ui.context_mode=="upgrade" and game.pending_build=="","direct purchase leaves valid inspector and no stuck placement")
  var spent=room.gold
  await click(ui.actions["build:turret"],true)
  check(room.buildings.size()==1 and room.gold==spent,"late doubleclick cannot duplicate purchase")
  check(ui.selected_details.text.contains("LEVEL 1"),"actual selected level label")
  await capture("purchased-needle-"+suffix)
  var hp=room.door_hp;m.hunter.target=0;m.hunter.state=HunterState.State.ATTACK;m.hunter.position=room.door_approach()
  m.hunter._damage_door(room,m,5);await advance(.12)
  check(room.door_hp<hp and ui.context_open and ui.context_box.visible,"actual door damage never autocloses drawer")
  check(ui.warning_box.visible,"own danger remains visible with drawer open")
  await capture("under-attack-open-"+suffix)
  check(game.camera.position==camera and game.camera.zoom==zoom and m.player_position==player,"panels and attack state preserve focused camera/player")
  await click(close_button())
  check(not ui.context_open and ui.bottom_context.is_transitioning() and ui.context_box.visible,"actual close starts downward Tween")
  await capture("closing-build-"+suffix);await finish_slide("close-"+suffix)
  check(not ui.context_box.visible and ui.room_dock.visible,"close restores compact toolbar")
  await capture("closed-after-attack-"+suffix)
  # Real rapid toolbar-open/close reversals. No purchase or manual signal emits.
  for i in range(3):
   await click(ui.room_selected_summary);await key(KEY_ESCAPE)
  await finish_slide("rapid-reversal-"+suffix)
  check(not ui.context_open and not ui.context_box.visible and game.pending_build=="","rapid real-input reversals leave no stranded drawer")
  check(room.gold==spent and room.buildings.size()==1,"rapid controls do not spend or duplicate")
  rows.append({"resolution":suffix,"toolbar":str(ui.room_dock.get_global_rect()),"body":str(ui.context_box.get_global_rect()),"camera":str(camera),"zoom":str(zoom),"player":str(player),"campaign_gold_after":room.gold,"campaign_electricity_after":room.electricity})
  game.return_menu();check(game.start_practice("crusher",false,["shield","repair"]),"real isolated Practice launches")
  await scene_ready();m=game.model;room=m.player();ui=game.ui
  var practice_tile=m.practice_tile;game.selected_tile=practice_tile
  var g=room.gold;var e=room.electricity;var level=room.buildings[practice_tile].level
  await world_click(room.tile_position(practice_tile));await finish_slide("practice-inspector-"+suffix)
  check(ui.context_mode=="upgrade" and ui.selected_details.text.contains("LEVEL 4"),"real occupied pad inspector shows L4")
  await click(ui.bottom_context.upgrade_shortcut);await finish_slide("shortcut-open-"+suffix)
  check(ui.context_open and ui.context_mode=="upgrade","toolbar upgrade shortcut opens selected building")
  await capture("upgrade-inspector-"+suffix)
  await click(ui.actions.upgrade)
  check(ui.context_mode=="specialize" and room.buildings[practice_tile].level==level and room.gold==g and room.electricity==e,"branch preview spends nothing")
  await click(ui.specialization_items[1]);await advance(.05)
  check(ui.pending_branch!="" and room.gold==g and room.buildings[practice_tile].level==level,"branch selection awaits explicit confirmation")
  await capture("specialization-preview-"+suffix)
  await click(ui.branch_confirm);await advance(.08)
  check(room.buildings[practice_tile].level==5 and room.gold<g and room.electricity<e,"explicit branch confirm pays and advances L5")
  var bought_g=room.gold;var bought_e=room.electricity
  await click(ui.branch_confirm,true)
  check(room.buildings[practice_tile].level==5 and room.gold==bought_g and room.electricity==bought_e,"duplicate branch-confirm cannot pay twice")
  await capture("specialization-chosen-"+suffix)
  await click(ui.room_bed_summary);await advance(.05)
  check(ui.context_mode=="bed" and ui.context_title.text.contains("5 / 10"),"bottom Bed opens real bed level")
  await capture("bed-inspector-"+suffix)
  await click(ui.room_door_summary);await advance(.05)
  check(ui.context_mode=="door" and ui.context_title.text.contains("5 / 10"),"bottom Door opens real door level")
  await capture("door-inspector-"+suffix)
  m.hunter.target=0;m.hunter.position=room.door_approach();m.hunter.state=HunterState.State.ATTACK
  m.hunter._damage_door(room,m,50);await advance(.05);var hurt=room.door_hp;g=room.gold
  await click(ui.quick_repair);await advance(.05)
  check(room.door_hp>hurt and room.gold<g and ui.context_open,"bottom quick repair works while drawer remains open")
  await key(KEY_ESCAPE);await finish_slide("escape-close-"+suffix)
  check(not ui.context_open and not ui.context_box.visible,"actual Escape slides drawer closed")
 write_result();print("OVERHAUL_HUD_RENDER_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
func transitions_only():
 phase="hud/after-layering"
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  game.return_menu();check(game.start_stage("stage_1","standard"),"real campaign launches")
  var m=game.model;check(m.claim_room(0),"actual ownership")
  m.player_position=m.player().bed_position();m.sleep_player();await scene_ready();await advance(1.8)
  var ui=game.ui;var camera=game.camera.position;var stock=m.player().gold
  await click(ui.room_selected_summary);check(ui.bottom_context.is_transitioning(),"opening in motion")
  await capture("opening-"+suffix);await finish_slide("open-"+suffix);await capture("opened-"+suffix)
  await click(close_button());check(ui.bottom_context.is_transitioning(),"closing in motion")
  await advance(.06);await capture("closing-"+suffix);await finish_slide("close-"+suffix)
  check(not ui.context_box.visible and ui.room_dock.visible,"toolbar restored")
  check(game.camera.position==camera and m.player().gold==stock,"transitions preserve camera/resources")
  await capture("closed-"+suffix)
 var f=FileAccess.open("res://docs/evidence/gameplay-overhaul/hud/after-layering/result.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"checks":checks,"failures":failures,"transitions":slide_rows,"fixture":"Affected visual layering refresh only; actual campaign toolbar/close inputs, controlled held model, real0.26Tween, LinuxXorg/Mesa/Dummy."}," "))
 print("OVERHAUL_HUD_LAYERING_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
