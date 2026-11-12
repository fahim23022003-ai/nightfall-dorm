extends "res://tools/capture_phase5d4_dense.gd"
var feedback=[]
func run():
 output="res://docs/evidence/phase5d4/";phase="core-render";await setup_game()
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y);var m=effect_fixture();await drive(.1)
  await capture("final-live-heal-shield-decoy-"+suffix)
  feedback.append({"case":"actualpaid+120healing/Shield/Decoy","resolution":suffix,"heals":m.presentation_events.filter(func(e):return e.type=="defense_heal"),"lure":m.defenses.lure_remaining,"barrier":m.player().barrier_hp})
  await drive(.8);check(not m.defenses.burns.is_empty() and m.defenses.lure_remaining>0,"realburn/lureactive fordrawfeedback")
  await capture("final-live-burn-lure-"+suffix);game.profile.settings.reduced_effects=true;await advance(.1);await capture("final-live-defense-reduced-"+suffix);game.profile.settings.reduced_effects=false
  # Exact Frost comparisons and tooltip after truthful actor-specific UI fix.
  var r=m.player();var frost=-1
  for tile in r.buildings:
   if r.buildings[tile].kind=="frost":frost=tile;break
  await world_click(r.tile_position(frost));await advance(.2);await capture("final-frost-current-next-"+suffix)
  check(game.ui.selected_details.text.contains("15") and game.ui.selected_details.text.contains("30"),"Frostcurrentactual actorvalues visible")
  game.ui.close_context();m=prepared();r=m.player();check(r.build("frost",0),"actualpaidFrostcomparisonfixture")
  for i in range(3):check(r.upgrade_building(0),"paidFrostL4")
  await world_click(r.tile_position(0));await advance(.15);await click(game.ui.actions.upgrade);await advance(.2);await capture("final-frost-truthful-branches-"+suffix)
  for b in [game.ui.specialization_items[1],game.ui.specialization_items[2]]:
   check(b.size.y>=b.get_combined_minimum_size().y and not b.get_global_rect().intersects(game.ui.branch_confirm.get_global_rect()),"truthfulFrostlinesfit branch target")
  var motion=InputEventMouseMotion.new();motion.position=root.get_final_transform()*game.ui.specialization_items[1].get_global_rect().get_center();motion.global_position=motion.position;Input.parse_input_event(motion);await create_timer(.7).timeout;await capture("final-frost-full-tooltip-"+suffix)
  # Bottom-facing doorway validates persistent burn-number clearance.
  game.return_menu();game.start_practice("crusher",false,["shield","repair"]);game.set_process(false);game.tutorial_enabled=false;m=game.model;r=m.player();var tile=m.practice_tile
  check(r.sell_building(tile) and r.build("flame",tile),"paidFlame replacesNeedle onnearestpad")
  m.hunter.boss_policy.enabled=false;m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.position=r.door_approach();m.hunter.cooldown=60;m.hunter.tactical_cooldown=60;game.focus_camera(true)
  await drive(1);check(not m.defenses.burns.is_empty(),"actualbottomdoorHunterburns")
  await capture("final-bottom-door-burn-"+suffix)
  var at=game.world_to_screen(m.hunter.position+Vector2(-39,17));var end=game.world_to_screen(m.hunter.position+Vector2(43,34));var badge=Rect2(at,end-at)
  check(not badge.intersects(game.ui.room_dock.get_global_rect()),"persistentburnbadge clear ofbottomheader")
  feedback.append({"case":"bottom-facingburnbadge","resolution":suffix,"badge_rect":str(badge),"header_rect":str(game.ui.room_dock.get_global_rect()),"intersects_header":badge.intersects(game.ui.room_dock.get_global_rect())})
 var f=FileAccess.open("res://docs/evidence/phase5d4/final-d-feedback-result.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"feedback":feedback,"fixture":"ActualpaidPractice realhealing/barrier/lure/burn states, read-onlynewFX; twores, ReducedFX and truthfulFrostcurrent/branch/tooltip. No naturalbalanceclaim."}," "))
 print("PHASE5D4_FINAL_FEEDBACK_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
