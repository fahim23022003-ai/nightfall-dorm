class_name DefeatFacts
extends RefCounted
var history: Array=[]
var report: Dictionary={}
var last_source="No door damage recorded since start/resume"
var door_history: Array=[]
func event(type: String,room_index: int,model,data: Dictionary):
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
 report={"elapsed":model.time,"source":last_source,"archetype":model.hunter.archetype,"reaper":model.hunter.transformed,"gold":room.gold if room!=null else 0.0,"power":room.electricity if room!=null else 0.0,"door_level":room.door_level+1 if room!=null else 0,"repairs":room.repair_actions if room!=null else 0,"damage":room.door_damage_taken if room!=null else 0.0,"buildings":buildings,"unused":stock,"sequence":history.duplicate(true),"door_history":door_history.duplicate(true),"tips":tips.slice(0,2)}
