class_name NightOmens
extends RefCounted
const IDS=["blood","blackout","walls"]
const DATA={"blood":{"name":"BLOOD MOON","icon":"hell"},"blackout":{"name":"BLACKOUT","icon":"power"},"walls":{"name":"CURSED WALLS","icon":"bulwark"}}
var selected=""
var reward=Vector2.ZERO
var active=""
var active_wave=0
var paid_wave=0
var last: Dictionary={}
static func offered(completed: int) -> bool:
 var next=completed+1
 return completed>=1 and completed%3==1 and next%5!=0 and not (next>=30 and next%3==0)
static func penalty(id: String,mode: String) -> float:
 var index=2 if mode=="hell" else 1 if mode=="hard" else 0
 return {"blood":[.12,.10,.08],"blackout":[.15,.12,.10],"walls":[.10,.08,.06]}.get(id,[0,0,0])[index]
static func risk(id: String,mode: String) -> String:
 var value=roundi(penalty(id,mode)*100)
 return {"blood":"Hunter movement +%d%%","blackout":"Your Dynamo output −%d%%","walls":"Your door damage +%d%%"}.get(id,"") % value if id in IDS else "No extra risk"
static func quote(model,id: String) -> Vector2:
 var room=model.player();var power=0.0
 for b in room.buildings.values():
  if b.kind=="generator":power+=Catalog.support_output("generator",b.level)
 var gold=room.income_rate()
 if id=="blood":return Vector2(roundf(clampf(gold*12,35,12000)),0)
 if id=="blackout":return Vector2(0,roundf(clampf(power*10,7,1000)))
 if id=="walls":return Vector2(roundf(clampf(gold*6,20,6000)),roundf(clampf(power*6,3,500)))
 return Vector2.ZERO
static func payout_text(value: Vector2) -> String:return "+%.0f Gold / +%.0f Electricity" % [value.x,value.y]
func select(model,id: String) -> bool:
 if model.run_kind!="endless" or model.endless.phase!="intermission" or not offered(model.endless.completed) or (id!="" and id not in IDS):return false
 selected=id;reward=quote(model,id)
 return true
func begin(model):
 active=selected if offered(model.endless.completed) else "";active_wave=model.endless.completed+1
 selected=""
func factor(id: String,mode: String) -> float:
 if active!=id:return 1.0
 return 1.0-penalty(id,mode) if id=="blackout" else 1.0+penalty(id,mode)
func finish(model):
 if model.endless.omen!=self or model.endless.phase!="combat" or not model.running or model.result!="":return
 var wave=model.endless.wave
 if active in IDS and active_wave==wave and paid_wave<wave and model.player()!=null and model.player().alive and model.hunter.hp<=0:
  var room=model.player();var gold=maxf(0,minf(reward.x,1e12-room.gold));var power=maxf(0,minf(reward.y,1e12-room.electricity))
  room.gold+=gold;room.electricity+=power;paid_wave=wave
  last={"id":active,"wave":wave,"gold":gold,"power":power}
 active="";selected="";reward=Vector2.ZERO
func snapshot() -> Dictionary:return {"selected":selected,"reward":[reward.x,reward.y],"paid_wave":paid_wave,"last":last.duplicate(true)}
func restore(data: Dictionary):
 selected=data.get("selected","");var amount=data.get("reward",[0,0]);reward=Vector2(amount[0],amount[1]);paid_wave=int(data.get("paid_wave",0));last=data.get("last",{}).duplicate(true);active="";active_wave=0
static func valid(data,completed: int) -> bool:
 if not data is Dictionary or data.size()!=4 or data.get("selected",null) not in ["","blood","blackout","walls"]:return false
 if data.selected!="" and not offered(completed):return false
 if not data.get("reward") is Array or data.reward.size()!=2 or not ReplaySnapshot.number(data.reward[0],0,12000) or not ReplaySnapshot.number(data.reward[1],0,1000):return false
 if data.selected=="" and (data.reward[0]!=0 or data.reward[1]!=0):return false
 if data.selected=="blood" and (data.reward[0]<35 or data.reward[1]!=0):return false
 if data.selected=="blackout" and (data.reward[1]<7 or data.reward[0]!=0):return false
 if data.selected=="walls" and (data.reward[0]<20 or data.reward[1]<3 or data.reward[0]>6000 or data.reward[1]>500):return false
 if not ReplaySnapshot.whole(data.get("paid_wave"),0,completed) or not data.get("last") is Dictionary:return false
 if data.last.is_empty():return data.paid_wave==0
 return data.last.size()==4 and data.last.get("id",null) in IDS and ReplaySnapshot.whole(data.last.get("wave"),1,completed) and data.last.wave==data.paid_wave and ReplaySnapshot.number(data.last.get("gold"),0,12000) and ReplaySnapshot.number(data.last.get("power"),0,1000)
