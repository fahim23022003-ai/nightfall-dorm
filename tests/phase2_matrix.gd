extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var failures=0
 var count=0
 var wins=0
 var losses=0
 for mode in ["standard","hard"]:
  var active_wins=0
  var passive_wins=0
  var highest_level=1
  for rank in range(6):
   for strategy in ["passive","balanced"]:
    for seed_value in [7,8]:
     var model=MatchModel.new()
     model.reset(seed_value)
     var perk=RankCatalog.PERKS[rank].id
     model.configure_match(mode,RankCatalog.bonuses([perk]))
     model.claim_room(seed_value%6)
     var room=model.player()
     room.profile="balanced"
     model.player_position=room.bed_position()
     model.sleep_player()
     for i in range(18000):
      if model.result!="": break
      if strategy=="balanced": BotAI.tick(room,0.1)
      model.tick(0.1)
     count+=1
     highest_level=maxi(highest_level,model.hunter.level)
     if model.result=="victory":
      wins+=1
      if strategy=="balanced": active_wins+=1
      else: passive_wins+=1
     elif model.result=="defeat": losses+=1
     else: failures+=1
     if room.gold< -0.0001 or room.electricity< -0.0001 or not is_finite(room.gold): failures+=1
     var points=RankCatalog.performance(model)
     if points.total>425 or points.total<0 or (model.result=="defeat" and points.total>80): failures+=1
     print("PHASE2_MATRIX mode=",mode," rank=",RankCatalog.NAMES[rank]," perk=",perk," strategy=",strategy," seed=",seed_value," result=",model.result," time=",snappedf(model.time,0.1)," hunter_level=",model.hunter.level," xp=",points.total," player_damage=",snappedf(room.damage_dealt,0.1)," door_damage_taken=",snappedf(room.door_damage_taken,0.1)," occupied_seconds=",snappedf(room.occupied_seconds,0.1)," rescue_used=",room.rescue_used)
  print("PHASE2_MATRIX_SUMMARY mode=",mode," active_wins=",active_wins," passive_wins=",passive_wins," matches=24 highest_level=",highest_level)
 if wins==0 or losses==0: failures+=1
 print("PHASE2_MATRIX_MATCHES=",count," WINS=",wins," LOSSES=",losses," FAILURES=",failures)
 quit(1 if failures else 0)
