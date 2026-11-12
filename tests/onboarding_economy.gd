extends SceneTree
# Deterministic currency-rule scenarios; synthetic performance inputs, not human win rates.
var failures=0
var checks=0
func _initialize():call_deferred("run")
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("ONBOARDING ECONOMY: "+label)
func fixture(mode,seconds,win):
 var m=MatchModel.new();m.configure_match(mode)
 m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player()
 m.time=m.preparation+seconds;m.player().occupied_seconds=seconds;m.player().damage_dealt=1000;m.player().door_damage_taken=200
 m.result="victory" if win else "defeat"
 if win:m.hunter.hp=0;m.hunter.state=HunterState.State.DEAD
 else:m.player().alive=false;m.player().sleeping=false
 return m
func run():
 var rows=[];var means={}
 for mode in ["standard","hard","hell"]:
  for seconds in [1.0,20.0,60.0,89.0,90.0,180.0,600.0]:
   for win in [false,true]:
    var m=fixture(mode,seconds,win);var rng=RandomNumberGenerator.new();rng.seed=5151
    var total=0;var low=1000000;var high=0
    for i in range(1000):
     var award=OnboardingCatalog.cash_reward(m,rng);total+=award;low=mini(low,award);high=maxi(high,award)
     check(award>=0 and award<=64,"bounded award")
     if (not win and seconds<90) or seconds<20:check(award==0,"no instant-loss or unqualified cash")
    var row={"mode":mode,"occupied_seconds":seconds,"victory":win,"draws":1000,"mean":total/1000.0,"minimum":low,"maximum":high,"cash_per_occupied_minute":total/1000.0*60/seconds}
    rows.append(row);print("RM_SCENARIO ",JSON.stringify(row))
    if seconds==180:means[mode+str(win)]=total/1000.0
 for mode in ["standard","hard","hell"]:
  check(means[mode+"true"]>means[mode+"false"]*3,"victory expected reward substantially higher "+mode)
 check(means.helltrue>means.hardtrue and means.hardtrue>means.standardtrue,"difficulty raises victory reward")
 for mode in ["standard","hard","hell"]:
  var m=fixture(mode,180,false);m.player().damage_dealt=0;m.player().door_damage_taken=0
  var rng=RandomNumberGenerator.new();rng.seed=25
  check(OnboardingCatalog.cash_reward(m,rng)==0,"idle death no participation reward")
  m=fixture(mode,180,true);m.tutorial_mode=true
  check(OnboardingCatalog.cash_reward(m,rng)==0,"tutorial never cash")
  m.tutorial_mode=false;m.hunter.hp=1
  check(OnboardingCatalog.cash_reward(m,rng)==0,"fictional victory no cash")
  m=fixture(mode,180,false);m.player().alive=true
  check(OnboardingCatalog.cash_reward(m,rng)==0,"unresolved living defeat no cash")
 var output=FileAccess.open("res://docs/evidence/onboarding/economy-results.json",FileAccess.WRITE)
 output.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows}," "));output.close()
 print("ONBOARDING_ECONOMY_CHECKS=",checks," SCENARIOS=",rows.size()," FAILURES=",failures)
 quit(0 if failures==0 else 1)
