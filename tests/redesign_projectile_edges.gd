extends SceneTree
var assertions=0
var failures=0
func check(ok: bool,message: String):
 assertions+=1
 if not ok:
  failures+=1
  push_error("PROJECTILE_EDGE_FAIL: "+message)
func fixture():
 var model=MatchModel.new()
 model.claim_room(1)
 model.player_position=model.player().bed_position()
 model.sleep_player()
 var source=model.rooms[0]
 source.owner=1
 source.sleeping=true
 source.gold=1000
 source.build("turret",2)
 model.hunter.state=HunterState.State.MOVE
 model.hunter.position=source.tile_position(2)+Vector2(100,0)
 return model
func _initialize(): call_deferred("run")
func run():
 var model=fixture()
 model._turrets(0.01)
 var shot=model.projectiles[0]
 var start=shot.position
 model.hunter.position=start+Vector2(0,100)
 model._advance_projectiles(0.1)
 check(shot.position.y>start.y and is_equal_approx(shot.position.x,start.x),"flight tracks the actual moving target instead of original aim")
 check(model.damage_dealt==0,"moving target remains undamaged before arrival")
 model.rooms[0].alive=false
 model._advance_projectiles(0.2)
 check(model.projectiles.is_empty() and model.hunter.hp<Catalog.HUNTER.hp,"already launched ally projectile completes flight after source elimination")
 check(model.rooms[0].damage_dealt>0 and model.player().damage_dealt==0,"late impact credits its original source resident only")
 model=fixture()
 model._turrets(0.01)
 var hp=model.hunter.hp
 model.hunter.position=Vector2(10000,10000)
 model._advance_projectiles(Catalog.PROJECTILES.max_age+1)
 check(model.projectiles.is_empty() and model.hunter.hp==hp,"escaping beyond lifetime expires shot without phantom damage")
 check(model.combat_events.back().type=="cancel" and model.combat_events.back().reason=="expired","expiration has correlated cancellation evidence")
 model=fixture()
 for i in range(Catalog.PROJECTILES.max_active):
  model.rooms[0].buildings[2].cooldown=0
  model._turrets(0.001)
 check(model.projectiles.size()==Catalog.PROJECTILES.max_active,"buffer reaches cap without exceeding it")
 var fired=model.shots
 model.rooms[0].buildings[2].cooldown=0
 model._turrets(0.001)
 check(model.shots==fired,"cap rejects extra launch without incrementing shots")
 model.projectiles.pop_back()
 model._turrets(0.001)
 check(model.projectiles.size()==Catalog.PROJECTILES.max_active and model.shots==fired+1,"launch resumes when a buffer slot becomes available")
 model.reset(2)
 check(model.next_projectile_id==1 and model.next_combat_event_id==1 and model.combat_events.is_empty(),"restart resets both event and projectile sequences")
 # Hunter is already in physical contact with an awake player at tick start.
 # A late allied projectile must not reverse the resulting player elimination.
 model=MatchModel.new()
 model.claim_room(1)
 model.player_position=model.player().bed_position()
 model.time=model.preparation+26
 var ally=model.rooms[0]
 ally.owner=1
 ally.sleeping=true
 ally.gold=1000
 ally.build("turret",2)
 model.hunter.state=HunterState.State.MOVE
 model.hunter.position=model.player_position
 model.hunter.hp=1
 model._turrets(0.01)
 check(model.projectiles.size()==1,"contact-priority fixture has a genuine allied shot in flight")
 model.tick(0.5)
 check(model.result=="defeat" and not model.player().alive and model.eliminations==1,"awake contact has defeat priority over a simultaneous allied lethal impact")
 print("REDESIGN_PROJECTILE_EDGE_ASSERTIONS=",assertions," FAILURES=",failures)
 quit(1 if failures else 0)
