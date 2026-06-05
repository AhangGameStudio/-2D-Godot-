extends Control

func _ready():
	# 科技感面板样式
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.04, 0.04, 0.14, 0.92)
	ps.border_color = Color(0, 0.83, 1.0, 0.6)
	ps.border_width_left = 2
	ps.border_width_top = 2
	ps.border_width_right = 1
	ps.border_width_bottom = 1
	ps.corner_radius_top_left = 8
	ps.corner_radius_top_right = 8
	ps.corner_radius_bottom_left = 8
	ps.corner_radius_bottom_right = 8
	ps.set_expand_margin_all(4)
	ps.shadow_color = Color(0, 0.83, 1.0, 0.15)
	ps.shadow_size = 12
	$Panel.add_theme_stylebox_override("panel", ps)
	
	# 按钮样式 + 信号连接
	for btn_name in ["NewGameBtn", "LoadGameBtn", "MultiplayerBtn", "SettingsBtn", "CreditsBtn", "QuitBtn"]:
		var btn = $Panel.get_node(btn_name) as Button
		if not btn: continue
		var bs = StyleBoxFlat.new()
		bs.bg_color = Color(0, 0.83, 1.0, 0.06)
		bs.border_color = Color(0, 0.83, 1.0, 0.25)
		bs.border_width_left = 1; bs.border_width_right = 1
		bs.border_width_top = 1; bs.border_width_bottom = 1
		bs.corner_radius_top_left = 4; bs.corner_radius_top_right = 4
		bs.corner_radius_bottom_left = 4; bs.corner_radius_bottom_right = 4
		var bh = bs.duplicate()
		bh.bg_color = Color(0, 0.83, 1.0, 0.15)
		bh.border_color = Color(0, 0.83, 1.0, 0.7)
		btn.add_theme_stylebox_override("normal", bs)
		btn.add_theme_stylebox_override("hover", bh)
		btn.add_theme_color_override("font_color", Color("#c8dcff"))
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.add_theme_font_size_override("font_size", 18)
	
	# 版本标签
	$VersionLabel.add_theme_color_override("font_color", Color("#7a8aba"))
	$VersionLabel.add_theme_font_size_override("font_size", 12)
	
	# 按钮信号
	$Panel/NewGameBtn.pressed.connect(_on_new_game)
	$Panel/LoadGameBtn.pressed.connect(_on_load_game)
	$Panel/QuitBtn.pressed.connect(_on_quit)
	var mp_btn = $Panel.get_node_or_null("MultiplayerBtn")
	if mp_btn:
		mp_btn.pressed.connect(_on_multiplayer)

func _on_new_game():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_load_game():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_multiplayer():
	var mp_ui = preload("res://scenes/ui/MultiplayerUI.tscn").instantiate()
	add_child(mp_ui)
	mp_ui.back_to_menu.connect(mp_ui.queue_free)

func _on_quit():
	get_tree().quit()
