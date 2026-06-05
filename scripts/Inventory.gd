extends Control

var inventory_grid = null
var close_button = null
var item_count_label = null
var player = null
var current_inventory = null

func _ready():
	inventory_grid = $Panel/InventoryGrid
	close_button = $Panel/CloseButton
	item_count_label = $Panel/ItemCount
	close_button.pressed.connect(_on_close_pressed)

func update_inventory(inventory):
	current_inventory = inventory
	clear_grid()
	for item in inventory.items:
		var item_slot = ItemSlot.new()
		item_slot.set_item(item, self)
		inventory_grid.add_child(item_slot)
	
	var empty_slots = inventory.max_slots - len(inventory.items)
	for i in range(empty_slots):
		var empty_slot = ItemSlot.new()
		inventory_grid.add_child(empty_slot)
	
	if item_count_label:
		item_count_label.text = "物品数量: %d/%d" % [len(inventory.items), inventory.max_slots]

func clear_grid():
	for child in inventory_grid.get_children():
		child.queue_free()

func _on_close_pressed():
	visible = false

func set_player(player_node):
	player = player_node

func use_inventory_item(item_data):
	if not player or not item_data:
		return
	if player.has_method("use_item") and player.use_item(item_data.name):
		update_inventory(player.inventory)

class ItemSlot extends Panel:
	const SLOT_SIZE = Vector2(64, 64)

	var item = null
	var icon = null
	var label = null
	var owner_inventory = null
	
	func _init():
		custom_minimum_size = SLOT_SIZE
		size = SLOT_SIZE
		mouse_filter = Control.MOUSE_FILTER_STOP
		add_theme_stylebox_override("panel", _make_slot_style(false))
		
		icon = TextureRect.new()
		icon.position = Vector2(9, 7)
		icon.size = Vector2(46, 46)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(icon)
		
		label = Label.new()
		label.position = Vector2(33, 43)
		label.size = Vector2(27, 17)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		add_child(label)
	
	func set_item(item_data, inventory_owner = null):
		item = item_data
		owner_inventory = inventory_owner
		if item:
			add_theme_stylebox_override("panel", _make_slot_style(true))
			icon.texture = load("res://assets/icons/" + item.icon + ".png")
			tooltip_text = item.name
			if item.quantity > 1:
				label.text = str(item.quantity)
			else:
				label.text = ""

	func _gui_input(event):
		if item and owner_inventory and event is InputEventMouseButton:
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				owner_inventory.use_inventory_item(item)

	func _make_slot_style(has_item):
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.12, 0.08, 0.82) if has_item else Color(0.04, 0.08, 0.05, 0.72)
		style.border_color = Color(0.48, 0.66, 0.46, 0.95) if has_item else Color(0.23, 0.36, 0.22, 0.9)
		style.set_border_width_all(2)
		style.set_corner_radius_all(3)
		return style
