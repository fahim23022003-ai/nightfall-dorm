class_name CosmeticPresentation
extends RefCounted
static func equipped(c,slot: String) -> bool:
 var id=str(c.profile.replay.cosmetics.get(slot,""))
 return id!="" and CosmeticCatalog.earned(c.profile,id)
static func bed(c,point: Vector2):
 if not equipped(c,"bed"):return
 for side in [-1,1]:
  c.draw_line(point+Vector2(side*37,-40),point+Vector2(side*37,45),Color("A4A29A"),3)
  c.draw_circle(point+Vector2(side*37,-41),3,Color("C1B492"))
 c.draw_colored_polygon(PackedVector2Array([point+Vector2(-37,-40),point+Vector2(-25,-47),point+Vector2(25,-47),point+Vector2(37,-40),point+Vector2(30,-31),point+Vector2(0,-38),point+Vector2(-30,-31)]),Color("675269"))
static func turret(c,point: Vector2):
 if not equipped(c,"turret"):return
 for side in [-1,1]:
  c.draw_colored_polygon(PackedVector2Array([point+Vector2(side*22-4,-4),point+Vector2(side*22,-31),point+Vector2(side*22+4,-4)]),Color("A9A79A"))
 c.draw_arc(point+Vector2(0,-16),27,PI,TAU,20,Color("B39BBD"),2)
static func door(c):
 if not equipped(c,"door"):return
 for x in [-23,0,23]:c.draw_line(Vector2(x,-32),Vector2(x,16),Color("262E35"),4)
 c.draw_arc(Vector2(0,-17),30,PI,TAU,20,Color("B6B29E"),3)
 c.draw_rect(Rect2(-7,-12,14,15),Color("A68D5F"))
