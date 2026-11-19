extends "res://tools/capture_fair_difficulty.gd"

func run():
 output="res://docs/evidence/nightmare-hunt/"
 root.size=Vector2i(1280,720)
 var profile=PlayerProfile.new("user://nightmare-hunt-capture-"+str(Time.get_ticks_usec())+".json")
 profile.complete_tutorial()
 OS.set_environment("NIGHTFALL_PROFILE_PATH",profile.path)
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.onboarding.set_process(false)
 game.onboarding.close_welcome()
 var match_state=scenario(2,"bulwark")
 var next_decision=0.0
 while match_state.time<400 and match_state.result=="":
  if match_state.hunter.target==0 and match_state.hunter.charged_ready and match_state.ward_reason()=="":
   break
  if match_state.time>=next_decision:
   policy.act(match_state,"balanced")
   next_decision+=1
  match_state.tick(.1)
 check(match_state.hunter.charged_ready and match_state.ward_reason()=="","earned combat fixture reaches a real charged warning")
 if failures>0:
  quit(1)
  return
 await layout()
 match_state.presentation_events=match_state.presentation_events.filter(func(event):return match_state.time-event.time<=1.0)
 await capture("charged-warning")
 print("VIDEO_READY")
 if "record" in OS.get_cmdline_user_args():
  while not FileAccess.file_exists("/tmp/nightmare-hunt-record"):await process_frame
 # The clip resumes normal-speed live gameplay at the earned encounter.
 game.set_process(true)
 await key(KEY_F)
 await capture("ward-720")
 check(match_state.ward_ready_at>match_state.time,"F activated the paid ward")
 await wait(3)
 check(match_state.contribution.ward_blocked>0,"actual charged attack hit the ward")
 await wait(3)
 game.set_process(false)
 root.size=Vector2i(1920,1080)
 await layout()
 await capture("combat-1080")
 print("NIGHTMARE_HUNT_RENDER_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown()
 game.queue_free()
 await wait(.5)
 quit(1 if failures else 0)
