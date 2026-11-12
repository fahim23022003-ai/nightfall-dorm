extends "res://tools/capture_phase5d3_team.gd"
var rows=[]
func camera_info():return {"position":str(game.camera.position),"zoom":str(game.camera.zoom),"target":str(game.camera_target)}
func run():
 output="res://docs/evidence/gameplay-overhaul/";phase="expansion-render"
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://overhaul-expansion-render-"+str(Time.get_ticks_usec())+".json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 preload("res://tests/onboarding_test_support.gd").skip(game);game.set_process(false);game.onboarding.set_process(false)
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y)
  for map_id in MapCatalog.IDS:
   game.return_menu();check(game.start_endless(map_id,"standard",17),"real Endless starts "+map_id)
   game.set_process(false);game.tutorial_enabled=false
   var m=game.model;m.player_position=m.rooms[0].center();check(m.claim_room(0),"actual room claim")
   m.player_position=m.player().bed_position();m.sleep_player()
   var r=m.player();r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp();r.gold=100000;r.electricity=100000
   var bed=r.bed_position();var door=r.door_position();var own=m.player_position;var prefix=[]
   game.ui.close_context();game.full_map=false;game.focus_camera(true);await advance(.4)
   check(r.tile_count()==3,"three actual initial pads")
   await world_click(r.tile_position(0));await advance(.35);await click(game.ui.build_items[0]);await advance(.2)
   check(r.buildings.has(0),"real first pad purchases Needle")
   var original=r.tile_position(0)
   for tier in range(8):
    check(r.tile_count()==RoomExpansion.SLOTS[tier],"actual tier slot count")
    check(r.bed_position()==bed and r.door_position()==door and m.player_position==own,"door bed player fixed")
    check(r.buildings.has(0) and r.tile_position(0)==original,"old machine retains actual position")
    for i in range(prefix.size()):check(prefix[i]==r.tile_position(i),"stable appended pad prefix")
    prefix=[]
    for i in range(r.tile_count()):
     var point=r.tile_position(i);prefix.append(point)
     check(r.bounds().has_point(point),"pad inside physical room")
     check(m.navigation_walkable(point),"expanded pad walkable geometry")
    var route=m.navigation_path(m.map_data.hunter_spawn,r.door_approach())
    check(not route.is_empty(),"real Hunter corridor route remains valid")
    game.ui.close_context();await advance(.35);game.focus_camera(true);await advance(.2)
    var tag=map_id+"-slots"+str(r.tile_count())+"-"+suffix
    if map_id==MapCatalog.IDS[0] or tier in [0,7]:await capture(tag)
    rows.append({"map":map_id,"resolution":suffix,"tier":tier,"slots":r.tile_count(),"bounds":str(r.bounds()),"door":str(door),"bed":str(bed),"camera":camera_info(),"gold":r.gold,"electricity":r.electricity,"route_points":route.size()})
    if tier==7:break
    await click(game.ui.room_selected_summary);await advance(.35)
    await click(game.ui.expansion_ui.shortcut);await advance(.1)
    check(game.ui.context_mode=="expansion","actual expansion inspector opened")
    if map_id==MapCatalog.IDS[0] and tier in [0,5]:await capture(tag+"-purchase")
    var g=r.gold;var e=r.electricity;var cost=RoomExpansion.COSTS[tier+1]
    await click(game.ui.expansion_ui.purchase_button);await advance(.1)
    check(r.expansion_tier==tier+1 and is_equal_approx(r.gold,g-cost.x) and is_equal_approx(r.electricity,e-cost.y),"actual paid expansion button spends once")
   game.ui.close_context();await advance(.35)
   var last=r.tile_count()-1;await world_click(r.tile_position(last));await advance(.35)
   check(game.selected_tile==last and game.ui.context_mode=="build","actual new last pad selectable")
   await click(game.ui.build_items[0]);await advance(.15)
   check(r.buildings.has(last),"actual newly unlocked final pad buys machine")
   game.ui.close_context();await advance(.35)
   await capture(map_id+"-ultimate-placed-"+suffix)
 var f=FileAccess.open(output+phase+"/result.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":rows,"fixture":"Actual Game.start_endless and mouse UI purchase flow; isolated profile,100000 temporary Gold/Electricity and Bed/Door5 injected to test geometry/transactions, held combat. NOT naturally earned expansion or human/Windows playtest."}," "))
 print("OVERHAUL_EXPANSION_RENDER_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
