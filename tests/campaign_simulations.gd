extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var failures=0
 var wins=0
 var losses=0
 var count=0
 for stage in StageCatalog.STAGES:
  for difficulty in ["standard","hard"]:
   for strategy in ["balanced","passive"]:
    var model=MatchModel.new()
    model.reset(7)
    model.configure_match(difficulty)
    model.configure_stage(stage.id)
    model.claim_room(1)
    var room=model.player()
    model.player_position=room.bed_position()
    model.sleep_player()
    room.profile=strategy
    var steps=0
    while model.result=="" and steps<12000:
     if strategy!="passive": BotAI.tick(room,0.1)
     model.tick(0.1)
     steps+=1
    count+=1
    if model.result=="victory": wins+=1
    elif model.result=="defeat": losses+=1
    else: failures+=1
    if room.gold<0 or room.electricity<0 or not is_finite(room.gold): failures+=1
    print("CAMPAIGN_SIM stage=",stage.id," difficulty=",difficulty," strategy=",strategy," result=",model.result," time=",snappedf(model.time,0.1)," shots=",model.shots)
 print("CAMPAIGN_SIMULATIONS=",count," WINS=",wins," LOSSES=",losses," UNRESOLVED=",failures)
 if wins==0 or losses==0: failures+=1
 quit(1 if failures else 0)
