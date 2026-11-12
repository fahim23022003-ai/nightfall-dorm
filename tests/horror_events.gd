extends SceneTree
# Independent Agent C verification of production event boundaries.
var checks=0
var failures=0

func check(ok: bool,label: String):
 checks+=1
 if not ok:
  failures+=1
  push_error("HORROR EVENTS: "+label)

func events(model,kind: String) -> Array:
 return model.presentation_events.filter(func(e): return e.type==kind)

func fixture(index: int=0):
 var model=MatchModel.new()
 model.time=Catalog.PREPARATION
 model.claim_room(index)
 var room=model.player()
 model.player_position=room.bed_position()
 model.sleep_player()
 room.gold=10000
 room.electricity=10000
 model.hunter.target=index
 model.hunter.state=HunterState.State.ATTACK
 model.hunter.position=room.door_position()+Vector2(0,22 if index<3 else -22)
 model.hunter.cooldown=0
 return model

func cue_count(audio,kind: String) -> int: return int(audio.event_counts.get(kind,0))

func screams(audio) -> int:
 return cue_count(audio,"scream_1")+cue_count(audio,"scream_2")+cue_count(audio,"scream_3")

func idle(audio):
 for voice in audio.voices: voice.stop()
 audio._frame_voices=0

func arrive(model,index: int):
 var r=model.rooms[index]
 r.owner=0 if index==model.player_room else 1
 r.sleeping=true
 r.closed=true
 model.hunter.target=index
 model.hunter.state=HunterState.State.MOVE
 model.hunter.position=r.door_position()+Vector2(0,22 if index<3 else -22)
 model.hunter.tick(0.01,model)

func _initialize(): call_deferred("run")

func run():
 OS.set_environment("NIGHTFALL_PROFILE_PATH","user://horror-events-qa.json")
 for index in range(6):
  var model=fixture(index)
  var room=model.player()
  var initial=room.door_hp
  model.hunter.tick(0.01,model)
  var hits=events(model,"door_damage")
  check(hits.size()==1,"one actual attack emits one damage record room "+str(index))
  if not hits.is_empty():
   check(hits[0].room==index and hits[0].position==room.door_position(),"damage room and position accurate")
   check(is_equal_approx(hits[0].damage,initial-room.door_hp),"damage equals actual loss")
   check(hits[0].hp==room.door_hp and hits[0].max_hp==room.max_hp(),"event retains post-impact hp")
  for frame in range(10): model.hunter.tick(0.01,model)
  check(events(model,"door_damage").size()==1,"cooldown frames do not invent attacks")
  room.door_hp=3
  model.hunter.cooldown=0
  model.hunter.tick(0.01,model)
  hits=events(model,"door_damage")
  check(hits.size()==2 and hits.back().damage==3,"overkill number clamps to remaining HP")
  check(events(model,"door_break").size()==1,"one break per actual zero crossing")
  for frame in range(3): model.hunter.tick(0.01,model)
  check(events(model,"door_break").size()==1,"breach frames do not duplicate breaks")
  model.hunter.position=room.bed_position()
  model.hunter.state=HunterState.State.BREACH
  model.hunter.tick(0.01,model)
  check(events(model,"elimination").size()==1 and not room.alive,"actual breach elimination event")
  for frame in range(3): model.hunter.tick(0.01,model)
  check(events(model,"elimination").size()==1,"elimination does not repeat after death")
 var rescue=fixture()
 var resident=rescue.player()
 resident.rescue_fraction=0.5
 resident.door_hp=30
 var before=resident.door_hp
 rescue.hunter.tick(0.01,rescue)
 var hit=events(rescue,"door_damage").back()
 check(hit.damage==Catalog.HUNTER.damage,"rescue does not erase real impact damage")
 check(resident.rescue_used and resident.door_hp>before,"rescue fixture genuinely restored health")
 check(events(rescue,"door_break").is_empty(),"rescue at nonzero HP is not destruction")
 var transactions=fixture()
 for index in range(6):
  var r=transactions.rooms[index]
  r.owner=index
  r.sleeping=true
  r.gold=10000
  r.electricity=10000
  r.bed_level=1
  check(r.build("repair",0),"actual build succeeds")
  check(events(transactions,"build").back().room==index,"room signal captures correct room")
  var count=transactions.presentation_events.size()
  check(not r.build("repair",0) and transactions.presentation_events.size()==count,"failed duplicate build emits nothing")
  check(r.upgrade_building(0),"actual upgrade succeeds")
  check(events(transactions,"building_upgrade").back().room==index,"upgrade room accurate")
  var refund=r.building_refund(0)
  var gold=r.gold
  var power=r.electricity
  check(r.sell_building(0),"actual sale succeeds")
  var sale=events(transactions,"sale").back()
  check(sale.room==index and sale.gold==refund.x and sale.power==refund.y,"sale event separate currency refund")
  check(r.gold==gold+refund.x and r.electricity==power+refund.y,"sale event matches actual resources")
  count=transactions.presentation_events.size()
  check(not r.sell_building(0) and transactions.presentation_events.size()==count,"double refund emits nothing")
  check(r.build("generator",0),"sold pad reusable")
  r.door_hp=20
  check(r.repair_door(),"actual manual repair succeeds")
  check(events(transactions,"repair").back().room==index,"repair emits for actual repaired room")
  check(r.upgrade_bed(),"actual bed upgrade succeeds")
  check(events(transactions,"bed_upgrade").back().room==index,"bed upgrade emits")
  check(r.upgrade_door(),"actual door upgrade succeeds")
  check(events(transactions,"door_upgrade").back().room==index,"door upgrade emits")
 var transitions=fixture()
 var hunter=transitions.hunter
 hunter.state=HunterState.State.SEEK
 hunter.tick(0.01,transitions)
 check(events(transitions,"approach").size()==1,"target selection emits approach once")
 hunter.position=transitions.player().door_position()+Vector2(0,22)
 hunter.tick(0.01,transitions)
 check(events(transitions,"encounter").size()==1,"arrival emits genuine encounter")
 for frame in range(10): hunter.tick(0.01,transitions)
 check(events(transitions,"encounter").size()==1,"attack frames do not emit repeated encounter")
 hunter.state=HunterState.State.SEEK
 hunter.tick(0.01,transitions)
 check(events(transitions,"encounter").size()==2,"new genuine arrival resets encounter")
 for i in range(300): transitions.record_event("repair",i%6)
 check(transitions.presentation_events.size()==128,"event queue bounded under rapid multiple rooms")
 var last_id=0
 for entry in transitions.presentation_events:
  check(entry.id>last_id,"event ids remain monotonic after pruning")
  last_id=entry.id
 var count=transitions.presentation_events.size()
 transitions.record_event("repair",-1)
 transitions.record_event("repair",6)
 check(transitions.presentation_events.size()==count,"invalid room records ignored")
 transitions.reset(42)
 check(transitions.presentation_events.is_empty() and transitions.next_presentation_event_id==1,"restart clears events and ids")
 var audio=AudioDirector.new()
 root.add_child(audio)
 check(audio.missing_assets.is_empty(),"all original horror audio resources decode")
 for cue in ["scream_1","scream_2","scream_3","door_reaction","sale","refund","insufficient_gold","insufficient_power","eerie"]:
  check(audio.streams.has(cue) and audio.streams[cue].get_length()>0.04,"new functional PCM cue "+cue)
 var audible=fixture()
 audio.reset_match(audible)
 arrive(audible,0)
 audio.update_state(0.3,audible,"match")
 check(screams(audio)==1,"actual encounter plays one survivor scream")
 var first_scream=screams(audio)
 audio.update_state(0.3,audible,"match")
 check(screams(audio)==first_scream,"replayed event list does not scream again")
 idle(audio)
 arrive(audible,0)
 audio.update_state(0.3,audible,"match")
 check(screams(audio)==first_scream,"same-room encounter cooldown blocks spam")
 audio.update_state(11,audible,"match")
 idle(audio)
 arrive(audible,0)
 audio.update_state(0.01,audible,"match")
 check(screams(audio)==2 and cue_count(audio,"scream_2")==1,"new encounter after cooldown plays next original variation")
 arrive(audible,1)
 audio.update_state(0.3,audible,"match")
 check(screams(audio)==2,"global scream concurrency prevents room overlap")
 idle(audio)
 audible.player().door_hp=20
 audible.hunter.state=HunterState.State.ATTACK
 audible.hunter.target=0
 audible.hunter.cooldown=0
 audible.hunter.tick(0.01,audible)
 audio.update_state(2.1,audible,"match")
 check(cue_count(audio,"door_break")==1 and cue_count(audio,"door_reaction")==1,"real door destruction plays distinct reaction")
 idle(audio)
 audible.player().door_hp=30
 var repairs=cue_count(audio,"repair")
 check(audible.repair_door(),"audio manual repair fixture pays actual cost")
 audio.update_state(2,audible,"match")
 check(cue_count(audio,"repair")==repairs+1,"actual repair emits functional audio")
 idle(audio)
 check(audible.buy("repair",0),"audio sale fixture builds real paid building")
 audio.update_state(0.3,audible,"match")
 idle(audio)
 check(audible.sell_building(0),"audio sale fixture actual sale succeeds")
 audio.update_state(0.3,audible,"match")
 check(cue_count(audio,"sale")==1 and cue_count(audio,"refund")==1,"actual sale and refund have distinct cues")
 var sale_count=cue_count(audio,"sale")
 check(not audible.sell_building(0),"invalid sale rejected")
 idle(audio)
 audio.update_state(1,audible,"match")
 check(cue_count(audio,"sale")==sale_count,"invalid/replayed sale cannot replay audio")
 # Final-tick records must be consumed even after the host switches to result.
 var terminal=fixture()
 idle(audio)
 audio.reset_match(terminal)
 terminal.player().door_hp=1
 terminal.hunter.tick(0.01,terminal)
 terminal.hunter.state=HunterState.State.BREACH
 terminal.hunter.position=terminal.player().bed_position()
 terminal.hunter.tick(0.01,terminal)
 terminal.result="defeat"
 var breaks_before=cue_count(audio,"door_break")
 var reactions_before=cue_count(audio,"door_reaction")
 audio.update_state(3,terminal,"result")
 check(cue_count(audio,"door_break")==breaks_before+1,"terminal transition retains actual door break cue")
 check(cue_count(audio,"door_reaction")==reactions_before+1,"terminal transition retains destruction reaction")
 audio.shutdown()
 await create_timer(0.5).timeout
 audio.queue_free()
 await process_frame
 print("HORROR_EVENT_CHECKS=%d FAILURES=%d" % [checks,failures])
 quit(0 if failures==0 else 1)
