extends Node2D

var building_types = {
    wood_wall = {name = "木墙", cost = {"wood": 5}, size = Vector2(64, 64), texture = "wood_wall"},
    stone_wall = {name = "石墙", cost = {"stone": 8}, size = Vector2(64, 64), texture = "stone_wall"},
    wooden_floor = {name = "木地板", cost = {"wood": 3}, size = Vector2(64, 64), texture = "wood_floor"},
    stone_floor = {name = "石地板", cost = {"stone": 5}, size = Vector2(64, 64), texture = "stone_floor"},
    roof = {name = "屋顶", cost = {"wood": 6}, size = Vector2(64, 64), texture = "roof"},
    window = {name = "窗户", cost = {"wood": 2, "glass": 1}, size = Vector2(64, 64), texture = "window"},
    door = {name = "门", cost = {"wood": 4}, size = Vector2(64, 64), texture = "door"},
    crafting_table = {name = "工作台", cost = {"wood": 10, "stone": 5}, size = Vector2(64, 64), texture = "crafting_table"},
    furnace = {name = "熔炉", cost = {"stone": 15, "coal": 5}, size = Vector2(64, 64), texture = "furnace"},
    chest = {name = "箱子", cost = {"wood": 8}, size = Vector2(64, 64), texture = "chest", storage = 12}
}

var player = null
var current_building = "wood_wall"
var is_building_mode = false
var buildings = []

func _ready():
    player = get_parent().get_node("Player")

func toggle_building_mode():
    is_building_mode = !is_building_mode
    if is_building_mode:
        current_building = "wood_wall"

func set_building_type(building_type):
    if building_type in building_types:
        current_building = building_type

func can_build(building_type, position):
    var building = building_types[building_type]
    for item in building.cost:
        if not has_item(item, building.cost[item]):
            return false
    
    for existing in buildings:
        if existing.position.distance_to(position) < building.size.x:
            return false
    
    return true

func build(building_type, position):
    if can_build(building_type, position):
        var building = building_types[building_type]
        for item in building.cost:
            player.remove_item(item, building.cost[item])
        
        var building_node = BuildingNode.new()
        building_node.set_building(building, position)
        get_parent().get_node("World").add_child(building_node)
        buildings.append(building_node)
        
        player.add_experience(10)
        player.update_skill("craftsman", 1)
        return true
    return false

func has_item(item_name, amount):
    var count = 0
    for item in player.inventory.items:
        if item.name == item_name:
            count += item.quantity
    return count >= amount

class BuildingNode extends StaticBody2D:
    var building_data = null
    var sprite = null
    
    func _init():
        sprite = Sprite2D.new()
        add_child(sprite)
        
        var shape = RectangleShape2D.new()
        var collider = CollisionShape2D.new()
        collider.shape = shape
        add_child(collider)
    
    func set_building(building, pos):
        building_data = building
        position = pos
        sprite.texture = load("res://assets/textures/buildings/" + building.texture + ".png")
        sprite.size = building.size
        
        var shape = RectangleShape2D.new()
        shape.extents = building.size / 2
        $CollisionShape2D.shape = shape