extends Control

signal back_to_menu()

var ip_edit = null
var status_label = null

func _ready():
	# 半透明背景
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.06, 0.16, 0.95)
	bg.border_color = Color(0, 0.83, 1.0, 0.3)
	bg.border_width_left = 1; bg.border_width_right = 1
	bg.border_width_top = 1; bg.border_width_bottom = 3
	bg.corner_radius_top_left = 10; bg.corner_radius_top_right = 10
	bg.corner_radius_bottom_left = 10; bg.corner_radius_bottom_right = 10
	$Panel.add_theme_stylebox_override("panel", bg)
	
	$Panel/Title.add_theme_color_override("font_color", Color("#00d4ff"))
	$Panel/Title.add_theme_font_size_override("font_size", 20)
	
	$Panel/BackBtn.add_theme_color_override("font_color", Color("#7a8aba"))
	$Panel/BackBtn.add_theme_font_size_override("font_size", 14)
	$Panel/BackBtn.pressed.connect(func(): back_to_menu.emit())
	
	# 主机按钮
	var hb = StyleBoxFlat.new()
	hb.bg_color = Color(0, 0.83, 1.0, 0.1)
	hb.border_color = Color(0, 0.83, 1.0, 0.4)
	hb.border_width_left = 1; hb.border_width_right = 1
	hb.border_width_top = 1; hb.border_width_bottom = 1
	hb.corner_radius_top_left = 6; hb.corner_radius_top_right = 6
	hb.corner_radius_bottom_left = 6; hb.corner_radius_bottom_right = 6
	var hb_h = hb.duplicate()
	hb_h.bg_color = Color(0, 0.83, 1.0, 0.25)
	
	$Panel/HostBtn.add_theme_stylebox_override("normal", hb)
	$Panel/HostBtn.add_theme_stylebox_override("hover", hb_h)
	$Panel/HostBtn.add_theme_color_override("font_color", Color("#c8dcff"))
	$Panel/HostBtn.add_theme_font_size_override("font_size", 16)
	$Panel/HostBtn.pressed.connect(_on_host)
	
	var jb = hb.duplicate()
	$Panel/JoinBtn.add_theme_stylebox_override("normal", jb)
	$Panel/JoinBtn.add_theme_stylebox_override("hover", hb_h)
	$Panel/JoinBtn.add_theme_color_override("font_color", Color("#c8dcff"))
	$Panel/JoinBtn.add_theme_font_size_override("font_size", 16)
	$Panel/JoinBtn.pressed.connect(_on_join)
	
	ip_edit = $Panel/IPInput
	ip_edit.placeholder_text = "输入 IP 地址（加入时）"
	var ip_bg = StyleBoxFlat.new()
	ip_bg.bg_color = Color(0, 0, 0, 0.3)
	ip_bg.border_color = Color(0, 0.83, 1.0, 0.2)
	ip_bg.border_width_left = 1; ip_bg.border_width_right = 1
	ip_bg.border_width_top = 1; ip_bg.border_width_bottom = 1
	ip_edit.add_theme_stylebox_override("normal", ip_bg)
	ip_edit.add_theme_color_override("font_color", Color.WHITE)
	
	status_label = $Panel/Status
	status_label.add_theme_color_override("font_color", Color("#7a8aba"))
	status_label.add_theme_font_size_override("font_size", 12)

func _on_host():
	var net = get_node("/root/NetworkManager")
	if net:
		status_label.text = "正在开房..."
		if net.host_game():
			status_label.text = "已开房，等待玩家加入..."
			print("Multiplayer: Hosting on port 8910")

func _on_join():
	var ip = ip_edit.text.strip_edges()
	if ip.is_empty():
		status_label.text = "请输入 IP 地址"
		return
	var net = get_node("/root/NetworkManager")
	if net:
		status_label.text = "正在连接 " + ip + "..."
		if net.join_game(ip):
			status_label.text = "已连接！"
			print("Multiplayer: Joined ", ip)

func set_status(text: String):
	if status_label:
		status_label.text = text
