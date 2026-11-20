extends SceneTree
## Boot an isolated embedded pack and prove the preview enters a real Story match.

var checks := 0
var failures := 0

func _initialize():
 call_deferred("run")

func check(ok: bool, label: String):
 checks+=1
 if not ok:
  failures+=1
  push_error(label)

func run():
 var entry_count:=0
 for level in range(1,51):
  var mission:=StoryCatalog.mission(level)
  check(mission.get("level")==level and not StageCatalog.stage(mission.stage_id).is_empty(),"embedded mission %d" % level)
  if not mission.is_empty():entry_count+=1
 for type in ["stalker","ravager","reaper_approach","reaper_transformed"]:
  for view in ["front","back","left","right"]:
   var atlas:=load("res://assets/visual_rebirth/articulated/%s_%s.png" % [type,view]) as Texture2D
   check(atlas!=null and atlas.get_width()>0,"embedded %s %s atlas" % [type,view])
 for score in ["music_hall","music_hell","music_victory","music_defeat","siege_heartbeat"]:
  var stream:=load("res://assets/audio/%s.wav" % score) as AudioStreamWAV
  check(stream!=null and stream.get_length()>0.0,"embedded "+score)
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 check(game.story_preview_enabled,"preview flag enabled through launcher")
 check(game.profile.save_ok and StoryProgress.valid(game.profile.story),"real isolated Story profile created")
 check(game.profile.complete_tutorial(),"leave first-run tutorial via profile test fixture")
 if is_instance_valid(game.onboarding):game.onboarding.close_welcome()
 check(game.start_story("standard"),"Continue Story starts the existing match runtime")
 check(game.model.story_level==1 and game.model.map_data.get("version")==2,"Story uses V2 generation")
 check(game.model.map_seed==StoryProgress.seed_for(game.profile.story,1),"the profile seed reaches the game model")
 check(game.model.claim_room(0),"regular room claim")
 check(game.model.player().spatial!=null and game.model.player().spatial.grid,"real Full Room Grid")
 check(entry_count==50 and not game.model.hunter.transformed,"valid intro and final task catalog")
 game.audio_system.shutdown()
 game.queue_free()
 await process_frame
 print("LIVING_NIGHTMARE_PACK_CHECKS=",checks," FAILURES=",failures," NATIVE_WINDOWS=UNVERIFIED")
 quit(int(failures>0))
