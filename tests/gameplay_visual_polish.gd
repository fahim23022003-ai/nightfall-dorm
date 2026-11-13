extends SceneTree
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("GAMEPLAY VISUAL "+label)
func click(point):
 point=root.get_final_transform()*point
 var move=InputEventMouseMotion.new();move.position=point;Input.parse_input_event(move);await process_frame
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;Input.parse_input_event(event);await process_frame
func _initialize():call_deferred("run")
func run():
 var path="user://visual-polish-"+str(Time.get_ticks_usec())+".json";var profile=PlayerProfile.new(path);profile.tutorial_completed=true;profile.save_profile();OS.set_environment("NIGHTFALL_PROFILE_PATH",path)
 var original=FileAccess.get_file_as_bytes(path)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);await process_frame;game.onboarding.close_welcome();await process_frame
 for reduced in [false,true]:
  game.profile.settings.reduced_effects=reduced
  game.start_practice("crusher",false,[],"abandoned_dorm");await process_frame
  var m=game.model;var r=m.player();var tile=0
  while r.buildings.has(tile):tile+=1
  game.selected_tile=tile;check(m.buy("generator",tile),"actual machine purchase")
  game.ui.close_context();await create_timer(.3).timeout;game.focus_camera(true)
  game.presentation.update(.01,m)
  await click(game.world_to_screen(r.tile_position(tile)));await create_timer(.3).timeout
  check(game.selected_tile==tile and game.ui.context_mode=="upgrade" and game.ui.context_open,"real building selection retains existing flow")
  game.ui.update_match()
  var gold=r.gold;var power=r.electricity;var cost=Catalog.upgrade_cost("generator",1)
  await click(game.ui.actions.upgrade.get_global_rect().get_center());game.presentation.update(.01,m)
  check(r.buildings[tile].level==2 and is_equal_approx(gold-r.gold,cost.x) and is_equal_approx(power-r.electricity,cost.y),"upgrade still spends exact existing resources")
  var pulses=game.presentation.visual_events.filter(func(e):return e.kind in ["level","prestige"] and e.position==r.tile_position(tile))
  check(pulses.size()==1,"successful upgrade reuses one positive event")
  var duration=pulses[0].life if not pulses.is_empty() else 0.0;r.gold=0;r.electricity=0
  check(not m.upgrade_building(tile),"unaffordable upgrade rejected")
  game.presentation.update(.1,m)
  pulses=game.presentation.visual_events.filter(func(e):return e.kind in ["level","prestige"] and e.position==r.tile_position(tile))
  check(pulses.size()==1 and pulses[0].life<duration,"failed upgrade does not restart recent success pulse")
  m.hunter.target=r.index;m.hunter.position=r.door_approach();m.hunter.state=HunterState.State.ATTACK;m.time=m.preparation+1
  game.horror.reset();var hp=r.door_hp;var total=0.0
  for attack in [[10.0,"physical"],[8.0,"magic"],[5.0,"physical"]]:total+=m.apply_room_damage(r.index,attack[0],"visual test",1,false,{"type":attack[1],"element":"neutral"})
  game.horror.update(.01,m)
  check(is_equal_approx(hp-r.door_hp,total) and total>0,"actual typed damage and health are unchanged")
  check(game.horror.damage_numbers.size()==2,"simultaneous types use distinct bounded lanes")
  check(game.horror.damage_numbers.any(func(n):return n.damage_type=="physical" and is_equal_approx(n.damage,15)),"physical aggregation remains type-consistent")
  check(game.horror.damage_numbers.any(func(n):return n.damage_type=="magic" and is_equal_approx(n.damage,8)),"magic aggregation remains type-consistent")
  check(game.horror.door_impacts.has(r.index),"existing local door impact still occurs")
  var random=m.random.state;hp=r.door_hp;var state=r.gold;game.presentation.update(.01,m);game.horror.update(.01,m)
  check(m.random.state==random and r.door_hp==hp and r.gold==state,"presentation does not mutate model or RNG")
  game.horror.update(1.2,m);check(game.horror.damage_numbers.is_empty(),"existing feedback expiry cleans both typed lanes")
  for index in range(6):
   var target=m.rooms[index];target.owner=index;target.sleeping=true;target.closed=true;target.door_hp=target.max_hp();m.hunter.target=index;m.hunter.position=target.door_approach()
   for type in ["physical","magic"]:m.apply_room_damage(index,1,"bounded fixture",1,false,{"type":type,"element":"neutral"})
  game.horror.update(0,m);check(game.horror.damage_numbers.size()==game.horror.MAX_NUMBERS,"six rooms with both damage types remain bounded at twelve")
 for index in [0,3]:
  game.start_practice("witch",false,[],"underground_lab");await process_frame
  var m=game.model;var room=m.rooms[index];room.owner=index;room.closed=true;room.sleeping=true
  game.watched_room=index if index!=m.player_room else -1;m.hunter.target=index;m.hunter.position=room.door_approach();m.hunter.state=HunterState.State.ATTACK;game.focus_camera(true)
  var hp_rect=Rect2(game.MAP_OFFSET+room.door_position()+Vector2(-39,30),Vector2(80,46))
  var body=Rect2(game.MAP_OFFSET+m.hunter.position+Vector2(-40,-85),Vector2(80,105));var prior=Rect2()
  for type in ["physical","magic"]:
   var layout=game.horror.damage_number_geometry(game,{"room":index,"damage_type":type,"position":room.door_position(),"damage":22.0,"age":.5})
   var canvas=game.get_canvas_transform();var screen=Rect2(canvas*layout.rect.position,layout.rect.size*canvas.get_scale())
   check(screen.position.y>=149 and screen.end.y<=645 and screen.position.x>=11 and screen.end.x<=1269,"sideways door typed cue stays inside safe screen")
   check(not layout.rect.intersects(hp_rect) and not layout.rect.intersects(body),"sideways cue avoids HP readout and Hunter")
   if prior.size!=Vector2.ZERO:check(not layout.rect.intersects(prior),"sideways physical and magic lanes do not overlap")
   prior=layout.rect
 var endless=MatchModel.new();check(endless.configure_endless("abandoned_dorm","standard",17,999),"existing Endless configuration")
 endless.claim_room(0);endless.player_position=endless.player().bed_position();endless.sleep_player()
 var room=endless.player();room.gold=100000;room.electricity=100000
 for i in range(4):room.upgrade_bed();room.upgrade_door()
 for i in range(7):check(endless.expansion.purchase(endless),"existing expansion purchase")
 check(room.tile_count()==16,"sixteen-slot expansion progression unchanged")
 endless.hunter.hp=0;endless.hunter.state=HunterState.State.DEAD;endless.endless.finish_wave(endless)
 var saved=ReplaySnapshot.encode(endless);check(not saved.is_empty() and ReplaySnapshot.valid(saved),"existing checkpoint compatibility")
 var restored=ReplaySnapshot.restore(JSON.parse_string(JSON.stringify(saved)));check(restored!=null and restored.player().tile_count()==16,"existing checkpoint round-trip")
 check(FileAccess.get_file_as_bytes(path)==original,"player profile bytes untouched")
 game.audio_system.shutdown();await create_timer(.55).timeout;game.queue_free();await process_frame
 print("GAMEPLAY_VISUAL_POLISH_CHECKS=%d FAILURES=%d" % [checks,failures]);quit(1 if failures else 0)
