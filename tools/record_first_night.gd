extends "res://tools/capture_first_night.gd"
func free_point(r):
 for tile in range(r.tile_count()):
  if r.buildings.has(tile):continue
  var point=r.fixed_tile_position(tile)+Vector2(3,-1)
  if r.spatial.geometry_reason(point)=="":return point
 return Vector2.INF
func after_cold():
 game.return_menu();await wait(.3)
 tell("SEPARATE SCENARIO · canonical earned45 copy · original earned funds, no HP edits")
 game.set_process(false)
 var source="res://docs/evidence/gameplay-overhaul/balance/earned-cursed_mansion.json";var hash=FileAccess.get_sha256(source)
 var raw=JSON.parse_string(FileAccess.get_file_as_string(source));var m=ReplaySnapshot.restore(raw);check(m!=null,"canonical45 actual migration")
 var p=PlayerProfile.new("user://phase11-earned-copy-"+str(Time.get_ticks_usec())+".json");p.complete_tutorial()
 var entry=p.begin_endless(m.map_id,m.difficulty,m.endless.seed_value);check(not entry.is_empty(),"isolated earned demonstration profile")
 m.endless.run_id=int(entry.run_id) # Rebind disposable transaction identity only, never combat/resources.
 game.profile=p;game.model=m;game.match_id=int(entry.id);game.mode="match";game.tutorial_active=false;game.watched_room=-1;game.construction.reset();p.bind_items(m,entry.id)
 check(p.checkpoint_endless(m),"imported earned state saves with valid identity")
 game.ui.replay_ui.preparing=true;game.ui.replay_ui.intermission_saved=true;game.ui.show_match();game.focus_camera(true);game.audio_system.reset_match(m);game.set_process(true)
 var r=m.player();var starting_wallet=[r.gold,r.electricity]
 # Repair station upgrades and four Arc10 machines, paid entirely from canonical earnings.
 for id in r.buildings:
  if r.buildings[id].kind=="repair":
   await world_click(r.tile_position(id)+Vector2(0,-12));await wait(.35)
   while r.buildings[id].level<10:await click(game.ui.actions.upgrade);await wait(.12)
   await key(KEY_ESCAPE);await wait(.3)
 while r.buildings.size()<16:
  var point=free_point(r);check(point!=Vector2.INF,"actual unlocked free floor")
  await key(KEY_B);await wait(.32);await click(game.ui.actions["build:heavy"]);await wait(.3);await world_click(point);await wait(.3)
  var id=game.selected_tile;check(r.buildings.has(id) and r.buildings[id].kind=="heavy","actual paid free-placement Arc")
  await world_click(r.tile_position(id)+Vector2(0,-12));await wait(.35)
  while r.buildings[id].level<10:
   await click(game.ui.actions.upgrade);await wait(.16)
   if game.ui.context_mode=="specialize":
    var choice=StrategyCatalog.branches("heavy").find("focus")+1;await click(game.ui.specialization_items[choice]);await wait(.1);await click(game.ui.branch_confirm);await wait(.15)
  await key(KEY_ESCAPE);await wait(.3)
 check(r.gold<starting_wallet[0] and r.electricity<starting_wallet[1],"earned wallet paid real costs")
 await capture("17-earned-full16")
 tell("Save & Continue · actual checkpoint roundtrip, no altered Hunter HP")
 await key(KEY_ESCAPE);await wait(.4);await click(find_button("Save & exit to menu"));await wait(.35);await click(find_button("Endless Siege"));await wait(.35);await click(find_button("Resume saved checkpoint"));await wait(.5)
 check(game.model.endless.phase=="intermission" and game.model.player().buildings.size()==16,"actual saved Continue restores all16 upgrades")
 await capture("15-intermission-decisions")
 await click(find_button("4 · Continue · Reinforce"));await wait(.4);m=game.model
 check(m.endless.wave==46 and m.hunter.hp==m.hunter.max_hp,"normal full-health next wave begins")
 tell("LIVE earned46 · normal runtime until actual wave completion")
 var deadline=Time.get_ticks_msec()+130000
 while m.endless.phase=="combat" and m.result=="" and Time.get_ticks_msec()<deadline:await process_frame
 check(m.endless.phase=="intermission" and m.endless.completed==46,"actual live earned wave46 victory")
 await wait(.5);await click(find_button("Wave report"));await wait(.8)
 check(game.ui.current_screen=="wave_report","live report stays open across normal game frames")
 await capture("11-wave-report-redesign");await capture("12-damage-breakdown")
 for button in ["Economy","Defense","Insights","Hunter Skills"]:
  await click(find_button(button));await wait(.4)
  await capture({"Economy":"13-economy-breakdown","Defense":"defense-breakdown","Insights":"14-strategy-feedback","Hunter Skills":"hunter-skills"}[button])
 await click(find_button("Back · wave choices and Omens"));await wait(.4);await capture("15-intermission-decisions")
 var data=m.wave_metrics.report();var f=FileAccess.open("res://docs/evidence/first-night/earned46-live.json",FileAccess.WRITE);f.store_string(JSON.stringify({"metrics":data,"checkpoint":ReplaySnapshot.encode(m),"source_sha256":hash,"conditions":"Canonical earned45 copy. Disposable profile transaction ID rebound; actual paid upgrades and four Arc10 from canonical earnings. Scripted real UI input, actual save/resume and full-health wave46 through normal Game._process. No injected Gold/Electricity or HP edits."}," "))
 await click(find_button("4 · Continue · Recharge"));await wait(.5);check(game.model.endless.wave==47,"actual intermission aid advances to wave47 once")
 tell("NEXT WAVE · report complete, defenses/resources persist")
 await wait(2)
 check(FileAccess.get_sha256(source)==hash,"canonical earned checkpoint byte-preserved")
