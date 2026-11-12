extends SceneTree
# Prepared production-method fixtures for actual Godot rendering and mixed audio.
# Resource/health/time setup is intentional and is not natural-match balance evidence.
var game
var record: AudioEffectRecord
var checks=0
var failures=0
var output="res://docs/evidence/boss/"
func _initialize(): call_deferred("run")
func check(ok: bool,label: String):
 checks+=1
 if not ok: failures+=1; push_error("BOSS RENDER: "+label)
func feedback(delta):
 game.horror.update(delta,game.model)
 game.audio_system.update_state(delta,game.model,game.mode)
 game.presentation.update(delta,game.model)
 game.ui.update_match()
 game.queue_redraw()
 if is_instance_valid(game.ui.horror_layer): game.ui.horror_layer.queue_redraw()
func advance(seconds):
 var start=Time.get_ticks_usec()
 var before=start
 while Time.get_ticks_usec()-start<seconds*1000000:
  await process_frame
  var now=Time.get_ticks_usec()
  feedback((now-before)/1000000.0)
  before=now
func capture(name):
 feedback(0)
 await process_frame
 await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image()
 var code=image.save_png(ProjectSettings.globalize_path(output+name+".png"))
 print("BOSS_CAPTURE ",name," size=",image.get_size()," code=",code)
 check(code==OK,"saved "+name)
func click(button):
 check(button!=null,"button exists")
 if button==null:return
 var point=root.get_final_transform()*button.get_global_rect().get_center()
 for pressed in [true,false]:
  var e=InputEventMouseButton.new()
  e.position=point
  e.global_position=point
  e.button_index=MOUSE_BUTTON_LEFT
  e.pressed=pressed
  Input.parse_input_event(e)
  await process_frame
func button_named(text):
 for child in game.ui.panel.get_children():
  if child is Button and child.text==text and not child.is_queued_for_deletion(): return child
 return null
func fixture(stage_id="stage_5"):
 check(game.start_stage(stage_id,"hell"),"real stage starts "+stage_id)
 game.set_process(false)
 game.tutorial_enabled=false
 var m=game.model
 m.claim_room(0)
 var r=m.player()
 m.player_position=r.bed_position()
 m.sleep_player()
 r.gold=10000
 r.electricity=10000
 r.door_level=4
 r.door_hp=r.max_hp()
 m.bot_claimed=5
 m.time=m.preparation+100
 var h=m.hunter
 h.target=0
 h.state=HunterState.State.ATTACK
 h.position=r.door_approach()
 h.cooldown=100
 h.boss_policy.enabled=false
 h.tick(0.01,m)
 h.boss_policy.enabled=true # Introductory map compatibility fixture only.
 for tile in range(r.tile_count()):
  if r.tile_position(tile).distance_to(h.position)<=Catalog.BUILDINGS.turret.range and r.buildings.size()<3:
   r.build("turret",tile)
 game.focus_camera(true)
 feedback(0)
 return h
func warn(kind):
 var h=game.model.hunter
 h.boss_cooldowns={"scythe":100.0,"siege":100.0,"surge":100.0}
 h.boss_cooldowns[kind]=0
 h.cancel_boss_attack()
 h.cooldown=0
 var hp=game.model.player().door_hp
 h.tick(0.01,game.model)
 check(h.boss_attack==kind and game.model.player().door_hp==hp,"real warning before damage "+kind)
 feedback(0.01)
func check_text():
 var label=game.ui.warning_label
 var font=label.get_theme_font("font")
 var width=font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x
 print("BOSS_WARNING_WIDTH text=",label.text," width=",width," available=",label.size.x)
 check(width<=label.size.x,"warning fits")
 for notice in game.horror.notifications:
  var extent=game.horror.font.get_string_size(notice.text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
  print("BOSS_NOTICE_WIDTH text=",notice.text," width=",extent)
  check(extent<=370,"notification fits")
func run():
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://boss-render-"+str(Time.get_ticks_usec())+".json")
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 root.size=Vector2i(1280,720)
 # Unlock the isolated audit campaign with eligible prepared wins through settlement.
 for stage in StageCatalog.STAGES:
  check(game.start_stage(stage.id,"hell"),"unlock fixture starts")
  game.model.claim_room(0)
  game.model.player_position=game.model.player().bed_position()
  game.model.sleep_player()
  game.model.time=game.model.preparation+40
  game.model.player().occupied_seconds=40
  game.model.hunter.state=HunterState.State.ATTACK
  game.model.hunter.hurt(1000000)
  game.model.result="victory"
  game._process(0)
 game.return_menu()
 game.ui.campaign.prepare("stage_5")
 await capture("render-01-preparation")
 record=AudioEffectRecord.new()
 AudioServer.add_bus_effect(0,record)
 record.set_recording_active(true)
 var h=fixture()
 await capture("render-02-normal-hunter")
 var hp=h.hp
 var max_hp=h.max_hp
 h.hp=h.max_hp*.5
 hp=h.hp
 h.tick(.01,game.model)
 check(h.state==HunterState.State.TRANSFORM and h.hp==hp and h.max_hp==max_hp,"real transform no HP grant")
 feedback(.01)
 h.tick(1.0,game.model)
 await advance(.3)
 await capture("render-03-transformation")
 root.size=Vector2i(960,600)
 await process_frame
 await capture("render-04-transformation-960x540")
 root.size=Vector2i(1280,720)
 h.tick(1.5,game.model)
 h.tick(.01,game.model)
 h.position=game.model.player().door_approach()
 h.state=HunterState.State.ATTACK
 h.target=0
 await advance(3.5)
 check(game.audio_system.loop_weights.music_reaper>.8 and game.audio_system.music_start_count==4,"boss music crossfades with no restart")
 await capture("render-05-reaper-awakened")
 for attack in ["scythe","siege","surge"]:
  warn(attack)
  var before=game.model.player().door_hp
  var delay=BossCatalog.ATTACKS[attack].windup
  h.tick(delay*.4,game.model)
  check(game.model.player().door_hp==before,"windup still nondamaging "+attack)
  await advance(.3)
  check_text()
  await capture("render-06-"+attack+"-warning")
  h.tick(delay*.61,game.model)
  if attack=="surge": check(h.surge_remaining>0 and game.model.player().door_hp==before,"surge activates without door damage")
  else: check(game.model.player().door_hp<before,"real impact "+attack)
  await advance(.1)
  await capture("render-07-"+attack+"-impact")
 root.size=Vector2i(960,600)
 await process_frame
 check_text()
 await capture("render-08-silence-960x540")
 root.size=Vector2i(1280,720)
 h.hurt(20)
 await capture("render-09-hurt")
 h.hurt(1000000)
 feedback(.05)
 await advance(.55)
 await capture("render-10-death")
 game.model.tick(.01)
 game._process(0)
 await advance(1.5)
 check(game.model.result=="victory" and game.audio_system.loop_weights.music_reaper==0 and game.audio_system.loop_weights.reaper_ambience==0,"death produces victory and fades boss music/ambience")
 await capture("render-11-victory")
 for stage in StageCatalog.STAGES:
  h=fixture(stage.id)
  h.hp=h.max_hp*.5
  h.tick(.01,game.model)
  h.tick(2.5,game.model)
  h.tick(.01,game.model)
  await advance(3.5)
  await capture("render-12-"+stage.map)
 # Defeat/retry must return the fresh Hunter state through the actual result button.
 game.model.player().alive=false
 game.model.tick(.01)
 game._process(0)
 await advance(1.4)
 await capture("render-13-defeat-retry")
 await click(button_named("Retry Stage"))
 check(game.mode=="match" and not game.model.hunter.transformed and game.model.hunter.surge_remaining==0 and game.model.stage_id=="stage_5","real Retry resets boss state and preserves stage")
 await advance(1)
 await capture("render-14-retry-normal")
 check(game.audio_system.music_start_count==4,"all captures/retries retain permanent music players")
 record.set_recording_active(false)
 var mix=record.get_recording()
 check(mix!=null and mix.data.size()>1000,"actual engine mixed PCM recorded")
 if mix!=null:
  var code=mix.save_to_wav(ProjectSettings.globalize_path(output+"render-engine-mix.wav"))
  check(code==OK,"mixed PCM saved")
  print("BOSS_ENGINE_MIX_BYTES=",mix.data.size())
 print("BOSS_RENDER_AUDIO=",JSON.stringify(game.audio_system.get_diagnostics()))
 print("BOSS_RENDER_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown()
 await create_timer(.2).timeout
 game.queue_free()
 await process_frame
 quit(0 if failures==0 else 1)
