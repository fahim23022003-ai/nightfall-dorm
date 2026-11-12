extends SceneTree
# Prepared real-render/action fixtures, not natural difficulty-balance evidence.
var game
var checks=0
var failures=0
var output="res://docs/evidence/difficulty/"
func _initialize(): call_deferred("run")
func check(ok: bool,label: String):
 checks+=1
 if not ok:
  failures+=1
  push_error("DIFFICULTY RENDER: "+label)
func capture(name: String):
 game.horror.update(0.25,game.model) # settle presentation-only slide without advancing combat
 game.queue_redraw()
 if is_instance_valid(game.ui.horror_layer): game.ui.horror_layer.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image()
 var code=image.save_png(ProjectSettings.globalize_path(output+name+".png"))
 print("DIFFICULTY_CAPTURE ",name," size=",image.get_size()," code=",code)
 check(code==OK,"image saved")
func button_named(name: String):
 for child in game.ui.panel.get_children():
  if child is Button and child.text==name and not child.is_queued_for_deletion(): return child
 return null
func click(button):
 check(button!=null,"button exists")
 if button==null: return
 var point=root.get_final_transform()*button.get_global_rect().get_center()
 Input.warp_mouse(point)
 for down in [true,false]:
  var event=InputEventMouseButton.new()
  event.position=point
  event.global_position=point
  event.button_index=MOUSE_BUTTON_LEFT
  event.pressed=down
  Input.parse_input_event(event)
  await process_frame
func feedback(delta: float):
 game.horror.update(delta,game.model)
 game.audio_system.update_state(delta,game.model,"match")
 game.presentation.update(delta,game.model)
 game.ui.update_match()
func run():
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://difficulty-render-"+str(Time.get_ticks_usec())+".json")
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 root.size=Vector2i(1280,720)
 game.ui.campaign.prepare("stage_1")
 await click(button_named("HELL MODE"))
 check(game.profile.selected_difficulty=="hell" and game.profile.selected_stage=="stage_1","Hell selection persists without changing stage")
 await capture("01-hell-risk-preparation")
 root.size=Vector2i(960,600)
 await process_frame
 await capture("02-hell-risk-preparation-960x540")
 root.size=Vector2i(1280,720)
 await process_frame
 await click(button_named("Start Match"))
 game.set_process(false)
 check(game.model.difficulty=="hell" and game.model.stage_id=="stage_1","actual Start Match preserves Hell and stage")
 game.model.claim_room(0)
 var room=game.model.player()
 game.model.player_position=room.bed_position()
 game.model.sleep_player()
 room.door_level=4
 room.door_hp=room.max_hp()
 room.gold=1000
 room.electricity=1000
 game.model.time=game.model.preparation+80
 var hunter=game.model.hunter
 hunter.target=0
 hunter.state=HunterState.State.MOVE
 hunter.position=room.door_approach()
 hunter.tick(0.01,game.model)
 var policy=RankCatalog.pressure("hell")
 for i in range(int(policy.charged_every)-1):
  hunter.cooldown=0
  hunter.tick(0.01,game.model)
 hunter.siege_seconds=policy.siege_ramp
 hunter.cooldown=0
 var before=room.door_hp
 var attacks=hunter.attacks
 hunter.tick(0.01,game.model)
 check(hunter.charged_ready and room.door_hp==before and hunter.attacks==attacks,"genuine charge begins without early hit")
 feedback(0.3)
 game.focus_camera(true)
 await capture("03-heavy-windup-and-threat-hud")
 root.size=Vector2i(960,600)
 await process_frame
 await capture("03b-heavy-windup-960x540")
 root.size=Vector2i(1280,720)
 await process_frame
 check(game.ui.warning_label.text.contains("HEAVY STRIKE") and game.ui.hunter_detail.text.contains("WINDUP"),"explicit warning and threat HUD show windup")
 check(not game.ui.hunter_bar.get_global_rect().intersects(game.ui.hunter_detail.get_global_rect()),"actual HP bar and damage detail rectangles do not overlap")
 hunter.tick(policy.windup*0.4,game.model)
 check(room.door_hp==before,"pre-delay tick does not apply charged hit")
 hunter.tick(policy.windup*0.61,game.model)
 check(room.door_hp<before and not hunter.charged_ready,"charged hit occurs after delay")
 feedback(0.1)
 await capture("04-charged-impact-repair-pressure")
 check(room.repair_factor<=policy.repair_floor+0.001 and game.ui.warning_label.text.contains("REPAIRS"),"siege repair floor is visibly communicated")
 var warning_font=game.ui.warning_label.get_theme_font("font")
 var warning_width=warning_font.get_string_size(game.ui.warning_label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,game.ui.warning_label.get_theme_font_size("font_size")).x
 check(warning_width<=game.ui.warning_label.size.x,"actual repair warning text fits inside its panel label")
 print("DIFFICULTY_UI_BOUNDS minimum=",game.ui.hunter_bar.get_minimum_size()," font=",game.ui.hunter_bar.get_theme_font_size("font_size")," percentage=",game.ui.hunter_bar.show_percentage," bar=",game.ui.hunter_bar.get_rect()," detail=",game.ui.hunter_detail.get_rect()," warning_text_width=",warning_width," label_width=",game.ui.warning_label.size.x)
 var healed_before=room.door_hp
 check(game.model.repair_door(),"actual repair still succeeds during siege")
 check(room.door_hp>healed_before,"weakened repair still restores HP")
 feedback(0.1)
 root.size=Vector2i(960,600)
 await process_frame
 await capture("05-repair-pressure-960x540")
 game.model.player().occupied_seconds=80
 game.model.result="defeat"
 game._process(0.0)
 await create_timer(1.4).timeout
 await capture("06-hell-defeat-retry-960x540")
 await click(button_named("Retry Stage"))
 check(game.model.difficulty=="hell" and game.model.stage_id=="stage_1" and game.mode=="match","actual Retry preserves Hell and stage")
 await capture("07-hell-retry-preserved-960x540")
 print("DIFFICULTY_RENDER_CHECKS=",checks," FAILURES=",failures)
 print("DIFFICULTY_RENDER_POLICY=",JSON.stringify(policy))
 game.audio_system.shutdown()
 await create_timer(0.3).timeout
 game.queue_free()
 await process_frame
 quit(0 if failures==0 else 1)
