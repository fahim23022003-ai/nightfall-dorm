extends "res://scripts/living_tutorial.gd"
## Three teaching goals on the existing disposable, fixed-map practice model.

const NEXT := {
 Lesson.OBJECTIVE:Lesson.MOVE, Lesson.MOVE:Lesson.FIND_ROOM,
 Lesson.FIND_ROOM:Lesson.CLAIM_ROOM, Lesson.CLAIM_ROOM:Lesson.REACH_BED,
 Lesson.REACH_BED:Lesson.SLEEP, Lesson.SLEEP:Lesson.OPEN_BUILD,
 Lesson.OPEN_BUILD:Lesson.SELECT_DYNAMO, Lesson.SELECT_DYNAMO:Lesson.PLACE_DYNAMO,
 Lesson.PLACE_DYNAMO:Lesson.CANCEL_PREVIEW, Lesson.CANCEL_PREVIEW:Lesson.REOPEN_BUILD,
 Lesson.REOPEN_BUILD:Lesson.SELECT_NEEDLE, Lesson.SELECT_NEEDLE:Lesson.PLACE_NEEDLE,
 Lesson.PLACE_NEEDLE:Lesson.HUNTER_DANGER, Lesson.HUNTER_DANGER:Lesson.COMPLETE,
}
var shown_target:=Rect2()

func begin():
 super.begin()
 var help:=button("Open Help",Vector2(16,187),Vector2(130,32),game.toggle_guide)
 help.name="quick_tutorial_help"
 card.size.y=231
 if game.ui.use_tactical_ui():
  card.position=Vector2(22,89)
  card.add_theme_stylebox_override("panel",GothicTheme.living_surface("frame"))
  heading_label.add_theme_font_size_override("font_size",24)
  message_label.add_theme_font_size_override("font_size",18)
  for control in [proceed,repeat,recover_button,exit_button,help]:
   game.ui.theme_button(control,"primary" if control==proceed else "quiet")
 help.hide()
 refresh()

func refresh():
 super.refresh()
 var chapter:=1 if stage in [Lesson.OBJECTIVE,Lesson.MOVE,Lesson.FIND_ROOM,Lesson.CLAIM_ROOM,Lesson.REACH_BED,Lesson.SLEEP] else 2 if stage in [Lesson.OPEN_BUILD,Lesson.SELECT_DYNAMO,Lesson.PLACE_DYNAMO] else 3
 position_label.text="LESSON %d / 3" % chapter
 heading_label.text=["Find a room","Build electricity","Build a turret"][chapter-1]
 match stage:
  Lesson.OBJECTIVE:message_label.text="Move into a vacant room, claim it, then reach its bed."
  Lesson.CANCEL_PREVIEW:message_label.text="The Dynamo makes Electricity. Choose Cancel or press Esc."
  Lesson.HUNTER_DANGER:message_label.text="The Needle fires when a Hunter reaches its range. Watch the shot travel."
  Lesson.COMPLETE:
   heading_label.text="You are ready to survive."
   message_label.text="Your practice is complete. Continue to Story or replay."
   var help=card.get_node_or_null("quick_tutorial_help")
   if help!=null:help.show()

func advance():
 if not NEXT.has(stage):return
 # The base advance applies model hooks and clears cached placement guidance.
 stage=int(NEXT[stage])-1
 super.advance()

func note_placement_cancelled(kind: String):
 if stage==Lesson.CANCEL_PREVIEW and kind=="generator":
  receipt.append({"event":"explicit_placement_cancel","kind":kind})
  advance()
 else:super.note_placement_cancelled(kind)

func focus_target() -> Rect2:
 if stage!=Lesson.CANCEL_PREVIEW:
  return super.focus_target()
 if game.construction.kind=="generator":
  return button_rect(game.ui.grid_placement_cancel_button)
 return build_selector_or_toolbar(game.ui,"generator")

func update_cue():
 var target:=focus_target()
 if target.is_equal_approx(shown_target):return
 shown_target=target
 var left:=Vector2(22,89)
 var right:=Vector2(930,89)
 if Rect2(left,card.size).intersects(target) and not Rect2(right,card.size).intersects(target):
  card.position=right
 else:card.position=left
 overlay.queue_redraw()

func draw():
 if not game.ui.use_tactical_ui():
  super.draw()
  return
 if shown_target.has_area() and Rect2(Vector2.ZERO,overlay.size).encloses(shown_target):
  overlay.draw_rect(shown_target.grow(5),Color("FFE0A0"),false,3.0)

func tick_danger(model,room):
 if not danger_started:
  super.tick_danger(model,room)
  return
 if room!=null and room.shots>danger_shots_before and model.hunter.hp<model.hunter.max_hp:
  receipt.append({"event":"practice_projectile","shots":room.shots-danger_shots_before})
  advance()
