extends Node2D

const TILE_SIZE = 64
const MAP_WIDTH = 50
const MAP_HEIGHT = 40
const DIRT_CHANCE = 0.12
const DECORATION_CHANCE = 0.08
const STUMP_CHANCE = 0.012
const GRASS_PATCH_SIZE = 8
const GRASS_TRANSITION_CHANCE = 0.22

const GRASS_TEXTURES = [
	preload("res://assets/textures/terrain/grass_dirt/grass_1.png"),
	preload("res://assets/textures/terrain/grass_dirt/grass_2.png"),
	preload("res://assets/textures/terrain/grass_dirt/grass_3.png"),
	preload("res://assets/textures/terrain/grass_dirt/grass_4.png"),
	preload("res://assets/textures/terrain/grass_dirt/grass_5.png"),
	preload("res://assets/textures/terrain/grass_dirt/grass_6.png")
]
const DIRT_TEXTURES = [
	preload("res://assets/textures/terrain/grass_dirt/dirt_1.png"),
	preload("res://assets/textures/terrain/grass_dirt/dirt_2.png"),
	preload("res://assets/textures/terrain/grass_dirt/dirt_3.png"),
	preload("res://assets/textures/terrain/grass_dirt/dirt_4.png"),
	preload("res://assets/textures/terrain/grass_dirt/dirt_5.png"),
	preload("res://assets/textures/terrain/grass_dirt/dirt_6.png")
]
const CLIFF_TEXTURES = [
	preload("res://assets/textures/terrain/grass_dirt/cliff_1.png"),
	preload("res://assets/textures/terrain/grass_dirt/cliff_2.png"),
	preload("res://assets/textures/terrain/grass_dirt/cliff_3.png"),
	preload("res://assets/textures/terrain/grass_dirt/cliff_4.png"),
	preload("res://assets/textures/terrain/grass_dirt/cliff_5.png"),
	preload("res://assets/textures/terrain/grass_dirt/cliff_6.png")
]
const DECORATION_TEXTURES = [
	preload("res://assets/textures/terrain/grass_dirt/daisy_bud.png"),
	preload("res://assets/textures/terrain/grass_dirt/daisy_open.png"),
	preload("res://assets/textures/terrain/grass_dirt/daisy_late.png"),
	preload("res://assets/textures/terrain/grass_dirt/stone_small.png"),
	preload("res://assets/textures/terrain/grass_dirt/stone_pebbles.png"),
	preload("res://assets/textures/terrain/grass_dirt/stone_large.png"),
	preload("res://assets/textures/terrain/grass_dirt/red_flower_1.png"),
	preload("res://assets/textures/terrain/grass_dirt/red_flower_2.png"),
	preload("res://assets/textures/terrain/grass_dirt/red_flower_3.png")
]
const STUMP_TEXTURE = preload("res://assets/textures/terrain/grass_dirt/wood_stump.png")

var tile_map_node = null
var collision_layer = null
var resources_node = null
var monsters_node = null
var labels_node = null
var bg_node = null
var decorations_node = null

var tile_colors = {
	0: Color(0.25, 0.55, 0.2),
	1: Color(0.35, 0.28, 0.22),
	2: Color(0.55, 0.5, 0.35),
	3: Color(0.55, 0.15, 0.08),
	4: Color(0.65, 0.7, 0.75),
	5: Color(0.4, 0.6, 0.35)
}

var region_tile_types = {
	forest = 0, floating = 2, desert = 3, glacier = 4, abyss = 1, plains = 5
}

var regions = {
	forest  = {cx = 12, cy = 12, r = 6, name = "灵语森林", tex = "res://assets/textures/terrain/Grass001/Grass001.png"},
	floating = {cx = 35, cy = 10, r = 5, name = "浮空秘境", tex = "res://assets/textures/terrain/Rock051/Rock051.png"},
	desert  = {cx = 38, cy = 28, r = 6, name = "熔岩荒漠", tex = "res://assets/textures/terrain/Lava001/Lava001.png"},
	glacier = {cx = 10, cy = 30, r = 6, name = "永冻冰川", tex = "res://assets/textures/terrain/Snow011/Snow011.png"},
	abyss   = {cx = 25, cy = 22, r = 6, name = "深渊裂隙", tex = "res://assets/textures/terrain/Rock044/Rock044.png"},
	plains  = {cx = 22, cy = 12, r = 5, name = "中州平原", tex = "res://assets/textures/terrain/Grass001/Grass001.png"}
}

var monster_types = ["野狼", "哥布林", "暗影", "冰霜"]

func _ready():
	tile_map_node = $TileMap
	collision_layer = $CollisionLayer
	resources_node = $Resources
	monsters_node = $Monsters
	labels_node = $Labels
	bg_node = $Background
	decorations_node = Node2D.new()
	decorations_node.name = "Decorations"
	add_child(decorations_node)
	move_child(decorations_node, tile_map_node.get_index() + 1)
	
	create_region_backgrounds()
	generate_map()
	spawn_resources()
	spawn_monsters()
	create_region_labels()

func get_tile_type(x, y):
	for rn in regions:
		var r = regions[rn]
		if abs(x - r.cx) <= r.r and abs(y - r.cy) <= r.r:
			return region_tile_types.get(rn, 0)
	return 0

func create_region_backgrounds():
	for rn in regions:
		var r = regions[rn]
		if not ResourceLoader.exists(r.tex): continue
		var tex = load(r.tex)
		if not tex: continue
		
		var rect = TextureRect.new()
		rect.texture = tex
		var w = (r.r * 2 + 1) * TILE_SIZE
		var h = (r.r * 2 + 1) * TILE_SIZE
		rect.size = Vector2(w, h)
		rect.position = Vector2((r.cx - r.r) * TILE_SIZE, (r.cy - r.r) * TILE_SIZE)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		rect.modulate = Color(1, 1, 1, 0.3)
		bg_node.add_child(rect)

func generate_map():
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var tt = get_tile_type(x, y)
			var is_grass_area = tt == 0 or tt == 5
			var is_cliff_edge = is_grass_area and _is_map_edge(x, y)
			var is_dirt = is_grass_area and not is_cliff_edge and randf() < DIRT_CHANCE
			
			if is_grass_area:
				var tex = null
				if is_cliff_edge:
					tex = CLIFF_TEXTURES[randi() % CLIFF_TEXTURES.size()]
					_create_tile_sprite(tile_map_node, tex, Vector2(x * TILE_SIZE, y * TILE_SIZE), _get_edge_rotation(x, y))
					continue
				elif is_dirt:
					tex = DIRT_TEXTURES[randi() % DIRT_TEXTURES.size()]
				else:
					tex = _get_grass_texture_for_tile(x, y)
				_create_tile_sprite(tile_map_node, tex, Vector2(x * TILE_SIZE, y * TILE_SIZE), 0.0)
				if not is_cliff_edge and not is_dirt:
					_try_spawn_decoration(x, y)
			else:
				var tile = ColorRect.new()
				tile.color = tile_colors.get(tt, Color(0.4, 0.4, 0.4))
				tile.size = Vector2(TILE_SIZE - 1, TILE_SIZE - 1)
				tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
				tile_map_node.add_child(tile)
			
			if tt == 1 or tt == 4:
				var collision = StaticBody2D.new()
				var shape = RectangleShape2D.new()
				shape.extents = Vector2(TILE_SIZE/2, TILE_SIZE/2)
				var collider = CollisionShape2D.new()
				collider.shape = shape
				collision.add_child(collider)
				collision.position = Vector2(x * TILE_SIZE + TILE_SIZE/2, y * TILE_SIZE + TILE_SIZE/2)
				collision_layer.add_child(collision)

func _create_tile_sprite(parent_node, texture, pos, rotation_degrees_value = 0.0):
	var tile = TextureRect.new()
	tile.texture = texture
	tile.position = pos
	tile.size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.pivot_offset = Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	tile.rotation_degrees = rotation_degrees_value
	tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tile.stretch_mode = TextureRect.STRETCH_SCALE
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent_node.add_child(tile)

func _is_map_edge(x, y):
	return x == 0 or y == 0 or x == MAP_WIDTH - 1 or y == MAP_HEIGHT - 1

func _get_edge_rotation(x, y):
	if y == 0:
		return 180.0
	if x == MAP_WIDTH - 1:
		return -90.0
	if x == 0:
		return 90.0
	return 0.0

func _get_grass_texture_for_tile(x, y):
	var patch_x = int(x / GRASS_PATCH_SIZE)
	var patch_y = int(y / GRASS_PATCH_SIZE)
	var main_index = abs((patch_x * 37 + patch_y * 19) % GRASS_TEXTURES.size())
	var local_x = x % GRASS_PATCH_SIZE
	var local_y = y % GRASS_PATCH_SIZE
	var near_patch_edge = local_x == 0 or local_y == 0 or local_x == GRASS_PATCH_SIZE - 1 or local_y == GRASS_PATCH_SIZE - 1
	if near_patch_edge and randf() < GRASS_TRANSITION_CHANCE:
		main_index = (main_index + 1 + randi() % (GRASS_TEXTURES.size() - 1)) % GRASS_TEXTURES.size()
	return GRASS_TEXTURES[main_index]

func _try_spawn_decoration(x, y):
	if randf() < STUMP_CHANCE:
		_spawn_stump(x, y)
		return
	if randf() > DECORATION_CHANCE:
		return
	var decor = TextureRect.new()
	decor.texture = DECORATION_TEXTURES[randi() % DECORATION_TEXTURES.size()]
	decor.size = Vector2(TILE_SIZE, TILE_SIZE)
	decor.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	decor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	decor.stretch_mode = TextureRect.STRETCH_SCALE
	decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decorations_node.add_child(decor)

func _spawn_stump(x, y):
	var decor = TextureRect.new()
	decor.texture = STUMP_TEXTURE
	decor.size = Vector2(TILE_SIZE, TILE_SIZE)
	decor.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	decor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	decor.stretch_mode = TextureRect.STRETCH_SCALE
	decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decorations_node.add_child(decor)
	
	var body = StaticBody2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 18
	var collider = CollisionShape2D.new()
	collider.shape = shape
	body.add_child(collider)
	body.position = Vector2(x * TILE_SIZE + TILE_SIZE / 2, y * TILE_SIZE + TILE_SIZE / 2 + 8)
	collision_layer.add_child(body)

func spawn_resources():
	var counts = {wood = 0, stone = 0, crystal = 0, ice = 0}
	var max_r = 60
	var tries = 0
	
	while tries < 5000 and not (counts.wood >= max_r and counts.stone >= max_r and counts.crystal >= max_r and counts.ice >= max_r):
		tries += 1
		var x = randi() % MAP_WIDTH
		var y = randi() % MAP_HEIGHT
		var tt = get_tile_type(x, y)
		
		if tt == 0 and counts.wood < max_r:
			spawn_resource_node(x, y, "wood", Color(0.6, 0.4, 0.2))
			counts.wood += 1
		elif tt == 2 and counts.stone < max_r:
			spawn_resource_node(x, y, "stone", Color(0.5, 0.5, 0.5))
			counts.stone += 1
		elif tt == 3 and counts.crystal < max_r:
			spawn_resource_node(x, y, "crystal", Color(0.6, 0.3, 1.0))
			counts.crystal += 1
		elif tt == 4 and counts.ice < max_r:
			spawn_resource_node(x, y, "ice", Color(0.8, 0.9, 1.0))
			counts.ice += 1

func spawn_resource_node(x, y, type_name, color):
	var rn = ResourceNode.new()
	rn.resource_type = type_name
	rn.resource_color = color
	rn.position = Vector2(x * TILE_SIZE + TILE_SIZE/2, y * TILE_SIZE + TILE_SIZE/2)
	resources_node.add_child(rn)

func spawn_monsters():
	for rn in regions:
		var r = regions[rn]
		var count = 3 + randi() % 4
		for i in range(count):
			var mx = clampi(r.cx + randi() % (r.r * 2 + 1) - r.r, 0, MAP_WIDTH - 1)
			var my = clampi(r.cy + randi() % (r.r * 2 + 1) - r.r, 0, MAP_HEIGHT - 1)
			var mon = MonsterNode.new()
			mon.monster_name = monster_types[randi() % monster_types.size()]
			mon.monster_level = 1 + randi() % 5
			mon.position = Vector2(mx * TILE_SIZE + TILE_SIZE/2, my * TILE_SIZE + TILE_SIZE/2)
			monsters_node.add_child(mon)

func create_region_labels():
	for rn in regions:
		var r = regions[rn]
		var lb = Label.new()
		lb.text = r.name
		lb.position = Vector2(r.cx * TILE_SIZE - 50, r.cy * TILE_SIZE - 40)
		lb.size = Vector2(120, 24)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.add_theme_color_override("font_color", Color(1, 1, 1))
		labels_node.add_child(lb)

# ===== 资源节点 =====
class ResourceNode extends Area2D:
	var resource_type = ""
	var resource_color = Color.WHITE
	var rect = null
	
	func _init():
		add_to_group("resources")
		rect = ColorRect.new()
		rect.size = Vector2(24, 24)
		rect.position = Vector2(-12, -12)
		add_child(rect)
		var shape = CircleShape2D.new()
		shape.radius = 14
		var collider = CollisionShape2D.new()
		collider.shape = shape
		add_child(collider)
	
	func _ready():
		rect.color = resource_color
	
	func collect(player):
		var item = {"name": resource_type, "icon": resource_type, "quantity": 1}
		if player.add_item(item):
			queue_free()

# ===== 怪物节点 =====
class MonsterNode extends Area2D:
	var monster_name = "野狼"
	var monster_level = 1
	var health = 50
	var max_health = 50
	var rect = null
	var hp_bar = null
	
	func _init():
		add_to_group("monsters")
		rect = ColorRect.new()
		rect.size = Vector2(28, 28)
		rect.position = Vector2(-14, -14)
		add_child(rect)
		var shape = CircleShape2D.new()
		shape.radius = 14
		var collider = CollisionShape2D.new()
		collider.shape = shape
		add_child(collider)
		hp_bar = ColorRect.new()
		hp_bar.size = Vector2(30, 4)
		hp_bar.position = Vector2(-15, -20)
		hp_bar.color = Color(0, 1, 0)
		add_child(hp_bar)
	
	func _ready():
		health = 30 + monster_level * 10
		max_health = health
		rect.color = Color(0.5 + randf() * 0.5, 0.15, 0.15)
	
	func take_damage(amount):
		health -= amount
		var orig = rect.color
		rect.color = Color(1, 1, 1)
		get_tree().create_timer(0.08).timeout.connect(func(): rect.color = orig)
		if hp_bar:
			hp_bar.size.x = (float(health) / max_health) * 30
		if health <= 0: die()
	
	func die():
		for body in get_overlapping_bodies():
			if body.has_method("add_experience"):
				body.add_experience(monster_level * 15)
		queue_free()
