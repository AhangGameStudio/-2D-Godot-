extends Control

signal shop_closed()
signal item_bought(item_name, quantity, cost)
signal item_sold(item_name, quantity, revenue)

# 商店物品数据
const SHOP_SELLS = {
	"工具": 20,
	"药水": 15,
	"布匹": 8,
	"木板": 10,
	"石砖": 12,
}

const SHOP_BUYS = {
	"肉": 3,
	"木头": 2,
	"石头": 3,
	"水晶": 5,
	"冰晶": 6,
	"布匹": 4,
}

const ITEM_COLORS = {
	"木头": Color("#8B5A2B"),
	"石头": Color("#A0A0A0"),
	"水晶": Color("#9B59B6"),
	"布匹": Color("#F5DEB3"),
	"木板": Color("#CD853F"),
	"石砖": Color("#696969"),
	"工具": Color("#FF8C00"),
	"药水": Color("#2ECC71"),
	"肉": Color("#E74C3C"),
	"冰晶": Color("#88DDDD"),
}

var current_inventory = null
var player_stats = null
var selected_side = ""  # "inventory" or "shop"
var selected_item_name = ""
var merchant_level = 1

# UI 节点缓存
var inv_container = null
var shop_container = null
var info_name_label = null
var info_price_label = null
var buy_button = null
var sell_button = null
var gold_label = null

func _ready():
	_style_panel()
	_build_layout()
	
	await get_tree().process_frame
	center_panel()
	get_window().size_changed.connect(center_panel)

	# 关闭按钮
	var close_btn = $Panel/CloseButton
	if close_btn:
		close_btn.pressed.connect(_on_close)

func _style_panel():
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.06, 0.16, 0.92)
	ps.border_color = Color(0, 0.83, 1.0, 0.3)
	ps.border_width_left = 1; ps.border_width_right = 1
	ps.border_width_top = 1; ps.border_width_bottom = 3
	ps.corner_radius_top_left = 10; ps.corner_radius_top_right = 10
	ps.corner_radius_bottom_left = 10; ps.corner_radius_bottom_right = 10
	$Panel.add_theme_stylebox_override("panel", ps)

func _build_layout():
	var panel = $Panel
	panel.size = Vector2(600, 420)
	
	# 标题
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "商 店"
	title.position = Vector2(20, 12)
	title.size = Vector2(100, 24)
	title.add_theme_color_override("font_color", Color("#00d4ff"))
	title.add_theme_font_size_override("font_size", 18)
	panel.add_child(title)

	# 关闭按钮
	var close_btn = Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "X"
	close_btn.position = Vector2(550, 10)
	close_btn.size = Vector2(40, 24)
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
	panel.add_child(close_btn)

	# 金币显示
	gold_label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.position = Vector2(130, 12)
	gold_label.size = Vector2(160, 24)
	gold_label.add_theme_color_override("font_color", Color("#ffd740"))
	gold_label.add_theme_font_size_override("font_size", 16)
	gold_label.text = "金币: 0"
	panel.add_child(gold_label)

	# 左侧：玩家背包
	var inv_header = Label.new()
	inv_header.text = "— 我的背包 —"
	inv_header.position = Vector2(20, 45)
	inv_header.size = Vector2(260, 20)
	inv_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inv_header.add_theme_color_override("font_color", Color("#7a8aba"))
	inv_header.add_theme_font_size_override("font_size", 13)
	panel.add_child(inv_header)

	# 左侧背包滚动容器
	var inv_scroll = ScrollContainer.new()
	inv_scroll.name = "InvScroll"
	inv_scroll.position = Vector2(15, 68)
	inv_scroll.size = Vector2(275, 260)
	var invs = StyleBoxFlat.new()
	invs.bg_color = Color(0.08, 0.08, 0.2, 0.4)
	invs.border_color = Color(0, 0.83, 1.0, 0.12)
	invs.border_width_left = 1; invs.border_width_right = 1
	invs.border_width_top = 1; invs.border_width_bottom = 1
	invs.corner_radius_top_left = 6; invs.corner_radius_top_right = 6
	invs.corner_radius_bottom_left = 6; invs.corner_radius_bottom_right = 6
	inv_scroll.add_theme_stylebox_override("panel", invs)
	panel.add_child(inv_scroll)

	inv_container = VBoxContainer.new()
	inv_container.name = "InvContainer"
	inv_container.size = Vector2(260, 0)
	inv_scroll.add_child(inv_container)

	# 右侧：商店库存
	var shop_header = Label.new()
	shop_header.text = "— 商人商品 —"
	shop_header.position = Vector2(320, 45)
	shop_header.size = Vector2(260, 20)
	shop_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_header.add_theme_color_override("font_color", Color("#7a8aba"))
	shop_header.add_theme_font_size_override("font_size", 13)
	panel.add_child(shop_header)

	var shop_scroll = ScrollContainer.new()
	shop_scroll.name = "ShopScroll"
	shop_scroll.position = Vector2(310, 68)
	shop_scroll.size = Vector2(275, 260)
	var shops = StyleBoxFlat.new()
	shops.bg_color = Color(0.08, 0.08, 0.2, 0.4)
	shops.border_color = Color(0, 0.83, 1.0, 0.12)
	shops.border_width_left = 1; shops.border_width_right = 1
	shops.border_width_top = 1; shops.border_width_bottom = 1
	shops.corner_radius_top_left = 6; shops.corner_radius_top_right = 6
	shops.corner_radius_bottom_left = 6; shops.corner_radius_bottom_right = 6
	shop_scroll.add_theme_stylebox_override("panel", shops)
	panel.add_child(shop_scroll)

	shop_container = VBoxContainer.new()
	shop_container.name = "ShopContainer"
	shop_container.size = Vector2(260, 0)
	shop_scroll.add_child(shop_container)

	# 底部信息栏
	var info_panel = Panel.new()
	info_panel.name = "InfoPanel"
	info_panel.position = Vector2(15, 336)
	info_panel.size = Vector2(570, 42)
	var ips = StyleBoxFlat.new()
	ips.bg_color = Color(0.08, 0.08, 0.2, 0.5)
	ips.border_color = Color(0, 0.83, 1.0, 0.15)
	ips.border_width_left = 1; ips.border_width_right = 1
	ips.border_width_top = 1; ips.border_width_bottom = 1
	ips.corner_radius_top_left = 6; ips.corner_radius_top_right = 6
	ips.corner_radius_bottom_left = 6; ips.corner_radius_bottom_right = 6
	info_panel.add_theme_stylebox_override("panel", ips)
	panel.add_child(info_panel)

	info_name_label = Label.new()
	info_name_label.name = "InfoName"
	info_name_label.position = Vector2(12, 5)
	info_name_label.size = Vector2(140, 30)
	info_name_label.text = "选择物品"
	info_name_label.add_theme_color_override("font_color", Color("#d0dcff"))
	info_name_label.add_theme_font_size_override("font_size", 14)
	info_panel.add_child(info_name_label)

	info_price_label = Label.new()
	info_price_label.name = "InfoPrice"
	info_price_label.position = Vector2(155, 5)
	info_price_label.size = Vector2(140, 30)
	info_price_label.add_theme_color_override("font_color", Color("#ffd740"))
	info_price_label.add_theme_font_size_override("font_size", 14)
	info_panel.add_child(info_price_label)

	# 购买按钮
	buy_button = Button.new()
	buy_button.name = "BuyButton"
	buy_button.text = "购买"
	buy_button.position = Vector2(310, 5)
	buy_button.size = Vector2(80, 30)
	buy_button.pressed.connect(_on_buy)
	info_panel.add_child(buy_button)
	_style_action_btn(buy_button, Color("#2ecc71"))

	# 出售按钮
	sell_button = Button.new()
	sell_button.name = "SellButton"
	sell_button.text = "出售"
	sell_button.position = Vector2(400, 5)
	sell_button.size = Vector2(80, 30)
	sell_button.pressed.connect(_on_sell)
	info_panel.add_child(sell_button)
	_style_action_btn(sell_button, Color("#ff8c00"))

	# 分割线
	var sep = HSeparator.new()
	sep.position = Vector2(285, 45)
	sep.size = Vector2(30, 4)
	sep.rotation = 1.57
	panel.add_child(sep)

func _style_action_btn(btn: Button, accent: Color):
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(accent.r, accent.g, accent.b, 0.15)
	bs.border_color = Color(accent.r, accent.g, accent.b, 0.5)
	bs.border_width_left = 1; bs.border_width_right = 1
	bs.border_width_top = 1; bs.border_width_bottom = 1
	bs.corner_radius_top_left = 4; bs.corner_radius_top_right = 4
	bs.corner_radius_bottom_left = 4; bs.corner_radius_bottom_right = 4
	var bh = bs.duplicate()
	bh.bg_color = Color(accent.r, accent.g, accent.b, 0.3)
	bh.border_color = Color(accent.r, accent.g, accent.b, 0.8)
	btn.add_theme_stylebox_override("normal", bs)
	btn.add_theme_stylebox_override("hover", bh)
	btn.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.9))
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 13)

# ---------- 价格计算 ----------

func _get_buy_price(base_price: int) -> int:
	# 购买价 = 基础价 × 1.5 × (1 - 商贾等级 × 0.01)
	var discount = 1.0 - merchant_level * 0.01
	return max(1, int(base_price * 1.5 * discount))

func _get_sell_price(base_price: int) -> int:
	# 出售价 = 基础价 × 0.4 × (1 + 商贾等级 × 0.01)
	var bonus = 1.0 + merchant_level * 0.01
	return max(1, int(base_price * 0.4 * bonus))

# ---------- 物品卡片 ----------

func _create_item_card(item_name: String, quantity: int, price_str: String, side: String) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(260, 36)
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.1, 0.1, 0.25, 0.3)
	card_style.border_color = Color(0, 0.83, 1.0, 0.1)
	card_style.border_width_left = 1; card_style.border_width_right = 1
	card_style.border_width_top = 1; card_style.border_width_bottom = 1
	card_style.corner_radius_top_left = 4; card_style.corner_radius_top_right = 4
	card_style.corner_radius_bottom_left = 4; card_style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", card_style)

	var hbox = HBoxContainer.new()
	hbox.size = Vector2(258, 34)
	hbox.position = Vector2(1, 1)
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	panel.add_child(hbox)

	# 图标
	var icon = ColorRect.new()
	icon.size = Vector2(24, 24)
	icon.custom_minimum_size = Vector2(24, 24)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var icolor = ITEM_COLORS.get(item_name, Color.WHITE)
	icon.color = icolor
	var ics = StyleBoxFlat.new()
	ics.bg_color = icolor
	ics.corner_radius_top_left = 4; ics.corner_radius_top_right = 4
	ics.corner_radius_bottom_left = 4; ics.corner_radius_bottom_right = 4
	icon.add_theme_stylebox_override("panel", ics)
	hbox.add_child(icon)

	# 名称 + 数量
	var name_label = Label.new()
	name_label.text = item_name + " × " + str(quantity)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", Color("#d0dcff"))
	name_label.add_theme_font_size_override("font_size", 12)
	hbox.add_child(name_label)

	# 价格
	var price_label = Label.new()
	price_label.text = price_str
	price_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	price_label.add_theme_color_override("font_color", Color("#ffd740"))
	price_label.add_theme_font_size_override("font_size", 12)
	hbox.add_child(price_label)

	# 选中高亮样式
	var select_style = card_style.duplicate()
	select_style.bg_color = Color(0, 0.83, 1.0, 0.12)
	select_style.border_color = Color(0, 0.83, 1.0, 0.3)

	# 点击选中
	panel.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_item(side, item_name))

	panel.set_meta("select_style", select_style)
	panel.set_meta("normal_style", card_style)
	panel.set_meta("side", side)
	panel.set_meta("item_name", item_name)

	return panel

func _select_item(side: String, item_name: String):
	selected_side = side
	selected_item_name = item_name

	# 更新所有卡片高亮
	for container in [inv_container, shop_container]:
		for child in container.get_children():
			if child is Panel:
				var cs = child.get_meta("normal_style")
				var ss = child.get_meta("select_style")
				var item_side = child.get_meta("side")
				var item_n = child.get_meta("item_name")
				if item_side == side and item_n == item_name:
					child.add_theme_stylebox_override("panel", ss)
				else:
					child.add_theme_stylebox_override("panel", cs)

	_update_info()

func _update_info():
	info_name_label.text = "选择物品"
	info_price_label.text = ""
	buy_button.visible = false
	sell_button.visible = false

	if selected_side == "" or selected_item_name == "":
		return

	if selected_side == "inventory":
		# 玩家背包选中 → 可出售（如果在收购列表中）
		var base_price = SHOP_BUYS.get(selected_item_name, 0)
		if base_price > 0:
			var price = _get_sell_price(base_price)
			info_name_label.text = selected_item_name
			info_price_label.text = "出售价: %d 金币" % price
			sell_button.visible = true
			# 查找背包数量
			var qty = _count_item(selected_item_name)
			sell_button.text = "出售(有%d)" % qty
		else:
			info_name_label.text = selected_item_name
			info_price_label.text = "商人不需要此物品"
			sell_button.visible = false
		buy_button.visible = false

	elif selected_side == "shop":
		# 商店选中 → 可购买
		var base_price = SHOP_SELLS.get(selected_item_name, 0)
		if base_price > 0:
			var price = _get_buy_price(base_price)
			info_name_label.text = selected_item_name
			info_price_label.text = "购买价: %d 金币" % price
			buy_button.visible = true
		sell_button.visible = false

# ---------- 交易操作 ----------

func _on_buy():
	if selected_side != "shop" or selected_item_name == "" or current_inventory == null:
		return
	var base_price = SHOP_SELLS.get(selected_item_name, 0)
	if base_price <= 0:
		return
	var cost = _get_buy_price(base_price)
	var gold = _get_gold()

	if gold < cost:
		# 显示提示 — 通知父节点
		var main = get_tree().current_scene
		if main and main.has_method("show_notification"):
			main.show_notification("金币不足！需要 %d 金币" % cost, 2.0)
		return

	# 扣除金币，添加物品
	_spend_gold(cost)
	current_inventory.items.append({"name": selected_item_name, "quantity": 1})
	item_bought.emit(selected_item_name, 1, cost)
	refresh()

	# 提示
	var main = get_tree().current_scene
	if main and main.has_method("show_notification"):
		main.show_notification("购买成功：%s × 1（-%d金币）" % [selected_item_name, cost], 2.0)

func _on_sell():
	if selected_side != "inventory" or selected_item_name == "" or current_inventory == null:
		return
	var base_price = SHOP_BUYS.get(selected_item_name, 0)
	if base_price <= 0:
		return

	# 检查是否有该物品
	var qty = _count_item(selected_item_name)
	if qty <= 0:
		return

	# 出售一个
	for i in range(current_inventory.items.size() - 1, -1, -1):
		if current_inventory.items[i].get("name", "") == selected_item_name:
			current_inventory.items[i].quantity -= 1
			if current_inventory.items[i].quantity <= 0:
				current_inventory.items.remove_at(i)
			break

	var revenue = _get_sell_price(base_price)
	_add_gold(revenue)
	item_sold.emit(selected_item_name, 1, revenue)
	refresh()

	# 提示
	var main = get_tree().current_scene
	if main and main.has_method("show_notification"):
		main.show_notification("出售成功：%s × 1（+%d金币）" % [selected_item_name, revenue], 2.0)

func _count_item(item_name: String) -> int:
	if current_inventory == null:
		return 0
	for item in current_inventory.items:
		if item.get("name", "") == item_name:
			return item.get("quantity", 0)
	return 0

func _get_gold() -> int:
	if current_inventory == null:
		return 0
	return current_inventory.get("gold", 0)

func _spend_gold(amount: int):
	if current_inventory == null:
		return
	current_inventory.gold = max(0, _get_gold() - amount)

func _add_gold(amount: int):
	if current_inventory == null:
		return
	current_inventory.gold = _get_gold() + amount

# ---------- 公共接口 ----------

func open(inventory, player_stats_data):
	current_inventory = inventory
	player_stats = player_stats_data

	# 获取商贾等级
	if player_stats and player_stats.has("skills") and player_stats.skills.has("merchant"):
		merchant_level = player_stats.skills.merchant.get("level", 1)
	else:
		merchant_level = 1

	selected_side = ""
	selected_item_name = ""
	refresh()
	visible = true

func close():
	shop_closed.emit()
	visible = false

func refresh():
	if not is_node_ready():
		return

	# 刷新金币
	if gold_label:
		gold_label.text = "金币: %d" % _get_gold()

	# 刷新背包列表
	for child in inv_container.get_children():
		child.queue_free()
	if current_inventory:
		for item in current_inventory.items:
			var item_name = item.get("name", "")
			var qty = item.get("quantity", 0)
			if qty <= 0:
				continue
			var base_price = SHOP_BUYS.get(item_name, 0)
			var price_str = ""
			if base_price > 0:
				price_str = "%d G" % _get_sell_price(base_price)
			var card = _create_item_card(item_name, qty, price_str, "inventory")
			inv_container.add_child(card)

	# 刷新商店列表
	for child in shop_container.get_children():
		child.queue_free()
	for item_name in SHOP_SELLS:
		var base_price = SHOP_SELLS[item_name]
		var price = _get_buy_price(base_price)
		var card = _create_item_card(item_name, 0, "%d G" % price, "shop")
		shop_container.add_child(card)

	# 重置选择状态
	selected_side = ""
	selected_item_name = ""
	info_name_label.text = "选择物品"
	info_price_label.text = ""
	buy_button.visible = false
	sell_button.visible = false

func center_panel():
	var ws = get_window().size
	var p = $Panel
	if p:
		p.position = Vector2((ws.x - p.size.x) / 2, (ws.y - p.size.y) / 2)

func _on_close():
	close()
