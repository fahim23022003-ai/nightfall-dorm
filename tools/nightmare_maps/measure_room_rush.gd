extends SceneTree
## Deterministic idle-human race telemetry. Gameplay clocks are advanced in
## quarter-second steps with the Hunter and economy excluded from the timing.

func _initialize() -> void:
 OS.set_environment("NIGHTFALL_SURVIVOR_REBIRTH","1")
 var failures:=0
 var families: Dictionary={}
 for index in range(35):
  var theme: String=MapCatalog.IDS[index%5]
  var seed:=147+index*283
  if index>=30:
   while NightmareMacroLayout.family_for(theme,seed)!="spine":
    seed+=1
  var sample:=measure(theme,seed,11+index)
  if not sample.started or sample.fifth<0.0 or sample.nearest_seconds>12.0:
   failures+=1
  if sample.started:families[sample.family]=true
  print("RUSH_SAMPLE ",JSON.stringify(sample))
 if families.size()!=NightmareMacroLayout.FAMILY_IDS.size():
  failures+=1
 print("SURVIVOR_RUSH_MATRIX seeds=35 families=",families.size()," failures=",failures)
 quit(int(failures>0))

func measure(theme: String, seed: int, nonce: int) -> Dictionary:
 var model:=MatchModel.new()
 model.procedural_v2_requested=true
 model.reset(seed)
 var ready:=model.configure_map(theme)
 var start:=Time.get_ticks_usec()
 var started:=ready and model.begin_room_rush(nonce)
 var init_ms: float=(Time.get_ticks_usec()-start)/1000.0
 var origin:=model.room_rush_spawn()
 var nearest: float=model.room_rush.nearest_room_distance(origin,model.room_rush.routes_to_vacant_rooms(model,origin))/model.SURVIVOR_SPEED if started else -1.0
 var stamps:=[-1.0,-1.0,-1.0,-1.0,-1.0]
 var previous:=0
 while started and model.time<160.0 and model.bot_claimed<5:
  model.time+=.25
  model.room_rush.tick(model,.25)
  if model.bot_claimed>previous:
   for claimed in range(previous,model.bot_claimed):stamps[claimed]=model.time
   previous=model.bot_claimed
 return {
  "theme":theme,"family":model.map_data.get("family",""),"seed":seed,"nonce":nonce,
  "started":started,"init_ms":init_ms,"nearest_seconds":nearest,
  "first":stamps[0],"third":stamps[2],"fifth":stamps[4],
 }
