extends SceneTree

var checks:=0
var failures:=0

func _initialize() -> void:
 run.call_deferred()

func check(ok: bool, name: String):
 checks+=1
 if not ok:
  failures+=1
  push_error(name)

func run() -> void:
 var model:=MatchModel.new()
 model.player_first_requested=true
 model.reset(44)
 check(model.configure_stage("stage_1") and model.configure_strategy(44,"stalker") and model.configure_balance(),"stage")
 check(model.claim_room(0),"claim")
 var room:=model.player()
 model.player_position=room.bed_position()
 check(model.sleep_player(),"bed")
 room.door_level=9
 room.door_hp=room.max_hp()
 room.gold=1000.0
 var hunter:=model.hunter
 hunter.hp=1000.0
 hunter.target=0
 hunter.position=room.door_approach()
 hunter.state=HunterState.State.ATTACK
 model.time=model.preparation+1
 check(PlayerDoorSurvival.under_siege(model,room),"active main siege")
 check(is_equal_approx(PlayerDoorSurvival.armor(9),.22) and PlayerDoorSurvival.armor(0)==0.0,"bounded level armor")
 model.player_first_requested=false
 var unarmored:=model.apply_room_damage(0,100.0,"door strike")
 var magic_unarmored:=model.apply_room_damage(0,100.0,"curse")
 model.player_first_requested=true
 room.door_hp=room.max_hp()
 var actual:=model.apply_room_damage(0,100.0,"door strike")
 check(unarmored>0.0 and is_equal_approx(actual,unarmored*.78),"physical reduced by 22 percent")
 actual=model.apply_room_damage(0,100.0,"curse")
 check(magic_unarmored>0.0 and is_equal_approx(actual,magic_unarmored),"magic bypasses armor")
 room.door_hp=room.max_hp()-200.0
 var earned: float=room.income_total
 var ordinary: float=room.income_rate()/room.temporary_income
 room.fear_bed_multiplier=1.5
 room.tick_economy(1.0)
 check(is_equal_approx(room.income_total-earned,ordinary*1.5),"exact Bed Gold multiplier")
 var prior:=float(room.gold)
 var price:=model.door_survival.price(room)
 check(model.repair_door() and is_equal_approx(room.gold,prior-price),"pay once to activate")
 var activation:=float(model.time)
 check(not model.repair_door() and is_equal_approx(room.gold,prior-price),"no stacking or repeat debit")
 check(is_equal_approx(model.door_survival.ready_at,activation+60.0),"activation starts 60s cooldown")
 var hp: float=room.door_hp
 model.door_survival.tick(10.0,model,room)
 check(is_equal_approx(model.door_survival.remaining,15.0) and is_equal_approx(room.door_hp-hp,56.0),"gradual delivery")
 model.door_survival.tick(15.0,model,room)
 check(model.door_survival.remaining==0.0 and is_equal_approx(room.door_hp-hp,140.0),"25s bounded healing")
 check(not model.repair_door(),"cooldown holds after healing")
 model.time=activation+60.0
 check(model.repair_door(),"reactivates at cooldown boundary")
 room.door_hp=0.0
 model.door_survival.tick(1.0,model,room)
 check(room.door_hp==0.0 and model.door_survival.remaining==0.0,"broken door is not revived")
 check(model.chronicle.entries.any(func(entry):return entry.name=="Room claimed"),"actual claim is on timeline")
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://phase20-help-test.json")
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.onboarding.skip()
 game.onboarding.close_welcome()
 game._adopt_session(model)
 model.running=true
 game.open_pausing_help()
 var frozen: float=model.time
 game._process(.25)
 check(game.phase20_help_open and not model.running and model.time==frozen,"Help freezes actual match model")
 game.close_pausing_help()
 check(model.running and not game.phase20_help_open,"Help preserves previous running state")
 game.phase20_adapt(.016)
 check(not game.phase20_trim,"fast frames do not trim")
 for index in range(120):game.phase20_adapt(.05)
 check(game.phase20_trim,"sustained slow frames enable optional trim")
 for index in range(120):game.phase20_adapt(.016)
 check(game.phase20_trim,"does not raise quality mid-match")
 var position: Vector2=model.player_position
 var drag:=InputEventMouseMotion.new()
 drag.button_mask=MOUSE_BUTTON_MASK_MIDDLE
 drag.relative=Vector2(100,30)
 check(game._phase20_camera_input(drag) and game.phase20_free_camera and model.player_position==position,"middle drag is camera only")
 game.return_to_my_room()
 check(not game.phase20_free_camera,"Home re-locks camera")
 game.audio_system.shutdown()
 await create_timer(.35).timeout
 game.queue_free()
 await process_frame
 print("PLAYER_FIRST_CHECKS=",checks," FAILURES=",failures)
 quit(int(failures>0))
