extends SceneTree
# Isolated render/input fixtures; not human pacing, native Windows or natural-earned-stock evidence.
var game
var checks=0
var failures=0
var output="res://docs/evidence/onboarding/"
var recording
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("ONBOARDING RENDER: "+label)
func wait(seconds):await create_timer(seconds).timeout
func until_elapsed(target):
 while game.onboarding.phase=="cinematic" and game.onboarding.elapsed<target:await process_frame
func capture(name):
 game.queue_redraw();game.onboarding.queue_redraw()
 await process_frame;await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output+name+".png"))==OK,"saved "+name)
 print("ONBOARDING_CAPTURE ",name," PHASE=",game.onboarding.phase," STEP=",game.onboarding.step)
func find_button(text,node=null):
 if node==null:node=game
 for c in node.get_children():
  if c is Button and c.text==text and c.is_visible_in_tree() and not c.is_queued_for_deletion():return c
  var found=find_button(text,c)
  if found!=null:return found
 return null
func click_point(point):
 for pressed in [true,false]:
  var e=InputEventMouseButton.new();e.position=point;e.global_position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;Input.parse_input_event(e)
  await process_frame
func click(button):
 check(button!=null,"button exists")
 if button==null:return
 await click_point(root.get_final_transform()*button.get_global_rect().get_center())
func key_down(code,pressed):
 var e=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=pressed;Input.parse_input_event(e)
func key(code):
 key_down(code,true);await process_frame;key_down(code,false);await process_frame
func move_to(goal):
 var path=game.model.player_navigation_path(game.model.player_position,goal)
 check(not path.is_empty(),"actual reachable movement path")
 for point in path:
  var deadline=Time.get_ticks_msec()+5000
  while game.model.player_position.distance_to(point)>5 and Time.get_ticks_msec()<deadline:
   var difference=point-game.model.player_position
   key_down(KEY_D,difference.x>3);key_down(KEY_A,difference.x< -3)
   key_down(KEY_S,difference.y>3);key_down(KEY_W,difference.y< -3)
   await process_frame
  for code in [KEY_D,KEY_A,KEY_W,KEY_S]:key_down(code,false)
 check(game.model.player_position.distance_to(goal)<12,"physical movement reaches destination")
func step_at_least(value,seconds=5.0):
 var deadline=Time.get_ticks_msec()+int(seconds*1000)
 while game.onboarding.step<value and Time.get_ticks_msec()<deadline:await process_frame
 check(game.onboarding.step>=value,"tutorial step "+str(value+1))
func world_click(point):await click_point(root.get_final_transform()*(game.get_canvas_transform()*(point+game.MAP_OFFSET)))
func build(kind,tile):
 await world_click(game.model.player().tile_position(tile))
 await click(game.ui.actions.get("build:"+kind))
 await click(find_button("Confirm placement"))
 await wait(.1)
func run():
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://onboarding-render-"+str(Time.get_ticks_usec())+".json")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 root.size=Vector2i(1280,720)
 recording=AudioEffectRecord.new();AudioServer.add_bus_effect(0,recording);recording.set_recording_active(true)
 check(game.mode=="intro" and not game.profile.tutorial_completed,"real fresh launch begins cinematic")
 await until_elapsed(1);await capture("render-01-chase")
 var first_position=game.onboarding.elapsed
 await until_elapsed(3);await capture("render-02-moving-chase")
 check(game.onboarding.elapsed>first_position+1.5,"cinematic actually progresses")
 await until_elapsed(5);await capture("render-03-hunter-reveal")
 await until_elapsed(8.7);await capture("render-04-dorm-approach")
 await until_elapsed(10.2);await capture("render-05-entering-dorm")
 await until_elapsed(10.82);await capture("render-06-door-impact")
 check(game.onboarding.elapsed<11.1,"captured actual impact counter window")
 await until_elapsed(13.3);await capture("render-07-darkness")
 await until_elapsed(15)
 while game.onboarding.phase=="title" and game.onboarding.elapsed<1.5:await process_frame
 await capture("render-08-welcome-credit-story")
 check(game.onboarding.phase=="title","15-second cinematic reaches title")
 root.size=Vector2i(960,540);await capture("render-09-title-small");root.size=Vector2i(1280,720)
 var auto_deadline=Time.get_ticks_msec()+5000
 while game.onboarding.phase=="title" and Time.get_ticks_msec()<auto_deadline:await process_frame
 check(game.tutorial_active and game.model.tutorial_mode,"unskipped opening automatically reaches mandatory real tutorial")
 var baseline=game.profile._reward_snapshot()
 await capture("render-10-tutorial-move")
 var m=game.model;var room=m.rooms[0]
 await move_to(room.door_approach());await step_at_least(1)
 await capture("render-11-tutorial-room")
 await move_to(room.door_position()-room.door_normal()*45)
 await key(KEY_E);await step_at_least(2)
 await capture("render-12-tutorial-bed")
 root.size=Vector2i(960,540);await capture("render-12a-tutorial-bed-small");root.size=Vector2i(1280,720)
 await move_to(room.bed_position()+Vector2(0,48));await key(KEY_E);await step_at_least(3)
 check(m.player()!=null and m.player().sleeping,"actual E sleeps")
 await capture("render-13-tutorial-gold")
 await step_at_least(4,5);check(m.player().income_total>=3,"actual bed Gold generation")
 await capture("render-14-tutorial-dynamo")
 var tiles=[]
 for tile in range(room.tile_count()):tiles.append(tile)
 tiles.sort_custom(func(a,b):return room.tile_position(a).distance_to(room.door_position())<room.tile_position(b).distance_to(room.door_position()))
 await build("generator",tiles[1]);await step_at_least(5,5)
 check(room.electricity>0,"actual Dynamo electricity")
 await capture("render-15-tutorial-turret")
 await build("turret",tiles[0]);await step_at_least(6)
 await capture("render-16-tutorial-upgrade-repair")
 await world_click(room.tile_position(tiles[0]));await click(game.ui.actions.upgrade)
 await key(KEY_R);await step_at_least(7)
 check(room.buildings[tiles[0]].level>=2 and room.repair_actions>0,"real upgrade and repair")
 await capture("render-17-tutorial-simple-threat")
 await step_at_least(8,35)
 check(m.hunter.attacks>0 and room.shots>0,"actual door hit and turret shots observed")
 await capture("render-18-tutorial-complete")
 check(game.profile.xp==baseline.xp and game.profile.rm_cash==baseline.rm_cash and game.profile.inventory==baseline.inventory and game.profile.pending_spins==baseline.pending_spins and game.profile.active_match==baseline.active_match,"tutorial no persistent rewards/consumption/active match")
 await click(find_button("Save completion & enter menu"));await wait(.2)
 check(game.profile.tutorial_completed and game.mode=="menu","actual completion saves and enters menu")
 var reload=PlayerProfile.new(game.profile.path);check(reload.load_profile() and reload.tutorial_completed,"completion survives reload")
 await capture("render-19-returning-menu")
 await click(find_button("Replay Tutorial"));await wait(.1)
 check(game.tutorial_active,"actual replay option")
 await click(find_button("Exit practice"));check(game.mode=="menu" and game.onboarding.phase=="idle","replay exits without reintro")
 game.return_menu();check(game.onboarding.phase=="idle","menu return does not replay intro")
 game.profile.rm_cash=100;check(game.profile.save_profile(),"explicit shop fixture budget saves")
 await click(find_button("Shop · Common supplies"));await capture("render-20-common-shop")
 root.size=Vector2i(960,540);await capture("render-21-shop-small");root.size=Vector2i(1280,720)
 var stock=int(game.profile.inventory.get("repair",0));var serial=game.profile.purchase_serial
 var button=find_button("Buy · 18 RM Cash");var point=button.get_global_rect().get_center()
 await click(button);await click_point(point)
 check(game.profile.rm_cash==82 and int(game.profile.inventory.get("repair",0))==stock+1 and game.profile.purchase_serial==serial+1,"actual doubleclick buys exactly once")
 await capture("render-22-shop-purchase")
 reload=PlayerProfile.new(game.profile.path);check(reload.load_profile() and reload.rm_cash==82 and int(reload.inventory.get("repair",0))==stock+1,"shop stock/cash durable")
 await wait(.5);game.profile.rm_cash=0;game.profile.save_profile();game.ui.shop.show_shop()
 check(find_button("Buy · 18 RM Cash").disabled,"insufficient funds disables purchase")
 await capture("render-23-shop-insufficient")
 await wait(.5)
 game.profile.rm_cash=30;game.profile.save_profile();var safe_path=game.profile.path;game.profile.path+="/missing.json";game.ui.shop.show_shop()
 var failed_stock=game.profile.inventory.duplicate(true);var failed_serial=game.profile.purchase_serial
 await click(find_button("Buy · 16 RM Cash"))
 check(game.profile.rm_cash==30 and game.profile.inventory==failed_stock and game.profile.purchase_serial==failed_serial,"actual failed-save shop transaction rolls back")
 await capture("render-23a-shop-save-failure")
 game.profile.path=safe_path
 await click(find_button("Back to main menu"))
 game.profile.update_setting("reduced_effects",true);game.onboarding.show_opening();await wait(4.35)
 await capture("render-24-reduced-flash-cinematic")
 await key(KEY_SPACE);await wait(.1)
 check(game.mode=="menu" and game.onboarding.phase=="idle","actual keyboard skip safe for returning player")
 check(game.audio_system.get_diagnostics().event_counts.get("intro_running",0)>0,"actual intro event plays")
 recording.set_recording_active(false)
 var stream=recording.get_recording();check(stream!=null and stream.data.size()>100,"real engine audio captured")
 if stream!=null:check(stream.save_to_wav(ProjectSettings.globalize_path(output+"render-onboarding-mix.wav"))==OK,"master audio saved")
 print("ONBOARDING_RENDER_AUDIO=",JSON.stringify(game.audio_system.get_diagnostics()))
 game.audio_system.shutdown();await wait(.5);game.queue_free();await process_frame
 print("ONBOARDING_RENDER_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
