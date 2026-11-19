extends "res://tools/visual_rebirth/capture_hunter_series.gd"
## Prepared live states exercise ability timers through the normal model tick.

func run() -> void:
 var args := OS.get_cmdline_user_args()
 if args.size()!=1 or not args[0].is_absolute_path():
  push_error("Pass an absolute evidence directory after --.")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 output=destination.get_base_dir()+"/"
 phase=destination.get_file()
 DirAccess.make_dir_recursive_absolute(destination)
 root.size=Vector2i(1280,720)
 await setup_game()
 game.onboarding.close_welcome()
 await _dash_fixture()
 await _ability_fixture("ravager","quills")
 await _ability_fixture("storm","gust")
 await _finish()

func _fresh(kind: String):
 game.new_balance_version=1
 game.return_menu()
 var seed_value := 66 + StrategyCatalog.ARCHETYPE_IDS.find(kind)
 check(game.start_endless("abandoned_dorm","standard",seed_value),"seeded " + kind)
 game.set_process(false)
 game.tutorial_enabled=false
 var model=game.model
 check(model.hunter.archetype==kind and model.claim_room(3),"selected actual " + kind)
 var room=model.player()
 model.player_position=room.bed_position()
 model.sleep_player()
 room.door_hp=room.max_hp()
 model.hunter.target=room.index
 model.hunter.arcane.cooldown=999
 model.time=model.preparation+.1
 model.evolution.evolution_level=7
 game.ui.show_match()
 game.focus_camera(true)
 game.presentation.identity.heading=Vector2.LEFT
 return model

func _dash_fixture():
 var model=_fresh("ravager")
 var hunter=model.hunter
 hunter.position=model.player().door_approach()+Vector2(145,-22)
 hunter.state=HunterState.State.MOVE
 hunter.tactical_cooldown=0.0
 var preview=game.presentation.nightmare_visual.ravager_preview
 var bound=false
 for frame in range(64):
  game._process(STEP)
  await _render_frame()
  if hunter.dash_remaining>0 and hunter.dash_remaining<1.11 and preview.pose_name=="dash":
   bound=true
   await capture("ravager-dash")
   break
 check(hunter.ability_counts.dash>0 and bound,"actual Ravager dash binds and renders pounce")

func _ability_fixture(kind: String, effect: String):
 var model=_fresh(kind)
 var hunter=model.hunter
 hunter.position=model.player().door_approach()
 hunter.state=HunterState.State.ATTACK
 hunter.nightmare.cooldown=0.0
 var renderer=game.presentation.nightmare_visual.get(kind+"_preview")
 var warning_bound=false
 var guard_bound=false
 for frame in range(115):
  game._process(STEP)
  await _render_frame()
  if hunter.nightmare.action==effect and renderer.pose_name=="tell":warning_bound=true
  if hunter.nightmare.effect==effect and hunter.nightmare.remaining<3.6 and renderer.pose_name=="guard":
   guard_bound=true
   await capture(kind+"-"+effect)
   break
 check(warning_bound and guard_bound and hunter.nightmare.casts.get(effect,0)>0,"actual %s %s binds tell and persistent stance" % [kind,effect])
