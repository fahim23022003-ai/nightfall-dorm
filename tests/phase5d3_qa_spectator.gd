extends "res://tests/premium_strategy_ui.gd"
const Support=preload("res://tests/replay_test_support.gd")
func key(code):
 for pressed in [true,false]:
  var e=InputEventKey.new();e.keycode=code;e.pressed=pressed;Input.parse_input_event(e);await process_frame
 await settle()
func world_click(point):
 var position=root.get_final_transform()*game.world_to_screen(point)
 for down in [true,false]:
  var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=position;e.global_position=position;e.pressed=down;Input.parse_input_event(e);await process_frame
func setup_team():
 var m=game.model;var owners=[0,2,4,1,5,3]
 for i in range(1,6):
  var r=m.rooms[i];r.owner=owners[i];r.alive=true;r.sleeping=true;r.closed=true;r.resident_position=r.bed_position();r.door_hp=r.max_hp()
 m.bot_claimed=5;m.hunter.boss_policy.enabled=false;m.hunter.target=0;m.hunter.state=HunterState.State.ATTACK;m.hunter.position=m.player().door_approach();m.hunter.cooldown=100
 game.ui.update_match();game.audio_system.update_state(.1,m,game.mode)
func run():
 profile_path="user://phase5d3-qa-spectator-"+str(Time.get_ticks_usec())+".json"
 var p=PlayerProfile.new(profile_path);p.tutorial_completed=true;check(p.save_profile(),"isolated returningprofile saves")
 OS.set_environment("NIGHTFALL_PROFILE_PATH",profile_path)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.onboarding.set_process(false);game.onboarding.skip();game.onboarding.close_welcome();await settle()
 var permanent=Support.profile_signature(game.profile);var bytes=FileAccess.get_file_as_bytes(profile_path)
 for map in MapCatalog.IDS:
  game.ui.replay_ui.practice_map=map
  check(game.start_practice("crusher",false,["repair","shield"],map),"actual realcombatPractice fixturestarts "+map)
  await settle();setup_team();var m=game.model;var ui=game.ui.teammates
  if not ui.expanded:await click(ui.toggle)
  screen("live teammate HUD "+map)
  check(ui.body.visible and ui.indices==[1,2,3,4,5] and ui.toggle.text.contains("5/5"),"rosterusesactualroomowners/livecount")
  for i in range(5):
   var r=m.rooms[i+1]
   check(ui.rows[i].text.contains(r.survivor_name()) and ui.rows[i].text.contains("Room %02d" % [r.index+1]) and ui.rows[i].text.contains("Door %d/%d" % [roundi(r.door_hp),roundi(r.max_hp())]),"actualnames/rooms/healthmapcorrectlywhenownerindicesdiffer")
  var stable=Support.model_signature(m)
  for i in range(5):
   await click(ui.rows[i]);await settle()
   for step in range(70):game.focus_camera(false,.016)
   check(game.watched_room==i+1 and (ui.watching.text.contains(m.rooms[i+1].survivor_name()) or ui.watching.text.contains("YOUR DOOR IS UNDER ATTACK")),"actualrowclickspectatescorrectteammate whileownwarninghaspriority")
   check(Support.model_signature(m)==stable,"camera+rowclicknevermutatesmodelposition/ownership/resources/stock")
   check(game.camera.position.distance_to(game.camera_target)<1 and is_finite(game.camera.zoom.x) and game.camera.zoom.x>0,"camera convergessmoothlywithvalidzoom on "+map)
   var r=m.rooms[i+1];var top=game.world_to_screen(r.bounds().position);var bottom=game.world_to_screen(r.bounds().end)
   check(top.x>=0 and top.y>=70 and bottom.x<=1280 and bottom.y<=640,"wholeobservedroomfitslivegameplay viewport")
  await key(KEY_PAGEUP);check(game.watched_room==4,"PageUpcyclesvalidrooms")
  await key(KEY_PAGEDOWN);check(game.watched_room==5,"PageDowncyclesvalidrooms")
  await key(KEY_HOME);check(game.watched_room==-1 and not ui.home.visible and game.camera.position.distance_to(game.camera_target)<.01,"Home instantlyrestoresownview")
  await click(ui.rows[0]);await settle();var target=game.watched_room
  stable=Support.model_signature(m)
  # Hide the actual roster before clicking the world; on narrow maps its
  # overlay legitimately occupies the projected first tile.
  await click(ui.toggle)
  await world_click(m.rooms[target].tile_position(0))
  game.begin_placement("generator");game.confirm_placement();await key(KEY_E)
  check(game.pending_build=="" and not game.ui.context_open and Support.model_signature(m)==stable,"spectatedworldclick/build/confirm/Ecannotcontrolforeignorownstructures")
  check(game.ui.room_bed_summary.disabled and game.ui.room_door_summary.disabled and game.ui.room_selected_summary.disabled,"watchingdisablesallowneditinspectors")
  game.ui.update_match();game.audio_system.update_state(.1,m,game.mode)
  check(ui.watching.text.contains("YOUR DOOR IS UNDER ATTACK") and ui.home.visible,"ownroomdangerremainsprominentwhilewatching")
  check(game.audio_system.listener_position==m.player().bed_position(),"listenerstaysatownbeddespitespectatorcamera")
  m.player().door_hp=m.player().max_hp()-100;var hp=m.player().door_hp;var gold=m.player().gold
  await key(KEY_R)
  check(m.player().door_hp>hp and m.player().gold<gold and game.watched_room==target,"actualRrepairprotectsownroomwithoutleavingspectator")
  var stock=game.item_wallet().inventory.repair;hp=m.player().door_hp;await key(KEY_1)
  check(game.item_wallet().inventory.repair==stock-1 and m.player().door_hp>hp,"actualitemhotkeyconsumesonlytemporaryownstockandhealsownroom")
  var time=m.time;var attacks=m.hunter.attacks;m.hunter.cooldown=0
  for step in range(20):game._process(.1)
  check(m.time>time and m.hunter.attacks>attacks and game.watched_room==target,"spectatingdoesnotpauseactualHunterattacks/modelticks")
  # Awake movement is blocked only while spectating, not merely by sleeping.
  m.player().sleeping=false;m.player().closed=false;m.player_position=m.player().center();var position=m.player_position
  var movement=InputEventKey.new();movement.keycode=KEY_W;movement.physical_keycode=KEY_W;movement.pressed=true;Input.parse_input_event(movement);await process_frame;check(Input.is_physical_key_pressed(KEY_W),"actualphysicalWheldduringawakeobservation");game._process(.1)
  movement=InputEventKey.new();movement.keycode=KEY_W;movement.physical_keycode=KEY_W;movement.pressed=false;Input.parse_input_event(movement);await process_frame
  await key(KEY_E)
  check(m.player_position==position and not m.player().sleeping,"spectatorcannotwalkorclaimthroughawakeplayercontrols")
  await click(ui.home);await settle()
  var home_position=m.player_position
  movement=InputEventKey.new();movement.keycode=KEY_W;movement.physical_keycode=KEY_W;movement.pressed=true;Input.parse_input_event(movement);await process_frame;game._process(.1)
  movement=InputEventKey.new();movement.keycode=KEY_W;movement.physical_keycode=KEY_W;movement.pressed=false;Input.parse_input_event(movement);await process_frame
  check(m.player_position.distance_to(home_position)>0,"samephysicalmovementworksagainafterReturn")
  m.player_position=m.player().bed_position()+Vector2(35,0);await key(KEY_E)
  check(game.watched_room==-1 and m.player().sleeping,"obviousReturnbuttonrestoresordinaryownEcontrols")
  # Let the real breach/contact controller eliminate the observed teammate.
  if not ui.expanded:await click(ui.toggle)
  await click(ui.rows[0]);await settle();var eliminated=m.eliminations
  var r=m.rooms[1];r.door_hp=0;m.hunter.target=1;m.hunter.state=HunterState.State.BREACH;m.hunter.position=r.bed_position()+Vector2(20,0)
  for step in range(4):game._process(.1)
  game.ui.update_match()
  check(not r.alive and m.eliminations==eliminated+1 and ui.rows[0].text.contains("DEAD") and ui.toggle.text.contains("4/5"),"realteammateeliminationupdatesactualrowandlivecountonce")
  check(game.watched_room==1 and ui.watching.text.contains("ELIMINATED") and m.result=="","observedteammatedeathkeepsvalidcameraandongoingmatch")
  for n in range(3):ui.update()
  check(m.eliminations==eliminated+1,"HUDupdatesneverduplicatedeathalerts/count")
  check(not game.spectate_room(-1) and not game.spectate_room(6) and not game.spectate_room(m.player_room),"invalid/ownroomcamera requestsfailwithoutownershipchange")
  await key(KEY_T);check(not ui.body.visible and ui.home.visible,"collapsingrosterdoesnothidereturn/dangerawareness")
  await key(KEY_T);check(ui.body.visible,"Trestorescompactactualroster")
  var own=m.player();own.door_hp=0;m.hunter.target=0;m.hunter.state=HunterState.State.BREACH;m.hunter.position=own.bed_position()+Vector2(20,0)
  for step in range(4):game._process(.1)
  check(m.result=="defeat" and game.mode=="result" and not game.spectate_room(2),"actualowndeathrespectsnormalterminalrulesratherthancontinuingspectator")
  game.reset_practice();await settle()
  check(game.watched_room==-1 and game.mode=="match" and game.model.map_id==map,"resetstartsvalidfreshcameraandcontrols")
  game.return_menu();await settle()
  check(Support.profile_signature(game.profile)==permanent and FileAccess.get_file_as_bytes(profile_path)==bytes,"allcamera/combat/death/resetactionsleavepermanentprofileunchanged")
 # Actual intermission Prepare→spectate→Wave→Continue must clear observation.
 var oldpath=profile_path;profile_path="user://phase5d3-qa-spectator-endless-"+str(Time.get_ticks_usec())+".json"
 DirAccess.copy_absolute("res://docs/evidence/phase5d3/qa-pre5d3-endless-profile.json",profile_path)
 var q=PlayerProfile.new(profile_path);q.load_profile();q.tutorial_completed=true;game.profile=q
 check(game.resume_endless(),"actuallegacypaidcheckpointresumesinGame")
 await click(find("Prepare defenses · frozen economy"));await settle()
 game.ui.teammates.expanded=false;game.ui.teammates.update();await click(game.ui.teammates.toggle);await settle();await click(game.ui.teammates.rows[0]);await settle()
 check(game.watched_room>=0,"actualfrozenpreparationallowsobservationwithoutincome")
 await click(game.ui.pause_button);await settle();await click(find("Continue · Reinforce"));await settle()
 check(game.watched_room==-1 and game.model.endless.wave==5 and game.mode=="match","realwaveContinuerebindsowncameraandcontrols")
 print("PHASE5D3_SPECTATOR_QA_CHECKS=",checks," MAPS=5 FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout
 Support.cleanup(oldpath);Support.cleanup(profile_path);quit(1 if failures else 0)
