class_name HunterIdentity
extends RefCounted

const NAMES := {
 "crusher": "The Bonebreaker",
 "stalker": "The Veiled Stalker",
 "ravager": "The Hollow Ravager",
 "witch": "The Mourning Witch",
 "electric": "The Static Revenant",
 "storm": "The Tempest Wraith",
}

static func display(archetype: String, transformed: bool = false) -> String:
 return "The Final Reaper" if transformed else NAMES.get(archetype, "The Hunter")
