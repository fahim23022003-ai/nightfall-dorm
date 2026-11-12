extends "res://tools/capture_phase5d4_early.gd"
var rows=[]
func hover(button):
 var motion=InputEventMouseMotion.new();motion.position=root.get_final_transform()*button.get_global_rect().get_center();motion.global_position=motion.position;Input.parse_input_event(motion);await create_timer(.7).timeout
func run():
 output="res://docs/evidence/phase5d4/";phase="early-render";await setup_game()
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  for kind in ["turret","heavy","generator","repair","economy","enhancer","bed","door"]:
   var m=prepared();var r=m.player()
   if kind in ["bed","door"]:
    await click(game.ui.room_bed_summary if kind=="bed" else game.ui.room_door_summary);await advance(.1);await click(game.ui.actions[kind])
   else:
    var tile=m.practice_tile
    if kind!="turret":
     tile=0;check(r.build(kind,tile),"actual paid "+kind)
     for level in range(3):check(r.upgrade_building(tile),"actual paid level "+kind)
    await world_click(r.tile_position(tile));await advance(.15);await click(game.ui.actions.upgrade)
   await advance(.15)
   var cards=[game.ui.specialization_items[1],game.ui.specialization_items[2]];var back=game.ui.specialization_items[3];var confirm=game.ui.branch_confirm;var close
   for node in game.ui.context_box.get_children():
    if node is Button and node.text=="×":close=node
   for card in cards:
    check(not card.get_global_rect().intersects(close.get_global_rect()) and not card.get_global_rect().intersects(back.get_global_rect()) and not card.get_global_rect().intersects(confirm.get_global_rect()),"branch/card/close/action clearance "+kind+suffix)
    check(card.size.y>=card.get_combined_minimum_size().y,"branch text fits its target "+kind+suffix)
   rows.append({"kind":kind,"resolution":suffix,"card_a":str(cards[0].get_global_rect()),"card_b":str(cards[1].get_global_rect()),"close":str(close.get_global_rect()),"back":str(back.get_global_rect()),"confirm":str(confirm.get_global_rect()),"tooltip":cards[1].tooltip_text})
   await capture(kind+"-choices-"+suffix)
   var gold=r.gold;var power=r.electricity;await click(cards[0]);await advance(.1)
   check(r.gold==gold and r.electricity==power and game.ui.pending_branch!="","exclusive selection previews without charge "+kind)
   await capture(kind+"-selected-before-confirm-"+suffix)
   await hover(cards[1]);await capture(kind+"-branch-tooltip-"+suffix)
  var m=prepared();m.player().gold=0;m.player().electricity=0
  await world_click(m.player().tile_position(0));await advance(.2)
  check(game.ui.actions["build:heavy"].disabled and game.ui.actions["build:heavy"].tooltip_text.contains("Need"),"disabled price has actual reason")
  await hover(game.ui.actions["build:heavy"]);await capture("build-insufficient-reason-"+suffix)
 var f=FileAccess.open("res://docs/evidence/phase5d4/early-render-clarity-result.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"fixture":"Real input. Paid Practice setup; branch preview holds actual funds. Zero-funds disabled state deliberately configured for reason visibility."}," "))
 print("PHASE5D4_EARLY_CLARITY_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
