extends Control

signal open_inventory()
signal open_skills()

var health_bar = null
var stamina_bar = null
var hunger_bar = null
var mana_bar = null
var level_label = null
var day_time_label = null

func _ready():
    health_bar = $Panel/HealthBar
    stamina_bar = $Panel/StaminaBar
    hunger_bar = $Panel/HungerBar
    mana_bar = $Panel/ManaBar
    level_label = $Panel/LevelLabel
    day_time_label = $Panel/DayTimeLabel
    
    # 设置颜色
    $Panel/HealthBar.modulate = Color(1, 0.3, 0.3)
    $Panel/StaminaBar.modulate = Color(0.3, 0.6, 1)
    $Panel/HungerBar.modulate = Color(0.6, 1, 0.3)
    $Panel/ManaBar.modulate = Color(0.8, 0.3, 1)
    
    $Panel/InventoryButton.pressed.connect(_on_inventory_pressed)
    $Panel/SkillButton.pressed.connect(_on_skills_pressed)

func update_player_stats(stats):
    if health_bar:
        health_bar.value = stats.health
    if stamina_bar:
        stamina_bar.value = stats.stamina
    if hunger_bar:
        hunger_bar.value = stats.hunger
    if mana_bar:
        mana_bar.value = stats.mana

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