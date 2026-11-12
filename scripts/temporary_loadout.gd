class_name TemporaryLoadout
extends PlayerProfile
# An isolated in-memory wallet. No file writes, progression or reward transactions.
var local_kind="practice"
func _temporary_marker():return true
func _init(kind="practice",selected: Array=["shield","repair"]):
 super("user://unused-temporary-profile.json")
 local_kind=kind;tutorial_completed=true
 for id in ItemCatalog.IDS:inventory[id]=5
 item_loadout=[]
 for id in selected:
  if id in ItemCatalog.IDS and id not in item_loadout and item_loadout.size()<2:item_loadout.append(id)
 active_match={"id":1,"items":item_loadout.duplicate(),"legendary_used":0}
func save_profile() -> bool:return true
func settle_match(_id: int,_model) -> Dictionary:return {}
func buy_common(_id: String,_token) -> bool:return false
func consume_item(item: String,model,id: int) -> bool:
 if model.run_kind!=local_kind or local_kind not in ["practice","challenge"] or id!=1 or item not in active_match.items or int(inventory.get(item,0))<=0:return false
 if ItemCatalog.legendary(item):
  if maxi(int(active_match.legendary_used),model.items.legendary_used)>=1:return false
  active_match.legendary_used+=1
 inventory[item]-=1
 return true
