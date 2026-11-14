extends "res://tools/capture_first_night.gd"
# Supplemental rendered layout checks. Restored fixtures, not human playtests.
func run():
 output="res://docs/evidence/first-night/screens/";root.size=Vector2i(1920,1080)
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://phase11-layout-"+str(Time.get_ticks_usec())+".json")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.onboarding.set_process(false);game.onboarding.close_welcome();game.onboarding.active=false;game.onboarding.phase="idle";game.onboarding.clean_controls();game.onboarding.queue_redraw()
 var actual=JSON.parse_string(FileAccess.get_file_as_string("res://docs/evidence/first-night/earned46-live.json"));game.model=ReplaySnapshot.restore(actual.checkpoint);check(game.model!=null,"live recorded wave46 checkpoint restored")
 game.mode="match";game.ui.replay_ui.preparing=true;game.ui.show_match();game.focus_camera(true);game.ui.update_match();await wait(.4)
 SessionInterface.wave_report(game.ui);await wait(.4);await capture("18-wave-report-1080")
 game.ui.show_match();check(game.model.continue_wave("power"),"normal next wave for1080 gameplay");game.audio_system.reset_match(game.model);game.set_process(true);await wait(2);await capture("18-gameplay-1080");game.set_process(false)
 for size in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
  root.size=size;game.focus_camera(true);game.ui.update_match();game.guidance.refresh(game);await wait(.3);await capture("layout-"+str(size.y))
 root.size=Vector2i(1280,720)
 var old=JSON.parse_string(FileAccess.get_file_as_string("res://docs/evidence/every-night/screens/prepared-wave1-checkpoint.json"));game.model=ReplaySnapshot.restore(old);check(game.model!=null,"prepared early Omen checkpoint remains compatible")
 game.ui.replay_ui.preparing=false;game.ui.replay_ui.intermission_saved=true;game.ui.replay_ui.show_intermission();await wait(.5);await capture("15b-early-omen-decisions")
 check(NightOmens.offered(game.model.endless.completed),"existing early Omen choice retained")
 print("FIRST_NIGHT_SUPPLEMENT_CHECKS=",checks," FAILURES=",failures);game.audio_system.shutdown();game.queue_free();await wait(.5);quit(1 if failures else 0)
