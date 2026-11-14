class_name PracticeRoom
extends RefCounted
static func configure(model,archetype="crusher",boss=false,selected: Array=["shield","repair"],map="abandoned_dorm",version=1) -> TemporaryLoadout:
 model.reset(17);model.run_kind="practice";model.tutorial_mode=false
 model.configure_map(map);model.configure_match("standard",{});model.configure_strategy(17,archetype)
 model.configure_balance(version)
 model.claim_room(0);model.player_position=model.player().bed_position();model.sleep_player()
 var room=model.player();room.gold=20000;room.electricity=5000
 for i in range(4):room.upgrade_bed();room.upgrade_door()
 var nearest=0
 for tile in range(room.tile_count()):
  if room.tile_position(tile).distance_to(room.door_approach())<room.tile_position(nearest).distance_to(room.door_approach()):nearest=tile
 model.practice_tile=nearest
 room.build("turret",nearest)
 for i in range(3):room.upgrade_building(nearest)
 if "rescue" in selected:
  var other=model.rooms[1];other.owner=1;other.closed=true;other.sleeping=true;other.resident_position=other.bed_position();other.door_hp=other.max_hp()*.65
 model.bot_claimed=5;model.time=model.preparation+1
 model.hunter.boss_policy={"enabled":boss,"opening":0.0,"hp_fraction":1.0,"deadline":0.0,"recovery":1.0}
 model.hunter.target=0;model.hunter.state=HunterState.State.MOVE
 var wallet=TemporaryLoadout.new("practice",selected)
 wallet.bind_items(model,1)
 return wallet
