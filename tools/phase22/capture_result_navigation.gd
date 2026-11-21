extends "res://tools/phase20/capture_door_survival.gd"
## Terminal Story fixture: open and dismiss the real Timeline without paying the result twice.

var result_stats := {}

func capture_victory(model: MatchModel,room: RoomState):
 if OS.get_environment("NIGHTFALL_RESULT_FIXTURE") != "defeat":
  await super.capture_victory(model,room)
  return
 root.size = Vector2i(1280,720)
 game.change_setting("graphics_quality","medium")
 # The initial siege fixture is already alive and has paid for repair. The
 # definitive result must still come from a real Hunter attack and settlement.
 room.door_hp = 1
 model.hunter.state = HunterState.State.ATTACK
 model.hunter.position = room.door_approach()
 model.hunter.target = room.index
 model.hunter.cooldown = 0
 model.hunter.archetype_primed = true
 for i in range(1200):
  if model.result != "":break
  model.tick(.1)
 game._process(0.0)
 await process_frame
 check(model.result == "defeat" and game.ui.current_screen == "story_result", "Hunter attack generated the settled defeat")
 if model.result == "defeat":await image("07-defeat",root.size)

func image(label: String, dims: Vector2i):
 if label not in ["07-victory","07-defeat"]:return
 await super.image(label,dims)
 var baseline: Dictionary = game.profile._reward_snapshot()
 var open_samples: Array[float] = []
 var close_samples: Array[float] = []
 for i in range(8):
  var opener := find_action("Match timeline")
  if opener == null:break
  var elapsed: float = await release_to_present(opener)
  open_samples.append(elapsed)
  check(game.ui.current_screen == "match_timeline", "click enters the real timeline")
  if i==0:
   await super.image("08-timeline",dims)
   await send_key(KEY_ESCAPE)
  else:
   var back := expect_button("MatchTimelineBack",game.ui.panel)
   if back==null:break
   close_samples.append(await release_to_present(back))
  check(game.ui.current_screen == "story_result", "Back or Escape returns to the same result")
 check(game.profile._reward_snapshot() == baseline, "reopening results preserves settlement")
 result_stats = {"outcome":game.model.result,"size":[root.size.x,root.size.y],"open_ms":open_samples,"close_ms":close_samples,"checks":checks,"failures":failures}
 FileAccess.open(destination.path_join("navigation.json"),FileAccess.WRITE).store_string(JSON.stringify(result_stats,"  ")+"\n")

func find_action(caption: String) -> Button:
 for node in game.ui.panel.find_children("*","Button",true,false):
  if node.is_visible_in_tree() and node.text == caption:return node
 check(false, "result has a visible " + caption + " control")
 return null

func release_to_present(button: Button) -> float:
 var point := root.get_final_transform() * button.get_global_rect().get_center()
 var motion := InputEventMouseMotion.new()
 motion.position=point
 motion.global_position=point
 Input.parse_input_event(motion)
 await process_frame
 var started := 0
 for down: bool in [true,false]:
  var event := InputEventMouseButton.new()
  event.button_index = MOUSE_BUTTON_LEFT
  event.position = point
  event.global_position = point
  event.pressed = down
  started = Time.get_ticks_usec()
  Input.parse_input_event(event)
  await process_frame
 await RenderingServer.frame_post_draw
 return (Time.get_ticks_usec()-started)/1000.0
