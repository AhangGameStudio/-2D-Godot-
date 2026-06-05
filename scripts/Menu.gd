extends Control

func _ready():
	$Panel/NewGameButton.pressed.connect(_on_new_game)
	$Panel/LoadGameButton.pressed.connect(_on_load_game)
	$Panel/QuitButton.pressed.connect(_on_quit)
	
	var bg = $Background
	if bg and bg.texture:
		var ws = get_viewport_rect().size
		var tex = bg.texture
		var scale = max(ws.x / tex.get_width(), ws.y / tex.get_height())
		bg.scale = Vector2(scale, scale)
		bg.position = ws / 2

func _on_new_game():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_load_game():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit():
	get_tree().quit()
