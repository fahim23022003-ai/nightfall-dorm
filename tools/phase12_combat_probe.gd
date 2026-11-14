extends "res://tools/phase12_strategy_probe.gd"
func run():
 var rows=[]
 for difficulty in ["standard","hard","hell"]:
  for path in ["first","last"]:
   var m=MatchModel.new();m.configure_endless("abandoned_dorm",difficulty,1,1);m.configure_balance(2);m.claim_room(0);m.player_position=m.player().bed_position();m.sleep_player();balance=2
   var next=0.0;var last_event=0;var elapsed_states={};var own_damage=0.0;var own_hits=0;var all_damage=0.0;var first_own_hit=-1.0;var breach=-1.0;var clears=[];var wave_started=0.0;var repair_gold=0.0;var picks=[]
   while m.time<900 and m.result=="":
    if m.endless.phase=="intermission":
     clears.append({"wave":m.endless.completed,"time":m.time,"encounter_seconds_including_preparation":m.time-wave_started,"main_hunter_damage":m.wave_metrics.data.total,"allied_main_hunter_damage":m.wave_metrics.data.allied})
     if not m.choices.draft.is_empty():
      var id=m.choices.draft[0] if path=="first" else m.choices.draft[-1];m.choices.choose(m,id);picks.append(id)
     m.continue_wave("repair");wave_started=m.time
    if m.time>=next:
     var r=m.player();var g=r.gold;var repairs=r.repair_actions;act(m,"balanced");next+=1
     if r.repair_actions>repairs:repair_gold+=g-r.gold
    var state=str(m.hunter.state);elapsed_states[state]=float(elapsed_states.get(state,0))+.2;m.tick(.2)
    for event in m.presentation_events:
     if event.id<=last_event:continue
     last_event=event.id
     if event.type=="door_damage" and event.damage>0:
      all_damage+=event.damage
      if event.room==m.player_room:
       own_damage+=event.damage;own_hits+=1
       if first_own_hit<0:first_own_hit=m.time
     if event.type=="door_break" and event.room==m.player_room:breach=m.time
   rows.append({"difficulty":difficulty,"reward_path":path,"seed":1,"result":m.result if m.result!="" else "ongoing_at_horizon","duration":m.time,"completed":m.endless.completed,"selected_perks":picks,"actual_player_door_damage":own_damage,"actual_all_room_door_damage":all_damage,"player_positive_damage_events":own_hits,"first_player_hit":first_own_hit,"player_breach_time":breach,"time_first_hit_to_breach_with_defenses_and_repairs":breach-first_own_hit if first_own_hit>=0 and breach>=0 else null,"manual_repair_gold":repair_gold,"states_seconds":elapsed_states,"clears":clears,"player_flow":m.player().ledger.totals})
 var f=FileAccess.open("res://docs/evidence/earned-power/combat-reward-paths.json",FileAccess.WRITE);f.store_string(JSON.stringify({"description":"Fresh seed1 actual production rules; balanced paid policy one decision/s, 900s horizon, actual NPCs. First/last deterministic draft options compare reward paths, not promised best/worst optimal picks. No wallet/HP injection or manual kills. State3=ATTACK,5=EXIT (post-elimination travel, not healing retreat). Missing breach means no observed player breach, not infinite durability.","rows":rows}," "));print("COMBAT_REWARD_PATHS_COMPLETE ",rows.size());quit()
