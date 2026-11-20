extends SceneTree

var director: AudioDirector
var tests := 0
var failures := 0

func _initialize():
 call_deferred("run")

func check(ok: bool,label: String):
 tests+=1
 if ok:return
 failures+=1
 push_error("PHASE16 AMBIENCE: "+label)

func settle(model: MatchModel):
 director.reset_match(model)
 for unused in range(60):
  director.update_state(.1,model,"match")

func run():
 OS.set_environment("NIGHTFALL_LIVING_NIGHTMARE","1")
 OS.set_environment("NIGHTFALL_PHASE16","1")
 director=AudioDirector.new()
 root.add_child(director)
 var model := MatchModel.new()
 for chapter in [1,2,3,7,10]:
  model.story_level=(chapter-1)*StoryCatalog.CHAPTER_LENGTH+1
  director.set_mix({"music_mode":"classic"})
  settle(model)
  check(director.soundtrack.current==AudioDirector.STORY_CALM_SCORES[chapter-1],"chapter %d score during preparation" % chapter)
  check(director.loops[director.soundtrack.current].playing,"original prerecorded score plays")
 director.set_mix({"music_mode":"manual","manual_track":"music_dust"})
 settle(model)
 check(director.soundtrack.family=="music_calm" and director.soundtrack.current=="music_dust","manual preference retains calm routing")
 director.set_mix({"music_mode":"off"})
 settle(model)
 check(director.soundtrack.current.is_empty(),"off mutes original chapter track")
 director.set_mix({"music_mode":"classic"})
 model.story_level=0
 settle(model)
 check(director.soundtrack.current=="music_calm","legacy Campaign preparation retains ordinary score")
 model.story_level=1
 model.time=model.preparation+10
 model.hunter.state=HunterState.State.RECOVER
 settle(model)
 check(director.soundtrack.current=="music_hall","Hall recovery has original priority")
 model.hunter.transformed=true
 model.hunter.state=HunterState.State.TRANSFORM
 settle(model)
 check(director.soundtrack.current=="music_reaper","Reaper has original priority")
 model.result="defeat"
 settle(model)
 check(director.soundtrack.current=="music_defeat","defeat keeps original ending score")

 director.shutdown()
 director.queue_free()
 await process_frame
 print("PHASE16_STORY_AMBIENCE_CHECKS=",tests," FAILURES=",failures)
 quit(int(failures>0))
