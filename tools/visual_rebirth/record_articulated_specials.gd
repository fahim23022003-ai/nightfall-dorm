extends "res://tools/visual_rebirth/capture_hunter_anchor_combat.gd"
## Movie Maker records these staged, full production match ticks and live audio.

func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=1 or not args[0].is_absolute_path():
  push_error("Pass an absolute receipt path after --.")
  quit(2)
  return
 root.size=Vector2i(1280,720)
 await setup_game()
 game.onboarding.close_welcome()
 game.audio_system.set_mix({"music_mode":"classic","music":.45,"effects":.85,"ambient":.35})
 var evidence:=[]
 for pair in [["stalker",10],["ravager",7],["crusher",1],["witch",1],["electric",1],["storm",1]]:
  var archetype: String=pair[0]
  var level: int=pair[1]
  var model: MatchModel=_setup_anchor_combat(archetype,level)
  var hunter:=model.hunter
  var room:=model.player()
  hunter.position=room.door_approach()
  hunter.state=HunterState.State.ATTACK
  model.bot_claimed=5
  hunter.cooldown=.3
  if level>1:
   hunter.nightmare.cooldown=0.0
   if level==10:model.evolution.final_revealed=false
  elif archetype=="crusher":
   hunter.tactical_cooldown=0.0
  else:
   hunter.arcane.cooldown=0.0
  var checked: Dictionary={}
  var poses: Dictionary={}
  var valid_hit:=false
  var door_damage_sfx_before:=int(game.audio_system.event_counts.get("door_hit",0))
  for tick in range(216 if level==10 else 144):
   game._process(STEP)
   await RenderingServer.frame_post_draw
   await process_frame
   var rig=game.presentation.nightmare_visual.articulated
   if not rig.pose_name.is_empty():poses[rig.pose_name]=true
   for event in model.presentation_events:
    if event.room!=room.index:continue
    if event.type in ["nightmare_rebirth","nightmare_warning","nightmare_release","hunter_ability_warning","hunter_ability","arcane_impact"]:
     checked[event.type]=event.get("ability",event.get("skill",""))
    if event.type=="door_damage" and event.get("damage",0)>0:
     valid_hit=true
  check(poses.has("cast") and poses.has("cast_release"),"cast and release pose drawn for "+archetype)
  if level==10:check(poses.has("evolve") and checked.has("nightmare_rebirth"),"real L10 rebirth bound on canvas")
  check(checked.has("nightmare_release") if level>1 else checked.has("hunter_ability"),"actual model special released for "+archetype)
  check(valid_hit and int(game.audio_system.event_counts.get("door_hit",0))>door_damage_sfx_before,"real damage and routed door SFX for "+archetype)
  evidence.append({"archetype":archetype,"level":level,"events":checked,"poses":poses.keys(),"door_hit":valid_hit})
 var receipt:=FileAccess.open(args[0],FileAccess.WRITE)
 if receipt!=null:
  receipt.store_string(JSON.stringify({"fixtures":evidence,"fps":24,"failures":failures},"  ")+"\n")
  receipt.close()
 output=args[0].get_base_dir()+"/"
 await _finish()
