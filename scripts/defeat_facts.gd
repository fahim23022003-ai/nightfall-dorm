class_name DefeatFacts
extends RefCounted
var history: Array=[]
var report: Dictionary={}
var last_source="No door damage recorded since start/resume"
var door_history: Array=[]
var decision_windows: Array=[]
var breach_at=-1.0
func event(type: String,room_index: int,model,data: Dictionary):
 if model.balance_version==2 and room_index==model.player_room:
  if type=="door_damage" and float(data.get("damage",0))>0 and model.player().door_hp>0:
   decision_windows.append(observe(model))
   if decision_windows.size()>24:decision_windows.pop_front()
  if type=="door_break" and breach_at<0:breach_at=model.time
 if room_index==model.player_room and type in ["door_upgrade","repair"]:
  door_history.append({"type":type,"time":snappedf(model.time,.01),"level":model.player().door_level+1})
  if door_history.size()>12:door_history.pop_front()
 if room_index!=model.player_room or type not in ["door_damage","door_break","elimination"]:return
 if type=="door_damage" and float(data.get("damage",0))>0:
  var source=str(data.get("source","door strike"))
  last_source=BossCatalog.ATTACKS[source].name if BossCatalog.ATTACKS.has(source) else "Hunter "+source
 history.append({"type":type,"time":snappedf(model.time,.01),"damage":data.get("damage",0.0),"source":last_source})
 if history.size()>16:history.pop_front()
func capture(model):
 if not report.is_empty() or model.result!="defeat" or not model.terminal_recorded or model.eliminations<=0 or model.hunter.position.distance_to(model.player_position)>15:return
 var room=model.player();var stock={};var used=[]
 if room==null or room.door_hp>0:last_source="Exposed survivor contact"
 if model.items.profile_ref!=null and model.items.profile_ref.get_ref()!=null:
  var wallet=model.items.profile_ref.get_ref()
  for id in wallet.active_match.get("items",[]):stock[id]=int(wallet.inventory.get(id,0))
 var buildings=[]
 if room!=null:
  for tile in room.buildings:
   var b=room.buildings[tile];buildings.append({"tile":tile,"kind":b.kind,"level":b.level,"branch":b.get("specialization","")})
 var tips=[]
 if room==null or room.occupied_seconds<=0:tips.append("Occupy a bed before the exposed-survivor grace period ends.")
 if room!=null:
  if room.door_level<4 and room.gold>=BalanceRules.structure("door",room.door_level,room.balance_version).x and room.electricity>=BalanceRules.structure("door",room.door_level,room.balance_version).y and room.bed_level>=maxi(0,room.door_level-1):tips.append("You retained the resources and prerequisite for the next door upgrade; consider upgrading before the breach.")
  if tips.size()<2 and room.occupied_seconds>0 and (int(stock.get("shield",0))>0 or int(stock.get("repair",0))>0):tips.append("An equipped Shield or Repair Kit remained in stock. Use it while the door is still intact.")
  if tips.size()<2 and buildings.is_empty() and room.gold>=Catalog.BUILDINGS.turret.gold:tips.append("No building remained at defeat. You retained enough Gold for a Needle turret; place it within door range next time.")
 var window={}
 if model.balance_version==2 and room!=null:
  var candidates=decision_windows.filter(func(w):return breach_at>=0 and w.time<=breach_at-2.0)
  if not candidates.is_empty():window=candidates[-1]
  tips=[]
  if not window.is_empty():
   var text="At %.1fs (%.1fs before breach), held %.2fG / %.2fE." % [window.time,breach_at-window.time,window.gold,window.power]
   if window.repair_affordable:text+=" Manual repair +%.1f HP for %.2fG was affordable." % [window.repair_heal,window.repair_cost]
   elif window.door_affordable:text+=" The next door upgrade was legal and affordable."
   else:text+=" No manual repair or next door upgrade was affordable in that recorded window."
   tips.append(text)
   tips.append("This records available choices, not proof that one action would prevent defeat.")
  elif room.door_hp<=0:tips.append("No earlier actionable hit window was recorded since start/resume; no missed counter is inferred.")
 report={"elapsed":model.time,"source":last_source,"archetype":model.hunter.archetype,"reaper":model.hunter.transformed,"gold":room.gold if room!=null else 0.0,"power":room.electricity if room!=null else 0.0,"door_level":room.door_level+1 if room!=null else 0,"repairs":room.repair_actions if room!=null else 0,"damage":room.door_damage_taken if room!=null else 0.0,"buildings":buildings,"unused":stock,"sequence":history.duplicate(true),"door_history":door_history.duplicate(true),"tips":tips.slice(0,2)}

 if model.balance_version==2 and room!=null:
  report.counter_window=window.duplicate(true);report.breach_at=breach_at
  report.repair_spend=float(room.ledger.totals.repair_g)
  report.pressure_stacks=model.pressure.stacks
  report.repair_effectiveness=window.get("repair_factor",room.repair_factor)
func observe(m) -> Dictionary:
 var r=m.player();var price=BalanceRules.structure("door",r.door_level,r.balance_version)
 var legal=r.door_level<9 and r.bed_level>=maxi(0,r.door_level-1) and (not r.strategy_enabled or r.door_level!=4 or r.door_branch!="")
 return {"time":m.time,"gold":r.gold,"power":r.electricity,"door_hp":r.door_hp,"repair_factor":r.repair_factor,"repair_cost":r.manual_repair_cost(),"repair_heal":minf(r.max_hp()-r.door_hp,Catalog.REPAIR_HEAL*r.repair_factor*StrategyCatalog.BRANCHES.get(r.door_branch,{}).get("repair",1.0)),"repair_affordable":r.door_hp>0 and r.gold>=r.manual_repair_cost(),"door_affordable":legal and r.gold>=price.x and r.electricity>=price.y,"reserve":r.repair_reserve(),"pressure":m.pressure.factor(m),"hunter_interval":m.hunter.interval}
