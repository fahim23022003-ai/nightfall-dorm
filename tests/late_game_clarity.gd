extends SceneTree
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("LATE CLARITY "+label)
func _initialize():call_deferred("run")
func run():
 var path="user://late-clarity-"+str(Time.get_ticks_usec())+".json"
 var profile=PlayerProfile.new(path);profile.tutorial_completed=true;profile.save_profile()
 OS.set_environment("NIGHTFALL_PROFILE_PATH",path)
 var saved=FileAccess.get_file_as_bytes(path)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);await process_frame
 game.onboarding.close_welcome();game.start_practice("crusher",false,[],"abandoned_dorm");game.set_process(false);await process_frame
 var m=game.model;var r=m.player()
 var corridor=r.corridor_anchor()
 for room in m.rooms:
  if room.index==r.index:continue
  room.owner=room.index;room.alive=true;room.sleeping=false;room.resident_position=corridor+Vector2(90+(room.index%3)*7,3*(room.index%2))
 m.hunter.target=2;m.hunter.state=HunterState.State.ATTACK;m.hunter.position=r.door_approach()
 game.ui.close_context();game.ui.teammates.expanded=false;game.focus_camera(true)
 await create_timer(.35).timeout
 var timings=[]
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;await process_frame
  for reduced in [false,true]:
   game.profile.settings.reduced_effects=reduced
   var gold=r.gold;var hp=r.door_hp;var rng=m.random.state
   var labels=game.presentation.resident_label_layout(game)
   check(labels.size()==5,"all five crowded arrivals identified "+str(resolution)+str(reduced))
   check(labels[0].index==2,"threatened teammate receives priority")
   check(labels==game.presentation.resident_label_layout(game),"stationary layout is stable and clock independent")
   check(labels.all(func(a):return a.name=="%02d · %s" % [a.index+1,m.rooms[a.index].survivor_name()]),"actual names and room IDs")
   var disjoint=true
   for a in range(labels.size()):
    for b in range(a+1,labels.size()):
     if labels[a].rect.intersects(labels[b].rect):disjoint=false
   check(disjoint,"crowded name rectangles never overlap")
   check(r.gold==gold and r.door_hp==hp and m.random.state==rng,"layout does not change economy health or random sequence")
   var begin=Time.get_ticks_usec()
   for i in range(1000):game.presentation.resident_label_layout(game)
   timings.append({"resolution":str(resolution),"reduced":reduced,"layout_calls":1000,"microseconds":Time.get_ticks_usec()-begin})
 game.watched_room=4
 var labels=game.presentation.resident_label_layout(game)
 check(not labels.is_empty() and labels[0].index==4,"observed teammate wins priority")
 game.watched_room=-1
 game.ui.context_open=true
 labels=game.presentation.resident_label_layout(game)
 var canvas=game.get_canvas_transform()
 check(labels.all(func(a):return (canvas*a.rect.end).y<=430),"open upgrade area protected")
 game.ui.context_open=false;game.ui.teammates.expanded=true
 labels=game.presentation.resident_label_layout(game)
 check(labels.all(func(a):return (canvas*a.rect.end).x<=915),"open teammate area protected")
 game.ui.teammates.expanded=false
 for room in m.rooms:
  if room.owner>0:room.sleeping=true
 check(game.presentation.resident_label_layout(game).is_empty(),"sleeping names use existing room plaques and Team roster")
 game.ui.teammates.update()
 check(game.ui.teammates.rows[0].text.contains(m.rooms[1].survivor_name()),"full identity remains in real existing Team inspection")
 check(FileAccess.get_file_as_bytes(path)==saved,"isolated saved profile bytes preserved")
 print("LATE_CLARITY_LAYOUT_TIMINGS="+JSON.stringify(timings))
 print("LATE_CLARITY_CHECKS=%d FAILURES=%d" % [checks,failures])
 game.audio_system.shutdown();game.queue_free();await create_timer(.3).timeout
 quit(1 if failures else 0)
