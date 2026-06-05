extends CharacterBody2D

var sprite_node = null
var remote_pos = Vector2.ZERO
var remote_dir = Vector2.ZERO
var lerp_speed = 10.0

func _ready():
	sprite_node = $Sprite2D
	remote_pos = position
	# 尝试加载 atmanan 角色贴图（第二行取绿色角色区分本地玩家）
	var tex = load("res://assets/sprites/characters/atmanan/Basic Char Set Blue.png")
	if tex:
		sprite_node.texture = tex
		sprite_node.centered = true
		sprite_node.region_enabled = true
		sprite_node.region_rect = Rect2(0, 0, 128, 128)
		sprite_node.scale = Vector2(1.2, 1.2)
		sprite_node.modulate = Color(0.7, 1.0, 0.7)  # 绿色调区分
	else:
		# fallback 纯色方块
		var cr = ColorRect.new()
		cr.color = Color(0, 0.8, 0.3)
		cr.size = Vector2(32, 32)
		cr.position = Vector2(-16, -16)
		add_child(cr)

func _physics_process(delta):
	position = position.lerp(remote_pos, lerp_speed * delta)
	# 朝向同步
	if remote_dir.length() > 0 and sprite_node and sprite_node.texture:
		var a = remote_dir.angle()
		var facing = 0
		if a > -PI/4 and a <= PI/4:       facing = 1
		elif a > PI/4 and a <= PI*3/4:     facing = 0
		elif a > -PI*3/4 and a <= -PI/4:   facing = 3
		else:                              facing = 2
		sprite_node.region_rect = Rect2(0, facing * 128, 128, 128)
