extends Control

signal open_inventory()
signal open_skills()
signal open_crafting()
signal open_quests()

var health_bar = null
var stamina_bar = null
var hunger_bar = null
var mana_bar = null
var level_label = null
var day_label = null
var skill_xp_label = null
var skill_xp_timer = 0.0
var skill_names = {craftsman="工匠", mage="魔导", warrior="勇者", merchant="商贾", hermit="隐士"}
var skill_colors = {craftsman=Color("#ffb347"), mage=Color("#b388ff"), warrior=Color("#ff5252"), merchant=Color("#ffd740"), hermit=Color("#69f0ae")}

func _ready():
	anchor_right = 1.0
	anchor_bottom = 1.0
	build_ui()
	# 强制检查背包按钮信号
	await get_tree().process_frame
	var p = $Panel
	if p:
		var ib = p.get_node_or_null("InventoryBtn")
		if ib and not ib.pressed.is_connected(_on_inv_btn):
			ib.pressed.connect(_on_inv_btn)
		var sb = p.get_node_or_null("SkillBtn")
		if sb and not sb.pressed.is_connected(_on_skill_btn):
			sb.pressed.connect(_on_skill_btn)
		var cb = p.get_node_or_null("CraftingBtn")
		if cb and not cb.pressed.is_connected(_on_crafting_btn):
			cb.pressed.connect(_on_crafting_btn)
		var qb = p.get_node_or_null("QuestBtn")
		if qb and not qb.pressed.is_connected(_on_quests_btn):
			qb.pressed.connect(_on_quests_btn)

func _on_inv_btn():
	open_inventory.emit()

func _on_skill_btn():
	open_skills.emit()

func _on_crafting_btn():
	open_crafting.emit()

func _on_quests_btn():
	open_quests.emit()

func make_style(border: bool = false) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.06, 0.16, 0.85)
	if border:
		s.border_color = Color(0, 0.83, 1.0, 0.25)
		s.border_width_left = 1; s.border_width_right = 1
		s.border_width_top = 1; s.border_width_bottom = 1
	s.corner_radius_top_left = 8; s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8; s.corner_radius_bottom_right = 8
	return s

func build_ui():
	var panel = Panel.new()
	panel.name = "Panel"
	panel.position = Vector2(0, 0)
	panel.size = Vector2(280, 200)
	panel.add_theme_stylebox_override("panel", make_style(true))
	add_child(panel)
	
	var colors = {
		health = Color("#00ff9d"), stamina = Color("#00d4ff"),
		hunger = Color("#ffb347"), mana = Color("#b388ff")
	}
	
	var y = 12
	for data in [
		{name="HP", key="health", bar="HealthBar"},
		{name="STA", key="stamina", bar="StaminaBar"},
		{name="HUN", key="hunger", bar="HungerBar"},
		{name="MAN", key="mana", bar="ManaBar"}
	]:
		var lb = Label.new()
		lb.position = Vector2(12, y)
		lb.size = Vector2(35, 16)
		lb.text = data.name
		lb.add_theme_color_override("font_color", Color("#7a8aba"))
		lb.add_theme_font_size_override("font_size", 12)
		panel.add_child(lb)
		
		var bar = ProgressBar.new()
		bar.name = data.bar
		bar.position = Vector2(48, y - 1)
		bar.size = Vector2(130, 16)
		bar.max_value = 100.0
		bar.value = 100.0
		bar.show_percentage = false
		var bg = StyleBoxFlat.new()
		bg.bg_color = Color(0, 0, 0, 0.3)
		bg.corner_radius_top_left = 3; bg.corner_radius_top_right = 3
		bg.corner_radius_bottom_left = 3; bg.corner_radius_bottom_right = 3
		var fill = StyleBoxFlat.new()
		fill.bg_color = colors[data.key]
		fill.corner_radius_top_left = 3; fill.corner_radius_top_right = 3
		fill.corner_radius_bottom_left = 3; fill.corner_radius_bottom_right = 3
		bar.add_theme_stylebox_override("background", bg)
		bar.add_theme_stylebox_override("fill", fill)
		panel.add_child(bar)
		
		match data.key:
			"health": health_bar = bar
			"stamina": stamina_bar = bar
			"hunger": hunger_bar = bar
			"mana": mana_bar = bar
		
		y += 25
	
	var right_x = 190
	level_label = Label.new()
	level_label.position = Vector2(right_x, 12)
	level_label.size = Vector2(80, 22)
	level_label.text = "Lv.1"
	level_label.add_theme_color_override("font_color", Color("#00d4ff"))
	level_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(level_label)
	
	day_label = Label.new()
	day_label.position = Vector2(right_x, 34)
	day_label.size = Vector2(80, 16)
	day_label.text = "06:00"
	day_label.add_theme_color_override("font_color", Color("#7a8aba"))
	day_label.add_theme_font_size_override("font_size", 12)
	panel.add_child(day_label)
	
	# 背包按钮
	var ib = Button.new()
	ib.name = "InventoryBtn"
	ib.position = Vector2(right_x, 105)
	ib.size = Vector2(70, 28)
	ib.text = "背包"
	style_btn(ib)
	ib.pressed.connect(_on_inv_btn)
	panel.add_child(ib)
	
	# 技能按钮
	var sb = Button.new()
	sb.name = "SkillBtn"
	sb.position = Vector2(right_x, 140)
	sb.size = Vector2(70, 28)
	sb.text = "技能"
	style_btn(sb)
	sb.pressed.connect(_on_skill_btn)
	panel.add_child(sb)

	# 合成按钮
	var cb = Button.new()
	cb.name = "CraftingBtn"
	cb.position = Vector2(right_x, 175)
	cb.size = Vector2(70, 28)
	cb.text = "合成"
	style_btn(cb)
	cb.pressed.connect(_on_crafting_btn)
	panel.add_child(cb)

	# 任务按钮
	var qb = Button.new()
	qb.name = "QuestBtn"
	qb.position = Vector2(right_x, 210)
	qb.size = Vector2(70, 28)
	qb.text = "任务"
	style_btn(qb)
	qb.pressed.connect(_on_quests_btn)
	panel.add_child(qb)

	# 面板高度自适应
	panel.size = Vector2(280, 250)
	
	# 技能经验浮动提示标签（位于面板下方）
	skill_xp_label = Label.new()
	skill_xp_label.name = "SkillXpLabel"
	skill_xp_label.position = Vector2(10, 228)
	skill_xp_label.size = Vector2(260, 18)
	skill_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_xp_label.add_theme_color_override("font_color", Color("#ffd740"))
	skill_xp_label.add_theme_font_size_override("font_size", 12)
	skill_xp_label.visible = false
	panel.add_child(skill_xp_label)

func style_btn(btn: Button):
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0, 0.83, 1.0, 0.1)
	bs.border_color = Color(0, 0.83, 1.0, 0.4)
	bs.border_width_left = 1; bs.border_width_right = 1
	bs.border_width_top = 1; bs.border_width_bottom = 1
	bs.corner_radius_top_left = 4; bs.corner_radius_top_right = 4
	bs.corner_radius_bottom_left = 4; bs.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", bs)
	btn.add_theme_color_override("font_color", Color("#d0dcff"))
	btn.add_theme_font_size_override("font_size", 13)

func update_player_stats(stats):
	if health_bar: health_bar.value = stats.get("health", 100)
	if stamina_bar: stamina_bar.value = stats.get("stamina", 100)
	if hunger_bar: hunger_bar.value = stats.get("hunger", 100)
	if mana_bar: mana_bar.value = stats.get("mana", 50)

func update_level(lv):
	if level_label: level_label.text = "Lv.%d" % lv

func update_day_time(hours):
	if day_label: day_label.text = "%02d:00" % int(hours)

func show_skill_xp_notification(skill_name, amount):
	if not skill_xp_label:
		return
	var display_name = skill_names.get(skill_name, skill_name)
	var color = skill_colors.get(skill_name, Color.WHITE)
	skill_xp_label.add_theme_color_override("font_color", color)
	skill_xp_label.text = "%s +%d XP" % [display_name, amount]
	skill_xp_label.visible = true
	skill_xp_label.modulate.a = 1.0
	skill_xp_timer = 2.0

func _process(delta):
	if skill_xp_label and skill_xp_label.visible:
		skill_xp_timer -= delta
		if skill_xp_timer <= 0:
			skill_xp_label.visible = false
		elif skill_xp_timer < 1.0:
			skill_xp_label.modulate.a = skill_xp_timer
