extends SceneTree
## Draw the production building renderer in an isolated 1280×720 viewport.
## Activity values are deliberately staged, with live-model checks run separately.

const BuildingVisual = preload("res://scripts/building_evolution_visual.gd")
const SIZE := Vector2i(1280,720)
const MOTION_FRAMES := 8
const HEADINGS := 12

class Board extends Node2D:
 var visual = BuildingVisual.new()
 var states: Array = []
 var kind: String
 var activity: float
 var clock: float
 var direction := Vector2.RIGHT
 var profile := {"settings":{"graphics_quality":"medium","reduced_motion":false}}

 func anchor(index: int) -> Vector2:
  return Vector2(74 + (index % 11) * 113, 177 + floori(index / 11.0) * 231)

 func _draw():
  draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE)), Color("25292C"))
  var font := ThemeDB.fallback_font
  draw_string(font,Vector2(31,44),Catalog.BUILDINGS.get(kind,{}).get("name",kind.capitalize()),HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("E4DBC9"))
  for index in range(states.size()):
   var state: Array = states[index]
   var point := anchor(index)
   visual.draw(self,null,kind,state[0],point,state[1],activity,direction,clock)
   draw_string(font,point + Vector2(-24,32),"L%02d" % int(state[0]),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("D4CFBE"))
   var branch: String = state[1]
   if not branch.is_empty():
    draw_string(font,point + Vector2(-51,52),StrategyCatalog.BRANCHES[branch].name,HORIZONTAL_ALIGNMENT_CENTER,104,10,Color("B9AC98"))

var failures := 0
var board: Board
var output: String

func _initialize():
 call_deferred("_run")

func _run():
 var args := OS.get_cmdline_user_args()
 if args.size()!=1 or not args[0].is_absolute_path() or DisplayServer.get_name()=="headless" or OS.get_environment("NIGHTFALL_VISUAL_REBIRTH")!="1":
  push_error("Use a real display, NIGHTFALL_VISUAL_REBIRTH=1 and one absolute output directory.")
  quit(2)
  return
 output=args[0]
 DirAccess.make_dir_recursive_absolute(output)
 root.size=SIZE
 board=Board.new()
 root.add_child(board)
 var summaries := {}
 var totals := {"baseline":0,"specializations":0,"moving_states":0,"static_states":0,"staged_variation_checks":0,"reduced_motion_checks":0}
 for kind: String in BuildingVisual.KINDS:
  var branches: Array = StrategyCatalog.branches(kind)
  var moving := BuildingVisual.SUPPORT_BRANCHES.has(kind)
  var aimed: bool = BuildingVisual.WEAPON_BRANCHES.has(kind) and kind!="frost"
  var is_static := BuildingVisual.STATIC_BRANCHES.has(kind)
  var expected_branches: Array = BuildingVisual.SUPPORT_BRANCHES.get(kind,BuildingVisual.WEAPON_BRANCHES.get(kind,BuildingVisual.STATIC_BRANCHES.get(kind,[])))
  _check(branches == expected_branches,kind + " branch row ordering")
  var stage: int = 6 if kind in ["bed","door"] else 5
  var expected: Array = []
  for level in range(1,11):expected.append([level,""])
  for branch in branches:
   for level in range(stage,11):expected.append([level,branch])
  _check(expected.size()==(20 if stage==6 else 22),kind + " state count")
  for index in range(expected.size()):
   var state: Array = expected[index]
   _check(board.visual.rebirth_state(state[0],state[1],branches,stage)==index,kind+" state "+str(state))
  _check(board.visual.load_rebirth_atlas(kind,"motion" if moving else "launcher" if aimed else ""),kind+" live atlas load")
  board.kind=kind
  board.states=expected
  var idle: Image = await _render(0.0,0.0,Vector2.RIGHT,false)
  _check(idle.get_size()==SIZE,kind + " 1280×720 viewport")
  var signatures := _signatures(idle)
  var distinct := {}
  for signature in signatures:distinct[signature]=true
  _check(distinct.size()==expected.size(),kind+" all idle states visually distinct")
  _check(idle.save_png(output.path_join(kind+"-idle.png"))==OK,kind+" save idle plate")
  var variation_samples := HEADINGS if aimed else MOTION_FRAMES-1 if moving else 1
  var poses: Array = []
  for idle_signature in signatures:poses.append({idle_signature:true})
  var changed := 0
  for frame in range(variation_samples):
   var activity := 0.15
   var sample_clock := 0.0
   var target := Vector2.RIGHT
   if moving:
    var phase := frame+1
    if kind=="shock":
     activity=(phase-.5)*.15/7.0
    else:
     activity=1.0
     sample_clock=(phase+.5)/BuildingVisual.SUPPORT_CLOCK_RATES[kind]
   elif aimed:
    var angle := frame*TAU/HEADINGS
    target=Vector2(cos(angle),-sin(angle)/sqrt(2.0))
   var active: Image = await _render(activity,sample_clock,target,false)
   var active_signatures := _signatures(active)
   for index in range(expected.size()):
    poses[index][active_signatures[index]]=true
    _check((active_signatures[index]!=signatures[index])!=is_static,kind+" activity frame "+str(frame)+" state "+str(index))
    if active_signatures[index]!=signatures[index]:changed+=1
   if frame==0 and not is_static:
    _check(active.save_png(output.path_join(kind+"-active.png"))==OK,kind+" save active plate")
  var reduced_checks := 0
  if moving:
   var reduced_clock: float = 0.0 if kind=="shock" else 2.5/BuildingVisual.SUPPORT_CLOCK_RATES[kind]
   var reduced: Image = await _render(.15,reduced_clock,Vector2.RIGHT,true)
   var reduced_signatures := _signatures(reduced)
   for index in range(expected.size()):
    _check(reduced_signatures[index]==signatures[index],kind+" reduced motion rests at initial state "+str(index))
    reduced_checks+=1
  var min_poses := variation_samples + 1
  for pose_set in poses:min_poses=mini(min_poses,pose_set.size())
  # One-pixel motion can render identically in two support frames on a given
  # state. Require actual variation rather than imposing atlas-cell uniqueness.
  _check(min_poses>1 if not is_static else min_poses==1,kind+" minimum rendered pose variation")
  totals.baseline+=10
  totals.specializations+=expected.size()-10
  if is_static:totals.static_states+=expected.size()
  else:totals.moving_states+=expected.size()
  totals.staged_variation_checks+=expected.size()*variation_samples
  totals.reduced_motion_checks+=reduced_checks
  summaries[kind]={"baseline":10,"specializations":expected.size()-10,"distinct_idle_states":distinct.size(),"staged_pose_samples_per_state":variation_samples+1,"minimum_unique_rendered_poses":min_poses,"changed_sample_count":changed,"reduced_motion_checks":reduced_checks}
 _check(totals.baseline==170 and totals.specializations==200,"catalog totals")
 _check(totals.moving_states==286 and totals.static_states==84,"motion route totals")
 var room := RoomState.new()
 var repair := {"kind":"auto_repair","level":1,"cooldown":2.95}
 room.sleeping=true
 _check(board.visual.support_activity(room,repair)>0.0,"occupied recent Auto Repair remains active")
 room.sleeping=false
 _check(board.visual.support_activity(room,repair)==0.0,"waking stops recent Auto Repair visual even with frozen cooldown")
 var result := {"viewport":[SIZE.x,SIZE.y],"building_families":summaries.size(),"totals":totals,"families":summaries,"failures":failures,"staging":"Isolated production CanvasItem renderer; positions and activity staged. No matches simulated."}
 var receipt := FileAccess.open(output.path_join("building-animation-audit.json"),FileAccess.WRITE)
 if receipt!=null:receipt.store_string(JSON.stringify(result,"  ")+"\n")
 _check(receipt!=null,"write JSON report")
 print("BUILDING_ANIMATION_AUDIT ", JSON.stringify(totals), " FAILURES=",failures)
 quit(1 if failures else 0)

func _render(activity: float,clock: float,target: Vector2,reduced: bool) -> Image:
 board.activity=activity
 board.clock=clock
 board.direction=target
 board.profile.settings.reduced_motion=reduced
 board.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 return root.get_texture().get_image()

func _signatures(frame: Image) -> Array[String]:
 var signatures: Array[String] = []
 for index in range(board.states.size()):
  var area := Rect2i(Vector2i(board.anchor(index))+Vector2i(-53,-76),Vector2i(106,98))
  signatures.append(frame.get_region(area).get_data().hex_encode().sha256_text())
 return signatures

func _check(ok: bool,description: String):
 if ok:return
 failures+=1
 push_error(description)
