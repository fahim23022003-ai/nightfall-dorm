extends "res://tests/replay_endless.gd"
# Inject only the second save failure; both surrounding transactions are production code.
class CloseFault extends PlayerProfile:
 var writes=0
 var fail_at=-1
 func save_profile() -> bool:
  writes+=1
  if writes==fail_at:save_ok=false;return false
  return super.save_profile()
func run():
 var a=fixture();var original=a.p;var m=a.m
 var before=original._reward_snapshot()
 check(original.end_endless_here(m).is_empty() and original._reward_snapshot()==before,"safe retirement cannot pay or close during combat")
 for wave in range(1,6):
  if wave>1:m.continue_wave("power");m.time=m.preparation+.1
  clear_wave(a)
 var p=CloseFault.new(original.path)
 check(p.load_profile() and not p.read_only,"save-fault fixture reopens actual active run")
 p.bind_items(m,a.id)
 var cash=p.rm_cash;var xp=p.xp;var stock=p.inventory.duplicate(true);var stats=p.statistics.duplicate(true)
 p.fail_at=p.writes+2
 check(p.end_endless_here(m).is_empty(),"failure after successful earned checkpoint cannot pretend retirement saved")
 check(p.rm_cash==cash+8 and p.xp==xp+20 and p.replay.milestone_wave==5 and not p.active_match.is_empty() and p.replay.checkpoint.completed==5,"failed close preserves already committed reward plus resumable checkpoint")
 var disk=PlayerProfile.new(p.path)
 check(disk.load_profile() and not disk.read_only and disk.rm_cash==cash+8 and disk.xp==xp+20 and disk.resume_endless()!=null,"fresh loader recovers actual first transaction after second save failed")
 p.fail_at=-1
 var report=p.end_endless_here(m)
 check(not report.is_empty() and report.safe_end and p.active_match.is_empty() and p.replay.checkpoint.is_empty(),"retry safely closes earned run")
 check(p.rm_cash==cash+8 and p.xp==xp+20 and p.inventory==stock and p.statistics==stats and p.pending_spins.is_empty(),"retry cannot double-award or manufacture campaign stats/items/spins")
 before=p._reward_snapshot()
 check(p.end_endless_here(m).is_empty() and p._reward_snapshot()==before,"duplicate retirement cannot pay or close twice")
 Support.cleanup(prefix)
 print("REPLAY_RETIREMENT_CHECKS=",checks," FAILURES=",failures)
 quit(0 if failures==0 else 1)
