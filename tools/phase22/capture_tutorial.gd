extends "res://tools/phase21/capture_tutorial.gd"
## Keep the same three-lesson route, transactions and wall-time sampler as Phase 21.

func capture(name):
 if "no-readback" not in OS.get_cmdline_user_args():
  await super.capture(name)
  return
 game.queue_redraw()
 game.onboarding.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw

func lesson(step: int, name: String, seconds: float = 7.0):
 await super.lesson(step, name, seconds)
 if step not in [Guide.Lesson.SELECT_DYNAMO, Guide.Lesson.SELECT_NEEDLE]:
  return
 var expected := "generator" if step == Guide.Lesson.SELECT_DYNAMO else "turret"
 var visible_cards: Array[String] = []
 for entry in game.ui.actions:
  if str(entry).begins_with("build:"):
   var card: Button = game.ui.actions[entry]
   if card.is_visible_in_tree():
    visible_cards.append(str(entry).trim_prefix("build:"))
 check(visible_cards == [expected], "lesson offers exactly the required machine")
 check(button_is_highlighted(game.ui.actions["build:" + expected]), "lesson targets the actual machine control")
