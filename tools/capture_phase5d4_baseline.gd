extends "res://tools/capture_phase5d3_team.gd"
# Fresh actual5D4 baseline; isolated temporary Practice budget, not economy proof.
const SOURCE="d507600f64c3c55ff858a9d5bc5d3c938b6e5f6d"
var observations=[]
func camera_state():return {"position":[game.camera.position.x,game.camera.position.y],"zoom":[game.camera.zoom.x,game.camera.zoom.y],"player":[game.model.player_position.x,game.model.player_position.y]}
func capture(name):
 if game.mode=="match":game.ui.update_match();game.ui.items_ui.update(0)
 await super.capture(name)
func run():
 output="res://docs/evidence/phase5d4/baseline/";phase="render"
 await setup_game()
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  game.return_menu();game.start_practice("crusher",false,["shield","repair"]);game.set_process(false)
  var m=game.model;var r=m.player()
  for i in range(1,6):
   var other=m.rooms[i];other.owner=i;other.sleeping=true;other.closed=true;other.resident_position=other.bed_position()
  game.tutorial_enabled=true;m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.position=r.door_approach();m.hunter.cooldown=10
  game.ui.teammates.expanded=false;await advance(.4);await capture("01-gameplay-hud-"+suffix)
  await key(KEY_T);await advance(.2);await capture("02-expanded-roster-"+suffix);await key(KEY_T)
  var initial=camera_state();var tile=0
  while r.buildings.has(tile):tile+=1
  await world_click(r.tile_position(tile));await advance(.4)
  check(game.ui.context_open and game.ui.context_mode=="build","actualempty-padcardsopen")
  observations.append({"resolution":suffix,"action":"openempty-padpanel","before":initial,"after":camera_state(),"panel_rect":str(game.ui.context_box.get_rect())})
  await capture("03-purchase-cards-"+suffix)
  var gold=r.gold;var power=r.electricity
  await click(game.ui.actions["build:generator"]);await advance(.2)
  check(game.pending_build=="generator" and r.gold==gold and r.electricity==power,"previewdoesnotspend")
  await capture("04-placement-confirmation-"+suffix)
  await click(game.ui.confirm_button);await advance(.25)
  check(r.buildings.has(tile) and r.buildings[tile].kind=="generator","actualconfirmconstructsDynamo")
  check(r.gold==gold-Catalog.BUILDINGS.generator.gold and r.electricity==power-Catalog.BUILDINGS.generator.power,"actualpurchasechargesonce")
  await world_click(r.tile_position(tile));await advance(.3);await capture("05-building-current-stats-"+suffix)
  check(game.ui.context_mode=="upgrade","actualexistingbuildingopensupgrade")
  await click(game.ui.actions.upgrade);await advance(.25)
  check(r.buildings[tile].level==2,"actualupgradelevel2")
  await capture("06-building-upgraded-"+suffix)
  await world_click(r.tile_position(m.practice_tile));await advance(.25)
  await capture("07-needle-level4-"+suffix)
  await click(game.ui.actions.upgrade);await advance(.2)
  await capture("08-specialization-choice-"+suffix)
  check(game.ui.context_mode=="specialize" and game.ui.specialization_items[1].visible,"actualbranchchoiceUI")
  await click(game.ui.specialization_items[1]);await advance(.2)
  check(r.buildings[m.practice_tile].level==5 and r.buildings[m.practice_tile].get("specialization","")!="","actualexclusivebranchpurchase")
  await capture("09-specialization-selected-"+suffix)
  game.ui.close_context();await click(game.ui.room_bed_summary);await advance(.25);await capture("10-bed-upgrade-panel-"+suffix)
  game.ui.close_context();await click(game.ui.room_door_summary);await advance(.25);await capture("11-door-upgrade-panel-"+suffix)
  observations.append({"resolution":suffix,"action":"doorpanel","panel_rect":str(game.ui.context_box.get_rect()),"camera":camera_state()})
 var f=FileAccess.open("res://docs/evidence/phase5d4/baseline/render-observations.json",FileAccess.WRITE);f.store_string(JSON.stringify({"source":SOURCE,"checks":checks,"failures":failures,"observations":observations,"conditions":"ActualGame Practice temporarybudget20kG/5kE; populatedactualNPCstate controlledrenderfixture. Purchases/upgrades/branchuseactualmouseinput. No naturalincome/balance/Windowsclaim."}," "))
 print("PHASE5D4_BASELINE_RENDER_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
