extends "res://tools/capture_phase5d4_core.gd"
func run():
 output="res://docs/evidence/phase5d4/";phase="core-render";await setup_game()
 var args=OS.get_cmdline_user_args();var mode=args[0] if args.size()>0 else "arrival"
 if mode=="team":
  await team()
 elif mode=="phase2":
  var m=boss_fixture();await transform(m);m.hunter.cooldown=60;m.hunter.hurt(m.hunter.hp-m.hunter.max_hp*.34);await drive(1.3);m.wrath.recovery=100
  check(m.wrath.phase==2,"actual own-room phaseII")
  for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
   root.size=resolution;game.focus_camera(true);await advance(.2);await capture("final-own-reaper-phase2-"+str(resolution.y))
 else:
  root.size=Vector2i(1280,720);var m=boss_fixture();var h=m.hunter;await transform(m)
  h.hurt(h.hp-h.max_hp*.34);await drive(.1);m.wrath.recovery=100;await drive(1.3)
  var test_seed=47
  while true:
   m.random.seed=test_seed;var state=m.random.state;var predicted=m.wrath.choose_room(m);m.random.state=state
   if predicted>0:break
   test_seed+=1
  h.hurt(h.hp-h.max_hp*.09);await drive(.1);var target=m.wrath.cast_target
  check(target>0 and target<6,"seeded threshold selects real NPC room")
  await drive(3.1);check(m.wrath.domain_active() and m.minions.is_empty(),"actual finalcombineddomain active")
  check(game.spectate_room(target),"actual teammate spectate accepts live NPCtarget")
  game.focus_camera(true)
  while m.wrath.domain_active() and m.wrath.domain_remaining>1 and h.position.distance_to(m.rooms[target].door_approach())>3:await drive(.25)
  check(m.wrath.domain_active() and h.position.distance_to(m.rooms[target].door_approach())<=3,"actual legalnavigation arrives forduel")
  var player_pos=m.player_position;var owner=m.player_room
  for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
   root.size=resolution;game.focus_camera(true);await advance(.2)
   await capture("final-npc-crimson-arrival-"+str(resolution.y))
   check(game.ui.teammates.home.visible,"ReturnHome remains visible")
   var projected=game.world_to_screen(h.position);mark("finalactualNPCduel",{"resolution":str(resolution),"room":target,"hunter_world":h.position,"hunter_screen_feet":projected,"distance_to_valid_door":h.position.distance_to(m.rooms[target].door_approach()),"home_rect":str(game.ui.teammates.home.get_global_rect())})
   await key(KEY_T);await advance(.1);await capture("final-npc-domain-team-expanded-"+str(resolution.y));check(game.ui.teammates.home.visible,"ReturnHome survives expanded roster");await key(KEY_T)
  await key(KEY_HOME);await advance(.3);check(game.watched_room<0 and m.player_room==owner and m.player_position==player_pos,"Home restorescamera withoutplayerteleport/ownershipchange")
 var f=FileAccess.open("res://docs/evidence/phase5d4/final-d-"+mode+"-result.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"cases":cases,"fixture":"Actualmodel/input. ControlledeligibleStage3Hell, realHPthresholds, seededNPCtarget andlegalHunterroute; no teleportingHunter intoNPCduel. Teamframes actualPracticefixtures acrossfive maps. NativeWindowsUNVERIFIED."}," "))
 print("PHASE5D4_FINAL_SCENE_",mode.to_upper(),"_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
