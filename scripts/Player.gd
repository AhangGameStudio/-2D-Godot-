extends CharacterBody2D

const SPEED = 250.0
const RUN_SPEED = 400.0
const JOY_RADIUS = 60.0

var camera = null
var touch_dir = Vector2.ZERO
var touch_running = false
var joystick_active = false
var joystick_center = Vector2.ZERO
var joy_knob = null
var touch_layer = null

var stats = {health = 100, stamina = 100, hunger = 100, mana = 50, level = 1, exp = 0}
var inventory = {items = [], max_slots = 20, gold = 50}
var skills = {
	craftsman = {level=1, xp=0, max_xp=100},
	mage = {level=1, xp=0, max_xp=100},
	warrior = {level=1, xp=0, max_xp=100},
	merchant = {level=1, xp=0, max_xp=100},
	hermit = {level=1, xp=0, max_xp=100}
}
var _combat_timer = 0.0
var force_push: Vector2 = Vector2.ZERO
signal update_stats(stats)
signal skill_xp_gained(skill_name, amount, level, xp, max_xp)

# 魔法系统
var magic_system = null
var current_magic_index = 0
var magic_list = ["fire", "ice", "lightning", "wind", "earth", "fireball", "ice_shard", "chain_lightning", "poison_mist", "heal", "shield"]
var _prev_f_pressed = false
var _prev_q_pressed = false

# 护盾
var shield_amount = 0

# 被动技能加成（由 _apply_skill_passives 计算）
var craft_bonus = 0.0       # 工匠：每级+1%额外产出概率
var magic_dmg_bonus = 1.0   # 魔导：每级+2%魔法伤害
var warrior_dmg_bonus = 1.0 # 勇者：每级+1%物理伤害
var max_hp_bonus = 1.0      # 勇者：每级+0.5%生命上限
var shop_discount = 0.0     # 商贾：每级-1%商店税率
var regen_bonus = 1.0       # 隐士：每级+1%生命/魔力自然回复速度

func _ready():
	add_to_group("player")
	# 玩家精灵：使用 atmanan 角色贴图（384×512，64×64 单元格，6列×8行）
	var tex = load("res://assets/sprites/characters/atmanan/Basic Character Set/Basic Char Set Blue.png")
	if tex:
		$Sprite2D.texture = tex
		$Sprite2D.centered = true
		$Sprite2D.region_enabled = true
		$Sprite2D.region_rect = Rect2(0, 0, 128, 128)  # 第一帧站立（384×512 = 3列×4行，每格128×128）
		$Sprite2D.scale = Vector2(1.0, 1.0)
		# 如果纹理是动画图，只显示第一帧区域
		# 此处用region_enabled来裁剪，仅当纹理较大时启用
		# 先用默认全纹理显示，后续可以调整
	else:
		# 回退：蓝色方块
		var cr = ColorRect.new()
		cr.name = "FallbackSprite"
		cr.size = Vector2(32, 40)
		cr.color = Color(0.3, 0.6, 1.0)
		cr.position = Vector2(-16, -20)
		add_child(cr)
	
	var cams = get_tree().get_nodes_in_group("main_camera")
	if cams.size() > 0: camera = cams[0]
	
	# 初始化魔法系统
	_initialize_magic_system()
	
	# 应用初始被动加成
	_apply_skill_passives()
	
	call_deferred("_create_touch_controls")
	get_tree().root.size_changed.connect(_resize_touch_controls)

func _create_touch_controls():
	if touch_layer:
		touch_layer.queue_free()
		touch_layer = null
	
	touch_layer = CanvasLayer.new()
	touch_layer.name = "TouchControls"
	touch_layer.layer = 10
	var vs = get_viewport_rect().size
	if vs.x <= 0: vs = Vector2(1920, 1080)
	
	# 预加载纹理
	var pad_tex = preload("res://assets/mobile-controls/Sprites/Style A/Default/joystick_polygon_pad_a.png")
	var nub_tex = preload("res://assets/mobile-controls/Sprites/Style A/Default/joystick_polygon_nub_a.png")
	var btn_tex = preload("res://assets/mobile-controls/Sprites/Style A/Default/button_circle.png")
	var sword_tex = preload("res://assets/mobile-controls/Sprites/Icons/Default/icon_sword.png")
	var hand_tex = preload("res://assets/mobile-controls/Sprites/Icons/Default/icon_hand.png")
	
	# ====== 摇杆（左下角） ======
	var pad_sz = Vector2(130, 130)
	var pad_pos = Vector2(60, vs.y - 180)
	joystick_center = pad_pos + pad_sz / 2   # 摇杆底座中心（屏幕坐标）
	
	if pad_tex:
		var jbg = TextureRect.new()
		jbg.name = "JoyBg"
		jbg.texture = pad_tex
		jbg.size = pad_sz
		jbg.position = pad_pos
		jbg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		jbg.modulate = Color(1,1,1,0.5)
		jbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		touch_layer.add_child(jbg)
	
	var nub_sz = Vector2(52, 52)
	if nub_tex:
		joy_knob = TextureRect.new()
		joy_knob.name = "JoyKnob"
		joy_knob.texture = nub_tex
		joy_knob.size = nub_sz
		# 手柄精确居中在底座中心
		joy_knob.position = Vector2(
			joystick_center.x - nub_sz.x / 2,
			joystick_center.y - nub_sz.y / 2
		)
		joy_knob.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		joy_knob.modulate = Color(1,1,1,0.7)
		joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
		touch_layer.add_child(joy_knob)
	else:
		# 备选：圆点
		var dot = ColorRect.new()
		dot.name = "JoyKnob"
		dot.size = Vector2(40, 40)
		dot.color = Color(0, 0.83, 1.0, 0.8)
		var ds = StyleBoxFlat.new()
		ds.bg_color = Color(0, 0.83, 1.0, 0.8)
		ds.corner_radius_top_left = 20; ds.corner_radius_top_right = 20
		ds.corner_radius_bottom_left = 20; ds.corner_radius_bottom_right = 20
		dot.add_theme_stylebox_override("panel", ds)
		dot.position = Vector2(
			joystick_center.x - 20,
			joystick_center.y - 20
		)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		touch_layer.add_child(dot)
		joy_knob = dot
	
	# ====== 操作按钮（右下角） ======
	if btn_tex:
		# 攻击按钮（大）
		var atk = TextureButton.new()
		atk.name = "AttackBtn"
		atk.texture_normal = btn_tex
		atk.position = Vector2(vs.x - 160, vs.y - 190)
		atk.size = Vector2(90, 90)
		atk.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		atk.modulate = Color(1, 0.3, 0.3, 0.7)
		atk.pressed.connect(attack)
		touch_layer.add_child(atk)
		if sword_tex:
			var si = TextureRect.new()
			si.texture = sword_tex
			si.size = Vector2(44, 44)
			si.position = atk.position + Vector2(23, 23)
			si.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			si.mouse_filter = Control.MOUSE_FILTER_IGNORE
			touch_layer.add_child(si)
		
		# 交互按钮（小，在攻击按钮左下方）
		var inte = TextureButton.new()
		inte.name = "InteractBtn"
		inte.texture_normal = btn_tex
		inte.position = Vector2(vs.x - 270, vs.y - 130)
		inte.size = Vector2(80, 80)
		inte.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		inte.modulate = Color(0.3, 0.6, 1.0, 0.7)
		inte.pressed.connect(interact)
		touch_layer.add_child(inte)
		if hand_tex:
			var hi = TextureRect.new()
			hi.texture = hand_tex
			hi.size = Vector2(40, 40)
			hi.position = inte.position + Vector2(20, 20)
			hi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hi.mouse_filter = Control.MOUSE_FILTER_IGNORE
			touch_layer.add_child(hi)
	
	get_tree().current_scene.add_child(touch_layer)

func _resize_touch_controls():
	_create_touch_controls()

func _input(event):
	if not joy_knob:
		return
	
	# 处理触摸和鼠标事件（桌面测试兼容）
	var is_touch_or_click = event is InputEventScreenTouch or event is InputEventMouseButton
	var is_drag = event is InputEventScreenDrag or (event is InputEventMouseMotion and joystick_active)
	
	if is_touch_or_click:
		var pos = event.position if event is InputEventScreenTouch else Vector2(event.position.x, event.position.y)
		if event.pressed:
			var dist = pos.distance_to(joystick_center)
			if dist < 200:
				joystick_active = true
		else:
			joystick_active = false
			touch_dir = Vector2.ZERO
			reset_knob_position()
	
	if is_drag:
		var pos = event.position if event is InputEventScreenDrag else Vector2(event.position.x, event.position.y)
		var delta = pos - joystick_center
		var dist = delta.length()
		if dist > JOY_RADIUS:
			delta = delta.normalized() * JOY_RADIUS
		touch_dir = delta.normalized() if dist > 15 else Vector2.ZERO
		touch_running = dist > JOY_RADIUS * 0.65
		var ks = joy_knob.size
		joy_knob.position = Vector2(
			joystick_center.x - ks.x / 2 + delta.x,
			joystick_center.y - ks.y / 2 + delta.y
		)

func reset_knob_position():
	if joy_knob:
		var ks = joy_knob.size
		joy_knob.position = Vector2(
			joystick_center.x - ks.x / 2,
			joystick_center.y - ks.y / 2
		)

# ==================== 魔法系统接口 ====================

func _initialize_magic_system():
	magic_system = get_parent().get_node_or_null("MagicSystem")
	if not magic_system:
		var MagicSystemScript = preload("res://scripts/MagicSystem.gd")
		magic_system = MagicSystemScript.new()
		get_parent().add_child.call_deferred(magic_system)
	# 同步魔导加成
	if magic_system:
		magic_system.magic_damage_bonus = magic_dmg_bonus

func _cycle_magic():
	current_magic_index = (current_magic_index + 1) % magic_list.size()
	var new_magic = magic_list[current_magic_index]
	if magic_system:
		magic_system.current = new_magic
	# 通知UI
	var main = get_tree().current_scene
	if main and main.has_method("show_notification"):
		var m = magic_system.magic_types[new_magic] if magic_system else null
		var display_name = m.name if m else new_magic
		main.show_notification("切换法术: %s" % display_name, 1.5)

func _cast_current_magic():
	if not magic_system:
		return
	var magic_name = magic_list[current_magic_index]
	if not magic_system.magic_types.has(magic_name):
		return
	var m = magic_system.magic_types[magic_name]
	# 检查魔力
	if not has_mana(m.cost):
		var main = get_tree().current_scene
		if main and main.has_method("show_notification"):
			main.show_notification("魔力不足！", 1.5)
		return
	var mouse_pos = get_global_mouse_position()
	var result = magic_system.cast(magic_name, position, mouse_pos, self)
	if result:
		# 使用法术可获得魔导经验
		add_skill_xp("mage", 2)

func has_mana(amount):
	return stats.mana >= amount

func use_mana(amount):
	stats.mana = max(stats.mana - amount, 0)
	emit_signal("update_stats", stats)

func heal(amount):
	stats.health = min(stats.health + amount, get_max_health())
	emit_signal("update_stats", stats)

func apply_shield(amount):
	shield_amount += amount

func get_max_health() -> int:
	var base = 100
	# 勇者被动：每级+0.5%生命上限
	var bonus = 1.0 + (skills.warrior.level - 1) * 0.005
	return int(base * bonus)

# ==================== 被动技能效果系统 ====================

func _apply_skill_passives():
	# 工匠：每级+1%合成额外产出概率（上限50级=+50%）
	craft_bonus = (skills.craftsman.level - 1) * 0.01
	
	# 魔导：每级+2%魔法伤害（基础100%，每级+2%）
	magic_dmg_bonus = 1.0 + (skills.mage.level - 1) * 0.02
	
	# 勇者：每级+1%物理伤害和+0.5%生命上限
	warrior_dmg_bonus = 1.0 + (skills.warrior.level - 1) * 0.01
	max_hp_bonus = 1.0 + (skills.warrior.level - 1) * 0.005
	
	# 商贾：每级-1%商店税率（上限50%）
	shop_discount = min((skills.merchant.level - 1) * 0.01, 0.50)
	
	# 隐士：每级+1%生命/魔力自然回复速度
	regen_bonus = 1.0 + (skills.hermit.level - 1) * 0.01
	
	# 同步到魔法系统
	if magic_system:
		magic_system.magic_damage_bonus = magic_dmg_bonus

func _apply_passive_regen(delta):
	# 隐士被动：每级+1%基础回复速度（基础每5秒回复1点）
	var base_regen_rate = 0.2  # 每秒回复0.2点
	var regen_amount = base_regen_rate * regen_bonus * delta
	var updated = false
	if stats.health < get_max_health():
		stats.health = min(stats.health + regen_amount, get_max_health())
		updated = true
	if stats.mana < 50:
		stats.mana = min(stats.mana + regen_amount, 50)
		updated = true
	if updated:
		emit_signal("update_stats", stats)

func _physics_process(delta):
	var dir = Vector2.ZERO
	# 键盘：WASD + 方向键
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"): dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"): dir.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"): dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"): dir.y += 1
	# 摇杆/触摸方向（优先级高于键盘）
	if touch_dir.length() > 0:
		dir = touch_dir
	
	if dir.length() > 0:
		dir = dir.normalized()
		var running = Input.is_key_pressed(KEY_SHIFT) or touch_running
		velocity = dir * (RUN_SPEED if running else SPEED)
		# 4方向人物朝向（atmanan 行：0=下, 1=左, 2=右, 3=上）
		var facing = 0
		var a = dir.angle()
		if a > -PI/4 and a <= PI/4:     facing = 1  # 右 → 行1
		elif a > PI/4 and a <= PI*3/4:   facing = 0  # 下 → 行0
		elif a > -PI*3/4 and a <= -PI/4: facing = 3  # 上 → 行3
		else:                            facing = 2  # 左 → 行2
		$Sprite2D.region_rect = Rect2(0, facing * 128, 128, 128)
		$Sprite2D.rotation = 0
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	
	# 应用击退
	if force_push.length_squared() > 0:
		velocity = force_push
		move_and_slide()
		force_push = Vector2.ZERO
	
	# 攻击：空格键
	if Input.is_key_pressed(KEY_SPACE) or Input.is_action_just_pressed("ui_accept"):
		attack()
	
	# 交互：E键
	if Input.is_key_pressed(KEY_E):
		interact()
	
	# 魔法快捷键
	var f_pressed = Input.is_key_pressed(KEY_F)
	if f_pressed and not _prev_f_pressed:
		_cast_current_magic()
	_prev_f_pressed = f_pressed
	
	var q_pressed = Input.is_key_pressed(KEY_Q)
	if q_pressed and not _prev_q_pressed:
		_cycle_magic()
	_prev_q_pressed = q_pressed
	
	# 被动回复（每秒）
	_apply_passive_regen(delta)
	
	# 怪物近战伤害（每秒一次）
	_combat_timer += delta
	if _combat_timer >= 1.0:
		_combat_timer = 0
		for body in get_tree().get_nodes_in_group("monsters"):
			if position.distance_to(body.position) < 50:
				take_damage(8 + body.get_meta("monster_level", 1))
				break

func attack():
	var dmg = 20 + stats.level * 2
	var hit = false
	# 每次攻击消耗少量魔力，获得魔导经验
	if stats.mana > 0:
		stats.mana = max(stats.mana - 1, 0)
		add_skill_xp("mage", 1)
	# 攻击怪物
	for body in get_tree().get_nodes_in_group("monsters"):
		if position.distance_to(body.position) < 80:
			var hp = body.get_meta("hp", 0)
			hp -= dmg
			body.set_meta("hp", hp)
			hit = true
			add_skill_xp("warrior", 3 + randi() % 3)
			if hp <= 0:
				var monster_type = body.get_meta("monster_type", "")
				body.queue_free()
				add_skill_xp("warrior", 10)
				# 推进怪物击杀任务
				if monster_type != "":
					var qm = get_node("/root/QuestManager")
					if qm:
						qm.advance_quest("kill_monster", monster_type, 1)
	# 攻击树木（wood 资源）
	for res in get_tree().get_nodes_in_group("resources"):
		if position.distance_to(res.position) < 80 and res.get_meta("res_name") == "wood":
			var hp = res.get_meta("hp", 0)
			var max_hp = res.get_meta("max_hp", 50)
			hp -= dmg
			res.set_meta("hp", hp)
			hit = true
			add_skill_xp("craftsman", 2 + randi() % 2)
			# 更新裂纹覆盖层
			var crack = res.get_node_or_null("CrackOverlay")
			if crack:
				var ratio = 1.0 - float(hp) / float(max_hp)
				crack.color = Color(0.2, 0.1, 0.05, min(ratio * 0.85, 0.85))
			# 树碎掉
			if hp <= 0:
				var tree_pos = res.position
				res.queue_free()
				add_item({"name": "木头", "quantity": 2 + randi() % 3})
				spawn_wood_pickup(tree_pos)
				add_skill_xp("craftsman", 5)
			break  # 一次只砍一棵
	return hit

func interact():
	# 商店NPC交互
	for npc in get_tree().get_nodes_in_group("shop_npcs"):
		if position.distance_to(npc.position) < 80:
			var main = get_tree().current_scene
			if main and main.has_method("_toggle_shop"):
				main._toggle_shop()
			return
	# 钓鱼点交互
	for spot in get_tree().get_nodes_in_group("fishing_spots"):
		if position.distance_to(spot.position) < 60:
			if spot.has_method("start_fishing"):
				spot.start_fishing(self)
			return
	# 捡拾掉落物（支持动态物品类型）
	for p in get_tree().get_nodes_in_group("pickups"):
		if position.distance_to(p.position) < 50:
			var item_name = p.get_meta("item_name", "木头")
			var quantity = p.get_meta("quantity", 1)
			add_item({"name": item_name, "quantity": quantity})
			add_skill_xp("merchant", 2)
			p.queue_free()
			return
	# 采集资源
	for res in get_tree().get_nodes_in_group("resources"):
		if position.distance_to(res.position) < 60:
			# 树（wood）用攻击砍伐，E键不直接采集
			if res.get_meta("res_name") == "wood": continue
			res.queue_free()
			add_item({"name": "资源", "quantity": 1})
			add_skill_xp("craftsman", 3)
			return

func take_damage(amount):
	# 护盾吸收伤害
	if shield_amount > 0:
		var absorbed = min(shield_amount, amount)
		shield_amount -= absorbed
		amount -= absorbed
		if shield_amount <= 0:
			shield_amount = 0
	if amount > 0:
		stats.health -= amount
	emit_signal("update_stats", stats)
	if stats.health <= 0: die()

func die():
	stats.health = 100; stats.stamina = 100; stats.hunger = 100; stats.mana = 50
	position = Vector2(0, 0)
	emit_signal("update_stats", stats)

func spawn_wood_pickup(pos):
	# 掉落一个木头图标在地上，30秒自动消失
	var p = Area2D.new()
	p.position = pos + Vector2(randf()*20-10, randf()*20-10)
	p.add_to_group("pickups")
	var cr = ColorRect.new()
	cr.color = Color(0.55, 0.35, 0.15)
	cr.size = Vector2(14, 14)
	cr.position = Vector2(-7, -7)
	p.add_child(cr)
	var sh = CircleShape2D.new(); sh.radius = 10
	var cs = CollisionShape2D.new(); cs.shape = sh
	p.add_child(cs)
	get_parent().add_child(p)
	# 30秒后自动消失
	get_tree().create_timer(30.0).timeout.connect(_cleanup_node.bind(p))

func _cleanup_node(node):
	if is_instance_valid(node):
		node.queue_free()

func add_item(item):
	var item_name = item.get("name", "")
	var quantity = item.get("quantity", 1)
	for i in range(inventory.items.size()):
		if inventory.items[i].get("name", "") == item_name:
			inventory.items[i].quantity = inventory.items[i].get("quantity", 0) + quantity
			# 推进收集任务
			var qm = get_node("/root/QuestManager")
			if qm:
				qm.advance_quest("collect_item", item_name, quantity)
			return true
	# 没有同名物品，在空格子中新增
	if inventory.items.size() < inventory.max_slots:
		inventory.items.append({"name": item_name, "quantity": quantity})
		# 推进收集任务
		var qm = get_node("/root/QuestManager")
		if qm:
			qm.advance_quest("collect_item", item_name, quantity)
		return true
	return false

func remove_item(item_name, amount):
	for i in range(inventory.items.size() - 1, -1, -1):
		if inventory.items[i].name == item_name:
			inventory.items[i].quantity -= amount
			if inventory.items[i].quantity <= 0: inventory.items.remove_at(i)
			return true
	return false

func add_experience(amount):
	stats.exp += amount
	var needed = stats.level * 100
	if stats.exp >= needed:
		stats.level += 1; stats.exp -= needed
	stats.health = min(stats.health + 10, 100)
	emit_signal("update_stats", stats)

func add_skill_xp(skill_name, amount):
	if not skill_name in skills:
		return
	var sk = skills[skill_name]
	if sk.level >= 50:
		return
	sk.xp += amount
	while sk.xp >= sk.max_xp and sk.level < 50:
		sk.xp -= sk.max_xp
		sk.level += 1
		sk.max_xp = ceil(sk.max_xp * 1.5)
		_on_skill_level_up(skill_name, sk.level)
		# 升级时重新计算被动加成
		_apply_skill_passives()
	emit_signal("skill_xp_gained", skill_name, amount, sk.level, sk.xp, sk.max_xp)
	emit_signal("update_stats", stats)

func _on_skill_level_up(skill_name, new_level):
	var names = {craftsman="工匠", mage="魔导", warrior="勇者", merchant="商贾", hermit="隐士"}
	var display_name = names.get(skill_name, skill_name)
	# 通知主游戏显示升级消息
	var main = get_tree().current_scene
	if main and main.has_method("show_notification"):
		main.show_notification("%s 提升至 Lv.%d！" % [display_name, new_level], 3.0)

func update_skill(sname, amount):
	if sname in skills:
		add_skill_xp(sname, amount)

# (force_push 声明在顶部已有)
