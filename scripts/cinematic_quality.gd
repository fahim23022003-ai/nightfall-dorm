class_name CinematicQuality
extends RefCounted
# Presentation-only preferences. All modes retain timing/target telegraphs.
static func reduced_motion(c) -> bool:return c.profile.settings.get("reduced_effects",false) or c.profile.settings.get("reduced_motion",false)
static func reduced_flash(c) -> bool:return c.profile.settings.get("reduced_effects",false) or c.profile.settings.get("reduced_flashes",false)
static func detail(c) -> int:
 if c.profile.settings.get("reduced_effects",false):return 0
 return {"low":0,"medium":1,"high":2}.get(c.profile.settings.get("graphics_quality","medium"),1)
