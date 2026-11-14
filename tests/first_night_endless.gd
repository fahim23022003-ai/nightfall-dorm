extends SceneTree
const Support=preload("res://tests/replay_test_support.gd")
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok:failures+=1;push_error("FIRST NIGHT ENDLESS: "+label)
func _initialize():call_deferred("run")
func run():
 var source="res://docs/evidence/gameplay-overhaul/balance/earned-cursed_mansion.json";var hash=FileAccess.get_sha256(source)
 var m=ReplaySnapshot.restore(JSON.parse_string(FileAccess.get_file_as_string(source)));check(m!=null,"canonical45 restores")
 var r=m.player()
 for id in r.buildings:
  if r.buildings[id].kind=="repair":
   while r.buildings[id].level<10:check(m.upgrade_building(id),"paid repair upgrade")
 for tile in range(r.tile_count()):
  if r.buildings.has(tile):continue
  var point=r.fixed_tile_position(tile)+Vector2(3,-1)
  if r.spatial.geometry_reason(point)!="":continue
  check(m.place_building("heavy",point),"paid Arc purchase")
  var id=r.spatial.next_id-1
  while r.buildings[id].level<10:check(m.specialize_building(id,"focus") if r.buildings[id].level==4 else m.upgrade_building(id),"paid Arc upgrade")
 check(r.buildings.size()==16,"all16 actual earned paid buildings")
 var snap=JSON.parse_string(JSON.stringify(ReplaySnapshot.encode(m)));m=ReplaySnapshot.restore(snap);var other=ReplaySnapshot.restore(snap)
 check(Support.numeric_same(Support.model_signature(m),Support.model_signature(other)),"twins begin from identical serialized checkpoint")
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.onboarding.set_process(false);game.onboarding.close_welcome();game.mode="match"
 var rows=[];var max_projectiles=0;var max_events=0;var ticks=0;var usec=0;var ui_usec=0;var peak_memory=0
 for wave in range(46,51):
  check(m.continue_wave("repair") and other.continue_wave("repair"),"same legitimate wave transition "+str(wave))
  var start=m.time
  for i in range(9000):
   var now=Time.get_ticks_usec();m.tick(.1);other.tick(.1);usec+=Time.get_ticks_usec()-now;ticks+=2
   max_projectiles=maxi(max_projectiles,m.projectiles.size());max_events=maxi(max_events,m.presentation_events.size())
   if i%10==0:
    now=Time.get_ticks_usec()
    for pair in [[m,"show"],[other,"off"]]:
     game.model=pair[0];game.profile.settings.guidance_mode=pair[1];game.ui.show_match() if game.ui.current_screen!="match" else game.ui.update_match();game.guidance.refresh(game)
    ui_usec+=Time.get_ticks_usec()-now;peak_memory=maxi(peak_memory,OS.get_static_memory_usage())
   if m.result!="" or m.endless.phase=="intermission":break
  check(Support.numeric_same(Support.model_signature(m),Support.model_signature(other)),"Show vs Off identical combat/economy/RNG wave "+str(wave))
  check(m.wave_metrics.data.observations.size()<=256 and WaveMetrics.valid(m.wave_metrics.data),"bounded valid wave ledger "+str(wave))
  rows.append({"wave":wave,"completed":m.endless.completed,"result":m.result,"alive":m.player().alive,"seconds":m.time-start,"gold":m.player().gold,"electricity":m.player().electricity,"observed_buildings":m.wave_metrics.data.observations.size()})
  if m.result!="" or m.endless.phase!="intermission":break
  var resumed=ReplaySnapshot.restore(JSON.parse_string(JSON.stringify(ReplaySnapshot.encode(m))))
  check(resumed!=null,"new observations checkpoint roundtrip "+str(wave))
 check(max_projectiles<=256 and max_events<=128,"long-run combat collections bounded")
 check(FileAccess.get_sha256(source)==hash,"original earned checkpoint untouched")
 var f=FileAccess.open("res://docs/evidence/first-night/extended-endless.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"waves":rows,"model_ticks":ticks,"average_model_tick_ms":usec/1000.0/maxi(1,ticks),"ui_update_total_ms":ui_usec/1000.0,"peak_static_memory_bytes":peak_memory,"max_projectiles":max_projectiles,"max_events":max_events,"source_sha256":hash,"conditions":"Linux headless Godot4.6.3. Canonical earned45, actual paid upgrades from its original wallet. Twin actual model simulations, same repair aid and .1s steps, guidance Show/Off refreshed once per simulated second. Automated continuation, not human/natural1→50 or Windows FPS benchmark."}," "))
 game.guidance.mark(null);game.audio_system.shutdown();game.queue_free();await create_timer(.5).timeout
 print("FIRST_NIGHT_ENDLESS_CHECKS=",checks," FAILURES=",failures);quit(1 if failures else 0)
