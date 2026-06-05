extends Node2D

var hud = null
var inventory = null
var skill_panel = null
var crafting_panel = null
var build_panel = null

var panels = []

func _ready():
    hud = $HUD
    inventory = $Inventory
    skill_panel = $SkillPanel
    crafting_panel = $CraftingPanel
    build_panel = $BuildPanel
    
    panels = [inventory, skill_panel, crafting_panel, build_panel]
    
    hud.open_inventory.connect(_on_open_inventory)
    hud.open_skills.connect(_on_open_skills)

func _on_open_inventory():
    toggle_panel(inventory)

func _on_open_skills():
    toggle_panel(skill_panel)

func toggle_panel(panel):
    panel.visible = not panel.visible
    
    if panel.visible:
        for other in panels:
            if other != panel:
                other.visible = false
        get_tree().paused = true
    else:
        get_tree().paused = false

func _input(event):
    if event is InputEventKey and event.pressed:
        if event.scancode == KEY_ESCAPE:
            for panel in panels:
                if panel.visible:
                    panel.visible = false
                    get_tree().paused = false
                    return

func update_player_stats(stats):
    hud.update_player_stats(stats)

func update_inventory(inventory_data):
    inventory.update_inventory(inventory_data)

func update_skills(skills):
    skill_panel.update_skills(skills)