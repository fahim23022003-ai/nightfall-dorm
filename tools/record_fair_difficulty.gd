extends "res://tools/record_earned_power.gd"
var snapshots=[]
var saw_recovery=false
var saw_pressure=false
func buy_control(kind):
 var r=game.model.player();var ids=[]
 for i in range(r.tile_count()):
  if not r.buildings.has(i):ids.append(i)
 ids.sort_custom(func(a,b):return r.tile_position(a).distance_to(r.door_approach())<r.tile_position(b).distance_to(r.door_approach()))
 if ids.is_empty():return false
 var id=ids[0];var count=r.buildings.size();await close_context();await world_click(r.tile_position(id));await wait(.35)
 var button=game.ui.actions["build:"+kind];var parent=button.get_parent()
 while parent!=null:
  if parent is ScrollContainer:parent.ensure_control_visible(button)
  parent=parent.get_parent()
 await wait(.2);await click(button);await wait(.25);await close_context()
 var ok=r.buildings.size()==count+1;check(ok,"ordinary UI purchase "+kind)
 if ok:log_action("buy "+kind)
 return ok
func structure_ready(kind):
 var r=game.model.player();var l=r.bed_level if kind=="bed" else r.door_level
 if l>=9 or l==4 and (r.bed_branch if kind=="bed" else r.door_branch)=="":return false
 var other=r.door_level if kind=="bed" else r.bed_level;var p=BalanceRules.structure(kind,l,2)
 return other>=maxi(0,l-1) and r.gold>=p.x and r.electricity>=p.y
func decide():
 var m=game.model;var r=m.player()
 if r==null or r.door_hp<=0:return
 if r.door_hp<r.max_hp()*.50:
  if structure_ready("door"):await structure_control("door");return
  if r.gold>=r.manual_repair_cost() and r.max_hp()-r.door_hp>=Catalog.REPAIR_HEAL*r.repair_factor:
   await close_context();await key(KEY_R);await wait(.15);log_action("repair R");return
 if not has_kind("turret"):
  if can_build("turret"):await buy_control("turret")
  return
 for kind in ["bed","door"]:
  if (r.bed_level if kind=="bed" else r.door_level)<1:
   if structure_ready(kind):await structure_control(kind)
   return
 for kind in ["bed","door"]:
  if (r.bed_level if kind=="bed" else r.door_level)<2:
   if structure_ready(kind):await structure_control(kind)
   return
 if not has_kind("generator"):
  if can_build("generator"):await buy_control("generator");await capture("live-earned-grid")
  return
 for id in r.buildings:
  var b=r.buildings[id]
  if b.kind=="turret" and b.level<2:
   var q=BalanceRules.upgrade(b.kind,b.level,2)
   if r.gold>=q.x and r.electricity>=q.y:await upgrade_control(id)
   return
 if r.door_level<3:
  if structure_ready("door"):await structure_control("door")
  return
 for kind in ["auto_repair","frost"]:
  if not has_kind(kind):
   if can_build(kind):await buy_control(kind);await capture("live-"+kind)
   return
 for kind in ["bed","door"]:
  if (r.bed_level if kind=="bed" else r.door_level)<(3 if kind=="bed" else 4):
   if structure_ready(kind):await structure_control(kind)
   return
 if not has_kind("flame") and can_build("flame"):await buy_control("flame")
func run():
 output="res://docs/evidence/fair-difficulty/screens/";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output));root.size=Vector2i(1280,720)
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://phase12b-live-fresh-"+str(Time.get_ticks_usec())+".json")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.onboarding.set_process(false)
 check(game.profile.xp==0 and game.profile.inventory.is_empty() and game.profile.equipped.is_empty(),"fresh entry no hidden inventory/permanent bonuses")
 var layer=CanvasLayer.new();layer.layer=99;root.add_child(layer);label=Label.new();label.position=Vector2(20,705);label.size=Vector2(1240,15);label.clip_text=true;label.add_theme_font_size_override("font_size",11);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(label)
 tell("SCRIPTED ACTUAL INPUT · fresh Long Night Campaign · normal speed · no assigned funds/HP/positions")
 var out=[];OS.execute("python",[ProjectSettings.globalize_path("res://tools/first_night_xinput.py"),"focus",str(DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE))],out)
 print("VIDEO_READY")
 if "record" in OS.get_cmdline_user_args():
  while not FileAccess.file_exists("/tmp/phase12b-record-go"):await process_frame
 recorder=AudioEffectRecord.new();AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);started=Time.get_ticks_usec();game.set_process(true);game.onboarding.set_process(true)
 await wait(1);await key(KEY_SPACE);await wait(.3);await click(game.onboarding.welcome_close);await click(game.ui.menu_start);await wait(.4);await click(find_button("Skip practice · no rewards"));await wait(.4)
 await click(game.ui.menu_start);await wait(.4);await click(find_button("Prepare"));await wait(.4);await click(game.find_child("mode_hard",true,false));await wait(.4);await capture("live-fresh-hard-entry");await click(find_button("Start Match"));await wait(.3)
 check(game.model.difficulty=="hard" and game.model.run_kind=="campaign" and game.model.balance_version==2,"real menu starts hard Campaign v2")
 var m=game.model;var room=m.rooms.filter(func(r):return r.owner<0)[0];await move_to(room.bed_position()+Vector2(31,46));await key(KEY_E);await wait(.2)
 check(m.player()!=null,"actual walk and claim, no teleport")
 if m.player()!=null:
  await move_to(m.player().bed_position()+Vector2(0,48));await wait(.2)
  print("SLEEP_BEFORE ",m.player_position," bed=",m.player().bed_position()," distance=",m.player_position.distance_to(m.player().bed_position()))
  await key(KEY_E);await wait(.5)
  print("SLEEP_AFTER sleeping=",m.player().sleeping," feedback=",game.ui.message.text)
  if not m.player().sleeping:
   await capture("failed-sleep-setup");game.audio_system.shutdown();quit(1);return
 check(m.player()!=null and m.player().sleeping,"actual sleep, ordinary production")
 var next_sample=0.0
 while (Time.get_ticks_usec()-started)/1e6<600 and m.result=="":
  if m.time>=next_sample:
   snapshots.append({"time":m.time,"hp":m.player().door_hp,"max_hp":m.player().max_hp(),"gold":m.player().gold,"electricity":m.player().electricity,"hunter_hp":m.hunter.hp,"repair_factor":m.player().repair_factor,"pressure":m.pressure.factor(m)});next_sample+=5
  if not saw_pressure and m.hunter.target==m.player_room and m.hunter.state==HunterState.State.ATTACK:saw_pressure=true;await capture("live-own-door-pressure")
  if not saw_recovery and m.hunter.recovery_remaining>0:saw_recovery=true;await capture("live-charged-recovery")
  await decide();await wait(.8)
 await wait(.8);await capture("live-actual-result")
 check(m.result=="victory","continuous actual hard-mode victory, no manual kills")
 check(not m.choices.enabled(m) and actions_log.all(func(a):return not a.action.begins_with("activate")),"no Endless perks/merchant or saved item use; post-victory earned inventory is legitimate")
 var f=FileAccess.open("res://docs/evidence/fair-difficulty/live-journey.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"result":m.result,"archetype":m.hunter.archetype,"simulation_seconds":m.time,"wall_seconds":(Time.get_ticks_usec()-started)/1e6,"actions":actions_log,"samples":snapshots,"flows":m.player().ledger.totals,"conditions":"Actual production Game processing, native scripted InputEvents, fresh profile, menu-selected Long Night stage1, walking/claim/sleep, no model wallet/HP/position/time edits. One visible action decision at a time, UI animations and reaction delays. Not human/native Windows."}," "))
 recorder.set_recording_active(false);var pcm=recorder.get_recording();check(pcm!=null and pcm.data.size()>1000,"actual Master audio capture");pcm.save_to_wav("/workspace/phase12b-master.wav");AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
 print("FAIR_LIVE_CHECKS=",checks," FAILURES=",failures);game.audio_system.shutdown();game.queue_free();layer.queue_free();await wait(.5);quit(1 if failures else 0)
