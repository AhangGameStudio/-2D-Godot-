extends Control

const TARGET_SCENE = "res://scenes/main.tscn"
const LOAD_SECONDS = 2.4
const COLUMNS = 12
const ROWS = 7

const TERRAIN_TEXTURES = [
	"res://assets/textures/terrain/Grass001/Grass001.png",
	"res://assets/textures/terrain/Rock051/Rock051.png",
	"res://assets/textures/terrain/Lava001/Lava001.png",
	"res://assets/textures/terrain/Snow011/Snow011.png",
	"res://assets/textures/terrain/Rock044/Rock044.png"
]

const REGION_MARKERS = [
	{name = "灵语森林", pos = Vector2(0.18, 0.28), color = Color(0.42, 1.0, 0.48)},
	{name = "浮空秘境", pos = Vector2(0.72, 0.18), color = Color(0.55, 0.86, 1.0)},
	{name = "熔岩荒漠", pos = Vector2(0.78, 0.72), color = Color(1.0, 0.38, 0.16)},
	{name = "永冻冰川", pos = Vector2(0.22, 0.76), color = Color(0.82, 0.95, 1.0)},
	{name = "深渊裂隙", pos = Vector2(0.52, 0.56), color = Color(0.72, 0.36, 1.0)}
]

@onready var map_area: Control = $MapArea
@onready var tile_layer: Control = $MapArea/TileLayer
@onready var marker_layer: Control = $MapArea/MarkerLayer
@onready var scan_line: ColorRect = $MapArea/ScanLine
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var status_label: Label = $StatusLabel
@onready var title_label: Label = $TitleLabel
@onready var hint_label: Label = $HintLabel

var elapsed = 0.0
var marker_nodes: Array[Control] = []

func _ready():
	title_label.add_theme_font_size_override("font_size", 28)
	status_label.add_theme_font_size_override("font_size", 18)
	hint_label.add_theme_font_size_override("font_size", 14)
	call_deferred("_build_map")

func _process(delta):
	elapsed += delta
	var t = clamp(elapsed / LOAD_SECONDS, 0.0, 1.0)
	progress_bar.value = round(t * 100.0)
	status_label.text = _get_status_text(t)
	scan_line.position.x = fmod(elapsed * 240.0, max(map_area.size.x, 1.0))
	scan_line.modulate.a = 0.35 + sin(elapsed * 8.0) * 0.2
	_update_markers(t)
	if t >= 1.0:
		set_process(false)
		await get_tree().create_timer(0.18).timeout
		get_tree().change_scene_to_file(TARGET_SCENE)

func _build_map():
	var tile_size = Vector2(map_area.size.x / COLUMNS, map_area.size.y / ROWS)
	var textures = []
	for path in TERRAIN_TEXTURES:
		textures.append(load(path))
	for y in range(ROWS):
		for x in range(COLUMNS):
			var tile = TextureRect.new()
			tile.texture = textures[_pick_terrain(x, y)]
			tile.position = Vector2(x * tile_size.x, y * tile_size.y)
			tile.size = tile_size + Vector2.ONE
			tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tile.stretch_mode = TextureRect.STRETCH_SCALE
			tile.modulate = Color(0.55, 0.62, 0.7, 0.78)
			tile_layer.add_child(tile)
	_build_markers()

func _pick_terrain(x, y):
	if x > 8 and y > 4:
		return 2
	if x < 4 and y > 4:
		return 3
	if x > 7 and y < 3:
		return 1
	if x >= 5 and x <= 7 and y >= 3:
		return 4
	return 0

func _build_markers():
	for data in REGION_MARKERS:
		var marker = Panel.new()
		marker.position = Vector2(data.pos.x * map_area.size.x - 48.0, data.pos.y * map_area.size.y - 18.0)
		marker.size = Vector2(96, 36)
		marker.modulate = Color(1, 1, 1, 0.18)
		var label = Label.new()
		label.text = data.name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.anchor_right = 1.0
		label.anchor_bottom = 1.0
		label.add_theme_color_override("font_color", data.color)
		label.add_theme_font_size_override("font_size", 14)
		marker.add_child(label)
		marker_layer.add_child(marker)
		marker_nodes.append(marker)

func _update_markers(t):
	for i in range(marker_nodes.size()):
		var marker = marker_nodes[i]
		var threshold = float(i + 1) / float(marker_nodes.size() + 1)
		var active = t >= threshold
		marker.modulate.a = 0.92 if active else 0.2
		marker.scale = Vector2.ONE * (1.03 + sin(elapsed * 5.0 + i) * 0.025) if active else Vector2.ONE

func _get_status_text(t):
	if t < 0.22:
		return "唤醒灵能脉络..."
	if t < 0.44:
		return "展开大陆地形..."
	if t < 0.66:
		return "标记六大生态区域..."
	if t < 0.88:
		return "同步资源与魔物..."
	return "即将进入魔幻人生..."
