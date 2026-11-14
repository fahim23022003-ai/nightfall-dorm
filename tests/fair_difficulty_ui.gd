extends "res://tests/onboarding_flow.gd"
func run():
 await create(true);game.onboarding.close_welcome();await process_frame
 check(game.start_stage("stage_1","hell"),"actual fresh eligible hard Campaign starts")
 var m=game.model;m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();var r=m.player()
 # Prepared UI states only, never a victory or affordability simulation claim.
 m.time=150;m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.position=r.door_approach();m.hunter.recovery_remaining=1.5;r.door_hp=r.max_hp()*.5
 for size in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=size;game.ui.show_match();game.ui.update_match();await process_frame
  check(game.ui.hunter_detail.text.contains("RECOVERY") and not game.ui.hunter_detail.text.contains("Hover"),"recovery is not demoted by adaptive urgent-information priority")
  check(game.ui.warning_label.text.contains("DOOR") and game.ui.warning_label.text.contains("RECOVERY"),"door HP and real recovery remain together")
  await key(KEY_B);game.ui.update_match();check(game.ui.context_open and game.ui.warning_box.visible,"build menu preserves urgent warning and keyboard input")
  await key(KEY_ESCAPE);check(not game.ui.context_open,"Escape restores unobstructed compact HUD")
  await mouse_button(game.ui.room_door_summary);game.ui.update_match();check(game.ui.context_mode=="door" and game.ui.warning_label.visible,"mouse opens door actions without hiding counter window")
  await key(KEY_ESCAPE)
 r.gold=500;r.electricity=50;m.buy("repair",9);r.electricity=0
 var description=BuildingStats.next_machine(m,r,9)
 check(description.contains("0.00") and description.contains("reserve") and description.split("\n").size()<=7,"repair limitation and next-level summary fit existing inspector")
 check(not m.choices.enabled(m),"Campaign remains outside perk/merchant scope")
 await dispose();print("FAIR_DIFFICULTY_UI_CHECKS=",checks," FAILURES=",failures);quit(1 if failures else 0)
