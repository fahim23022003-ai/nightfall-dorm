class_name RunChoices
extends RefCounted
# Independent deterministic reward stream; no global/audio/gameplay RNG draws.
const CATALOG={
 "ledger":{"name":"Night Ledger","icon":"economy","text":"Run: +12% occupied-bed production; weapons fire 8% slower. One selection."},
 "grid":{"name":"Thrifty Grid","icon":"generator","text":"Next3 Dynamo/amplifier purchases cost20% less. Actual spend governs refunds. One selection."},
 "discipline":{"name":"Clean Defenses","icon":"door","text":"Clear with intact door ≥80% HP: earn3s current income,10–80Gold, once per wave. No recursive income."},
 "latch":{"name":"Last Latch","icon":"shield","text":"One charge/run: prevent one lethal intact-door strike, leave up to10% HP (max150). Does not revive a breached door."},
 "rhythm":{"name":"Repair Rhythm","icon":"repair","text":"Manual repairs15% cheaper below50% door HP; Dynamos produce5% less. Run duration."},
 "thorns":{"name":"Thorn Debt","icon":"barrier","text":"Retaliate 5% actual Hunter door damage, 12HP burst /12HP per second refill. No reflected damage triggers. Run duration."},
 "cadence":{"name":"Heavy Cadence","icon":"turret","text":"Owned weapon hits+20%; firing interval+15%. Burn unchanged. Run duration."},
 "beat":{"name":"Sixth Beat","icon":"frost","text":"Every6 actual Hunter projectile hits: brief12% suppression; ≥6s proc gap, shares existing control limits."},
 "mercy":{"name":"Mercy Spark","icon":"auto_repair","text":"Actual weapon hits restore 1.5% damage to an intact door, 6HP burst /6HP per second refill. No overheal or revival."},
 "mixed":{"name":"Mixed Circuit","icon":"heavy","text":"While owning Physical and Magic weapons: +8% hit damage. Floor-space tradeoff; run duration."},
 "workshop":{"name":"Working Dorm","icon":"enhancer","text":"With3 different permanent support types: +8% bed output; weapon range−5%. Run duration."},
 "reserve":{"name":"Reserve Cell","icon":"power","text":"One emergency action/run: +20Electricity only below40% intact-door HP. Use in Run Supplies; cannot sell the charge."}}
const ITEMS=["repair","shield","pillow","frost","barricade"]
var selected=[]
var draft=[]
var draft_wave=0
var offers=[]
var offer_wave=0
var used={}
var stock={}
var paid_wave=0
var hits=0
var last_proc=-100.0
var heal_tokens=6.0
var thorn_tokens=12.0
var payment: Callable
func enabled(m) -> bool:return m.balance_version==2 and m.run_kind=="endless"
func has(id: String) -> bool:return id in selected
func available(id,m) -> bool:
 var r=m.player()
 if id in selected:return false
 if id in ["cadence","beat","mercy","mixed"] and not r.buildings.values().any(func(b):return b.kind in DefenseEffects.WEAPONS):return false
 if id in ["grid","rhythm"] and not r.buildings.values().any(func(b):return b.kind=="generator"):return false
 if id=="grid" and r.buildings.size()>=r.tile_count():return false
 if id=="workshop":
  var kinds=[]
  for b in r.buildings.values():
   if b.kind not in DefenseEffects.WEAPONS and b.kind not in kinds:kinds.append(b.kind)
  if kinds.size()<3:return false
 if id=="mixed":
  var types=[]
  for b in r.buildings.values():
   if b.kind in DefenseEffects.WEAPONS and DamageRules.weapon(b.kind).type not in types:types.append(DamageRules.weapon(b.kind).type)
  if types.size()<2:return false
 return true
func prepare(m):
 if not enabled(m) or m.endless.phase!="intermission":return
 var wave=m.endless.completed
 if wave in [1,4,8,13,19,26] and draft_wave!=wave:
  draft_wave=wave;draft=[];var choices=[]
  for id in CATALOG:
   if available(id,m):choices.append(id)
  var rng=RandomNumberGenerator.new();rng.seed=m.endless.seed_value*7919+wave*104729+222
  while draft.size()<3 and not choices.is_empty():draft.append(choices.pop_at(rng.randi_range(0,choices.size()-1)))
 if offer_wave!=wave:
  offer_wave=wave;offers=[];var pool=ITEMS.filter(func(id):return id!="pillow" or m.player().bed_level>=1);var rng=RandomNumberGenerator.new();rng.seed=m.endless.seed_value*6151+wave*421+19
  while offers.size()<3 and not pool.is_empty():
   var id=pool.pop_at(rng.randi_range(0,pool.size()-1));var price=BalanceRules.merchant_price(m.player(),id);offers.append({"id":id,"gold":price.x,"power":price.y,"left":1})
func choose(m,id: String) -> bool:
 if not enabled(m) or m.endless.phase!="intermission" or id not in draft or not available(id,m):return false
 selected.append(id);draft=[];apply(m);return true
func decline(m) -> bool:
 if not enabled(m) or m.endless.phase!="intermission":return false
 draft=[];return true
func buy(m,id: String) -> bool:
 if not enabled(m) or m.endless.phase!="intermission" or not m.running:return false
 for offer in offers:
  if offer.id!=id or offer.left!=1 or int(stock.get(id,0))>=3:continue
  if not m.player().pay(offer.gold,offer.power,"merchant: "+id):return false
  offer.left=0;stock[id]=int(stock.get(id,0))+1;return true
 return false
func consume(m,id: String,limit=1) -> bool:
 if int(used.get(id,0))>=limit:return false
 if payment.is_valid() and not payment.call(id,int(used.get(id,0))+1):return false
 used[id]=int(used.get(id,0))+1;return true
func activate(m,id: String) -> bool:
 if not enabled(m) or not m.running or m.result!="" or m.endless.phase!="combat" or m.player()==null:return false
 if id=="reserve":
  var r=m.player()
  if not has(id) or r.door_hp<=0 or r.door_hp>=r.max_hp()*.4 or not consume(m,id):return false
  r.electricity+=20;r.ledger.note("other",[0,20],"Reserve Cell one charge");return true
 if int(stock.get(id,0))<=0 or m.items.can_activate(id,m)!="":return false
 if not consume(m,id,100000):return false
 stock[id]-=1;m.items.apply(id,m);return true
func apply(m):
 if m.player()==null:return
 var r=m.player();r.run_effects={}
 if not enabled(m):return
 r.run_effects={"income":1.12 if has("ledger") else 1.0,"interval":1.08 if has("ledger") else 1.0,"damage":1.2 if has("cadence") else 1.0,"range":.95 if has("workshop") else 1.0,"infrastructure_discount":.8 if has("grid") and int(used.get("grid",0))<3 else 1.0,"rhythm":has("rhythm"),"power":.95 if has("rhythm") else 1.0}
 if has("cadence"):r.run_effects.interval*=1.15
 var supports=[];var types=[]
 for b in r.buildings.values():
  if b.kind not in DefenseEffects.WEAPONS and b.kind not in supports:supports.append(b.kind)
  if b.kind in DefenseEffects.WEAPONS and DamageRules.weapon(b.kind).type not in types:types.append(DamageRules.weapon(b.kind).type)
 if has("workshop") and supports.size()>=3:r.run_effects.income*=1.08
 if has("mixed") and types.size()>=2:r.run_effects.damage*=1.08
func tick(m,delta):
 if not enabled(m):return
 heal_tokens=minf(6,heal_tokens+delta*6);thorn_tokens=minf(12,thorn_tokens+delta*12);apply(m)
func event(m,type: String,room: int,data: Dictionary):
 if not enabled(m) or room!=m.player_room:return
 if type=="build" and has("grid") and data.get("kind","") in ["generator","economy"]:used.grid=mini(3,int(used.get("grid",0))+1);apply(m)
func impact(m,damage: float):
 if not enabled(m) or damage<=0:return
 var r=m.player();hits+=1
 if has("mercy") and r.door_hp>0:
  var value=minf(heal_tokens,minf(damage*.015,r.max_hp()-r.door_hp));r.door_hp+=value;heal_tokens-=value
  if value>0:m.record_event("healing",r.index,{"amount":value})
 if has("beat") and hits%6==0 and m.time-last_proc>=6 and m.items.control_recovery<=0:
  m.hunter.apply_suppression(.12);m.items.control_recovery=maxf(m.items.control_recovery,1.0);last_proc=m.time
func incoming(m,amount: float) -> float:
 var r=m.player()
 if enabled(m) and has("latch") and r.door_hp>0 and amount>=r.door_hp and consume(m,"latch"):
  return maxf(0,r.door_hp-minf(150,r.max_hp()*.1))
 return amount
func retaliate(m,amount: float):
 if not enabled(m) or not has("thorns") or amount<=0 or m.wrath.domain_active() and m.wrath.domain_room!=m.player_room:return
 var value=minf(thorn_tokens,amount*.05);thorn_tokens-=value
 if value>0:
  var hp=m.hunter.hp;m.hunter.hurt(value);m.credit_damage(m.player_room,maxf(0,hp-m.hunter.hp),1)
func finish(m):
 if not enabled(m) or paid_wave>=m.endless.wave:return
 paid_wave=m.endless.wave
 if has("discipline") and m.player().door_hp>=m.player().max_hp()*.8:
  var value=clampf(m.player().income_rate()*3,10,BalanceRules.DISCIPLINE_MAX);m.player().gold+=value;m.player().ledger.note("other",[value,0],"Clean Defenses cleared wave")
func snapshot() -> Dictionary:return {"selected":selected.duplicate(),"draft":draft.duplicate(),"draft_wave":draft_wave,"offers":offers.duplicate(true),"offer_wave":offer_wave,"used":used.duplicate(true),"stock":stock.duplicate(true),"paid_wave":paid_wave,"hits":hits,"last_proc":last_proc,"heal_tokens":heal_tokens,"thorn_tokens":thorn_tokens}
func restore(data):
 for key in snapshot():set(key,data[key].duplicate(true) if data[key] is Dictionary or data[key] is Array else data[key])
static func valid(data,completed: int) -> bool:
 if not data is Dictionary:return false
 for key in ["selected","draft"]:
  if not data.get(key) is Array or data[key].size()>(12 if key=="selected" else 3):return false
  var seen=[]
  for id in data[key]:
   if id not in CATALOG or id in seen or key=="draft" and id in data.selected:return false
   seen.append(id)
 for key in ["draft_wave","offer_wave","paid_wave","hits"]:
  if not ReplaySnapshot.whole(data.get(key)):return false
 if data.offer_wave>completed or data.draft_wave>completed or data.paid_wave>completed:return false
 for key in ["used","stock"]:
  if not data.get(key) is Dictionary or data[key].size()>18:return false
  for id in data[key]:
   if id not in ITEMS+["reserve","latch","grid"] or not ReplaySnapshot.whole(data[key][id],0,3 if key=="stock" else 100000):return false
 if not data.get("offers") is Array or data.offers.size()>3:return false
 var seen=[]
 for row in data.offers:
  if not row is Dictionary or row.get("id") not in ITEMS or row.id in seen or not ReplaySnapshot.whole(row.get("left"),0,1) or not ReplaySnapshot.number(row.get("gold"),1,4000) or not ReplaySnapshot.number(row.get("power"),1,100):return false
  seen.append(row.id)
 return ReplaySnapshot.number(data.get("last_proc"),-100,1e12) and ReplaySnapshot.number(data.get("heal_tokens"),0,6) and ReplaySnapshot.number(data.get("thorn_tokens"),0,12)

func apply_journal(journal: Dictionary):
 for id in journal:
  var delta=maxi(0,int(journal[id])-int(used.get(id,0)))
  if id in ITEMS:stock[id]=maxi(0,int(stock.get(id,0))-delta)
  used[id]=maxi(int(journal[id]),int(used.get(id,0)))
