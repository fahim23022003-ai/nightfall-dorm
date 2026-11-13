extends SceneTree
var checks=0
var failures=0
func check(ok,message):
 checks+=1
 if not ok:failures+=1;push_error(message)
func actors(points,ids=[1,2,3]):
 var result=[]
 for i in range(points.size()):result.append({"index":ids[i],"point":points[i],"name":"Test %d" % ids[i],"priority":2})
 return result
func _initialize():call_deferred("run")
func run():
 var p=load("res://scripts/dorm_presentation.gd").new()
 var sparse=actors([Vector2.ZERO,Vector2(150,0),Vector2(300,0)])
 check(p.adaptive_allies(sparse)==sparse,"sparse labels retain existing individual names")
 var dense=actors([Vector2.ZERO,Vector2(8,0),Vector2(15,0)])
 p.clock=.1;p.adaptive_allies(dense);p.clock=.3
 check(p.adaptive_allies(dense).size()==3,"brief overlap does not immediately group")
 p.clock=.5;var labels=p.adaptive_allies(dense)
 check(labels.size()==1 and labels[0].name=="ALLIES ×3","sustained overlap uses accurate compact count")
 check(labels==p.adaptive_allies(dense),"repeat redraws cannot change display mode")
 var edge=actors([Vector2.ZERO,Vector2(70,0),Vector2(80,0)])
 p.clock=.6;check(p.adaptive_allies(edge).size()==1,"separate leave radius prevents boundary flicker")
 var important=dense.duplicate(true);important[1].priority=1
 labels=p.adaptive_allies(important)
 check(labels.any(func(a):return a.index==2 and not a.get("group",false)),"threatened individual identity always has priority")
 p.clock=.7;p.adaptive_allies(sparse);p.clock=1.2
 check(p.adaptive_allies(sparse).size()==1,"short separation does not flash back to names")
 p.clock=1.6;check(p.adaptive_allies(sparse)==sparse,"sustained separation restores individual names")
 p.reset();p.clock=0;var pair=actors([Vector2.ZERO,Vector2(20,0)],[1,2]);p.adaptive_allies(pair);p.clock=1
 check(p.adaptive_allies(pair)==pair,"two short-lane names remain individual")
 p.reset();p.clock=0;var long_pair=actors([Vector2.ZERO,Vector2(20,0)],[4,5]);p.adaptive_allies(long_pair);p.clock=.4
 check(p.adaptive_allies(long_pair)[0].name=="ALLIES ×2","two excessively long identity lanes can group")
 p.reset();p.clock=0;p.adaptive_allies(dense);p.clock=.2;p.adaptive_allies(sparse);p.clock=1
 check(p.adaptive_allies(sparse)==sparse,"transient overlap never activates stale group")
 p.reset();check(p.ally_group.is_empty() and p.ally_pending.is_empty(),"display state resets between matches")
 var source="res://docs/evidence/gameplay-overhaul/balance/earned-cursed_mansion.json"
 var before=FileAccess.get_sha256(source);var checkpoint=JSON.parse_string(FileAccess.get_file_as_string(source))
 check(checkpoint.rooms.filter(func(r):return r.owner>0 and r.alive).size()==0,"wave45 really contains zero living AI allies")
 check(checkpoint.rooms.filter(func(r):return r.owner>0 and not r.alive and r.buildings.size()>0).size()==5,"eliminated ally buildings intentionally remain in checkpoint")
 check(FileAccess.get_sha256(source)==before,"earned checkpoint is unchanged")
 var path="user://adaptive-visual-"+str(Time.get_ticks_usec())+".json"
 var profile=PlayerProfile.new(path);profile.tutorial_completed=true;profile.save_profile();OS.set_environment("NIGHTFALL_PROFILE_PATH",path)
 var saved=FileAccess.get_file_as_bytes(path)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);await process_frame
 game.onboarding.close_welcome();game.start_practice("crusher",false,[],"abandoned_dorm");game.set_process(false);game.ui.close_context();await create_timer(.3).timeout
 game.model.hunter.target=game.model.player_room;game.model.hunter.state=HunterState.State.ATTACK
 game.ui.feedback_until=game.presentation.clock+5;game.ui.feedback_text="Defense improved!";game.ui.help_open=false;game.ui.update_match()
 check(game.ui.warning_box.visible and not game.ui.guide_box.visible,"door warning outranks automatic positive feedback")
 game.ui.feedback_text="Not enough Gold";game.ui.update_match()
 check(game.ui.guide_box.visible,"failed-action feedback remains accessible during siege")
 game.ui.feedback_text="Defense improved!";game.ui.help_open=true;game.ui.update_match()
 check(game.ui.guide_box.visible,"explicitly requested Help remains visible during siege")
 check(FileAccess.get_file_as_bytes(path)==saved,"display-priority changes preserve isolated saved profile")
 game.audio_system.shutdown();game.queue_free();await create_timer(.3).timeout
 print("ADAPTIVE_READABILITY_CHECKS=%d FAILURES=%d" % [checks,failures])
 quit(1 if failures else 0)
