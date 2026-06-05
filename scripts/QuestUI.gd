extends Control

signal quest_accepted(quest_id)
signal quest_ui_closed()

var selected_quest_id = null
var quest_list_container = null
var detail_container = null
var accept_btn = null

func _ready():
	build_ui()
	await get_tree().process_frame
	center_panel()
	get_tree().root.size_changed.connect(center_panel)
	
	# 监听任务数据更新
	var qm = get_node("/root/QuestManager")
	if qm:
		qm.quest_updated.connect(_on_quest_data_changed)
		qm.quest_progress.connect(_on_quest_data_changed)

func build_ui():
	# 主面板
	var main_panel = Panel.new()
	main_panel.name = "MainPanel"
	main_panel.size = Vector2(700, 480)
	add_child(main_panel)
	
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.06, 0.16, 0.95)
	ps.border_color = Color(0, 0.83, 1.0, 0.35)
	ps.border_width_left = 1; ps.border_width_right = 1
	ps.border_width_top = 1; ps.border_width_bottom = 3
	ps.corner_radius_top_left = 10; ps.corner_radius_top_right = 10
	ps.corner_radius_bottom_left = 10; ps.corner_radius_bottom_right = 10
	main_panel.add_theme_stylebox_override("panel", ps)
	
	# 标题
	var title = Label.new()
	title.name = "TitleLabel"
	title.position = Vector2(20, 12)
	title.size = Vector2(160, 28)
	title.text = "任 务 面 板"
	title.add_theme_color_override("font_color", Color("#00d4ff"))
	title.add_theme_font_size_override("font_size", 20)
	main_panel.add_child(title)
	
	# 关闭按钮
	var close_btn = Button.new()
	close_btn.name = "CloseButton"
	close_btn.position = Vector2(655, 10)
	close_btn.size = Vector2(35, 24)
	close_btn.text = "X"
	var clos_bs = StyleBoxFlat.new()
	clos_bs.bg_color = Color(1, 0.2, 0.2, 0.15)
	clos_bs.border_color = Color(1, 0.2, 0.2, 0.4)
	clos_bs.border_width_left = 1; clos_bs.border_width_right = 1
	clos_bs.border_width_top = 1; clos_bs.border_width_bottom = 1
	clos_bs.corner_radius_top_left = 4; clos_bs.corner_radius_top_right = 4
	clos_bs.corner_radius_bottom_left = 4; clos_bs.corner_radius_bottom_right = 4
	close_btn.add_theme_stylebox_override("normal", clos_bs)
	close_btn.add_theme_color_override("font_color", Color("#ff5555"))
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(_on_close)
	main_panel.add_child(close_btn)
	
	# ----- 左侧：任务列表 -----
	var left_panel = Panel.new()
	left_panel.name = "LeftPanel"
	left_panel.position = Vector2(15, 48)
	left_panel.size = Vector2(280, 385)
	var left_ps = StyleBoxFlat.new()
	left_ps.bg_color = Color(0.08, 0.08, 0.2, 0.4)
	left_ps.border_color = Color(0, 0.83, 1.0, 0.12)
	left_ps.border_width_left = 1; left_ps.border_width_right = 1
	left_ps.border_width_top = 1; left_ps.border_width_bottom = 1
	left_ps.corner_radius_top_left = 6; left_ps.corner_radius_top_right = 6
	left_ps.corner_radius_bottom_left = 6; left_ps.corner_radius_bottom_right = 6
	left_panel.add_theme_stylebox_override("panel", left_ps)
	main_panel.add_child(left_panel)
	
	# 滚动容器装任务列表
	var scroll = ScrollContainer.new()
	scroll.name = "QuestScroll"
	scroll.position = Vector2(5, 5)
	scroll.size = Vector2(270, 375)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_panel.add_child(scroll)
	
	quest_list_container = VBoxContainer.new()
	quest_list_container.name = "QuestListContainer"
	quest_list_container.size = Vector2(258, 0)
	quest_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(quest_list_container)
	
	# ----- 右侧：详情面板 -----
	var right_panel = Panel.new()
	right_panel.name = "RightPanel"
	right_panel.position = Vector2(305, 48)
	right_panel.size = Vector2(380, 385)
	var right_ps = StyleBoxFlat.new()
	right_ps.bg_color = Color(0.08, 0.08, 0.2, 0.4)
	right_ps.border_color = Color(0, 0.83, 1.0, 0.12)
	right_ps.border_width_left = 1; right_ps.border_width_right = 1
	right_ps.border_width_top = 1; right_ps.border_width_bottom = 1
	right_ps.corner_radius_top_left = 6; right_ps.corner_radius_top_right = 6
	right_ps.corner_radius_bottom_left = 6; right_ps.corner_radius_bottom_right = 6
	right_panel.add_theme_stylebox_override("panel", right_ps)
	main_panel.add_child(right_panel)
	
	detail_container = VBoxContainer.new()
	detail_container.name = "DetailContainer"
	detail_container.position = Vector2(310, 55)
	detail_container.size = Vector2(370, 370)
	main_panel.add_child(detail_container)
	
	# 接受任务按钮
	accept_btn = Button.new()
	accept_btn.name = "AcceptBtn"
	accept_btn.position = Vector2(310, 440)
	accept_btn.size = Vector2(140, 30)
	accept_btn.text = "接受任务"
	accept_btn.visible = false
	var abs = StyleBoxFlat.new()
	abs.bg_color = Color(0, 0.83, 1.0, 0.15)
	abs.border_color = Color(0, 0.83, 1.0, 0.4)
	abs.border_width_left = 1; abs.border_width_right = 1
	abs.border_width_top = 1; abs.border_width_bottom = 1
	abs.corner_radius_top_left = 4; abs.corner_radius_top_right = 4
	abs.corner_radius_bottom_left = 4; abs.corner_radius_bottom_right = 4
	accept_btn.add_theme_stylebox_override("normal", abs)
	accept_btn.add_theme_color_override("font_color", Color("#d0dcff"))
	accept_btn.add_theme_font_size_override("font_size", 14)
	accept_btn.pressed.connect(_on_accept)
	main_panel.add_child(accept_btn)

func refresh():
	_rebuild_quest_list()
	_update_detail()

func _rebuild_quest_list():
	# 清空
	for child in quest_list_container.get_children():
		child.queue_free()
	
	var qm = get_node("/root/QuestManager")
	if not qm:
		return
	
	# 可用任务
	_add_category_label("—— 可用任务 ——", Color("#7a8aba"))
	var available = qm.get_available_quests()
	if available.size() == 0:
		_add_empty_label("暂无可用任务")
	else:
		for qid in available:
			_add_quest_item(qid, Color("#7a8aba"))
	
	# 进行中任务
	_add_category_label("—— 进行中 ——", Color("#00d4ff"))
	var active = qm.get_active_quests()
	if active.size() == 0:
		_add_empty_label("暂无进行中的任务")
	else:
		for qid in active:
			_add_quest_item(qid, Color("#00d4ff"))
	
	# 已完成任务
	_add_category_label("—— 已完成 ——", Color("#2ecc71"))
	var completed = qm.get_completed_quests()
	if completed.size() == 0:
		_add_empty_label("暂无已完成的任务")
	else:
		for qid in completed:
			_add_quest_item(qid, Color("#555555"))

func _add_category_label(text: String, color: Color):
	var lb = Label.new()
	lb.text = text
	lb.custom_minimum_size = Vector2(0, 22)
	lb.add_theme_color_override("font_color", color)
	lb.add_theme_font_size_override("font_size", 11)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_list_container.add_child(lb)

func _add_empty_label(text: String):
	var lb = Label.new()
	lb.text = text
	lb.custom_minimum_size = Vector2(0, 20)
	lb.add_theme_color_override("font_color", Color("#555555"))
	lb.add_theme_font_size_override("font_size", 11)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_list_container.add_child(lb)

func _add_quest_item(quest_id: String, color: Color):
	var qm = get_node("/root/QuestManager")
	if not qm or not qm.quests.has(quest_id):
		return
	var q = qm.quests[quest_id]
	
	var item = Panel.new()
	item.custom_minimum_size = Vector2(0, 32)
	item.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var item_style = StyleBoxFlat.new()
	item_style.bg_color = Color(0.1, 0.1, 0.25, 0.3)
	item_style.border_color = Color(0, 0.83, 1.0, 0.08)
	item_style.border_width_left = 1; item_style.border_width_right = 1
	item_style.border_width_top = 1; item_style.border_width_bottom = 1
	item_style.corner_radius_top_left = 4; item_style.corner_radius_top_right = 4
	item_style.corner_radius_bottom_left = 4; item_style.corner_radius_bottom_right = 4
	item.add_theme_stylebox_override("panel", item_style)
	
	var label = Label.new()
	label.position = Vector2(8, 7)
	label.size = Vector2(250, 18)
	label.text = quest_id
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 12)
	item.add_child(label)
	
	# 点击选中
	item.gui_input.connect(_on_quest_item_click.bind(quest_id))
	
	quest_list_container.add_child(item)

func _on_quest_item_click(event: InputEvent, quest_id: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected_quest_id = quest_id
		_update_detail()

func _update_detail():
	# 清空
	for child in detail_container.get_children():
		child.queue_free()
	
	if selected_quest_id == null:
		var hint = Label.new()
		hint.text = "请选择一个任务"
		hint.add_theme_color_override("font_color", Color("#7a8aba"))
		hint.add_theme_font_size_override("font_size", 14)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.size = Vector2(370, 370)
		detail_container.add_child(hint)
		accept_btn.visible = false
		return
	
	var qm = get_node("/root/QuestManager")
	if not qm or not qm.quests.has(selected_quest_id):
		accept_btn.visible = false
		return
	
	var q = qm.quests[selected_quest_id]
	
	# 任务名
	var name_lb = Label.new()
	name_lb.text = q.name
	name_lb.add_theme_color_override("font_color", Color("#00d4ff"))
	name_lb.add_theme_font_size_override("font_size", 18)
	detail_container.add_child(name_lb)
	
	# 分隔线
	var sep = HSeparator.new()
	sep.size = Vector2(370, 4)
	detail_container.add_child(sep)
	
	# 描述
	var desc_lb = Label.new()
	desc_lb.text = "描述： " + q.desc
	desc_lb.add_theme_color_override("font_color", Color("#d0dcff"))
	desc_lb.add_theme_font_size_override("font_size", 13)
	desc_lb.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lb.custom_minimum_size = Vector2(370, 30)
	detail_container.add_child(desc_lb)
	
	# 状态
	var status_text = "状态："
	var status_color = Color("#7a8aba")
	if q.completed:
		status_text += "已完成"
		status_color = Color("#2ecc71")
	elif q.active:
		status_text += "进行中"
		status_color = Color("#00d4ff")
	else:
		status_text += "未接取"
		status_color = Color("#ffb347")
	
	var status_lb = Label.new()
	status_lb.text = status_text
	status_lb.add_theme_color_override("font_color", status_color)
	status_lb.add_theme_font_size_override("font_size", 13)
	detail_container.add_child(status_lb)
	
	# 进度
	if q.active:
		var progress_text = "进度： %d / %d" % [q.progress, q.required]
		var progress_lb = Label.new()
		progress_lb.text = progress_text
		progress_lb.add_theme_color_override("font_color", Color("#d0dcff"))
		progress_lb.add_theme_font_size_override("font_size", 13)
		detail_container.add_child(progress_lb)
		
		# 进度条
		var bar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(350, 16)
		bar.max_value = q.required
		bar.value = q.progress
		bar.show_percentage = false
		var bar_bg = StyleBoxFlat.new()
		bar_bg.bg_color = Color(0, 0, 0, 0.3)
		bar_bg.corner_radius_top_left = 3; bar_bg.corner_radius_top_right = 3
		bar_bg.corner_radius_bottom_left = 3; bar_bg.corner_radius_bottom_right = 3
		var bar_fill = StyleBoxFlat.new()
		bar_fill.bg_color = Color("#00d4ff")
		bar_fill.corner_radius_top_left = 3; bar_fill.corner_radius_top_right = 3
		bar_fill.corner_radius_bottom_left = 3; bar_fill.corner_radius_bottom_right = 3
		bar.add_theme_stylebox_override("background", bar_bg)
		bar.add_theme_stylebox_override("fill", bar_fill)
		detail_container.add_child(bar)
	
	# 奖励
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	detail_container.add_child(spacer)
	
	var reward_lb = Label.new()
	reward_lb.text = "—— 奖励 ——"
	reward_lb.add_theme_color_override("font_color", Color("#ffd740"))
	reward_lb.add_theme_font_size_override("font_size", 13)
	detail_container.add_child(reward_lb)
	
	if q.rewards.get("xp", 0) > 0:
		var xp_lb = Label.new()
		xp_lb.text = "经验值： +%d" % q.rewards.xp
		xp_lb.add_theme_color_override("font_color", Color("#d0dcff"))
		xp_lb.add_theme_font_size_override("font_size", 12)
		detail_container.add_child(xp_lb)
	
	var items = q.rewards.get("items", {})
	if items.size() > 0:
		var item_text = "物品： "
		var first = true
		for item_name in items:
			if not first:
				item_text += "，"
			item_text += "%s × %d" % [item_name, items[item_name]]
			first = false
		var item_lb = Label.new()
		item_lb.text = item_text
		item_lb.add_theme_color_override("font_color", Color("#d0dcff"))
		item_lb.add_theme_font_size_override("font_size", 12)
		item_lb.autowrap_mode = TextServer.AUTOWRAP_WORD
		item_lb.custom_minimum_size = Vector2(370, 20)
		detail_container.add_child(item_lb)
	
	# 接受按钮可见性
	accept_btn.visible = not q.active and not q.completed

func _on_accept():
	if selected_quest_id == null:
		return
	var qm = get_node("/root/QuestManager")
	if qm and qm.accept_quest(selected_quest_id):
		quest_accepted.emit(selected_quest_id)
		refresh()

func _on_quest_data_changed(_quest_id):
	refresh()

func _on_close():
	quest_ui_closed.emit()
	visible = false

func center_panel():
	var ws = get_window().size
	var p = $MainPanel
	if p:
		p.position = Vector2((ws.x - p.size.x) / 2, (ws.y - p.size.y) / 2)
