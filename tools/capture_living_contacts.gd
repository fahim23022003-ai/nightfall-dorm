extends "res://tools/capture_hell_tactics.gd"
## Native 720p contact capture. The fixture starts at a legal door approach.

const CONTACT_STEP := 1.0 / 30.0
const CONTACT_FAMILIES := ["crusher","stalker","ravager","witch","electric","storm","reaper"]

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 2 or args[1] not in ["low","medium"]:
  quit(2)
  return
 directory=args[0]
 DirAccess.make_dir_recursive_absolute(directory)
 root.size=Vector2i(1280,720)
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://living-contact-capture.json")
 OS.set_environment("NIGHTFALL_VISUAL_REBIRTH","1")
 OS.set_environment("NIGHTFALL_LIVING_NIGHTMARE","1")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 await process_frame
 preload("res://tests/onboarding_test_support.gd").skip(game)
 game.onboarding.set_process(false)
 game.change_setting("graphics_quality",args[1])
 var fixtures := {}
 for family: String in CONTACT_FAMILIES:
  var model := make_contact_fixture(family)
  game._adopt_session(model)
  game.set_process(false)
  game.full_map=false
  game.focus_camera(true)
  var result := await record_contact(family,model)
  verify(not result.is_empty(),family+" confirms contact with positive production damage")
  fixtures[family]=result
 var output:=FileAccess.open(directory.path_join("contacts.json"),FileAccess.WRITE)
 output.store_string(JSON.stringify({"graphics":args[1],"fixtures":fixtures,"errors":errors},"  ")+"\n")
 output.close()
 game.presentation.reset()
 game.audio_system.shutdown()
 game.queue_free()
 await process_frame
 await process_frame
 print("LIVING_CONTACT_CAPTURE_FAILURES=",errors.size())
 quit(int(not errors.is_empty()))

func make_contact_fixture(family: String) -> MatchModel:
 var model := MatchModel.new()
 model.procedural_v2_requested=true
 model.reset(10358)
 var boss := family=="reaper"
 model.configure_match("hard" if boss else "standard")
 model.configure_stage("stage_5" if boss else "stage_1")
 model.configure_strategy(10358,"crusher" if boss else family)
 model.configure_balance()
 model.claim_room(1)
 var room:=model.player()
 model.player_position=room.bed_position()
 model.sleep_player()
 model.bot_claimed=5
 model.time=model.preparation+5.0
 var hunter:=model.hunter
 hunter.position=room.door_approach()
 hunter.target=room.index
 hunter.state=HunterState.State.ATTACK
 hunter.cooldown=.15
 hunter.arcane.cooldown=20.0
 if boss:
  hunter.transformed=true
  hunter.boss_cooldowns.surge=20.0
  hunter.boss_cooldowns.siege=20.0
 return model

func record_contact(family: String,model: MatchModel) -> Dictionary:
 var contact := {}
 var finished := -1
 for frame in range(82):
  game._process(CONTACT_STEP)
  var sample: Dictionary=game.presentation.hunter_combat.latest_body_contact(model)
  if not sample.is_empty() and contact.is_empty():
   var event := get_event(model,"door_damage",model.player_room)
   verify(event.id==sample.id and event.damage>0.0 and absf(event.time-model.time)<.0001,"impact is visible on the exact landed event")
   contact={
    "frame":frame, "time":event.time, "damage":event.damage, "hp":event.hp, "source":event.source,
    "style":sample.style, "material":sample.material, "socket":arr(sample.point), "origin":arr(sample.origin),
    "evolution_level":model.evolution.evolution_level, "stage":model.stage_id,
   }
   finished=frame+16
  await record_frame(family,frame)
  if not contact.is_empty() and frame==int(contact.frame):
   var tip: Vector2=game.presentation.boss_presentation.articulated_contact() if model.hunter.transformed else game.presentation.nightmare_visual.articulated_contact()
   if tip.is_finite():
    var socket:=Vector2(float(contact.socket[0]),float(contact.socket[1]))
    contact["rig_tip_distance"]=tip.distance_to(socket+HunterCombatVisual.OFFSET)
   await image(family+"-contact")
  if frame==finished:
   break
 return contact
