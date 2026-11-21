extends SceneTree

func _initialize() -> void:
 run.call_deferred()

func run() -> void:
 var moved:=0
 var unchanged:=0
 var failed:=0
 for theme: String in MapCatalog.IDS:
  for family: String in NightmareMacroLayout.FAMILY_IDS:
   var original:=NightmareMacroLayout.generate(theme,73,family,true)
   for room: Dictionary in original.rooms:
    var patched:=room.duplicate(true)
    LivingDormFurniture.arrange(patched)
    if patched.cabinet!=room.cabinet or patched.plant!=room.plant:moved+=1
    else:unchanged+=1
    if patched.access_route!=room.access_route or patched.interior_nodes!=room.interior_nodes or patched.tiles!=room.tiles or patched.door!=room.door or patched.bed!=room.bed:
     failed+=1
    if patched.cabinet!=room.cabinet and not LivingDormFurniture._fits(patched,patched.floor,"cabinet",patched.cabinet):
     failed+=1
    if patched.plant!=room.plant and not LivingDormFurniture._fits(patched,patched.floor,"plant",patched.plant):
     failed+=1
 print("FURNITURE_LAYOUTS=",moved+unchanged," MOVED=",moved," UNCHANGED=",unchanged," FAILURES=",failed)
 quit(int(failed>0))
