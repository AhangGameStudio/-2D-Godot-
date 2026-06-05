extends Node2D

const TILE_SIZE = 64
const MAP_W = 50
const MAP_H = 40

var tile_node = null
var col_node = null
var res_node = null
var mon_node = null
var npc_node = null
var lbl_node = null

var regions = {
	forest  = {cx=12, cy=12, r=6, name="灵语森林"},
	floating= {cx=35, cy=10, r=5, name="浮空秘境"},
	desert  = {cx=38, cy=28, r=6, name="熔岩荒漠"},
	glacier = {cx=10, cy=30, r=6, name="永冻冰川"},
	abyss   = {cx=25, cy=22, r=6, name="深渊裂隙"},
	plains  = {cx=22, cy=12, r=5, name="中州平原"}
}

var monster_names = ["野狼", "哥布林", "暗影", "冰霜"]

func _ready():
	tile_node = $TileMap
	col_node = $CollisionLayer
	res_node = $Resources
	mon_node = $Monsters
	npc_node = $NPCS
	lbl_node = $Labels
	
	# 加载 scribble-dungeons 贴图（64×64，直接平铺）
	var tex_grass = load("res://assets/sprites/tilesets/scribble-dungeons/grass.png")
	var tex_path  = load("res://assets/sprites/tilesets/scribble-dungeons/path.png")
	var tex_tiles = load("res://assets/sprites/tilesets/scribble-dungeons/tiles.png")
	var tex_water = load("res://assets/sprites/tilesets/scribble-dungeons/water.png")
	var tex_wood  = load("res://assets/sprites/tilesets/scribble-dungeons/wood.png")
	
	gen_tiles(tex_grass, tex_path, tex_tiles, tex_water, tex_wood)
	gen_collision()
	spawn_res()
	spawn_mons()
	spawn_fishing_spots()
	spawn_npcs()
	make_labels()

# ===== 1. 瓦片地图（scribble-dungeons 真实贴图） =====
func gen_tiles(tex_grass, tex_path, tex_tiles, tex_water, tex_wood):
	for x in range(MAP_W):
		for y in range(MAP_H):
			var tt = get_tile(x, y)
			var tex = _pick_tex(tt, tex_grass, tex_path, tex_tiles, tex_water, tex_wood)
			if not tex:
				# 回退色块
				var cr = ColorRect.new()
				cr.color = _fallback_color(tt)
				cr.size = Vector2(TILE_SIZE, TILE_SIZE)
				cr.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
				tile_node.add_child(cr)
				continue
			
			var sp = Sprite2D.new()
			sp.texture = tex
			sp.centered = false
			sp.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			tile_node.add_child(sp)

func _pick_tex(tt, grass, path, tiles, water, wood):
	match tt:
		0: return grass   # 森林
		1: return wood    # 深渊（木板）
		2: return tiles   # 浮空（地砖）
		3: return path    # 荒漠（沙石路）
		4: return water   # 冰川（水面/雪）
		5: return grass   # 平原
		_: return grass

func _fallback_color(tt):
	match tt:
		0: return Color(0.25, 0.55, 0.2)
		1: return Color(0.35, 0.28, 0.22)
		2: return Color(0.55, 0.5, 0.35)
		3: return Color(0.55, 0.15, 0.08)
		4: return Color(0.65, 0.7, 0.75)
		5: return Color(0.4, 0.6, 0.35)
		_: return Color(0.4, 0.4, 0.4)

func get_tile(x, y):
	for rn in regions:
		var r = regions[rn]
		if abs(x - r.cx) <= r.r and abs(y - r.cy) <= r.r:
			var keys = {forest=0, floating=2, desert=3, glacier=4, abyss=1, plains=5}
			return keys.get(rn, 0)
	return 0

# ===== 2. 碰撞层 =====
func gen_collision():
	for x in range(MAP_W):
		for y in range(MAP_H):
			var tt = get_tile(x, y)
			if tt == 1 or tt == 4:
				var col = StaticBody2D.new()
				var sh = RectangleShape2D.new()
				sh.extents = Vector2(TILE_SIZE/2, TILE_SIZE/2)
				var c = CollisionShape2D.new()
				c.shape = sh
				col.add_child(c)
				col.position = Vector2(x * TILE_SIZE + TILE_SIZE/2, y * TILE_SIZE + TILE_SIZE/2)
				col_node.add_child(col)

# ===== 3. 资源节点 =====
func spawn_res():
	# 用 scribble-dungeons 的 tree.png 和 plants.png 当资源
	var tex_tree  = load("res://assets/sprites/tilesets/scribble-dungeons/tree.png")
	var tex_plant = load("res://assets/sprites/tilesets/scribble-dungeons/plants.png")
	var res_defs = [
		{tile=0, key="wood", tex=tex_tree, max=60},
		{tile=2, key="stone", tex=tex_plant, max=60},
		{tile=3, key="crystal", tex=tex_plant, max=60},
		{tile=4, key="ice", tex=tex_tree, max=60},
	]
	var counts = {wood=0, stone=0, crystal=0, ice=0}
	for _tries in range(5000):
		var x = randi() % MAP_W
		var y = randi() % MAP_H
		var tt = get_tile(x, y)
		for rd in res_defs:
			var c = counts[rd.key]
			if tt == rd.tile and c < rd.max:
				var rn = Area2D.new()
				rn.add_to_group("resources")
				rn.set_meta("res_name", rd.key)
				if rd.tex:
					var sp = Sprite2D.new()
					sp.texture = rd.tex
					sp.centered = true
					sp.scale = Vector2(0.5, 0.5)
					rn.add_child(sp)
				# 树（wood）添加血量 + 裂纹覆盖层
				if rd.key == "wood":
					rn.set_meta("hp", 50)
					rn.set_meta("max_hp", 50)
					var crack = ColorRect.new()
					crack.color = Color(0.2, 0.1, 0.05, 0.0)
					crack.size = Vector2(50, 50)
					crack.position = Vector2(-25, -25)
					crack.name = "CrackOverlay"
					rn.add_child(crack)
				var sh = CircleShape2D.new()
				sh.radius = 14; var cs = CollisionShape2D.new(); cs.shape = sh
				rn.add_child(cs)
				rn.position = Vector2(x * TILE_SIZE + TILE_SIZE/2, y * TILE_SIZE + TILE_SIZE/2)
				res_node.add_child(rn)
				counts[rd.key] += 1
		if counts.values().all(func(v): return v >= 60): break

# ===== 4. 怪物 =====
func spawn_mons():
	var mon_scene = preload("res://scenes/monster.tscn")
	if not mon_scene:
		return
	
	# 按区域类型分配怪物类型概率
	var type_probs = {
		"forest":   [["野狼", 0.7], ["哥布林", 0.3]],
		"floating": [["暗影", 0.6], ["野狼", 0.4]],
		"desert":   [["哥布林", 0.6], ["暗影", 0.4]],
		"glacier":  [["冰霜", 0.8], ["野狼", 0.2]],
		"abyss":    [["暗影", 0.5], ["冰霜", 0.5]],
		"plains":   [["野狼", 0.5], ["哥布林", 0.5]]
	}
	
	for rn in regions:
		var r = regions[rn]
		var probs = type_probs[rn]
		for _i in range(3 + randi() % 4):
			var mx = clampi(r.cx + randi() % (r.r*2+1) - r.r, 0, MAP_W-1)
			var my = clampi(r.cy + randi() % (r.r*2+1) - r.r, 0, MAP_H-1)
			
			var m = mon_scene.instantiate()
			m.add_to_group("monsters")
			
			# 按概率选择怪物类型
			var roll = randf()
			var cumulative = 0.0
			var chosen = probs[0][0]
			for pair in probs:
				cumulative += pair[1]
				if roll <= cumulative:
					chosen = pair[0]
					break
			m.set_meta("monster_type", chosen)
			m.set_meta("monster_name", chosen)
			m.set_meta("monster_level", 1 + randi() % 5)
			m.set_meta("hp", 30 + randi() % 20)
			
			m.position = Vector2(mx * TILE_SIZE + TILE_SIZE/2, my * TILE_SIZE + TILE_SIZE/2)
			mon_node.add_child(m)

# ===== 5. 钓鱼点 =====
func spawn_fishing_spots():
	var spot_script = preload("res://scripts/FishingSpot.gd")
	if not spot_script:
		return
	var spots_per_region = 3
	# 在冰川(4) / 水域区域旁边生成钓鱼点
	for rn in regions:
		var r = regions[rn]
		for _i in range(spots_per_region):
			var mx = clampi(r.cx + randi() % (r.r*2+1) - r.r, 0, MAP_W-1)
			var my = clampi(r.cy + randi() % (r.r*2+1) - r.r, 0, MAP_H-1)
			# 确保生成在水域（tile=4）旁边或水域本身上方
			var found_water = false
			for ox in range(-2, 3):
				for oy in range(-2, 3):
					var nx = clampi(mx + ox, 0, MAP_W-1)
					var ny = clampi(my + oy, 0, MAP_H-1)
					if get_tile(nx, ny) == 4:
						found_water = true
						break
				if found_water: break
			if not found_water:
				continue
			var spot = Area2D.new()
			spot.set_script(spot_script)
			spot.position = Vector2(mx * TILE_SIZE + TILE_SIZE/2, my * TILE_SIZE + TILE_SIZE/2)
			spot.name = "FishingSpot_%d_%d" % [mx, my]
			res_node.add_child(spot)

# ===== 6. 商人NPC =====
func spawn_npcs():
	# 在平原区域生成一个商人NPC
	var r = regions.plains
	var mx = clampi(r.cx + randi() % (r.r*2+1) - r.r, 0, MAP_W-1)
	var my = clampi(r.cy + randi() % (r.r*2+1) - r.r, 0, MAP_H-1)
	
	var npc = Area2D.new()
	npc.add_to_group("shop_npcs")
	npc.name = "MerchantNPC"
	
	# ColorRect 显示商人
	var cr = ColorRect.new()
	cr.size = Vector2(28, 32)
	cr.position = Vector2(-14, -16)
	cr.color = Color(0.0, 0.83, 1.0, 0.9)
	cr.add_theme_stylebox_override("panel", _make_npc_style())
	npc.add_child(cr)
	
	# 商人名称标签
	var label = Label.new()
	label.text = "商人"
	label.position = Vector2(-20, 20)
	label.size = Vector2(40, 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#ffd740"))
	label.add_theme_font_size_override("font_size", 10)
	npc.add_child(label)
	
	# 碰撞区域
	var sh = CircleShape2D.new()
	sh.radius = 20
	var cs = CollisionShape2D.new()
	cs.shape = sh
	npc.add_child(cs)
	
	npc.position = Vector2(mx * TILE_SIZE + TILE_SIZE/2, my * TILE_SIZE + TILE_SIZE/2)
	npc_node.add_child(npc)

func _make_npc_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.0, 0.83, 1.0, 0.3)
	s.border_color = Color(0.0, 0.83, 1.0, 0.6)
	s.border_width_left = 1; s.border_width_right = 1
	s.border_width_top = 1; s.border_width_bottom = 1
	s.corner_radius_top_left = 4; s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4; s.corner_radius_bottom_right = 4
	return s

# ===== 7. 区域标签 =====
func make_labels():
	for rn in regions:
		var r = regions[rn]
		var colors = {forest="#66ff66", floating="#b388ff", desert="#ff6b35",
			glacier="#88ddff", abyss="#cc44ff", plains="#88ff88"}
		var clr = Color(colors.get(rn, "#ffffff"))
		var lb = Label.new()
		lb.text = r.name
		lb.position = Vector2(r.cx * TILE_SIZE - 60, r.cy * TILE_SIZE - 45)
		lb.size = Vector2(120, 24)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.add_theme_color_override("font_color", clr)
		lb.add_theme_font_size_override("font_size", 14)
		var sh = Label.new()
		sh.text = r.name
		sh.position = Vector2(r.cx * TILE_SIZE - 59, r.cy * TILE_SIZE - 44)
		sh.size = Vector2(120, 24)
		sh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sh.add_theme_color_override("font_color", Color(0,0,0,0.6))
		sh.add_theme_font_size_override("font_size", 14)
		lbl_node.add_child(sh); lbl_node.add_child(lb)
