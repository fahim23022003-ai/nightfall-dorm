extends SceneTree
var assertions=0
var failures=0
var prefix="user://qa-ranked-phase2-"
var counter=0

func check(ok: bool,label: String):
 assertions+=1
 if not ok:
  failures+=1
  push_error("RANKED_QA_FAIL: "+label)

func fresh_path(tag):
 counter+=1
 return prefix+str(counter)+"-"+tag+".json"

func base_data():
 return {"version":RankCatalog.VERSION,"xp":0,"next_match_id":1,"equipped":[],"settings":{"music":0.5,"effects":0.65,"ambient":0.5,"muted":false,"fullscreen":false,"tutorial":true},"active_match":{},"last_award":{}}

func write_raw(path,text):
 var file=FileAccess.open(path,FileAccess.WRITE)
 check(file!=null,"isolated QA fixture writable")
 if file!=null:
  file.store_string(text)
  file.close()

func write_data(path,data): write_raw(path,JSON.stringify(data))

func eligible_model(mode="standard", equipped=[]):
 var model=MatchModel.new()
 model.configure_match(mode,RankCatalog.bonuses(equipped))
 model.claim_room(0)
 model.player_position=model.player().bed_position()
 model.sleep_player()
 model.time=model.preparation+30
 model.player().occupied_seconds=30
 model.player().damage_dealt=100
 model.player().door_damage_taken=100
 model.hunter.hp=0
 model.hunter.state=HunterState.State.DEAD
 model.result="victory"
 return model

func clean_own_files():
 var directory=DirAccess.open("user://")
 if directory==null: return
 for name in directory.get_files():
  if name.begins_with(prefix.trim_prefix("user://")):
   DirAccess.remove_absolute("user://"+name)

func _initialize():
 prefix+=str(Time.get_ticks_usec())+"-"
 call_deferred("run")

func run():
 print("RANKED_QA persistence: isolated missing/save/backup/corrupt/future")
 var path=fresh_path("roundtrip")
 var profile=PlayerProfile.new(path)
 check(profile.load_profile() and profile.xp==0 and profile.rank_name()=="Bronze","missing profile starts safe Bronze defaults")
 profile.xp=700
 check(profile.save_profile(),"first generation saves")
 var first_generation=FileAccess.get_file_as_string(path)
 profile.xp=1400
 profile.settings.music=0.23
 check(profile.save_profile(),"second generation replaces atomically")
 check(not FileAccess.file_exists(path+".tmp") and FileAccess.get_file_as_string(path+".bak")==first_generation,"successful rename consumes temp and retains previous valid generation")
 var reloaded=PlayerProfile.new(path)
 check(reloaded.load_profile() and reloaded.xp==1400 and is_equal_approx(reloaded.settings.music,0.23),"reopen restores XP and settings")
 var original=FileAccess.get_file_as_string(path)
 reloaded.xp=-1
 check(not reloaded.save_profile() and FileAccess.get_file_as_string(path)==original,"invalid new generation cannot replace valid primary")
 write_raw(path,"{ broken json")
 var damaged_bytes=FileAccess.get_file_as_string(path)
 reloaded=PlayerProfile.new(path)
 check(reloaded.load_profile() and reloaded.xp==700 and reloaded.warning!="","corrupt primary recovers valid older backup with warning")
 check(FileAccess.get_file_as_string(path)==damaged_bytes,"recovery does not silently overwrite damaged primary")
 var quarantined=false
 var directory=DirAccess.open("user://")
 for name in directory.get_files():
  if name.begins_with(path.trim_prefix("user://")+".corrupt."):
   quarantined=FileAccess.get_file_as_string("user://"+name)==damaged_bytes
 check(quarantined,"corrupt bytes preserved in quarantine")
 var future=base_data()
 future.version=RankCatalog.VERSION+1
 future.xp=9999
 write_data(path,future)
 var future_bytes=FileAccess.get_file_as_string(path)
 reloaded=PlayerProfile.new(path)
 check(not reloaded.load_profile() and reloaded.read_only,"future schema disables writes even with valid older backup")
 reloaded.xp=1
 check(not reloaded.save_profile() and FileAccess.get_file_as_string(path)==future_bytes,"future save is preserved byte-for-byte")
 path=fresh_path("orphan-backup")
 var backup_data=base_data()
 backup_data.xp=2400
 write_data(path+".bak",backup_data)
 profile=PlayerProfile.new(path)
 check(profile.load_profile() and profile.xp==2400,"missing primary can recover standalone valid backup")
 path=fresh_path("both-corrupt")
 write_raw(path,"[]")
 write_raw(path+".bak","not-json")
 profile=PlayerProfile.new(path)
 check(not profile.load_profile() and profile.xp==0 and profile.warning!="","corrupt generations fail safely with new defaults and warning")
 print("RANKED_QA schema: reject invalid nested records and bounds")
 var malformed=[]
 var data=base_data()
 data.next_match_id=1e30
 malformed.append([data,"overflowing match sequence"])
 data=base_data()
 data.next_match_id=3
 data.active_match={"id":1.5,"difficulty":"standard","equipped":[]}
 malformed.append([data,"fractional active match ID"])
 data=base_data()
 data.next_match_id=3
 data.active_match={"id":1,"difficulty":"standard","equipped":["first_aid"]}
 malformed.append([data,"locked active loadout"])
 data=base_data()
 data.xp=3800
 data.next_match_id=3
 data.active_match={"id":1,"difficulty":"standard","equipped":["pocket","reinforced"]}
 malformed.append([data,"over-cap active loadout"])
 data=base_data()
 data.next_match_id=3
 data.active_match={"id":1,"difficulty":"standard","equipped":["unknown"]}
 malformed.append([data,"unknown active perk"])
 data=base_data()
 data.next_match_id=3
 data.last_award={"match_id":1.5,"breakdown":{}}
 malformed.append([data,"fractional last award ID"])
 for item in malformed:
  path=fresh_path("malformed")
  write_data(path,item[0])
  profile=PlayerProfile.new(path)
  check(profile._decode(path).is_empty(),"reject "+item[1])
 print("RANKED_QA bounded typed-schema mutation table")
 for key in ["xp","next_match_id"]:
  for value in [-1,1.5,"12",true,null,1e30]:
   data=base_data()
   data[key]=value
   path=fresh_path("typed")
   write_data(path,data)
   profile=PlayerProfile.new(path)
   check(profile._decode(path).is_empty(),"typed schema rejects "+key+"="+str(value))
 for key in ["equipped","settings","active_match","last_award"]:
  data=base_data()
  data[key]="wrong type"
  path=fresh_path("container-type")
  write_data(path,data)
  profile=PlayerProfile.new(path)
  check(profile._decode(path).is_empty(),"container schema rejects "+key+" wrong type")
 data=base_data()
 data.xp=500
 data.next_match_id=3
 data.active_match={"id":1,"difficulty":"standard","equipped":[]}
 data.last_award={"match_id":2,"breakdown":RankCatalog.performance(eligible_model()),"old_rank":0,"new_rank":1,"promoted":true,"result":"victory"}
 path=fresh_path("reversed-sequence")
 write_data(path,data)
 profile=PlayerProfile.new(path)
 check(profile._decode(path).is_empty(),"active match cannot precede or replay an already settled sequence")
 path=fresh_path("oversized")
 write_raw(path,"x".repeat(1024*1024+1))
 profile=PlayerProfile.new(path)
 check(profile._decode(path).is_empty(),"oversized primary is rejected before schema decode")
 path=fresh_path("settings-clamp")
 data=base_data()
 data.settings.music=-5
 data.settings.effects=9
 data.settings.ambient="invalid"
 data.settings.muted="yes"
 write_data(path,data)
 profile=PlayerProfile.new(path)
 check(profile.load_profile() and profile.settings.music==0 and profile.settings.effects==1 and profile.settings.ambient==0.5 and not profile.settings.muted,"volume settings clamp and invalid setting types retain safe defaults")
 check(not profile.update_setting("music",NAN) and not profile.update_setting("music","loud") and not profile.update_setting("missing",0.5),"runtime setting API rejects nonfinite, wrong type and unknown keys")
 path=fresh_path("missing-parent")+"/profile.json"
 profile=PlayerProfile.new(path)
 profile.xp=3800
 check(not profile.save_profile() and not profile.save_ok and profile.warning!="","unwritable missing parent reports save failure")
 check(not profile.equip("marksman") and profile.equipped.is_empty(),"failed equip save rolls back in-memory loadout")
 print("RANKED_QA seeded valid-profile roundtrip properties")
 var random=RandomNumberGenerator.new()
 random.seed=202602
 for sample in range(40):
  path=fresh_path("roundtrip-fuzz")
  profile=PlayerProfile.new(path)
  profile.xp=random.randi_range(0,10000)
  var options=profile.unlocked()
  if sample%3!=0: profile.equipped=[options[random.randi_range(0,options.size()-1)]]
  for key in ["music","effects","ambient"]: profile.settings[key]=random.randf()
  var entry=profile.begin_match("hard" if sample%2 else "standard")
  reloaded=PlayerProfile.new(path)
  check(reloaded.load_profile() and reloaded.xp==profile.xp and reloaded.equipped==profile.equipped,"seeded roundtrip preserves XP and legal loadout")
  check(int(reloaded.active_match.id)==int(profile.active_match.id) and reloaded.active_match.difficulty==profile.active_match.difficulty and reloaded.active_match.equipped==profile.active_match.equipped and reloaded.next_match_id==profile.next_match_id,"seeded roundtrip preserves active snapshot and monotonic counter")
  for key in ["music","effects","ambient"]:
   check(is_equal_approx(reloaded.settings[key],profile.settings[key]),"seeded mix roundtrip: "+key)
 print("RANKED_QA rank boundaries and single unlocked loadout")
 for i in range(RankCatalog.THRESHOLDS.size()):
  var threshold=RankCatalog.THRESHOLDS[i]
  check(RankCatalog.rank_for(threshold)==i,"promotion exactly at threshold "+str(i))
  if i>0: check(RankCatalog.rank_for(threshold-1)==i-1,"rank remains below next threshold")
 path=fresh_path("equip")
 profile=PlayerProfile.new(path)
 check(not profile.equip("reinforced") and not profile.equip("unknown"),"locked and unknown perk cannot equip")
 check(profile.equip("pocket") and profile.equipped==["pocket"],"Bronze can equip unlocked starting perk")
 profile.xp=3800
 check(profile.equip("first_aid") and profile.equipped==["pocket","first_aid"],"Master appends second permanent perk")
 check(profile.equip("first_aid") and profile.equipped==["pocket"],"equipped perk toggles off independently")
 data=base_data()
 data.xp=250
 data.equipped=["first_aid","pocket","pocket","reinforced","unknown"]
 write_data(path,data)
 profile=PlayerProfile.new(path)
 check(profile.load_profile() and profile.equipped==["pocket"],"top-level loaded perks are unlocked unique and capped")
 print("RANKED_QA all six perks alter actual game calculations")
 for perk in RankCatalog.PERKS:
  var model=MatchModel.new()
  check(model.configure_match("standard",RankCatalog.bonuses([perk.id])),"configure fresh perk "+perk.id)
  check(model.claim_room(0),"claim boosted room "+perk.id)
  var room=model.player()
  var max_hp=room.max_hp()
  match perk.id:
   "pocket": check(is_equal_approx(room.gold,30),"starting gold +5 applied exactly once")
   "reinforced":
    check(is_equal_approx(max_hp,Catalog.DOOR_HP[0]*1.05) and is_equal_approx(room.door_hp,max_hp),"reinforced applies 5 percent maximum and initial HP")
    room.gold=1000
    room.door_hp-=20
    room.upgrade_door()
    check(is_equal_approx(room.max_hp(),Catalog.DOOR_HP[1]*1.05) and is_equal_approx(room.max_hp()-room.door_hp,20),"door upgrade retains reinforcement and existing damage")
   "dreamer":
    room.sleeping=true
    var before=room.gold
    room.tick_economy(10)
    check(is_equal_approx(room.gold-before,Catalog.BED_INCOME[0]*1.03*10),"dreamer increases actual income by 3 percent")
    room.sleeping=false
    before=room.gold
    room.tick_economy(10)
    check(room.gold==before,"dreamer never earns while awake")
   "capacitor":
    room.sleeping=true
    room.gold=1000
    room.build("generator",0)
    room.tick_economy(10)
    check(is_equal_approx(room.electricity,Catalog.BUILDINGS.generator.rate*1.04*10),"capacitor increases actual production by 4 percent")
   "marksman":
    room.sleeping=true
    room.gold=1000
    room.build("turret",0)
    model.hunter.state=HunterState.State.MOVE
    model.hunter.position=room.tile_position(0)
    var before=model.hunter.hp
    model._turrets(0.1)
    model._advance_projectiles(0.1)
    check(is_equal_approx(before-model.hunter.hp,Catalog.BUILDINGS.turret.damage*1.03),"marksman increases real impact damage by 3 percent")
   "first_aid":
    room.door_hp=max_hp*0.25
    check(room.try_rescue() and is_equal_approx(room.door_hp,max_hp*0.35),"rescue heals 10 percent at threshold")
    room.door_hp=max_hp*0.2
    check(not room.try_rescue() and is_equal_approx(room.door_hp,max_hp*0.2),"rescue cannot trigger twice")
    room.rescue_used=false
    room.door_hp=0
    check(not room.try_rescue() and room.door_hp==0,"rescue never resurrects broken door")
  check(is_equal_approx(model.rooms[1].gold,25) and is_equal_approx(model.rooms[1].max_hp(),Catalog.DOOR_HP[0]),"player perk does not buff unrelated bot room")
  check(not model.configure_match("hard",{}),"active claimed room blocks loadout mutation")
 print("RANKED_QA bounded transparent awards and exactly-once reload")
 var model=eligible_model()
 var points=RankCatalog.performance(model)
 check(points.eligible and points.total==133,"known victory breakdown is 120+9+2+2")
 check(points.total==points.victory+points.survival+points.damage+points.defense+points.difficulty_bonus+points.loss_adjustment,"breakdown sums exactly to displayed total")
 model.difficulty="hard"
 check(RankCatalog.performance(model).total==166,"hard difficulty adds floor25percent of known133XP base")
 model.result="defeat"
 model.player().alive=false
 check(RankCatalog.performance(model).total==1,"hard defeat is limited to one XP per30occupiedseconds with no modebonus")
 model.difficulty="standard"
 check(RankCatalog.performance(model).total==1,"standard defeat shares the same timebound without victory bonus")
 model=eligible_model()
 model.player().occupied_seconds=20
 model.time=model.preparation+9.99
 check(not RankCatalog.performance(model).eligible,"time before ten active seconds is ineligible even after occupation threshold")
 model.time=model.preparation+10
 check(RankCatalog.performance(model).eligible,"exact occupation and active-time eligibility boundary is accepted")
 for seconds in [0,10,19.9]:
  model.player().occupied_seconds=seconds
  check(RankCatalog.performance(model).total==0,"insufficient occupied time cannot farm rewards")
 model.player().occupied_seconds=100000
 model.player().damage_dealt=10000000
 model.player().door_damage_taken=10000000
 model.time=100000
 model.difficulty="hard"
 check(RankCatalog.performance(model).total<=425,"hard victory award upper bound")
 model.result="defeat"
 model.player().alive=false
 check(RankCatalog.performance(model).total<=30,"legitimate defeat partial progression capped at30")
 path=fresh_path("settle")
 profile=PlayerProfile.new(path)
 profile.xp=240
 profile.equip("pocket")
 var snapshot=profile.begin_match("standard")
 var id=int(snapshot.id)
 snapshot.equipped.clear()
 check(profile.active_match.equipped==["pocket"],"returned snapshot cannot mutate saved active loadout")
 model=eligible_model("standard",["pocket"])
 var award=profile.settle_match(id,model)
 check(not award.is_empty() and profile.xp==373 and award.promoted,"eligible settlement adds exact XP and promotes")
 var awarded=profile.xp
 check(profile.settle_match(id,model).is_empty() and profile.xp==awarded,"repeat settlement same process gives zero duplicate rewards")
 profile=PlayerProfile.new(path)
 check(profile.load_profile() and profile.xp==awarded,"settled progression survives fresh instance")
 check(profile.settle_match(id,model).is_empty() and profile.xp==awarded,"reload cannot duplicate last match reward")
 profile.equip("reinforced")
 snapshot=profile.begin_match("hard")
 id=int(snapshot.id)
 check(id>1,"persisted match sequence remains monotonic")
 model=eligible_model("standard",["reinforced"])
 check(profile.settle_match(id,model).is_empty(),"wrong difficulty cannot settle active snapshot")
 model=eligible_model("hard",["pocket"])
 check(profile.settle_match(id,model).is_empty(),"wrong perk bonuses cannot settle active snapshot")
 print("RANKED_QA finite XP ceiling remains persistable and transparent")
 path=fresh_path("xp-ceiling")
 profile=PlayerProfile.new(path)
 profile.xp=RankCatalog.MAX_XP-10
 check(profile.save_profile(),"valid near-ceiling profile saves")
 snapshot=profile.begin_match("standard")
 model=eligible_model()
 award=profile.settle_match(int(snapshot.id),model)
 check(profile.xp==RankCatalog.MAX_XP and profile.save_ok and award.breakdown.total==10,"near-ceiling win grants only remaining10XP and still saves")
 check(award.breakdown.ceiling_adjustment==-123 and award.breakdown.total==award.breakdown.victory+award.breakdown.survival+award.breakdown.damage+award.breakdown.defense+award.breakdown.difficulty_bonus+award.breakdown.loss_adjustment+award.breakdown.ceiling_adjustment,"ceiling deduction keeps displayed breakdown sum transparent")
 profile=PlayerProfile.new(path)
 check(profile.load_profile() and profile.xp==RankCatalog.MAX_XP,"ceiling-clipped progression survives reload")
 snapshot=profile.begin_match("standard")
 award=profile.settle_match(int(snapshot.id),model)
 check(profile.xp==RankCatalog.MAX_XP and profile.save_ok and award.breakdown.total==0 and award.breakdown.ceiling_adjustment==-133,"at-ceiling match awards zero transparently without breaking persistence")
 reloaded=PlayerProfile.new(path)
 check(reloaded.load_profile() and reloaded.xp==RankCatalog.MAX_XP and reloaded.last_award.breakdown.total==0,"zero ceiling award and exact maximum reload safely")
 clean_own_files()
 print("RANKED_PROGRESSION_ASSERTIONS=",assertions," FAILURES=",failures)
 quit(1 if failures else 0)
