extends Node2D

var magic_types = {
	# 原有法术
	fire = {name="火焰", color=Color(1,0.3,0), damage=20, cost=10, category="projectile"},
	ice = {name="冰霜", color=Color(0.3,0.6,1), damage=15, cost=12, category="projectile"},
	lightning = {name="雷电", color=Color(1,1,0), damage=25, cost=15, category="projectile"},
	wind = {name="疾风", color=Color(0.8,0.9,1), damage=10, cost=5, category="projectile"},
	earth = {name="岩石", color=Color(0.6,0.5,0.4), damage=18, cost=12, category="projectile"},
	# 新法术
	fireball = {name="火球", color=Color(1,0.5,0), damage=35, cost=18, category="projectile", aoe_radius=60},
	ice_shard = {name="冰锥", color=Color(0.3,0.5,1), damage=20, cost=14, category="projectile", pierce=true},
	chain_lightning = {name="闪电链", color=Color(1,1,0.2), damage=22, cost=20, category="chain"},
	poison_mist = {name="毒雾", color=Color(0.6,0.1,0.8), damage=5, cost=12, category="area", duration=4.0},
	heal = {name="治疗", color=Color(0.2,1,0.2), damage=-30, cost=15, category="heal"},
	shield = {name="护盾", color=Color(0.2,0.8,1), damage=0, cost=20, category="shield", shield_amount=30}
}

var current = "fire"
var magic_damage_bonus = 1.0  # 魔导被动加成，由Player设置

func _ready():
	add_to_group("magic_system")

func cast(magic_name, caster_pos, target_pos, caster = null):
	if not magic_types.has(magic_name):
		return false
	var m = magic_types[magic_name]

	# 检查并消耗魔力（若提供了caster且有对应方法）
	if caster != null and caster.has_method("has_mana"):
		if not caster.has_mana(m.cost):
			return false
		caster.use_mana(m.cost)

	match m.get("category", "projectile"):
		"projectile":
			cast_projectile(m, caster_pos, target_pos)
		"heal":
			cast_heal(m, caster_pos, caster)
		"chain":
			cast_chain(m, caster_pos, target_pos)
		"area":
			cast_area(m, caster_pos, target_pos)
		"shield":
			cast_shield(m, caster_pos, caster)
		_:
			cast_projectile(m, caster_pos, target_pos)
	return true

# ==================== 投射物类法术 ====================
func cast_projectile(m, caster_pos, target_pos):
	var p = Area2D.new()
	p.add_to_group("magic_projectiles")

	# 视觉
	var rect = ColorRect.new()
	var proj_size = 24
	if m.get("aoe_radius", 0) > 0:
		proj_size = 32  # 火球更大
	rect.size = Vector2(proj_size, proj_size)
	rect.position = Vector2(-proj_size / 2, -proj_size / 2)
	rect.color = m.color
	p.add_child(rect)

	# 碰撞
	var sh = CircleShape2D.new()
	sh.radius = proj_size / 2
	var cs = CollisionShape2D.new()
	cs.shape = sh
	p.add_child(cs)

	p.set_meta("magic_damage", m.damage)
	p.set_meta("magic_name", m.name)
	p.set_meta("pierce", m.get("pierce", false))
	p.set_meta("aoe_radius", m.get("aoe_radius", 0))
	p.set_meta("damage_bonus", magic_damage_bonus)

	# 连接碰撞信号
	p.body_entered.connect(_on_projectile_hit.bind(p))
	p.area_entered.connect(_on_projectile_hit_area.bind(p))

	p.position = caster_pos
	get_parent().add_child(p)

	var dir = (target_pos - caster_pos).normalized()
	var travel_dist = 500.0
	var target = caster_pos + dir * travel_dist

	# 飞行和旋转动画
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(p, "position", target, 0.8)
	tween.tween_property(rect, "rotation", deg_to_rad(360), 0.8)
	tween.set_parallel(false)
	tween.tween_callback(p.queue_free)

func _on_projectile_hit(body, proj):
	if body.is_in_group("monsters"):
		_apply_projectile_damage(proj, body)

func _on_projectile_hit_area(area, proj):
	if area.is_in_group("monsters"):
		_apply_projectile_damage(proj, area)

func _apply_projectile_damage(proj, target):
	if not is_instance_valid(proj) or not is_instance_valid(target):
		return

	var base_damage = proj.get_meta("magic_damage", 10)
	var bonus = proj.get_meta("damage_bonus", 1.0)
	var final_damage = int(base_damage * bonus)
	var pierce = proj.get_meta("pierce", false)
	var aoe_radius = proj.get_meta("aoe_radius", 0)

	if aoe_radius > 0:
		# 范围伤害：伤害半径内的所有怪物
		for body in get_tree().get_nodes_in_group("monsters"):
			if is_instance_valid(body) and body.position.distance_to(proj.position) < aoe_radius:
				_damage_monster(body, final_damage)
	else:
		_damage_monster(target, final_damage)

	# 非穿透则销毁
	if not pierce:
		if is_instance_valid(proj):
			proj.queue_free()

func _damage_monster(monster, damage):
	if not is_instance_valid(monster):
		return
	var hp = monster.get_meta("hp", 0)
	hp -= damage
	monster.set_meta("hp", hp)
	if hp <= 0:
		monster.queue_free()

# ==================== 回复类法术（治疗） ====================
func cast_heal(m, caster_pos, caster):
	# 视觉效果：绿色光环扩散
	var p = Area2D.new()
	var rect = ColorRect.new()
	rect.size = Vector2(48, 48)
	rect.position = Vector2(-24, -24)
	rect.color = m.color
	p.add_child(rect)
	var sh = CircleShape2D.new()
	sh.radius = 24
	var c = CollisionShape2D.new()
	c.shape = sh
	p.add_child(c)
	p.position = caster_pos
	get_parent().add_child(p)

	# 治疗玩家
	if caster != null and caster.has_method("heal"):
		caster.heal(-m.damage)  # damage 为负值=治疗量

	# 扩散动画后消失
	var tween = get_tree().create_tween()
	tween.tween_property(p, "scale", Vector2(3, 3), 0.5)
	tween.tween_property(rect, "modulate", Color(0, 0, 0, 0), 0.3)
	tween.tween_callback(p.queue_free)

# ==================== 连锁类法术（闪电链） ====================
func cast_chain(m, caster_pos, target_pos):
	var chain_count = 3

	# 获取所有怪物并按距离排序
	var monsters = []
	for body in get_tree().get_nodes_in_group("monsters"):
		if is_instance_valid(body):
			monsters.append(body)

	monsters.sort_custom(func(a, b):
		return a.position.distance_to(target_pos) < b.position.distance_to(target_pos))

	var last_pos = target_pos
	for i in range(min(chain_count, monsters.size())):
		var mon = monsters[i]
		if not is_instance_valid(mon):
			continue

		var damage = int(m.damage * magic_damage_bonus)
		_damage_monster(mon, damage)

		# 闪电连线效果
		var line = _create_lightning_line(last_pos, mon.position, m.color)
		get_parent().add_child(line)

		# 击中效果
		var hit_effect = Area2D.new()
		var rect = ColorRect.new()
		rect.size = Vector2(16, 16)
		rect.position = Vector2(-8, -8)
		rect.color = m.color
		hit_effect.add_child(rect)
		hit_effect.position = mon.position
		get_parent().add_child(hit_effect)

		var tween = get_tree().create_tween()
		tween.tween_property(hit_effect, "scale", Vector2(2, 2), 0.3)
		tween.tween_property(rect, "modulate", Color(0, 0, 0, 0), 0.2)
		tween.tween_callback(hit_effect.queue_free)

		last_pos = mon.position

func _create_lightning_line(from, to, color):
	var line = Line2D.new()
	line.points = [from, to]
	line.width = 3
	line.default_color = color
	# 自动消失
	get_tree().create_timer(0.2).timeout.connect(_cleanup_node.bind(line))
	return line

# ==================== 范围类法术（毒雾） ====================
func cast_area(m, caster_pos, target_pos):
	var p = Area2D.new()
	p.add_to_group("magic_areas")

	var rect = ColorRect.new()
	rect.size = Vector2(80, 80)
	rect.position = Vector2(-40, -40)
	rect.color = m.color
	rect.modulate = Color(m.color.r, m.color.g, m.color.b, 0.5)
	p.add_child(rect)

	var sh = CircleShape2D.new()
	sh.radius = 40
	var cs = CollisionShape2D.new()
	cs.shape = sh
	p.add_child(cs)

	p.position = target_pos
	p.set_meta("magic_damage", m.damage)
	p.set_meta("duration", m.get("duration", 4.0))
	p.set_meta("damage_bonus", magic_damage_bonus)
	p.set_meta("elapsed", 0.0)
	get_parent().add_child(p)

	# 持续对范围内怪物造成伤害
	var duration = m.get("duration", 4.0)
	var total_ticks = int(duration / 0.5)  # 每0.5秒一跳

	# 使用一个处理节点来持续造成伤害
	var tick_tween = get_tree().create_tween()
	for j in range(total_ticks):
		tick_tween.tween_interval(0.5)
		tick_tween.tween_callback(func():
			if not is_instance_valid(p):
				return
			var dmg = int(m.damage * magic_damage_bonus)
			for body in get_tree().get_nodes_in_group("monsters"):
				if is_instance_valid(body) and body.position.distance_to(p.position) < 40:
					_damage_monster(body, dmg)
		)

	# 渐变消失
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(rect, "modulate", Color(0, 0, 0, 0), duration)
	fade_tween.tween_callback(p.queue_free)

# ==================== 增益类法术（护盾） ====================
func cast_shield(m, caster_pos, caster):
	if caster != null and caster.has_method("apply_shield"):
		caster.apply_shield(m.get("shield_amount", 30))

	# 视觉：在玩家周围生成光环
	var p = Area2D.new()
	var rect = ColorRect.new()
	rect.size = Vector2(60, 60)
	rect.position = Vector2(-30, -30)
	rect.color = m.color
	rect.modulate = Color(m.color.r, m.color.g, m.color.b, 0.4)
	p.add_child(rect)
	p.position = caster_pos
	get_parent().add_child(p)

	# 脉冲缩放动画
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(p, "scale", Vector2(1.5, 1.5), 0.5)
	tween.tween_property(rect, "modulate", Color(0, 0, 0, 0), 0.5)
	tween.set_parallel(false)
	tween.tween_callback(p.queue_free)

# ==================== 工具函数 ====================
func _cleanup_node(node):
	if is_instance_valid(node):
		node.queue_free()
