extends SceneTree
var checks=0
var failures=0
var audio
func _initialize(): call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok: failures+=1; push_error("BOSS AUDIO: "+label)
func update(model,seconds,mode="match"):
 for i in range(ceili(seconds/.1)):
  audio.update_state(.1,model,mode)
  await process_frame
func run():
 audio=AudioDirector.new()
 root.add_child(audio)
 await process_frame
 for name in ["music_reaper","reaper_ambience","reaper_transform","reaper_scythe","reaper_charge","reaper_surge","reaper_impact","reaper_hurt","reaper_death"]:
  check(audio.streams.has(name),"asset imports "+name)
  if not audio.streams.has(name):continue
  var stream=audio.streams[name]
  check(stream.format==AudioStreamWAV.FORMAT_16_BITS,"PCM import "+name)
  check(stream.get_length()>.1,"playable length "+name)
 var m=MatchModel.new()
 m.configure_match("hell")
 m.configure_stage("stage_5")
 m.claim_room(0)
 var r=m.player()
 m.player_position=r.bed_position()
 m.sleep_player()
 m.time=m.preparation+100
 r.door_level=4
 r.door_hp=r.max_hp()
 r.gold=10000
 r.electricity=10000
 var h=m.hunter
 h.state=HunterState.State.ATTACK
 h.target=0
 h.position=r.door_approach()
 h.hp=h.max_hp*.5
 audio.reset_match(m)
 h.tick(.01,m)
 await update(m,.3)
 check(audio.event_counts.get("reaper_transform",0)==1,"actual transformation cue once")
 check(audio.loop_weights.music_reaper>0,"music enters during transformation")
 var starts=audio.music_start_count
 await update(m,2)
 check(audio.music_start_count==starts and audio.loop_weights.music_reaper>.8,"boss mix settles without restarts")
 check(audio.loop_weights.music_calm==0 and audio.loop_weights.music_danger==0,"other match scores fade out")
 check(audio.loop_weights.reaper_ambience>0,"nearby boss ambience active")
 h.tick(2.5,m)
 h.tick(.01,m)
 h.position=r.door_approach()
 h.state=HunterState.State.ATTACK
 for tile in range(r.tile_count()):
  if r.tile_position(tile).distance_to(h.position)<=Catalog.BUILDINGS.turret.range and r.buildings.size()<2:r.build("turret",tile)
 for attack in ["scythe","siege","surge"]:
  h.cancel_boss_attack()
  h.cooldown=0
  h.boss_cooldowns={"scythe":100.0,"siege":100.0,"surge":100.0}
  h.boss_cooldowns[attack]=0
  h.tick(.01,m)
  await update(m,.3)
  var cue={"scythe":"reaper_scythe","siege":"reaper_charge","surge":"reaper_surge"}[attack]
  check(audio.event_counts.get(cue,0)==1,"actual warning sound "+attack)
  h.tick(BossCatalog.ATTACKS[attack].windup+.01,m)
  await update(m,2)
 check(audio.event_counts.get("reaper_impact",0)>=2,"both damaging impacts sound")
 var mix=audio.loop_weights.duplicate()
 audio.set_suspended(true)
 audio.update_state(5,m,"match")
 check(audio.loop_weights==mix,"pause freezes audio mix")
 audio.set_suspended(false)
 m._combat_event("impact",{"id":1,"room":0,"kind":"turret","level":1},h.position,5)
 await update(m,.3)
 check(audio.event_counts.get("reaper_hurt",0)==1,"actual combat observer uses boss hurt")
 h.hurt(1000000)
 m.tick(.01)
 await update(m,2,"result")
 check(audio.event_counts.get("reaper_death",0)==1,"death event plus snapshot play only once")
 check(audio.loop_weights.music_reaper==0 and audio.loop_weights.reaper_ambience==0,"terminal clears boss score and danger ambience")
 for cue in audio._pending_critical:check(cue.name not in ["reaper_transform","reaper_charge","reaper_surge"],"terminal warning queue clear")
 m.reset()
 audio.reset_match(m)
 await update(m,1)
 check(audio.music_start_count==starts and audio.loop_weights.music_reaper==0,"retry has no stale score or restart")
 check(audio.missing_assets.is_empty(),"no missing audio")
 print("BOSS_AUDIO_CHECKS=",checks," FAILURES=",failures," EVENTS=",JSON.stringify(audio.event_counts))
 audio.shutdown()
 await create_timer(.3).timeout
 audio.queue_free()
 await process_frame
 quit(0 if failures==0 else 1)
