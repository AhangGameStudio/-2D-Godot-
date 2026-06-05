extends Control

signal crafting_closed()
signal item_crafted(recipe_name, quantity)

const ITEM_COLORS = {
	"木头": Color("#8B5A2B"),
	"石头": Color("#A0A0A0"),
	"水晶": Color("#9B59B6"),
	"铁锭": Color("#C0C0C0"),
	"布匹": Color("#F5DEB3"),
	"木板": Color("#CD853F"),
	"石砖": Color("#696969"),
	"工具": Color("#FF8C00"),
	"药水": Color("#2ECC71"),
	"护甲": Color("#3498DB"),
	"武器": Color("#E74C3C"),
}

var selected_recipe = null
var craft_quantity = 1
var current_inventory = null
var recipe_widgets = {}  # recipe_name -> {craft_btn, card}
var qty_buttons = []

func _ready():
	# 关闭按钮
	$Panel/CloseButton.pressed.connect(_on_close)

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

	# 关闭按钮样式
	var clos_bs = StyleBoxFlat.new()
	clos_bs.bg_color = Color(1, 0.2, 0.2, 0.15)
	clos_bs.border_color = Color(1, 0.2, 0.2, 0.4)
	clos_bs.border_width_left = 1; clos_bs.border_width_right = 1
	clos_bs.border_width_top = 1; clos_bs.border_width_bottom = 1
	clos_bs.corner_radius_top_left = 4; clos_bs.corner_radius_top_right = 4
	clos_bs.corner_radius_bottom_left = 4; clos_bs.corner_radius_bottom_right = 4
	$Panel/CloseButton.add_theme_stylebox_override("normal", clos_bs)
	$Panel/CloseButton.add_theme_color_override("font_color", Color("#ff5555"))
	$Panel/CloseButton.add_theme_font_size_override("font_size", 14)

	# 居中面板
	await get_tree().process_frame
	center_panel()
	get_tree().root.size_changed.connect(center_panel)

	# 详情面板样式
	var dps = StyleBoxFlat.new()
	dps.bg_color = Color(0.08, 0.08, 0.2, 0.5)
	dps.border_color = Color(0, 0.83, 1.0, 0.15)
	dps.border_width_left = 1; dps.border_width_right = 1
	dps.border_width_top = 1; dps.border_width_bottom = 1
	dps.corner_radius_top_left = 6; dps.corner_radius_top_right = 6
	dps.corner_radius_bottom_left = 6; dps.corner_radius_bottom_right = 6
	$Panel/DetailPanel.add_theme_stylebox_override("panel", dps)

	# 构建数量选择按钮和配方列表
	_build_qty_buttons()
	_build_recipe_list()

# ---------- 数量选择 ----------

func _build_qty_buttons():
	var qty_hbox = $Panel/QtyHBox
	# 清除旧按钮
	for child in qty_hbox.get_children():
		child.queue_free()
	qty_buttons.clear()
	var qty_values = [1, 5, 10, 0]  # 0 表示最大
	var qty_labels = ["1x", "5x", "10x", "最大"]
	for i in range(qty_values.size()):
		var btn = Button.new()
		btn.text = qty_labels[i]
		btn.size = Vector2(70, 28)
		btn.custom_minimum_size = Vector2(70, 28)
		var v = qty_values[i]
		btn.pressed.connect(_set_quantity.bind(v))
		_style_qty_btn(btn, i == 0)
		qty_hbox.add_child(btn)
		qty_buttons.append(btn)

func _set_quantity(v):
	craft_quantity = v if v > 0 else 999999
	for i in range(qty_buttons.size()):
		var vals = [1, 5, 10, 0]
		var selected = vals[i] == v
		_style_qty_btn(qty_buttons[i], selected)
	_update_detail()
	_update_craft_buttons()

func _style_qty_btn(btn: Button, selected: bool):
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0, 0.83, 1.0, 0.25) if selected else Color(0, 0.83, 1.0, 0.08)
	bs.border_color = Color(0, 0.83, 1.0, 0.6) if selected else Color(0, 0.83, 1.0, 0.2)
	bs.border_width_left = 1; bs.border_width_right = 1
	bs.border_width_top = 1; bs.border_width_bottom = 1
	bs.corner_radius_top_left = 4; bs.corner_radius_top_right = 4
	bs.corner_radius_bottom_left = 4; bs.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", bs)
	btn.add_theme_color_override("font_color", Color("#00d4ff") if selected else Color("#7a8aba"))
	btn.add_theme_font_size_override("font_size", 13)

# ---------- 配方列表 ----------

func _build_recipe_list():
	var vbox = $Panel/RecipeList/RecipeVBox
	for child in vbox.get_children():
		child.queue_free()
	recipe_widgets.clear()

	for recipe_name in get_node("/root/CraftingSystem").recipes:
		var card = _create_recipe_card(recipe_name)
		vbox.add_child(card)

func _create_recipe_card(recipe_name: String):
	var recipe = get_node("/root/CraftingSystem").recipes[recipe_name]

	# 卡片背景面板
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(220, 52)
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.1, 0.1, 0.25, 0.3)
	card_style.border_color = Color(0, 0.83, 1.0, 0.1)
	card_style.border_width_left = 1; card_style.border_width_right = 1
	card_style.border_width_top = 1; card_style.border_width_bottom = 1
	card_style.corner_radius_top_left = 4; card_style.corner_radius_top_right = 4
	card_style.corner_radius_bottom_left = 4; card_style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", card_style)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS

	var hbox = HBoxContainer.new()
	hbox.size = Vector2(218, 50)
	hbox.position = Vector2(1, 1)
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	panel.add_child(hbox)

	# 图标
	var icon = ColorRect.new()
	icon.size = Vector2(32, 32)
	icon.custom_minimum_size = Vector2(32, 32)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var icolor = ITEM_COLORS.get(recipe_name, Color.WHITE)
	icon.color = icolor
	var ics = StyleBoxFlat.new()
	ics.bg_color = icolor
	ics.corner_radius_top_left = 4; ics.corner_radius_top_right = 4
	ics.corner_radius_bottom_left = 4; ics.corner_radius_bottom_right = 4
	icon.add_theme_stylebox_override("panel", ics)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon)

	# 名称+材料
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var name_label = Label.new()
	name_label.text = recipe_name
	name_label.add_theme_color_override("font_color", Color("#d0dcff"))
	name_label.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(name_label)

	var mats_label = Label.new()
	var mats_parts = []
	for mat_name in recipe.ingredients:
		mats_parts.append(mat_name + "×" + str(recipe.ingredients[mat_name]))
	mats_label.text = " ".join(mats_parts)
	mats_label.add_theme_color_override("font_color", Color("#7a8aba"))
	mats_label.add_theme_font_size_override("font_size", 10)
	mats_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_vbox.add_child(mats_label)

	hbox.add_child(info_vbox)

	# 制作按钮
	var craft_btn = Button.new()
	craft_btn.text = "制作"
	craft_btn.size = Vector2(46, 28)
	craft_btn.custom_minimum_size = Vector2(46, 28)
	craft_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	craft_btn.pressed.connect(_on_craft.bind(recipe_name))
	hbox.add_child(craft_btn)

	# 选中高亮样式
	var select_bg = StyleBoxFlat.new()
	select_bg.bg_color = Color(0, 0.83, 1.0, 0.12)
	select_bg.border_color = Color(0, 0.83, 1.0, 0.3)
	select_bg.border_width_left = 1; select_bg.border_width_right = 1
	select_bg.border_width_top = 1; select_bg.border_width_bottom = 1
	select_bg.corner_radius_top_left = 4; select_bg.corner_radius_top_right = 4
	select_bg.corner_radius_bottom_left = 4; select_bg.corner_radius_bottom_right = 4

	recipe_widgets[recipe_name] = {
		"craft_btn": craft_btn,
		"panel": panel,
		"style": card_style,
		"select_style": select_bg,
	}

	# 点击卡片选中
	panel.gui_input.connect(_on_recipe_card_click.bind(recipe_name))

	return panel

func _on_recipe_card_click(event: InputEvent, recipe_name: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_recipe(recipe_name)

func _select_recipe(recipe_name):
	selected_recipe = recipe_name
	# 更新所有卡片样式
	for rname in recipe_widgets:
		var w = recipe_widgets[rname]
		if rname == recipe_name:
			w.panel.add_theme_stylebox_override("panel", w.select_style)
		else:
			w.panel.add_theme_stylebox_override("panel", w.style)
	_update_detail()

# ---------- 详情面板 ----------

func _update_detail():
	var dvbox = $Panel/DetailPanel/DetailVBox
	# 清空旧内容
	for child in dvbox.get_children():
		child.queue_free()

	if selected_recipe == null or not get_node("/root/CraftingSystem").recipes.has(selected_recipe):
		var empty_label = Label.new()
		empty_label.text = "请选择配方"
		empty_label.add_theme_color_override("font_color", Color("#7a8aba"))
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.size = Vector2(200, 290)
		dvbox.add_child(empty_label)
		return

	var recipe = get_node("/root/CraftingSystem").recipes[selected_recipe]
	var max_craft = get_node("/root/CraftingSystem").can_craft(selected_recipe, current_inventory) if current_inventory else 0
	var actual_qty = min(craft_quantity, max_craft) if craft_quantity < 999999 else max_craft

	# 标题
	var title_lbl = Label.new()
	title_lbl.text = selected_recipe
	title_lbl.add_theme_color_override("font_color", Color("#00d4ff"))
	title_lbl.add_theme_font_size_override("font_size", 16)
	dvbox.add_child(title_lbl)

	# 分隔线
	var sep = HSeparator.new()
	sep.size = Vector2(200, 4)
	dvbox.add_child(sep)

	# 材料列表
	for mat_name in recipe.ingredients:
		var needed = recipe.ingredients[mat_name]
		var have = get_node("/root/CraftingSystem").count_item(current_inventory, mat_name) if current_inventory else 0
		var enough = have >= needed * actual_qty

		var mat_hbox = HBoxContainer.new()
		var mat_icon = ColorRect.new()
		mat_icon.size = Vector2(16, 16)
		mat_icon.custom_minimum_size = Vector2(16, 16)
		var mic = ITEM_COLORS.get(mat_name, Color.WHITE)
		mat_icon.color = mic
		var mics = StyleBoxFlat.new()
		mics.bg_color = mic
		mics.corner_radius_top_left = 2; mics.corner_radius_top_right = 2
		mics.corner_radius_bottom_left = 2; mics.corner_radius_bottom_right = 2
		mat_icon.add_theme_stylebox_override("panel", mics)
		mat_hbox.add_child(mat_icon)

		var mat_label = Label.new()
		mat_label.text = "%s: %d / %d" % [mat_name, have, needed * actual_qty]
		mat_label.add_theme_color_override("font_color", Color("#2ecc71") if enough else Color("#e74c3c"))
		mat_label.add_theme_font_size_override("font_size", 12)
		mat_hbox.add_child(mat_label)

		dvbox.add_child(mat_hbox)

	# 可制作数量
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	dvbox.add_child(spacer)

	var craft_count_lbl = Label.new()
	craft_count_lbl.text = "可制作: %d 次" % max_craft
	craft_count_lbl.add_theme_color_override("font_color", Color("#d0dcff"))
	craft_count_lbl.add_theme_font_size_override("font_size", 12)
	dvbox.add_child(craft_count_lbl)

	var result_count_lbl = Label.new()
	result_count_lbl.text = "每次获得: %d 个" % recipe.result_count
	result_count_lbl.add_theme_color_override("font_color", Color("#7a8aba"))
	result_count_lbl.add_theme_font_size_override("font_size", 12)
	dvbox.add_child(result_count_lbl)

	var will_get = actual_qty * recipe.result_count
	var will_get_lbl = Label.new()
	will_get_lbl.text = "本次获得: %d 个" % will_get
	will_get_lbl.add_theme_color_override("font_color", Color("#ffd740"))
	will_get_lbl.add_theme_font_size_override("font_size", 12)
	dvbox.add_child(will_get_lbl)

# ---------- 制作按钮 ----------

func _update_craft_buttons():
	if not current_inventory:
		return
	for recipe_name in recipe_widgets:
		var w = recipe_widgets[recipe_name]
		var max_possible = get_node("/root/CraftingSystem").can_craft(recipe_name, current_inventory)
		var can = max_possible >= 1
		_style_craft_btn(w.craft_btn, can)

func _style_craft_btn(btn: Button, enabled: bool):
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0, 0.83, 1.0, 0.15) if enabled else Color(0.3, 0.3, 0.3, 0.15)
	bs.border_color = Color(0, 0.83, 1.0, 0.4) if enabled else Color(0.3, 0.3, 0.3, 0.2)
	bs.border_width_left = 1; bs.border_width_right = 1
	bs.border_width_top = 1; bs.border_width_bottom = 1
	bs.corner_radius_top_left = 4; bs.corner_radius_top_right = 4
	bs.corner_radius_bottom_left = 4; bs.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", bs)
	btn.add_theme_color_override("font_color", Color("#d0dcff") if enabled else Color("#555555"))
	btn.add_theme_font_size_override("font_size", 12)
	btn.disabled = not enabled

func _on_craft(recipe_name: String):
	if not current_inventory:
		return
	var qty = craft_quantity if craft_quantity < 999999 else get_node("/root/CraftingSystem").can_craft(recipe_name, current_inventory)
	if qty <= 0:
		return
	if get_node("/root/CraftingSystem").craft(recipe_name, current_inventory, qty):
		item_crafted.emit(recipe_name, qty)
		_update_detail()
		_update_craft_buttons()

# ---------- 通用 ----------

func open(inventory):
	current_inventory = inventory
	selected_recipe = null
	craft_quantity = 1
	_build_recipe_list()
	# 重置数量按钮状态（默认1x选中）
	for i in range(qty_buttons.size()):
		var vals = [1, 5, 10, 0]
		_style_qty_btn(qty_buttons[i], vals[i] == 1)
	_update_detail()
	_update_craft_buttons()
	visible = true

func center_panel():
	var ws = get_window().size
	var p = $Panel
	p.position = Vector2((ws.x - p.size.x) / 2, (ws.y - p.size.y) / 2)

func _on_close():
	crafting_closed.emit()
	visible = false
