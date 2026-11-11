extends SceneTree
# Host CPU simulation benchmark; this is not an Android renderer/FPS benchmark.
func _initialize(): call_deferred("run")
func run():
 var steps=0
 var micros=0
 var maximum=0
 var peak_shots=0
 var wins=0
 var losses=0
 var unresolved=0
 for difficulty in ["standard","hard"]:
  for index in range(6):
   var model=MatchModel.new()
   model.configure_match(difficulty)
   model.random.seed=7+index
   model.claim_room(index)
   var room=model.player()
   model.player_position=room.bed_position()
   model.sleep_player()
   room.profile="balanced"
   var ticks=0
   while model.result=="" and ticks<12000:
    var start=Time.get_ticks_usec()
    BotAI.tick(room,0.05)
    model.tick(0.05)
    var spent=Time.get_ticks_usec()-start
    micros+=spent
    maximum=maxi(maximum,spent)
    peak_shots=maxi(peak_shots,model.projectiles.size())
    ticks+=1
    steps+=1
   if model.result=="victory": wins+=1
   elif model.result=="defeat": losses+=1
   else: unresolved+=1
 print("HOST_SIM_PROFILE ",JSON.stringify({"host":"Linux headless; NOT Android performance","matches":12,"wins":wins,"losses":losses,"unresolved":unresolved,"simulation_steps":steps,"mean_step_us":float(micros)/steps,"worst_step_us":maximum,"peak_projectiles":peak_shots,"projectile_limit":Catalog.PROJECTILES.max_active,"static_memory_bytes":OS.get_static_memory_usage()}))
 quit(1 if unresolved else 0)
