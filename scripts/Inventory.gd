extends Control

var inventory_grid = null
var close_button = null

func _ready():
    inventory_grid = $Panel/InventoryGrid
    close_button = $Panel/CloseButton
    close_button.pressed.connect(_on_close_pressed)

func update_inventory(inventory):
    clear_grid()
    for item in inventory.items:
        var item_slot = ItemSlot.new()
        item_slot.set_item(item)
        inventory_grid.add_child(item_slot)
    
    var empty_slots = inventory.max_slots - len(inventory.items)
    for i in range(empty_slots):
        var empty_slot = ItemSlot.new()
        inventory_grid.add_child(empty_slot)

func clear_grid():
    for child in inventory_grid.get_children():
        child.queue_free()

func _on_close_pressed():
    visible = false

class ItemSlot extends Panel:
    var item = null
    var icon = null
    var label = null
    
    func _init():
        size = Vector2(64, 64)
        icon = TextureRect.new()
        icon.size = Vector2(48, 48)
        icon.position = Vector2(8, 8)
        icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        add_child(icon)
        label = Label.new()
        label.position = Vector2(52, 52)
        label.size = Vector2(12, 12)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        add_child(label)
    
    func set_item(item_data):
        item = item_data
        if item:
            icon.texture = load("res://assets/icons/" + item.icon + ".png")
            if item.quantity > 1:
                label.text = str(item.quantity)
            else:
                label.text = ""