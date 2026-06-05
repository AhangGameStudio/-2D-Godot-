extends Area2D

# ==================== 怪物类型配置 ====================
const MONSTER_CONFIGS = {
	"野狼":		{health=60, damage=8,  speed=80, exp=30, drops=[{item="肉",   chance=0.6, qty=[1,2]}]},
	"哥布林":	{health=80, damage=12, speed=50, exp=40, drops=[{item="布匹", chance=0.4, qty=[1,1]}, {item="金币", chance=0.3, qty=[1,3]}]},
	"暗影":		{health=120, damage=18, speed=65, exp=60, drops=[{item="水晶", chance=0.3, qty=[1,2]}]},
	"冰霜":		{health=100, damage=15, speed=55, exp=50, drops=[{item="冰晶", chance=0.5, qty=[1,2]}]}
}

# ==================== 状态枚举 ====================
enum State { IDLE, WANDER, CHASE, ATTACK, DIE }

# ==================== 公共属性 ====================
var monster_type: String = ""
var health: int = 100
var max_health: int = 100
var damage: int = 10
var speed: float = 50.0
var exp_reward: int = 30
var drops: Array = []

# ==================== 状态机 ====================
var state: int = State.IDLE
var target = null
var attack_cooldown: float = 0.0
var state_timer: float = 0.0
var wander_dir: Vector2 = Vector2.ZERO

# ==================== 移动 ====================
var velocity: Vector2 = Vector2.ZERO

# ==================== 死亡 ====================
var is_dying: bool = false
var fade_timer: float = 0.0

# ==================== 常量 ====================
const DETECT_RANGE: float = 300.0
const ATTACK_RANGE: float = 35.0
const ATTACK_COOLDOWN_TIME: float = 1.0
const DIE_FADE_DURATION: float = 1.2
const MONSTER_PUSH_RADIUS: float = 28.0
const MONSTER_PUSH_FORCE: float = 2.0

# ==================== 生命周期 ====================

func _ready():
	add_to_group("monsters")
	setup_monster_type()
	if has_node("HealthBar"):
		$HealthBar.max_value = max_health
		$HealthBar.value = health
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	state = State.IDLE
	state_timer = randf_range(2.0, 5.0)

func _physics_process(delta: float):
	# ----- 死亡状态：闪烁渐隐 -----
	if is_dying:
		fade_timer += delta
		modulate.a = 1.0 - (fade_timer / DIE_FADE_DURATION)
		if fade_timer >= DIE_FADE_DURATION:
			queue_free()
		return

	# 攻击冷却
	attack_cooldown = max(attack_cooldown - delta, 0.0)

	# ----- 状态机 -----
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			state_timer -= delta
			if state_timer <= 0.0:
				state = State.WANDER
				wander_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				state_timer = randf_range(1.5, 4.0)

		State.WANDER:
			state_timer -= delta
			if is_instance_valid(target) and _in_detect_range(target):
				state = State.CHASE
			else:
				target = null
				velocity = wander_dir * speed * 0.4
				if state_timer <= 0.0:
					state = State.IDLE
					state_timer = randf_range(2.0, 5.0)

		State.CHASE:
			if not is_instance_valid(target) or not _in_detect_range(target):
				target = null
				state = State.WANDER
				wander_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				state_timer = randf_range(1.5, 4.0)
			else:
				var dir = (target.global_position - global_position).normalized()
				velocity = dir * speed
				if global_position.distance_to(target.global_position) <= ATTACK_RANGE:
					state = State.ATTACK

		State.ATTACK:
			if not is_instance_valid(target):
				target = null
				state = State.IDLE
				state_timer = randf_range(2.0, 5.0)
			else:
				# 攻击
				_do_attack()
				var dist = global_position.distance_to(target.global_position)
				if dist > ATTACK_RANGE:
					state = State.CHASE
				else:
					# 保持追击状态（attacking 但过程与 chase 相同）
					var dir = (target.global_position - global_position).normalized()
					velocity = dir * speed

	# ----- 移动（使用 global_position 而非 position，原因：Area2D 无 move_and_collide）-----
	global_position += velocity * delta

	# ----- 怪物之间避免堆叠 -----
	_avoid_monster_stacking()

	# ----- 精灵朝向 -----
	_update_sprite_direction()

# ==================== 状态辅助 ====================

func _in_detect_range(body) -> bool:
	return global_position.distance_to(body.global_position) <= DETECT_RANGE

func _update_sprite_direction():
	if velocity.length_squared() < 1.0:
		return
	var sprite = get_node_or_null("Sprite2D")
	if not sprite:
		return
	# 根据移动方向翻转精灵
	sprite.scale.x = abs(sprite.scale.x) * (-1.0 if velocity.x < 0 else 1.0)

# ==================== 攻击 ====================

func _do_attack():
	if attack_cooldown > 0.0:
		return
	attack_cooldown = ATTACK_COOLDOWN_TIME

	if not is_instance_valid(target):
		return

	# 造成伤害
	if target.has_method("take_damage"):
		target.take_damage(damage)

	# 击退玩家：给玩家一个反方向速度（force_push）
	if target is CharacterBody2D:
		var push_dir = (target.global_position - global_position).normalized()
		var force = push_dir * 350.0
		if target.has_method("apply_force_push"):
			target.apply_force_push(force)
		else:
			target.velocity = force
			target.move_and_slide()

func attack():
	# 兼容外部调用（如攻击动画事件）
	_do_attack()

# ==================== 受伤 & 死亡 ====================

func take_damage(amount: int):
	if is_dying:
		return
	health -= amount
	if has_node("HealthBar"):
		$HealthBar.value = health
	show_damage_number(amount, Color.YELLOW)
	if health <= 0:
		die()

func die():
	if is_dying:
		return
	is_dying = true
	state = State.DIE

	# 禁用碰撞
	$CollisionShape2D.set_deferred("disabled", true)

	# 经验奖励
	if is_instance_valid(target) and target.has_method("add_experience"):
		target.add_experience(exp_reward)

	# 掉落物品
	for drop in drops:
		if randf() < drop.chance:
			var qty = randi_range(drop.qty[0], drop.qty[1])
			spawn_drop(global_position, drop.item, qty)

	fade_timer = 0.0

# ==================== 掉落物品 ====================

func spawn_drop(pos: Vector2, item_name: String, quantity: int):
	var p = Area2D.new()
	p.position = pos + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	p.add_to_group("pickups")
	p.set_meta("item_name", item_name)
	p.set_meta("quantity", quantity)

	# 拾取物外观（ColorRect）
	var colors = {
		"肉": Color(0.9, 0.3, 0.3),
		"布匹": Color(0.7, 0.7, 0.9),
		"金币": Color(1.0, 0.84, 0.0),
		"水晶": Color(0.5, 0.8, 1.0),
		"冰晶": Color(0.6, 0.9, 1.0)
	}
	var cr = ColorRect.new()
	cr.size = Vector2(14, 14)
	cr.position = Vector2(-7, -7)
	cr.color = colors.get(item_name, Color(0.8, 0.8, 0.8))
	p.add_child(cr)

	# 碰撞形状
	var sh = CircleShape2D.new()
	sh.radius = 10
	var cs = CollisionShape2D.new()
	cs.shape = sh
	p.add_child(cs)

	get_parent().add_child(p)

	# 30 秒后自动消失
	var timer := get_tree().create_timer(30.0)
	timer.timeout.connect(_cleanup_pickup.bind(p))

func _cleanup_pickup(p: Area2D):
	if is_instance_valid(p):
		p.queue_free()

# ==================== 伤害数字 ====================

func show_damage_number(amount: int, color: Color):
	var label = Label.new()
	label.text = str(amount)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# 添加阴影描边效果
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_outline_size", 2)

	add_child(label)
	label.position = Vector2(-20, -45)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", -85, 0.9).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.9).set_ease(Tween.EASE_IN)
	tween.finished.connect(func():
		if is_instance_valid(label):
			label.queue_free()
	)

# ==================== 怪物堆叠避免 ====================

func _avoid_monster_stacking():
	for other in get_tree().get_nodes_in_group("monsters"):
		if other == self:
			continue
		if not is_instance_valid(other):
			continue
		var dist = global_position.distance_to(other.global_position)
		if dist < MONSTER_PUSH_RADIUS and dist > 0.001:
			var push_dir = (global_position - other.global_position).normalized()
			var force = (MONSTER_PUSH_RADIUS - dist) * MONSTER_PUSH_FORCE
			global_position += push_dir * force

# ==================== 类型设置 ====================

func setup_monster_type():
	var cfg = MONSTER_CONFIGS.get(monster_type, MONSTER_CONFIGS["野狼"])
	max_health = cfg.health
	health = max_health
	damage = cfg.damage
	speed = cfg.speed
	exp_reward = cfg.exp
	# 深拷贝掉落配置
	drops = []
	for d in cfg.drops:
		drops.append({"item": d.item, "chance": d.chance, "qty": [d.qty[0], d.qty[1]]})

# ==================== 信号处理 ====================

func _on_body_entered(body):
	if body.is_in_group("player") or body.name == "Player":
		target = body

func _on_body_exited(body):
	if (body.is_in_group("player") or body.name == "Player") and body == target:
		target = null
