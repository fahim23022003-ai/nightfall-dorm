extends "res://tools/capture_first_night.gd"
var actions_log=[]
var did_pressure=false
var bought_supply=""
func log_action(text):actions_log.append({"wall":(Time.get_ticks_usec()-started)/1e6,"simulation":game.model.time,"action":text,"gold":game.model.player().gold if game.model.player()!=null else 0,"electricity":game.model.player().electricity if game.model.player()!=null else 0})
func close_context():
 if game.ui.context_open:await key(KEY_ESCAPE);await wait(.32)
func buy_control(kind):
 var r=game.model.player();var tile=-1
 for i in range(r.tile_count()):
  if r.spatial.geometry_reason(r.fixed_tile_position(i))=="":tile=i;break
 if tile<0:return false
 var count=r.buildings.size();await close_context();await key(KEY_B);await wait(.35);await click(game.ui.actions["build:"+kind]);await wait(.35);await world_click(r.fixed_tile_position(tile));await wait(.35);await close_context()
 var ok=r.buildings.size()==count+1
 check(ok,"actual paid input purchase "+kind)
 if ok:log_action("buy "+kind)
 return ok
func structure_control(kind):
 await close_context();await click(game.ui.room_bed_summary if kind=="bed" else game.ui.room_door_summary);await wait(.32)
 await click(game.ui.bed_button if kind=="bed" else game.ui.door_button);await wait(.15);await close_context();log_action("upgrade "+kind)
func upgrade_control(id):
 var r=game.model.player();var before=int(r.buildings[id].level);await close_context();await world_click(r.tile_position(id)+Vector2(0,-12));await wait(.32)
 await click(game.ui.actions.upgrade);await wait(.2)
 if game.ui.context_mode=="specialize":
  await click(game.ui.specialization_items[1]);await wait(.15);await click(game.ui.branch_confirm);await wait(.2)
 await close_context();check(r.buildings[id].level>before,"actual input machine upgrade");log_action("upgrade "+r.buildings[id].kind)
func can_build(kind):
 var r=game.model.player();var q=r.quote_build(kind)
 return r.buildings.size()<r.tile_count() and BalanceRules.build_requirement(kind,r)=="" and r.gold>=q.x and r.electricity>=q.y
func has_kind(kind):return game.model.player().buildings.values().any(func(b):return b.kind==kind)
func find_prefix(text,node=null):
 if node==null:node=game.ui.panel
 for child in node.get_children():
  if child is Button and child.text.begins_with(text) and child.is_visible_in_tree() and not child.disabled and not child.is_queued_for_deletion():return child
  var got=find_prefix(text,child)
  if got!=null:return got
 return null
func intermission():
 await close_context();await wait(.4)
 tell("Wave actually cleared · review production/spending → optional perk + limited merchant → aid → Continue")
 await click(find_button("Wave report"));await wait(1);await click(find_button("Economy"));await wait(1.4);await capture("live-economy-flow")
 await click(find_button("Back · wave choices and Omens"));await wait(.4);await click(find_button("Run perks / merchant"));await wait(.6);await capture("live-perk-merchant")
 var c=game.model.choices
 if not c.draft.is_empty():
  var id=c.draft[0];await click(find_button("Choose · "+RunChoices.CATALOG[id].name));await wait(.5);check(c.selected.has(id),"real input perk draft saved");log_action("perk "+id)
 for offer in c.offers:
  var target=find_prefix("Buy "+offer.id.capitalize()+" ·")
  if target==null:continue
  var id=offer.id;await click(target);await wait(.4)
  if int(c.stock.get(id,0))>0:bought_supply=id;log_action("merchant "+id);await capture("live-merchant-purchase");break
 await click(find_button("Back · aid and Omens"));await wait(.4)
 await click(find_button("Save & exit to menu"));await wait(.4);await click(find_button("Endless Siege"));await wait(.4);await click(find_button("Resume saved checkpoint"));await wait(.5)
 check(game.model.balance_version==2 and not game.model.choices.selected.is_empty(),"actual saved run resumes with rules/perk")
 await click(find_button("4 · Continue · Reinforce"));await wait(.5);log_action("continued next wave")
 tell("Next wave · paid defenses persist · temporary supplies via K · real Hunter pressure")
func decide():
 var m=game.model;var r=m.player()
 if r==null or not r.alive:return
 if bought_supply!="" and int(m.choices.stock.get(bought_supply,0))>0 and m.items.can_activate(bought_supply,m)=="":
  await close_context();await key(KEY_K);await wait(.3)
  var target=find_prefix("Use "+ItemCatalog.ITEMS[bought_supply].name)
  if target!=null:await click(target);await wait(.2);log_action("activate supply "+bought_supply)
  await key(KEY_K);await wait(.2)
 if r.door_hp<r.max_hp()*.67 and r.door_hp>0 and r.gold>=r.manual_repair_cost():
  if not did_pressure:await capture("live-pressure-before-repair")
  var hp=r.door_hp;await key(KEY_R);await wait(.25)
  if r.door_hp>hp and not did_pressure:did_pressure=true;await capture("live-successful-repair-counter")
  log_action("repair R");return
 # Save a real merchant budget near the end of wave1, rather than injecting one.
 if m.endless.wave==1 and m.time>170:return
 if not has_kind("turret") and can_build("turret"):await buy_control("turret");return
 for kind in ["bed","door"]:
  var level=r.bed_level if kind=="bed" else r.door_level
  var price=BalanceRules.structure(kind,level,2)
  if level<1 and r.gold>=price.x and r.electricity>=price.y:await structure_control(kind);return
 if not has_kind("generator"):
  if can_build("generator"):await buy_control("generator");await capture("live-earned-dynamo")
  return
 for kind in ["bed","door"]:
  var level=r.bed_level if kind=="bed" else r.door_level
  var price=BalanceRules.structure(kind,level,2)
  if level<3 and r.gold>=price.x and r.electricity>=price.y and (r.door_level>=maxi(0,r.bed_level-1) if kind=="bed" else r.bed_level>=maxi(0,r.door_level-1)):await structure_control(kind);return
 if not has_kind("repair") and can_build("repair"):await buy_control("repair");return
 if r.buildings.size()==r.tile_count() and m.expansion.reason(m,r.index)=="":
  await close_context();await key(KEY_B);await wait(.32);await click(game.ui.expansion_ui.shortcut);await wait(.3);await click(game.ui.expansion_ui.purchase_button);await wait(.4);await close_context();log_action("paid room expansion");return
 if can_build("heavy") and not has_kind("heavy"):await buy_control("heavy");return
 for id in r.buildings:
  var b=r.buildings[id];var price=BalanceRules.upgrade(b.kind,b.level,2)
  if b.level<3 and BalanceRules.requirement(b.kind,b.level,r.bed_level,r.door_level,2)=="" and r.gold>=price.x and r.electricity>=price.y:await upgrade_control(id);return
func run():
 output="res://docs/evidence/earned-power/screens/";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output));root.size=Vector2i(1280,720)
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://phase12-live-fresh-"+str(Time.get_ticks_usec())+".json")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.onboarding.set_process(false)
 check(game.profile.xp==0 and game.profile.inventory.is_empty(),"fresh isolated profile no advantages")
 var layer=CanvasLayer.new();layer.layer=99;root.add_child(layer);label=Label.new();label.position=Vector2(20,705);label.size=Vector2(1240,15);label.clip_text=true;label.add_theme_font_size_override("font_size",11);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(label)
 tell("SCRIPTED REAL INPUT · fresh profile / no budget injection · normal speed / new economy v2")
 var out=[];OS.execute("python",[ProjectSettings.globalize_path("res://tools/first_night_xinput.py"),"focus",str(DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE))],out)
 print("VIDEO_READY")
 if "record" in OS.get_cmdline_user_args():
  while not FileAccess.file_exists("/tmp/phase12-record-go"):await process_frame
 recorder=AudioEffectRecord.new();AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);started=Time.get_ticks_usec();game.set_process(true);game.onboarding.set_process(true)
 await wait(1);await key(KEY_SPACE);await wait(.3);await click(game.onboarding.welcome_close);await wait(.3);await click(game.ui.menu_start);await wait(.3);await click(find_button("Skip practice · no rewards"));await wait(.4)
 await click(find_button("Endless Siege"));await wait(.4);await click(find_button("New Endless run"));await wait(.5)
 var m=game.model;var room=m.rooms.filter(func(r):return r.owner<0)[0];await move_to(room.bed_position()+Vector2(31,46));await key(KEY_E);await wait(.2)
 if m.player()==null:room=m.rooms.filter(func(r):return r.owner<0)[0];await move_to(room.bed_position()+Vector2(31,46));await key(KEY_E)
 check(m.player()!=null,"actual walking/claim without teleport")
 await move_to(m.player().bed_position()+Vector2(31,46));await key(KEY_E);await wait(.3);check(m.player().sleeping,"actual sleep starts production")
 await capture("live-fresh-opening")
 var until=started+360000000
 while Time.get_ticks_usec()<until and game.model.result=="":
  if game.model.endless.phase=="intermission":await intermission()
  else:await decide()
  await wait(.8)
 check(game.model.player()!=null and game.model.player().alive,"six-minute ordinary input journey remains playable")
 check(game.model.endless.completed>=1 and not game.model.choices.selected.is_empty(),"actual completed encounter / meaningful run choice")
 check(bought_supply!="","merchant bought from actual earnings")
 await close_context();await capture("live-six-minute-position")
 var file=FileAccess.open("res://docs/evidence/earned-power/live-journey.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"wall_seconds":(Time.get_ticks_usec()-started)/1e6,"simulation_seconds":game.model.time,"completed":game.model.endless.completed,"actions":actions_log,"flows":game.model.player().ledger.totals,"trace":game.model.player().ledger.records,"conditions":"Actual running production scene, scripted InputEvent keyboard/mouse, fresh profile, explicit practice Skip. No assigned wallet/HP/position/stats, no time acceleration. Menu save/resume uses actual safe checkpoint. Not human or native Windows testing."}," "))
 recorder.set_recording_active(false);var pcm=recorder.get_recording();check(pcm!=null and pcm.data.size()>1000,"actual engine Master capture");pcm.save_to_wav("/workspace/phase12-master.wav");AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
 print("EARNED_POWER_LIVE_CHECKS=",checks," FAILURES=",failures);game.audio_system.shutdown();game.queue_free();layer.queue_free();await wait(.5);quit(1 if failures else 0)
