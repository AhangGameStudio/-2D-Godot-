extends Control

var grid = null
var close_btn = null

func _ready():
	grid = $Panel/GridContainer
	close_btn = $Panel/CloseButton
	
	# 面板居中
	await get_tree().process_frame
	center_panel()
	get_tree().root.size_changed.connect(center_panel)
	
	# 科技感面板
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.06, 0.16, 0.92)
	ps.border_color = Color(0, 0.83, 1.0, 0.3)
	ps.border_width_left = 1; ps.border_width_right = 1
	ps.border_width_top = 1; ps.border_width_bottom = 3
	ps.corner_radius_top_left = 10; ps.corner_radius_top_right = 10
	ps.corner_radius_bottom_left = 10; ps.corner_radius_bottom_right = 10
	$Panel.add_theme_stylebox_override("panel", ps)
	
	# 标题
	var tl = $Panel/TitleLabel
	tl.add_theme_color_override("font_color", Color("#00d4ff"))
	tl.add_theme_font_size_override("font_size", 18)
	
	# 关闭按钮
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(1, 0.2, 0.2, 0.15)
	bs.border_color = Color(1, 0.2, 0.2, 0.4)
	bs.border_width_left = 1; bs.border_width_right = 1
	bs.border_width_top = 1; bs.border_width_bottom = 1
	bs.corner_radius_top_left = 4; bs.corner_radius_top_right = 4
	bs.corner_radius_bottom_left = 4; bs.corner_radius_bottom_right = 4
	close_btn.add_theme_stylebox_override("normal", bs)
	close_btn.add_theme_color_override("font_color", Color("#ff5555"))
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(_on_close)
	
	# 格子数
	var sc = $Panel/SlotCount
	sc.add_theme_color_override("font_color", Color("#7a8aba"))
	sc.add_theme_font_size_override("font_size", 12)

func update_inventory(inv):
	for child in grid.get_children():
		child.queue_free()
	if not inv or not inv.has("items"): return
	for item in inv.items:
		var slot = ItemSlot.new()
		slot.set_item(item)
		slot.setup_style()
		grid.add_child(slot)
	var max_s = inv.get("max_slots", 20)
	for i in range(max_s - len(inv.items)):
		var empty = ItemSlot.new()
		empty.setup_style(true)
		grid.add_child(empty)
	$Panel/SlotCount.text = "%d/%d" % [len(inv.items), max_s]

func center_panel():
	var ws = get_window().size
	var p = $Panel
	p.position = Vector2((ws.x - p.size.x) / 2, (ws.y - p.size.y) / 2)

func _on_close():
	visible = false

class ItemSlot extends Panel:
	var item = null
	var icon = null
	var qty = null
	
	# 物品名称 → 贴图路径映射
	static var item_textures = {
		"木头": "res://assets/sprites/characters/kenney-tiny-dungeon/Tiles/tile_0033.png",
		"石头": "res://assets/sprites/characters/kenney-tiny-dungeon/Tiles/tile_0056.png",
		"水晶": "res://assets/sprites/characters/kenney-tiny-dungeon/Tiles/tile_0081.png",
		"冰晶": "res://assets/sprites/characters/kenney-tiny-dungeon/Tiles/tile_0039.png",
		"铁锭": "res://assets/sprites/characters/kenney-tiny-dungeon/Tiles/tile_0031.png",
		"布匹": "res://assets/sprites/characters/kenney-tiny-dungeon/Tiles/tile_0043.png",
		"药水": "res://assets/sprites/characters/kenney-tiny-dungeon/Tiles/tile_0074.png",
		"金币": "res://assets/sprites/characters/kenney-tiny-dungeon/Tiles/tile_0080.png",
		"资源": "res://assets/sprites/characters/kenney-tiny-dungeon/Tiles/tile_0050.png",
	}
	static var default_texture = "res://assets/sprites/characters/kenney-tiny-dungeon/Tiles/tile_0000.png"
	
	# 后备彩色方块颜色（纹理加载失败时使用）
	static var item_colors = {
		"木头": Color(0.55, 0.35, 0.15),
		"石头": Color(0.5, 0.5, 0.5),
		"水晶": Color(0.5, 0.8, 1.0),
		"冰晶": Color(0.7, 0.9, 1.0),
		"铁锭": Color(0.6, 0.6, 0.7),
		"布匹": Color(0.8, 0.6, 0.4),
		"药水": Color(0.3, 0.8, 0.3),
		"金币": Color(1.0, 0.84, 0.0),
		"资源": Color(0.5, 0.7, 0.3),
	}
	static var default_color = Color(0.5, 0.5, 0.5)
	
	func _init():
		custom_minimum_size = Vector2(64, 64)
		icon = TextureRect.new()
		icon.size = Vector2(48, 48)
		icon.position = Vector2(8, 8)
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		icon.texture_filter = TEXTURE_FILTER_NEAREST  # 像素画用最近邻，保持清晰
		add_child(icon)
		qty = Label.new()
		qty.position = Vector2(48, 48)
		qty.size = Vector2(16, 16)
		qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		add_child(qty)
	
	func setup_style(empty: bool = false):
		var s = StyleBoxFlat.new()
		s.bg_color = Color(0.1, 0.1, 0.25, 0.5) if not empty else Color(0.06, 0.06, 0.16, 0.3)
		s.border_color = Color(0, 0.83, 1.0, 0.15)
		s.border_width_left = 1; s.border_width_right = 1
		s.border_width_top = 1; s.border_width_bottom = 1
		s.corner_radius_top_left = 4; s.corner_radius_top_right = 4
		s.corner_radius_bottom_left = 4; s.corner_radius_bottom_right = 4
		add_theme_stylebox_override("panel", s)
		qty.add_theme_color_override("font_color", Color("#d0dcff"))
		qty.add_theme_font_size_override("font_size", 11)
	
	func set_item(item_data):
		item = item_data
		# 清除旧的 fallback 方块
		var fb = get_node_or_null("FallbackIcon")
		if fb:
			fb.queue_free()
		
		if item:
			# 从字典中查找贴图路径
			var tex_path = item_textures.get(item.get("name", ""), default_texture)
			var tex = load(tex_path)
			if tex:
				icon.texture = tex
				icon.visible = true
			else:
				# 纹理加载失败 → 使用彩色方块作为后备显示
				icon.texture = null
				icon.visible = false
				var cr = ColorRect.new()
				cr.name = "FallbackIcon"
				cr.size = Vector2(48, 48)
				cr.position = Vector2(8, 8)
				cr.color = item_colors.get(item.get("name", ""), default_color)
				add_child(cr)
			
			# 显示数量
			if item.get("quantity", 1) > 1:
				qty.text = str(item.quantity)
			else:
				qty.text = ""
		else:
			icon.texture = null
			icon.visible = true
			qty.text = ""
