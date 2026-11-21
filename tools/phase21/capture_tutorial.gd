extends "res://tools/capture_living_tutorial.gd"

var wall_frames: Dictionary={}
var draw_calls: Dictionary={}
var update_calls: Dictionary={}
var prior_usec:=0

func sample_frame():
 var now:=Time.get_ticks_usec()
 if is_instance_valid(game) and is_instance_valid(game.onboarding) and game.tutorial_active and prior_usec>0:
  var stage:=str(game.onboarding.step)
  if not wall_frames.has(stage):
   wall_frames[stage]=[]
   draw_calls[stage]=[]
   update_calls[stage]=[]
  wall_frames[stage].append((now-prior_usec)/1000.0)
  draw_calls[stage].append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
  update_calls[stage].append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
 prior_usec=now

func run():
 var args:=OS.get_cmdline_user_args()
 record_walkthrough="record" in args
 output=args[0].trim_suffix("/")+"/"
 DirAccess.make_dir_recursive_absolute(output)
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://phase20-tutorial-test.json")
 game=load("res://scenes/main.tscn").instantiate()
 root.size=Vector2i(960,540) if args[1]=="low" else Vector2i(1280,720)
 root.add_child(game)
 process_frame.connect(sample_frame)
 await process_frame
 game.change_setting("graphics_quality",args[1])
 if record_walkthrough:await wait(.7)
 await key(KEY_SPACE)
 await click(game.onboarding.welcome_close)
 await click(game.ui.menu_start)
 practice=game.onboarding.course
 check(game.tutorial_active and practice!=null,"isolated quick practice")
 var before: Dictionary=game.profile._reward_snapshot()
 var room: RoomState=game.model.rooms[0]
 await lesson(Guide.Lesson.OBJECTIVE,"01-find-a-room")
 await click(practice.proceed)
 await move_to(room.door_approach())
 await move_to(room.door_position()-room.door_normal()*43.0)
 await lesson(Guide.Lesson.CLAIM_ROOM,"02-claim")
 await key(KEY_E)
 await lesson(Guide.Lesson.REACH_BED,"03-bed")
 await move_to(room.bed_position()+room.door_normal()*50.0)
 await key(KEY_E)
 await lesson(Guide.Lesson.OPEN_BUILD,"04-gold")
 check(room.income_total>0.0 and room.sleeping,"real Bed Gold")
 await click(game.ui.room_selected_summary)
 await lesson(Guide.Lesson.SELECT_DYNAMO,"05-dynamo")
 await click(game.ui.actions["build:generator"])
 await motion_to_current_cell()
 await lesson(Guide.Lesson.PLACE_DYNAMO,"05b-placement")
 await click_current_cell()
 await lesson(Guide.Lesson.CANCEL_PREVIEW,"06-paid-dynamo")
 check(room.buildings.has(practice.dynamo_id),"real Dynamo bought")
 await key(KEY_ESCAPE)
 await lesson(Guide.Lesson.REOPEN_BUILD,"07-next-lesson")
 await key(KEY_B)
 await lesson(Guide.Lesson.SELECT_NEEDLE,"08-needle")
 await click(game.ui.actions["build:turret"])
 await motion_to_current_cell()
 await lesson(Guide.Lesson.PLACE_NEEDLE,"08b-placement")
 await click_current_cell()
 await lesson(Guide.Lesson.COMPLETE,"09-complete",15.0)
 check(room.shots>0 and room.electricity>0.0,"actual projectile and electricity")
 check(no_permanent_changes(before),"no permanent economy changes")
 await click(practice.proceed)
 check(game.ui.current_screen=="story_prepare" and game.profile.tutorial_completed,"completion reopens Story")
 await capture("10-story-preparation")
 if record_walkthrough:await wait(1.0)
 var file:=FileAccess.open(output+"receipt.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":checks,"failures":failures,"lessons":lesson_trace,"transactions":practice.receipt,"wall_ms":wall_frames,"draw_calls":draw_calls,"process_monitor_ms":update_calls}))
 file.close()
 await finish()
