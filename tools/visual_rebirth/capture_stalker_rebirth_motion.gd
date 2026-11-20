extends "res://tools/visual_rebirth/capture_hunter_anchor_combat.gd"
## Observe the original L10 reveal trigger and the exact art swap in motion.

func run():
 var args := OS.get_cmdline_user_args()
 if args.size()!=1 or not args[0].is_absolute_path():
  push_error("Pass an absolute evidence directory after --.")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 output=destination.get_base_dir()+"/"
 phase=destination.get_file()
 var frames := destination.path_join("frames")
 DirAccess.make_dir_recursive_absolute(frames)
 root.size=Vector2i(1280,720)
 await setup_game()
 game.onboarding.close_welcome()

 var model=_setup_anchor_combat("stalker",10)
 var hunter=model.hunter
 var door: Vector2=model.player().door_approach()
 hunter.position=door+Vector2(0,-38)
 model.evolution.final_revealed=false
 game.presentation.identity.reset()
 game.presentation.nightmare_visual.reset()
 game.presentation.update(STEP,model)
 var renderer=game.presentation.nightmare_visual.stalker_preview

 # The pending state is visible before activating the normal match timer.
 for hold in range(8):
  await _record(frames,model,"stalker",10)
 check(renderer.active_level==9,"pending reveal uses existing level 9 prior to trigger")
 var event_frame := -1
 var swap_frame := -1
 var finish_frame := -1
 var saw_morph := false
 for tick in range(125):
  game._process(STEP)
  await _record(frames,model,"stalker",10)
  if event_frame<0:
   for event in model.presentation_events:
    if event.type=="nightmare_rebirth":
     event_frame=frame_number-1
  if swap_frame<0 and renderer.active_level==10:
   swap_frame=frame_number-1
  if renderer.pose_name=="evolve":saw_morph=true
  if event_frame>=0 and finish_frame<0 and model.evolution.rebirth_remaining<=0:
   finish_frame=frame_number-1
  if finish_frame>=0 and frame_number>finish_frame+14:
   break
 check(event_frame>=0 and model.evolution.final_revealed,"normal model emits and completes the existing reveal")
 check(swap_frame>event_frame and finish_frame>swap_frame and saw_morph,"level 10 swaps during existing evolution animation")
 check(missing_view_frames==0,"no legacy frame interrupted the progression")
 var metadata := FileAccess.open(destination.path_join("rebirth-motion.json"),FileAccess.WRITE)
 check(metadata!=null,"write reveal evidence metadata")
 if metadata!=null:
  metadata.store_string(JSON.stringify({
   "fps":24,"viewport":[1280,720],"frame_count":frame_number,
   "fixture":"Prepared seeded Endless near the player door, with level 10 ready and final_revealed false. No level was earned during this setup. Normal MatchModel ticks trigger the existing reveal.",
   "rebirth_frame":event_frame, "art_swap_frame":swap_frame, "finish_frame":finish_frame,
   "textures":observed_textures, "frames":frame_records,
  },"  ")+"\n")
 print("STALKER_REBIRTH_FRAMES=",frame_number," REBIRTH=",event_frame," ART_SWAP=",swap_frame," FINISH=",finish_frame)
 await _finish()
