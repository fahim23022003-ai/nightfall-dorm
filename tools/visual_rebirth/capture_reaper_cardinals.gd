extends "res://tools/capture_visual_rebirth.gd"
## Review both dedicated Reaper forms at each authored cardinal heading.

const HEADINGS := {"front": Vector2.DOWN, "left": Vector2.LEFT, "back": Vector2.UP, "right": Vector2.RIGHT}
const CROP_SIZE := Vector2i(224, 164)
const CROP_OFFSET := Vector2i(-112, -121)

func run():
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
 var model=_dense_fixture()
 var hunter=model.hunter
 hunter.boss_policy=BossCatalog.encounter("stage_5","hell")
 check(hunter.boss_policy.get("enabled",false),"existing boss encounter enabled")
 game.ui.update_match()
 await _render_frame()
 var center := Vector2i(root.get_final_transform()*game.world_to_screen(hunter.position))
 var region := Rect2i(center+CROP_OFFSET,CROP_SIZE)
 var bindings := {}
 for form in ["approach","transformed"]:
  if form=="transformed":
   model.time=model.preparation+float(hunter.boss_policy.deadline)+STEP
   hunter.tick(STEP,model)
   check(hunter.transformed and hunter.state==HunterState.State.TRANSFORM,"normal deadline enters the second form")
   hunter.tick(BossCatalog.TRANSFORM_SECONDS+STEP,model)
   check(hunter.state!=HunterState.State.TRANSFORM,"second form settled after normal animation timer")
   hunter.state=HunterState.State.ATTACK
   hunter.target=model.player_room
   game.ui.update_match()
  for direction in HEADINGS:
   game.presentation.identity.heading=HEADINGS[direction]
   await _render_frame()
   var stem: String=form+"_"+direction
   var source: String=game.presentation.boss_presentation.preview_texture_path
   check(source.get_file()==stem+".png","exact %s art reached canvas" % stem)
   var frame := root.get_texture().get_image()
   check(frame.get_size()==Vector2i(1280,720),"native Reaper frame at 720p")
   check(Rect2i(Vector2i.ZERO,frame.get_size()).encloses(region),"unscaled crop is inside native viewport")
   check(frame.get_region(region).save_png(destination.path_join(stem+".png"))==OK,"save exact native crop")
   bindings[stem]=source
 var json := FileAccess.open(destination.path_join("reaper-cardinals.json"),FileAccess.WRITE)
 check(json!=null,"cardinal capture metadata opens")
 if json!=null:
  json.store_string(JSON.stringify({"fixture":"Prepared 16-slot room with staged headings. Existing HunterState transform timer reveals the second form. Unscaled crops from a native Godot viewport.","viewport":[1280,720],"crop":[region.position.x,region.position.y,CROP_SIZE.x,CROP_SIZE.y],"bindings":bindings},"  ")+"\n")
 print("REAPER_CARDINALS=",bindings.size())
 await _finish()
