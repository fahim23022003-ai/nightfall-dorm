extends "res://tests/replay_endless.gd"
# Presentation must never change simulation, budgets, inventory or checkpoint data.
func run():
 var path="user://cinematic-options-"+str(Time.get_ticks_usec())+".json"
 var p=PlayerProfile.new(path)
 check(p.settings.graphics_quality=="medium","old profile defaults balanced")
 for mode in ["low","medium","high"]:check(p.update_setting("graphics_quality",mode),"valid quality saves "+mode)
 check(not p.update_setting("graphics_quality","ultra") and not p.update_setting("graphics_quality",true),"invalid quality rejected")
 check(p.update_setting("reduced_motion",true) and p.update_setting("reduced_flashes",true),"independent accessibility preferences save")
 var loaded=PlayerProfile.new(path);check(loaded.load_profile(),"new settings profile reloads")
 check(loaded.settings.graphics_quality=="high" and loaded.settings.reduced_motion and loaded.settings.reduced_flashes,"all cinematic preferences restored")
 var a=fixture();var m=a.m;var before=JSON.stringify(ReplaySnapshot.encode(m))
 var presentation=load("res://scripts/dorm_presentation.gd").new()
 for i in range(10):presentation.update(.05,m)
 check(JSON.stringify(ReplaySnapshot.encode(m))==before,"visual updates never mutate checkpoint/model")
 var rig=presentation.nightmare_visual
 check(rig.art.size()==168,"cached six organic four-form rigs complete")
 check(presentation.building_visual.art.size()==68,"all seventeen four-tier machine families cached")
 check(presentation.building_visual.tier_for(1)==0 and presentation.building_visual.tier_for(4)==1 and presentation.building_visual.tier_for(7)==2 and presentation.building_visual.tier_for(10)==3,"true building architecture milestones")
 for kind in StrategyCatalog.ARCHETYPE_IDS:
  for part in ["move","charge","release"]:
   var name="cinematic_"+kind+"_"+part
   check(AudioDirector.EFFECT_NAMES.has(name) and ResourceLoader.exists("res://assets/audio/"+name+".wav"),"sample event resolves "+name)
   if part!="move":check(name in AudioDirector.CRITICAL_EVENTS,"warning and release get priority "+name)
 # Older optional settings must load, not erase permanent progression.
 var data=JSON.parse_string(FileAccess.get_file_as_string(path))
 for key in ["graphics_quality","reduced_motion","reduced_flashes"]:data.settings.erase(key)
 var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(data));f=null
 loaded=PlayerProfile.new(path);check(loaded.load_profile() and loaded.settings.graphics_quality=="medium","legacy settings migrate without new fields")
 print("CINEMATIC_CHECKS=%d FAILURES=%d" % [checks,failures])
 quit(1 if failures else 0)
