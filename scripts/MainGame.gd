extends Node2D

var player = null
var hud = null
var inventory_panel = null
var skill_panel = null
var camera = null

var game_state = {
	day_time = 0,
	is_day = true,
	weather = "sunny",
	player_stats = {
		health = 100, stamina = 100, hunger = 100,
		mana = 50, level = 1, experience = 0
	},
	skills = {craftsman = 0, mage = 0, warrior = 0, merchant = 0, hermit = 0}
}

func _ready():
	player = $World/Player if has_node("World/Player") else null
	hud = $UI/HUD if has_node("UI/HUD") else null
	inventory_panel = $UI/Inventory if has_node("UI/Inventory") else null
	skill_panel = $UI/SkillPanel if has_node("UI/SkillPanel") else null
	camera = $Camera2D if has_node("Camera2D") else null
	
	if hud and hud.has_signal("open_inventory"):
		hud.open_inventory.connect(_on_open_inventory)
	if hud and hud.has_signal("open_skills"):
		hud.open_skills.connect(_on_open_skills)
	if player and player.has_signal("update_stats"):
		player.update_stats.connect(_on_player_stats_update)

func _process(delta):
	update_day_time(delta)
	if player and camera:
		camera.position = camera.position.lerp(player.position, 0.1)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if inventory_panel and inventory_panel.visible:
			inventory_panel.visible = false
			return
		if skill_panel and skill_panel.visible:
			skill_panel.visible = false
			return
		get_tree().change_scene_to_file("res://scenes/menu.tscn")

func update_day_time(delta):
	game_state.day_time += delta * 0.1
	if game_state.day_time >= 24:
		game_state.day_time = 0
	game_state.is_day = game_state.day_time >= 6 and game_state.day_time < 18
	
	if hud and hud.has_method("update_day_time"):
		hud.update_day_time(game_state.day_time)

func _on_player_stats_update(stats):
	game_state.player_stats = stats
	if hud and hud.has_method("update_player_stats"):
		hud.update_player_stats(stats)

func _on_open_inventory():
	if inventory_panel:
		inventory_panel.visible = not inventory_panel.visible
		if inventory_panel.visible and player:
			pass

func _on_open_skills():
	if skill_panel:
		skill_panel.visible = not skill_panel.visible
		if skill_panel.visible:
			pass

func add_experience(amount):
	game_state.player_stats.experience += amount
	var needed = game_state.player_stats.level * 100
	if game_state.player_stats.experience >= needed:
		game_state.player_stats.level += 1
		game_state.player_stats.experience -= needed
		if hud and hud.has_method("update_level"):
			hud.update_level(game_state.player_stats.level)

func update_skill(skill_name, amount):
	if skill_name in game_state.skills:
		game_state.skills[skill_name] += amount
