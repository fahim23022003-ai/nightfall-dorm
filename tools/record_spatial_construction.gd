extends "res://tools/capture_spatial_construction.gd"
# Uncut native XTest pointer/keyboard events; no direct economic action calls.
var caption: Label
var timeline=[]
var started=0
func tell(text):
 caption.text=text;timeline.append({"seconds":(Time.get_ticks_usec()-started)/1e6,"text":text})
func native(action: String,args: Array=[]):
 var out=[];check(OS.execute("python",["/tmp/spatial_xinput.py",action]+args,out)==0,"native "+action);await process_frame;await advance(.25)
func native_key(value):await native("key",[value])
func native_click(button):
 check(button!=null,"native target exists")
 if button==null:return
 var at=root.get_final_transform()*button.get_global_rect().get_center();await native("motion",[str(roundi(at.x)),str(roundi(at.y))]);await native("click",[str(roundi(at.x)),str(roundi(at.y))]);await advance(.4)
func native_world(point,press=true):
 var at=root.get_final_transform()*game.world_to_screen(point)
 if press:await native("motion",[str(roundi(at.x)),str(roundi(at.y))])
 await native("click" if press else "motion",[str(roundi(at.x)),str(roundi(at.y))])
func native_buy(kind,point):
 await native_click(game.ui.room_selected_summary);await native_click(game.ui.actions["build:"+kind]);await native_world(point,false);await advance(.8);await native_world(point);await advance(.4)
func run():
 output="/workspace/freedom-to-build/";phase="video";root.size=Vector2i(1280,720);await setup_game();game.onboarding.close_welcome();game.return_menu();await advance(.4)
 var layer=CanvasLayer.new();layer.layer=90;root.add_child(layer);caption=Label.new();caption.position=Vector2(355,78);caption.add_theme_font_size_override("font_size",14);caption.add_theme_color_override("font_shadow_color",Color.BLACK);caption.add_theme_constant_override("shadow_outline_size",4);caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(caption)
 caption.text="NATIVE INPUT DEMO · prepared temporary budget · Linux Godot 4.6.3"
 print("VIDEO_READY")
 while not FileAccess.file_exists("/tmp/spatial-record-go"):await process_frame
 pcm_start();started=Time.get_ticks_usec();await advance(1)
 await native_click(find_button("Endless Siege"));print("NATIVE_SCREEN ",game.ui.current_screen);await native_click(find_button("New Endless run"))
 if game.model.run_kind!="endless":push_error("Native input did not start Endless");quit(1);return
 var m=game.model;m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();m.bot_claimed=5
 for i in range(1,6):
  var other=m.rooms[i];other.owner=i;other.sleeping=true;other.closed=true;other.resident_position=other.bed_position();other.bot_timer=10000
 var r=m.player();r.gold=3000;r.electricity=700;r.bed_level=1;r.door_level=1;r.door_hp=r.max_hp();game.ui.show_match();game.focus_camera(true);await advance(1)
 tell("Prepared occupied room · 3000 Gold / 700 Electricity · real prices")
 await native_click(game.ui.room_selected_summary);await native_click(game.ui.actions["build:turret"])
 check(game.construction.active(),"first real native palette card starts preview")
 tell("Preview follows native mouse · optional 8-unit snap, F toggles")
 for point in [Vector2(175,151),Vector2(240,100),Vector2(300,170),Vector2(175,151)]:await native_world(point,false);await advance(.6)
 await native_world(Vector2(175,151));check(r.buildings.size()==1,"native off-pad purchase")
 tell("Invalid overlap: real click rejected, no resources deducted")
 await native_click(game.ui.room_selected_summary);await native_click(game.ui.actions["build:generator"]);await native_world(r.tile_position(16),false);await advance(1);var gold=r.gold;await native_world(r.tile_position(16));check(r.gold==gold and r.buildings.size()==1,"native invalid overlap transaction");await native_key("Escape")
 tell("Second purchase · another freely chosen location")
 await native_buy("heavy",Vector2(266,116));check(r.buildings.size()==2,"native second purchase")
 tell("Select same turret → Move [V] · no payment or cooldown reset")
 await native_world(r.tile_position(16));await native_click(game.construction.move_button);await native_world(Vector2(180,88),false);await advance(1);await native_world(Vector2(180,88));check(r.tile_position(16).distance_to(Vector2(180,88))<7,"native actual move")
 tell("Cancel a second move with Esc · original position retained")
 var position=r.tile_position(16);await native_world(position);await native_click(game.construction.move_button);await native_world(Vector2(300,160),false);await advance(1);await native_key("Escape");check(r.tile_position(16)==position,"native cancelled move unchanged")
 tell("Expansion pays existing 120 Gold / 15 Electricity · 3 → 6 capacity")
 await native_click(game.ui.room_selected_summary);await native_click(game.ui.expansion_ui.shortcut);await advance(1);await native_click(game.ui.expansion_ui.purchase_button);check(r.tile_count()==6,"native expansion real action");await advance(1)
 tell("Place on NEW floor · old boundary rejected this area")
 game.ui.close_context();await advance(.4);await native_buy("generator",Vector2(280,20));check(r.buildings.size()==3,"native new floor purchase")
 tell("Live combat · relocated turrets use their stored positions")
 var h=m.hunter;h.boss_policy.enabled=false;h.position=r.door_approach();h.target=0;h.state=HunterState.State.ATTACK;h.cooldown=1
 # Advance only through the ordinary preparation clock, no stat or HP reductions.
 var prep_start=Time.get_ticks_usec();var previous=prep_start
 while m.time<m.preparation+.05:
  await process_frame;var now=Time.get_ticks_usec();game._process((now-previous)/1e6);previous=now
 var combat_start=m.time;await live(9)
 check(r.shots>0 and m.hunter.hp<m.hunter.max_hp,"native layout fires and causes actual damage in live tick")
 tell("End of uncut native-input demonstration · no human playtest claim");await advance(1)
 pcm_finish("native-input-master")
 var f=FileAccess.open(output+"video/timeline.json",FileAccess.WRITE);f.store_string(JSON.stringify({"timeline":timeline,"seconds":(Time.get_ticks_usec()-started)/1e6,"checks":checks,"failures":failures,"combat_seconds":m.time-combat_start,"shots":r.shots,"hunter_hp":h.hp,"hunter_max_hp":h.max_hp,"buildings":r.buildings,"conditions":"Native XTest mouse/keyboard, scripted driver, actual production GUI transactions. Prepared isolated wallet/occupied room and Hunter contact, normal stats/prices. Frozen prep during build showcase, then ordinary wall-time Game._process; no edits/cuts."}," "))
 print("VIDEO_COMPLETE checks=",checks," failures=",failures);layer.queue_free();game.audio_system.shutdown();game.queue_free();await create_timer(.3).timeout;quit(1 if failures else 0)
