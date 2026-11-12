extends "res://tools/capture_phase5d3_team.gd"
# Early UX gate, before boss/new-building integration. Actual GUI transactions.
var measurements=[]
func camera_state():return {"position":game.camera.position,"zoom":game.camera.zoom,"player":game.model.player_position}
func check_camera(old,label):
 var now=camera_state();check(now.position.distance_to(old.position)<.001 and now.zoom.distance_to(old.zoom)<.001 and now.player==old.player,"no camera/player motion: "+label)
 measurements.append({"label":label,"delta_position":now.position.distance_to(old.position),"delta_zoom":now.zoom.distance_to(old.zoom),"panel":str(game.ui.context_box.get_rect())})
func prepared(map="abandoned_dorm"):
 game.return_menu();game.start_practice("crusher",false,["shield","repair"],map);game.set_process(false);game.tutorial_enabled=false
 var m=game.model
 for i in range(1,6):
  var r=m.rooms[i];r.owner=i;r.sleeping=true;r.closed=true;r.resident_position=r.bed_position()
 m.hunter.boss_policy.enabled=false;m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.position=m.player().door_approach();m.hunter.cooldown=20
 game.ui.teammates.expanded=false;game.focus_camera(true)
 return m
func branch_geometry(kind,suffix):
 var a=game.ui.specialization_items[1];var b=game.ui.specialization_items[2];var back=game.ui.specialization_items[3];var confirm=game.ui.branch_confirm
 var row={"kind":kind,"resolution":suffix,"a":str(a.get_global_rect()),"b":str(b.get_global_rect()),"back":str(back.get_global_rect()),"confirm":str(confirm.get_global_rect()),"minimum_a":str(a.get_combined_minimum_size()),"minimum_b":str(b.get_combined_minimum_size())}
 measurements.append(row)
 check(not a.get_global_rect().intersects(back.get_global_rect()) and not b.get_global_rect().intersects(confirm.get_global_rect()),"branch controls do not overlap "+kind+suffix)
func run():
 output="res://docs/evidence/phase5d4/";phase="early-render"
 await setup_game()
 var args=OS.get_cmdline_user_args()
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  var m=prepared();var r=m.player();await advance(.2);await capture("01-hud-"+suffix)
  await key(KEY_I);await advance(.15);check(game.ui.items_ui.expanded,"I opens actual inventory");await capture("02-items-"+suffix);await key(KEY_I)
  await key(KEY_G);await advance(.15);check(game.ui.help_open,"G opens guide");await capture("03-help-"+suffix);await key(KEY_G)
  await key(KEY_T);await advance(.15);await capture("04-team-"+suffix);await key(KEY_T)
  var before=camera_state();await world_click(r.tile_position(0));await advance(.2);check_camera(before,"purchase "+suffix)
  await capture("05-build-palette-"+suffix)
  var build_button=game.ui.actions["build:generator"]
  var motion=InputEventMouseMotion.new();motion.position=root.get_final_transform()*build_button.get_global_rect().get_center();motion.global_position=motion.position;Input.parse_input_event(motion);await create_timer(.75).timeout
  await capture("06-build-tooltip-"+suffix)
  var gold=r.gold;var power=r.electricity;await click(build_button);await advance(.2)
  check(r.buildings.has(0) and r.buildings[0].kind=="generator" and game.pending_build=="","direct BUILD creates once without nested placement")
  check(r.gold==gold-30 and r.electricity==power,"direct BUILD charges actual cost")
  check_camera(before,"built inspector "+suffix);await capture("07-built-inspector-"+suffix)
  await click(game.ui.actions.upgrade);await advance(.15);check(r.buildings[0].level==2,"upgrade actual Dynamo L2");await capture("08-upgraded-"+suffix)
  for kind in ["turret","heavy","generator","repair","economy","enhancer","bed","door"]:
   m=prepared();r=m.player();var branch_camera=camera_state()
   if kind in ["bed","door"]:
    await click(game.ui.room_bed_summary if kind=="bed" else game.ui.room_door_summary);await advance(.1);await capture(kind+"-current-"+suffix)
    await click(game.ui.actions[kind])
   else:
    var tile=m.practice_tile
    if kind!="turret":
     tile=0;check(r.build(kind,tile),"actual paid "+kind)
     for level in range(3):check(r.upgrade_building(tile),"actual paid level "+kind)
    await world_click(r.tile_position(tile));await advance(.1);await capture(kind+"-current-"+suffix)
    await click(game.ui.actions.upgrade)
   await advance(.2);check_camera(branch_camera,"branch "+kind+suffix);check(game.ui.context_mode=="specialize","branch mode "+kind)
   branch_geometry(kind,suffix);await capture(kind+"-choices-"+suffix)
   gold=r.gold;power=r.electricity;var rng=m.random.state
   await click(game.ui.specialization_items[1]);await advance(.15)
   check(r.gold==gold and r.electricity==power and m.random.state==rng,"branch selection does not spend/RNG "+kind)
   await capture(kind+"-selected-before-confirm-"+suffix)
   await click(game.ui.branch_confirm);await advance(.15)
   check(r.gold<gold and r.electricity<power,"confirmed branch spends "+kind);await capture(kind+"-confirmed-"+suffix)
  if not "quick" in args:
   for stage in StageCatalog.STAGES:
    m=prepared(stage.map);await advance(.15);await capture(stage.id+"-hud-"+suffix)
    before=camera_state();await world_click(m.player().tile_position(0));await advance(.15);check_camera(before,stage.id+suffix);await capture(stage.id+"-build-"+suffix)
 var f=FileAccess.open("res://docs/evidence/phase5d4/early-render-observations.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"measurements":measurements,"fixture":"Actual input in isolated Practice temporary resources; paid existing structures/branches; controlled Hunter and teammate pose. UI/audio gate only, no natural balance claim."}," "))
 print("PHASE5D4_EARLY_RENDER_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
