extends "res://tests/phase6_balance_campaign.gd"
# Matched prior policy matrix on new tactical AI; genuine live resources/navigation.
func run():
 if "--hell-crusher-only" in OS.get_cmdline_user_args():
  var rows=[]
  rows.append(simulate("crusher","hell",StrategyCatalog.TRAIT_IDS[2],"focus",StageCatalog.STAGES[2].id,11,"frontline"))
  rows.append(simulate("crusher","hell","fortified","suppression","stage_5",47,"frontline","","mythic_control"))
  write_results(rows,"balance-hell-crusher-campaign-results.json");return
 if "--ravager-only" not in OS.get_cmdline_user_args():super.run();return
 var rows=[]
 for mi in range(3):
  rows.append(simulate("ravager",["standard","hard","hell"][mi],StrategyCatalog.TRAIT_IDS[(2+mi)%3],["precision","suppression","focus","storm"][(6+mi)%4],StageCatalog.STAGES[(6+mi)%5].id,11,"frontline"))
 rows.append(simulate("ravager","hell","fortified","suppression","stage_5",47,"frontline","","mythic_control"))
 for branch in ["focus","storm"]:rows.append(simulate("ravager","hard","economy",branch,"stage_4",47,"branch_first"))
 write_results(rows,"balance-ravager-campaign-results.json")
func write_results(rows,output):
 var summary={}
 for row in rows:
  var key=row.arm+"_"+row.policy+"_"+row.mode+"_"+row.branch
  if not summary.has(key):summary[key]={"wins":0,"losses":0,"level5":0,"level10":0,"transforms":0}
  summary[key].wins+=int(row.result=="victory");summary[key].losses+=int(row.result!="victory");summary[key].level5+=int(row.level>=5);summary[key].level10+=int(row.level==10);summary[key].transforms+=int(row.transformed)
 var out={"phase":"5D3","matches":rows.size(),"failures":failures,"scope":"Fresh actual earned-currency matches on new tactical AI using matched prior diagnostic policies; prepared progression/finite stock disclosed, no live currencies/HP/positions/time injected. Not human win rates.","master_budget":"Master dreamer+first_aid,4 Shields+1 automatic Heart; no stage bonus","mythic_budget":"Mythic marksman+reaper_slayer,4 Frost+1 TimeFreeze; no stage bonus","rows":rows,"summary":summary}
 var file=FileAccess.open("res://docs/evidence/phase5d3/"+output,FileAccess.WRITE);file.store_string(JSON.stringify(out," "));file.close()
 print("PHASE5D3_AUDIT_CAMPAIGN_MATCHES=",rows.size()," FAILURES=",failures)
 quit(1 if failures else 0)
