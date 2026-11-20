extends SceneTree
## Protect active controls and distinct urgent messages on the Phase 16 HUD.
var checks := 0
var failures := 0
var game

func _initialize():
 call_deferred("run")

func verify(ok: bool,label: String):
 checks+=1
 if not ok:
  failures+=1
  push_error("PHASE16 HUD: "+label)

func run():
 OS.set_environment("NIGHTFALL_PHASE16","1")
 OS.set_environment("NIGHTFALL_FULL_ROOM_GRID","1")
 OS.set_environment("NIGHTFALL_VISUAL_REBIRTH","1")
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://phase16-horror-hud.json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 preload("res://tests/onboarding_test_support.gd").skip(game)
 await process_frame

 var model:=MatchModel.new()
 verify(model.configure_endless("underground_lab","hell",67,1),"configured actual room fixture")
 model.configure_balance()
 verify(model.claim_room(0),"claimed room")
 model.player_position=model.player().bed_position()
 verify(model.sleep_player(),"closed real door")
 var ally: RoomState=model.rooms[2]
 ally.owner=1
 ally.closed=true
 ally.sleeping=true
 game._adopt_session(model)
 game.set_process(false)
 game.ui.open_build_menu()
 game.construction.machines_open=true
 game.construction.refresh()
 model.record_event("encounter",2)
 game.horror.update(.30,model)
 var cards: Array=game.horror.notification_placements(game.ui)
 verify(cards.size()==1 and cards[0].notification.key=="encounter:2","real nearby encounter reaches one card with panels open")
 verify(game.ui.context_open and game.construction.machine_list.visible,"machine finder and drawer are actually open")
 for card in cards:
  for reserved in game.horror.visible_hud(game.ui):
   verify(not card.box.intersects(reserved),"outlined card avoids each visible control and the drawer's resting area")
 verify(game.ui.horror_layer.mouse_filter==Control.MOUSE_FILTER_IGNORE,"notification layer cannot capture a click")

 model.hunter.state=HunterState.State.ATTACK
 model.hunter.target=0
 model.hunter.position=model.player().door_approach()
 game.ui.update_match()
 verify(game.ui.warning_box.visible,"own siege top warning is visible")
 model.record_event("encounter",0)
 game.horror.update(.30,model)
 cards=game.horror.notification_placements(game.ui)
 verify(game.horror.notifications.size()==2 and game.horror.observed_counts.encounter==2,"presentation observes both real encounters once")
 verify(cards.all(func(card):return card.notification.key!="encounter:0"),"duplicate own encounter stays out of the display")
 verify(cards.any(func(card):return card.notification.key=="encounter:2"),"distinct teammate encounter remains visible")

 ally.door_hp=0
 ally.alive=false
 model.record_event("door_break",2)
 model.record_event("elimination",2)
 game.horror.update(.3,model)
 cards=game.horror.notification_placements(game.ui)
 verify(cards.any(func(card):return card.loss and card.notification.key=="elimination:2"),"actual survivor loss replaces old remote warning")
 verify(game.horror.notifications.size()<=game.horror.MAX_ALERTS,"notification queue remains bounded")
 verify(game.horror.breaks.size()==1,"a genuine break queues one visual event")
 game.horror.update(7.0,model)
 verify(game.horror.breaks.is_empty() and game.horror.notification_placements(game.ui).is_empty(),"elapsed cue states expire without repeats")

 game.audio_system.shutdown()
 game.queue_free()
 await create_timer(.2).timeout
 print("PHASE16_HORROR_HUD_CHECKS=",checks," FAILURES=",failures)
 quit(int(failures>0))
