extends Node2D

const TILE_SIZE = 64
const MAP_WIDTH = 50
const MAP_HEIGHT = 40

var tile_map_node = null
var collision_layer = null
var resources_node = null
var monsters_node = null
var labels_node = null
var bg_node = null

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
