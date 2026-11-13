extends "res://tools/spatial_performance.gd"
func run():
 output="res://docs/evidence/every-night/";phase="screens";root.size=Vector2i(1280,720);await setup_game();game.onboarding.close_welcome()
 var data=JSON.parse_string(FileAccess.get_file_as_string(output+phase+"/prepared-wave1-checkpoint.json"));var m=ReplaySnapshot.restore(data)
 check(m!=null,"real captured prepared checkpoint loads")
 if m==null:quit(1);return
 game.model=m;game.mode="match";game.watched_room=-1;game.construction.reset();game.ui.show_match();game.focus_camera(true);game.audio_system.reset_match(m);game.presentation.environment.night_seed=417;game.presentation.environment.configure(m)
 game.selected_tile=16;game.ui.open_context();await advance(.5)
 var rows=[];game.construction.ranges=false;rows.append(await sample("full16 inspector, range off"))
 game.construction.ranges=true;rows.append(await sample("full16 inspector, actual range on"))
 var nodes=game.audio_system.get_child_count();var starts=game.audio_system.music_start_count
 for i in range(200):
  game.audio_system.update_state(.1,m,"match" if i%2==0 else "menu")
 check(nodes==game.audio_system.get_child_count() and starts==game.audio_system.music_start_count,"200 state updates never allocate additional players")
 var f=FileAccess.open(output+"performance.json",FileAccess.WRITE);f.store_string(JSON.stringify({"rows":rows,"checks":checks,"failures":failures,"music_players":starts,"conditions":"Linux Godot4.6.3 Mesa llvmpipe shared CPU, 30 warmup and240 measured frames/state; full16 actual prepared checkpoint, range off/on within current executable. Not paired baseline executable, human FPS or Windows/hours-long evidence."}," "))
 print("SESSION_PERFORMANCE_CHECKS=",checks," FAILURES=",failures);game.audio_system.shutdown();game.queue_free();await create_timer(.5).timeout;quit(1 if failures else 0)
