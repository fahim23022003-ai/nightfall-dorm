extends "res://tools/capture_phase5d4_core.gd"
var listening=[]
func run():
 output="res://docs/evidence/phase5d4/";phase="core-render";await setup_game();game.return_menu();game.set_process(false)
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;var suffix=str(resolution.y);game.ui.show_settings();await advance(.15);await click(find_button("Audio listening room"));await advance(.15)
  check(game.ui.current_screen=="audio_test","real Settings opens Listening Room")
  await click(find_button("Music"));await advance(.15);await capture("listening-eight-music-"+suffix)
  for id in ["music_intro","music_menu","music_calm","music_approach","music_danger","music_reaper","music_endless","music_crimson"]:
   await click(find_button(id.trim_prefix("music_").capitalize()+" · score"));await advance(.25)
   check(game.audio_system.preview_music==id and game.audio_system.loops[id].playing,"actual music preview "+id)
   listening.append({"resolution":suffix,"id":id,"duration":game.audio_system.streams[id].get_length(),"selected":game.audio_system.preview_music})
  await click(find_button("Voices"));await advance(.15);await capture("listening-voices-"+suffix)
  for id in ["death_scream_1","hunter_laugh","reaper_laugh","intro_breath","reaper_charge"]:
   await click(find_button(id.replace("_"," ").capitalize()));await advance(.1)
   check(game.audio_system.preview_effect_name==id and game.audio_system.voices.any(func(v):return v.playing and game.audio_system._voice_names.get(v.get_instance_id(),"")==id),"actual voice preview "+id)
  await click(find_button("Action SFX"));await advance(.15)
  var groups=game.audio_system.sfx_preview_groups();check(groups.size()==4,"fouractual actiongroups")
  for group in groups:
   await click(find_button(group));await advance(.12);await capture("listening-action-"+group.to_lower().replace(" ","-")+"-"+suffix)
   for id in groups[group]:
    var before=int(game.audio_system.event_counts.get(id,0));await click(find_button(id.replace("_"," ").capitalize()));await advance(.12)
    check(game.audio_system.preview_effect_name==id and int(game.audio_system.event_counts.get(id,0))>before,"actual action preview "+id)
  await click(find_button("Stop audition"));await advance(.1);check(game.audio_system.preview_music=="" and game.audio_system.preview_effect_name=="","actual Stop clears allpreviews")
  await click(find_button("Back to settings"));await advance(.1);check(game.ui.current_screen=="settings","actual audioBack restores settings")
 var f=FileAccess.open("res://docs/evidence/phase5d4/core-listening-result.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"music":listening,"fixture":"Actual GUIinput and liveAudioDirector preview selection on LinuxDummy; no PCM/humanqualityclaim fromthis menu gate."}," "))
 print("PHASE5D4_CORE_LISTENING_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;quit(1 if failures else 0)
