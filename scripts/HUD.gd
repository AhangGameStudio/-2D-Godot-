extends Control

signal open_inventory()
signal open_skills()

var health_bar = null
var mana_bar = null
var hunger_bar = null
var thirst_bar = null
var level_label = null
var day_time_label = null

func _ready():
    health_bar = $Panel/HealthBar
    mana_bar = $Panel/StaminaBar
    hunger_bar = $Panel/HungerBar
    thirst_bar = $Panel/ManaBar
    level_label = $Panel/LevelLabel
    day_time_label = $Panel/DayTimeLabel
    
    # 设置颜色
    $Panel/HealthBar.modulate = Color(1.0, 0.22, 0.22)
    $Panel/StaminaBar.modulate = Color(0.45, 0.32, 1.0)
    $Panel/HungerBar.modulate = Color(1.0, 0.82, 0.2)
    $Panel/ManaBar.modulate = Color(0.25, 0.58, 1.0)
    
    $Panel/InventoryButton.pressed.connect(_on_inventory_pressed)
    $Panel/SkillButton.pressed.connect(_on_skills_pressed)

func update_player_stats(stats):
    if health_bar:
        health_bar.value = stats.health
    if mana_bar:
        mana_bar.value = stats.mana
    if hunger_bar:
        hunger_bar.value = stats.hunger
    if thirst_bar:
        thirst_bar.value = stats.thirst

func update_level(level):
    if level_label:
        level_label.text = "Lv.%d" % level

func update_day_time(hours):
    if day_time_label:
        day_time_label.text = "%02d:00" % int(hours)

func _on_inventory_pressed():
    open_inventory.emit()

func _on_skills_pressed():
    open_skills.emit()
