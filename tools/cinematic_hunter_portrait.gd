extends Node2D
# Enlarged production-rig inspection only, never a simulated extra enemy.
var game
var profile
var model
var full_map=false
var identity=preload("res://scripts/visual_presence.gd").new()
func _draw():
 identity.heading=Vector2.RIGHT;identity.velocity=Vector2.ZERO
 game.presentation.nightmare_visual.hunter(self,model.hunter,.5,0,identity)
