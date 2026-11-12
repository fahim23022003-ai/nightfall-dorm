class_name ChallengeCode
extends RefCounted
const RULESET=1
const FIXED_STEP=1.0/30.0
static func encode(config: Dictionary) -> String:
 var map_index=MapCatalog.IDS.find(config.get("map",""))
 var archetype=StrategyCatalog.ARCHETYPE_IDS.find(config.get("archetype",""))
 var mode=["standard","hard","hell"].find(config.get("difficulty",""))
 var seed_value=int(config.get("seed",0));var preset=int(config.get("preset",0));var gear=int(config.get("gear",0))
 if map_index<0 or archetype<0 or mode<0 or seed_value<1 or seed_value>999999 or preset not in [0,1] or gear not in [0,1]:return ""
 var body="NF2-%d-%d-%d-%d-%d-%d-%d" % [RULESET,map_index,seed_value,archetype,mode,preset,gear]
 return body+"-"+body.sha256_text().left(8).to_upper()
static func decode(raw: String) -> Dictionary:
 if raw.length()>128:return {"ok":false,"error":"Code exceeds 128 characters."}
 var code=raw.strip_edges().to_upper()
 var expression=RegEx.new();expression.compile("^NF2-[0-9]+-[0-9]+-[0-9]+-[0-9]+-[0-9]+-[0-9]+-[0-9]+-[A-F0-9]{8}$")
 if expression.search(code)==null:return {"ok":false,"error":"Malformed code. Paste the complete NF2 code."}
 var parts=code.split("-");var numbers=[]
 for i in range(1,8):
  if parts[i].length()>6:return {"ok":false,"error":"Code field is out of range."}
  numbers.append(int(parts[i]))
 if numbers[0]!=RULESET:return {"ok":false,"error":"Incompatible challenge ruleset."}
 if numbers[1] not in range(5) or numbers[2]<1 or numbers[2]>999999 or numbers[3] not in range(3) or numbers[4] not in range(3) or numbers[5] not in [0,1] or numbers[6] not in [0,1]:return {"ok":false,"error":"Unsupported map, mode, seed or normalized gear preset."}
 var config={"map":MapCatalog.IDS[numbers[1]],"seed":numbers[2],"archetype":StrategyCatalog.ARCHETYPE_IDS[numbers[3]],"difficulty":["standard","hard","hell"][numbers[4]],"preset":numbers[5],"gear":numbers[6]}
 var canonical=encode(config)
 if canonical!=code:return {"ok":false,"error":"Checksum or canonical formatting mismatch."}
 return {"ok":true,"config":config,"code":canonical,"error":""}
static func configure(model,config: Dictionary) -> bool:
 if encode(config)=="" or model.time>0 or model.player_room>=0:return false
 model.reset(int(config.seed));model.run_kind="challenge"
 model.configure_map(config.map);model.configure_match(config.difficulty,{})
 model.configure_strategy(config.seed,config.archetype)
 model.hunter.boss_policy={"enabled":true,"opening":70.0,"hp_fraction":.55,"deadline":120.0,"recovery":1.0}
 for room in model.rooms:room.gold=25.0 if int(config.preset)==0 else 15.0
 model.challenge_config=config.duplicate(true);model.challenge_code=encode(config)
 return true
