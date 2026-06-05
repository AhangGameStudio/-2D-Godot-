extends Node2D

var save_path = "user://save_game.dat"

func save_game(player_data, world_data):
    var save_data = {
        "player": player_data,
        "world": world_data,
        "timestamp": Time.get_unix_time_from_system()
    }
    
    var file = FileAccess.open(save_path, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(save_data))
        file.close()
        return true
    return false

func load_game():
    if FileAccess.file_exists(save_path):
        var file = FileAccess.open(save_path, FileAccess.READ)
        if file:
            var content = file.get_as_text()
            file.close()
            
            var json = JSON.new()
            var result = json.parse(content)
            if result == OK:
                return json.data
    return null

func delete_save():
    if FileAccess.file_exists(save_path):
        var dir = DirAccess.open("user://")
        if dir:
            dir.remove("save_game.dat")
            return true
    return false

func get_save_info():
    if FileAccess.file_exists(save_path):
        var file = FileAccess.open(save_path, FileAccess.READ)
        if file:
            var content = file.get_as_text()
            file.close()
            
            var json = JSON.new()
            var result = json.parse(content)
            if result == OK:
                return {
                    "exists": true,
                    "timestamp": json.data.timestamp,
                    "level": json.data.player.level
                }
    return {"exists": false}

func export_save(filepath):
    if FileAccess.file_exists(save_path):
        var file = FileAccess.open(save_path, FileAccess.READ)
        if file:
            var content = file.get_as_text()
            file.close()
            
            var export_file = FileAccess.open(filepath, FileAccess.WRITE)
            if export_file:
                export_file.store_string(content)
                export_file.close()
                return true
    return false

func import_save(filepath):
    if FileAccess.file_exists(filepath):
        var file = FileAccess.open(filepath, FileAccess.READ)
        if file:
            var content = file.get_as_text()
            file.close()
            
            var save_file = FileAccess.open(save_path, FileAccess.WRITE)
            if save_file:
                save_file.store_string(content)
                save_file.close()
                return true
    return false