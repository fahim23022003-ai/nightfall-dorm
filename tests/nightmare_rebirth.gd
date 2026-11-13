extends "res://tests/replay_endless.gd"
var evidence=[]
func prepare(kind: String,level: int):
 var a=fixture();var m=a.m;var h=HunterState.new();h.configure("standard");h.configure_archetype(kind);h.boss_policy={"enabled":false};m.hunter=h
 h.state=HunterState.State.ATTACK;h.target=m.player_room;h.position=m.player().door_approach();h.cooldown=100;h.tactical_cooldown=100
 m.evolution.evolution_level=level;m.evolution.final_revealed=true;h.nightmare.cooldown=0
 return a
func progression():
 var a=prepare("crusher",1);var m=a.m;var health=m.hunter.max_hp;var damage=m.hunter.damage
 for entry in [[1,1],[16,4],[31,7],[46,10],[999,10]]:
  m.endless.wave=entry[0];m.evolution.tick(.1,m)
  check(m.evolution.evolution_level==entry[1],"bounded legitimate wave-based evolution "+str(entry))
 check(m.hunter.max_hp==health and m.hunter.damage==damage,"evolution adds no duplicate blanket stat multiplier")
 m.evolution.final_revealed=false;m.evolution.tick(.1,m)
 check(m.evolution.rebirth_remaining>3 and m.evolution.final_revealed,"level10 begins one finite real reveal")
 m.evolution.tick(4,m);m.evolution.tick(.1,m)
 check(m.presentation_events.filter(func(e):return e.type=="nightmare_rebirth").size()==1,"reveal does not repeat")
 m.endless.wave=46;m.hunter.hurt(m.hunter.hp*2);m.endless.finish_wave(m)
 var snap=ReplaySnapshot.encode(m);check(not snap.is_empty() and ReplaySnapshot.valid(snap),"evolution checkpoint validates")
 var resumed=ReplaySnapshot.restore(snap)
 check(resumed!=null and resumed.evolution.evolution_level==10 and resumed.evolution.final_revealed,"evolution and reveal history survive checkpoint")
 var old=JSON.parse_string(FileAccess.get_file_as_string("res://docs/evidence/gameplay-overhaul/balance/earned-cursed_mansion.json"))
 var legacy=ReplaySnapshot.restore(old);check(legacy!=null,"old kill-buff checkpoint remains readable")
 check(legacy.evolution.evolution_level==9,"old wave45 derives appropriate nightmare tier without stat change")
 var campaign=MatchModel.new();campaign.configure_stage("stage_1");campaign.configure_strategy(7,"crusher");campaign.time=campaign.preparation+226;campaign.evolution.tick(.1,campaign)
 check(campaign.evolution.evolution_level==4,"campaign elapsed survival evolves original form")
 var challenge=MatchModel.new();challenge.run_kind="challenge";challenge.time=9999;challenge.evolution.tick(1,challenge)
 check(challenge.evolution.evolution_level==1,"normalized Challenge progression is preserved")
func skills():
 for kind in StrategyCatalog.ARCHETYPE_IDS:
  for level in [4,10]:
   var a=prepare(kind,level);var m=a.m;var h=m.hunter;var n=h.nightmare;var r=m.player()
   var expected=NightmareCombat.KITS[kind][1 if level==10 else 0]
   if expected=="rend":r.barrier_remaining=10;r.barrier_hp=100
   var hp=r.door_hp;var power=r.electricity;var income=r.gold
   check(n.tick(.01,h,m) and n.action==expected and n.warning>=1.9,"actual warning begins "+expected)
   check(r.door_hp==hp and r.gold==income and r.electricity==power,"warning causes no untelegraphed damage or theft")
   n.tick(3,h,m);check(n.casts.get(expected,0)==1 and n.effect==expected and n.remaining==4,"actual bounded release "+expected)
   for i in range(4):n.advance(.9,h,m)
   if expected in ["faultline","ritual","convergence"]:check(r.door_hp<hp and r.door_hp>hp*.8,"real bounded channel damage "+expected)
   if expected=="ossuary":check(is_equal_approx(n.incoming_factor({"type":"physical"}),.7) and n.incoming_factor({"type":"magic"})==1.2,"Ossuary has meaningful typed counterplay")
   if expected=="overload":check(is_equal_approx(n.incoming_factor({"type":"magic"}),.7) and n.incoming_factor({"type":"physical"})==1.2,"Overload has opposite typed weakness")
   if expected=="drag":check(n.projectile_factor(r.index,Vector2.ZERO,h.position)==.8,"Lantern Snare changes real projectile speed factor")
   if expected=="oath":h.tick(.01,m);check(r.repair_factor<1,"Hollow Oath affects actual contact repair calculations")
   if expected=="quills":
    var before=r.door_hp;m.apply_target_damage(1,100,r.index,{"type":"physical","element":"neutral"})
    check(r.door_hp<before and n.retaliation_left<h.damage,"actual physical hit triggers capped retaliation")
    before=r.door_hp;m.apply_target_damage(1,100,r.index,{"type":"magic","element":"neutral"});check(r.door_hp==before,"magic counters Quills without recursive reflection")
   if expected=="rend":check(r.barrier_hp<80 and r.barrier_hp>=0,"Carrion Rend removes bounded active barrier, not a building")
   if expected=="hex":
    var before_gold=r.gold;r.tick_economy(.1,1,n.income_factor(r.index));check(is_equal_approx(r.gold-before_gold,r.income_rate()*.1*.8),"Hex changes actual occupied bed generation")
   if expected=="cage":check(n.range_factor(r.index)==.85 and n.range_factor((r.index+1)%6)==1,"Static Cage is room-limited range pressure, not a global lock")
   if expected=="gust":check(n.projectile_factor(r.index,h.position+Vector2(50,0),h.position)==.55 and n.projectile_factor(r.index,h.position+Vector2(200,0),h.position)==1,"Pressure Front affects only actual near-Hunter flight")
   n.advance(1,h,m);check(n.effect=="" and n.remaining==0,"automatic effect cleanup "+expected)
   check(not n.tick(.01,h,m),"cooldown prevents repeated ability "+expected)
   evidence.append({"archetype":kind,"level":level,"skill":expected,"door_damage":hp-r.door_hp,"cooldown":n.cooldown})
 var a=prepare("witch",10);var h=a.m.hunter;h.nightmare.tick(.01,h,a.m);h.hp-=h.max_hp*.06
 check(not h.nightmare.tick(.1,h,a.m) and h.nightmare.action=="","focused damage interrupts dangerous casting")
 a=prepare("storm",10);h=a.m.hunter;h.nightmare.tick(.01,h,a.m);h.transformed=true;h.nightmare.advance(.1,h,a.m)
 check(h.nightmare.action=="" and h.nightmare.remaining==0,"Reaper cancels archetype evolved actions")
 a=prepare("crusher",10);h=a.m.hunter;h.nightmare.tick(.01,h,a.m);a.m.items.timers.frost=2
 check(not h.nightmare.tick(.1,h,a.m) and h.nightmare.action=="","existing Frost counter interrupts wind-up")
func visual_inventory():
 var rig=load("res://scripts/nightmare_presentation.gd").new()
 check(rig.art.size()==168,"all six four-tier rigs have seven independent original layers")
 for kind in StrategyCatalog.ARCHETYPE_IDS:
  check(rig.art.has(kind+"_0_body") and rig.art.has(kind+"_3_head"),"complete base/final assets "+kind)
 check(Catalog.BUILDINGS.size()==15 and Catalog.BUILDING_MAX_LEVEL==10,"all fifteen registered kinds retain cap and economy")
 check(AudioDirector.EFFECT_NAMES.has("nightmare_rebirth"),"finite transformation cue is routed")
 var stream=load("res://assets/audio/nightmare_rebirth.wav");check(stream!=null and stream.get_length()>4 and stream.get_length()<6,"sustained recorded-layer cue duration")
func run():
 progression();skills();visual_inventory()
 print("NIGHTMARE_SKILL_OBSERVATIONS="+JSON.stringify(evidence))
 print("NIGHTMARE_CHECKS=%d FAILURES=%d" % [checks,failures])
 quit(1 if failures else 0)
