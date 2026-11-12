extends SceneTree
# Prepared isolated profile/match fixtures; screenshots are real engine renders.
# Injected XP/time/HP are not naturally played matches or pacing evidence.
var game
var checks=0
var failures=0
var output="res://docs/evidence/ranks/"
func _initialize(): call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok: failures+=1; push_error("RANK RENDER: "+label)
func capture(name):
 game.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 var result=root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output+name+".png"))
 check(result==OK,"saved "+name)
 print("RANK_CAPTURE ",name)
func advance(seconds):
 var start=Time.get_ticks_usec()
 var previous=start
 while Time.get_ticks_usec()-start<seconds*1000000:
  await process_frame
  var now=Time.get_ticks_usec()
  game.audio_system.update_state((now-previous)/1000000.0,game.model,game.mode)
  previous=now
func button_named(text):
 for child in game.ui.panel.get_children():
  if child is Button and child.text==text and not child.is_queued_for_deletion(): return child
 return null
func click(button):
 check(button!=null,"button exists")
 if button==null:return
 var point=root.get_final_transform()*button.get_global_rect().get_center()
 for pressed in [true,false]:
  var event=InputEventMouseButton.new()
  event.position=point
  event.global_position=point
  event.button_index=MOUSE_BUTTON_LEFT
  event.pressed=pressed
  Input.parse_input_event(event)
  await process_frame
func complete_stage(id,won=true):
 check(game.start_stage(id,"hard"),"starts "+id)
 game.set_process(false)
 var model=game.model
 model.claim_room(0)
 model.player_position=model.player().bed_position()
 model.sleep_player()
 model.time=model.preparation+130
 model.player().occupied_seconds=130
 model.player().damage_dealt=1200
 model.hunter.state=HunterState.State.ATTACK
 model.hunter.transformed=id!="stage_1"
 if won:model.hunter.hurt(1000000)
 else:model.player().alive=false
 model.tick(.01)
 game._process(0)
 check(game.mode=="result","settles result")
func run():
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://rank-render-"+str(Time.get_ticks_usec())+".json")
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 root.size=Vector2i(1280,720)
 game.ui.progression.show_ranks()
 await advance(.3)
 var badges=game.ui.panel.get_children().filter(func(n): return n is TextureRect and n.position.y==180)
 check(badges.size()==7,"seven loaded badge illustrations")
 var large=game.ui.panel.get_children().filter(func(n): return n is TextureRect and n.position==Vector2(86,62))[0]
 var shade=large.modulate
 await advance(.5)
 check(large.modulate!=shade,"actual rank badge pulse animates")
 await capture("render-01-bronze-ranks")
 root.size=Vector2i(960,540)
 await process_frame
 await capture("render-02-bronze-ranks-small")
 root.size=Vector2i(1280,720)
 game.profile.xp=8000
 game.profile.highest_rank=5
 game.ui.progression.show_ranks()
 check(game.profile.rank_index()==5,"XP alone cannot grant Mythic")
 await capture("render-03-master-gates-locked")
 game.profile.xp=0
 for stage in ["stage_1","stage_2","stage_3","stage_4"]:
  complete_stage(stage)
  await advance(.1)
 game.return_menu()
 game.profile.xp=7990
 check(game.profile.rank_index()==5,"stage5 gate still pending")
 game.ui.progression.show_ranks()
 await capture("render-04-master-final-stage-needed")
 var record=AudioEffectRecord.new()
 AudioServer.add_bus_effect(0,record)
 record.set_recording_active(true)
 complete_stage("stage_5")
 await advance(1.15)
 check(game.profile.rank_index()==6,"actual settlement grants Mythic")
 check(game.last_progression.promoted,"actual promotion report")
 for child in game.ui.panel.get_children():
  if child is Label and child.position.x==434:
   for line in child.text.split("\n"):
    check(child.get_theme_font("font").get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,child.get_theme_font_size("font_size")).x<=415,"promotion text fits")
 await capture("render-05-mythic-promotion")
 await advance(1.5)
 await capture("render-06-mythic-result")
 root.size=Vector2i(960,540)
 await process_frame
 await capture("render-07-mythic-result-small")
 root.size=Vector2i(1280,720)
 await click(button_named("Stage Select"))
 game.ui.progression.show_ranks()
 await advance(.3)
 await capture("render-08-mythic-ranks")
 root.size=Vector2i(960,540)
 await process_frame
 await capture("render-09-mythic-ranks-small")
 root.size=Vector2i(1280,720)
 game.return_menu()
 await process_frame
 await process_frame
 for child in game.ui.panel.get_children():
  if child is Label and child.position==Vector2(430,519):
   check(child.get_rect().end.x<=654.1,"menu requirement fits its column after deferred resize")
 await capture("render-10-mythic-menu")
 game.ui.campaign.prepare("stage_5")
 await capture("render-11-mythic-loadout")
 complete_stage("stage_5",false)
 await advance(1.2)
 await capture("render-12-defeat-breakdown")
 await click(button_named("Retry Stage"))
 check(game.mode=="match" and game.profile.rank_index()==6,"retry preserves prestige")
 await capture("render-13-retry-preserves-rank")
 record.set_recording_active(false)
 var mix=record.get_recording()
 check(mix!=null and mix.data.size()>1000,"actual engine mix exists")
 if mix!=null: check(mix.save_to_wav(ProjectSettings.globalize_path(output+"render-promotion-mix.wav"))==OK,"saved engine mix")
 check(game.audio_system.event_counts.get("mythic_promotion",0)==1,"actual unique promotion sound once")
 print("RANK_RENDER_AUDIO=",JSON.stringify(game.audio_system.get_diagnostics()))
 print("RANK_RENDER_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown()
 await create_timer(.3).timeout
 game.queue_free()
 await process_frame
 quit(0 if failures==0 else 1)
