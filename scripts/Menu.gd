extends Control

func _ready():
	$Panel/NewGameButton.pressed.connect(_on_new_game)
	$Panel/LoadGameButton.pressed.connect(_on_load_game)
	$Panel/QuitButton.pressed.connect(_on_quit)

func _on_new_game():
	get_tree().change_scene_to_file("res://scenes/loading.tscn")

func _on_load_game():
	get_tree().change_scene_to_file("res://scenes/loading.tscn")

func _on_quit():
	get_tree().quit()
