extends RefCounted
## Render-only cache. Corridor surfaces, collision and route nodes stay map-owned.
## Small padded chunks composite opaque floor, trim, and local fixtures once.

const CHUNK_SIZE := 256
const PAD := 2
const KEEP_COUNT := 32
const TRIM := 3

var _data: Dictionary
var _details := -1
var _parts := {}
var _textures := {}
var _last_use := {}
var _clock := 0
var _floor_tile: Image
var _lamp_horizontal: Image
var _lamp_vertical: Image
var _base_color: Color
var _trim_color: Color


func render(canvas: CanvasItem, data: Dictionary, source: Texture2D, colors: Array, offset: Vector2, visible: Rect2, details: int) -> void:
 if not is_same(_data,data) or details != _details:
  _prepare(data,source,colors,offset,details)
 _clock += 1
 var first := _key_at(visible.position)
 var last := _key_at(visible.end)
 for y in range(first.y,last.y+1):
  for x in range(first.x,last.x+1):
   var key := Vector2i(x,y)
   if not _parts.has(key):
    continue
   if not _textures.has(key):
    _textures[key] = _assemble(key)
   _last_use[key] = _clock
   var texture: ImageTexture = _textures[key]
   canvas.draw_texture_rect_region(texture, Rect2(Vector2(key * CHUNK_SIZE),Vector2.ONE * CHUNK_SIZE),
    Rect2(Vector2.ONE * PAD,Vector2.ONE * CHUNK_SIZE))
 _evict()


func texture_bytes() -> int:
 return _textures.size() * (CHUNK_SIZE + 2*PAD) * (CHUNK_SIZE + 2*PAD) * 4


func _key_at(at: Vector2) -> Vector2i:
 return Vector2i(floori(at.x / CHUNK_SIZE), floori(at.y / CHUNK_SIZE))


func _patch_bounds(key: Vector2i) -> Rect2i:
 return Rect2i(key * CHUNK_SIZE - Vector2i.ONE * PAD, Vector2i.ONE * (CHUNK_SIZE + 2*PAD))


func _prepare(data: Dictionary, source: Texture2D, colors: Array, offset: Vector2, details: int) -> void:
 _data = data
 _details = details
 _parts.clear()
 _textures.clear()
 _last_use.clear()
 _base_color = colors[0]
 _trim_color = colors[2].darkened(.18)
 var source_image := source.get_image()
 if source_image != null and not source_image.is_empty():
  _floor_tile = _make_floor_tile(source_image,colors[1].lightened(.3))
 else:
  _floor_tile = null
 _lamp_horizontal = _make_lamp(colors[4],details>0,true)
 _lamp_vertical = _make_lamp(colors[4],details>0,false)
 for corridor: Rect2 in data.corridors:
  var world := Rect2(corridor.position + offset,corridor.size)
  var rect := Rect2i(Vector2i(world.position.floor()),Vector2i(world.end.ceil() - world.position.floor()))
  _index_rect(rect.grow(TRIM),0)
  _index_rect(rect,1)
 for i in range(data.lane_links.size()):
  var edge: Array = data.lane_links[i]
  var a: Vector2 = offset + data.nodes[edge[0]]
  var b: Vector2 = offset + data.nodes[edge[1]]
  var direction := a.direction_to(b)
  var length := a.distance_to(b)
  if length < 85.0:
   continue
  var lateral: Vector2 = direction.orthogonal() * (float(data.lane_widths[i])*.5 - 9.0)
  for distance in range(52,int(length)-25,136 if details>0 else 216):
   var midpoint := Vector2i((a + direction*distance + lateral).round())
   var size := _lamp_horizontal.get_size()
   var bounds := Rect2i(midpoint - size / 2,size)
   _index_rect(bounds,2 if absf(direction.x)>absf(direction.y) else 3)


func _index_rect(rect: Rect2i, layer: int) -> void:
 var first := _key_at(Vector2(rect.position - Vector2i.ONE * PAD))
 var last := _key_at(Vector2(rect.end + Vector2i.ONE * PAD))
 for y in range(first.y,last.y+1):
  for x in range(first.x,last.x+1):
   var key := Vector2i(x,y)
   if not _patch_bounds(key).intersects(rect):
    continue
   if not _parts.has(key):
    _parts[key] = [[],[],[],[]]
   _parts[key][layer].append(rect)


func _make_floor_tile(source: Image, tint: Color) -> Image:
 var size := source.get_size()
 var tile := Image.create_empty(size.x,size.y,false,Image.FORMAT_RGBA8)
 for y in range(size.y):
  for x in range(size.x):
   var pixel := source.get_pixel(x,y)
   var colored := Color(pixel.r*tint.r,pixel.g*tint.g,pixel.b*tint.b,1.0)
   tile.set_pixel(x,y,_base_color.lerp(colored,pixel.a*.48))
 return tile


func _make_lamp(tint: Color, glow: bool, horizontal: bool) -> Image:
 var diameter := 32 if glow else 10
 var image := Image.create_empty(diameter,diameter,false,Image.FORMAT_RGBA8)
 var center := Vector2(diameter,diameter)*.5
 for y in range(diameter):
  for x in range(diameter):
   var from_center := Vector2(x+.5,y+.5)-center
   var mark := from_center if horizontal else Vector2(from_center.y,from_center.x)
   if absf(mark.x)<4.0 and absf(mark.y)<1.0:
    image.set_pixel(x,y,Color(tint,.65))
   elif glow and from_center.length_squared()<225.0:
    image.set_pixel(x,y,Color(tint,.07))
 return image


func _tile_floor(target: Image, world: Rect2i, at: Vector2i) -> void:
 if _floor_tile == null:
  target.fill_rect(Rect2i(world.position-at,world.size),_base_color)
  return
 var tile_size := _floor_tile.get_size()
 var y := world.position.y
 while y < world.end.y:
  var row := posmod(y,tile_size.y)
  var height := mini(tile_size.y-row,world.end.y-y)
  var x := world.position.x
  while x < world.end.x:
   var col := posmod(x,tile_size.x)
   var width := mini(tile_size.x-col,world.end.x-x)
   target.blit_rect(_floor_tile,Rect2i(col,row,width,height),Vector2i(x,y)-at)
   x += width
  y += height


func _assemble(key: Vector2i) -> ImageTexture:
 var world := _patch_bounds(key)
 var image := Image.create_empty(world.size.x,world.size.y,false,Image.FORMAT_RGBA8)
 var parts: Array = _parts[key]
 for rect: Rect2i in parts[0]:
  var clip := world.intersection(rect)
  image.fill_rect(Rect2i(clip.position-world.position,clip.size),_trim_color)
 for rect: Rect2i in parts[1]:
  _tile_floor(image,world.intersection(rect),world.position)
 for layer in [2,3]:
  var lamp := _lamp_horizontal if layer==2 else _lamp_vertical
  for rect: Rect2i in parts[layer]:
   var clip := world.intersection(rect)
   image.blend_rect(lamp,Rect2i(clip.position-rect.position,clip.size),clip.position-world.position)
 return ImageTexture.create_from_image(image)


func _evict() -> void:
 if _textures.size() <= KEEP_COUNT:
  return
 var oldest: Array = _last_use.keys()
 oldest.sort_custom(func(a,b):return _last_use[a]<_last_use[b])
 for key in oldest:
  if _textures.size()<=KEEP_COUNT or _last_use[key]==_clock:
   return
  _last_use.erase(key)
  _textures.erase(key)
