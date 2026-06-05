extends Node

# 科技感主题配色
const C_PRIMARY = Color("#00d4ff")
const C_SECONDARY = Color("#7b2fff")
const C_ACCENT = Color("#ff6b35")
const C_BG_DARK = Color("#0a0a1a")
const C_BG_PANEL = Color("#0e0e28")
const C_TEXT = Color("#d0dcff")
const C_TEXT_DIM = Color("#7a8aba")
const C_GREEN = Color("#00ff9d")
const C_RED = Color("#ff3355")

static func make_panel_style(corner: int = 8, border_w: int = 1, alpha: float = 0.9) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.06, 0.16, alpha)
	s.border_color = Color(0, 0.83, 1.0, 0.4)
	s.border_width_left = border_w
	s.border_width_right = border_w
	s.border_width_top = border_w
	s.border_width_bottom = border_w
	s.corner_radius_top_left = corner
	s.corner_radius_top_right = corner
	s.corner_radius_bottom_left = corner
	s.corner_radius_bottom_right = corner
	s.expand_margin_left = 4
	s.expand_margin_top = 4
	s.expand_margin_right = 4
	s.expand_margin_bottom = 4
	return s

static func make_button_style(pressed: bool = false) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0, 0.83, 1.0, 0.15) if not pressed else Color(0, 0.83, 1.0, 0.3)
	s.border_color = Color(0, 0.83, 1.0, 0.5)
	s.border_width_left = 1; s.border_width_right = 1
	s.border_width_top = 1; s.border_width_bottom = 1
	s.corner_radius_top_left = 4; s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4; s.corner_radius_bottom_right = 4
	return s

static func make_bar_style(color: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color * Color(1,1,1,0.15)
	return s

static func style_button(btn: Button):
	btn.add_theme_stylebox_override("normal", make_button_style(false))
	btn.add_theme_stylebox_override("hover", make_button_style(false))
	btn.add_theme_stylebox_override("pressed", make_button_style(true))
	btn.add_theme_color_override("font_color", C_TEXT)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 18)

static func style_label(lb: Label, size: int = 16, color: Color = C_TEXT):
	lb.add_theme_color_override("font_color", color)
	lb.add_theme_font_size_override("font_size", size)

static func style_bar(bar: ProgressBar, fill_color: Color):
	bar.add_theme_stylebox_override("background", make_bar_style(fill_color))
	bar.add_theme_stylebox_override("fill", make_bar_style(fill_color))
	bar.modulate = fill_color

static func add_glow_effect(node: CanvasItem, color: Color = C_PRIMARY, strength: float = 0.3):
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/glow.gdshader") if ResourceLoader.exists("res://shaders/glow.gdshader") else null
	if mat.shader:
		mat.set_shader_parameter("glow_color", color)
		mat.set_shader_parameter("glow_strength", strength)
		node.material = mat