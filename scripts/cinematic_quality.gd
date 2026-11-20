class_name CinematicQuality
extends RefCounted
# Presentation-only preferences. All modes retain timing/target telegraphs.
static var hunter_backlight: GradientTexture2D

static func rebirth_preview() -> bool:
 return OS.get_environment("NIGHTFALL_VISUAL_REBIRTH") == "1"

static func draw_hunter_backlight(canvas: CanvasItem, floor: Vector2, hue: Color, alpha: float, wide: bool) -> void:
 if hunter_backlight == null:
  hunter_backlight = _make_hunter_backlight()
 var size := Vector2(154.0 if wide else 112.0, 151.0)
 var color := Color("#8a9bae").lerp(hue, .23)
 color.a = .36 * alpha
 canvas.draw_texture_rect(hunter_backlight, Rect2(floor - Vector2(size.x * .5, 123), size), false, color)

static func _make_hunter_backlight() -> GradientTexture2D:
 var ramp := Gradient.new()
 ramp.offsets = PackedFloat32Array([0.0, .25, .63, 1.0])
 ramp.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, .88), Color(1, 1, 1, .32), Color(1, 1, 1, 0)])
 var texture := GradientTexture2D.new()
 texture.width = 64
 texture.height = 64
 texture.gradient = ramp
 texture.fill = GradientTexture2D.FILL_RADIAL
 texture.fill_from = Vector2(.5, .5)
 texture.fill_to = Vector2(1, .5)
 return texture

static func reduced_motion(c) -> bool:return c.profile.settings.get("reduced_effects",false) or c.profile.settings.get("reduced_motion",false)
static func reduced_flash(c) -> bool:return c.profile.settings.get("reduced_effects",false) or c.profile.settings.get("reduced_flashes",false)
static func detail(c) -> int:
 if c.profile.settings.get("reduced_effects",false):return 0
 return {"low":0,"medium":1,"high":2}.get(c.profile.settings.get("graphics_quality","medium"),1)
