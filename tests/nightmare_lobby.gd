extends SceneTree
## Deterministic controller clock, transition and audio routing.

const Lobby = preload("res://scripts/nightmare_lobby.gd")

var checks := 0
var failures := 0
var starts := 0
var cancels := 0
var cues: Array[String] = []

func _initialize():
 call_deferred("run")

func check(condition: bool, label: String):
 checks+=1
 if not condition:
  failures+=1
  push_error(label)

func open_lobby(lobby, seed: int):
 lobby.configure(StoryCatalog.mission(14),"hard","storm",seed)
 lobby.set_process(false)

func run():
 OS.set_environment("NIGHTFALL_LIVING_NIGHTMARE","1")
 var lobby:=Lobby.new()
 root.add_child(lobby)
 lobby.start_requested.connect(func(): starts+=1)
 lobby.cancel_requested.connect(func(): cancels+=1)
 lobby.cue_requested.connect(func(cue: String): cues.append(cue))
 open_lobby(lobby,98756)
 var roster:=lobby.roster()
 check(roster.size()==6 and roster[0].human and roster.count(roster[0])==1 and roster.slice(1).all(func(slot):return not slot.human),"one human and five local AIs")
 check(lobby._hunter!=null and not lobby._unknown_hunter and lobby._hunter_title==StrategyCatalog.ARCHETYPES.storm.name,"actual requested mission Hunter portrait")
 check(lobby.seconds_left()==15 and not lobby.armed,"15s first render shows timer without advancing")
 lobby.advance(2.0)
 lobby.press_ready()
 check(lobby.elapsed==0.0 and not lobby.loading,"unarmed lobby rejects timer and Ready")
 await process_frame
 await process_frame
 check(lobby.armed and cues.count("open")==1,"the first initialized view arms exactly once")
 lobby.advance(3.5)
 var staged:=lobby.roster()
 check(lobby.ready_ai_count()>0 and lobby.ready_ai_count()<5,"AIs stagger instead of appearing together")
 lobby.set_suspended(true)
 lobby.advance(7.0)
 check(lobby.elapsed==3.5 and lobby.roster()==staged,"background suspend freezes clock and roster")
 lobby.set_suspended(false)
 lobby._focus_exited()
 lobby.advance(7.0)
 lobby.press_ready()
 check(lobby.elapsed==3.5 and not lobby.loading,"window focus suspends both timer and launch")
 lobby._focus_entered()
 lobby.advance(11.499)
 check(not lobby.loading and lobby.seconds_left()==1 and starts==0,"no auto-ready before 15 seconds")
 lobby.advance(.0011)
 check(lobby.elapsed==15.0 and lobby.loading and lobby.ready_ai_count()==5 and starts==0,"15 seconds moves into queued loading exactly")
 check(cues.count("join")==5 and cues.count("ready")==1,"the deterministic roster and auto-ready cue fire once")
 lobby.advance(.419)
 check(starts==0 and lobby.loading,"loading stays visibly recoverable")
 lobby.set_suspended(true)
 lobby.advance(7.0)
 check(starts==0,"loading launch is also suspended")
 lobby.set_suspended(false)
 lobby.advance(.0011)
 check(starts==1 and not lobby.active,"launch dispatches once after the presentational delay")
 lobby.advance(20.0)
 lobby.press_ready()
 check(starts==1,"completed timer cannot double-launch")
 open_lobby(lobby,98756)
 await process_frame
 await process_frame
 lobby.advance(3.5)
 check(lobby.roster()==staged,"identical seed produces identical local roster at the same time")
 lobby.press_ready()
 check(lobby.human_ready and not lobby.loading and lobby.roster().slice(1)==staged.slice(1),"early Ready changes only the human card")
 lobby.advance(.4)
 check(not lobby.loading and starts==1,"match waits for every independently staged AI")
 lobby.advance(2.7)
 check(lobby.loading and lobby.elapsed<15.0 and lobby.ready_ai_count()==5,"once the last AI really joins an early launch is queued")
 lobby.request_cancel()
 lobby.advance(20.0)
 check(cancels==1 and starts==1 and not lobby.visible,"Back cancels an early queued launch")
 open_lobby(lobby,555)
 lobby.request_cancel()
 await process_frame
 await process_frame
 check(not lobby.armed and cancels==2 and starts==1,"cancel before readiness invalidates pending render continuation")

 var audio:=AudioDirector.new()
 root.add_child(audio)
 audio.set_mix({"music_mode":"classic","muted":false,"effects":.8})
 audio.update_state(.4,null,"menu")
 check(audio._active_score=="music_menu","normal menu begins with the menu score")
 audio.update_state(.4,null,"story_prepare")
 check(audio._active_score=="music_calm","Story preparation has a separate restrained score")
 audio.set_lobby_active(true)
 audio.update_state(.4,null,"story_lobby")
 check(audio._active_score=="music_intro","the offline roster runs a separate opening score")
 check(audio.lobby_cue("open") and audio.lobby_cue("join") and audio.lobby_cue("ready"),"existing opening sounds route through live SFX voices")
 check(audio.lobby_cue_counts.get("join",0)==1,"cue receipt counts only accepted engine audio events")
 audio.set_mix({"muted":true})
 check(not audio.lobby_cue("join"),"lobby cues respect mute")
 audio.set_mix({"music_mode":"off","muted":false})
 audio.update_state(.4,null,"menu")
 check(audio._active_score=="","lobby respects music off")
 audio.set_mix({"music_mode":"classic"})
 audio.set_lobby_active(false)
 audio.update_state(.4,null,"menu")
 check(audio._active_score=="music_menu" and not audio.lobby_cue("ready"),"leaving rejoins menu score and disables stale lobby cues")
 audio.shutdown()
 await create_timer(.25).timeout
 audio.queue_free()
 lobby.queue_free()
 await process_frame
 print("NIGHTMARE_LOBBY_CHECKS=",checks," FAILURES=",failures)
 quit(int(failures>0))
