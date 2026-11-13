extends "res://tests/replay_endless.gd"
func run():
 var path="user://session-music-test-"+str(Time.get_ticks_usec())+".json";var bag=Soundtrack.new(path);var sequence=[]
 for i in range(21):
  var next=Soundtrack.new(path);var id=next.draw("music_menu");sequence.append(id)
  if i>0:check(id!=sequence[i-1],"persisted shuffle avoids last launch")
 for i in range(0,21,3):
  for track in Soundtrack.FAMILIES.music_menu:check(sequence.slice(i,i+3).count(track)==1,"complete bag visits each composition exactly once")
 var p=PlayerProfile.new(path+"-profile");check(p.settings.music_mode=="shuffle","new profile Dynamic Shuffle default");check(p.update_setting("music_mode","manual") and p.update_setting("manual_track","music_siege"),"actual saved preference transactions")
 var q=PlayerProfile.new(p.path);check(q.load_profile() and q.settings.manual_track=="music_siege" and q.settings.music_mode=="manual","preferences survive fresh loader")
 var a=fixture();var m=a.m;var r=m.player();m.time=0;var rng=m.random.state
 check(m.place_building("turret",r.fixed_tile_position(0)+Vector2(3,-2)),"free placement for undo/range")
 var original=r.buildings[16].duplicate(true);var to=r.fixed_tile_position(1)+Vector2(3,-2);check(m.begin_building_move(16) and m.move_building(to),"real move")
 var wallet=Vector2(r.gold,r.electricity);check(r.spatial.undo(m) and r.buildings[16]==original and Vector2(r.gold,r.electricity)==wallet,"single-use undo retains identity/economy/cooldown")
 check(not r.spatial.undo(m),"undo cannot toggle indefinitely")
 check(m.begin_building_move(16) and m.move_building(to),"another valid move")
 m.time=m.preparation+1;check(not r.spatial.undo(m),"combat undo forbidden")
 check(m.random.state==rng,"presentation/placement leaves gameplay RNG unchanged")
 m.time=0;r.spatial.cancel_move();var b=r.buildings[16];var stats=BuildingStats.weapon_stats(m,r,b)
 check(stats.range==Catalog.BUILDINGS.turret.range,"range uses real unmodified resolver")
 m.time=m.preparation+.1;var h=m.hunter;h.state=HunterState.State.ATTACK;h.target=0;h.position=r.door_approach();h.cooldown=100;h.boss_policy.enabled=false
 var hp=h.hp;var before_gold=r.income_total
 for i in range(40):m.tick(.05)
 var metrics=m.wave_metrics.report();check(metrics.total>0 and absf(metrics.total-(hp-h.hp))<.001,"actual impacts reconcile Hunter HP loss")
 check(absf(metrics.total-metrics.top[0].damage-metrics.other)<.001 and metrics.top[0].hits>0,"per-building damage/hits reconcile")
 check(absf(metrics.gold-(r.income_total-before_gold))<.001,"generation from measured economy, not wallet net")
 var door=r.door_hp;m.apply_room_damage(0,10,"test",1);check(absf(m.wave_metrics.data.door-(door-r.door_hp))<.001,"actual door damage tracked")
 var damaged=r.door_hp;m.repair_door();check(absf(m.wave_metrics.data.repair-(r.door_hp-damaged))<.001,"actual manual repair tracked")
 clear_wave(a);var snap=Snapshot.encode(m);check(Snapshot.valid(snap) and Snapshot.restore(snap).wave_metrics.data==m.wave_metrics.data,"wave report checkpoint roundtrip")
 check(Snapshot.restore(JSON.parse_string(JSON.stringify(snap)))!=null,"JSON disk roundtrip preserves numeric building IDs")
 snap.erase("wave_metrics");check(not Snapshot.restore(snap).wave_metrics.data.available,"legacy report absent, never fabricated")
 check(m.continue_wave("repair") and m.wave_metrics.data.total==0 and m.wave_metrics.data.gold==0,"next wave resets telemetry and excludes aid")
 var env1=preload("res://scripts/haunted_environment.gd").new();env1.night_seed=10;env1.configure(m);var env2=preload("res://scripts/haunted_environment.gd").new();env2.night_seed=20;env2.configure(m)
 check(env1.moonlight!=env2.moonlight and env1.fog_phase!=env2.fog_phase,"separate night atmosphere varies")
 var state=m.random.state;env1.update(.1,m);check(m.random.state==state,"atmosphere cannot consume combat RNG")
 # Real burn tick accounting retains source after movement/sale; no DPS estimates.
 m.time=m.preparation+.1;m.hunter.state=HunterState.State.ATTACK;m.hunter.position=r.door_approach();m.hunter.target=0;m.hunter.cooldown=100
 var burn_hp=m.hunter.hp;m.defenses.ignite(1,10.0,1.0,0,16,"flame",4);m.defenses.tick(.5,m)
 check(absf(m.wave_metrics.data.buildings["16"].damage-(burn_hp-m.hunter.hp))<.001 and m.wave_metrics.data.buildings["16"].hits==0,"actual burn damage credited without fabricating projectile hits")
 var prior_burn=m.wave_metrics.data.total;check(m.sell_building(16),"actual sale during an existing burn")
 m.defenses.tick(.25,m);check(m.wave_metrics.data.total>prior_burn and m.wave_metrics.data.buildings.has("16"),"sold source retains actual burn attribution")
 var bad_metrics=m.wave_metrics.data.duplicate(true);bad_metrics.buildings["16"].damage+=1000
 check(not WaveMetrics.valid(bad_metrics),"inconsistent checkpoint telemetry rejected")
 # Preparation undo must never reappear after fighting that same wave.
 m.time=0;check(m.place_building("turret",r.fixed_tile_position(1)+Vector2(3,-2)),"replacement purchase for undo phase guard")
 var replacement=r.spatial.next_id-1
 check(m.begin_building_move(replacement) and m.move_building(r.fixed_tile_position(0)+Vector2(3,-2)),"prep move before phase-change guard")
 m.time=m.preparation+1;m.endless.phase="intermission"
 check(r.spatial.undo_reason(m)!="","prep undo cannot cross into later intermission")
 var wallet2=Vector2(r.gold,r.electricity);check(not r.spatial.undo(m) and Vector2(r.gold,r.electricity)==wallet2,"invalid undo never refunds or changes resources")
 print("SESSION_FEATURE_CHECKS=",checks," FAILURES=",failures," SHUFFLE=",sequence)
 Support.cleanup(prefix);quit(1 if failures else 0)
