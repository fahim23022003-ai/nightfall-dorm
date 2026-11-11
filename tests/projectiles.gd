extends SceneTree
var assertions = 0
var failures = 0

func check(condition: bool, label: String):
 assertions += 1
 if not condition:
  failures += 1
  push_error("PROJECTILE FAIL: "+label)

func fixture() -> MatchModel:
 var game = MatchModel.new()
 game.claim_room(0)
 game.player_position = game.player().bed_position()
 game.sleep_player()
 game.player().gold = 1000
 game.buy("turret",0)
 game.hunter.state = HunterState.State.MOVE
 game.hunter.position = game.player().tile_position(0)+Vector2(200,0)
 return game

func _initialize():
 call_deferred("run")

func run():
 var game = fixture()
 var hp = game.hunter.hp
 game._turrets(0.1)
 check(game.projectiles.size()==1 and game.shots==1,"turret launches a real owned projectile")
 var shot = game.projectiles[0]
 check(shot.position==shot.from and shot.room==0 and shot.kind=="turret" and shot.level==1,"launch metadata exposes actual origin and owner")
 check(game.hunter.hp==hp and game.damage_dealt==0,"launch applies no damage")
 game._advance_projectiles(0.1)
 check(is_equal_approx(shot.position.distance_to(shot.from),Catalog.PROJECTILES.turret*0.1),"projectile travels configured distance per second")
 check(game.hunter.hp==hp,"no impact before projectile reaches target")
 game._advance_projectiles(0.3)
 check(game.hunter.hp==hp and game.projectiles.size()==1,"nearby projectile still cannot deal early damage")
 game._advance_projectiles(0.02)
 check(game.projectiles.is_empty() and is_equal_approx(hp-game.hunter.hp,Catalog.BUILDINGS.turret.damage),"damage applies on actual arrival only")
 check(is_equal_approx(game.player().damage_dealt,Catalog.BUILDINGS.turret.damage),"impact credits source resident")
 check(game.combat_events.size()==2 and game.combat_events[0].type=="launch" and game.combat_events[1].type=="impact","launch and impact are correlated events")
 check(game.combat_events[0].projectile_id==game.combat_events[1].projectile_id and game.combat_events[1].position==game.hunter.position,"impact event identifies shot and actual impact position")
 game._age_combat_events(Catalog.PROJECTILES.event_lifetime+0.01)
 check(game.combat_events.is_empty(),"presentation events expire")
 game = fixture()
 game._turrets(0.1)
 var paused_position = game.projectiles[0].position
 game.running = false
 game.tick(1)
 game._advance_projectiles(1)
 check(game.projectiles[0].position==paused_position and game.damage_dealt==0,"pause freezes projectile travel and damage")
 game.running = true
 game.hunter.state = HunterState.State.DEAD
 game._advance_projectiles(1)
 check(game.projectiles.is_empty() and game.damage_dealt==0,"dead target cancels projectile without damage")
 game = fixture()
 game.hunter.hp = 0
 game._turrets(0.1)
 check(game.shots == 0 and game.projectiles.is_empty(),"zero HP target cannot attract new shots even before state transition")
 game = fixture()
 game._turrets(0.1)
 game.projectiles[0].target_id = 99
 game._advance_projectiles(1)
 check(game.projectiles.is_empty() and game.damage_dealt==0,"invalid target cancels projectile")
 game = fixture()
 game._turrets(0.1)
 game.projectiles[0].age = Catalog.PROJECTILES.max_age
 game._advance_projectiles(0.1)
 check(game.projectiles.is_empty() and game.damage_dealt==0,"stale projectiles expire without damage")
 game = fixture()
 game._turrets(0.1)
 game.hunter.position = game.projectiles[0].position
 game.hunter.hp = 1
 game.player().buildings[0].cooldown = 0
 game._turrets(0.1)
 game._advance_projectiles(0.01)
 check(game.hunter.hp==0 and game.damage_dealt==1 and game.projectiles.is_empty(),"lethal impact clamps actual damage and cancels other shots")
 game = fixture()
 game._turrets(0.1)
 game.preparation = 0
 game.player().door_hp = 0
 game.hunter.state = HunterState.State.BREACH
 game.hunter.target = 0
 game.hunter.position = game.player().bed_position()
 hp = game.hunter.hp
 game.tick(0.1)
 check(game.result=="defeat" and game.projectiles.is_empty() and game.hunter.hp==hp,"terminal breach cancels flight before pending damage")
 game.tick(10)
 game._advance_projectiles(10)
 check(game.hunter.hp==hp and game.damage_dealt==0,"no projectile damage after result")
 game = fixture()
 game._turrets(0.1)
 game.reset(42)
 check(game.projectiles.is_empty() and game.combat_events.is_empty() and game.next_projectile_id==1,"restart clears projectile and event state")
 var first = fixture()
 var second = fixture()
 for i in range(20):
  for candidate in [first,second]:
   candidate.hunter.position.y += 0.25
   candidate._advance_projectiles(0.05)
   candidate._turrets(0.05)
 check(first.projectiles==second.projectiles and first.hunter.hp==second.hunter.hp and first.combat_events==second.combat_events,"identical deterministic flight inputs reproduce positions damage and events")
 game = fixture()
 for i in range(Catalog.PROJECTILES.max_active+10):
  game.player().buildings[0].cooldown = 0
  game._turrets(0.001)
 check(game.projectiles.size()==Catalog.PROJECTILES.max_active and game.combat_events.size()<=Catalog.PROJECTILES.max_events,"projectile and event buffers stay bounded")
 print("PROJECTILE_ASSERTIONS=",assertions," FAILURES=",failures)
 quit(1 if failures else 0)
