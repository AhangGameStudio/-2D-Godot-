extends Control

var skills_data = {
	craftsman = {name="工匠", desc="提升建造效率", color=Color("#ffb347")},
	mage = {name="魔导", desc="提升魔法威力", color=Color("#b388ff")},
	warrior = {name="勇者", desc="提升战斗能力", color=Color("#ff5252")},
	merchant = {name="商贾", desc="降低交易税", color=Color("#ffd740")},
	hermit = {name="隐士", desc="提升情绪恢复", color=Color("#69f0ae")}
}

const MAX_LEVEL = 50

func _ready():
	await get_tree().process_frame
	center_panel()
	get_tree().root.size_changed.connect(center_panel)
	
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.06, 0.16, 0.92)
	ps.border_color = Color(0, 0.83, 1.0, 0.3)
	ps.border_width_left = 1; ps.border_width_right = 1
	ps.border_width_top = 1; ps.border_width_bottom = 3
	ps.corner_radius_top_left = 10; ps.corner_radius_top_right = 10
	ps.corner_radius_bottom_left = 10; ps.corner_radius_bottom_right = 10
	$Panel.add_theme_stylebox_override("panel", ps)
	
	$Panel/TitleLabel.add_theme_color_override("font_color", Color("#b388ff"))
	$Panel/TitleLabel.add_theme_font_size_override("font_size", 18)
	
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(1, 0.2, 0.2, 0.15)
	bs.border_color = Color(1, 0.2, 0.2, 0.4)
	bs.border_width_left = 1; bs.border_width_right = 1
	bs.border_width_top = 1; bs.border_width_bottom = 1
	bs.corner_radius_top_left = 4; bs.corner_radius_top_right = 4
	bs.corner_radius_bottom_left = 4; bs.corner_radius_bottom_right = 4
	$Panel/CloseButton.add_theme_stylebox_override("normal", bs)
	$Panel/CloseButton.add_theme_color_override("font_color", Color("#ff5555"))
	$Panel/CloseButton.add_theme_font_size_override("font_size", 14)
	$Panel/CloseButton.pressed.connect(func(): visible = false)

func update_skills(vals):
	var list = $Panel/VBoxContainer
	for child in list.get_children():
		child.queue_free()
	for sk in skills_data:
		var d = skills_data[sk]
		var sv = vals.get(sk, {level=1, xp=0, max_xp=100}) if vals else {level=1, xp=0, max_xp=100}
		var item = SkillItem.new()
		item.setup(d, sv)
		list.add_child(item)

func center_panel():
	var ws = get_window().size
	var p = $Panel
	p.position = Vector2((ws.x - p.size.x) / 2, (ws.y - p.size.y) / 2)

class SkillItem extends Panel:
	var name_lb = null
	var desc_lb = null
	var level_lb = null
	var bar = null
	var xp_bar = null
	var xp_lb = null
	var _skill_name = ""
	var _tween = null
	
	func _init():
		custom_minimum_size = Vector2(360, 70)
		# 技能名称
		name_lb = Label.new()
		name_lb.position = Vector2(10, 4)
		name_lb.size = Vector2(140, 18)
		add_child(name_lb)
		# 等级
		level_lb = Label.new()
		level_lb.position = Vector2(155, 4)
		level_lb.size = Vector2(80, 18)
		add_child(level_lb)
		# 描述
		desc_lb = Label.new()
		desc_lb.position = Vector2(10, 22)
		desc_lb.size = Vector2(150, 14)
		add_child(desc_lb)
		# 主进度条（经验条）
		bar = ProgressBar.new()
		bar.position = Vector2(170, 22)
		bar.size = Vector2(180, 14)
		bar.max_value = 100.0
		bar.show_percentage = false
		add_child(bar)
		# 经验值的二级细条
		xp_bar = ProgressBar.new()
		xp_bar.position = Vector2(170, 38)
		xp_bar.size = Vector2(180, 8)
		xp_bar.max_value = 100.0
		xp_bar.show_percentage = false
		xp_bar.modulate = Color(1, 1, 1, 0.6)
		add_child(xp_bar)
		# 经验值文字
		xp_lb = Label.new()
		xp_lb.position = Vector2(170, 47)
		xp_lb.size = Vector2(180, 14)
		add_child(xp_lb)
	
	func setup(data, sv: Dictionary):
		var level = sv.get("level", 1)
		var xp = sv.get("xp", 0)
		var max_xp = sv.get("max_xp", 100)
		_skill_name = data.name
		
		name_lb.add_theme_color_override("font_color", data.color)
		name_lb.add_theme_font_size_override("font_size", 15)
		name_lb.text = data.name
		
		level_lb.add_theme_color_override("font_color", Color("#00d4ff"))
		level_lb.add_theme_font_size_override("font_size", 13)
		level_lb.text = "Lv.%d/%d" % [level, MAX_LEVEL]
		
		desc_lb.add_theme_color_override("font_color", Color("#7a8aba"))
		desc_lb.add_theme_font_size_override("font_size", 11)
		desc_lb.text = data.desc
		
		var pct = float(xp) / float(max_xp) * 100.0 if max_xp > 0 else 0.0
		bar.value = pct
		
		var bg = StyleBoxFlat.new()
		bg.bg_color = Color(0, 0, 0, 0.2)
		bg.corner_radius_top_left = 3; bg.corner_radius_top_right = 3
		bg.corner_radius_bottom_left = 3; bg.corner_radius_bottom_right = 3
		var fill = StyleBoxFlat.new()
		fill.bg_color = data.color
		fill.corner_radius_top_left = 3; fill.corner_radius_top_right = 3
		fill.corner_radius_bottom_left = 3; fill.corner_radius_bottom_right = 3
		bar.add_theme_stylebox_override("background", bg)
		bar.add_theme_stylebox_override("fill", fill)
		
		var xp_bg = StyleBoxFlat.new()
		xp_bg.bg_color = Color(0, 0, 0, 0.15)
		xp_bg.corner_radius_top_left = 2; xp_bg.corner_radius_top_right = 2
		xp_bg.corner_radius_bottom_left = 2; xp_bg.corner_radius_bottom_right = 2
		var xp_fill = StyleBoxFlat.new()
		xp_fill.bg_color = Color(1, 1, 1, 0.35)
		xp_fill.corner_radius_top_left = 2; xp_fill.corner_radius_top_right = 2
		xp_fill.corner_radius_bottom_left = 2; xp_fill.corner_radius_bottom_right = 2
		xp_bar.add_theme_stylebox_override("background", xp_bg)
		xp_bar.add_theme_stylebox_override("fill", xp_fill)
		xp_bar.value = pct
		
		xp_lb.add_theme_color_override("font_color", Color("#9aabc8"))
		xp_lb.add_theme_font_size_override("font_size", 10)
		xp_lb.text = "XP: %d/%d" % [xp, max_xp]
	
	func play_level_up_effect():
		if _tween and _tween.is_running():
			_tween.kill()
		_tween = create_tween()
		_tween.set_trans(Tween.TRANS_SINE)
		_tween.tween_property(self, "modulate", Color(10, 10, 10, 1), 0.15)
		_tween.tween_property(self, "modulate", Color.WHITE, 0.3)
		_tween.tween_property(self, "modulate", Color(10, 10, 10, 1), 0.1)
		_tween.tween_property(self, "modulate", Color.WHITE, 0.3)
