extends SceneTree
# Isolated prepared production fixtures, real rendering/input. Not earned-resource balance evidence.
var game
var checks=0
var failures=0
var output="res://docs/evidence/haunted/"
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("HAUNTED RENDER: "+label)
func update(delta):
 game.presentation.update(delta,game.model)
 game.horror.update(delta,game.model)
 game.audio_system.update_state(delta,game.model,game.mode)
 game.audio_system.update_environment(game.presentation.environment)
 game.ui.items_ui.update(delta)
 game.ui.update_match()
 if is_instance_valid(game.ui.horror_layer):game.ui.horror_layer.queue_redraw()
 game.queue_redraw()
func advance(seconds,move_hunter=false):
 var start=Time.get_ticks_usec();var before=start
 while Time.get_ticks_usec()-start<seconds*1000000:
  await process_frame
  var now=Time.get_ticks_usec();var delta=(now-before)/1000000.0
  if move_hunter:game.model.hunter.tick(delta,game.model)
  update(delta);before=now
func capture(name):
 game.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output+name+".png"))==OK,"saved "+name)
 print("HAUNTED_CAPTURE ",name)
func click(button):
 check(button!=null,"actual button exists")
 if button==null:return
 await process_frame
 var point=root.get_final_transform()*button.get_global_rect().get_center()
 var move=InputEventMouseMotion.new();move.position=point;move.global_position=point;Input.parse_input_event(move);await process_frame
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
  Input.parse_input_event(event);await process_frame
func record():return {"clears":1,"best_time":180.0,"best_damage":2000.0,"best_xp":200,"difficulty":"hell","first_match_id":1}
func fixture(stage):
 game.profile.item_loadout=["coupon","overdrive"];game.profile.inventory.coupon=20;game.profile.inventory.overdrive=20
 check(game.start_stage(stage,"hell"),"real stage starts "+stage)
 game.set_process(false);game.tutorial_enabled=false
 var m=game.model;m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 m.time=m.preparation+120;m.bot_claimed=5;m.hunter.boss_policy.enabled=false
 for i in range(1,m.rooms.size()):
  var r=m.rooms[i];r.owner=i;r.sleeping=true;r.closed=true;r.resident_position=r.bed_position()
 m.hunter.target=1;m.hunter.state=HunterState.State.MOVE;m.hunter.position=m.map_data.spawn;m.hunter.cooldown=100
 game.presentation.reset();game.audio_system.reset_match(m);game.horror.reset()
 game.full_map=true;game.focus_camera(true);update(.01)
 return m
func view_room(room):
 game.camera.zoom=Vector2.ONE*minf(820.0/room.bounds().grow(40).size.x,480.0/room.bounds().grow(40).size.y)
 game.camera.position=room.center()+game.MAP_OFFSET+Vector2(-65,25);game.camera.force_update_scroll()
func real_breach(m,index,boss=false):
 var room=m.rooms[index];var h=m.hunter
 h.transformed=boss;h.target=index;h.state=HunterState.State.ATTACK;h.position=room.door_approach();h.cooldown=0;h.boss_attack="";h.boss_cooldowns={"scythe":0.0,"siege":0.0,"surge":0.0};room.door_hp=1
 update(.01)
 h.tick(.01,m)
 if boss:h.tick(2.0,m)
 check(room.door_hp==0 and room.alive,"actual attack destroys door before survivor death")
 update(.01);await advance(.4)
 check(game.audio_system.laughed_rooms.has(index),"breach laugh queued once")
 return room
func real_eliminate(m,index):
 var h=m.hunter;var room=m.rooms[index]
 var limit=0
 while room.alive and limit<100:
  h.tick(.1,m);update(.01);limit+=1
  if game.presentation.fear_rooms.has(index):break
 check(game.presentation.fear_rooms.has(index) and room.alive,"real breach panic before valid bed contact")
 await capture("render-12-panic-before-kill" if index==1 else "render-17-reaper-panic")
 while room.alive and limit<300:h.tick(.1,m);update(.005);limit+=1
 check(not room.alive and not room.sleeping and h.state==HunterState.State.EXIT,"valid bed contact eliminates and exits")
 check(h.position.distance_to(room.bed_position())<12,"actual survivor attack position")
 update(.01)
 return room
func run():
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://haunted-render-"+str(Time.get_ticks_usec())+".json")
 preload("res://tests/onboarding_test_support.gd").prepare()
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 preload("res://tests/onboarding_test_support.gd").skip(game);game.set_process(false);root.size=Vector2i(1280,720)
 game.profile.next_match_id=2
 for stage in StageCatalog.STAGES:game.profile.campaign_records[stage.id]=record()
 game.profile.save_profile()
 var recording=AudioEffectRecord.new();AudioServer.add_bus_effect(0,recording);recording.set_recording_active(true)
 var m
 for i in range(StageCatalog.STAGES.size()):
  m=fixture(StageCatalog.STAGES[i].id)
  var env=game.presentation.environment
  env.update(8,m,false)
  await advance(.12)
  check(env.creatures.size()==5,"five bounded ambient types "+m.map_id)
  for creature in env.creatures:check(env.is_exterior(creature.position,m,30),"complete creature exterior "+creature.kind)
  var rng=m.random.state;var hp=m.hunter.hp
  var first=env.creatures[0].position
  await advance(.4)
  check(m.random.state==rng and m.hunter.hp==hp,"cosmetic animation leaves model RNG and HP intact")
  check(env.creatures[0].position!=first,"actual walker animation "+m.map_id)
  var visible=0
  for actor in env.creatures:
   var screen=game.get_canvas_transform()*(actor.position+game.MAP_OFFSET)
   if Rect2(15,90,1250,535).has_point(screen) and env.creature_alpha(actor)>0:visible+=1
  check(visible>0,"ambient actor actually visible in full map "+m.map_id)
  print("HAUNTED_VISIBLE_ACTORS ",m.map_id,"=",visible)
  await capture("render-%02d-world-%s" % [i+1,m.map_id])
  if i==4:
   var ghost=env.creatures[4];ghost.age=2;ghost.visible=true
   env.flash=0;check(env.creature_alpha(ghost)==0,"apparition hidden outside flash")
   env.next_lightning=env.clock+.02;await advance(.08)
   check(env.flash>0 and env.creature_alpha(ghost)>0,"lightning actually reveals apparition")
   await capture("render-06-lightning-apparition")
   var thunder=game.audio_system.event_counts.get("weather_thunder",0)
   check(env.thunder_due>env.clock,"thunder scheduled after lightning")
   await advance(2.0)
   check(game.audio_system.event_counts.get("weather_thunder",0)>thunder,"delayed thunder played")
   game.profile.update_setting("reduced_effects",true);await advance(.1)
   env.next_lightning=env.clock+.01;await advance(.06)
   check(env.reduced_effects,"reduced effects active")
   await capture("render-07-reduced-storm")
   root.size=Vector2i(960,540);await capture("render-08-world-small");root.size=Vector2i(1280,720)
   game.profile.update_setting("reduced_effects",false)
   for actor in env.creatures:
    actor.age=2;actor.visible=true
    if actor.kind=="fog_apparition":env.flash=.5
    game.camera.zoom=Vector2(3,3);game.camera.position=actor.position+game.MAP_OFFSET;game.camera.force_update_scroll()
    await capture("render-creature-"+actor.kind)
   game.full_map=true;game.focus_camera(true)
 m=fixture("stage_1")
 var r=await real_breach(m,1,false);view_room(r)
 await capture("render-09-normal-breach-laugh")
 await advance(.4)
 check(game.audio_system.event_counts.get("hunter_laugh",0)>0,"normal actual breach laughter played")
 var before_elims=m.eliminations
 await real_eliminate(m,1)
 await advance(.12,true);await capture("render-13-elimination-start")
 await advance(.6,true);await capture("render-14-collapse")
 await advance(1.1,true);await capture("render-15-abandoned-room")
 check(m.eliminations==before_elims+1,"real elimination count increments once")
 check(game.horror.notifications.any(func(n):return n.text.contains("SURVIVOR ELIMINATED") and n.text.contains(r.survivor_name()) and n.text.contains("ROOM 02") and n.text.contains("5 SURVIVORS REMAIN")),"actual survivor/name/room/count notification")
 var gold=r.gold;var power=r.electricity;var builds=r.buildings.size();r.tick_economy(1);BotAI.tick(r,1)
 check(r.gold==gold and r.electricity==power and r.buildings.size()==builds,"dead resident stops economy and autonomous construction")
 var screams=game.audio_system.event_counts.get("death_scream_1",0)+game.audio_system.event_counts.get("death_scream_2",0)
 m.record_event("elimination",1);m.record_event("door_break",1);await advance(.2)
 check(game.audio_system.event_counts.get("death_scream_1",0)+game.audio_system.event_counts.get("death_scream_2",0)==screams,"new-ID duplicate callback no second scream")
 check(game.audio_system.event_counts.get("hunter_laugh",0)==1,"duplicate breach no second laugh")
 var r2=await real_breach(m,2,true);view_room(r2);await capture("render-16-reaper-breach")
 await advance(.5);check(game.audio_system.event_counts.get("reaper_laugh",0)>0,"different Reaper breach cue played")
 await real_eliminate(m,2);await advance(.3,true);await capture("render-18-second-elimination")
 check(game.audio_system.event_counts.get("death_scream_2",0)>0,"second survivor distinct death variation")
 await advance(1.5,true)
 m.hunter.target=0;m.hunter.state=HunterState.State.ATTACK;m.hunter.position=m.player().door_approach();m.hunter.boss_attack="";m.hunter.cooldown=0;m.player().door_hp=1;m.hunter.tick(.01,m);m.hunter.tick(2,m);update(.01)
 check(game.horror.notifications[0].priority==4,"player breach outranks teammate elimination")
 game.full_map=false;game.focus_camera(true);await advance(.3)
 await capture("render-19-player-breach-priority")
 m=fixture("stage_3");r=m.player();r.bed_level=4;r.door_level=4;r.door_hp=r.max_hp();r.gold=30000;r.electricity=5000
 game.presentation.reset();update(.01)
 var tile=0;var best=1e20
 for i in range(r.tile_count()):
  var distance=r.tile_position(i).distance_to(r.door_approach())
  if distance<best:best=distance;tile=i
 check(r.build("turret",tile),"funded visual fixture actual purchase")
 for i in range(3):check(r.upgrade_building(tile),"paid original tier")
 game.selected_tile=tile;game.ui.open_context();game.full_map=false;game.focus_camera(true);update(.01)
 await capture("render-20-original-level-four")
 await click(game.ui.actions.upgrade);check(r.buildings[tile].level==5,"real upgrade button reaches L5")
 await capture("render-21-level-five-armor")
 check(game.profile.activate_item(0,m,game.match_id),"real coupon arms for eligible upgrade")
 var price=Catalog.upgrade_cost("turret",5);var oldgold=r.gold;var oldpower=r.electricity
 await click(game.ui.actions.upgrade)
 check(is_equal_approx(oldgold-r.gold,price.x*.6) and is_equal_approx(oldpower-r.electricity,price.y*.6),"actual discounted gold and power")
 for i in range(3):await click(game.ui.actions.upgrade)
 check(r.buildings[tile].level==9,"paid all advanced tiers")
 update(.01);await capture("render-22-level-nine")
 await click(game.ui.actions.upgrade);await advance(.2)
 check(r.buildings[tile].level==10 and game.ui.actions.upgrade.disabled,"L10 maximum reached through actual UI")
 check(game.ui.actions.upgrade.text=="MAX LEVEL","max indicator")
 await capture("render-23-level-ten-prestige")
 check(not r.upgrade_building(tile),"L11 rejected")
 root.size=Vector2i(960,540);await capture("render-24-prestige-small");root.size=Vector2i(1280,720)
 game.profile.update_setting("reduced_effects",true);await capture("render-25-prestige-reduced");game.profile.update_setting("reduced_effects",false)
 game.ui.close_context();m.hunter.transformed=true;m.hunter.state=HunterState.State.ATTACK;m.hunter.target=0;m.hunter.position=r.door_approach();m.hunter.cooldown=100
 m._turrets(.01);check(m.projectiles.size()>0,"real L10 projectile fires")
 update(.01);await capture("render-26-level-ten-projectile")
 check(game.audio_system.event_counts.get("prestige_upgrade",0)>0,"real max-level sound played")
 game.ui.open_context();var refund=r.building_refund(tile);oldgold=r.gold;oldpower=r.electricity
 await click(game.ui.actions.sell)
 check(not r.buildings.has(tile) and is_equal_approx(r.gold-oldgold,refund.x) and is_equal_approx(r.electricity-oldpower,refund.y),"actual L10 discounted-investment refund both resources")
 check(not r.sell_building(tile),"no second refund")
 await capture("render-27-sold-pad-reusable")
 check(r.build("heavy",tile),"sold pad reusable for Arc")
 for i in range(9):check(r.upgrade_building(tile),"paid Arc upgrade")
 game.selected_tile=tile;game.ui.open_context();update(.01);await capture("render-28-arc-prestige")
 await advance(.4)
 recording.set_recording_active(false);var mix=recording.get_recording();check(mix!=null and mix.data.size()>1000,"actual engine masterbus recording")
 if mix!=null:check(mix.save_to_wav(ProjectSettings.globalize_path(output+"render-haunted-mix.wav"))==OK,"saved actual mixer")
 for cue in ["death_scream_1","death_scream_2","hunter_laugh","reaper_laugh","weather_thunder","weather_wind","weather_rain","prestige_upgrade","survivor_notice"]:check(game.audio_system.event_counts.get(cue,0)>0,"new cue played "+cue)
 for voice in game.audio_system.voices:
  if game.audio_system._voice_names.get(voice.get_instance_id(),"").begins_with("weather_"):check(voice.bus=="Ambient","weather on saved Ambient bus")
 game.audio_system.set_mix({"music":.5,"effects":.65,"ambient":0,"muted":false})
 check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambient")) and not AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")),"saved Ambience mute leaves combat SFX bus audible")
 game.audio_system.set_mix(game.profile.settings)
 print("HAUNTED_RENDER_AUDIO=",JSON.stringify(game.audio_system.get_diagnostics()))
 print("HAUNTED_RENDER_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.5).timeout;game.queue_free();await process_frame;quit(0 if failures==0 else 1)
