extends Node2D

var recipes = {
    wooden_pickaxe = {
        name = "木镐",
        description = "用于采集矿石",
        ingredients = {"wood": 5, "stone": 2},
        result = {"wooden_pickaxe": 1},
        skill_requirement = {"craftsman": 0}
    },
    stone_pickaxe = {
        name = "石镐",
        description = "用于采集高级矿石",
        ingredients = {"wood": 3, "stone": 8},
        result = {"stone_pickaxe": 1},
        skill_requirement = {"craftsman": 5}
    },
    iron_pickaxe = {
        name = "铁镐",
        description = "用于采集稀有矿石",
        ingredients = {"wood": 3, "iron": 5},
        result = {"iron_pickaxe": 1},
        skill_requirement = {"craftsman": 15}
    },
    wooden_sword = {
        name = "木剑",
        description = "基础武器",
        ingredients = {"wood": 6},
        result = {"wooden_sword": 1},
        skill_requirement = {"craftsman": 0}
    },
    stone_sword = {
        name = "石剑",
        description = "锋利的武器",
        ingredients = {"wood": 2, "stone": 5},
        result = {"stone_sword": 1},
        skill_requirement = {"craftsman": 5}
    },
    iron_sword = {
        name = "铁剑",
        description = "强力的武器",
        ingredients = {"wood": 2, "iron": 5},
        result = {"iron_sword": 1},
        skill_requirement = {"craftsman": 15}
    },
    health_potion = {
        name = "生命药水",
        description = "恢复50点生命值",
        ingredients = {"herb": 3, "water": 1},
        result = {"health_potion": 1},
        skill_requirement = {"mage": 0}
    },
    mana_potion = {
        name = "魔力药水",
        description = "恢复30点魔力值",
        ingredients = {"crystal": 2, "water": 1},
        result = {"mana_potion": 1},
        skill_requirement = {"mage": 5}
    },
    cooked_meat = {
        name = "熟肉",
        description = "恢复大量饥饿值",
        ingredients = {"raw_meat": 1},
        result = {"cooked_meat": 1},
        skill_requirement = {"hermit": 0}
    },
    bread = {
        name = "面包",
        description = "恢复中等饥饿值",
        ingredients = {"flour": 3, "water": 1},
        result = {"bread": 1},
        skill_requirement = {"hermit": 3}
    },
    campfire = {
        name = "篝火",
        description = "提供温暖和烹饪",
        ingredients = {"wood": 8, "stone": 4},
        result = {"campfire": 1},
        skill_requirement = {"craftsman": 0}
    },
    bed = {
        name = "床",
        description = "恢复体力和情绪",
        ingredients = {"wood": 10, "cloth": 5},
        result = {"bed": 1},
        skill_requirement = {"craftsman": 8}
    }
}

var player = null

func _ready():
    player = get_parent().get_node("Player")

func can_craft(recipe_name):
    if recipe_name not in recipes:
        return false
    
    var recipe = recipes[recipe_name]
    
    for skill in recipe.skill_requirement:
        if player.skills[skill] < recipe.skill_requirement[skill]:
            return false
    
    for ingredient in recipe.ingredients:
        if not has_item(ingredient, recipe.ingredients[ingredient]):
            return false
    
    return true

func craft(recipe_name):
    if can_craft(recipe_name):
        var recipe = recipes[recipe_name]
        
        for ingredient in recipe.ingredients:
            player.remove_item(ingredient, recipe.ingredients[ingredient])
        
        for result_item in recipe.result:
            player.add_item({"name": result_item, "icon": result_item, "quantity": recipe.result[result_item]})
        
        player.add_experience(15)
        
        for skill in recipe.skill_requirement:
            player.update_skill(skill, 1)
        
        return true
    return false

func has_item(item_name, amount):
    var count = 0
    for item in player.inventory.items:
        if item.name == item_name:
            count += item.quantity
    return count >= amount

func get_all_recipes():
    return recipes

func get_recipe(recipe_name):
    if recipe_name in recipes:
        return recipes[recipe_name]
    return null