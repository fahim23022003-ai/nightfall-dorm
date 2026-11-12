extends SceneTree
# Reusable earned-resource diagnostic. Original pre-change capture is documented
# in DIFFICULTY_BASELINE.md; reruns use whichever production tuning is installed.
func _initialize(): call_deferred("run")
func empty(room,kind):
 for tile in range(room.tile_count()):
  if not room.buildings.has(tile): return room.build(kind,tile)
 return false
func count(room,kind):
 var n=0
 for b in room.buildings.values():
  if b.kind==kind: n+=1
 return n
func act(room,strategy):
 if strategy=="minimal": return
 if room.door_hp<room.max_hp()*0.35 and (room.upgrade_door() or room.repair_door()): return
 if room.bed_level<1:
  room.upgrade_bed()
  return
 if room.door_level<1:
  room.upgrade_door()
  return
 if strategy=="turret_rush" and count(room,"turret")<5:
  empty(room,"turret")
  return
 if not BotAI.has_kind(room,"generator"):
  empty(room,"generator")
  return
 if room.bed_level<2:
  room.upgrade_bed()
  return
 if strategy=="door" and room.door_level<4:
  if room.bed_level<maxi(0,room.door_level-1): room.upgrade_bed()
  else: room.upgrade_door()
  return
 if room.door_level<2:
  room.upgrade_door()
  return
 if strategy=="economy_stack" and count(room,"economy")<4:
  empty(room,"economy")
  return
 if room.buildings.size()<room.tile_count():
  empty(room,"turret")
  return
 for tile in room.buildings:
  if room.buildings[tile].kind=="turret" and room.buildings[tile].level<4:
   room.upgrade_building(tile)
   return
func run():
 print("DIFFICULTY_DIAGNOSTIC seed=17 room=2 initial_gold=25")
 var failures=0
 var matches=0
 for stage in StageCatalog.STAGES:
  for difficulty in ["standard","hard"]:
   for strategy in ["balanced","turret_rush","economy_stack","door","minimal","marksman"]:
    var model=MatchModel.new()
    model.reset(17)
    model.configure_match(difficulty,RankCatalog.bonuses(["marksman"] if strategy=="marksman" else []))
    model.configure_stage(stage.id)
    model.claim_room(1)
    var room=model.player()
    model.player_position=room.bed_position()
    model.sleep_player()
    room.profile="balanced"
    var steps=0
    var timer=0.0
    var peak=0
    var attacked_seconds=0.0
    var attack_state_seconds=0.0
    var idle_seconds=0.0
    var door_min=room.door_hp
    var first_player_hit=-1.0
    var levels=1
    while model.result=="" and steps<12000:
     if strategy in ["balanced","marksman"]: BotAI.tick(room,0.1)
     else:
      timer-=0.1
      if timer<=0:
       act(room,strategy)
       timer=0.5
     model.tick(0.1)
     peak=maxi(peak,room.buildings.size())
     levels=maxi(levels,model.hunter.level)
     if model.hunter.state==HunterState.State.ATTACK:
      attack_state_seconds+=0.1
      if model.hunter.target==1: attacked_seconds+=0.1
     elif model.time>model.preparation: idle_seconds+=0.1
     if room.door_damage_taken>0 and first_player_hit<0: first_player_hit=model.time
     door_min=minf(door_min,room.door_hp)
     steps+=1
    matches+=1
    if model.result=="" or room.gold<0 or room.electricity<0: failures+=1
    print("DIFFICULTY_BASELINE stage=",stage.id," difficulty=",difficulty," strategy=",strategy," result=",model.result," time=",snappedf(model.time,0.1)," level=",levels," attacks=",model.hunter.attacks," attack_seconds=",snappedf(attack_state_seconds,0.1)," travel_seconds=",snappedf(idle_seconds,0.1)," player_attack_seconds=",snappedf(attacked_seconds,0.1)," player_first_hit=",snappedf(first_player_hit,0.1)," player_door_damage=",snappedf(room.door_damage_taken,0.1)," player_min_hp=",snappedf(door_min,0.1)," buildings=",peak," spent=",snappedf(room.spent,0.1)," income=",snappedf(room.income_total,0.1)," player_damage=",snappedf(room.damage_dealt,0.1)," team_damage=",snappedf(model.damage_dealt-room.damage_dealt,0.1)," hunter_max_hp=",snappedf(model.hunter.max_hp,0.1)," retargets=",model.hunter.retargets," recoveries=",model.hunter.navigation_recoveries)
 print("DIFFICULTY_BASELINE_MATCHES=",matches," FAILURES=",failures)
 quit(0 if failures==0 else 1)
