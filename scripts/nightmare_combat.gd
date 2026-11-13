class_name NightmareCombat
extends RefCounted
# Separate from combat level and kill buffs: finite abilities, no stat growth.
const KITS={
 "crusher":["faultline","ossuary"],"stalker":["drag","oath"],"ravager":["quills","rend"],
 "witch":["hex","ritual"],"electric":["cage","overload"],"storm":["gust","convergence"]}
const SKILLS={
 "faultline":{"name":"Seismic Faultline","type":"physical","element":"earth","help":"Four small contact pulses. Shield, repair or interrupt the channel."},
 "ossuary":{"name":"Ossuary Cathedral","type":"physical","element":"earth","help":"Physical armor for 4s, but magic deals 20% more damage."},
 "drag":{"name":"Lantern Snare","type":"magic","element":"neutral","help":"Marked-room projectiles travel 20% slower for 4s. Build closer."},
 "oath":{"name":"Hollow Oath","type":"magic","element":"neutral","help":"Marked-door repairs 15% weaker for 4s. Repair during the warning."},
 "quills":{"name":"Blood Quills","type":"physical","element":"neutral","help":"Physical hits retaliate for 4s, capped at one ordinary hit. Use magic."},
 "rend":{"name":"Carrion Rend","type":"physical","element":"neutral","help":"Breaks 20% of an active temporary barrier; magic wards remain intact."},
 "hex":{"name":"Hex Orchard","type":"magic","element":"ice","help":"Target bed income falls 20% for 4s; stored resources are untouched."},
 "ritual":{"name":"Moonless Ritual","type":"magic","element":"ice","help":"Three visible curse pulses over 4s. Magic defenses absorb/reflect them."},
 "cage":{"name":"Static Cage","type":"magic","element":"electric","help":"Target-room turret range falls 15% for 4s; close defenses still fire."},
 "overload":{"name":"Grounded Overload","type":"magic","element":"electric","help":"Magic damage resisted 30% for 4s, but physical damage rises 20%."},
 "gust":{"name":"Pressure Front","type":"magic","element":"electric","help":"Projectiles within 100px of the Hunter travel 45% slower for 4s."},
 "convergence":{"name":"Thunder Convergence","type":"magic","element":"electric","help":"Three channel pulses; branches only to visible nearby intact doors."}}
var cooldown=12.0
var action=""
var warning=0.0
var target=-1
var start_hp=0.0
var effect=""
var remaining=0.0
var pulse_clock=0.0
var pulses=0
var sequence=0
var retaliation_left=0.0
var casts: Dictionary={}
func clear():
 action="";warning=0;effect="";remaining=0;pulses=0;retaliation_left=0
func valid_target(h,m) -> bool:
 return target>=0 and target<m.rooms.size() and m.rooms[target].alive and m.rooms[target].closed and m.rooms[target].door_hp>0 and h.target==target and h.position.distance_to(m.rooms[target].door_approach())<=3 and m._visible(h.position,m.rooms[target].door_approach())
func advance(delta: float,h,m):
 cooldown=maxf(0,cooldown-delta)
 if h.hp<=0 or h.transformed or m.result!="" or m.run_kind in ["practice","challenge"] or m.tutorial_mode:clear();return
 if remaining>0:
  remaining=maxf(0,remaining-delta)
  if not valid_target(h,m):clear();return
  if effect in ["faultline","ritual","convergence"]:
   pulse_clock-=delta
   if pulse_clock<=0 and pulses>0:
    pulse_clock+=1.15;pulses-=1;strike(h,m,effect,.25,.035)
  if remaining<=0:effect="";retaliation_left=0
func tick(delta: float,h,m) -> bool:
 if not KITS.has(h.archetype) or h.transformed or m.tutorial_mode or m.run_kind in ["practice","challenge"]:clear();return false
 if m.evolution.rebirth_remaining>0:return true
 if m.evolution.evolution_level==10 and not m.evolution.final_revealed:return false
 if action!="":
  if not valid_target(h,m) or h.hp<start_hp-h.max_hp*.05 or m.items.timers.get("frost",0)>0 or m.items.timers.get("reaper_seal",0)>0:
   m.record_event("nightmare_cancel",target,{"skill":action});clear();cooldown=maxf(cooldown,12);return false
  warning=maxf(0,warning-delta)
  if warning>0:return true
  var chosen=action;action="";effect=chosen;remaining=4.0;pulse_clock=.5;pulses=4 if chosen=="faultline" else 3
  retaliation_left=h.damage
  casts[chosen]=mini(1000000000,int(casts.get(chosen,0))+1)
  if chosen=="rend":m.rooms[target].barrier_hp*=.8
  if chosen not in ["faultline","ritual","convergence","quills","gust"]:strike(h,m,chosen,.8,.08)
  m.record_event("nightmare_release",target,{"skill":chosen,"duration":4.0,"origin":h.position})
  return true
 if remaining>0:return effect in ["faultline","ritual","convergence"] # persistent channels hold movement; finite stances permit ordinary strikes
 if cooldown>0 or m.evolution.evolution_level<4 or h.state!=HunterState.State.ATTACK or h.arcane.action!="" or not h.arcane.bolt.is_empty() or h.tactical_action!="" or h.boss_attack!="" or m.wrath.active():return false
 target=h.target
 if not valid_target(h,m):return false
 var signature=m.evolution.evolution_level==10 and sequence%2==0
 action=KITS[h.archetype][1 if signature else 0];sequence=1-sequence
 warning=2.8 if signature else 2.0;start_hp=h.hp
 cooldown=(64.0 if signature else 46.0)+(6 if m.difficulty=="hard" else 12 if m.difficulty=="hell" else 0)
 m.record_event("nightmare_warning",target,{"skill":action,"delay":warning,"origin":h.position})
 return true
func strike(h,m,id: String,mult: float,cap: float):
 if not valid_target(h,m):return
 var data=SKILLS[id];var targets=[target]
 if id=="convergence":
  for room in m.rooms:
   if targets.size()>=3:break
   if room.index==target or room.owner<0 or not room.alive or not room.closed or room.door_hp<=0:continue
   if room.door_approach().distance_to(m.rooms[target].door_approach())<=200 and m._visible(m.rooms[target].door_approach(),room.door_approach()):targets.append(room.index)
 for index in targets:
  var room=m.rooms[index];var amount=minf(h.damage*mult*(.9 if m.difficulty=="hard" else .8 if m.difficulty=="hell" else 1),room.max_hp()*cap)
  var actual=m.apply_room_damage(index,amount,data.name,1,true,{"type":data.type,"element":data.element})
  if actual>0:m.record_event("nightmare_impact",index,{"skill":id,"amount":actual,"origin":h.position,"damage_type":data.type,"element":data.element})
func incoming_factor(packet: Dictionary) -> float:
 if remaining<=0:return 1.0
 if effect=="ossuary":return .7 if packet.type=="physical" else 1.2
 if effect=="overload":return .7 if packet.type=="magic" else 1.2
 return 1.0
func projectile_factor(room: int,point: Vector2,hunter_position: Vector2) -> float:
 if remaining<=0:return 1.0
 if effect=="drag" and room==target:return .8
 if effect=="gust" and point.distance_to(hunter_position)<100:return .55
 return 1.0
func range_factor(room: int) -> float:return .85 if remaining>0 and effect=="cage" and target==room else 1.0
func income_factor(room: int) -> float:return .8 if remaining>0 and effect=="hex" and target==room else 1.0
func repair_factor(room: int) -> float:return .85 if remaining>0 and effect=="oath" and target==room else 1.0
func retaliate(h,m,actual: float,packet: Dictionary):
 if remaining>0 and effect=="quills" and h.hp>0 and not h.transformed and packet.type=="physical" and retaliation_left>0 and valid_target(h,m):
  var amount=minf(actual*.15,retaliation_left);retaliation_left-=amount
  var dealt=m.apply_room_damage(target,amount,"Blood Quills",1,true,{"type":"physical","element":"neutral"})
  if dealt>0:m.record_event("nightmare_impact",target,{"skill":"quills","amount":dealt,"origin":h.position,"damage_type":"physical","element":"neutral"})
