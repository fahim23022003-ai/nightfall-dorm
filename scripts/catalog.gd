class_name Catalog
extends RefCounted

const PREPARATION = 30.0
const BED_INCOME = [2.0, 4.0, 8.0, 15.0, 26.0]
const BED_COST = [25, 70, 160, 350]
const BED_POWER = [0, 0, 12, 30]
const DOOR_HP = [150.0, 300.0, 600.0, 1100.0, 1800.0]
const DOOR_COST = [30, 85, 190, 400]
const DOOR_POWER = [0, 0, 10, 30]
const BUILDINGS = {
 "turret": {"name":"Needle turret", "gold":20, "power":0, "damage":9.0, "range":240.0, "interval":0.9, "color":Color("63cdd2")},
 "heavy": {"name":"Arc turret", "gold":95, "power":12, "damage":28.0, "range":300.0, "interval":1.3, "color":Color("a78bfa")},
 "generator": {"name":"Dynamo", "gold":30, "power":0, "rate":1.5, "color":Color("e9ce67")},
 "repair": {"name":"Repair station", "gold":40, "power":5, "rate":7.0, "color":Color("7cdea0")},
 "economy": {"name":"Dream amplifier", "gold":45, "power":4, "rate":0.35, "color":Color("efab71")},
 "enhancer": {"name":"Target relay", "gold":65, "power":8, "rate":0.35, "color":Color("ee8fb2")}
}
const BOT_PROFILES = ["guard", "engineer", "economist", "gunner", "balanced"]

const HUNTER = {"hp":5000.0,"retarget_seconds":24.0,"door_weight":1.8,"growth_seconds":45.0,"hp_growth":100.0,"damage":22.0,"damage_growth":10.0,"interval":1.1,"interval_growth":0.04,"min_interval":0.45,"speed":80.0}
const REPAIR_COST = 12
const REPAIR_HEAL = 70.0
const BUILDING_MAX_LEVEL = 4
const AI_PROFILES = {
 "guard":{"priorities":["turret","generator","repair","economy","heavy","enhancer"],"bed_goal":2,"door_goal":3,"interval":1.1},
 "engineer":{"priorities":["generator","turret","repair","economy","enhancer","heavy"],"bed_goal":2,"door_goal":1,"interval":1.0},
 "economist":{"priorities":["economy","generator","turret","repair","heavy","enhancer"],"bed_goal":3,"door_goal":1,"interval":1.2},
 "gunner":{"priorities":["turret","generator","heavy","enhancer","economy","repair"],"bed_goal":1,"door_goal":1,"interval":0.9},
 "balanced":{"priorities":["turret","generator","economy","repair","heavy","enhancer"],"bed_goal":2,"door_goal":2,"interval":1.1}
}
