extends "res://tools/capture_visual_rebirth.gd"
## Prepared legacy Endless render fixture with real paid Arc upgrades and combat.

class Gallery extends Node2D:
 var profile

const FONT := preload("res://assets/fonts/Interface.ttf")
const UPGRADE_STILLS := [4, 5, 7, 10]

func run():
 var args := OS.get_cmdline_user_args()
 if args.size() != 1 or not args[0].is_absolute_path():
  push_error("Pass an absolute evidence directory after --")
  quit(2)
  return
 var destination := args[0].trim_suffix("/")
 phase = destination.get_file()
 output = destination.get_base_dir() + "/"
 DirAccess.make_dir_recursive_absolute(destination)
 root.size = Vector2i(1280, 720)
 await setup_game()
 game.onboarding.close_welcome()
 var model = _fresh_room(0)
 var room = model.player()
 for branch in ["focus", "storm"]:
  check(model.place_building("heavy", candidate(room)), "paid " + branch + " Arc construction")
 var ids: Array = room.buildings.keys()
 for level in range(2, 11):
  for index in range(ids.size()):
   var id: int = ids[index]
   var old_gold: float = room.gold
   var branch := "focus" if index == 0 else "storm"
   var succeeded: bool
   if level == 5:
    succeeded = model.specialize_building(id, branch)
    check(room.buildings[id].specialization == branch, branch + " persists")
   else:
    succeeded = model.upgrade_building(id)
   check(succeeded and room.gold < old_gold, "paid %s L%d" % [branch, level])
  if level in UPGRADE_STILLS:
   _pose_if_needed(model)
   model.running = false
   for iteration in range(8):
    game.presentation.update(.125, model)
    await _render_frame()
   await capture("paid-upgrade-l%d" % level)
   model.running = true
 var layer := CanvasLayer.new()
 layer.layer = 100
 root.add_child(layer)
 var sheet := Gallery.new()
 sheet.profile = game.profile
 layer.add_child(sheet)
 sheet.draw.connect(_draw_sheet.bind(sheet))
 sheet.queue_redraw()
 await capture("arc-production-renderer-matrix")
 layer.queue_free()
 await _render_frame()
 await _capture_launch(destination)
 await _finish()

func _capture_launch(destination: String):
 var combat = _combat_fixture()
 var player = combat.player()
 var needle: int = player.buildings.keys()[0]
 var origin: Vector2 = player.tile_position(needle)
 check(combat.sell_building(needle), "real sale of fixture Needle")
 player.gold = 5000
 player.electricity = 5000
 check(combat.place_building("heavy", origin), "paid Arc construction in the same legal position")
 check(game.presentation.building_visual.arc_rebirth_active() == (OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"), "Arc renderer respects launch switch")
 for iteration in range(8):
  game.presentation.update(.125, combat)
  await _render_frame()
 for tick in range(24):
  game._process(STEP)
  await _render_frame()
  for shot in combat.projectiles:
   if shot.kind != "heavy" or shot.room != combat.player_room or shot.age > .075:
    continue
   var room = combat.player()
   check(shot.from == room.tile_position(shot.building_id) and shot.target_id == 1, "canonical Arc launch origin and Stalker target")
   await capture("arc-actual-launch-720")
   var frame := root.get_texture().get_image()
   var center: Vector2 = root.get_final_transform() * game.world_to_screen(shot.from)
   var region := Rect2i(Vector2i(center) - Vector2i(77, 115), Vector2i(154, 151))
   check(Rect2i(Vector2i.ZERO, frame.get_size()).encloses(region), "native launch crop in viewport")
   check(frame.get_region(region).save_png(destination.path_join("arc-actual-launch-crop.png")) == OK, "save actual launch crop")
   print("ARC_LAUNCH_AGE=", shot.age, " POSITION=", shot.position, " ORIGIN=", shot.from, " TARGET=", shot.target_id)
   var projectile_id: int = shot.id
   for flight_tick in range(36):
    game._process(STEP)
    await _render_frame()
    for event in combat.combat_events:
     if event.projectile_id == projectile_id and event.type == "impact":
      check(event.damage > 0 and event.target_id == 1, "matching Arc shot deals actual damage to Stalker")
      await capture("arc-actual-impact-720")
      print("ARC_IMPACT_ID=", projectile_id, " POSITION=", event.position, " DAMAGE=", event.damage)
      return
   check(false, "capture matching Arc impact")
   return
 check(false, "capture in-flight Arc launch")

func _pose_if_needed(model):
 if model.hunter.state != HunterState.State.ATTACK:
  _pose_stalker(model)
 game.presentation.identity.heading = Vector2.LEFT

func _draw_sheet(sheet: Node2D):
 sheet.draw_rect(Rect2(0, 0, 1280, 720), Color("17212b"))
 sheet.draw_string(FONT, Vector2(26, 42), "Arc Turret · Godot production renderer", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("f0debc"))
 sheet.draw_string(FONT, Vector2(26, 68), "Equal scale and bearing · isolated inspection views", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("beccd3"))
 var row_names := ["Unbranched", "Focused Discharge", "Storm Coil"]
 var branches := ["", "focus", "storm"]
 var visual = game.presentation.building_visual
 for level in range(1, 11):
  var x := 237 + (level - 1) * 106
  sheet.draw_string(FONT, Vector2(x - 15, 112), "L%d" % level, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("e9d5af"))
  for row in range(3):
   var y := 224 + row * 160
   if level == 1:
    sheet.draw_string(FONT, Vector2(24, y - 34), row_names[row], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("e9d5af"))
   var origin := Vector2(x, y)
   sheet.draw_rect(Rect2(origin - Vector2(48, 92), Vector2(96, 122)), Color("283542"))
   if row > 0 and level < 5:
    sheet.draw_string(FONT, origin + Vector2(-4, -11), "–", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("b2b7bc"))
    continue
   visual.draw(sheet, game.presentation, "heavy", level, origin, branches[row], 0.0, Vector2(1, -.35), 0.0, 0.0, 1.25)
