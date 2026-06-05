extends Area2D

var fish_pool = [
	{name="鲤鱼", weight=0.5, xp=5},
	{name="鲈鱼", weight=0.3, xp=8},
	{name="鲑鱼", weight=0.15, xp=12},
	{name="金鱼", weight=0.04, xp=20},
	{name="破靴子", weight=0.01, xp=1},
]

var is_fishing = false
var mini_game_active = false

func _ready():
	add_to_group("fishing_spots")
	# 显示一个钓鱼点标记
	var marker = ColorRect.new()
	marker.size = Vector2(32, 32)
	marker.position = Vector2(-16, -16)
	marker.color = Color(0.2, 0.6, 1.0, 0.5)
	add_child(marker)
	# 波浪动画
	var tween = create_tween().set_loops()
	tween.tween_property(marker, "position:y", -20, 1.0).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(marker, "position:y", -16, 1.0).set_ease(Tween.EASE_IN_OUT)
	
	var sh = CircleShape2D.new()
	sh.radius = 20
	var cs = CollisionShape2D.new()
	cs.shape = sh
	add_child(cs)

func start_fishing(player):
	if is_fishing: return
	is_fishing = true
	# 显示钓鱼小游戏
	var main = get_tree().current_scene
	if main and main.has_method("show_fishing_minigame"):
		main.show_fishing_minigame(self, player)
	
func catch_fish():
	var roll = randf()
	var cumulative = 0.0
	for f in fish_pool:
		cumulative += f.weight
		if roll <= cumulative:
			return f
	return fish_pool[0]

func reset():
	is_fishing = false
