extends Node

# 任务数据结构
var quests = {
	"狩猎野狼": {
		name="狩猎野狼", desc="消灭5只野狼",
		objective="kill_monster", target="野狼", required=5, progress=0,
		rewards={xp=100, items={"肉": 3}},
		completed=false, active=false
	},
	"收集水晶": {
		name="收集水晶", desc="收集3个水晶",
		objective="collect_item", target="水晶", required=3, progress=0,
		rewards={xp=150, items={"药水": 2}},
		completed=false, active=false
	},
	"探索深渊": {
		name="探索深渊", desc="前往深渊裂隙区域",
		objective="explore_region", target="深渊裂隙", required=1, progress=0,
		rewards={xp=200, items={"武器": 1}},
		completed=false, active=false
	},
	"工匠大师": {
		name="工匠大师", desc="合成5个物品",
		objective="craft_items", target="any", required=5, progress=0,
		rewards={xp=120, items={"工具": 1}},
		completed=false, active=false
	},
	"消灭哥布林": {
		name="消灭哥布林", desc="消灭10只哥布林",
		objective="kill_monster", target="哥布林", required=10, progress=0,
		rewards={xp=250, items={"铁锭": 3}},
		completed=false, active=false
	},
}

signal quest_updated(quest_id)
signal quest_completed(quest_id)
signal quest_progress(quest_id, progress, required)

func _ready():
	pass

func accept_quest(quest_id: String) -> bool:
	if not quests.has(quest_id): return false
	var q = quests[quest_id]
	if q.active or q.completed: return false
	q.active = true
	q.progress = 0
	emit_signal("quest_updated", quest_id)
	return true

func advance_quest(objective: String, target: String, amount: int = 1):
	for qid in quests:
		var q = quests[qid]
		if not q.active or q.completed: continue
		if q.objective != objective: continue
		if q.target != "any" and q.target != target: continue
		q.progress = min(q.progress + amount, q.required)
		emit_signal("quest_progress", qid, q.progress, q.required)
		if q.progress >= q.required:
			q.completed = true
			q.active = false
			emit_signal("quest_completed", qid)

func get_quest_rewards(quest_id: String) -> Dictionary:
	if quests.has(quest_id): return quests[quest_id].rewards
	return {}

func get_active_quests() -> Array:
	var result = []
	for qid in quests:
		if quests[qid].active and not quests[qid].completed:
			result.append(qid)
	return result

func get_completed_quests() -> Array:
	var result = []
	for qid in quests:
		if quests[qid].completed:
			result.append(qid)
	return result

func get_available_quests() -> Array:
	var result = []
	for qid in quests:
		if not quests[qid].active and not quests[qid].completed:
			result.append(qid)
	return result
