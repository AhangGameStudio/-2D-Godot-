extends Control

signal fishing_result(success, fish_name, fish_xp)

var fishing_spot = null
var player = null
var bar_width = 300
var bar_height = 30
var target_center = 0.0
var target_width = 40
var pointer_pos = 0.0
var pointer_speed = 200.0
var pointer_dir = 1.0
var game_active = false
var time_limit = 5.0
var timer = 0.0

# UI 节点
var panel = null
var bar_bg = null
var target_rect = null
var pointer_rect = null
var info_label = null

func _ready():
	# 构建UI（同项目现有风格）
	anchor_right = 1.0
	anchor_bottom = 1.0
	build_ui()

func build_ui():
	# 半透明背景
	var bg = Panel.new()
	bg.name = "FishingBG"
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.5)
	bg.add_theme_stylebox_override("panel", bg_style)
	add_child(bg)
	
	# 主面板
	panel = Panel.new()
	panel.name = "FishingPanel"
	panel.size = Vector2(400, 200)
	panel.position = Vector2(0, 0)  # 居中
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.06, 0.16, 0.95)
	ps.border_color = Color(0, 0.83, 1.0, 0.3)
	ps.border_width_left = 1; ps.border_width_right = 1
	ps.border_width_top = 1; ps.border_width_bottom = 3
	ps.corner_radius_top_left = 10; ps.corner_radius_top_right = 10
	ps.corner_radius_bottom_left = 10; ps.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)
	
	# 标题
	var title = Label.new()
	title.text = "钓 鱼"
	title.position = Vector2(150, 10)
	title.size = Vector2(100, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#00d4ff"))
	title.add_theme_font_size_override("font_size", 22)
	panel.add_child(title)
	
	# 进度条背景
	bar_bg = Panel.new()
	bar_bg.position = Vector2(50, 60)
	bar_bg.size = Vector2(bar_width, bar_height)
	var bar_bg_style = StyleBoxFlat.new()
	bar_bg_style.bg_color = Color(0, 0, 0, 0.4)
	bar_bg_style.border_color = Color(0.3, 0.3, 0.5, 0.6)
	bar_bg_style.border_width_left = 1
	bar_bg_style.border_width_right = 1
	bar_bg_style.border_width_top = 1
	bar_bg_style.border_width_bottom = 1
	bar_bg.add_theme_stylebox_override("panel", bar_bg_style)
	panel.add_child(bar_bg)
	
	# 目标区域
	target_rect = ColorRect.new()
	target_rect.color = Color(0, 1, 0.5, 0.3)
	target_rect.size = Vector2(target_width, bar_height)
	bar_bg.add_child(target_rect)
	
	# 指针
	pointer_rect = ColorRect.new()
	pointer_rect.color = Color(1, 0.3, 0.3, 0.9)
	pointer_rect.size = Vector2(4, bar_height)
	bar_bg.add_child(pointer_rect)
	
	# 提示文字
	info_label = Label.new()
	info_label.position = Vector2(50, 100)
	info_label.size = Vector2(300, 30)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_color_override("font_color", Color("#ffd740"))
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.text = "按 空格键 停住指针！"
	panel.add_child(info_label)
	
	# 居中
	await get_tree().process_frame
	var ws = get_window().size
	panel.position = Vector2((ws.x - panel.size.x) / 2, (ws.y - panel.size.y) / 2)

func start(spot, p):
	fishing_spot = spot
	player = p
	visible = true
	game_active = true
	timer = time_limit
	pointer_pos = 0.0
	target_center = randf_range(target_width, bar_width - target_width)
	target_rect.position = Vector2(target_center - target_width/2, 0)
	pointer_rect.position = Vector2(0, 0)
	info_label.text = "按 空格键 停住指针！"

func _process(delta):
	if not game_active: return
	timer -= delta
	if timer <= 0:
		end_game(false, "超时了...")
		return
	
	# 指针来回移动
	pointer_pos += pointer_speed * pointer_dir * delta
	if pointer_pos >= bar_width:
		pointer_pos = bar_width
		pointer_dir = -1
	elif pointer_pos <= 0:
		pointer_pos = 0
		pointer_dir = 1
	pointer_rect.position = Vector2(pointer_pos, 0)
	
	# 按空格
	if Input.is_key_pressed(KEY_SPACE) or Input.is_action_just_pressed("ui_accept"):
		var hit = abs(pointer_pos - target_center) < target_width/2
		end_game(hit, "上钩了！" if hit else "没中...")

func end_game(success, message):
	game_active = false
	if success and fishing_spot:
		var fish = fishing_spot.catch_fish()
		info_label.text = "%s！钓到 %s！" % [message, fish.name]
		# 延迟关闭
		await get_tree().create_timer(1.5).timeout
		visible = false
		fishing_result.emit(true, fish.name, fish.xp)
	else:
		info_label.text = message
		await get_tree().create_timer(1.0).timeout
		visible = false
		fishing_result.emit(false, "", 0)
	
	if fishing_spot:
		fishing_spot.reset()
	fishing_spot = null
