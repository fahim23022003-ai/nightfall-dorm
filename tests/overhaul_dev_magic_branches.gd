extends SceneTree
var checks=0
var failures=0
func check(value,label=""):
 checks+=1
 if not value:failures+=1;push_error("MAGIC_BRANCH %d %s" % [checks,label])
func _initialize():call_deferred("run")
func run():
 for kind in MagicDefense.KINDS:
  for branch in StrategyCatalog.branches(kind):
   var room=RoomState.new(0);room.layout=MapCatalog.map("cursed_mansion").rooms[0];room.owner=0;room.sleeping=true;room.closed=true;room.strategy_enabled=true;room.bed_level=4;room.door_level=4;room.door_hp=room.max_hp();room.gold=1e6;room.electricity=1e6
   check(room.build(kind,0),"purchase")
   for i in range(3):check(room.upgrade_building(0),"paidupgrade")
   var b=room.buildings[0];var before=MagicDefense.stats(b);var preview=BuildingStats.branch_preview(null,room,b,branch)
   check("→" in preview and StrategyCatalog.BRANCHES[branch].description in preview,"computedpreview")
   check(PremiumButton.texture(branch)!=null,"nonnulloriginalglyph")
   check(room.specialize_building(0,branch),"paidexclusivebranch")
   check(not room.specialize_building(0,StrategyCatalog.branches(kind)[1]),"exclusive")
   for i in range(5):check(room.upgrade_building(0),"paidlateupgrade")
   check(room.buildings[0].level==10 and not room.upgrade_building(0),"max10")
   check("MAX" in BuildingStats.next_machine(null,room,0),"maxpreview")
   check(not BuildingStats.format_machine(null,room,room.buildings[0]).is_empty(),"computedstats")
 print("OVERHAUL_MAGIC_BRANCH_CHECKS=%d FAILURES=%d" % [checks,failures]);quit(1 if failures else 0)
