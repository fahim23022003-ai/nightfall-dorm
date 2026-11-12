extends SceneTree
func _initialize():
 var checks=0
 for id in StrategyCatalog.ARCHETYPE_IDS:
  assert(ResourceLoader.exists("res://assets/premium_ui/"+id+".svg"));checks+=1
  var texture=PremiumButton.texture(id)
  assert(texture!=null and texture.get_width()>0 and texture.get_height()>0);checks+=1
  var button=Button.new();button.text=StrategyCatalog.ARCHETYPES[id].name;button.icon=texture;PremiumButton.decorate(button,true);assert(button.icon==texture);checks+=1
  button.free()
 print("OVERHAUL_HUNTER_MENU_ART_CHECKS=%d FAILURES=0" % checks);quit()
