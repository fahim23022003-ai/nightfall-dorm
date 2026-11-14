extends SceneTree
func _initialize():
 var machines=[]
 for kind in Catalog.BUILDINGS:
  var upgrades=[];var total=BalanceRules.price(kind,2)
  for level in range(1,10):
   var price=BalanceRules.upgrade(kind,level,2);upgrades.append([price.x,price.y]);total+=price
  machines.append({"id":kind,"name":Catalog.BUILDINGS[kind].name,"purchase":[BalanceRules.price(kind,2).x,BalanceRules.price(kind,2).y],"upgrade_1_to_10":upgrades,"purchase_plus_upgrades":[total.x,total.y],"branch_fee_excluded":[25,4]})
 var expansions=[]
 for tier in range(1,8):
  var price=BalanceRules.expansion(tier,2);expansions.append({"tier":tier,"capacity":RoomExpansion.SLOTS[tier],"gold":price.x,"electricity":price.y,"bed_door_display_required":tier+1})
 var f=FileAccess.open("res://docs/evidence/earned-power/final-balance-tables.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"version":2,"starting_gold":BalanceRules.START_GOLD,"preparation":BalanceRules.PREPARATION,"bed_income":BalanceRules.BED,"bed_upgrade_gold":BalanceRules.BED_G,"bed_upgrade_electricity":BalanceRules.BED_E,"door_hp_unmodified":Catalog.DOOR_HP,"door_upgrade_gold":BalanceRules.DOOR_G,"door_upgrade_electricity":BalanceRules.DOOR_E,"dynamo_output":BalanceRules.DYNAMO,"machines":machines,"expansions":expansions,"run_perks":RunChoices.CATALOG,"merchant_base_gold":BalanceRules.MERCHANT_GOLD,"merchant_electricity":BalanceRules.MERCHANT_POWER}," "));quit()
