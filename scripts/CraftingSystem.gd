extends Node

var recipes = {
	"木板": {icon="res://path", ingredients={"木头": 2}, result_count=4},
	"石砖": {ingredients={"石头": 2}, result_count=4},
	"工具": {ingredients={"木头": 3, "石头": 2}, result_count=1},
	"铁锭": {ingredients={"石头": 5, "木头": 1}, result_count=1},
	"药水": {ingredients={"水晶": 2, "木头": 1}, result_count=1},
	"护甲": {ingredients={"铁锭": 3, "布匹": 2}, result_count=1},
	"武器": {ingredients={"铁锭": 2, "木头": 2}, result_count=1},
}

# 返回最多可制作次数
func can_craft(recipe_name: String, inventory: Dictionary) -> int:
	if not recipes.has(recipe_name):
		return 0
	var recipe = recipes[recipe_name]
	var max_count = 999999
	for ingredient_name in recipe.ingredients:
		var needed = recipe.ingredients[ingredient_name]
		var have = count_item(inventory, ingredient_name)
		var count = int(have / needed)
		max_count = min(max_count, count)
	return max_count

# 执行合成，返回是否成功
func craft(recipe_name: String, inventory: Dictionary, quantity: int = 1) -> bool:
	if not recipes.has(recipe_name):
		return false
	if can_craft(recipe_name, inventory) < quantity:
		return false

	var recipe = recipes[recipe_name]

	# 扣除材料
	for ingredient_name in recipe.ingredients:
		var total_needed = recipe.ingredients[ingredient_name] * quantity
		_remove_items(inventory, ingredient_name, total_needed)

	# 添加产物 - 尝试合并到同名物品
	var result_name = recipe_name
	var result_qty = recipe.result_count * quantity
	var merged = false
	for item in inventory.items:
		if item.name == result_name:
			item.quantity += result_qty
			merged = true
			break
	if not merged:
		inventory.items.append({"name": result_name, "quantity": result_qty})

	return true

# 统计背包中某物品的总数量
func count_item(inventory: Dictionary, item_name: String) -> int:
	var total = 0
	for item in inventory.items:
		if item.name == item_name:
			total += item.quantity
	return total

# 从背包中扣除指定数量的物品（从后往前扣）
func _remove_items(inventory: Dictionary, item_name: String, amount: int):
	var remaining = amount
	for i in range(inventory.items.size() - 1, -1, -1):
		if inventory.items[i].name == item_name:
			var qty = inventory.items[i].quantity
			if qty <= remaining:
				remaining -= qty
				inventory.items.remove_at(i)
			else:
				inventory.items[i].quantity -= remaining
				remaining = 0
				break
			if remaining <= 0:
				break
