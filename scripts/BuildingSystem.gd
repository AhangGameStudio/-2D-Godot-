extends Node2D

var building_types = {
	wall = {name="木墙", cost={"wood":5}, size=Vector2(64,64)},
	floor = {name="木地板", cost={"wood":3}, size=Vector2(64,64)},
	door = {name="门", cost={"wood":4}, size=Vector2(64,64)},
	table = {name="工作台", cost={"wood":10}, size=Vector2(64,64)},
	furnace = {name="熔炉", cost={"stone":15}, size=Vector2(64,64)},
	chest = {name="箱子", cost={"wood":8}, size=Vector2(64,64)}
}
var is_building = false
var current_type = "wall"
var player = null

func _ready():
	player = get_parent().get_node("Player") if get_parent().has_node("Player") else null

func toggle_mode():
	is_building = not is_building

func build_at(pos):
	if not player: return false
	var bt = building_types.get(current_type)
	if not bt: return false
	for item in bt.cost:
		var need = bt.cost[item]
		if not player.has_method("remove_item"): return false
	var b = Area2D.new()
	var rect = ColorRect.new()
	rect.size = bt.size; rect.color = Color(0.6, 0.4, 0.2)
	b.add_child(rect)
	var sh = RectangleShape2D.new(); sh.extents = bt.size / 2
	var c = CollisionShape2D.new(); c.shape = sh
	b.add_child(c)
	b.position = pos
	get_parent().add_child(b)
	return true