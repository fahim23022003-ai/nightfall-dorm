extends SceneTree

var checks:=0
var failures:=0
var events: Array[Dictionary]=[]

func _initialize() -> void:
 call_deferred("run")

func check(condition: bool, label: String) -> void:
 checks+=1
 if not condition:
  failures+=1
  push_error(label)

func run() -> void:
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.profile.complete_tutorial()
 game.onboarding.skip()
 game.onboarding.close_welcome()
 check(game.model.weapon_feedback.enabled and game.story_preview_enabled and game.survivor_preview_enabled,"Preview uses the expected launcher flags")
 check(ResourceLoader.exists("res://scripts/weapon_presentation.gd"),"Weapon renderer is in the embedded PCK")
 game.ui.show_settings()
 var option: OptionButton=game.ui.panel.find_child("damage_numbers",true,false)
 check(option!=null and option.item_count==4 and option.selected==0,"Default On and all four options are present in the packed scene")
 var model:=MatchModel.new()
 var sink:=func(event: Dictionary):events.append(event)
 model.weapon_feedback.received.connect(sink)
 check(model.claim_room(0),"Claim model room")
 var room:=model.player()
 model.player_position=room.bed_position()
 check(model.sleep_player() and room._purchase_building("turret",0),"Buy a real Needle with original rules")
 model.hunter.position=room.tile_position(0)+Vector2(100,0)
 model.hunter.state=HunterState.State.MOVE
 var hp: float=model.hunter.hp
 model._turrets(.05)
 check(model.projectiles.size()==1 and events.size()==1,"Physical model projectile and visual launch receipt")
 model._advance_projectiles(.05)
 check(model.projectiles.size()==1 and model.hunter.hp==hp,"Projectile travels before damage")
 model._advance_projectiles(.45)
 if events.size()==2:
  var hit:=events[1]
  check(hit.damage==hp-model.hunter.hp and hit.damage>0 and hit.projectile_id==events[0].projectile_id,"Exact paid damage reaches the packed presentation feed")
  check(model.weapon_feedback.machine(room,0).last_damage==hit.damage,"Packed inspector uses the same amount")
 else:check(false,"A launch and one matching impact")
 model.weapon_feedback.received.disconnect(sink)
 room=null
 model=null
 game.return_menu()
 game.audio_system.shutdown()
 await create_timer(.5).timeout
 game.queue_free()
 await create_timer(.2).timeout
 print("WEAPON_FEEDBACK_PACK_CHECKS=",checks," FAILURES=",failures," NATIVE_WINDOWS=UNVERIFIED")
 quit(int(failures>0))
