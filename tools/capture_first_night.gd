extends "res://tools/capture_onboarding.gd"
var started=0
var journey=[]
var recorder
var label: Label
func tell(text):
 if is_instance_valid(label):label.text=text
 journey.append({"seconds":0.0 if started==0 else (Time.get_ticks_usec()-started)/1e6,"text":text})
func click_point(point):
 Input.warp_mouse(point);var motion=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;Input.parse_input_event(motion);await process_frame
 await super.click_point(point)
func move_to(goal):
 await super.move_to(goal)
func capture(name):
 await super.capture(name)
func build_real(kind,tile):
 await world_click(game.model.player().tile_position(tile));await wait(.35);await click(game.ui.actions["build:"+kind]);await wait(.35)
func nearest_empty(r):
 var best=-1;var distance=1e20
 for id in range(r.tile_count()):
  if r.buildings.has(id):continue
  var d=r.tile_position(id).distance_to(r.door_approach())
  if d<distance:distance=d;best=id
 return best
func after_cold():pass
func run():
 output="res://docs/evidence/first-night/screens/";root.size=Vector2i(1280,720)
 var path="user://phase11-cold-"+str(Time.get_ticks_usec())+".json";OS.set_environment("NIGHTFALL_PROFILE_PATH",path)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.onboarding.set_process(false)
 check(game.profile.xp==0 and game.profile.inventory.is_empty() and not game.profile.tutorial_completed,"actual fresh profile has no unlocked advantages")
 var layer=CanvasLayer.new();layer.layer=99;root.add_child(layer);label=Label.new();label.position=Vector2(20,705);label.add_theme_font_size_override("font_size",11);label.size=Vector2(1240,15);label.clip_text=true;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(label)
 tell("SCRIPTED REAL INPUT · fresh profile · standard built-in practice credits only")
 var out=[];OS.execute("python",[ProjectSettings.globalize_path("res://tools/first_night_xinput.py"),"focus",str(DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE))],out)
 print("VIDEO_READY")
 if "record" in OS.get_cmdline_user_args():
  while not FileAccess.file_exists("/tmp/phase11-record-go"):await process_frame
 recorder=AudioEffectRecord.new();AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);started=Time.get_ticks_usec();game.set_process(true);game.onboarding.set_process(true)
 await wait(1);await key(KEY_SPACE);await wait(.3);await capture("01-first-time-welcome");await click(game.onboarding.welcome_close);await wait(.2);await click(game.ui.menu_start);await wait(.4);await capture("02-primary-objective")
 var fx=game.onboarding;var m=game.model
 await key(KEY_B);await wait(.3);check(fx.step==0 and m.player()==null,"invalid early build cannot advance objective or claim room")
 tell("Walk into the highlighted room · genuine held WASD")
 await move_to(m.rooms[0].bed_position()+Vector2(31,46));await step_at_least(1);await capture("03-claim-room-guidance")
 await key(KEY_E);await step_at_least(2);await capture("04-sleep-guidance")
 await move_to(m.player().bed_position()+Vector2(31,46));await key(KEY_E);await step_at_least(3);await step_at_least(4)
 await key(KEY_B);await wait(.4);await capture("05-dynamo-construction-guidance")
 var r=m.player();var before_build=r.buildings.duplicate(true)
 await click(game.ui.actions["build:heavy"]);await wait(.2);check(r.buildings==before_build and fx.step==4,"disabled Arc cannot spend funds or complete the Dynamo lesson")
 # Close/reopen proves recovery through actual UI, not a direct lesson callback.
 await key(KEY_ESCAPE);await click(find_button("Recover / reopen build controls"));await wait(.4)
 check(game.ui.context_open and game.ui.context_mode=="build","actual recovery button reopens correct build panel")
 await click(game.ui.actions["build:generator"]);await step_at_least(5);await wait(.4)
 var turret=nearest_empty(r);await key(KEY_ESCAPE);await wait(.35);await world_click(r.tile_position(turret));await wait(.4);await capture("06-turret-range-guidance");await click(game.ui.actions["build:turret"]);await step_at_least(6);await wait(.4)
 check(r.buildings[turret].kind=="turret" and fx.defense_ready(r),"actual in-range Needle bought using ordinary practice controls")
 await capture("06b-built-turret-actual-range")
 await click(game.ui.actions.upgrade);await wait(.4);await capture("07-door-repair-guidance");await key(KEY_R);await step_at_least(7)
 tell("Real practice combat · actual Hunter strikes and automatic turret shots")
 await step_at_least(8,30);await capture("08-tutorial-victory")
 check(r.shots>0 and fx.damage_observed and r.alive,"practice victory required actual outgoing shots and incoming attack")
 await click(find_button("Save completion & enter menu"));await wait(.4)
 check(game.profile.tutorial_completed and game.profile.xp==0 and game.profile.rm_cash==0 and game.profile.inventory.is_empty(),"tutorial completion saves without permanent rewards")
 var reloaded=PlayerProfile.new(path);check(reloaded.load_profile() and reloaded.tutorial_completed,"actual completion survives disk load")
 tell("First ordinary Campaign match · default wallet / no injected progression")
 await click(game.ui.menu_start);await wait(.3);await click(find_button("Prepare"));await wait(.3);await click(find_button("Start Match"));await wait(.4)
 check(game.mode=="match" and not game.tutorial_active and game.model.stage_id=="stage_1","first ordinary Normal campaign starts through actual menu buttons")
 await wait(.2);m=game.model
 var chosen=m.rooms.filter(func(room):return room.owner<0)[0]
 await move_to(chosen.bed_position()+Vector2(31,46));await key(KEY_E);await wait(.2)
 if m.player()==null:
  chosen=m.rooms.filter(func(room):return room.owner<0)[0];await move_to(chosen.bed_position()+Vector2(31,46));await key(KEY_E)
 check(m.player()!=null,"actual ordinary match room claim through input")
 if m.player()!=null:
  await move_to(m.player().bed_position()+Vector2(31,46));await key(KEY_E);await wait(1)
  var ordinary=m.player();check(ordinary.sleeping,"ordinary E sleeps within interaction radius");var tile=nearest_empty(ordinary)
  await build_real("turret",tile);check(ordinary.buildings.has(tile),"ordinary Needle purchase from real starting wallet")
  var deadline=Time.get_ticks_msec()+25000
  while ordinary.gold<Catalog.BUILDINGS.generator.gold and Time.get_ticks_msec()<deadline:await process_frame
  await key(KEY_ESCAPE);await wait(.3);await build_real("generator",nearest_empty(ordinary));await key(KEY_ESCAPE);await wait(.3)
  await wait(3.2);await capture("09-normal-gameplay-without-clutter");await key(KEY_ESCAPE);await wait(.2);check(not m.running,"ordinary match pause")
  await key(KEY_ESCAPE);await wait(.2);check(m.running,"ordinary match resume")
 game.return_menu();game.ui.show_settings();await wait(.4);await capture("19-guidance-settings")
 var before=game.profile._reward_snapshot();game.profile.update_setting("guidance_mode","off");check(game.profile._reward_snapshot().get("xp")==before.get("xp"),"guidance preference has no XP side effect")
 await after_cold()
 var receipt={"checks":checks,"failures":failures,"seconds":(Time.get_ticks_usec()-started)/1e6,"profile_path":path,"timeline":journey,"tutorial_completed":game.profile.tutorial_completed,"cold_xp":reloaded.xp,"cold_rm_cash":reloaded.rm_cash,"conditions":"Actual production scene, fresh isolated profile, scripted InputEvent keyboard/mouse through normal controller and UI. No teleports, no manual wallet/stat/XP assignments. Existing tutorial's own temporary funding and weak encounter are unchanged. First ordinary match uses its default economy. Not human or native Windows testing."}
 var file=FileAccess.open("res://docs/evidence/first-night/cold-journey.json",FileAccess.WRITE);file.store_string(JSON.stringify(receipt," "))
 recorder.set_recording_active(false);var wav=recorder.get_recording();check(wav!=null and wav.data.size()>1000,"actual cold journey Master audio");if wav!=null:wav.save_to_wav("res://docs/evidence/first-night/video/cold-master.wav")
 AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
 print("COLD_JOURNEY_CHECKS=",checks," FAILURES=",failures);game.audio_system.shutdown();game.queue_free();layer.queue_free();await wait(.5);quit(1 if failures else 0)
