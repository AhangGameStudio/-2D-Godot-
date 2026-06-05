extends Control

var skills = {
    craftsman = {name = "工匠", desc = "提升建造效率", icon = "hammer"},
    mage = {name = "魔导", desc = "提升魔法威力", icon = "wand"},
    warrior = {name = "勇者", desc = "提升战斗能力", icon = "sword"},
    merchant = {name = "商贾", desc = "降低交易税", icon = "coins"},
    hermit = {name = "隐士", desc = "提升情绪恢复", icon = "leaf"}
}

func _ready():
    $Panel/CloseButton.pressed.connect(_on_close_pressed)

func update_skills(skill_values):
    var skill_list = $Panel/SkillList
    for child in skill_list.get_children():
        child.queue_free()
    
    for skill_name in skills:
        var skill_item = SkillItem.new()
        skill_item.set_skill(skills[skill_name], skill_values[skill_name])
        skill_list.add_child(skill_item)

func _on_close_pressed():
    visible = false

class SkillItem extends Panel:
    var skill_icon = null
    var skill_name = null
    var skill_desc = null
    var skill_bar = null
    
    func _init():
        size = Vector2(300, 64)
        
        skill_icon = TextureRect.new()
        skill_icon.size = Vector2(48, 48)
        skill_icon.position = Vector2(8, 8)
        skill_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
        skill_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        add_child(skill_icon)
        
        skill_name = Label.new()
        skill_name.position = Vector2(64, 8)
        skill_name.size = Vector2(200, 20)
        skill_name.font_size = 16
        add_child(skill_name)
        
        skill_desc = Label.new()
        skill_desc.position = Vector2(64, 32)
        skill_desc.size = Vector2(200, 16)
        skill_desc.font_size = 12
        skill_desc.modulate = Color(0.7, 0.7, 0.7)
        add_child(skill_desc)
        
        skill_bar = ProgressBar.new()
        skill_bar.position = Vector2(64, 48)
        skill_bar.size = Vector2(220, 12)
        skill_bar.max_value = 100
        add_child(skill_bar)
    
    func set_skill(skill_data, value):
        skill_icon.texture = load("res://assets/icons/" + skill_data.icon + ".png")
        skill_name.text = skill_data.name
        skill_desc.text = skill_data.desc
        skill_bar.value = value