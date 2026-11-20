extends SceneTree

var checks:=0
var failures:=0
var audio: AudioDirector
var model: MatchModel

func _initialize() -> void:
 call_deferred("run")

func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(message)

func advance(seconds: float,mode: String="match") -> void:
 for _step in range(roundi(seconds/.1)):
  audio.update_state(.1,model,mode)

func heartbeat_count() -> int:
 return audio.event_counts.get(AudioDirector.HEARTBEAT_CUE,0)

func settle_score(score: String,duration: float=2.0,mode: String="match") -> void:
 advance(duration,mode)
 check(audio.soundtrack.current==score and audio.loop_weights[score]>.7,"route and mix reach "+score)
 var music_count:=0
 for key in audio.loops:
  if key.begins_with("music") and audio.loops[key].playing:
   music_count+=1
 check(music_count<=2,"only one current and one outgoing score are permitted")

func run() -> void:
 OS.set_environment("NIGHTFALL_LIVING_NIGHTMARE","1")
 audio=AudioDirector.new()
 root.add_child(audio)
 var nodes:=audio.get_child_count()
 audio.set_mix({"music_mode":"classic","music":.75,"effects":.7})
 check(audio.missing_assets.is_empty() and audio.music_start_count==0,"all assets decode without starting the silent music library")
 check(audio.heartbeat.stream.get_length()>4.8 and audio.heartbeat.stream.get_length()<=5.0,"sampled heartbeat fits five seconds")
 model=MatchModel.new()
 check(model.configure_match("hell"),"Hell fixture difficulty")
 check(model.claim_room(0),"normal player room claim")
 model.player_position=model.player().bed_position()
 check(model.sleep_player(),"normal bed closes the player door")
 var room:=model.player()
 settle_score("music_menu",2,"menu")
 settle_score("music_calm")
 check(audio.loop_weights.music_menu<=.001 and not audio.loops.music_menu.playing,"menu score leaves actual playback after the match begins")

 model.time=model.preparation+1
 model.hunter.state=HunterState.State.MOVE
 model.hunter.target=room.index
 model.hunter.position=room.door_approach()+Vector2(120,0)
 settle_score("music_approach",5.0)
 check(heartbeat_count()==0,"nearby approach alone never triggers the heartbeat")
 var npc: RoomState=model.rooms[1]
 npc.owner=1
 npc.sleeping=true
 npc.closed=true
 model.hunter.state=HunterState.State.ATTACK
 model.hunter.target=npc.index
 model.hunter.position=npc.door_approach()
 advance(.2)
 check(heartbeat_count()==0,"NPC door siege never triggers the heartbeat")
 model.hunter.target=room.index
 advance(.2)
 check(heartbeat_count()==0,"stale attack state away from own door cannot trigger the heartbeat")
 model.hunter.state=HunterState.State.MOVE
 model.hunter.position=room.door_approach()
 model.hunter.tick(.05,model)
 check(model.hunter.state==HunterState.State.ATTACK,"production Hunter enters the live door attack state")
 advance(.1)
 check(heartbeat_count()==1 and audio.heartbeat.playing and audio.heartbeat.remaining>4.8,"exactly one heartbeat begins on the real door encounter")
 advance(1.0)
 check(audio.music_duck<=.56 and audio.soundtrack.current=="music_danger","first siege has its own composition and heartbeat duck")
 var pause_remaining:=audio.heartbeat.remaining
 model.running=false
 advance(1.0)
 check(audio.heartbeat.stream_paused and is_equal_approx(audio.heartbeat.remaining,pause_remaining),"Pause freezes actual heartbeat playback and its timer")
 model.running=true
 advance(4.1)
 check(audio.heartbeat.remaining==0.0 and not audio.heartbeat.playing,"heartbeat ends rather than looping through combat")
 # Room stays in direct siege while multiple hits occur.
 model.record_event("door_damage",room.index,{"hp":room.door_hp-10.0,"max_hp":room.max_hp(),"damage":10.0,"attacker_id":1,"attack_archetype":"stalker","attack_boss":false})
 advance(.1)
 check(audio.event_counts.get("cinematic_stalker_release",0)==1,"landed Stalker contact emits the captured family release")
 model.record_event("door_damage",room.index,{"hp":room.door_hp,"max_hp":room.max_hp(),"damage":0.0,"attacker_id":1,"attack_archetype":"stalker","attack_boss":false})
 advance(1.0)
 check(audio.event_counts.get("cinematic_stalker_release",0)==1,"blocked contact has no claw release layer")
 audio.stop_events(AudioDirector.CRITICAL_EVENTS)
 advance(.5)
 check(audio.music_duck>=.95,"background volume recovers when the heartbeat and ordinary critical cues are over")
 advance(44.0)
 check(heartbeat_count()==1 and audio.soundtrack.current=="music_siege","sustained siege escalates the arrangement with no repeat heartbeat")
 model.hunter.state=HunterState.State.MOVE
 advance(2.0)
 model.hunter.state=HunterState.State.ATTACK
 advance(.2)
 check(heartbeat_count()==1,"brief departure cannot retrigger after the cooldown elapsed")
 model.hunter.state=HunterState.State.RECOVER
 settle_score("music_hall")
 advance(7.0)
 model.hunter.state=HunterState.State.ATTACK
 advance(.3)
 check(heartbeat_count()==2,"a genuinely separate attack can play again after both limits")
 model.hunter.state=HunterState.State.RETREAT
 advance(10.0)
 model.hunter.state=HunterState.State.ATTACK
 advance(.3)
 check(heartbeat_count()==2,"separate encounter inside 45 seconds is suppressed")
 model.hunter.state=HunterState.State.RETREAT
 advance(50.0)
 audio.set_mix({"effects":0.0})
 model.hunter.state=HunterState.State.ATTACK
 advance(.3)
 check(heartbeat_count()==2 and AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")),"effects-zero preserves silence at a valid new encounter")
 audio.set_mix({"effects":.7})
 advance(.8)
 check(heartbeat_count()==2,"unmute does not replay a missed encounter")
 model.hunter.state=HunterState.State.MOVE
 model.hunter.position=room.door_approach()+Vector2(1300,0)
 settle_score("music_hell",5.0)

 model.hunter.transformed=true
 model.hunter.state=HunterState.State.TRANSFORM
 settle_score("music_reaper")
 model.wrath.domain_room=0
 model.wrath.domain_remaining=20
 settle_score("music_crimson")
 check(audio.crimson_music_starts==1,"Crimson activates once and outranks the Reaper score")
 model.result="victory"
 settle_score("music_victory",2.0,"result")
 check(audio.loop_weights.music_menu<=.001,"results use their own score instead of the menu")
 model.result="defeat"
 settle_score("music_defeat",2.0,"result")
 check(audio.streams.music_defeat.loop_mode==AudioStreamWAV.LOOP_DISABLED,"result composition is a one-shot")
 audio.set_mix({"music_mode":"off"})
 advance(.2,"result")
 check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")),"Off mutes the actual Music bus")
 audio.preview_track("music_hall")
 advance(.2,"menu")
 check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")) and audio.loops.music_hall.playing,"explicit audition works under Music Off")
 audio.stop_preview()

 model.result=""
 model.hunter.transformed=false
 model.wrath.domain_remaining=0
 model.hunter.state=HunterState.State.DORMANT
 model.time=0
 audio.set_mix({"music_mode":"manual","manual_track":"music_portrait"})
 advance(3.0)
 check(audio.soundtrack.manual=="music_portrait" and audio.soundtrack.current in Soundtrack.ADAPTIVE_FAMILIES.music_calm,"saved menu-only manual preference is preserved without becoming the gameplay track")
 audio.set_mix({"manual_track":"music_siege"})
 advance(2.0)
 check(audio.soundtrack.current=="music_siege","an eligible manual gameplay score still plays in quiet gameplay")

 var endless:=MatchModel.new()
 check(endless.configure_endless("abandoned_dorm","standard",71,987),"ordinary Endless fixture")
 endless.time=endless.preparation+1
 endless.hunter.state=HunterState.State.MOVE
 endless.hunter.position=Vector2(2400,1900)
 model=endless
 audio.set_mix({"music_mode":"classic"})
 settle_score("music_endless")
 check(audio.get_child_count()==nodes,"audio transitions reuse the same node pool")
 var history_path: String="user://test-living-nonrepeat.json"
 DirAccess.remove_absolute(history_path)
 DirAccess.remove_absolute(history_path+".bak")
 var bag:=Soundtrack.new(history_path,true)
 var last:=""
 for _index in range(12):
  var drawn:=bag.draw("music_menu")
  check(drawn!=last,"adaptive menu bag never immediately repeats across refill")
  last=drawn
 var reloaded:=Soundtrack.new(history_path,true)
 check(reloaded.history.last.get("music_menu","")==last and reloaded.history.bags==bag.history.bags,"adaptive playlist and last composition survive a reload")
 check(reloaded.draw("music_menu")!=last,"adaptive bag reload has no immediate repetition")

 audio.shutdown()
 audio.update_state(.1,model,"menu")
 check(audio.streams.is_empty() and not audio.heartbeat.playing,"terminal shutdown cannot resume score or heartbeat")
 audio.queue_free()
 model=null
 await create_timer(.4).timeout
 print("LIVING_NIGHTMARE_AUDIO_CHECKS=",checks," FAILURES=",failures)
 quit(int(failures!=0))
