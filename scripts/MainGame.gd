extends Node2D

var player = null
var hud = null
var inventory_ui = null
var skill_ui = null
var crafting_ui = null
var shop_ui = null
var quest_ui = null
var fishing_ui = null
var camera = null
var pause_menu = null
var notif_label = null
var paused = false
var _last_player_region = ""

# 联机
var net = null
var remote_players = {}  # peer_id -> RemotePlayer node

var game_state = {
	day_time = 0, is_day = true,
	weather = "sunny",
	stats = {health=100, stamina=100, hunger=100, mana=50, level=1, exp=0},
	skills = {craftsman={level=1, xp=0, max_xp=100}, mage={level=1, xp=0, max_xp=100}, warrior={level=1, xp=0, max_xp=100}, merchant={level=1, xp=0, max_xp=100}, hermit={level=1, xp=0, max_xp=100}}
}

var _last_day_hour = -1

func _ready():
	player = $World/Player if has_node("World/Player") else null
	hud = $CanvasLayer/HUD if has_node("CanvasLayer/HUD") else null
	inventory_ui = $CanvasLayer/Inventory if has_node("CanvasLayer/Inventory") else null
	skill_ui = $CanvasLayer/SkillPanel if has_node("CanvasLayer/SkillPanel") else null
	camera = $Camera2D if has_node("Camera2D") else null
	
	# 相机初始位置对准玩家
	if camera and player:
		camera.position = player.position
	
	# 同步玩家初始状态
	if player and hud:
		hud.update_player_stats(player.stats)
	
	# 信号连接
	if hud and hud.has_signal("open_inventory"):
		hud.open_inventory.connect(_toggle_inventory)
	if hud and hud.has_signal("open_skills"):
		hud.open_skills.connect(_toggle_skills)
	if hud and hud.has_signal("open_crafting"):
		hud.open_crafting.connect(_toggle_crafting)
	if hud and hud.has_signal("open_quests"):
		hud.open_quests.connect(_toggle_quests)
	if player and player.has_signal("update_stats"):
		player.update_stats.connect(_on_player_stats_update)
	if player and player.has_signal("skill_xp_gained"):
		player.skill_xp_gained.connect(_on_player_skill_xp_gained)
	
	# 创建暂停菜单和通知系统
	_pause_setup()
	_notif_setup()
	
	# 创建钓鱼UI（默认隐藏）
	fishing_ui = preload("res://scripts/FishingUI.gd").new()
	fishing_ui.visible = false
	fishing_ui.fishing_result.connect(_on_fishing_result)
	$CanvasLayer.add_child(fishing_ui)
	
	# 任务UI
	quest_ui = $CanvasLayer/QuestUI if has_node("CanvasLayer/QuestUI") else null
	if quest_ui:
		quest_ui.visible = false
	
	# 连接任务系统信号
	var qm = get_node("/root/QuestManager")
	if qm:
		qm.quest_completed.connect(_on_quest_completed)
	
	# 联机初始化
	net = get_node("/root/NetworkManager") if has_node("/root/NetworkManager") else null
	if net and net.mode != net.MODE_NONE:
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		# 主机也注册自己
		if net.mode == net.MODE_HOST:
			net.player_connected.connect(_on_player_connected)
			_on_player_connected(1)
		# 客户端：连接后注册自己
		elif net.mode == net.MODE_CLIENT:
			net.register_player.rpc_id(1, net.player_name)

func _process(delta):
	if paused: return  # 暂停时不更新时间/相机
	update_day_time(delta)
	if player and camera:
		camera.position = camera.position.lerp(player.position, 0.1)
	# 检测玩家所在区域（用于探索任务）
	if player:
		var tile_x = int(player.position.x / 64)
		var tile_y = int(player.position.y / 64)
		var current_region = _get_region_name(tile_x, tile_y)
		if current_region != "" and current_region != _last_player_region:
			_last_player_region = current_region
			var qm = get_node("/root/QuestManager")
			if qm:
				qm.advance_quest("explore_region", current_region)
	# 联机同步：每秒约10次广播自己的位置
	if net and net.mode != net.MODE_NONE and player:
		var dir = Vector2.ZERO
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    dir.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  dir.y += 1
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  dir.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1
		_sync_player_position.rpc(multiplayer.get_unique_id(), player.position, dir.normalized() if dir.length() > 0 else Vector2.ZERO)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()

# ----- 联机 RPC -----

@rpc("any_peer", "unreliable", "call_local")
func _sync_player_position(pid: int, pos: Vector2, dir: Vector2):
	if pid == multiplayer.get_unique_id(): return  # 不处理自己
	if pid in remote_players and is_instance_valid(remote_players[pid]):
		remote_players[pid].remote_pos = pos
		remote_players[pid].remote_dir = dir

func _on_peer_connected(peer_id: int):
	print("Peer connected: ", peer_id)
	if net and net.mode == NetworkManager.MODE_HOST:
		_spawn_remote_player(peer_id)

func _on_peer_disconnected(peer_id: int):
	print("Peer disconnected: ", peer_id)
	if peer_id in remote_players and is_instance_valid(remote_players[peer_id]):
		remote_players[peer_id].queue_free()
		remote_players.erase(peer_id)

func _on_player_connected(peer_id: int):
	_spawn_remote_player(peer_id)

func _spawn_remote_player(peer_id: int):
	var rp_scene = load("res://scenes/RemotePlayer.tscn")
	if not rp_scene: return
	var rp = rp_scene.instantiate()
	rp.name = "RemotePlayer_" + str(peer_id)
	if player:
		rp.position = player.position + Vector2(randf()*60-30, randf()*60-30)
	remote_players[peer_id] = rp
	$World.add_child(rp)
	print("Spawned remote player for peer ", peer_id)

func _toggle_pause():
	paused = not paused
	get_tree().paused = paused
	if pause_menu:
		pause_menu.visible = paused

func _pause_setup():
	pause_menu = Panel.new()
	pause_menu.name = "PauseMenu"
	pause_menu.visible = false
	pause_menu.anchor_right = 1.0
	pause_menu.anchor_bottom = 1.0
	pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED  # 暂停时仍可交互
	
	# 半透明背景
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.7)
	pause_menu.add_theme_stylebox_override("panel", bg)
	add_child(pause_menu)
	
	# 暂停文字
	var title = Label.new()
	title.name = "PauseTitle"
	title.text = "游 戏 暂 停"
	title.add_theme_color_override("font_color", Color("#00d4ff"))
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_menu.add_child(title)
	
	# 按钮容器
	var vb = VBoxContainer.new()
	vb.name = "PauseVBox"
	vb.position = Vector2(0, 170)
	vb.size = Vector2(200, 250)
	pause_menu.add_child(vb)
	
	var btn_data = [
		{"text": "继 续 游 戏", "cb": _resume_game},
		{"text": "返 回 主 菜 单", "cb": _back_to_menu},
		{"text": "退 出 游 戏", "cb": _quit_game}
	]
	for bd in btn_data:
		var btn = Button.new()
		btn.text = bd.text
		btn.size = Vector2(200, 50)
		btn.custom_minimum_size = Vector2(200, 50)
		var bs = StyleBoxFlat.new()
		bs.bg_color = Color(0, 0.83, 1.0, 0.08)
		bs.border_color = Color(0, 0.83, 1.0, 0.3)
		bs.border_width_left = 1; bs.border_width_right = 1
		bs.border_width_top = 1; bs.border_width_bottom = 1
		bs.corner_radius_top_left = 6; bs.corner_radius_top_right = 6
		bs.corner_radius_bottom_left = 6; bs.corner_radius_bottom_right = 6
		var bh = bs.duplicate()
		bh.bg_color = Color(0, 0.83, 1.0, 0.2)
		bh.border_color = Color(0, 0.83, 1.0, 0.8)
		btn.add_theme_stylebox_override("normal", bs)
		btn.add_theme_stylebox_override("hover", bh)
		btn.add_theme_color_override("font_color", Color("#c8dcff"))
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(bd.cb)
		vb.add_child(btn)
	
	# 居中容器
	await get_tree().process_frame
	var ws = get_window().size
	title.position = Vector2((ws.x - title.size.x) / 2, ws.y * 0.18)
	vb.position = Vector2((ws.x - 200) / 2, ws.y * 0.30)
	get_window().size_changed.connect(_recenter_pause)

func _recenter_pause():
	if not pause_menu: return
	var ws = get_window().size
	var title = pause_menu.get_node_or_null("PauseTitle")
	var vb = pause_menu.get_node_or_null("PauseVBox")
	if title: title.position = Vector2((ws.x - title.size.x) / 2, ws.y * 0.18)
	if vb: vb.position = Vector2((ws.x - 200) / 2, ws.y * 0.30)

func _resume_game():
	_toggle_pause()

func _back_to_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _quit_game():
	get_tree().quit()

func _notif_setup():
	var canvas = CanvasLayer.new()
	canvas.name = "NotifLayer"
	canvas.layer = 100
	add_child(canvas)
	
	notif_label = Label.new()
	notif_label.name = "NotifLabel"
	notif_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notif_label.add_theme_color_override("font_color", Color("#ffd740"))
	notif_label.add_theme_font_size_override("font_size", 20)
	notif_label.visible = false
	notif_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	canvas.add_child(notif_label)
	
	var notif_bg = StyleBoxFlat.new()
	notif_bg.bg_color = Color(0, 0, 0, 0.6)
	notif_bg.corner_radius_top_left = 8; notif_bg.corner_radius_top_right = 8
	notif_bg.corner_radius_bottom_left = 8; notif_bg.corner_radius_bottom_right = 8
	notif_label.add_theme_stylebox_override("normal", notif_bg)
	
	await get_tree().process_frame
	_recenter_notif()
	get_window().size_changed.connect(_recenter_notif)

func _recenter_notif():
	if not notif_label: return
	var ws = get_window().size
	notif_label.size = Vector2(min(500, ws.x - 40), 50)
	notif_label.position = Vector2((ws.x - notif_label.size.x) / 2, 20)

func show_notification(text: String, duration: float = 2.5):
	if not notif_label: return
	notif_label.text = text
	notif_label.visible = true
	notif_label.modulate = Color.WHITE
	# 渐出动画
	var t = create_tween()
	t.tween_property(notif_label, "modulate:a", 1.0, 0.2)
	t.tween_interval(duration)
	t.tween_property(notif_label, "modulate:a", 0.0, 0.5)
	t.tween_callback(func(): notif_label.visible = false)

# ----- 公共接口 -----

func update_day_time(delta):
	game_state.day_time += delta * 0.1
	if game_state.day_time >= 24: game_state.day_time = 0
	game_state.is_day = game_state.day_time >= 6 and game_state.day_time < 18
	# 每过1游戏小时给隐士加1点经验
	var current_hour = int(game_state.day_time)
	if current_hour != _last_day_hour:
		_last_day_hour = current_hour
		if player and player.has_method("add_skill_xp"):
			player.add_skill_xp("hermit", 1)
	if hud and hud.has_method("update_day_time"):
		hud.update_day_time(game_state.day_time)

func _on_player_stats_update(stats):
	game_state.stats = stats
	if hud and hud.has_method("update_player_stats"):
		hud.update_player_stats(stats)
	# 同步技能数据
	if player:
		game_state.skills = player.skills.duplicate(true)

func _on_player_skill_xp_gained(skill_name, amount, level, xp, max_xp):
	# 更新 game_state 技能数据
	if skill_name in game_state.skills:
		game_state.skills[skill_name] = {level=level, xp=xp, max_xp=max_xp}
	# 如果技能面板可见，实时刷新
	if skill_ui and skill_ui.visible and player:
		skill_ui.update_skills(player.skills)
	# HUD 显示技能经验浮动提示
	if hud and hud.has_method("show_skill_xp_notification"):
		hud.show_skill_xp_notification(skill_name, amount)

func _toggle_inventory():
	if inventory_ui:
		inventory_ui.visible = not inventory_ui.visible
		if inventory_ui.visible and player:
			inventory_ui.update_inventory(player.inventory)

func _toggle_skills():
	if skill_ui:
		skill_ui.visible = not skill_ui.visible
		if skill_ui.visible and player:
			skill_ui.update_skills(player.skills)

func _toggle_crafting():
	if not crafting_ui:
		crafting_ui = preload("res://scenes/ui/CraftingUI.tscn").instantiate()
		crafting_ui.item_crafted.connect(_on_item_crafted)
		crafting_ui.crafting_closed.connect(_on_crafting_closed)
		# 加入 CanvasLayer，不跟世界滚动
		$CanvasLayer.add_child(crafting_ui)
	if not crafting_ui.visible and player:
		crafting_ui.open(player.inventory)
	else:
		crafting_ui.visible = false

func _on_crafting_closed():
	crafting_ui.visible = false

func _on_item_crafted(recipe_name: String, quantity: int):
	var recipe = get_node("/root/CraftingSystem").recipes[recipe_name]
	var total = recipe.result_count * quantity
	show_notification("合成成功：%s × %d" % [recipe_name, total])
	# 推进任务进度
	var qm = get_node("/root/QuestManager")
	if qm:
		qm.advance_quest("craft_items", "any", quantity)

func _toggle_quests():
	if not quest_ui:
		quest_ui = preload("res://scenes/ui/QuestUI.tscn").instantiate()
		quest_ui.quest_accepted.connect(_on_quest_accepted)
		quest_ui.quest_ui_closed.connect(_on_quest_ui_closed)
		$CanvasLayer.add_child(quest_ui)
	quest_ui.visible = not quest_ui.visible
	if quest_ui.visible:
		quest_ui.refresh()

func _on_quest_accepted(quest_id: String):
	show_notification("接受任务：%s" % quest_id, 2.0)

func _on_quest_ui_closed():
	quest_ui.visible = false

func _on_quest_completed(quest_id: String):
	var qm = get_node("/root/QuestManager")
	if not qm:
		return
	var rewards = qm.get_quest_rewards(quest_id)
	# 经验奖励
	if rewards.get("xp", 0) > 0 and player:
		player.add_experience(rewards.xp)
	# 物品奖励
	if rewards.get("items", {}) and player:
		for item_name in rewards.items:
			var qty = rewards.items[item_name]
			player.add_item({"name": item_name, "quantity": qty})
	show_notification("任务完成：%s，获得奖励！" % quest_id, 3.0)

func _get_region_name(tile_x: int, tile_y: int) -> String:
	# 从 WorldMap 的区域定义中检测玩家所在区域
	var regions = {
		"灵语森林": {cx=12, cy=12, r=6},
		"浮空秘境": {cx=35, cy=10, r=5},
		"熔岩荒漠": {cx=38, cy=28, r=6},
		"永冻冰川": {cx=10, cy=30, r=6},
		"深渊裂隙": {cx=25, cy=22, r=6},
		"中州平原": {cx=22, cy=12, r=5}
	}
	for region_name in regions:
		var r = regions[region_name]
		if abs(tile_x - r.cx) <= r.r and abs(tile_y - r.cy) <= r.r:
			return region_name
	return ""

# ----- 商店系统 -----

func _toggle_shop():
	if not shop_ui:
		shop_ui = preload("res://scenes/ui/ShopUI.tscn").instantiate()
		shop_ui.shop_closed.connect(_on_shop_closed)
		shop_ui.item_bought.connect(_on_item_bought)
		shop_ui.item_sold.connect(_on_item_sold)
		$CanvasLayer.add_child(shop_ui)
	if not shop_ui.visible and player:
		shop_ui.open(player.inventory, player)
	else:
		shop_ui.visible = false

func _on_shop_closed():
	shop_ui.visible = false

func _on_item_bought(item_name: String, quantity: int, cost: int):
	show_notification("购买 %s ×%d （-%d金币）" % [item_name, quantity, cost])

func _on_item_sold(item_name: String, quantity: int, revenue: int):
	show_notification("出售 %s ×%d （+%d金币）" % [item_name, quantity, revenue])

# ----- 钓鱼系统 -----

func show_fishing_minigame(spot, p):
	if not fishing_ui or fishing_ui.game_active:
		return
	fishing_ui.start(spot, p)

func _on_fishing_result(success, fish_name, fish_xp):
	if success and player:
		player.add_item({"name": fish_name, "quantity": 1})
		player.add_skill_xp("craftsman", fish_xp)
		show_notification("钓到 %s ！获得 %d 工匠经验" % [fish_name, fish_xp], 2.0)
