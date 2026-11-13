extends "res://tests/replay_endless.gd"
var observations=[]
func sealed():
 var a=fixture();clear_wave(a);return a
func start(a,id):
 check(a.m.endless.omen.select(a.m,id),"accept or decline "+id)
 check(a.p.checkpoint_endless(a.m),"selected choice saves transactionally")
 var restored=a.p.resume_endless();check(restored!=null and restored.endless.omen.selected==id,"saved choice resumes unchanged")
 a.m=restored;check(a.m.continue_wave("supply"),"existing Salvage continues with Omen")
 return a.m
func mechanics():
 var normal=sealed();var blood=sealed();start(normal,"");start(blood,"blood")
 for a in [normal,blood]:a.m.tick(.1)
 check(is_equal_approx(blood.m.hunter.speed/normal.m.hunter.speed,1.12),"actual recalculated Hunter movement +12 percent")
 var power=sealed();var control=sealed()
 for a in [power,control]:check(a.m.buy("generator",Support.nearest_pad(a.m.player(),a.m.player().bed_position())),"paid Dynamo for real economy test")
 start(power,"blackout");start(control,"")
 var before=power.m.player().electricity;var other=control.m.player().electricity
 for i in range(10):power.m.tick(.1);control.m.tick(.1)
 check(is_equal_approx((power.m.player().electricity-before)/(control.m.player().electricity-other),.85),"real model Dynamo generation reduced 15 percent")
 var walls=sealed();var safe=sealed();start(walls,"walls");start(safe,"")
 var values=[]
 for a in [walls,safe]:
  var m=a.m;m.hunter.target=m.player_room;m.hunter.position=m.player().door_approach();m.hunter.state=HunterState.State.ATTACK
  values.append(m.apply_room_damage(m.player_room,20))
 check(is_equal_approx(values[0]/values[1],1.1),"Cursed Walls actual mitigated door damage +10 percent")
 check(walls.m.endless.omen.active_wave==2,"active encounter identity is exact")
func safety():
 var a=sealed();var m=start(a,"blood");var award=m.endless.omen.reward
 var disk=PlayerProfile.new(a.p.path)
 var disk_ok=disk.load_profile();var pending=disk.resume_endless() if disk_ok else null
 check(pending!=null and pending.endless.omen.selected=="blood" and pending.endless.omen.reward==award,"fresh profile disk-load restores selected Omen and exact quote")
 var gold=m.player().gold;clear_wave(a)
 # Income from the real combat tick is tracked separately from Omen payout.
 check(m.endless.omen.last.id=="blood" and m.endless.omen.last.gold==award.x,"real projectile victory pays quoted bonus")
 check(m.endless.omen.active=="" and m.endless.omen.paid_wave==2,"effect expires and wave payment seals")
 var wallet=m.player().gold;m.endless.finish_wave(m);check(m.player().gold==wallet,"duplicate completion cannot pay")
 check(a.p.checkpoint_endless(m),"completed payout and checkpoint save together")
 disk=PlayerProfile.new(a.p.path);check(disk.load_profile(),"fresh profile disk-load accepts paid Omen checkpoint")
 var resumed=disk.resume_endless();check(resumed!=null and absf(resumed.player().gold-m.player().gold)<.0000001,"completion disk reload preserves paid wallet within floating serialization precision")
 var reloaded_wallet=resumed.player().gold
 resumed.endless.finish_wave(resumed);check(resumed.player().gold==reloaded_wallet,"reload cannot duplicate Omen payout")
 check(resumed.continue_wave("power") and resumed.endless.omen.active=="","next ordinary wave has no inherited event")
 var dead=sealed();start(dead,"walls");dead.m.player().alive=false;dead.m.hunter.hp=0
 var old=dead.m.player().gold;dead.m.endless.finish_wave(dead.m)
 check(dead.m.player().gold==old and dead.m.endless.omen.paid_wave==0,"death cannot receive survival payout")
 var abandon=sealed();start(abandon,"blood");check(abandon.p.forfeit_endless(),"mid-wave forfeit succeeds")
 check(abandon.p.replay.checkpoint.is_empty() and abandon.m.endless.omen.paid_wave==0,"forfeit has no payout or resumable claim")
 var aid=sealed();start(aid,"blackout");clear_wave(aid)
 check(aid.m.continue_wave("repair"),"Reinforce still works")
 clear_wave(aid);check(aid.m.continue_wave("power"),"Recharge still works")
func compatibility():
 check(NightOmens.offered(1) and NightOmens.offered(7) and not NightOmens.offered(2),"early intermittent deterministic offers")
 for completed in range(1,100):
  if NightOmens.offered(completed) and EndlessRun.new().boss_wave(completed+1):check(false,"no offer can stack with Reaper milestone")
 check(not NightOmens.offered(4) and not NightOmens.offered(34),"known Reaper milestone windows excluded")
 for mode in ["standard","hard","hell"]:
  check(NightOmens.penalty("blood",mode)<=.12 and NightOmens.penalty("walls",mode)<=.10 and NightOmens.penalty("blackout",mode)<=.15,"mode risks bounded "+mode)
 var old=JSON.parse_string(FileAccess.get_file_as_string("res://docs/evidence/gameplay-overhaul/balance/earned-cursed_mansion.json"))
 check(not old.has("omen") and ReplaySnapshot.valid(old),"real previous wave45 snapshot remains valid")
 var restored=ReplaySnapshot.restore(old);check(restored!=null and restored.endless.omen.selected=="","old snapshot migrates to no Omen")
 var encoded=ReplaySnapshot.encode(restored);check(ReplaySnapshot.valid(encoded),"migrated checkpoint encodes valid optional state")
 encoded.omen.reward=[-1,0];check(not ReplaySnapshot.valid(encoded),"corrupt negative reward is rejected")
 var p=NightOmens.quote(restored,"blood");var e=NightOmens.quote(restored,"blackout");var w=NightOmens.quote(restored,"walls")
 observations.append({"state":"genuine earned wave45","gold_bonus":p.x,"power_bonus":e.y,"mixed":[w.x,w.y],"bed_income":restored.player().income_rate()})
 # Controlled early/mid/high budgets: actual 30-second model pressure, not
 # a natural playthrough or evidence of human difficulty preference.
 for level in [0,4,9]:
  var a=sealed();var m=a.m;var r=m.player();r.bed_level=level;r.door_level=level;r.bed_branch=StrategyCatalog.branches("bed")[0] if level>=5 else "";r.door_branch=StrategyCatalog.branches("door")[0] if level>=5 else "";r.door_hp=r.max_hp();m.buy("generator",Support.nearest_pad(r,r.bed_position()))
  var cleared={0:1,4:13,9:43}[level];m.endless.wave=cleared;m.endless.completed=cleared;m.endless.sealed_wave=cleared
  observations.append({"level":level+1,"blood_quote":NightOmens.quote(m,"blood").x,"blackout_quote":NightOmens.quote(m,"blackout").y})
  start(a,"walls");m=a.m;m.time=m.preparation+.1;m.hunter.position=m.player().door_approach();m.hunter.target=m.player_room;m.hunter.state=HunterState.State.ATTACK
  for i in range(300):
   m.tick(.1)
   if m.result!="" or m.endless.phase=="intermission":break
  observations.append({"level":level+1,"wave":m.endless.wave,"simulated_time":m.time,"door_hp":m.player().door_hp,"result":m.result,"wave_phase":m.endless.phase,"payout":m.endless.omen.paid_wave})
func run():
 mechanics();safety();compatibility()
 print("NIGHT_OMEN_OBSERVATIONS="+JSON.stringify(observations))
 print("NIGHT_OMEN_CHECKS=%d FAILURES=%d" % [checks,failures])
 quit(1 if failures else 0)
