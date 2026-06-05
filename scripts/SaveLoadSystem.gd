extends Node2D

var save_path = "user://save.dat"

func save_game(player_data, world_data):
	var data = {player=player_data, world=world_data, time=Time.get_unix_time_from_system()}
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close(); return true
	return false

func load_game():
	if not FileAccess.file_exists(save_path): return null
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var text = file.get_as_text(); file.close()
		var json = JSON.new()
		var err = json.parse(text)
		return json.data if err == OK else null
	return null

func delete_save():
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
		return true
	return false