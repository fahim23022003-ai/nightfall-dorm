extends "res://tools/record_spatial_construction.gd"
func run():
 output="res://docs/evidence/every-night/";phase="video";root.size=Vector2i(1280,720);await setup_game();game.onboarding.close_welcome();game.return_menu();await advance(.4)
 var layer=CanvasLayer.new();layer.layer=90;root.add_child(layer);caption=Label.new();caption.position=Vector2(355,650);caption.add_theme_font_size_override("font_size",14);caption.add_theme_color_override("font_shadow_color",Color.BLACK);caption.add_theme_constant_override("shadow_outline_size",4);caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(caption)
 caption.text="PHASE 10 · scripted native mouse/keys · Linux Godot 4.6.3"
 print("VIDEO_READY")
 while not FileAccess.file_exists("/tmp/session-record-go"):await process_frame
 pcm_start();started=Time.get_ticks_usec();await advance(1)
 game.ui.show_settings();await advance(.4)
 await native_click(find_button("Soundtrack · playlist preferences"));check(game.ui.current_screen=="soundtrack","native soundtrack button opens preferences");await advance(1)
 tell("Saved soundtrack mode · separate from Listening Room previews")
 var mode=game.ui.panel.get_node("music_mode");await native_click(mode);await native_key("Home");await native_key("Down");await native_key("Down");await native_key("Down");await native_key("Return");await advance(.5);SessionInterface.refresh(game.ui)
 print("NATIVE_MUSIC_MODE=",game.profile.settings.music_mode);check(game.profile.settings.music_mode=="manual","native menu selects persistent Manual Track")
 tell("Manual selection saved · Reaper/Crimson music retains priority");await advance(1.5)
 var m=fresh();caption.position=Vector2(355,78);var r=m.player();r.gold=3000;r.electricity=700;game.construction.snap=false
 tell("Prepared isolated wallet · range follows real mouse position")
 await native_click(game.ui.room_selected_summary);await native_click(game.ui.actions["build:turret"])
 for point in [Vector2(175,151),Vector2(245,100),Vector2(175,151)]:await native_world(point,false);await advance(.7)
 await native_world(Vector2(175,151));check(r.buildings.size()==1,"native purchase with range preview")
 var original=r.tile_position(16);await native_world(original);await native_click(game.construction.move_button)
 tell("Move the SAME turret · no payment, upgrade or cooldown reset")
 await native_world(Vector2(180,88),false);await advance(.8);await native_world(Vector2(180,88));await native_world(r.tile_position(16));await advance(.5)
 tell("Undo [Z] restores previous valid position · one use only");await native_click(game.construction.undo_button);check(r.tile_position(16)==original,"native GUI undo");await advance(1)
 await native_key("O");check(not game.construction.ranges,"native range toggle off");await native_key("O");check(game.construction.ranges,"native range toggle on")
 game.ui.close_context();await advance(.4)
 tell("Live wave · ordinary prices, HP and combat · prepared room")
 var h=m.hunter;h.boss_policy.enabled=false;h.position=r.door_approach();h.target=0;h.state=HunterState.State.ATTACK;h.cooldown=1
 m.time=m.preparation+.01;await live(8);check(m.shots>0 and h.hp<h.max_hp,"live normal combat after moving and undo")
 tell("Uncut scripted-input demonstration complete · not a human playtest");await advance(1)
 pcm_finish("native-input-master")
 var f=FileAccess.open(output+phase+"/timeline.json",FileAccess.WRITE);f.store_string(JSON.stringify({"timeline":timeline,"seconds":(Time.get_ticks_usec()-started)/1e6,"checks":checks,"failures":failures,"conditions":"Uncut XTest native input, production UI. Prepared isolated wallet/room, frozen prep showcase then actual wall-time combat; no human/Windows claim."}," "))
 print("VIDEO_COMPLETE checks=",checks," failures=",failures);layer.queue_free();game.audio_system.shutdown();game.queue_free();await create_timer(.3).timeout;quit(1 if failures else 0)
