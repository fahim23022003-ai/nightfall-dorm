extends "res://tools/capture_onboarding.gd"
## Staged rooms and funds in a disposable profile. Damage and repair use live rules.

var map_scores: Dictionary={}

func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=2 or args[1] not in ["960","1280"] or DisplayServer.get_name()=="headless":
  quit(2)
  return
 output=args[0].trim_suffix("/")+"/"
 DirAccess.make_dir_recursive_absolute(output)
 root.size=Vector2i(960,540) if args[1]=="960" else Vector2i(1280,720)
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://phase19-capture.json")
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.onboarding.skip()
 game.onboarding.close_welcome()
 game.profile.complete_tutorial()
 game.change_setting("graphics_quality","low" if args[1]=="960" else "medium")
 game.return_menu()
 game.ui.show_settings()
 await capture("settings")
 game.ui.shop.show_shop()
 await capture("shop")
 game.ui.items_ui.inventory()
 await capture("inventory")
 var model:=MatchModel.new()
 model.reset(10358)
 check(model.configure_stage("stage_2") and model.configure_strategy(10358,"stalker") and model.configure_balance(),"real themed Campaign model")
 game.profile.inventory.gold=2
 game.profile.item_loadout=["gold"]
 var receipt: Dictionary=game.profile.begin_match("standard","stage_1")
 check(not receipt.is_empty(),"disposable match item wallet")
 game.match_id=receipt.id
 game._adopt_session(model)
 game.set_process(false)
 var room: RoomState=model.rooms[1]
 model.player_position=room.door_position()-room.door_normal()*36
 check(model.claim_room(1),"real room claim")
 model.player_position=room.bed_position()
 check(model.sleep_player(),"real room occupancy")
 room.gold=300.0
 game.focus_camera(true)
 game.ui.update_match()
 check(game.ui.living_dorm_hud!=null and game.ui.living_dorm_hud.meter.visible,"always-visible meter on claimed room")
 await capture("door-healthy")
 var hunter:=model.hunter
 hunter.target=room.index
 hunter.state=HunterState.State.ATTACK
 hunter.position=room.door_approach()
 model.time=model.preparation+12
 var damaged:=model.apply_room_damage(room.index,room.door_hp*.98,"door strike")
 check(damaged>0.0,"actual door damage event")
 game.ui.update_match()
 check(game.ui.living_dorm_hud.band==2,"critical danger color")
 await capture("door-critical")
 var before_repair: float=room.door_hp
 await click(game.ui.quick_repair)
 check(room.door_hp>before_repair and room.repair_actions==1,"real Repair button recovered actual HP")
 check(game.ui.living_dorm_hud.repair_message.begins_with("+"+WeaponFeedback.format_damage(room.door_hp-before_repair)),"repair feedback matches transaction")
 await capture("door-repaired")
 await click(game.ui.items_ui.item_toggle)
 check(game.ui.items_ui.expanded,"one Items button opens drawer")
 var before_quantity: int=game.profile.inventory.gold
 await click(game.ui.items_ui.hotbar[0])
 check(game.profile.inventory.gold==before_quantity and game.ui.items_ui.inspected_slot==0,"selecting only inspects")
 await capture("item-details")
 await click(game.ui.items_ui.drawer_use)
 check(game.profile.inventory.gold==before_quantity-1,"explicit Use consumes one unit")
 await click(game.ui.items_ui.item_toggle)
 await click(game.ui.living_dorm_hud.traits_button)
 check(game.ui.living_dorm_hud.traits.visible,"room effects expand")
 await capture("room-effects")
 if args[1]=="960":
  await record_scores()
 await finish()

func record_scores():
 var recorder:=AudioEffectRecord.new()
 AudioServer.add_bus_effect(0,recorder)
 var bus_index:=AudioServer.get_bus_effect_count(0)-1
 for stage in ["stage_1","stage_2","stage_3","stage_4","stage_5"]:
  var model:=MatchModel.new()
  model.configure_stage(stage)
  var theme: String=model.map_data.theme
  recorder.set_recording_active(true)
  for frame in range(80):
   game.audio_system.update_state(.05,model,"match")
   await create_timer(.05).timeout
  var started: String=game.audio_system._active_score
  recorder.set_recording_active(false)
  var sound:=recorder.get_recording()
  check(started!="" and not map_scores.values().has(started),"different actual score for "+theme)
  map_scores[theme]=started
  if sound!=null and sound.data.size()>0:
   check(sound.save_to_wav(output+theme+".wav")==OK,"recorded actual engine audio for "+theme)
  else:
   check(false,"no audio frames recorded for "+theme)
 AudioServer.remove_bus_effect(0,bus_index)
 var score_receipt:=FileAccess.open(output+"music.json",FileAccess.WRITE)
 score_receipt.store_string(JSON.stringify(map_scores,"  ")+"\n")

func finish():
 game.audio_system.shutdown()
 await create_timer(.3).timeout
 game.queue_free()
 await create_timer(.2).timeout
 print("LIVING_DORM_RENDER_CHECKS=",checks," FAILURES=",failures)
 quit(int(failures>0))
