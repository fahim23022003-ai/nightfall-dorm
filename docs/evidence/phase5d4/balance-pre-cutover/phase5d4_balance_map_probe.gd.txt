extends SceneTree
func _initialize():
 var m=MatchModel.new();m.reset(1);m.configure_map("cursed_mansion")
 for r in m.rooms:
  var ds=[]
  for t in range(r.tile_count()):ds.append([t,round(r.tile_position(t).distance_to(r.door_approach()))])
  print("ROOM ",r.index," ",r.trait_id," ",r.tile_count()," ",ds)
 quit()
