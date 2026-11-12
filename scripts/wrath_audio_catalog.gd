extends RefCounted
# Sound-only data; no gameplay, save, or model RNG mutation.
const NAMES = [
 "shot_needle_precision",
 "shot_needle_suppression",
 "shot_needle_high",
 "shot_arc_focus",
 "shot_arc_storm",
 "shot_arc_high",
 "shot_flame",
 "shot_flame_high",
 "shot_frost",
 "shot_frost_high",
 "shot_shock",
 "shot_shock_high",
 "impact_flame",
 "impact_frost",
 "impact_shock",
 "branch_select",
 "ui_hover",
 "ui_confirm",
 "ui_fail",
 "shield_activate",
 "shield_absorb",
 "auto_repair_activate",
 "decoy_activate",
 "hunter_crusher_warning",
 "hunter_crusher_pressure",
 "hunter_stalker_warning",
 "hunter_stalker_conceal",
 "hunter_stalker_feint",
 "hunter_ravager_warning",
 "hunter_ravager_dash",
 "hunter_evolve",
 "buff_offense",
 "buff_armor",
 "buff_speed",
 "buff_resource",
 "buff_command",
 "undead_spawn",
 "undead_attack",
 "undead_hurt",
 "undead_death",
 "reaper_phase_2",
 "scythe_throw",
 "scythe_embed",
 "scythe_tick",
 "scythe_end",
 "shot_flame_searing",
 "shot_flame_wildfire",
 "shot_frost_deep_chill",
 "shot_frost_rime_field",
 "shot_shock_capacitor_burst",
 "shot_shock_rapid_discharge",
 "shot_needle_precision_high",
 "shot_needle_suppression_high",
 "shot_arc_focus_high",
 "shot_arc_storm_high",
 "shot_flame_searing_high",
 "shot_flame_wildfire_high",
 "shot_frost_deep_chill_high",
 "shot_frost_rime_field_high",
 "shot_shock_capacitor_burst_high",
 "shot_shock_rapid_discharge_high",
 "generator_activate",
 "resource_gold",
 "resource_power",
 "hunter_charged_warning",
 "undead_spawn_enhanced",
 "lock_release",
 "build_flame",
 "build_frost",
 "build_shock",
 "build_auto_repair",
 "build_shield",
 "build_decoy",
 "wrath_warning_summon",
 "wrath_activate_summon",
 "wrath_warning_assault",
 "wrath_activate_assault",
 "wrath_warning_soul_steal",
 "wrath_activate_soul_steal",
 "wrath_warning_scythe_slash",
 "wrath_activate_scythe_slash",
 "wrath_warning_rules_judgement",
 "wrath_activate_rules_judgement",
 "wrath_warning_eternal_sacrifices",
 "wrath_activate_eternal_sacrifices",
 "wrath_warning_enhanced_undead",
 "wrath_activate_enhanced_undead",
 "wrath_warning_soul_reaper",
 "wrath_activate_soul_reaper",
 "wrath_warning_phantom_scream",
 "wrath_activate_phantom_scream",
 "wrath_warning_final_judgement",
 "wrath_activate_final_judgement",
 "wrath_warning_crimson_execution",
 "wrath_activate_crimson_execution"
]
const CRITICAL_NAMES = [
 "branch_select",
 "shield_activate",
 "auto_repair_activate",
 "decoy_activate",
 "hunter_crusher_warning",
 "hunter_stalker_warning",
 "hunter_ravager_warning",
 "hunter_evolve",
 "buff_offense",
 "buff_armor",
 "buff_speed",
 "buff_resource",
 "buff_command",
 "reaper_phase_2",
 "generator_activate",
 "hunter_charged_warning",
 "build_flame",
 "build_frost",
 "build_shock",
 "build_auto_repair",
 "build_shield",
 "build_decoy",
 "wrath_warning_summon",
 "wrath_activate_summon",
 "wrath_warning_assault",
 "wrath_activate_assault",
 "wrath_warning_soul_steal",
 "wrath_activate_soul_steal",
 "wrath_warning_scythe_slash",
 "wrath_activate_scythe_slash",
 "wrath_warning_rules_judgement",
 "wrath_activate_rules_judgement",
 "wrath_warning_eternal_sacrifices",
 "wrath_activate_eternal_sacrifices",
 "wrath_warning_enhanced_undead",
 "wrath_activate_enhanced_undead",
 "wrath_warning_soul_reaper",
 "wrath_activate_soul_reaper",
 "wrath_warning_phantom_scream",
 "wrath_activate_phantom_scream",
 "wrath_warning_final_judgement",
 "wrath_activate_final_judgement",
 "wrath_warning_crimson_execution",
 "wrath_activate_crimson_execution",
 "hunter_laugh",
 "reaper_laugh"
]
const COMBAT_WARNINGS = [
 "hunter_crusher_warning",
 "hunter_stalker_warning",
 "hunter_ravager_warning",
 "hunter_charged_warning",
 "wrath_warning_summon",
 "wrath_warning_assault",
 "wrath_warning_soul_steal",
 "wrath_warning_scythe_slash",
 "wrath_warning_rules_judgement",
 "wrath_warning_eternal_sacrifices",
 "wrath_warning_enhanced_undead",
 "wrath_warning_soul_reaper",
 "wrath_warning_phantom_scream",
 "wrath_warning_final_judgement",
 "wrath_warning_crimson_execution"
]
const RULES = {
 "shot_needle": {
  "gain_db": -10.0,
  "cooldown": 0.1,
  "critical": false
 },
 "shot_needle_precision": {
  "gain_db": -10.0,
  "cooldown": 0.1,
  "critical": false
 },
 "shot_needle_suppression": {
  "gain_db": -10.0,
  "cooldown": 0.1,
  "critical": false
 },
 "shot_needle_high": {
  "gain_db": -10.0,
  "cooldown": 0.1,
  "critical": false
 },
 "shot_arc": {
  "gain_db": -10.0,
  "cooldown": 0.14,
  "critical": false
 },
 "shot_arc_focus": {
  "gain_db": -10.0,
  "cooldown": 0.14,
  "critical": false
 },
 "shot_arc_storm": {
  "gain_db": -10.0,
  "cooldown": 0.14,
  "critical": false
 },
 "shot_arc_high": {
  "gain_db": -10.0,
  "cooldown": 0.14,
  "critical": false
 },
 "shot_flame": {
  "gain_db": -10.0,
  "cooldown": 0.19,
  "critical": false
 },
 "shot_flame_high": {
  "gain_db": -10.0,
  "cooldown": 0.19,
  "critical": false
 },
 "shot_frost": {
  "gain_db": -10.0,
  "cooldown": 0.19,
  "critical": false
 },
 "shot_frost_high": {
  "gain_db": -10.0,
  "cooldown": 0.19,
  "critical": false
 },
 "shot_shock": {
  "gain_db": -10.0,
  "cooldown": 0.19,
  "critical": false
 },
 "shot_shock_high": {
  "gain_db": -10.0,
  "cooldown": 0.19,
  "critical": false
 },
 "impact": {
  "gain_db": -13.0,
  "cooldown": 0.09,
  "critical": false
 },
 "impact_flame": {
  "gain_db": -13.0,
  "cooldown": 0.09,
  "critical": false
 },
 "impact_frost": {
  "gain_db": -13.0,
  "cooldown": 0.09,
  "critical": false
 },
 "impact_shock": {
  "gain_db": -13.0,
  "cooldown": 0.09,
  "critical": false
 },
 "door_hit": {
  "gain_db": -11.0,
  "cooldown": 0.12,
  "critical": false
 },
 "door_crack": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": false
 },
 "door_break": {
  "gain_db": -11.0,
  "cooldown": 0.5,
  "critical": false
 },
 "build": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": false
 },
 "upgrade": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": false
 },
 "branch_select": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": true
 },
 "repair": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": false
 },
 "sale": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": false
 },
 "refund": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": false
 },
 "ui_hover": {
  "gain_db": -24.0,
  "cooldown": 0.09,
  "critical": false
 },
 "ui_confirm": {
  "gain_db": -19.0,
  "cooldown": 0.09,
  "critical": false
 },
 "ui_fail": {
  "gain_db": -19.0,
  "cooldown": 0.09,
  "critical": false
 },
 "shield_activate": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": true
 },
 "shield_absorb": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": false
 },
 "auto_repair_activate": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": true
 },
 "decoy_activate": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": true
 },
 "hunter_crusher_warning": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": true
 },
 "hunter_crusher_pressure": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": false
 },
 "hunter_stalker_warning": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": true
 },
 "hunter_stalker_conceal": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": false
 },
 "hunter_stalker_feint": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": false
 },
 "hunter_ravager_warning": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": true
 },
 "hunter_ravager_dash": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": false
 },
 "hunter_evolve": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": true
 },
 "buff_offense": {
  "gain_db": -15.0,
  "cooldown": 0.6,
  "critical": true
 },
 "buff_armor": {
  "gain_db": -15.0,
  "cooldown": 0.6,
  "critical": true
 },
 "buff_speed": {
  "gain_db": -15.0,
  "cooldown": 0.6,
  "critical": true
 },
 "buff_resource": {
  "gain_db": -15.0,
  "cooldown": 0.6,
  "critical": true
 },
 "buff_command": {
  "gain_db": -15.0,
  "cooldown": 0.6,
  "critical": true
 },
 "undead_spawn": {
  "gain_db": -16.0,
  "cooldown": 0.4,
  "critical": false
 },
 "undead_attack": {
  "gain_db": -16.0,
  "cooldown": 0.24,
  "critical": false
 },
 "undead_hurt": {
  "gain_db": -16.0,
  "cooldown": 0.24,
  "critical": false
 },
 "undead_death": {
  "gain_db": -16.0,
  "cooldown": 0.24,
  "critical": false
 },
 "reaper_phase_2": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": true
 },
 "scythe_throw": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": false
 },
 "scythe_embed": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": false
 },
 "scythe_tick": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": false
 },
 "scythe_end": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": false
 },
 "shot_flame_searing": {
  "gain_db": -10.0,
  "cooldown": 0.19,
  "critical": false
 },
 "shot_flame_wildfire": {
  "gain_db": -10.0,
  "cooldown": 0.19,
  "critical": false
 },
 "shot_frost_deep_chill": {
  "gain_db": -10.0,
  "cooldown": 0.19,
  "critical": false
 },
 "shot_frost_rime_field": {
  "gain_db": -10.0,
  "cooldown": 0.19,
  "critical": false
 },
 "shot_shock_capacitor_burst": {
  "gain_db": -10.0,
  "cooldown": 0.19,
  "critical": false
 },
 "shot_shock_rapid_discharge": {
  "gain_db": -10.0,
  "cooldown": 0.19,
  "critical": false
 },
 "shot_needle_precision_high": {
  "gain_db": -10.0,
  "cooldown": 0.1,
  "critical": false
 },
 "shot_needle_suppression_high": {
  "gain_db": -10.0,
  "cooldown": 0.1,
  "critical": false
 },
 "shot_arc_focus_high": {
  "gain_db": -10.0,
  "cooldown": 0.14,
  "critical": false
 },
 "shot_arc_storm_high": {
  "gain_db": -10.0,
  "cooldown": 0.14,
  "critical": false
 },
 "shot_flame_searing_high": {
  "gain_db": -10.0,
  "cooldown": 0.19,
  "critical": false
 },
 "shot_flame_wildfire_high": {
  "gain_db": -10.0,
  "cooldown": 0.19,
  "critical": false
 },
 "shot_frost_deep_chill_high": {
  "gain_db": -10.0,
  "cooldown": 0.19,
  "critical": false
 },
 "shot_frost_rime_field_high": {
  "gain_db": -10.0,
  "cooldown": 0.19,
  "critical": false
 },
 "shot_shock_capacitor_burst_high": {
  "gain_db": -10.0,
  "cooldown": 0.19,
  "critical": false
 },
 "shot_shock_rapid_discharge_high": {
  "gain_db": -10.0,
  "cooldown": 0.19,
  "critical": false
 },
 "turret_upgrade": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": false
 },
 "bed_upgrade": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": false
 },
 "door_upgrade": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": false
 },
 "prestige_upgrade": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": false
 },
 "button": {
  "gain_db": -19.0,
  "cooldown": 0.09,
  "critical": false
 },
 "menu": {
  "gain_db": -24.0,
  "cooldown": 0.09,
  "critical": false
 },
 "purchase": {
  "gain_db": -19.0,
  "cooldown": 0.09,
  "critical": false
 },
 "failure": {
  "gain_db": -19.0,
  "cooldown": 0.09,
  "critical": false
 },
 "shop_purchase": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": false
 },
 "footstep": {
  "gain_db": -18.0,
  "cooldown": 0.36,
  "critical": false
 },
 "danger": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": false
 },
 "generator_activate": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": true
 },
 "resource_gold": {
  "gain_db": -21.0,
  "cooldown": 0.8,
  "critical": false
 },
 "resource_power": {
  "gain_db": -21.0,
  "cooldown": 0.8,
  "critical": false
 },
 "reaper_impact": {
  "gain_db": -11.0,
  "cooldown": 0.5,
  "critical": false
 },
 "hunter_charged_warning": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": true
 },
 "undead_spawn_enhanced": {
  "gain_db": -16.0,
  "cooldown": 0.4,
  "critical": false
 },
 "lock_release": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": false
 },
 "build_flame": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": true
 },
 "build_frost": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": true
 },
 "build_shock": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": true
 },
 "build_auto_repair": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": true
 },
 "build_shield": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": true
 },
 "build_decoy": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": true
 },
 "income": {
  "gain_db": -21.0,
  "cooldown": 0.8,
  "critical": false
 },
 "electricity": {
  "gain_db": -21.0,
  "cooldown": 0.8,
  "critical": false
 },
 "reward": {
  "gain_db": -12.0,
  "cooldown": 0.12,
  "critical": false
 },
 "wrath_warning_summon": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": true
 },
 "wrath_activate_summon": {
  "gain_db": -11.0,
  "cooldown": 0.5,
  "critical": true
 },
 "wrath_warning_assault": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": true
 },
 "wrath_activate_assault": {
  "gain_db": -11.0,
  "cooldown": 0.5,
  "critical": true
 },
 "wrath_warning_soul_steal": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": true
 },
 "wrath_activate_soul_steal": {
  "gain_db": -11.0,
  "cooldown": 0.5,
  "critical": true
 },
 "wrath_warning_scythe_slash": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": true
 },
 "wrath_activate_scythe_slash": {
  "gain_db": -11.0,
  "cooldown": 0.5,
  "critical": true
 },
 "wrath_warning_rules_judgement": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": true
 },
 "wrath_activate_rules_judgement": {
  "gain_db": -11.0,
  "cooldown": 0.5,
  "critical": true
 },
 "wrath_warning_eternal_sacrifices": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": true
 },
 "wrath_activate_eternal_sacrifices": {
  "gain_db": -11.0,
  "cooldown": 0.5,
  "critical": true
 },
 "wrath_warning_enhanced_undead": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": true
 },
 "wrath_activate_enhanced_undead": {
  "gain_db": -11.0,
  "cooldown": 0.5,
  "critical": true
 },
 "wrath_warning_soul_reaper": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": true
 },
 "wrath_activate_soul_reaper": {
  "gain_db": -11.0,
  "cooldown": 0.5,
  "critical": true
 },
 "wrath_warning_phantom_scream": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": true
 },
 "wrath_activate_phantom_scream": {
  "gain_db": -11.0,
  "cooldown": 0.5,
  "critical": true
 },
 "wrath_warning_final_judgement": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": true
 },
 "wrath_activate_final_judgement": {
  "gain_db": -11.0,
  "cooldown": 0.5,
  "critical": true
 },
 "wrath_warning_crimson_execution": {
  "gain_db": -11.0,
  "cooldown": 0.45,
  "critical": true
 },
 "wrath_activate_crimson_execution": {
  "gain_db": -11.0,
  "cooldown": 0.5,
  "critical": true
 }
}
const PREVIEW_GROUPS = {
 "Weapons": [
  "shot_needle",
  "shot_arc",
  "shot_flame",
  "shot_frost",
  "shot_shock",
  "impact"
 ],
 "Construction": [
  "build",
  "upgrade",
  "branch_select",
  "repair",
  "shield_activate",
  "decoy_activate"
 ],
 "Hunter": [
  "hunter_crusher_warning",
  "hunter_stalker_conceal",
  "hunter_ravager_dash",
  "hunter_evolve",
  "buff_armor",
  "undead_spawn"
 ],
 "Reaper": [
  "wrath_warning_summon",
  "wrath_warning_scythe_slash",
  "wrath_warning_soul_reaper",
  "wrath_warning_phantom_scream",
  "wrath_warning_final_judgement",
  "wrath_activate_crimson_execution"
 ]
}
const BUFF_CATEGORY = {
 "blood_frenzy": "offense",
 "iron_skin": "armor",
 "predator_rush": "speed",
 "door_crusher": "offense",
 "soul_hunger": "armor",
 "rapid_recovery": "offense",
 "shadow_step": "speed",
 "ruthless_pursuit": "speed",
 "cursed_armor": "armor",
 "savage_strike": "offense",
 "dread_aura": "resource",
 "undead_commander": "command",
 "soul_drain": "resource",
 "relentless_siege": "offense",
 "deaths_momentum": "speed"
}

static func gain_db(name: String) -> float:
 if name.begins_with("weather_"):return -29.0
 if name in ["death_scream_1","death_scream_2","hunter_laugh","reaper_laugh","scream_1","scream_2","scream_3","intro_breath","intro_shriek","intro_whisper"]:return -11.0
 if name in ["ghost_hurt","reaper_hurt"]:return -15.0
 return float(RULES.get(name,{}).get("gain_db",-20.0))
static func cooldown(name: String,legacy) -> float:
 if name in ["ghost_hurt","reaper_hurt"]:return .4
 return float(RULES.get(name,{}).get("cooldown",legacy))
static func family(name: String) -> String:
 for kind in ["needle","arc","flame","frost","shock"]:
  if name.begins_with("shot_"+kind):return kind
 return ""
static func shot_event(kind: String,level: int,specialization: String) -> String:
 var base={"turret":"shot_needle","heavy":"shot_arc","flame":"shot_flame","frost":"shot_frost","shock":"shot_shock"}.get(kind,"")
 if base=="":return ""
 var branch=base+"_"+specialization
 var cue=branch if RULES.has(branch) else base
 if level>=8 and RULES.has(cue+"_high"):cue+="_high"
 return cue
static func impact_event(kind: String) -> String:
 return "impact_"+kind if kind in ["flame","frost","shock"] else "impact"
