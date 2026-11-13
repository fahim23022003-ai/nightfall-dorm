extends Node2D
# Explicit runtime contact sheet, not a multi-Hunter combat mode.
var game
var profile
var model
var full_map=false
var models=[]
var baseline=false
var old_presentation
var identity=preload("res://scripts/visual_presence.gd").new()
var font=preload("res://assets/fonts/Interface.ttf")
func _ready():
 identity.heading=Vector2.RIGHT;identity.velocity=Vector2.ZERO
 for kind in StrategyCatalog.ARCHETYPE_IDS:
  var m=MatchModel.new();m.hunter.configure_archetype(kind);m.hunter.state=HunterState.State.ATTACK;m.hunter.cooldown=.8;m.evolution.final_revealed=true;models.append(m)
func _draw():
 draw_rect(Rect2(0,0,1280,720),Color("101822"))
 draw_string(font,Vector2(20,28),"NIGHTMARE REBIRTH · SIX HUNTER FORM CONTACT SHEET" if not baseline else "BASELINE 6479803 · MATCHING HUNTER ART INSPECTION",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("E6CCA2"))
 draw_string(font,Vector2(20,52),"Actual Godot renderer · inspection poses, not simultaneous combat · Evolution 1 / 5 / 8 / 10" if not baseline else "Baseline had no independent evolution forms; same camera/pose grid for comparison. Gameplay comparisons are indexed separately.",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("A8BBC9"))
 for row in range(3):
  for column in range(8):
   var index=row*2+int(column/4);var level=[1,5,8,10][column%4]
   model=models[index];model.evolution.evolution_level=level;var h=model.hunter
   h.position=Vector2(80+column*160,207+row*210)-Vector2(145,40)
   draw_string(font,Vector2(7+column*160,92+row*210),StrategyCatalog.ARCHETYPES[h.archetype].name.replace("The ","")+" E%d" % level,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("DCD0BB"))
   if baseline:old_presentation.hunter(self,h)
   else:game.presentation.nightmare_visual.hunter(self,h,.5,0,identity)
