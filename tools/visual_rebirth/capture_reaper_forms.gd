extends "res://tools/capture_visual_rebirth.gd"
## Prepared room and authoritative Hunter tick to exercise both preview forms.

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 1 or not args[0].is_absolute_path():
  push_error("Pass an absolute capture directory after --")
  quit(2)
  return
 var destination := args[0]
 output = destination.get_base_dir() + "/"
 phase = destination.get_file()
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280,720)
 await setup_game()
 game.onboarding.close_welcome()
 var model = _dense_fixture()
 var hunter = model.hunter
 hunter.configure_encounter("stage_5")
 hunter.boss_policy = BossCatalog.encounter("stage_5","hell")
 check(hunter.boss_policy.get("enabled",false) and not hunter.transformed,"prepared authoritative boss encounter")
 hunter.state = HunterState.State.ATTACK
 hunter.target = model.player_room
 model.running = true
 for index in range(8):
  game.presentation.update(.125,model)
  await _render_frame()
 await capture("reaper-approach-720")
 var art = game.presentation.boss_presentation
 var pilot := OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"
 check(art.preview_textures.has("approach") == pilot,"expected approach form reached production draw")
 model.time = model.preparation + float(hunter.boss_policy.deadline) + 1.0
 var hp: float = hunter.hp
 hunter.tick(.01,model)
 check(hunter.state==HunterState.State.TRANSFORM and hunter.transformed and hunter.hp<=hp,"actual transformation starts without healing")
 hunter.tick(.75,model)
 game.presentation.update(.75,model)
 await _render_frame()
 await capture("reaper-transform-720")
 hunter.tick(BossCatalog.TRANSFORM_SECONDS,model)
 check(hunter.state!=HunterState.State.TRANSFORM,"actual transformation completes")
 hunter.state = HunterState.State.ATTACK
 hunter.target = model.player_room
 var before_hp: float = model.player().door_hp
 hunter.cooldown = 0.0
 hunter.tick(.01,model)
 check(hunter.boss_attack!="" and model.player().door_hp==before_hp,"actual boss warning comes before damage")
 game.presentation.update(.01,model)
 await _render_frame()
 await capture("reaper-awakened-tell-720")
 check(art.preview_textures.has("transformed") == pilot,"expected transformed form reached production draw")
 print("REAPER_TRANSFORM_HP=",hunter.hp," BOSS_ATTACK=",hunter.boss_attack," DOOR_HP=",model.player().door_hp)
 await _finish()
