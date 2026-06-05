extends CharacterBody2D

const SPEED = 250.0
const RUN_SPEED = 400.0
const JOY_RADIUS = 80.0

var camera = null
var touch_dir = Vector2.ZERO
var touch_running = false
var joystick_active = false
var joystick_start = Vector2.ZERO
var joy_knob = null
var joy_knob_origin = Vector2.ZERO

func _ready():
	# 生成可见的彩色精灵纹理
	var img = Image.create(32, 40, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.6, 0.9))  # 蓝色
	# 画一个简单的轮廓
	var tex = ImageTexture.create_from_image(img)
	$Sprite2D.texture = tex
	$Sprite2D.scale = Vector2(2.0, 2.0)
	
	# 找相机
	var cams = get_tree().get_nodes_in_group("main_camera")
	if cams.size() > 0:
		camera = cams[0]
	
	# 延迟创建摇杆
	call_deferred("_create_touch_controls")

func _create_touch_controls():
	var layer = CanvasLayer.new()
	layer.name = "TouchControls"
	layer.layer = 10
	var vs = get_viewport_rect().size
	
	var pad_tex = preload("res://assets/mobile-controls/Sprites/Style A/Default/joystick_polygon_pad_a.png")
	var nub_tex = preload("res://assets/mobile-controls/Sprites/Style A/Default/joystick_polygon_nub_a.png")
	var btn_tex = preload("res://assets/mobile-controls/Sprites/Style A/Default/button_circle.png")
	var sword_tex = preload("res://assets/mobile-controls/Sprites/Icons/Default/icon_sword.png")
	var hand_tex = preload("res://assets/mobile-controls/Sprites/Icons/Default/icon_hand.png")
	
	# 摇杆背景
	var pad_sz = Vector2(130, 130)
	var pad_pos = Vector2(35, vs.y - 165)
	if pad_tex:
		var jbg = TextureRect.new()
		jbg.name = "JoyBg"
		jbg.texture = pad_tex
		jbg.size = pad_sz
		jbg.position = pad_pos
		jbg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		jbg.modulate = Color(1, 1, 1, 0.5)
		jbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(jbg)
	
	# 摇杆旋钮（居中）
	var nub_sz = Vector2(52, 52)
	var center = pad_pos + pad_sz / 2
	joy_knob_origin = center - nub_sz / 2
	if nub_tex:
		joy_knob = TextureRect.new()
		joy_knob.name = "JoyKnob"
		joy_knob.texture = nub_tex
		joy_knob.size = nub_sz
		joy_knob.position = joy_knob_origin
		joy_knob.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		joy_knob.modulate = Color(1, 1, 1, 0.7)
		joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(joy_knob)
	
	# 攻击按钮
	if btn_tex:
		var atk = TextureButton.new()
		atk.name = "AttackBtn"
		atk.texture_normal = btn_tex
		atk.position = Vector2(vs.x - 130, vs.y - 170)
		atk.size = Vector2(85, 85)
		atk.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		atk.modulate = Color(1, 0.3, 0.3, 0.7)
		atk.pressed.connect(attack)
		layer.add_child(atk)
		if sword_tex:
			var si = TextureRect.new()
			si.texture = sword_tex
			si.position = atk.position + Vector2(18, 18)
			si.size = Vector2(48, 48)
			si.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			si.mouse_filter = Control.MOUSE_FILTER_IGNORE
			layer.add_child(si)
	
	# 交互按钮
	if btn_tex:
		var inte = TextureButton.new()
		inte.name = "InteractBtn"
		inte.texture_normal = btn_tex
		inte.position = Vector2(vs.x - 215, vs.y - 135)
		inte.size = Vector2(75, 75)
		inte.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		inte.modulate = Color(0.3, 0.6, 1.0, 0.7)
		inte.pressed.connect(interact)
		layer.add_child(inte)
		if hand_tex:
			var hi = TextureRect.new()
			hi.texture = hand_tex
			hi.position = inte.position + Vector2(18, 18)
			hi.size = Vector2(40, 40)
			hi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hi.mouse_filter = Control.MOUSE_FILTER_IGNORE
			layer.add_child(hi)
	
	get_tree().current_scene.add_child(layer)

# 触摸输入
func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			joystick_start = event.position
			joystick_active = true
		else:
			joystick_active = false
			touch_dir = Vector2.ZERO
			if joy_knob:
				joy_knob.position = joy_knob_origin
	if event is InputEventScreenDrag and joystick_active:
		var delta = event.position - joystick_start
		var dist = delta.length()
		if dist > JOY_RADIUS:
			delta = delta.normalized() * JOY_RADIUS
		touch_dir = delta.normalized() if dist > 15 else Vector2.ZERO
		touch_running = dist > JOY_RADIUS * 0.65
		if joy_knob:
			joy_knob.position = joy_knob_origin + delta

# 键盘+触摸统一处理
func _physics_process(delta):
	var dir = Vector2.ZERO
	
	if Input.is_action_pressed("ui_left"): dir.x -= 1
	if Input.is_action_pressed("ui_right"): dir.x += 1
	if Input.is_action_pressed("ui_up"): dir.y -= 1
	if Input.is_action_pressed("ui_down"): dir.y += 1
	
	if touch_dir.length() > 0:
		dir = touch_dir
	
	if dir.length() > 0:
		dir = dir.normalized()
		var running = Input.is_key_pressed(KEY_SHIFT) or touch_running
		velocity = dir * (RUN_SPEED if running else SPEED)
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	
	if camera:
		camera.position = position

func attack():
	pass

func interact():
	pass