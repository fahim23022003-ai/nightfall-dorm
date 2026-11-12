extends SceneTree
var checks=0
var failures=0
func check(ok: bool,label: String):
 checks+=1
 if not ok:
  failures+=1
  push_error("DIFFICULTY QA: "+label)
func _initialize(): call_deferred("run")
func fixture(difficulty: String,stage_id="stage_1"):
 var model=MatchModel.new()
 model.configure_match(difficulty)
 model.configure_stage(stage_id)
 model.claim_room(0)
 var room=model.player()
 model.player_position=room.bed_position()
 model.sleep_player()
 model.time=model.preparation
 model.hunter.target=0
 model.hunter.state=HunterState.State.ATTACK
 model.hunter.position=room.door_approach()
 return model
func events(model,kind): return model.presentation_events.filter(func(e):return e.type==kind)
func click_button(button):
 var point=root.get_final_transform()*button.get_global_rect().get_center()
 for pressed in [true,false]:
  var e=InputEventMouseButton.new()
  e.position=point
  e.global_position=point
  e.button_index=MOUSE_BUTTON_LEFT
  e.pressed=pressed
  Input.parse_input_event(e)
  await process_frame
func run():
 check(RankCatalog.DIFFICULTIES.has("hell"),"Hell profile exists")
 if not RankCatalog.DIFFICULTIES.has("hell"): quit(1); return
 var profiles=[]
 for difficulty in ["standard","hard","hell"]:
  var model=fixture(difficulty)
  var room=model.player()
  check(model.hunter.choose_target(model.rooms)==0,"target selection only occupied living sleeping rooms")
  var previous=room.door_hp
  var alive=room.alive
  model.hunter.tick(0.01,model)
  check(room.door_hp<=previous and room.alive==alive,"door attack cannot damage survivor behind intact door")
  var attacks=model.hunter.attacks
  for i in range(4): model.hunter.tick(0.01,model)
  check(model.hunter.attacks<=attacks+1,"attack cooldown prevents frame spam")
  model.hunter.cooldown=999
  model.time=model.preparation+180
  model.hunter.tick(0.01,model)
  var late_pressure=model.hunter.damage/model.hunter.interval
  check(is_finite(late_pressure) and late_pressure>0,"late pressure finite")
  var early=fixture(difficulty)
  early.hunter.cooldown=999
  early.hunter.tick(0.01,early)
  check(late_pressure>early.hunter.damage/early.hunter.interval,"controlled late escalation increases pressure")
  profiles.append({"difficulty":difficulty,"early":early.hunter.damage/early.hunter.interval,"late":late_pressure})
  for stage in StageCatalog.STAGES:
   var match_model=fixture(difficulty,stage.id)
   var r=match_model.player()
   var h=match_model.hunter
   var start=h.position
   var old=r.door_hp
   # An interrupted attack must reacquire its real doorway before damage.
   h.position=match_model.map_data.hunter_spawn
   h.cooldown=0
   h.tick(0.05,match_model)
   check(r.door_hp==old,"displaced attack cannot hit door remotely "+difficulty+stage.id)
   h.position=start
   h.state=HunterState.State.ATTACK
   r.door_hp=1
   h.cooldown=0
   for step in range(150):
    h.tick(0.05,match_model)
    if r.door_hp<=0: break
   check(r.door_hp==0 and r.alive,"broken door still requires physical breach to eliminate")
   check(events(match_model,"door_break").size()==1,"one real break event per door")
   h.state=HunterState.State.BREACH
   h.position=r.bed_position()
   h.tick(0.01,match_model)
   check(not r.alive,"physical breach can eliminate survivor")
 for difficulty in ["hard","hell"]:
  var opening=fixture(difficulty)
  opening.hunter.encounter_attacks=int(RankCatalog.pressure(difficulty).charged_every)-1
  opening.hunter.tick(0.01,opening)
  check(events(opening,"charged_attack").is_empty(),"opening grace has no unprepared charged attacks")
  check(opening.player().repair_factor==1,"opening grace preserves full repairs")
 for difficulty in ["hard","hell"]:
  var charged=fixture(difficulty)
  var room=charged.player()
  charged.time+=float(RankCatalog.pressure(difficulty).get("opening",0))+1
  room.door_level=4
  room.door_hp=room.max_hp()
  var announced=false
  for step in range(300):
   charged.time+=0.05
   charged.hunter.tick(0.05,charged)
   if not events(charged,"charged_attack").is_empty(): announced=true; break
  check(announced,"dangerous attack is telegraphed "+difficulty)
  if announced:
   var warning=events(charged,"charged_attack").back()
   var attacks=charged.hunter.attacks
   var health=room.door_hp
   var delay=float(warning.delay)
   check(delay>=0.5,"charged attack gives meaningful reaction time")
   charged.time+=delay*0.4
   charged.hunter.tick(delay*0.4,charged)
   check(charged.hunter.attacks==attacks and room.door_hp==health,"windup cannot strike early")
   check(events(charged,"charged_attack").size()==1,"windup warning not repeated per frame")
   for step in range(40):
    charged.time+=0.05
    charged.hunter.tick(0.05,charged)
    if charged.hunter.attacks>attacks: break
   check(charged.hunter.attacks==attacks+1,"windup resolves one stronger physical hit")
   check(room.door_hp<health and room.alive,"charged attack obeys intact door barrier")
 for difficulty in ["standard","hard","hell"]:
  var siege=fixture(difficulty)
  var room=siege.player()
  room.door_level=4
  room.door_hp=100
  room.gold=1000
  siege.time+=float(RankCatalog.pressure(difficulty).get("opening",0))+100
  siege.hunter.cooldown=999
  siege.hunter.siege_seconds=100
  siege.hunter.tick(0.01,siege)
  check(room.repair_factor>0 and room.repair_factor<=1,"repair pressure remains bounded with counterplay")
  check(room.repair_factor==1 if difficulty=="standard" else room.repair_factor<1,"difficulty-specific repair pressure activates only advanced modes")
  var previous=room.door_hp
  check(room.repair_door(),"paid repair remains available under siege")
  check(is_equal_approx(room.door_hp-previous,Catalog.REPAIR_HEAL*room.repair_factor),"manual repair applies communicated siege factor")
  siege.hunter.state=HunterState.State.MOVE
  siege.hunter.tick(0.01,siege)
  check(room.repair_factor==1,"leaving the siege restores repair effectiveness")
 for difficulty in ["hard","hell"]:
  var held=fixture(difficulty)
  var room=held.player()
  room.door_level=4
  room.door_hp=room.max_hp()
  held.hunter.cooldown=999
  held.hunter.siege_start_hp=room.door_hp
  var pressure=RankCatalog.pressure(difficulty)
  held.time+=float(pressure.opening)+20
  var duration=maxf(float(pressure.commit),Catalog.HUNTER_ESCALATION.minimum_commitment)*2+5
  for step in range(ceili(duration/0.25)):
   held.time+=0.25
   held.hunter.tick(0.25,held)
   if held.hunter.siege_seconds>float(pressure.siege_ramp)+1:
    check(is_equal_approx(room.repair_factor,float(pressure.repair_floor)),"continuous siege keeps repair floor through target reassessment")
  check(held.hunter.target==0 and held.hunter.state==HunterState.State.ATTACK,"single valid room retains actual siege")
  check(held.hunter.siege_seconds>=duration-0.5,"reassessment never resets continuous siege clock")
 check(profiles[1].late>profiles[0].late,"Long Night late pressure exceeds Normal")
 check(profiles[2].late>profiles[1].late,"Hell late pressure exceeds Long Night")
 var save="user://difficulty-qa-"+str(Time.get_ticks_usec())+".json"
 var profile=PlayerProfile.new(save)
 check(profile.select_stage("stage_1"),"select existing stage")
 check(profile.equip("pocket"),"existing unlocked perk usable")
 check(profile.select_difficulty("hell"),"Hell difficulty can be selected and saved")
 check(profile.selected_stage=="stage_1" and profile.equipped==["pocket"],"difficulty switch preserves stage and loadout")
 var loaded=PlayerProfile.new(save)
 check(loaded.load_profile() and loaded.selected_difficulty=="hell" and loaded.equipped==["pocket"] and loaded.selected_stage=="stage_1","fresh profile preserves Hell stage and perk")
 check(not profile.equip("marksman"),"locked perk remains blocked")
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://difficulty-ui-"+str(Time.get_ticks_usec())+".json")
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.profile.equip("pocket")
 game.ui.campaign.prepare("stage_1")
 await process_frame
 var hell_button: Button
 for node in game.ui.panel.get_children():
  if node is Button and not node.is_queued_for_deletion() and node.text.to_upper().contains("HELL"): hell_button=node
 check(hell_button!=null,"Hell choice exists in actual preparation UI")
 if hell_button!=null:
  await click_button(hell_button)
  check(game.profile.selected_difficulty=="hell" and game.profile.selected_stage=="stage_1" and game.profile.equipped==["pocket"],"actual Hell click preserves stage/perk and persists mode")
  var start_button: Button
  for node in game.ui.panel.get_children():
   if node is Button and not node.is_queued_for_deletion() and node.text=="Start Match": start_button=node
  check(start_button!=null,"campaign Start Match remains available")
  if start_button!=null:
   await click_button(start_button)
   check(game.model.difficulty=="hell" and game.model.stage_id=="stage_1" and game.mode=="match","actual UI starts correct Hell stage")
   game.model.claim_room(0)
   check(game.model.player().gold==30,"existing selected perk affects actual Hell match")
 game.audio_system.shutdown()
 await create_timer(0.5).timeout
 game.queue_free()
 await process_frame
 print("DIFFICULTY_PRESSURE ",JSON.stringify(profiles))
 print("DIFFICULTY_BEHAVIOR_CHECKS=%d FAILURES=%d" % [checks,failures])
 quit(0 if failures==0 else 1)
